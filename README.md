
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
library(rgl)
library(rphylopic)
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Original drawing by Antonov, vectorized by Roberto Díaz Sibaja, Jagged
Fang Designs, xgirouxb, Scott Hartman, Gabriela Palomo-Munoz, Markus A.
Grohme, Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.,
Falconaumanni and T. Michael Keesey, FunkMonk, Jerry Oldenettel
(vectorized by T. Michael Keesey), Zimices, Matt Martyniuk, Christoph
Schomburg, Margot Michaud, Maxwell Lefroy (vectorized by T. Michael
Keesey), Gareth Monger, Giant Blue Anteater (vectorized by T. Michael
Keesey), T. Michael Keesey, Chris huh, Alexis Simon, Jon Hill (Photo by
Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Matt Crook,
Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Emily Willoughby, Matus Valach, Obsidian Soul
(vectorized by T. Michael Keesey), Sarah Werning, Ignacio Contreras, C.
Camilo Julián-Caballero, Ferran Sayol, Jaime Headden, Birgit Lang,
Darius Nau, Tauana J. Cunha, Lisa Byrne, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Eduard Solà
(vectorized by T. Michael Keesey), Didier Descouens (vectorized by T.
Michael Keesey), Johan Lindgren, Michael W. Caldwell, Takuya Konishi,
Luis M. Chiappe, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Michelle Site, Sergio A. Muñoz-Gómez, Katie S. Collins, Nobu Tamura
(vectorized by T. Michael Keesey), Mathew Wedel, Renata F. Martins,
Steven Traver, Iain Reid, Nobu Tamura, vectorized by Zimices, Nobu
Tamura (modified by T. Michael Keesey), Kamil S. Jaron, Noah Schlottman,
Oliver Griffith, Yan Wong, Martin R. Smith, Rebecca Groom, Rene Martin,
Maija Karala, Mathieu Basille, Becky Barnes, L. Shyamal, Michele Tobias,
Collin Gross, Joanna Wolfe, Cesar Julian, Kanchi Nanjo, Tracy A. Heath,
Caleb M. Brown, Dean Schnabel, Jack Mayer Wood, Elizabeth Parker, E.
Lear, 1819 (vectorization by Yan Wong), Robbie N. Cada (modified by T.
Michael Keesey), Jessica Anne Miller, Emily Jane McTavish, Mali’o Kodis,
photograph by Jim Vargo, Chuanixn Yu, Armin Reindl, Beth Reinke, Henry
Lydecker, Christine Axon, Xavier Giroux-Bougard, Mali’o Kodis, traced
image from the National Science Foundation’s Turbellarian Taxonomic
Database, Tyler Greenfield, Robbie N. Cada (vectorized by T. Michael
Keesey), Mario Quevedo, Ingo Braasch, Scott Reid, Conty (vectorized by
T. Michael Keesey), George Edward Lodge (modified by T. Michael Keesey),
H. Filhol (vectorized by T. Michael Keesey), Alex Slavenko, Matthew E.
Clapham, Tasman Dixon, Mathilde Cordellier, Oscar Sanisidro, Chase
Brownstein, Hans Hillewaert (vectorized by T. Michael Keesey),
Smokeybjb, Francesco Veronesi (vectorized by T. Michael Keesey), Fcb981
(vectorized by T. Michael Keesey), E. D. Cope (modified by T. Michael
Keesey, Michael P. Taylor & Matthew J. Wedel), Kai R. Caspar, V. Deepak,
Geoff Shaw, Rachel Shoop, Oliver Voigt, Darren Naish (vectorize by T.
Michael Keesey), Michael Scroggie, Luis Cunha, Steven Coombs, Owen Jones
(derived from a CC-BY 2.0 photograph by Paulo B. Chaves), Dmitry
Bogdanov, Fernando Carezzano, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Ghedoghedo
(vectorized by T. Michael Keesey), Trond R. Oskars, JJ Harrison
(vectorized by T. Michael Keesey), Aviceda (vectorized by T. Michael
Keesey), Tomas Willems (vectorized by T. Michael Keesey), DW Bapst
(modified from Bulman, 1970), Juan Carlos Jerí, Nobu Tamura, Alan Manson
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Roberto Diaz Sibaja, based on Domser, Harold N Eyster, Smokeybjb
(vectorized by T. Michael Keesey), Melissa Broussard, Dmitry Bogdanov
(modified by T. Michael Keesey), Walter Vladimir, Mareike C. Janiak, M.
Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius
(vectorized by T. Michael Keesey), Hans Hillewaert (photo) and T.
Michael Keesey (vectorization), Ellen Edmonson and Hugh Chrisp
(vectorized by T. Michael Keesey), Mali’o Kodis, image from the
Biodiversity Heritage Library, Ville-Veikko Sinkkonen, david maas / dave
hone, Bennet McComish, photo by Hans Hillewaert, Sean McCann, Tim
Bertelink (modified by T. Michael Keesey), Dr. Thomas G. Barnes, USFWS,
Martin Kevil, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Carlos
Cano-Barbacil, Ricardo N. Martinez & Oscar A. Alcober, Haplochromis
(vectorized by T. Michael Keesey), Jonathan Wells, Christian A.
Masnaghetti, Todd Marshall, vectorized by Zimices, Bill Bouton (source
photo) & T. Michael Keesey (vectorization), Zachary Quigley, Jimmy
Bernot, Chris Hay, Ekaterina Kopeykina (vectorized by T. Michael
Keesey), Ernst Haeckel (vectorized by T. Michael Keesey), David Tana,
Matt Martyniuk (vectorized by T. Michael Keesey), Michael P. Taylor,
Esme Ashe-Jepson, CNZdenek, Benjamint444, FJDegrange, Estelle Bourdon,
Shyamal, Jake Warner, Michael Scroggie, from original photograph by Gary
M. Stolz, USFWS (original photograph in public domain)., Felix Vaux,
Mike Keesey (vectorization) and Vaibhavcho (photography),
SecretJellyMan, Julio Garza, David Orr, Julie Blommaert based on photo
by Sofdrakou, Maxime Dahirel, T. Michael Keesey (after Tillyard), Mo
Hassan, DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).,
Verdilak, Noah Schlottman, photo by Carol Cummings, T. Michael Keesey
(after Kukalová), Evan Swigart (photography) and T. Michael Keesey
(vectorization), Ville Koistinen and T. Michael Keesey, Alexander
Schmidt-Lebuhn, Gabriele Midolo, Eduard Solà Vázquez, vectorised by Yan
Wong, Ghedoghedo, Berivan Temiz, Kent Sorgon, Lily Hughes, Joseph J. W.
Sertich, Mark A. Loewen, Stanton F. Fink (vectorized by T. Michael
Keesey), Scott Hartman (modified by T. Michael Keesey), Lafage, Mali’o
Kodis, photograph property of National Museums of Northern Ireland, Jose
Carlos Arenas-Monroy, Peileppe, Manabu Bessho-Uehara, Neil Kelley, Matt
Hayes, Ron Holmes/U. S. Fish and Wildlife Service (source photo), T.
Michael Keesey (vectorization), Manabu Sakamoto, Noah Schlottman, photo
by Casey Dunn, Douglas Brown (modified by T. Michael Keesey),
Terpsichores, M Kolmann, Mike Hanson, Crystal Maier, zoosnow, Acrocynus
(vectorized by T. Michael Keesey), Milton Tan, Robert Gay, Allison
Pease, Robert Bruce Horsfall, vectorized by Zimices, Julia B McHugh,
Christina N. Hodson, Matt Wilkins, Ieuan Jones, Arthur S. Brum, Yan Wong
from photo by Gyik Toma, Andrew A. Farke, Francesco “Architetto”
Rollandin, Mali’o Kodis, photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Joe Schneid (vectorized
by T. Michael Keesey), Jakovche, Catherine Yasuda, Dann Pigdon, Fernando
Campos De Domenico, (after Spotila 2004), Tess Linden, Elisabeth Östman,
JCGiron, Nicolas Mongiardino Koch, Michael Scroggie, from original
photograph by John Bettaso, USFWS (original photograph in public
domain)., Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Chloé
Schmidt, A. H. Baldwin (vectorized by T. Michael Keesey), Agnello
Picorelli, Andrés Sánchez, Brad McFeeters (vectorized by T. Michael
Keesey), Paul O. Lewis, Frank Förster (based on a picture by Jerry
Kirkhart; modified by T. Michael Keesey), Tarique Sani (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Daniel Jaron,
Kent Elson Sorgon, Michael Wolf (photo), Hans Hillewaert (editing), T.
Michael Keesey (vectorization), Matt Celeskey, B Kimmel, Mali’o Kodis,
image from the “Proceedings of the Zoological Society of London”,
Almandine (vectorized by T. Michael Keesey), Félix Landry Yuan, Charles
Doolittle Walcott (vectorized by T. Michael Keesey), T. Michael Keesey
(vectorization) and Tony Hisgett (photography), Lukasiniho, Benjamin
Monod-Broca, Emil Schmidt (vectorized by Maxime Dahirel), Lukas Panzarin
(vectorized by T. Michael Keesey), Steven Haddock • Jellywatch.org, Noah
Schlottman, photo from Casey Dunn, Noah Schlottman, photo from National
Science Foundation - Turbellarian Taxonomic Database

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                       |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    641.957022 |    502.652243 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                               |
|   2 |    157.948987 |    571.087149 | Jagged Fang Designs                                                                                                                                          |
|   3 |    567.636932 |    196.552158 | xgirouxb                                                                                                                                                     |
|   4 |    122.687617 |    200.597279 | Scott Hartman                                                                                                                                                |
|   5 |    467.019270 |    317.699711 | Gabriela Palomo-Munoz                                                                                                                                        |
|   6 |    764.587845 |    508.105826 | Jagged Fang Designs                                                                                                                                          |
|   7 |    732.054946 |    746.412986 | Markus A. Grohme                                                                                                                                             |
|   8 |    297.845136 |    623.885397 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                        |
|   9 |    147.362593 |     66.548522 | NA                                                                                                                                                           |
|  10 |    952.814243 |    535.384175 | Falconaumanni and T. Michael Keesey                                                                                                                          |
|  11 |    245.903984 |    400.787708 | FunkMonk                                                                                                                                                     |
|  12 |    608.510280 |    688.024970 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                           |
|  13 |    961.206492 |    235.718377 | Gabriela Palomo-Munoz                                                                                                                                        |
|  14 |    744.579350 |    167.317582 | NA                                                                                                                                                           |
|  15 |    443.236556 |    674.760467 | Zimices                                                                                                                                                      |
|  16 |    261.776805 |    495.189949 | Matt Martyniuk                                                                                                                                               |
|  17 |    131.341974 |    459.612622 | Christoph Schomburg                                                                                                                                          |
|  18 |    143.470133 |    707.744118 | Jagged Fang Designs                                                                                                                                          |
|  19 |    367.201507 |    437.531159 | Margot Michaud                                                                                                                                               |
|  20 |    454.546804 |    162.241836 | FunkMonk                                                                                                                                                     |
|  21 |    620.380001 |    298.346729 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                             |
|  22 |    285.553292 |     69.978928 | Gareth Monger                                                                                                                                                |
|  23 |    928.476546 |    155.682784 | Zimices                                                                                                                                                      |
|  24 |    264.282966 |    264.447800 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                        |
|  25 |    692.973833 |    347.135396 | T. Michael Keesey                                                                                                                                            |
|  26 |    211.913200 |    640.288625 | Scott Hartman                                                                                                                                                |
|  27 |    585.342951 |    122.156570 | Chris huh                                                                                                                                                    |
|  28 |     48.106958 |    110.714815 | Alexis Simon                                                                                                                                                 |
|  29 |     53.190725 |    341.969064 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                  |
|  30 |    860.816346 |    372.408164 | Matt Crook                                                                                                                                                   |
|  31 |    287.671083 |    188.765937 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
|  32 |     94.024989 |    626.534469 | Emily Willoughby                                                                                                                                             |
|  33 |    618.060024 |     52.467118 | Scott Hartman                                                                                                                                                |
|  34 |    864.945151 |    677.443702 | Matus Valach                                                                                                                                                 |
|  35 |    854.241244 |    745.706122 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                              |
|  36 |    314.636888 |    700.709139 | Sarah Werning                                                                                                                                                |
|  37 |    139.959766 |    265.668250 | Margot Michaud                                                                                                                                               |
|  38 |    384.764174 |    565.727599 | Zimices                                                                                                                                                      |
|  39 |    251.492655 |    770.196515 | Ignacio Contreras                                                                                                                                            |
|  40 |    855.789223 |    114.028372 | Ignacio Contreras                                                                                                                                            |
|  41 |    714.208812 |    634.156941 | Margot Michaud                                                                                                                                               |
|  42 |    833.307002 |    237.322241 | Zimices                                                                                                                                                      |
|  43 |   1007.150967 |    134.829187 | NA                                                                                                                                                           |
|  44 |    435.793133 |     26.813395 | Gareth Monger                                                                                                                                                |
|  45 |    832.254999 |    603.555985 | Chris huh                                                                                                                                                    |
|  46 |    240.304800 |    158.368176 | Chris huh                                                                                                                                                    |
|  47 |    912.803221 |     37.994304 | Margot Michaud                                                                                                                                               |
|  48 |    412.391565 |    250.130775 | C. Camilo Julián-Caballero                                                                                                                                   |
|  49 |    358.535491 |    378.021358 | Gareth Monger                                                                                                                                                |
|  50 |    957.435404 |    693.479672 | Margot Michaud                                                                                                                                               |
|  51 |    166.692279 |    338.957611 | Ferran Sayol                                                                                                                                                 |
|  52 |    508.654580 |     70.890484 | Scott Hartman                                                                                                                                                |
|  53 |    440.873736 |    766.204573 | Jaime Headden                                                                                                                                                |
|  54 |    676.912407 |    417.149107 | Jagged Fang Designs                                                                                                                                          |
|  55 |    104.179289 |    743.282198 | Birgit Lang                                                                                                                                                  |
|  56 |    712.191250 |     26.977730 | NA                                                                                                                                                           |
|  57 |    883.344055 |    772.902982 | Darius Nau                                                                                                                                                   |
|  58 |    358.513491 |    320.427177 | Tauana J. Cunha                                                                                                                                              |
|  59 |    813.871949 |    475.362405 | Margot Michaud                                                                                                                                               |
|  60 |    543.184420 |    387.624366 | Gareth Monger                                                                                                                                                |
|  61 |    342.951369 |    516.813902 | Lisa Byrne                                                                                                                                                   |
|  62 |    624.471130 |    769.279907 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                      |
|  63 |    519.890913 |    265.289023 | Chris huh                                                                                                                                                    |
|  64 |    426.679658 |    108.036691 | Chris huh                                                                                                                                                    |
|  65 |    767.864380 |    698.285301 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                |
|  66 |    212.232117 |    737.686309 | Zimices                                                                                                                                                      |
|  67 |     67.377265 |    774.997069 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                           |
|  68 |    378.929469 |     61.787782 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                         |
|  69 |    379.014328 |    189.146655 | NA                                                                                                                                                           |
|  70 |    187.889810 |    674.760483 | NA                                                                                                                                                           |
|  71 |    806.431201 |    523.871265 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  72 |    866.144564 |    163.242405 | Michelle Site                                                                                                                                                |
|  73 |     99.950969 |    515.329021 | Sergio A. Muñoz-Gómez                                                                                                                                        |
|  74 |    937.317497 |    199.591246 | Margot Michaud                                                                                                                                               |
|  75 |    341.480604 |    755.410789 | Katie S. Collins                                                                                                                                             |
|  76 |    393.081640 |    145.659757 | Zimices                                                                                                                                                      |
|  77 |    188.307779 |    790.322678 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  78 |     40.816961 |    239.079141 | Margot Michaud                                                                                                                                               |
|  79 |    208.665478 |     53.938124 | Mathew Wedel                                                                                                                                                 |
|  80 |    961.140072 |     21.821928 | Renata F. Martins                                                                                                                                            |
|  81 |    983.138953 |    100.703685 | Matt Crook                                                                                                                                                   |
|  82 |    235.619511 |    701.178789 | Jagged Fang Designs                                                                                                                                          |
|  83 |    164.849252 |    148.272792 | Steven Traver                                                                                                                                                |
|  84 |    275.689711 |    577.927153 | T. Michael Keesey                                                                                                                                            |
|  85 |    549.074082 |    781.721377 | Emily Willoughby                                                                                                                                             |
|  86 |    228.101071 |    559.024903 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  87 |    761.024220 |      5.027661 | Iain Reid                                                                                                                                                    |
|  88 |    622.409639 |    481.377677 | Sarah Werning                                                                                                                                                |
|  89 |    115.321033 |    128.839342 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
|  90 |    392.725514 |    300.636903 | Steven Traver                                                                                                                                                |
|  91 |    601.794824 |     26.385809 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  92 |     15.515346 |    183.206655 | Matt Crook                                                                                                                                                   |
|  93 |     36.135182 |    432.701004 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                  |
|  94 |    729.000505 |    406.011553 | Kamil S. Jaron                                                                                                                                               |
|  95 |    860.116325 |    716.121393 | Noah Schlottman                                                                                                                                              |
|  96 |    209.858599 |    309.443796 | Oliver Griffith                                                                                                                                              |
|  97 |    707.442943 |    661.044128 | Scott Hartman                                                                                                                                                |
|  98 |    366.342447 |    269.187928 | Steven Traver                                                                                                                                                |
|  99 |    559.665174 |    344.768084 | Jagged Fang Designs                                                                                                                                          |
| 100 |    978.650391 |    346.828735 | Yan Wong                                                                                                                                                     |
| 101 |    758.224794 |     73.586447 | Martin R. Smith                                                                                                                                              |
| 102 |    340.669790 |    599.046923 | Rebecca Groom                                                                                                                                                |
| 103 |    110.804262 |    378.714324 | Rene Martin                                                                                                                                                  |
| 104 |    115.183403 |    152.403619 | NA                                                                                                                                                           |
| 105 |    516.647659 |    107.734677 | Maija Karala                                                                                                                                                 |
| 106 |    245.111371 |    301.779623 | Steven Traver                                                                                                                                                |
| 107 |     31.593485 |    485.177233 | Tauana J. Cunha                                                                                                                                              |
| 108 |    625.535729 |    456.511139 | Zimices                                                                                                                                                      |
| 109 |    213.621003 |    200.903049 | Mathieu Basille                                                                                                                                              |
| 110 |    933.431960 |     94.545747 | Becky Barnes                                                                                                                                                 |
| 111 |    238.619921 |    190.434311 | L. Shyamal                                                                                                                                                   |
| 112 |    621.628228 |    727.447237 | Gareth Monger                                                                                                                                                |
| 113 |     43.671445 |    192.629628 | Michele Tobias                                                                                                                                               |
| 114 |    684.748242 |    605.659961 | NA                                                                                                                                                           |
| 115 |    127.503220 |    404.512007 | Zimices                                                                                                                                                      |
| 116 |    401.109472 |    730.256805 | Scott Hartman                                                                                                                                                |
| 117 |    207.856297 |    121.117882 | Collin Gross                                                                                                                                                 |
| 118 |    772.140967 |    782.718824 | Joanna Wolfe                                                                                                                                                 |
| 119 |    616.909990 |    695.550362 | Cesar Julian                                                                                                                                                 |
| 120 |     15.051249 |     42.146763 | Kanchi Nanjo                                                                                                                                                 |
| 121 |    806.904367 |    553.887712 | Margot Michaud                                                                                                                                               |
| 122 |    580.806249 |     81.875892 | Zimices                                                                                                                                                      |
| 123 |    878.523625 |    563.811131 | Tracy A. Heath                                                                                                                                               |
| 124 |    374.776218 |    104.639001 | Chris huh                                                                                                                                                    |
| 125 |    417.561482 |    527.473356 | Jagged Fang Designs                                                                                                                                          |
| 126 |    739.107075 |    664.844992 | Caleb M. Brown                                                                                                                                               |
| 127 |    211.626880 |    541.340823 | Dean Schnabel                                                                                                                                                |
| 128 |     26.013288 |    627.628914 | Zimices                                                                                                                                                      |
| 129 |    976.259802 |    791.600811 | Jack Mayer Wood                                                                                                                                              |
| 130 |    192.440162 |    610.830929 | Elizabeth Parker                                                                                                                                             |
| 131 |    317.995677 |    345.753075 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                    |
| 132 |    697.958990 |    240.982796 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                               |
| 133 |    988.347480 |    182.316822 | Zimices                                                                                                                                                      |
| 134 |    148.770290 |    514.476826 | C. Camilo Julián-Caballero                                                                                                                                   |
| 135 |     17.774546 |    452.730187 | Jessica Anne Miller                                                                                                                                          |
| 136 |    981.631869 |    699.793093 | Ferran Sayol                                                                                                                                                 |
| 137 |    549.058502 |    245.811923 | NA                                                                                                                                                           |
| 138 |   1001.325215 |    708.528667 | L. Shyamal                                                                                                                                                   |
| 139 |    387.199217 |    227.630810 | Matt Crook                                                                                                                                                   |
| 140 |    386.451035 |    352.901972 | Tauana J. Cunha                                                                                                                                              |
| 141 |    214.040022 |    229.308209 | Zimices                                                                                                                                                      |
| 142 |    994.433531 |    453.241124 | Margot Michaud                                                                                                                                               |
| 143 |     33.853216 |    735.733292 | Emily Jane McTavish                                                                                                                                          |
| 144 |    203.810498 |      6.915829 | NA                                                                                                                                                           |
| 145 |    905.391238 |    647.642440 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                        |
| 146 |    761.750253 |    660.989131 | Chuanixn Yu                                                                                                                                                  |
| 147 |     54.064801 |    662.125501 | Armin Reindl                                                                                                                                                 |
| 148 |    175.655118 |    760.281067 | Scott Hartman                                                                                                                                                |
| 149 |    820.539466 |    634.284631 | Beth Reinke                                                                                                                                                  |
| 150 |    780.161098 |    274.934931 | Henry Lydecker                                                                                                                                               |
| 151 |    588.854658 |    305.549113 | Matt Crook                                                                                                                                                   |
| 152 |    460.100263 |     44.642140 | Christine Axon                                                                                                                                               |
| 153 |    620.492964 |    390.530426 | C. Camilo Julián-Caballero                                                                                                                                   |
| 154 |    639.284913 |    221.164510 | Zimices                                                                                                                                                      |
| 155 |    611.269858 |    142.321841 | Chris huh                                                                                                                                                    |
| 156 |    537.951941 |    350.996213 | Xavier Giroux-Bougard                                                                                                                                        |
| 157 |    657.610893 |    714.130777 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                            |
| 158 |    560.360751 |     17.495711 | Matt Crook                                                                                                                                                   |
| 159 |    165.095647 |    587.454518 | Chris huh                                                                                                                                                    |
| 160 |    816.947103 |    508.230185 | Tyler Greenfield                                                                                                                                             |
| 161 |    265.036563 |    440.950176 | NA                                                                                                                                                           |
| 162 |    427.983028 |    129.453851 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                             |
| 163 |    998.401413 |    489.897993 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                             |
| 164 |    649.740890 |    234.799012 | Mario Quevedo                                                                                                                                                |
| 165 |    924.402902 |    274.575187 | Gareth Monger                                                                                                                                                |
| 166 |    691.320484 |    681.521245 | Zimices                                                                                                                                                      |
| 167 |    888.245830 |     24.726989 | Ingo Braasch                                                                                                                                                 |
| 168 |    153.908157 |    639.849039 | Zimices                                                                                                                                                      |
| 169 |    662.806117 |     59.641913 | Steven Traver                                                                                                                                                |
| 170 |    210.167727 |    599.965691 | L. Shyamal                                                                                                                                                   |
| 171 |     99.374188 |    110.482985 | Scott Reid                                                                                                                                                   |
| 172 |    928.112892 |    723.400154 | Zimices                                                                                                                                                      |
| 173 |     95.184369 |    412.956122 | T. Michael Keesey                                                                                                                                            |
| 174 |      9.326082 |    678.355104 | Collin Gross                                                                                                                                                 |
| 175 |    953.063267 |    752.302582 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
| 176 |    286.111577 |    750.199185 | NA                                                                                                                                                           |
| 177 |    719.298347 |    553.190212 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                          |
| 178 |    992.088735 |    771.688111 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                  |
| 179 |    535.950119 |     14.878097 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 180 |      8.924219 |    508.361515 | Matt Crook                                                                                                                                                   |
| 181 |    741.304706 |    448.022179 | Jagged Fang Designs                                                                                                                                          |
| 182 |     72.397270 |    154.179111 | FunkMonk                                                                                                                                                     |
| 183 |    513.866944 |    589.546892 | Alex Slavenko                                                                                                                                                |
| 184 |    378.508183 |    721.951261 | NA                                                                                                                                                           |
| 185 |    521.060497 |      4.569089 | Matthew E. Clapham                                                                                                                                           |
| 186 |   1002.163872 |    601.498142 | Joanna Wolfe                                                                                                                                                 |
| 187 |    341.343545 |    483.671271 | Zimices                                                                                                                                                      |
| 188 |    514.506630 |    644.842551 | Ferran Sayol                                                                                                                                                 |
| 189 |    748.376514 |    414.192795 | Steven Traver                                                                                                                                                |
| 190 |    456.657649 |     84.815415 | Matt Crook                                                                                                                                                   |
| 191 |    664.164156 |    697.237692 | Scott Hartman                                                                                                                                                |
| 192 |     31.872512 |    727.136508 | Gabriela Palomo-Munoz                                                                                                                                        |
| 193 |     72.497353 |    532.798640 | T. Michael Keesey                                                                                                                                            |
| 194 |    742.786619 |    276.939354 | Tasman Dixon                                                                                                                                                 |
| 195 |    290.757996 |    463.438329 | Mathilde Cordellier                                                                                                                                          |
| 196 |    657.829451 |    403.649025 | Ferran Sayol                                                                                                                                                 |
| 197 |    480.118386 |     47.662899 | Matthew E. Clapham                                                                                                                                           |
| 198 |    498.850254 |    627.713848 | NA                                                                                                                                                           |
| 199 |    413.007563 |    482.292303 | Oscar Sanisidro                                                                                                                                              |
| 200 |    730.467375 |    266.576976 | Darius Nau                                                                                                                                                   |
| 201 |    829.456185 |     28.162137 | Gabriela Palomo-Munoz                                                                                                                                        |
| 202 |    379.315565 |    782.876700 | Kamil S. Jaron                                                                                                                                               |
| 203 |    901.008850 |    591.251805 | Chase Brownstein                                                                                                                                             |
| 204 |   1014.762835 |    198.940915 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                            |
| 205 |    362.165927 |    388.023919 | Chris huh                                                                                                                                                    |
| 206 |    680.884754 |    508.241226 | Matt Crook                                                                                                                                                   |
| 207 |    712.442337 |    602.335424 | Tasman Dixon                                                                                                                                                 |
| 208 |    556.048248 |    760.837995 | Ferran Sayol                                                                                                                                                 |
| 209 |    764.423134 |    439.042710 | Margot Michaud                                                                                                                                               |
| 210 |    635.290077 |    501.091590 | Tracy A. Heath                                                                                                                                               |
| 211 |     35.879635 |    569.451393 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                               |
| 212 |    414.848013 |    236.074383 | Smokeybjb                                                                                                                                                    |
| 213 |    339.728505 |     21.828742 | Ferran Sayol                                                                                                                                                 |
| 214 |    693.918012 |    126.488322 | Gareth Monger                                                                                                                                                |
| 215 |    714.860126 |    361.247687 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                         |
| 216 |    363.664150 |    494.399443 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                     |
| 217 |    560.670799 |    613.793987 | Matt Crook                                                                                                                                                   |
| 218 |    818.374129 |    714.562695 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                             |
| 219 |    749.235790 |    458.989198 | Kai R. Caspar                                                                                                                                                |
| 220 |    304.160790 |    541.887495 | Darius Nau                                                                                                                                                   |
| 221 |    668.282615 |    274.899753 | V. Deepak                                                                                                                                                    |
| 222 |     82.415432 |    406.324470 | Geoff Shaw                                                                                                                                                   |
| 223 |    735.574376 |    425.758254 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
| 224 |    705.556279 |    248.635796 | Ferran Sayol                                                                                                                                                 |
| 225 |    959.727076 |    281.666601 | Margot Michaud                                                                                                                                               |
| 226 |    317.983500 |    221.164114 | Rachel Shoop                                                                                                                                                 |
| 227 |    772.916596 |    681.208825 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 228 |    753.250891 |    393.269548 | Oliver Voigt                                                                                                                                                 |
| 229 |      8.328475 |    751.899697 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                |
| 230 |    188.662510 |    288.037391 | Markus A. Grohme                                                                                                                                             |
| 231 |    578.992079 |    325.125120 | Michael Scroggie                                                                                                                                             |
| 232 |    313.682632 |    426.209135 | Matt Crook                                                                                                                                                   |
| 233 |     30.644302 |    681.252491 | Luis Cunha                                                                                                                                                   |
| 234 |    630.252845 |    230.745574 | Steven Coombs                                                                                                                                                |
| 235 |    997.333453 |    310.571478 | Gabriela Palomo-Munoz                                                                                                                                        |
| 236 |     29.249780 |     13.617384 | Beth Reinke                                                                                                                                                  |
| 237 |    403.463056 |    497.707846 | Zimices                                                                                                                                                      |
| 238 |     59.173869 |    460.603934 | Ferran Sayol                                                                                                                                                 |
| 239 |    899.111739 |    555.055166 | Margot Michaud                                                                                                                                               |
| 240 |    532.416113 |    244.279171 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                          |
| 241 |    896.258204 |    159.223667 | Gabriela Palomo-Munoz                                                                                                                                        |
| 242 |    645.833816 |     82.022839 | Sergio A. Muñoz-Gómez                                                                                                                                        |
| 243 |     44.821783 |    656.638140 | Scott Hartman                                                                                                                                                |
| 244 |    370.446345 |    617.944354 | Dmitry Bogdanov                                                                                                                                              |
| 245 |    253.849416 |    175.113933 | Fernando Carezzano                                                                                                                                           |
| 246 |    431.235703 |    530.419121 | Maija Karala                                                                                                                                                 |
| 247 |    807.746026 |    677.779950 | Yan Wong                                                                                                                                                     |
| 248 |    390.569718 |    713.880964 | NA                                                                                                                                                           |
| 249 |   1009.324685 |    674.357167 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
| 250 |     95.926227 |    792.094420 | L. Shyamal                                                                                                                                                   |
| 251 |    718.582664 |    300.766518 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 252 |    365.804262 |    134.069409 | Jagged Fang Designs                                                                                                                                          |
| 253 |     85.709632 |     82.444441 | Zimices                                                                                                                                                      |
| 254 |   1011.798598 |    411.509574 | Zimices                                                                                                                                                      |
| 255 |     13.430202 |    594.603051 | Trond R. Oskars                                                                                                                                              |
| 256 |    156.759493 |    777.031326 | Chris huh                                                                                                                                                    |
| 257 |    939.465575 |    207.391083 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 258 |     75.682887 |    514.352215 | Margot Michaud                                                                                                                                               |
| 259 |    883.738242 |    521.089958 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                |
| 260 |    528.475241 |    164.679876 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                    |
| 261 |    676.264259 |    675.797271 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                              |
| 262 |    612.119324 |    713.230236 | DW Bapst (modified from Bulman, 1970)                                                                                                                        |
| 263 |    482.898042 |    334.275433 | Scott Hartman                                                                                                                                                |
| 264 |    494.675604 |    636.065250 | Dean Schnabel                                                                                                                                                |
| 265 |    249.238462 |    448.693039 | Kamil S. Jaron                                                                                                                                               |
| 266 |    549.852511 |    476.967686 | Juan Carlos Jerí                                                                                                                                             |
| 267 |    892.752369 |    265.059184 | Jagged Fang Designs                                                                                                                                          |
| 268 |    172.686846 |    424.837438 | Nobu Tamura                                                                                                                                                  |
| 269 |   1005.902949 |    586.336116 | NA                                                                                                                                                           |
| 270 |     38.377393 |    550.518854 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 271 |     20.175890 |    701.684278 | Mathilde Cordellier                                                                                                                                          |
| 272 |    271.065512 |    297.604504 | FunkMonk                                                                                                                                                     |
| 273 |    779.873304 |     61.170389 | Matt Crook                                                                                                                                                   |
| 274 |   1020.289697 |    359.574720 | Gareth Monger                                                                                                                                                |
| 275 |    844.508919 |    629.635116 | Gabriela Palomo-Munoz                                                                                                                                        |
| 276 |    273.691115 |    281.420826 | Juan Carlos Jerí                                                                                                                                             |
| 277 |    601.963115 |    483.067165 | Chris huh                                                                                                                                                    |
| 278 |    619.991696 |    735.751824 | Roberto Diaz Sibaja, based on Domser                                                                                                                         |
| 279 |    214.609394 |    220.523223 | Harold N Eyster                                                                                                                                              |
| 280 |    993.013795 |     62.327570 | Gareth Monger                                                                                                                                                |
| 281 |    773.971654 |    514.042174 | Christoph Schomburg                                                                                                                                          |
| 282 |     39.177955 |    211.789437 | Chris huh                                                                                                                                                    |
| 283 |    420.725626 |    200.539910 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                  |
| 284 |    821.815676 |     59.241420 | Melissa Broussard                                                                                                                                            |
| 285 |    126.206722 |    515.701526 | Rebecca Groom                                                                                                                                                |
| 286 |     42.035046 |    217.611676 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                              |
| 287 |    698.970498 |    219.626020 | Walter Vladimir                                                                                                                                              |
| 288 |    978.311552 |    381.307501 | NA                                                                                                                                                           |
| 289 |    604.064681 |    173.556068 | Mareike C. Janiak                                                                                                                                            |
| 290 |    570.691049 |    748.213370 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                |
| 291 |    824.687469 |    521.803430 | Birgit Lang                                                                                                                                                  |
| 292 |     29.992305 |    669.079366 | NA                                                                                                                                                           |
| 293 |    730.576049 |    215.097562 | NA                                                                                                                                                           |
| 294 |     15.274961 |    270.735194 | Scott Hartman                                                                                                                                                |
| 295 |    674.745669 |    246.200797 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                     |
| 296 |      8.485908 |    691.957465 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                |
| 297 |    696.652138 |    230.748314 | Katie S. Collins                                                                                                                                             |
| 298 |    532.293384 |    147.198131 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                             |
| 299 |    631.905059 |    155.023797 | Margot Michaud                                                                                                                                               |
| 300 |    654.307422 |    279.577762 | Michael Scroggie                                                                                                                                             |
| 301 |    377.639737 |    494.001540 | Margot Michaud                                                                                                                                               |
| 302 |    799.375682 |    622.670215 | C. Camilo Julián-Caballero                                                                                                                                   |
| 303 |    647.309081 |     16.331536 | NA                                                                                                                                                           |
| 304 |    661.253192 |    647.725414 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                   |
| 305 |    175.151140 |    533.763913 | Birgit Lang                                                                                                                                                  |
| 306 |    993.537221 |    409.016494 | Ville-Veikko Sinkkonen                                                                                                                                       |
| 307 |    699.208739 |    539.228216 | david maas / dave hone                                                                                                                                       |
| 308 |    441.527164 |    229.126489 | Ferran Sayol                                                                                                                                                 |
| 309 |    228.645814 |    685.910338 | Bennet McComish, photo by Hans Hillewaert                                                                                                                    |
| 310 |    503.838233 |    103.536109 | Katie S. Collins                                                                                                                                             |
| 311 |    458.671664 |    402.367099 | T. Michael Keesey                                                                                                                                            |
| 312 |    258.580374 |    542.379759 | Sergio A. Muñoz-Gómez                                                                                                                                        |
| 313 |    827.322136 |    511.524177 | Tasman Dixon                                                                                                                                                 |
| 314 |    504.167068 |    434.438771 | Jagged Fang Designs                                                                                                                                          |
| 315 |     15.100741 |    577.002455 | Sean McCann                                                                                                                                                  |
| 316 |    884.281973 |    505.342955 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                |
| 317 |    196.223306 |    221.091340 | Cesar Julian                                                                                                                                                 |
| 318 |    510.902655 |    243.951663 | Chris huh                                                                                                                                                    |
| 319 |    240.364801 |    534.196895 | Jagged Fang Designs                                                                                                                                          |
| 320 |    203.976784 |    323.234960 | Gabriela Palomo-Munoz                                                                                                                                        |
| 321 |    973.729186 |    427.816725 | Kai R. Caspar                                                                                                                                                |
| 322 |    547.365979 |     32.435642 | Markus A. Grohme                                                                                                                                             |
| 323 |    990.766842 |    378.714461 | Mathilde Cordellier                                                                                                                                          |
| 324 |    618.126923 |    405.400205 | Zimices                                                                                                                                                      |
| 325 |    459.858207 |    211.943296 | Kamil S. Jaron                                                                                                                                               |
| 326 |     97.981898 |    252.890533 | Dr. Thomas G. Barnes, USFWS                                                                                                                                  |
| 327 |    506.732621 |    614.891933 | Steven Traver                                                                                                                                                |
| 328 |     27.532208 |    755.764200 | Gareth Monger                                                                                                                                                |
| 329 |    419.154324 |    353.635617 | Martin Kevil                                                                                                                                                 |
| 330 |    942.240331 |    276.672803 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                               |
| 331 |    654.283394 |    504.710261 | Tasman Dixon                                                                                                                                                 |
| 332 |    424.194534 |    398.543099 | Gabriela Palomo-Munoz                                                                                                                                        |
| 333 |   1008.455477 |      4.948016 | Carlos Cano-Barbacil                                                                                                                                         |
| 334 |     77.358109 |    670.738233 | Gareth Monger                                                                                                                                                |
| 335 |   1006.603345 |    329.155817 | Alex Slavenko                                                                                                                                                |
| 336 |    955.801423 |    765.165491 | Ferran Sayol                                                                                                                                                 |
| 337 |    893.736706 |    621.868704 | Steven Traver                                                                                                                                                |
| 338 |    575.089477 |    287.845548 | L. Shyamal                                                                                                                                                   |
| 339 |    542.461792 |    325.877042 | Emily Willoughby                                                                                                                                             |
| 340 |    407.630238 |    624.225169 | T. Michael Keesey                                                                                                                                            |
| 341 |    539.275305 |    599.968713 | T. Michael Keesey                                                                                                                                            |
| 342 |     66.652079 |    430.818849 | Mathilde Cordellier                                                                                                                                          |
| 343 |    242.197142 |    648.481148 | Matt Crook                                                                                                                                                   |
| 344 |    466.439345 |    590.262236 | Elizabeth Parker                                                                                                                                             |
| 345 |    772.863299 |    254.764387 | Matt Crook                                                                                                                                                   |
| 346 |    785.328879 |    625.602398 | Margot Michaud                                                                                                                                               |
| 347 |     50.880914 |      6.842907 | NA                                                                                                                                                           |
| 348 |     97.381433 |    689.599244 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
| 349 |    251.699371 |    428.996328 | Gabriela Palomo-Munoz                                                                                                                                        |
| 350 |    469.206949 |    736.715300 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                       |
| 351 |    160.419134 |    394.504564 | Ferran Sayol                                                                                                                                                 |
| 352 |    892.150621 |    472.931538 | Jagged Fang Designs                                                                                                                                          |
| 353 |    707.329778 |    420.079292 | Scott Hartman                                                                                                                                                |
| 354 |    784.517738 |    411.894136 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
| 355 |     43.541525 |    410.083657 | Emily Willoughby                                                                                                                                             |
| 356 |    651.018039 |    474.912558 | Chris huh                                                                                                                                                    |
| 357 |     93.692929 |     58.904379 | Tasman Dixon                                                                                                                                                 |
| 358 |    259.521988 |    574.887318 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                               |
| 359 |    776.011327 |    444.967386 | Michael Scroggie                                                                                                                                             |
| 360 |    522.102103 |    655.651790 | Jagged Fang Designs                                                                                                                                          |
| 361 |    317.232495 |    582.738223 | Zimices                                                                                                                                                      |
| 362 |     95.528029 |     13.118387 | T. Michael Keesey                                                                                                                                            |
| 363 |    475.500654 |     13.442633 | Steven Traver                                                                                                                                                |
| 364 |    563.397048 |    293.725240 | Jonathan Wells                                                                                                                                               |
| 365 |     74.213288 |    682.625559 | Becky Barnes                                                                                                                                                 |
| 366 |    715.425953 |    775.300524 | Dean Schnabel                                                                                                                                                |
| 367 |    559.863198 |     55.444204 | Carlos Cano-Barbacil                                                                                                                                         |
| 368 |   1000.990554 |    617.603713 | Noah Schlottman                                                                                                                                              |
| 369 |     57.190846 |     15.123066 | Scott Hartman                                                                                                                                                |
| 370 |    128.944600 |    370.627007 | Nobu Tamura                                                                                                                                                  |
| 371 |    295.048676 |    299.457483 | Gabriela Palomo-Munoz                                                                                                                                        |
| 372 |     57.960340 |    572.321693 | Scott Hartman                                                                                                                                                |
| 373 |     51.704226 |    717.591580 | Christian A. Masnaghetti                                                                                                                                     |
| 374 |    373.149104 |    139.728730 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 375 |   1000.229819 |    431.549757 | Matt Crook                                                                                                                                                   |
| 376 |    914.035541 |    639.919931 | Todd Marshall, vectorized by Zimices                                                                                                                         |
| 377 |    387.278129 |    487.461560 | Melissa Broussard                                                                                                                                            |
| 378 |     10.897818 |     20.454476 | Matt Crook                                                                                                                                                   |
| 379 |    982.751069 |     79.350897 | NA                                                                                                                                                           |
| 380 |    462.499228 |    608.611230 | Margot Michaud                                                                                                                                               |
| 381 |   1013.196230 |    529.167857 | Matt Crook                                                                                                                                                   |
| 382 |    515.436454 |    697.005708 | NA                                                                                                                                                           |
| 383 |    399.939889 |    343.539367 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                               |
| 384 |    170.013560 |      9.303778 | T. Michael Keesey                                                                                                                                            |
| 385 |    275.943142 |     11.637047 | Steven Traver                                                                                                                                                |
| 386 |    526.954541 |     82.047243 | Zachary Quigley                                                                                                                                              |
| 387 |     58.892034 |    190.440100 | Michael Scroggie                                                                                                                                             |
| 388 |   1005.932683 |     25.544393 | Jimmy Bernot                                                                                                                                                 |
| 389 |    252.491102 |     15.070211 | Gareth Monger                                                                                                                                                |
| 390 |     15.151830 |    415.882808 | Michelle Site                                                                                                                                                |
| 391 |    735.303255 |    598.272977 | NA                                                                                                                                                           |
| 392 |    238.166419 |     28.622325 | T. Michael Keesey                                                                                                                                            |
| 393 |    195.145603 |    102.880862 | Chris Hay                                                                                                                                                    |
| 394 |    421.315407 |    741.603003 | Matt Crook                                                                                                                                                   |
| 395 |    590.967816 |    160.705081 | Tracy A. Heath                                                                                                                                               |
| 396 |    484.567291 |    577.818116 | NA                                                                                                                                                           |
| 397 |    903.271916 |      6.298683 | Beth Reinke                                                                                                                                                  |
| 398 |    376.196410 |    661.077548 | Caleb M. Brown                                                                                                                                               |
| 399 |     62.561902 |    222.872015 | Collin Gross                                                                                                                                                 |
| 400 |    787.184914 |    731.745027 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 401 |     47.267085 |    175.353063 | Jagged Fang Designs                                                                                                                                          |
| 402 |     50.501602 |    550.082446 | Dean Schnabel                                                                                                                                                |
| 403 |    382.186887 |    649.681873 | NA                                                                                                                                                           |
| 404 |     39.871704 |    747.964476 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                  |
| 405 |    588.657292 |    232.761808 | Becky Barnes                                                                                                                                                 |
| 406 |    671.328408 |    156.637383 | Michelle Site                                                                                                                                                |
| 407 |    860.118118 |    145.714841 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                        |
| 408 |    565.124960 |    594.079828 | Zimices                                                                                                                                                      |
| 409 |    686.020712 |    269.317583 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                        |
| 410 |    358.408906 |    124.315043 | T. Michael Keesey                                                                                                                                            |
| 411 |    554.611083 |      4.578707 | Margot Michaud                                                                                                                                               |
| 412 |    432.392147 |    389.714230 | Matt Crook                                                                                                                                                   |
| 413 |    637.654072 |    649.526153 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                              |
| 414 |    734.630936 |    613.041706 | T. Michael Keesey                                                                                                                                            |
| 415 |    335.707071 |    777.688653 | David Tana                                                                                                                                                   |
| 416 |    646.848647 |    366.837693 | Zimices                                                                                                                                                      |
| 417 |    351.831763 |    156.000570 | Maija Karala                                                                                                                                                 |
| 418 |    741.660892 |    722.137597 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 419 |    346.987464 |    613.985892 | Zimices                                                                                                                                                      |
| 420 |     72.727287 |     46.137257 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 421 |    748.459884 |    307.893350 | Steven Traver                                                                                                                                                |
| 422 |    906.603937 |    250.855555 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 423 |      7.596158 |    562.622651 | Matt Crook                                                                                                                                                   |
| 424 |   1011.781500 |    400.427454 | Michelle Site                                                                                                                                                |
| 425 |    666.909797 |    737.487627 | Ferran Sayol                                                                                                                                                 |
| 426 |     20.007713 |    208.397969 | Iain Reid                                                                                                                                                    |
| 427 |    130.018701 |    336.048376 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                             |
| 428 |    668.178092 |    106.554829 | Michael P. Taylor                                                                                                                                            |
| 429 |      8.383840 |    638.359248 | Zimices                                                                                                                                                      |
| 430 |    975.076832 |    308.888700 | Emily Willoughby                                                                                                                                             |
| 431 |    722.864918 |     45.134631 | Matt Crook                                                                                                                                                   |
| 432 |    327.252282 |     23.301748 | Esme Ashe-Jepson                                                                                                                                             |
| 433 |    316.341602 |     37.868159 | Kamil S. Jaron                                                                                                                                               |
| 434 |     62.057387 |    509.013078 | NA                                                                                                                                                           |
| 435 |    114.625537 |    281.104223 | T. Michael Keesey                                                                                                                                            |
| 436 |    600.632267 |    329.615875 | CNZdenek                                                                                                                                                     |
| 437 |    593.332769 |    148.319365 | Ingo Braasch                                                                                                                                                 |
| 438 |    285.237579 |    545.520820 | NA                                                                                                                                                           |
| 439 |    931.054515 |      3.565380 | Tasman Dixon                                                                                                                                                 |
| 440 |    233.484959 |    218.653028 | Dmitry Bogdanov                                                                                                                                              |
| 441 |    130.743960 |    156.286613 | Benjamint444                                                                                                                                                 |
| 442 |    624.358235 |     80.225622 | Chris huh                                                                                                                                                    |
| 443 |    876.141969 |    173.201430 | Birgit Lang                                                                                                                                                  |
| 444 |     41.504277 |     28.984370 | Matt Crook                                                                                                                                                   |
| 445 |    385.300277 |     38.546768 | Kai R. Caspar                                                                                                                                                |
| 446 |   1000.048282 |    466.347115 | Kamil S. Jaron                                                                                                                                               |
| 447 |    683.458325 |    470.711168 | Chris huh                                                                                                                                                    |
| 448 |    827.388892 |    626.915024 | FJDegrange                                                                                                                                                   |
| 449 |    693.481067 |    287.867722 | T. Michael Keesey                                                                                                                                            |
| 450 |    363.320177 |     19.804310 | Estelle Bourdon                                                                                                                                              |
| 451 |   1012.527865 |    455.163513 | Shyamal                                                                                                                                                      |
| 452 |     64.985888 |    486.393172 | Michael Scroggie                                                                                                                                             |
| 453 |    681.737187 |    401.970766 | Jake Warner                                                                                                                                                  |
| 454 |     59.334573 |    687.320312 | Zimices                                                                                                                                                      |
| 455 |    194.594021 |    141.657863 | Margot Michaud                                                                                                                                               |
| 456 |    292.958186 |    284.405223 | Armin Reindl                                                                                                                                                 |
| 457 |     80.249543 |     24.034914 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                   |
| 458 |    480.141928 |    451.877329 | Michelle Site                                                                                                                                                |
| 459 |    680.161867 |    305.807696 | Zimices                                                                                                                                                      |
| 460 |    345.962730 |     91.014605 | Felix Vaux                                                                                                                                                   |
| 461 |    922.019628 |    283.405930 | Sarah Werning                                                                                                                                                |
| 462 |    397.907962 |    172.442871 | Steven Traver                                                                                                                                                |
| 463 |    356.234671 |    348.159527 | Margot Michaud                                                                                                                                               |
| 464 |    977.911623 |    620.875782 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                     |
| 465 |    509.182983 |    576.345970 | Scott Hartman                                                                                                                                                |
| 466 |     32.759141 |    617.190754 | Maija Karala                                                                                                                                                 |
| 467 |    736.727347 |     63.981981 | SecretJellyMan                                                                                                                                               |
| 468 |    832.454031 |    163.654379 | Scott Reid                                                                                                                                                   |
| 469 |    831.368410 |     38.628141 | Kamil S. Jaron                                                                                                                                               |
| 470 |    277.110956 |    740.770988 | Yan Wong                                                                                                                                                     |
| 471 |    115.967262 |    289.093941 | Julio Garza                                                                                                                                                  |
| 472 |    752.748732 |    597.225745 | NA                                                                                                                                                           |
| 473 |    942.001790 |    645.742473 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 474 |    798.258055 |     24.164227 | Yan Wong                                                                                                                                                     |
| 475 |    591.631470 |    364.624992 | Gareth Monger                                                                                                                                                |
| 476 |    234.443795 |    324.215030 | Dmitry Bogdanov                                                                                                                                              |
| 477 |    146.173458 |    727.554827 | Iain Reid                                                                                                                                                    |
| 478 |    982.702761 |    436.486525 | David Orr                                                                                                                                                    |
| 479 |    253.432392 |    567.988712 | Smokeybjb                                                                                                                                                    |
| 480 |    927.767158 |    703.705795 | Julie Blommaert based on photo by Sofdrakou                                                                                                                  |
| 481 |    348.840926 |    634.882357 | Jagged Fang Designs                                                                                                                                          |
| 482 |    607.671968 |    375.761816 | Zimices                                                                                                                                                      |
| 483 |     20.926664 |    652.469688 | Mathew Wedel                                                                                                                                                 |
| 484 |    988.804353 |    628.987134 | Zimices                                                                                                                                                      |
| 485 |    785.241501 |    540.488716 | Steven Traver                                                                                                                                                |
| 486 |    478.484167 |    431.487159 | Joanna Wolfe                                                                                                                                                 |
| 487 |    768.115002 |    205.007858 | Matt Crook                                                                                                                                                   |
| 488 |    133.281323 |    137.825150 | Maxime Dahirel                                                                                                                                               |
| 489 |    350.398968 |    296.965597 | Matt Crook                                                                                                                                                   |
| 490 |    454.821941 |    575.517572 | Rebecca Groom                                                                                                                                                |
| 491 |    695.927276 |     57.191742 | Iain Reid                                                                                                                                                    |
| 492 |    532.264737 |    109.515718 | Margot Michaud                                                                                                                                               |
| 493 |    936.896077 |    112.637298 | Mathew Wedel                                                                                                                                                 |
| 494 |    683.192416 |    716.224972 | Steven Traver                                                                                                                                                |
| 495 |     39.859491 |    522.257817 | Rebecca Groom                                                                                                                                                |
| 496 |    358.837492 |     86.732042 | T. Michael Keesey (after Tillyard)                                                                                                                           |
| 497 |    390.578072 |    475.422603 | Matt Crook                                                                                                                                                   |
| 498 |    334.590971 |    290.801476 | Christoph Schomburg                                                                                                                                          |
| 499 |    229.842269 |    245.072602 | Mo Hassan                                                                                                                                                    |
| 500 |    485.103438 |    254.262102 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                |
| 501 |    666.350917 |    365.526528 | Margot Michaud                                                                                                                                               |
| 502 |    973.521080 |    404.924311 | Jagged Fang Designs                                                                                                                                          |
| 503 |   1018.555433 |     12.294202 | Birgit Lang                                                                                                                                                  |
| 504 |    342.611236 |    197.577646 | Kamil S. Jaron                                                                                                                                               |
| 505 |     78.574372 |    229.762477 | Markus A. Grohme                                                                                                                                             |
| 506 |    383.239618 |     75.771072 | Yan Wong                                                                                                                                                     |
| 507 |    952.969166 |    320.027408 | Verdilak                                                                                                                                                     |
| 508 |     10.806500 |    768.861186 | Noah Schlottman, photo by Carol Cummings                                                                                                                     |
| 509 |    351.797705 |    241.110534 | Chris huh                                                                                                                                                    |
| 510 |    651.167944 |    342.246737 | T. Michael Keesey (after Kukalová)                                                                                                                           |
| 511 |    711.319220 |     67.982620 | NA                                                                                                                                                           |
| 512 |    909.165407 |    734.627831 | Matt Crook                                                                                                                                                   |
| 513 |    257.086854 |    581.997264 | Steven Traver                                                                                                                                                |
| 514 |    558.608473 |    337.128873 | Zimices                                                                                                                                                      |
| 515 |    534.656001 |    620.960257 | Margot Michaud                                                                                                                                               |
| 516 |    199.646994 |     73.878675 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                             |
| 517 |    165.104641 |    172.251539 | Ignacio Contreras                                                                                                                                            |
| 518 |    805.019067 |    630.076878 | Steven Traver                                                                                                                                                |
| 519 |    421.721284 |    454.556663 | Ville Koistinen and T. Michael Keesey                                                                                                                        |
| 520 |    544.928806 |     54.171053 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 521 |    319.116542 |    780.969261 | Zimices                                                                                                                                                      |
| 522 |   1009.268732 |    300.018736 | Matt Crook                                                                                                                                                   |
| 523 |    568.263916 |    350.811049 | Matt Crook                                                                                                                                                   |
| 524 |    196.048383 |    210.435057 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 525 |    245.314752 |      9.067622 | Jagged Fang Designs                                                                                                                                          |
| 526 |    876.937506 |    550.028437 | CNZdenek                                                                                                                                                     |
| 527 |    794.051583 |    131.908830 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 528 |    342.962152 |    226.254788 | Matt Crook                                                                                                                                                   |
| 529 |    240.747737 |    664.594672 | Ferran Sayol                                                                                                                                                 |
| 530 |    857.331433 |    638.175158 | Katie S. Collins                                                                                                                                             |
| 531 |    463.304335 |    133.361217 | Tasman Dixon                                                                                                                                                 |
| 532 |    512.574882 |    668.897250 | Chris huh                                                                                                                                                    |
| 533 |     68.354418 |    210.577006 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 534 |   1016.426724 |    480.693124 | Steven Traver                                                                                                                                                |
| 535 |    687.867393 |    387.646574 | Kai R. Caspar                                                                                                                                                |
| 536 |     86.853930 |     36.728391 | Chris huh                                                                                                                                                    |
| 537 |    800.266989 |    589.750043 | Scott Hartman                                                                                                                                                |
| 538 |    351.162881 |     19.844678 | Zimices                                                                                                                                                      |
| 539 |     11.416713 |    527.086007 | Gabriele Midolo                                                                                                                                              |
| 540 |    551.309632 |    435.670869 | Ignacio Contreras                                                                                                                                            |
| 541 |    368.667383 |    639.822425 | Zimices                                                                                                                                                      |
| 542 |    302.245777 |    129.597528 | Tauana J. Cunha                                                                                                                                              |
| 543 |    187.179821 |    376.581106 | Ferran Sayol                                                                                                                                                 |
| 544 |    140.271771 |    380.324245 | Beth Reinke                                                                                                                                                  |
| 545 |    330.982670 |    790.916701 | Matt Crook                                                                                                                                                   |
| 546 |    418.446795 |    221.275408 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                  |
| 547 |    834.997719 |    291.919820 | Ghedoghedo                                                                                                                                                   |
| 548 |    939.805777 |    651.420728 | Berivan Temiz                                                                                                                                                |
| 549 |     41.319491 |    445.590692 | Chris huh                                                                                                                                                    |
| 550 |    591.081820 |      5.003291 | Markus A. Grohme                                                                                                                                             |
| 551 |    116.167824 |    639.066219 | Jagged Fang Designs                                                                                                                                          |
| 552 |    847.824124 |    183.361957 | Kent Sorgon                                                                                                                                                  |
| 553 |    518.975043 |     12.880881 | Lily Hughes                                                                                                                                                  |
| 554 |    206.688523 |     32.083732 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                         |
| 555 |    896.604215 |    105.490646 | Steven Traver                                                                                                                                                |
| 556 |    655.979693 |    667.111622 | Jagged Fang Designs                                                                                                                                          |
| 557 |    841.276185 |      7.113553 | Matt Crook                                                                                                                                                   |
| 558 |    391.643427 |    619.888414 | Michelle Site                                                                                                                                                |
| 559 |    303.363773 |    565.142514 | Matt Crook                                                                                                                                                   |
| 560 |    128.954138 |    774.144751 | T. Michael Keesey                                                                                                                                            |
| 561 |    254.440942 |    121.545000 | Jagged Fang Designs                                                                                                                                          |
| 562 |    779.183877 |    174.473975 | Steven Traver                                                                                                                                                |
| 563 |    857.653886 |     40.591550 | Zimices                                                                                                                                                      |
| 564 |    222.935744 |    342.534634 | Michelle Site                                                                                                                                                |
| 565 |    223.622679 |     68.815138 | Scott Hartman                                                                                                                                                |
| 566 |    472.491546 |    341.295475 | Kanchi Nanjo                                                                                                                                                 |
| 567 |    747.218879 |    434.424250 | Dean Schnabel                                                                                                                                                |
| 568 |    986.190618 |    638.369119 | Ignacio Contreras                                                                                                                                            |
| 569 |    253.215543 |    755.713191 | Jagged Fang Designs                                                                                                                                          |
| 570 |    502.728659 |    789.261985 | Margot Michaud                                                                                                                                               |
| 571 |    818.829069 |     15.972876 | Steven Traver                                                                                                                                                |
| 572 |    892.744203 |    715.144573 | Ferran Sayol                                                                                                                                                 |
| 573 |    374.057301 |    155.329214 | T. Michael Keesey                                                                                                                                            |
| 574 |    131.581018 |    505.589108 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                            |
| 575 |    850.873190 |     54.538490 | Scott Reid                                                                                                                                                   |
| 576 |    771.391479 |     81.462956 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                |
| 577 |    746.462163 |     88.964055 | Michelle Site                                                                                                                                                |
| 578 |    584.576030 |    138.136761 | Lafage                                                                                                                                                       |
| 579 |    967.433117 |     67.334932 | FJDegrange                                                                                                                                                   |
| 580 |    546.505245 |     42.771526 | Tyler Greenfield                                                                                                                                             |
| 581 |     71.566760 |    258.229030 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 582 |    748.373827 |    648.284637 | Jack Mayer Wood                                                                                                                                              |
| 583 |    169.738552 |    656.184883 | Emily Willoughby                                                                                                                                             |
| 584 |    766.495178 |    577.583137 | Michelle Site                                                                                                                                                |
| 585 |    229.600676 |    195.685604 | Margot Michaud                                                                                                                                               |
| 586 |    671.262760 |    221.660350 | Matt Crook                                                                                                                                                   |
| 587 |    984.836850 |     15.081719 | Gareth Monger                                                                                                                                                |
| 588 |    504.148389 |    720.914138 | Matt Crook                                                                                                                                                   |
| 589 |    503.307677 |     34.482253 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                    |
| 590 |    890.985121 |    484.498070 | Zimices                                                                                                                                                      |
| 591 |    230.609038 |    124.818235 | Rebecca Groom                                                                                                                                                |
| 592 |    448.548177 |    404.829815 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 593 |    383.138181 |    740.452683 | Peileppe                                                                                                                                                     |
| 594 |    833.900346 |    215.280855 | Jaime Headden                                                                                                                                                |
| 595 |    906.162569 |    630.003123 | Tracy A. Heath                                                                                                                                               |
| 596 |    427.578336 |    438.717448 | T. Michael Keesey                                                                                                                                            |
| 597 |    186.951919 |    249.190541 | Manabu Bessho-Uehara                                                                                                                                         |
| 598 |     40.832868 |    681.946160 | Felix Vaux                                                                                                                                                   |
| 599 |    673.907203 |     91.864891 | Neil Kelley                                                                                                                                                  |
| 600 |    565.977026 |    316.432744 | Jaime Headden                                                                                                                                                |
| 601 |    783.180885 |    671.461670 | Gabriela Palomo-Munoz                                                                                                                                        |
| 602 |    612.117589 |      9.865001 | NA                                                                                                                                                           |
| 603 |    759.591031 |    424.727879 | Margot Michaud                                                                                                                                               |
| 604 |    354.053552 |    207.589435 | Markus A. Grohme                                                                                                                                             |
| 605 |    555.724269 |    154.148840 | CNZdenek                                                                                                                                                     |
| 606 |    828.232284 |    155.909346 | Gareth Monger                                                                                                                                                |
| 607 |    487.106181 |    603.962190 | Matt Hayes                                                                                                                                                   |
| 608 |    917.835153 |    204.914829 | Felix Vaux                                                                                                                                                   |
| 609 |    603.984384 |    235.477333 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                 |
| 610 |    303.511494 |    458.962347 | Ferran Sayol                                                                                                                                                 |
| 611 |     69.012231 |     23.814373 | Matt Crook                                                                                                                                                   |
| 612 |    895.160736 |    726.006104 | Emily Willoughby                                                                                                                                             |
| 613 |    779.695836 |    639.222368 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                             |
| 614 |    809.481934 |      3.795283 | Christoph Schomburg                                                                                                                                          |
| 615 |     73.860204 |    275.169402 | Zimices                                                                                                                                                      |
| 616 |    805.149287 |     47.403048 | Matt Crook                                                                                                                                                   |
| 617 |    539.482337 |    290.227173 | Gabriela Palomo-Munoz                                                                                                                                        |
| 618 |    705.966890 |    375.315718 | NA                                                                                                                                                           |
| 619 |    901.804552 |     98.801504 | Christoph Schomburg                                                                                                                                          |
| 620 |    500.943560 |    443.729638 | NA                                                                                                                                                           |
| 621 |    898.149250 |    498.116780 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                  |
| 622 |    990.346574 |    191.957942 | Joanna Wolfe                                                                                                                                                 |
| 623 |    961.268657 |    343.438819 | Gareth Monger                                                                                                                                                |
| 624 |    406.881188 |    504.798548 | Manabu Sakamoto                                                                                                                                              |
| 625 |     99.868585 |    367.163250 | Tasman Dixon                                                                                                                                                 |
| 626 |    122.614774 |    244.818477 | Margot Michaud                                                                                                                                               |
| 627 |    559.851214 |    101.981459 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
| 628 |    621.043399 |    360.248480 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                |
| 629 |    302.956391 |    239.252769 | Zimices                                                                                                                                                      |
| 630 |    229.120353 |    760.267485 | Lily Hughes                                                                                                                                                  |
| 631 |    742.290517 |    103.385382 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 632 |    408.304723 |     70.577231 | Michael Scroggie                                                                                                                                             |
| 633 |     27.813506 |     44.389026 | Terpsichores                                                                                                                                                 |
| 634 |    991.376082 |    283.494274 | Ignacio Contreras                                                                                                                                            |
| 635 |    130.173181 |    390.924969 | M Kolmann                                                                                                                                                    |
| 636 |    805.410415 |    646.170084 | Margot Michaud                                                                                                                                               |
| 637 |     21.576688 |    610.914634 | Gareth Monger                                                                                                                                                |
| 638 |    161.993900 |    513.584443 | Ignacio Contreras                                                                                                                                            |
| 639 |    612.331151 |     74.359058 | Mike Hanson                                                                                                                                                  |
| 640 |    542.163101 |    408.453827 | Matt Crook                                                                                                                                                   |
| 641 |    159.348333 |    238.211337 | Matt Crook                                                                                                                                                   |
| 642 |    341.169019 |    348.580416 | Crystal Maier                                                                                                                                                |
| 643 |    352.336435 |    274.744439 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 644 |    696.682455 |    772.648147 | Matt Crook                                                                                                                                                   |
| 645 |    103.990548 |    156.886011 | Xavier Giroux-Bougard                                                                                                                                        |
| 646 |    394.351724 |    238.622673 | NA                                                                                                                                                           |
| 647 |    698.787797 |    144.681317 | Jaime Headden                                                                                                                                                |
| 648 |    591.253890 |    593.762714 | Beth Reinke                                                                                                                                                  |
| 649 |    937.541152 |    755.731536 | Mathew Wedel                                                                                                                                                 |
| 650 |    633.135331 |    712.604429 | zoosnow                                                                                                                                                      |
| 651 |    306.552164 |     16.691056 | Emily Willoughby                                                                                                                                             |
| 652 |    882.221257 |    627.205447 | Gareth Monger                                                                                                                                                |
| 653 |    567.719835 |    442.113962 | Margot Michaud                                                                                                                                               |
| 654 |   1010.643263 |    558.884285 | Birgit Lang                                                                                                                                                  |
| 655 |    923.377700 |    669.434512 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                  |
| 656 |      8.753459 |    150.414364 | Peileppe                                                                                                                                                     |
| 657 |   1004.100206 |    738.952207 | Ignacio Contreras                                                                                                                                            |
| 658 |    166.579782 |    750.381298 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 659 |    249.287450 |     50.289211 | Milton Tan                                                                                                                                                   |
| 660 |    588.905775 |    407.506546 | Beth Reinke                                                                                                                                                  |
| 661 |    705.493135 |    391.900358 | Collin Gross                                                                                                                                                 |
| 662 |    696.143621 |    456.112914 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 663 |    479.790614 |    371.365986 | Gabriela Palomo-Munoz                                                                                                                                        |
| 664 |     61.867893 |     48.670478 | Gabriela Palomo-Munoz                                                                                                                                        |
| 665 |    464.792174 |    261.478738 | Robert Gay                                                                                                                                                   |
| 666 |    767.100039 |    287.545740 | Markus A. Grohme                                                                                                                                             |
| 667 |    764.466188 |    651.712218 | Allison Pease                                                                                                                                                |
| 668 |    830.238154 |    266.065234 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                 |
| 669 |    333.835550 |    496.791308 | Chris huh                                                                                                                                                    |
| 670 |    358.064886 |    215.781299 | Scott Hartman                                                                                                                                                |
| 671 |    368.472841 |     77.628026 | Steven Traver                                                                                                                                                |
| 672 |    314.881612 |    415.257258 | Zimices                                                                                                                                                      |
| 673 |    891.125204 |    252.132011 | Scott Hartman                                                                                                                                                |
| 674 |    548.827864 |    331.319210 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                  |
| 675 |    666.767973 |     72.553116 | Chris huh                                                                                                                                                    |
| 676 |    467.690131 |    180.309778 | Matt Crook                                                                                                                                                   |
| 677 |    475.327665 |    248.965143 | Chris huh                                                                                                                                                    |
| 678 |   1014.559775 |    434.072577 | Margot Michaud                                                                                                                                               |
| 679 |    873.404167 |    634.298605 | Julia B McHugh                                                                                                                                               |
| 680 |    996.038631 |    732.414471 | Jagged Fang Designs                                                                                                                                          |
| 681 |    914.579618 |    662.401608 | Christina N. Hodson                                                                                                                                          |
| 682 |    138.535370 |    287.588190 | Matt Wilkins                                                                                                                                                 |
| 683 |    453.670501 |    584.353324 | Ieuan Jones                                                                                                                                                  |
| 684 |    898.555971 |    187.280440 | Rebecca Groom                                                                                                                                                |
| 685 |    560.113377 |    411.203498 | Chris huh                                                                                                                                                    |
| 686 |    210.869079 |    693.589980 | Gabriela Palomo-Munoz                                                                                                                                        |
| 687 |    679.379125 |    168.684469 | Margot Michaud                                                                                                                                               |
| 688 |    991.203533 |    343.863189 | Zimices                                                                                                                                                      |
| 689 |    496.745343 |    346.329337 | Gabriela Palomo-Munoz                                                                                                                                        |
| 690 |     79.175389 |    721.417960 | Arthur S. Brum                                                                                                                                               |
| 691 |    555.431101 |     90.026006 | Michael Scroggie                                                                                                                                             |
| 692 |    791.286186 |     10.850877 | Steven Traver                                                                                                                                                |
| 693 |    185.171940 |    608.096621 | Chris huh                                                                                                                                                    |
| 694 |    376.423208 |    762.838033 | Todd Marshall, vectorized by Zimices                                                                                                                         |
| 695 |    136.816621 |    651.445409 | Harold N Eyster                                                                                                                                              |
| 696 |    355.808600 |     40.753328 | Berivan Temiz                                                                                                                                                |
| 697 |    213.115315 |    171.243992 | Zimices                                                                                                                                                      |
| 698 |    336.242387 |     38.539412 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                             |
| 699 |    147.849312 |    130.030521 | Yan Wong from photo by Gyik Toma                                                                                                                             |
| 700 |    837.458110 |    194.722537 | Steven Traver                                                                                                                                                |
| 701 |    241.430388 |     70.705171 | Andrew A. Farke                                                                                                                                              |
| 702 |    626.353418 |    631.968494 | Gabriela Palomo-Munoz                                                                                                                                        |
| 703 |   1012.904271 |     60.235400 | Jagged Fang Designs                                                                                                                                          |
| 704 |    169.089161 |    502.593402 | Zimices                                                                                                                                                      |
| 705 |    685.848334 |    520.725806 | Zimices                                                                                                                                                      |
| 706 |    389.648207 |    760.321180 | Jaime Headden                                                                                                                                                |
| 707 |    746.258479 |     55.344324 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 708 |    627.752868 |     32.361581 | Zimices                                                                                                                                                      |
| 709 |   1007.823803 |    350.828684 | Francesco “Architetto” Rollandin                                                                                                                             |
| 710 |    149.315562 |    615.248044 | Dean Schnabel                                                                                                                                                |
| 711 |    186.697672 |    526.382854 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                  |
| 712 |    436.184089 |    457.470453 | Shyamal                                                                                                                                                      |
| 713 |    694.022075 |    656.764833 | NA                                                                                                                                                           |
| 714 |    363.026866 |    458.218892 | L. Shyamal                                                                                                                                                   |
| 715 |    839.815379 |    169.568363 | Matt Crook                                                                                                                                                   |
| 716 |     39.794404 |    583.548593 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                |
| 717 |     40.914569 |    271.526416 | Gabriela Palomo-Munoz                                                                                                                                        |
| 718 |    995.459484 |     42.635195 | Zimices                                                                                                                                                      |
| 719 |    440.489310 |    475.661525 | Ignacio Contreras                                                                                                                                            |
| 720 |    461.822332 |    561.748894 | Jakovche                                                                                                                                                     |
| 721 |    201.251715 |    356.529385 | Catherine Yasuda                                                                                                                                             |
| 722 |    384.944871 |    394.984392 | Dann Pigdon                                                                                                                                                  |
| 723 |    132.364207 |    792.227300 | Fernando Campos De Domenico                                                                                                                                  |
| 724 |    360.587616 |    796.508796 | Shyamal                                                                                                                                                      |
| 725 |    301.220196 |    140.087195 | Oscar Sanisidro                                                                                                                                              |
| 726 |    815.406967 |    767.715679 | Gareth Monger                                                                                                                                                |
| 727 |    905.158939 |     16.515972 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 728 |    648.150496 |    618.979933 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                               |
| 729 |    871.505325 |     81.264756 | NA                                                                                                                                                           |
| 730 |    370.091670 |    667.557001 | Chris huh                                                                                                                                                    |
| 731 |    442.913862 |     82.415767 | Jagged Fang Designs                                                                                                                                          |
| 732 |    466.901103 |    794.032500 | Andrew A. Farke                                                                                                                                              |
| 733 |    587.648778 |    250.826879 | NA                                                                                                                                                           |
| 734 |    912.178933 |    599.210255 | Michelle Site                                                                                                                                                |
| 735 |    115.319143 |    766.953537 | Margot Michaud                                                                                                                                               |
| 736 |    762.315046 |    723.424641 | Gareth Monger                                                                                                                                                |
| 737 |    217.435041 |    318.730440 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 738 |    401.963672 |     84.956252 | Steven Traver                                                                                                                                                |
| 739 |    779.074778 |    574.641236 | (after Spotila 2004)                                                                                                                                         |
| 740 |    778.921045 |    214.930073 | Matt Martyniuk                                                                                                                                               |
| 741 |    364.794236 |    673.837763 | Scott Hartman                                                                                                                                                |
| 742 |    890.110332 |    492.684802 | Julio Garza                                                                                                                                                  |
| 743 |     87.892427 |    753.382781 | Matt Crook                                                                                                                                                   |
| 744 |    824.727855 |    207.672324 | Steven Traver                                                                                                                                                |
| 745 |    404.236107 |    362.111211 | Tess Linden                                                                                                                                                  |
| 746 |    415.755337 |    310.526001 | Elisabeth Östman                                                                                                                                             |
| 747 |    984.095131 |    466.223539 | JCGiron                                                                                                                                                      |
| 748 |    507.602969 |    402.492900 | Scott Hartman                                                                                                                                                |
| 749 |    495.435744 |    115.544001 | Matt Crook                                                                                                                                                   |
| 750 |    165.249133 |    299.858930 | Henry Lydecker                                                                                                                                               |
| 751 |    783.592970 |    630.148975 | NA                                                                                                                                                           |
| 752 |    654.717238 |    155.640042 | Nicolas Mongiardino Koch                                                                                                                                     |
| 753 |    624.061572 |    495.739037 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                |
| 754 |    141.484664 |    481.180437 | Jagged Fang Designs                                                                                                                                          |
| 755 |    183.699459 |    698.419425 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                    |
| 756 |    303.394026 |    442.885051 | NA                                                                                                                                                           |
| 757 |    489.849047 |     91.399428 | Tauana J. Cunha                                                                                                                                              |
| 758 |    695.769001 |    431.913577 | Kamil S. Jaron                                                                                                                                               |
| 759 |    233.751230 |    333.843097 | Margot Michaud                                                                                                                                               |
| 760 |    525.453871 |     28.003542 | Margot Michaud                                                                                                                                               |
| 761 |    283.985346 |    426.890155 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 762 |    429.997659 |    510.105533 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 763 |    847.842746 |    488.406383 | Markus A. Grohme                                                                                                                                             |
| 764 |    578.449945 |    100.194635 | Kai R. Caspar                                                                                                                                                |
| 765 |      8.043854 |    336.458935 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                      |
| 766 |    918.441349 |    759.467257 | Yan Wong                                                                                                                                                     |
| 767 |   1008.807924 |    684.938818 | Chloé Schmidt                                                                                                                                                |
| 768 |    592.213352 |    714.186836 | Steven Traver                                                                                                                                                |
| 769 |    663.246869 |    470.570853 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                              |
| 770 |      9.795414 |     80.740799 | NA                                                                                                                                                           |
| 771 |    194.742997 |    181.439046 | Chris huh                                                                                                                                                    |
| 772 |    395.575038 |    281.971834 | Agnello Picorelli                                                                                                                                            |
| 773 |    890.139252 |     88.560014 | Andrés Sánchez                                                                                                                                               |
| 774 |    571.598332 |    241.436577 | Iain Reid                                                                                                                                                    |
| 775 |   1006.865436 |    388.254802 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                             |
| 776 |   1014.874092 |    169.884988 | Michelle Site                                                                                                                                                |
| 777 |    541.514981 |     72.148494 | NA                                                                                                                                                           |
| 778 |    445.204974 |    741.821546 | Matt Crook                                                                                                                                                   |
| 779 |    326.911269 |    257.510295 | Zimices                                                                                                                                                      |
| 780 |    906.324988 |    533.822885 | T. Michael Keesey                                                                                                                                            |
| 781 |    607.632252 |    415.937924 | Paul O. Lewis                                                                                                                                                |
| 782 |    460.585433 |      9.800222 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                          |
| 783 |    270.133192 |    174.930621 | Matt Crook                                                                                                                                                   |
| 784 |    154.393210 |    787.109060 | Ferran Sayol                                                                                                                                                 |
| 785 |    860.890320 |    515.121843 | Steven Traver                                                                                                                                                |
| 786 |    178.670324 |    437.673884 | Chase Brownstein                                                                                                                                             |
| 787 |    295.695366 |    362.884415 | Matt Crook                                                                                                                                                   |
| 788 |    681.760073 |     98.586848 | Maija Karala                                                                                                                                                 |
| 789 |    104.182360 |    404.082973 | Shyamal                                                                                                                                                      |
| 790 |      7.638485 |    664.999903 | Zimices                                                                                                                                                      |
| 791 |    874.477587 |    792.675678 | Scott Hartman                                                                                                                                                |
| 792 |    186.166176 |    130.638751 | Mathew Wedel                                                                                                                                                 |
| 793 |    833.243405 |    684.549902 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 794 |    865.338299 |    524.329445 | Chris huh                                                                                                                                                    |
| 795 |    274.771715 |    758.440418 | L. Shyamal                                                                                                                                                   |
| 796 |    191.687246 |    360.684039 | Zimices                                                                                                                                                      |
| 797 |    583.549744 |     67.065639 | Jack Mayer Wood                                                                                                                                              |
| 798 |    182.933186 |    582.409328 | Maija Karala                                                                                                                                                 |
| 799 |    730.430435 |     78.948178 | T. Michael Keesey                                                                                                                                            |
| 800 |    527.583618 |    637.952898 | Scott Hartman                                                                                                                                                |
| 801 |     47.515763 |     40.576680 | Kai R. Caspar                                                                                                                                                |
| 802 |    177.192570 |    386.897396 | Matt Crook                                                                                                                                                   |
| 803 |    815.983532 |    289.393084 | Margot Michaud                                                                                                                                               |
| 804 |    906.033507 |    218.283767 | Gareth Monger                                                                                                                                                |
| 805 |    783.171578 |    292.410128 | Daniel Jaron                                                                                                                                                 |
| 806 |     10.270270 |    788.646354 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                            |
| 807 |    191.821946 |    195.936466 | Zimices                                                                                                                                                      |
| 808 |    551.350605 |    145.585391 | Robert Gay                                                                                                                                                   |
| 809 |    351.844474 |    780.344700 | Kent Elson Sorgon                                                                                                                                            |
| 810 |    467.133650 |    145.510572 | Yan Wong                                                                                                                                                     |
| 811 |    146.757587 |    769.266326 | Scott Hartman                                                                                                                                                |
| 812 |    455.442376 |    277.258604 | Margot Michaud                                                                                                                                               |
| 813 |    688.022534 |    698.958723 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                           |
| 814 |    668.500477 |    784.353525 | Sarah Werning                                                                                                                                                |
| 815 |    372.248157 |    447.651018 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 816 |    924.265825 |    794.498524 | Matt Celeskey                                                                                                                                                |
| 817 |    235.635333 |    617.717386 | Tasman Dixon                                                                                                                                                 |
| 818 |    379.174825 |    244.941880 | Darius Nau                                                                                                                                                   |
| 819 |    948.076546 |    427.553607 | Beth Reinke                                                                                                                                                  |
| 820 |    933.891435 |    296.902455 | L. Shyamal                                                                                                                                                   |
| 821 |    282.872219 |    356.099198 | Jake Warner                                                                                                                                                  |
| 822 |    436.644047 |    486.640449 | Zimices                                                                                                                                                      |
| 823 |     98.525626 |    302.378525 | B Kimmel                                                                                                                                                     |
| 824 |    650.313882 |    485.859385 | Matt Crook                                                                                                                                                   |
| 825 |    390.300962 |    500.699393 | Michael Scroggie                                                                                                                                             |
| 826 |    265.970267 |    588.851772 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                               |
| 827 |    212.586194 |    491.167422 | Matt Crook                                                                                                                                                   |
| 828 |    534.410840 |     94.768712 | Matt Crook                                                                                                                                                   |
| 829 |     95.432794 |     23.643697 | Scott Hartman                                                                                                                                                |
| 830 |     25.860240 |    216.403278 | Almandine (vectorized by T. Michael Keesey)                                                                                                                  |
| 831 |    705.900750 |    408.048496 | Ferran Sayol                                                                                                                                                 |
| 832 |    599.282707 |    347.099173 | Iain Reid                                                                                                                                                    |
| 833 |    641.039454 |     96.711000 | Margot Michaud                                                                                                                                               |
| 834 |    566.466828 |    630.757904 | Yan Wong                                                                                                                                                     |
| 835 |   1006.701787 |    634.175135 | Matt Martyniuk                                                                                                                                               |
| 836 |    886.676181 |    585.483470 | Scott Hartman                                                                                                                                                |
| 837 |    653.328312 |    301.002969 | Gareth Monger                                                                                                                                                |
| 838 |    894.952783 |    567.160695 | Félix Landry Yuan                                                                                                                                            |
| 839 |    251.265574 |    288.496968 | Harold N Eyster                                                                                                                                              |
| 840 |    727.007866 |    785.426708 | Tasman Dixon                                                                                                                                                 |
| 841 |    283.422296 |    134.274485 | Tasman Dixon                                                                                                                                                 |
| 842 |    173.074342 |    778.639585 | Matt Crook                                                                                                                                                   |
| 843 |    928.019776 |    716.074485 | NA                                                                                                                                                           |
| 844 |    648.379068 |    352.169616 | Steven Traver                                                                                                                                                |
| 845 |    441.279235 |    792.311005 | Scott Hartman                                                                                                                                                |
| 846 |    849.690881 |    576.444280 | Chloé Schmidt                                                                                                                                                |
| 847 |    727.504850 |    719.298799 | Matt Crook                                                                                                                                                   |
| 848 |    743.384031 |    545.710191 | Markus A. Grohme                                                                                                                                             |
| 849 |    809.943803 |     74.500127 | Matt Crook                                                                                                                                                   |
| 850 |    137.974549 |    684.218900 | Scott Hartman                                                                                                                                                |
| 851 |     99.626167 |    339.795259 | T. Michael Keesey                                                                                                                                            |
| 852 |    272.068142 |    606.969600 | Collin Gross                                                                                                                                                 |
| 853 |    319.571366 |    771.969136 | Zimices                                                                                                                                                      |
| 854 |    288.893504 |    791.652099 | Jaime Headden                                                                                                                                                |
| 855 |    849.417275 |    204.447827 | Matt Crook                                                                                                                                                   |
| 856 |   1004.858385 |    644.075157 | Markus A. Grohme                                                                                                                                             |
| 857 |    948.204686 |    297.957889 | Jaime Headden                                                                                                                                                |
| 858 |    967.877976 |    296.793298 | Margot Michaud                                                                                                                                               |
| 859 |    699.398886 |    717.830394 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                  |
| 860 |     29.325702 |    262.933901 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                             |
| 861 |    449.407740 |    215.571518 | Margot Michaud                                                                                                                                               |
| 862 |    288.687555 |    579.102998 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                           |
| 863 |    379.935464 |    629.988823 | Lukasiniho                                                                                                                                                   |
| 864 |    414.933122 |    467.150838 | Gabriela Palomo-Munoz                                                                                                                                        |
| 865 |    663.699651 |    419.876792 | Matt Crook                                                                                                                                                   |
| 866 |    646.202034 |    742.043035 | Dean Schnabel                                                                                                                                                |
| 867 |    446.492849 |    374.014720 | Matt Crook                                                                                                                                                   |
| 868 |    382.973147 |    793.627207 | Felix Vaux                                                                                                                                                   |
| 869 |    714.968289 |    217.051774 | Carlos Cano-Barbacil                                                                                                                                         |
| 870 |    197.669662 |    663.529349 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                              |
| 871 |    339.078116 |    743.409784 | Zimices                                                                                                                                                      |
| 872 |    459.339805 |    228.616809 | Gareth Monger                                                                                                                                                |
| 873 |    845.559465 |    536.053005 | Zimices                                                                                                                                                      |
| 874 |    320.833981 |    248.554748 | T. Michael Keesey                                                                                                                                            |
| 875 |    870.884054 |    238.809243 | Matt Crook                                                                                                                                                   |
| 876 |    710.705309 |    678.366739 | Scott Hartman                                                                                                                                                |
| 877 |    502.147306 |    602.880140 | Falconaumanni and T. Michael Keesey                                                                                                                          |
| 878 |    892.910529 |    535.018479 | Steven Traver                                                                                                                                                |
| 879 |    301.392731 |    603.627599 | Benjamin Monod-Broca                                                                                                                                         |
| 880 |    375.566178 |    347.320147 | Tasman Dixon                                                                                                                                                 |
| 881 |    271.468110 |    560.534535 | Gareth Monger                                                                                                                                                |
| 882 |    345.954820 |    257.057714 | Ferran Sayol                                                                                                                                                 |
| 883 |    328.318468 |    234.448328 | T. Michael Keesey                                                                                                                                            |
| 884 |      4.204803 |    212.072758 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                  |
| 885 |    112.561114 |    653.601114 | Matt Crook                                                                                                                                                   |
| 886 |   1015.562102 |    706.860276 | T. Michael Keesey                                                                                                                                            |
| 887 |    391.058289 |      7.730478 | Ferran Sayol                                                                                                                                                 |
| 888 |    163.039011 |    608.510106 | Birgit Lang                                                                                                                                                  |
| 889 |    325.272942 |    744.569714 | Kai R. Caspar                                                                                                                                                |
| 890 |     95.264211 |    536.593104 | Dean Schnabel                                                                                                                                                |
| 891 |    901.203087 |    270.705751 | NA                                                                                                                                                           |
| 892 |    350.040646 |     79.458962 | Steven Traver                                                                                                                                                |
| 893 |    151.209839 |    537.037162 | Sergio A. Muñoz-Gómez                                                                                                                                        |
| 894 |    883.757437 |    709.972327 | Gabriela Palomo-Munoz                                                                                                                                        |
| 895 |    543.620487 |    314.922526 | Yan Wong                                                                                                                                                     |
| 896 |    985.935749 |    124.726164 | Margot Michaud                                                                                                                                               |
| 897 |     55.732310 |    693.635856 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                             |
| 898 |    491.482105 |    403.116495 | Tasman Dixon                                                                                                                                                 |
| 899 |    771.206440 |    554.443905 | Andrew A. Farke                                                                                                                                              |
| 900 |    864.767749 |     88.524152 | NA                                                                                                                                                           |
| 901 |     52.210495 |    592.338126 | Christoph Schomburg                                                                                                                                          |
| 902 |    583.643993 |    350.983300 | Steven Traver                                                                                                                                                |
| 903 |    995.496821 |    360.584607 | Zimices                                                                                                                                                      |
| 904 |    323.343330 |    482.507216 | Iain Reid                                                                                                                                                    |
| 905 |    877.177125 |    186.139618 | Mo Hassan                                                                                                                                                    |
| 906 |    316.997529 |    290.895016 | Steven Haddock • Jellywatch.org                                                                                                                              |
| 907 |    519.268626 |    683.812732 | Jagged Fang Designs                                                                                                                                          |
| 908 |    248.496849 |    201.075102 | Margot Michaud                                                                                                                                               |
| 909 |    824.455866 |    790.738001 | Joanna Wolfe                                                                                                                                                 |
| 910 |    204.061918 |    507.212986 | Noah Schlottman, photo from Casey Dunn                                                                                                                       |
| 911 |    219.297418 |    461.677713 | Tauana J. Cunha                                                                                                                                              |
| 912 |    146.487808 |    142.209473 | Ferran Sayol                                                                                                                                                 |
| 913 |    272.534330 |    466.884226 | NA                                                                                                                                                           |
| 914 |    664.422565 |    251.491177 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
| 915 |   1012.995739 |    273.923733 | Rebecca Groom                                                                                                                                                |
| 916 |    272.603301 |    240.881390 | Steven Traver                                                                                                                                                |
| 917 |     94.685944 |    210.875384 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                    |
| 918 |    260.450244 |    421.255218 | Mike Hanson                                                                                                                                                  |
| 919 |    888.837988 |    178.075733 | Andrew A. Farke                                                                                                                                              |
| 920 |    338.766376 |    583.728664 | T. Michael Keesey                                                                                                                                            |

    #> Your tweet has been posted!
