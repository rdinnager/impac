
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

Gareth Monger, Evan Swigart (photography) and T. Michael Keesey
(vectorization), François Michonneau, Andy Wilson, Nobu Tamura
(vectorized by T. Michael Keesey), Matt Crook, L. Shyamal, Jiekun He,
Caroline Harding, MAF (vectorized by T. Michael Keesey), Zimices, Erika
Schumacher, Matt Celeskey, Birgit Lang, Tony Ayling, Margot Michaud,
John Curtis (vectorized by T. Michael Keesey), Tauana J. Cunha, Daniel
Stadtmauer, Sarah Alewijnse, Chris huh, Notafly (vectorized by T.
Michael Keesey), Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Jerry Oldenettel
(vectorized by T. Michael Keesey), Sean McCann, Steven Traver, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Griensteidl and T. Michael
Keesey, Markus A. Grohme, . Original drawing by M. Antón, published in
Montoya and Morales 1984. Vectorized by O. Sanisidro, Oren Peles /
vectorized by Yan Wong, Maxime Dahirel (digitisation), Kees van
Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication),
Gustav Mützel, Kamil S. Jaron, Jagged Fang Designs, Scott Hartman,
Tasman Dixon, Stanton F. Fink (vectorized by T. Michael Keesey), Nina
Skinner, Armin Reindl, Duane Raver (vectorized by T. Michael Keesey),
Iain Reid, Michelle Site, Robbie N. Cada (vectorized by T. Michael
Keesey), Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael
Keesey), Christoph Schomburg, T. Michael Keesey, Pranav Iyer (grey
ideas), Christopher Chávez, Jaime Headden, , Ferran Sayol, Zachary
Quigley, Maxime Dahirel, Scott Reid, Tracy A. Heath, Dean Schnabel, T.
Michael Keesey and Tanetahi, Michele M Tobias from an image By Dcrjsr -
Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Timothy
Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy
J. Bartley (silhouette), T. Michael Keesey (after James & al.), Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), FJDegrange, T. Michael Keesey (after A. Y.
Ivantsov), Chris Jennings (Risiatto), Beth Reinke, Kanchi Nanjo,
Meliponicultor Itaymbere, Caleb M. Brown, Lafage, david maas / dave
hone, Andrew A. Farke, Xavier Giroux-Bougard, Chris Hay, Sharon
Wegner-Larsen, Kai R. Caspar, Jon M Laurent, Gopal Murali, Lauren
Anderson, Inessa Voet, Hans Hillewaert (vectorized by T. Michael
Keesey), Philippe Janvier (vectorized by T. Michael Keesey), Michael
Scroggie, from original photograph by John Bettaso, USFWS (original
photograph in public domain)., Jose Carlos Arenas-Monroy, Ignacio
Contreras, Sarah Werning, Prathyush Thomas, Gabriela Palomo-Munoz,
Mali’o Kodis, photograph by Derek Keats
(<http://www.flickr.com/photos/dkeats/>), Noah Schlottman, Yan Wong,
Eyal Bartov, Nobu Tamura, vectorized by Zimices, Lukasiniho, George
Edward Lodge (modified by T. Michael Keesey), Tess Linden, CNZdenek,
Gordon E. Robertson, Jimmy Bernot, Martin R. Smith, DW Bapst (modified
from Bulman, 1970), Sibi (vectorized by T. Michael Keesey), Collin
Gross, V. Deepak, Melissa Broussard, Harold N Eyster, Tony Ayling
(vectorized by Milton Tan), Jessica Rick, Katie S. Collins, Alexander
Schmidt-Lebuhn, E. D. Cope (modified by T. Michael Keesey, Michael P.
Taylor & Matthew J. Wedel), Fernando Carezzano, Mo Hassan, Rachel Shoop,
Ludwik Gąsiorowski, Emily Willoughby, Jaime Headden, modified by T.
Michael Keesey, Verdilak, Bruno C. Vellutini, Alexandra van der Geer,
Bryan Carstens, Tyler Greenfield, Josefine Bohr Brask, Jesús Gómez,
vectorized by Zimices, Nobu Tamura, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Zimices, based in Mauricio Antón skeletal, Cesar Julian, Michele Tobias,
Roger Witter, vectorized by Zimices, Roberto Díaz Sibaja, Becky Barnes,
T. Tischler, Chase Brownstein, Alex Slavenko, Lily Hughes, Michael
Ströck (vectorized by T. Michael Keesey), Courtney Rockenbach, Jan
Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Matt Martyniuk, Brad McFeeters (vectorized by T. Michael
Keesey), Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J.
Bartley (silhouette), Benjamin Monod-Broca, Timothy Knepp (vectorized by
T. Michael Keesey), kreidefossilien.de, Blair Perry, Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, FunkMonk, Abraão
Leite, Baheerathan Murugavel, Ralf Janssen, Nikola-Michael Prpic & Wim
G. M. Damen (vectorized by T. Michael Keesey), Joseph J. W. Sertich,
Mark A. Loewen, David Sim (photograph) and T. Michael Keesey
(vectorization), Maija Karala, Agnello Picorelli, Natasha Vitek,
Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja,
Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Michele
M Tobias, Julio Garza, Henry Lydecker, Servien (vectorized by T. Michael
Keesey), Stuart Humphries, Florian Pfaff, Roberto Diaz Sibaja, based on
Domser, C. Camilo Julián-Caballero, Martin Kevil, Claus Rebler, Joanna
Wolfe, Cristopher Silva, Ieuan Jones, Kosta Mumcuoglu (vectorized by T.
Michael Keesey), Hans Hillewaert (photo) and T. Michael Keesey
(vectorization), TaraTaylorDesign, JCGiron, Robert Bruce Horsfall,
vectorized by Zimices, Alexis Simon, S.Martini, Sarefo (vectorized by T.
Michael Keesey), Julia B McHugh, Kimberly Haddrell, Jaime Chirinos
(vectorized by T. Michael Keesey), Mattia Menchetti, Andreas Preuss /
marauder, Dmitry Bogdanov, Wayne Decatur, Zsoldos Márton (vectorized by
T. Michael Keesey), Andrew Farke and Joseph Sertich, Dmitry Bogdanov,
vectorized by Zimices, Jake Warner, Gabriel Lio, vectorized by Zimices,
Caleb M. Gordon, Hugo Gruson, Ville Koistinen and T. Michael Keesey,
Ghedoghedo (vectorized by T. Michael Keesey), Dave Angelini, Michael
Scroggie, Mason McNair, Carlos Cano-Barbacil, Mali’o Kodis, image by
Rebecca Ritger, Owen Jones (derived from a CC-BY 2.0 photograph by Paulo
B. Chaves), LeonardoG (photography) and T. Michael Keesey
(vectorization), Conty (vectorized by T. Michael Keesey), Christine
Axon, T. Michael Keesey (vectorization) and HuttyMcphoo (photography),
E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T.
Michael Keesey), Terpsichores, Marmelad, Wynston Cooper (photo) and
Albertonykus (silhouette), Karina Garcia, xgirouxb, Andrés Sánchez,
Henry Fairfield Osborn, vectorized by Zimices, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Nobu Tamura (modified by T. Michael Keesey), Benjamint444,
Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey), Brian
Gratwicke (photo) and T. Michael Keesey (vectorization), Matt Wilkins,
Danielle Alba, Tomas Willems (vectorized by T. Michael Keesey), Shyamal,
Lisa Byrne, FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey),
T. Michael Keesey (after Heinrich Harder), Rebecca Groom, Darren Naish
(vectorized by T. Michael Keesey), Apokryltaros (vectorized by T.
Michael Keesey), Smokeybjb, Craig Dylke, Roderic Page and Lois Page,
(after McCulloch 1908), Obsidian Soul (vectorized by T. Michael Keesey),
Chuanixn Yu, Jaime A. Headden (vectorized by T. Michael Keesey),
Riccardo Percudani, Nancy Wyman (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Elisabeth Östman, David Orr, Smokeybjb
(vectorized by T. Michael Keesey), Noah Schlottman, photo from Casey
Dunn, Alexandre Vong, Jessica Anne Miller, Mariana Ruiz (vectorized by
T. Michael Keesey), Felix Vaux, Mykle Hoban, Maha Ghazal, Stacy Spensley
(Modified), Vijay Cavale (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, M. A. Broussard, Robert Bruce Horsfall
(vectorized by William Gearty), Louis Ranjard, Milton Tan, Nobu Tamura,
modified by Andrew A. Farke, Didier Descouens (vectorized by T. Michael
Keesey), Lukas Panzarin (vectorized by T. Michael Keesey), Qiang Ou,
Raven Amos, Michael P. Taylor, Dann Pigdon, Mali’o Kodis, photograph by
P. Funch and R.M. Kristensen, Anthony Caravaggi, Lukas Panzarin, Darren
Naish (vectorize by T. Michael Keesey), Rainer Schoch, Air Kebir NRG,
Maxwell Lefroy (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     804.67660 |    208.182949 | Gareth Monger                                                                                                                                                         |
|   2 |     645.00316 |    474.854774 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
|   3 |     227.93152 |    653.301730 | Gareth Monger                                                                                                                                                         |
|   4 |     734.53047 |    624.402958 | François Michonneau                                                                                                                                                   |
|   5 |     459.11008 |    114.139410 | Andy Wilson                                                                                                                                                           |
|   6 |     361.53578 |    641.067726 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|   7 |      91.09447 |    463.388680 | NA                                                                                                                                                                    |
|   8 |     151.56463 |    220.590284 | Matt Crook                                                                                                                                                            |
|   9 |     940.71312 |    215.421301 | L. Shyamal                                                                                                                                                            |
|  10 |     356.89361 |    335.301921 | Jiekun He                                                                                                                                                             |
|  11 |     437.54150 |    234.868100 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
|  12 |     481.24106 |    430.018685 | Zimices                                                                                                                                                               |
|  13 |     838.92640 |     58.165897 | Erika Schumacher                                                                                                                                                      |
|  14 |     625.93810 |    111.139550 | Matt Celeskey                                                                                                                                                         |
|  15 |     203.87227 |     75.693563 | Birgit Lang                                                                                                                                                           |
|  16 |     128.07661 |    502.503438 | Matt Crook                                                                                                                                                            |
|  17 |     842.55398 |    380.973361 | Matt Crook                                                                                                                                                            |
|  18 |     249.77422 |    248.609634 | Tony Ayling                                                                                                                                                           |
|  19 |     369.73507 |    438.294703 | Andy Wilson                                                                                                                                                           |
|  20 |     136.84704 |    611.901263 | Margot Michaud                                                                                                                                                        |
|  21 |     390.45621 |    524.704235 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
|  22 |     925.95831 |    297.877495 | Tauana J. Cunha                                                                                                                                                       |
|  23 |     927.63017 |    528.683299 | Daniel Stadtmauer                                                                                                                                                     |
|  24 |      84.62072 |    422.928377 | Sarah Alewijnse                                                                                                                                                       |
|  25 |     550.55330 |    186.380656 | Chris huh                                                                                                                                                             |
|  26 |     521.73535 |    563.451125 | Margot Michaud                                                                                                                                                        |
|  27 |     345.97924 |    138.295320 | Andy Wilson                                                                                                                                                           |
|  28 |     253.33201 |    461.082406 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
|  29 |     563.48654 |    346.663199 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  30 |     952.11154 |     90.201639 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
|  31 |     571.92014 |    109.597871 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
|  32 |     142.97407 |    734.148045 | Matt Crook                                                                                                                                                            |
|  33 |     671.23471 |    204.598121 | Sean McCann                                                                                                                                                           |
|  34 |     962.88665 |    368.359772 | Steven Traver                                                                                                                                                         |
|  35 |     237.82856 |    628.602777 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  36 |     631.61706 |    315.356200 | Griensteidl and T. Michael Keesey                                                                                                                                     |
|  37 |     531.46281 |    473.113892 | Markus A. Grohme                                                                                                                                                      |
|  38 |     723.77440 |    444.891350 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
|  39 |     462.81214 |    724.658081 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
|  40 |     313.15389 |    743.817489 | Steven Traver                                                                                                                                                         |
|  41 |      69.94689 |    154.719857 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
|  42 |     954.70382 |    607.064863 | Gustav Mützel                                                                                                                                                         |
|  43 |     452.36611 |    370.688676 | Kamil S. Jaron                                                                                                                                                        |
|  44 |      17.93045 |    626.269218 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  45 |     618.65050 |    747.125122 | Margot Michaud                                                                                                                                                        |
|  46 |     896.30803 |    463.644556 | Matt Crook                                                                                                                                                            |
|  47 |     850.02446 |    139.732312 | Jagged Fang Designs                                                                                                                                                   |
|  48 |     684.13785 |     41.795890 | Scott Hartman                                                                                                                                                         |
|  49 |     148.94991 |    348.883989 | Scott Hartman                                                                                                                                                         |
|  50 |     106.27597 |    663.224159 | Chris huh                                                                                                                                                             |
|  51 |     720.11846 |    334.973683 | Jagged Fang Designs                                                                                                                                                   |
|  52 |     917.17195 |    729.948196 | Tasman Dixon                                                                                                                                                          |
|  53 |     692.34740 |    704.778194 | Steven Traver                                                                                                                                                         |
|  54 |     496.57550 |     35.200392 | Erika Schumacher                                                                                                                                                      |
|  55 |     763.18898 |    747.801661 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
|  56 |     745.88121 |    300.257078 | Jagged Fang Designs                                                                                                                                                   |
|  57 |     793.01290 |     22.781903 | Scott Hartman                                                                                                                                                         |
|  58 |     423.95401 |    731.322929 | Nina Skinner                                                                                                                                                          |
|  59 |     386.80583 |     12.803224 | Armin Reindl                                                                                                                                                          |
|  60 |     997.95857 |    720.198403 | Gareth Monger                                                                                                                                                         |
|  61 |     411.75912 |    488.078058 | Scott Hartman                                                                                                                                                         |
|  62 |      98.63950 |     20.507391 | Jagged Fang Designs                                                                                                                                                   |
|  63 |     876.09477 |     26.896214 | Markus A. Grohme                                                                                                                                                      |
|  64 |     177.84115 |    279.084840 | Erika Schumacher                                                                                                                                                      |
|  65 |     466.44760 |    646.821823 | Jagged Fang Designs                                                                                                                                                   |
|  66 |     318.07784 |    260.717901 | Markus A. Grohme                                                                                                                                                      |
|  67 |     936.85639 |    156.149216 | Zimices                                                                                                                                                               |
|  68 |     342.89225 |    572.898841 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
|  69 |     133.28943 |    551.546909 | Iain Reid                                                                                                                                                             |
|  70 |     479.58856 |    296.231516 | Markus A. Grohme                                                                                                                                                      |
|  71 |      28.26300 |    261.815068 | NA                                                                                                                                                                    |
|  72 |     769.39525 |    125.321424 | Jagged Fang Designs                                                                                                                                                   |
|  73 |     124.06892 |    398.522704 | Michelle Site                                                                                                                                                         |
|  74 |     535.58943 |    263.474968 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  75 |     443.98605 |    171.186857 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
|  76 |     787.69210 |    538.937639 | Christoph Schomburg                                                                                                                                                   |
|  77 |     513.69316 |    511.736336 | Jagged Fang Designs                                                                                                                                                   |
|  78 |     268.29294 |    678.859823 | Markus A. Grohme                                                                                                                                                      |
|  79 |     864.93454 |    783.781211 | T. Michael Keesey                                                                                                                                                     |
|  80 |     227.51374 |    325.864924 | Pranav Iyer (grey ideas)                                                                                                                                              |
|  81 |     382.68395 |    386.218665 | Zimices                                                                                                                                                               |
|  82 |     939.07204 |    564.981638 | Christopher Chávez                                                                                                                                                    |
|  83 |     304.60429 |     82.911339 | Matt Crook                                                                                                                                                            |
|  84 |     973.34265 |    476.401663 | Steven Traver                                                                                                                                                         |
|  85 |     488.02932 |    683.298987 | Jaime Headden                                                                                                                                                         |
|  86 |     985.02883 |    785.491372 | Chris huh                                                                                                                                                             |
|  87 |     631.58731 |    379.339748 | Steven Traver                                                                                                                                                         |
|  88 |     504.06788 |    602.474861 |                                                                                                                                                                       |
|  89 |     345.03342 |     52.865146 | Ferran Sayol                                                                                                                                                          |
|  90 |     291.31129 |    481.482232 | Zachary Quigley                                                                                                                                                       |
|  91 |     977.00441 |     28.990278 | Zimices                                                                                                                                                               |
|  92 |     354.77382 |    680.016968 | Chris huh                                                                                                                                                             |
|  93 |      49.76540 |    373.651166 | Maxime Dahirel                                                                                                                                                        |
|  94 |     395.92655 |    650.903643 | Matt Crook                                                                                                                                                            |
|  95 |     693.37825 |    525.819849 | Ferran Sayol                                                                                                                                                          |
|  96 |     882.83817 |    400.613128 | Scott Reid                                                                                                                                                            |
|  97 |      45.67361 |    747.774233 | Tracy A. Heath                                                                                                                                                        |
|  98 |     885.51525 |    236.119442 | Zimices                                                                                                                                                               |
|  99 |     960.12687 |    501.846590 | Dean Schnabel                                                                                                                                                         |
| 100 |     378.69595 |    345.689898 | T. Michael Keesey and Tanetahi                                                                                                                                        |
| 101 |     843.24804 |    192.826016 | Markus A. Grohme                                                                                                                                                      |
| 102 |     554.31737 |    752.155451 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 103 |      38.27433 |    479.373473 | Zimices                                                                                                                                                               |
| 104 |     822.56537 |    451.141764 | Ferran Sayol                                                                                                                                                          |
| 105 |     308.43851 |    231.042952 | Matt Crook                                                                                                                                                            |
| 106 |      18.38162 |    333.143136 | T. Michael Keesey                                                                                                                                                     |
| 107 |     574.42673 |     63.032241 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 108 |      40.88912 |    597.951008 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 109 |      68.50222 |     64.423200 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 110 |     562.92877 |     12.877615 | Matt Crook                                                                                                                                                            |
| 111 |     974.34354 |    412.233754 | FJDegrange                                                                                                                                                            |
| 112 |     706.16164 |     93.846803 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 113 |      64.68649 |    649.592162 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 114 |    1007.36519 |    178.597839 | Jagged Fang Designs                                                                                                                                                   |
| 115 |     261.85111 |    700.656830 | Margot Michaud                                                                                                                                                        |
| 116 |     358.75861 |    603.797232 | Chris Jennings (Risiatto)                                                                                                                                             |
| 117 |     299.45714 |    550.500590 | Margot Michaud                                                                                                                                                        |
| 118 |      66.26895 |    616.545555 | Beth Reinke                                                                                                                                                           |
| 119 |     139.51649 |    438.851607 | Kanchi Nanjo                                                                                                                                                          |
| 120 |     519.58132 |    713.410669 | Gareth Monger                                                                                                                                                         |
| 121 |     854.87103 |    708.305994 | Meliponicultor Itaymbere                                                                                                                                              |
| 122 |      49.13887 |    551.176921 | Scott Hartman                                                                                                                                                         |
| 123 |      49.99837 |    673.515816 | Caleb M. Brown                                                                                                                                                        |
| 124 |     727.89980 |     82.820494 | Lafage                                                                                                                                                                |
| 125 |     981.22653 |    511.784158 | david maas / dave hone                                                                                                                                                |
| 126 |     182.29539 |    434.973246 | Zimices                                                                                                                                                               |
| 127 |     528.03232 |    656.354346 | Zimices                                                                                                                                                               |
| 128 |     835.87629 |    714.157612 | Andrew A. Farke                                                                                                                                                       |
| 129 |     377.48841 |    266.962889 | Xavier Giroux-Bougard                                                                                                                                                 |
| 130 |      24.70134 |    466.279646 | Markus A. Grohme                                                                                                                                                      |
| 131 |     180.36698 |     14.776915 | Chris Hay                                                                                                                                                             |
| 132 |     270.65949 |     24.051289 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 133 |      90.32729 |     95.427582 | Sharon Wegner-Larsen                                                                                                                                                  |
| 134 |     916.66014 |    609.215397 | Caleb M. Brown                                                                                                                                                        |
| 135 |     782.14277 |    511.438637 | Dean Schnabel                                                                                                                                                         |
| 136 |     845.49251 |    553.377645 | NA                                                                                                                                                                    |
| 137 |     354.26349 |     38.743988 | Matt Crook                                                                                                                                                            |
| 138 |     204.98697 |    235.895649 | Kai R. Caspar                                                                                                                                                         |
| 139 |     627.83134 |     73.928897 | Jon M Laurent                                                                                                                                                         |
| 140 |     510.76094 |    675.651375 | Gopal Murali                                                                                                                                                          |
| 141 |      80.92695 |    222.424745 | Lauren Anderson                                                                                                                                                       |
| 142 |     300.83979 |    428.788683 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 143 |     587.84759 |    376.380771 | Steven Traver                                                                                                                                                         |
| 144 |     829.53336 |    290.161652 | Inessa Voet                                                                                                                                                           |
| 145 |     996.81692 |    521.165692 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 146 |     275.86473 |    196.894601 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 147 |     224.27713 |    218.219172 | Michelle Site                                                                                                                                                         |
| 148 |     874.12742 |    408.348716 | Chris huh                                                                                                                                                             |
| 149 |     397.01428 |    129.712637 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 150 |     707.55181 |    309.136614 | Kamil S. Jaron                                                                                                                                                        |
| 151 |     208.40524 |    711.708371 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 152 |    1014.37570 |    465.808358 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 153 |     851.15635 |    456.066808 | Ignacio Contreras                                                                                                                                                     |
| 154 |     672.50064 |    786.575061 | Sarah Werning                                                                                                                                                         |
| 155 |     923.41380 |     45.038086 | Zimices                                                                                                                                                               |
| 156 |     586.71040 |    410.720258 | Steven Traver                                                                                                                                                         |
| 157 |     525.06005 |      9.993627 | Prathyush Thomas                                                                                                                                                      |
| 158 |     181.06595 |    168.537035 | NA                                                                                                                                                                    |
| 159 |     170.02812 |    256.733776 | Iain Reid                                                                                                                                                             |
| 160 |     898.42447 |    245.277839 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 161 |      69.60295 |    748.870124 | NA                                                                                                                                                                    |
| 162 |     567.41155 |    599.196767 | Zimices                                                                                                                                                               |
| 163 |     833.20002 |    267.501386 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                      |
| 164 |      13.90141 |    395.965667 | NA                                                                                                                                                                    |
| 165 |    1010.34182 |    319.451948 | Ferran Sayol                                                                                                                                                          |
| 166 |     986.04512 |     15.010636 | NA                                                                                                                                                                    |
| 167 |     971.30227 |    456.691485 | Gareth Monger                                                                                                                                                         |
| 168 |    1011.64901 |    346.575396 | Matt Crook                                                                                                                                                            |
| 169 |     738.22531 |     68.651743 | Tasman Dixon                                                                                                                                                          |
| 170 |     958.04141 |    675.878334 | Markus A. Grohme                                                                                                                                                      |
| 171 |    1016.69902 |    252.271909 | Noah Schlottman                                                                                                                                                       |
| 172 |     795.01623 |     92.067956 | Yan Wong                                                                                                                                                              |
| 173 |     422.29084 |    146.003796 | T. Michael Keesey                                                                                                                                                     |
| 174 |     535.45762 |    433.412258 | Birgit Lang                                                                                                                                                           |
| 175 |     615.86110 |    538.927338 | Ignacio Contreras                                                                                                                                                     |
| 176 |     628.54155 |    784.249786 | Eyal Bartov                                                                                                                                                           |
| 177 |     514.51297 |    580.108679 | Ferran Sayol                                                                                                                                                          |
| 178 |     503.75533 |    778.475240 | Zimices                                                                                                                                                               |
| 179 |     805.59991 |    796.112014 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 180 |     598.99645 |    214.242341 | Scott Hartman                                                                                                                                                         |
| 181 |     361.35613 |    725.594597 | Maxime Dahirel                                                                                                                                                        |
| 182 |     909.01375 |     43.970282 | Margot Michaud                                                                                                                                                        |
| 183 |     400.52781 |    388.549019 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 184 |     705.32439 |    366.726767 | Lukasiniho                                                                                                                                                            |
| 185 |     392.84406 |    428.965944 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 186 |      58.92348 |    498.461970 | Lauren Anderson                                                                                                                                                       |
| 187 |     731.06650 |    132.308404 | Tess Linden                                                                                                                                                           |
| 188 |     713.83027 |    666.989645 | T. Michael Keesey                                                                                                                                                     |
| 189 |      14.80729 |    494.805198 | CNZdenek                                                                                                                                                              |
| 190 |    1009.38771 |    654.535670 | Gordon E. Robertson                                                                                                                                                   |
| 191 |      99.04345 |    170.017366 | Matt Crook                                                                                                                                                            |
| 192 |     117.75312 |    584.892935 | Xavier Giroux-Bougard                                                                                                                                                 |
| 193 |     790.17977 |    362.006273 | NA                                                                                                                                                                    |
| 194 |     985.80585 |    105.242413 | Sarah Werning                                                                                                                                                         |
| 195 |    1015.19663 |    110.637398 | Jimmy Bernot                                                                                                                                                          |
| 196 |     749.45526 |    391.235632 | Martin R. Smith                                                                                                                                                       |
| 197 |     611.03605 |    203.499151 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 198 |     988.01455 |    325.170296 | Beth Reinke                                                                                                                                                           |
| 199 |     400.11483 |    510.098580 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 200 |     149.89248 |    117.085963 | Collin Gross                                                                                                                                                          |
| 201 |     805.17184 |    337.762524 | Steven Traver                                                                                                                                                         |
| 202 |     812.74113 |    378.179653 | Dean Schnabel                                                                                                                                                         |
| 203 |     172.26740 |    189.921000 | Ferran Sayol                                                                                                                                                          |
| 204 |     501.67820 |     59.212211 | V. Deepak                                                                                                                                                             |
| 205 |      31.10170 |     54.236867 | Melissa Broussard                                                                                                                                                     |
| 206 |     651.08742 |    192.067470 | NA                                                                                                                                                                    |
| 207 |     970.71792 |    756.894824 | Kai R. Caspar                                                                                                                                                         |
| 208 |     133.49111 |     33.773973 | Jaime Headden                                                                                                                                                         |
| 209 |     587.11140 |    552.025690 | Beth Reinke                                                                                                                                                           |
| 210 |      41.04223 |     36.513471 | Scott Hartman                                                                                                                                                         |
| 211 |     399.30880 |    689.636415 | Harold N Eyster                                                                                                                                                       |
| 212 |      33.75736 |    410.545671 | Matt Crook                                                                                                                                                            |
| 213 |     593.25072 |    435.577350 | NA                                                                                                                                                                    |
| 214 |     261.84438 |    418.954520 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 215 |     655.30509 |    153.597333 | Jessica Rick                                                                                                                                                          |
| 216 |     289.57494 |     47.176315 | Katie S. Collins                                                                                                                                                      |
| 217 |     918.60200 |    336.598450 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 218 |     343.02681 |    609.542873 | Chris huh                                                                                                                                                             |
| 219 |     658.53359 |     52.570454 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 220 |     398.21677 |     30.260018 | Fernando Carezzano                                                                                                                                                    |
| 221 |     540.22255 |    775.495746 | Collin Gross                                                                                                                                                          |
| 222 |     737.94021 |    374.083065 | Ferran Sayol                                                                                                                                                          |
| 223 |     153.57380 |    326.563018 | Gareth Monger                                                                                                                                                         |
| 224 |     689.23910 |    309.318824 | Matt Crook                                                                                                                                                            |
| 225 |     881.71950 |    489.878890 | Matt Crook                                                                                                                                                            |
| 226 |    1011.74257 |    219.210170 | Lukasiniho                                                                                                                                                            |
| 227 |     603.06336 |     14.598415 | Mo Hassan                                                                                                                                                             |
| 228 |     764.98766 |    668.737513 | Matt Crook                                                                                                                                                            |
| 229 |     249.76701 |    762.348492 | Rachel Shoop                                                                                                                                                          |
| 230 |     964.76900 |    652.330686 | Andy Wilson                                                                                                                                                           |
| 231 |     168.58731 |    170.885036 | NA                                                                                                                                                                    |
| 232 |     672.78622 |    194.294073 | Ludwik Gąsiorowski                                                                                                                                                    |
| 233 |     661.20570 |     27.646347 | Zimices                                                                                                                                                               |
| 234 |     521.68218 |    745.727045 | Zimices                                                                                                                                                               |
| 235 |     965.53107 |    788.839483 | Emily Willoughby                                                                                                                                                      |
| 236 |     868.26787 |    403.250404 | Markus A. Grohme                                                                                                                                                      |
| 237 |     515.16611 |    421.644858 | Steven Traver                                                                                                                                                         |
| 238 |     362.98886 |    364.779608 | Steven Traver                                                                                                                                                         |
| 239 |     433.17515 |    719.056084 | NA                                                                                                                                                                    |
| 240 |     350.44771 |    554.855758 | Chris huh                                                                                                                                                             |
| 241 |     314.35852 |    586.969020 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 242 |     735.39049 |    519.236458 | Michelle Site                                                                                                                                                         |
| 243 |     245.87740 |    306.104199 | Matt Crook                                                                                                                                                            |
| 244 |     100.13283 |    479.810100 | Verdilak                                                                                                                                                              |
| 245 |     651.52722 |    552.587249 | Matt Crook                                                                                                                                                            |
| 246 |     326.74659 |    669.157912 | Matt Crook                                                                                                                                                            |
| 247 |     764.54452 |     65.677253 | Beth Reinke                                                                                                                                                           |
| 248 |      55.30212 |    697.859838 | Birgit Lang                                                                                                                                                           |
| 249 |     791.71293 |    456.685427 | Jagged Fang Designs                                                                                                                                                   |
| 250 |     737.72855 |    488.714170 | Zimices                                                                                                                                                               |
| 251 |     320.63999 |    348.082488 | Bruno C. Vellutini                                                                                                                                                    |
| 252 |     867.41674 |    383.567789 | Chris huh                                                                                                                                                             |
| 253 |     910.41048 |    381.973969 | Alexandra van der Geer                                                                                                                                                |
| 254 |     933.33062 |    108.963123 | Markus A. Grohme                                                                                                                                                      |
| 255 |     384.00202 |    159.501666 | Matt Crook                                                                                                                                                            |
| 256 |     405.71602 |    754.479914 | Bryan Carstens                                                                                                                                                        |
| 257 |     687.62784 |    251.575959 | Tyler Greenfield                                                                                                                                                      |
| 258 |     423.61789 |    697.286094 | Steven Traver                                                                                                                                                         |
| 259 |     432.21921 |    795.574509 | Josefine Bohr Brask                                                                                                                                                   |
| 260 |     549.91984 |     23.646876 | Tasman Dixon                                                                                                                                                          |
| 261 |     603.24000 |     61.391494 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 262 |     146.13095 |    146.103764 | Gareth Monger                                                                                                                                                         |
| 263 |      55.95289 |    523.694569 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
| 264 |     382.01201 |    198.526232 | Nobu Tamura                                                                                                                                                           |
| 265 |      77.13442 |    770.719790 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 266 |     300.72518 |    170.028288 | Margot Michaud                                                                                                                                                        |
| 267 |     628.96601 |     36.836900 | Gareth Monger                                                                                                                                                         |
| 268 |     657.03386 |    391.590117 | Gareth Monger                                                                                                                                                         |
| 269 |      35.16653 |    677.195593 | Kamil S. Jaron                                                                                                                                                        |
| 270 |     813.11720 |    703.699793 | NA                                                                                                                                                                    |
| 271 |     501.08365 |    794.711401 | Gareth Monger                                                                                                                                                         |
| 272 |     930.92770 |    771.435393 | Scott Hartman                                                                                                                                                         |
| 273 |     541.88046 |    456.784254 | Markus A. Grohme                                                                                                                                                      |
| 274 |      18.25375 |     25.298667 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 275 |     814.60992 |    556.247090 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 276 |     163.94708 |    531.331968 | Cesar Julian                                                                                                                                                          |
| 277 |      40.23673 |    513.368629 | Kamil S. Jaron                                                                                                                                                        |
| 278 |    1010.84875 |    137.551059 | Birgit Lang                                                                                                                                                           |
| 279 |     999.16056 |    292.733828 | Michele Tobias                                                                                                                                                        |
| 280 |     421.28832 |    467.133261 | Ferran Sayol                                                                                                                                                          |
| 281 |     570.48892 |     77.574852 | Ferran Sayol                                                                                                                                                          |
| 282 |    1006.11397 |    209.930373 | Scott Hartman                                                                                                                                                         |
| 283 |     972.39485 |    582.348186 | Steven Traver                                                                                                                                                         |
| 284 |     756.21566 |    379.613416 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 285 |      86.01068 |    761.484465 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 286 |     399.59136 |    587.318112 | Roberto Díaz Sibaja                                                                                                                                                   |
| 287 |     107.41837 |    298.965115 | Becky Barnes                                                                                                                                                          |
| 288 |     176.37163 |    403.864100 | Markus A. Grohme                                                                                                                                                      |
| 289 |     413.32572 |    272.514124 | T. Michael Keesey                                                                                                                                                     |
| 290 |     958.65172 |    300.168885 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 291 |     771.55047 |     97.657502 | T. Tischler                                                                                                                                                           |
| 292 |      35.09686 |    688.235212 | Harold N Eyster                                                                                                                                                       |
| 293 |     509.95123 |    722.126868 | Margot Michaud                                                                                                                                                        |
| 294 |     224.62804 |    124.702343 | T. Michael Keesey                                                                                                                                                     |
| 295 |     981.80971 |    637.504516 | Chase Brownstein                                                                                                                                                      |
| 296 |     574.08666 |    714.494540 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 297 |      96.99649 |    385.471170 | Birgit Lang                                                                                                                                                           |
| 298 |     753.64211 |     47.014098 | Jaime Headden                                                                                                                                                         |
| 299 |     539.13086 |    248.648200 | Gareth Monger                                                                                                                                                         |
| 300 |     888.58697 |     93.819651 | Tasman Dixon                                                                                                                                                          |
| 301 |     453.37748 |    718.046253 | Alex Slavenko                                                                                                                                                         |
| 302 |     603.17290 |    777.952088 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 303 |     522.24031 |    330.884473 | Lily Hughes                                                                                                                                                           |
| 304 |     933.59091 |    665.937713 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 305 |     885.04580 |      8.649837 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 306 |     101.03142 |    110.783629 | Scott Hartman                                                                                                                                                         |
| 307 |     828.56609 |    750.981228 | Yan Wong                                                                                                                                                              |
| 308 |     213.93827 |     22.356834 | Zimices                                                                                                                                                               |
| 309 |     437.37487 |     80.419551 | Courtney Rockenbach                                                                                                                                                   |
| 310 |     554.81080 |    786.862623 | Gareth Monger                                                                                                                                                         |
| 311 |     893.02382 |    132.469383 | Steven Traver                                                                                                                                                         |
| 312 |    1012.56949 |    299.373045 | Matt Crook                                                                                                                                                            |
| 313 |     763.41781 |    709.105590 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 314 |     891.12572 |    576.017661 | Jimmy Bernot                                                                                                                                                          |
| 315 |     508.06782 |    235.027383 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 316 |    1007.76626 |    441.168885 | Matt Martyniuk                                                                                                                                                        |
| 317 |     667.80064 |    278.335501 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 318 |     443.49037 |    286.975654 | CNZdenek                                                                                                                                                              |
| 319 |     225.28748 |    553.367564 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 320 |     276.31175 |    175.907423 | Sharon Wegner-Larsen                                                                                                                                                  |
| 321 |     921.52398 |    494.839472 | Zimices                                                                                                                                                               |
| 322 |     224.82408 |    775.371586 | Chris huh                                                                                                                                                             |
| 323 |      87.39026 |    162.754087 | Scott Hartman                                                                                                                                                         |
| 324 |     657.15002 |     93.797810 | Benjamin Monod-Broca                                                                                                                                                  |
| 325 |     383.27696 |    582.996667 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 326 |      99.61529 |    318.346717 | Andy Wilson                                                                                                                                                           |
| 327 |     213.29462 |    757.464783 | kreidefossilien.de                                                                                                                                                    |
| 328 |     827.80542 |    183.066279 | Mo Hassan                                                                                                                                                             |
| 329 |     507.84486 |    456.945265 | Blair Perry                                                                                                                                                           |
| 330 |      35.35394 |     91.388731 | Steven Traver                                                                                                                                                         |
| 331 |     767.69817 |    416.451530 | Zimices                                                                                                                                                               |
| 332 |     418.46124 |    320.493367 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 333 |     365.25670 |    281.583228 | Scott Hartman                                                                                                                                                         |
| 334 |     517.96192 |    620.595413 | Tauana J. Cunha                                                                                                                                                       |
| 335 |      83.46572 |    510.088607 | FunkMonk                                                                                                                                                              |
| 336 |     322.53477 |    474.834101 | Jaime Headden                                                                                                                                                         |
| 337 |     857.32968 |    523.605253 | Steven Traver                                                                                                                                                         |
| 338 |     755.37943 |    362.030441 | Jimmy Bernot                                                                                                                                                          |
| 339 |      91.91320 |    791.572880 | Abraão Leite                                                                                                                                                          |
| 340 |     746.11039 |    792.340102 | Baheerathan Murugavel                                                                                                                                                 |
| 341 |     825.73041 |    502.672646 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 342 |     295.69161 |    608.489761 | Andrew A. Farke                                                                                                                                                       |
| 343 |     665.21371 |     73.277150 | Birgit Lang                                                                                                                                                           |
| 344 |     286.17246 |     63.108243 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 345 |     873.65348 |    171.651961 | Christoph Schomburg                                                                                                                                                   |
| 346 |     853.98578 |     84.259300 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 347 |     129.24345 |    181.545854 | Steven Traver                                                                                                                                                         |
| 348 |     800.23412 |    509.459522 | Steven Traver                                                                                                                                                         |
| 349 |     183.85689 |    501.630358 | Maija Karala                                                                                                                                                          |
| 350 |     511.58670 |    692.747772 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 351 |     879.98404 |    197.669876 | Christoph Schomburg                                                                                                                                                   |
| 352 |      21.92505 |    524.666299 | Agnello Picorelli                                                                                                                                                     |
| 353 |      46.81687 |     19.349854 | Natasha Vitek                                                                                                                                                         |
| 354 |     888.38498 |    368.838840 | Michelle Site                                                                                                                                                         |
| 355 |     896.48887 |    105.718655 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 356 |     636.01194 |    175.458132 | Ferran Sayol                                                                                                                                                          |
| 357 |     247.09502 |    735.201224 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 358 |      85.91793 |    733.823947 | Michele M Tobias                                                                                                                                                      |
| 359 |     301.68301 |    519.130561 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 360 |     961.89003 |    632.807957 | Matt Crook                                                                                                                                                            |
| 361 |     430.02636 |    498.936646 | Andy Wilson                                                                                                                                                           |
| 362 |     584.78976 |     54.808515 | Collin Gross                                                                                                                                                          |
| 363 |     323.98805 |    609.285824 | Gordon E. Robertson                                                                                                                                                   |
| 364 |     932.38212 |    119.095394 | Julio Garza                                                                                                                                                           |
| 365 |     224.36637 |    368.128428 | Henry Lydecker                                                                                                                                                        |
| 366 |     453.43347 |    267.231254 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 367 |     610.59616 |    410.932906 | Margot Michaud                                                                                                                                                        |
| 368 |     541.92184 |    510.766140 | T. Michael Keesey                                                                                                                                                     |
| 369 |      19.89360 |    161.067453 | Sarah Werning                                                                                                                                                         |
| 370 |     271.09415 |    401.056071 | Scott Hartman                                                                                                                                                         |
| 371 |     271.82807 |    588.567104 | Chris huh                                                                                                                                                             |
| 372 |     460.24778 |    552.441494 | Scott Hartman                                                                                                                                                         |
| 373 |      11.35447 |    790.337934 | Matt Crook                                                                                                                                                            |
| 374 |     885.80831 |    390.252177 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 375 |      21.84830 |    711.837893 | Fernando Carezzano                                                                                                                                                    |
| 376 |     227.81299 |    283.697637 | Gareth Monger                                                                                                                                                         |
| 377 |     385.82397 |    774.416159 | Jagged Fang Designs                                                                                                                                                   |
| 378 |      75.77007 |    518.016381 | Stuart Humphries                                                                                                                                                      |
| 379 |     961.63767 |    773.738471 | Florian Pfaff                                                                                                                                                         |
| 380 |     797.62820 |     81.139323 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 381 |     293.61042 |    491.183688 | Ignacio Contreras                                                                                                                                                     |
| 382 |    1005.46369 |    475.803329 | C. Camilo Julián-Caballero                                                                                                                                            |
| 383 |     686.33174 |    688.701145 | Martin Kevil                                                                                                                                                          |
| 384 |     970.29752 |    568.645221 | Claus Rebler                                                                                                                                                          |
| 385 |     507.63509 |    401.850593 | Cesar Julian                                                                                                                                                          |
| 386 |     459.56784 |    795.124866 | Joanna Wolfe                                                                                                                                                          |
| 387 |     542.10021 |    216.601026 | NA                                                                                                                                                                    |
| 388 |     229.42963 |      7.392379 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 389 |     113.18822 |    445.410172 | Scott Hartman                                                                                                                                                         |
| 390 |     235.58369 |    707.863818 | Cristopher Silva                                                                                                                                                      |
| 391 |     194.21147 |    403.667938 | T. Michael Keesey                                                                                                                                                     |
| 392 |     221.69153 |    741.909064 | Margot Michaud                                                                                                                                                        |
| 393 |     623.76999 |    207.923563 | Matt Crook                                                                                                                                                            |
| 394 |     604.05303 |     38.221262 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 395 |      87.76716 |    363.461788 | Zimices                                                                                                                                                               |
| 396 |    1011.94081 |     98.847600 | Emily Willoughby                                                                                                                                                      |
| 397 |     671.14221 |    137.361836 | Jagged Fang Designs                                                                                                                                                   |
| 398 |     444.64000 |    617.276246 | Gareth Monger                                                                                                                                                         |
| 399 |     754.34314 |     85.925544 | FunkMonk                                                                                                                                                              |
| 400 |     349.27368 |    795.186904 | Margot Michaud                                                                                                                                                        |
| 401 |     131.25590 |    315.073221 | Steven Traver                                                                                                                                                         |
| 402 |     191.43762 |     25.243308 | Jaime Headden                                                                                                                                                         |
| 403 |     720.63848 |     36.797811 | Scott Reid                                                                                                                                                            |
| 404 |     203.81327 |    469.989836 | Ieuan Jones                                                                                                                                                           |
| 405 |     485.11883 |    317.296463 | Zimices                                                                                                                                                               |
| 406 |      33.31276 |    128.102096 | Matt Crook                                                                                                                                                            |
| 407 |      38.25455 |    344.393091 | Jaime Headden                                                                                                                                                         |
| 408 |     285.34185 |    500.657478 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 409 |      84.66988 |    268.540738 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 410 |     690.28623 |    538.166886 | Scott Hartman                                                                                                                                                         |
| 411 |     704.30439 |    268.721660 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 412 |     486.62299 |     12.503715 | T. Michael Keesey                                                                                                                                                     |
| 413 |     704.98213 |    782.819363 | NA                                                                                                                                                                    |
| 414 |     581.71830 |    512.829731 | Matt Crook                                                                                                                                                            |
| 415 |     422.81878 |    579.894723 | TaraTaylorDesign                                                                                                                                                      |
| 416 |     250.18214 |    263.340062 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 417 |     996.13082 |    257.188058 | Ferran Sayol                                                                                                                                                          |
| 418 |     410.17053 |    357.970205 | Margot Michaud                                                                                                                                                        |
| 419 |     171.88203 |    371.283086 | Kamil S. Jaron                                                                                                                                                        |
| 420 |     165.12405 |    576.274043 | NA                                                                                                                                                                    |
| 421 |     510.73809 |    330.690867 | Gareth Monger                                                                                                                                                         |
| 422 |     738.13787 |    406.815813 | Steven Traver                                                                                                                                                         |
| 423 |     413.41938 |    521.436780 | JCGiron                                                                                                                                                               |
| 424 |      39.80905 |    772.217376 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 425 |     623.95053 |    552.056887 | Zimices                                                                                                                                                               |
| 426 |     387.32505 |    266.318201 | Alexis Simon                                                                                                                                                          |
| 427 |     784.71266 |    266.606411 | S.Martini                                                                                                                                                             |
| 428 |     279.07651 |    411.409007 | Scott Hartman                                                                                                                                                         |
| 429 |      29.46601 |    120.852083 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 430 |     780.57698 |    366.802056 | Matt Crook                                                                                                                                                            |
| 431 |     866.15425 |    590.095016 | Scott Hartman                                                                                                                                                         |
| 432 |     761.17658 |    778.987778 | Matt Crook                                                                                                                                                            |
| 433 |     535.62251 |    283.824350 | Claus Rebler                                                                                                                                                          |
| 434 |      50.35637 |    726.493603 | NA                                                                                                                                                                    |
| 435 |     882.53809 |    584.112381 | Jagged Fang Designs                                                                                                                                                   |
| 436 |     846.28417 |    173.340891 | Zimices                                                                                                                                                               |
| 437 |     995.30359 |    144.187246 | Joanna Wolfe                                                                                                                                                          |
| 438 |     144.40584 |    308.513976 | Cristopher Silva                                                                                                                                                      |
| 439 |     284.87319 |    355.111726 | Andy Wilson                                                                                                                                                           |
| 440 |     530.16191 |    387.315412 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 441 |     644.54246 |     28.925663 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 442 |     470.48729 |    345.067602 | Ignacio Contreras                                                                                                                                                     |
| 443 |      45.64167 |    401.019504 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 444 |     983.39950 |    202.556614 | Margot Michaud                                                                                                                                                        |
| 445 |     882.62989 |    348.402934 | Julia B McHugh                                                                                                                                                        |
| 446 |     681.38925 |    300.882217 | NA                                                                                                                                                                    |
| 447 |     461.93258 |    246.885799 | Zimices                                                                                                                                                               |
| 448 |     695.44394 |     76.602121 | Jagged Fang Designs                                                                                                                                                   |
| 449 |     776.66980 |     84.338889 | Michele Tobias                                                                                                                                                        |
| 450 |     412.49907 |    247.710252 | Steven Traver                                                                                                                                                         |
| 451 |     984.16054 |     51.322973 | Kimberly Haddrell                                                                                                                                                     |
| 452 |     694.19911 |      9.218294 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
| 453 |    1014.05931 |    407.968940 | Andy Wilson                                                                                                                                                           |
| 454 |     931.21818 |    417.923619 | Jiekun He                                                                                                                                                             |
| 455 |     155.74899 |    414.829755 | Scott Hartman                                                                                                                                                         |
| 456 |     958.12712 |     14.249889 | Bryan Carstens                                                                                                                                                        |
| 457 |    1004.22820 |     18.368721 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 458 |     372.33834 |    597.805199 | Mattia Menchetti                                                                                                                                                      |
| 459 |     746.70316 |    648.155456 | Andreas Preuss / marauder                                                                                                                                             |
| 460 |     732.45695 |    671.548510 | Steven Traver                                                                                                                                                         |
| 461 |     367.93797 |    412.752844 | Margot Michaud                                                                                                                                                        |
| 462 |     524.53326 |    531.916509 | Margot Michaud                                                                                                                                                        |
| 463 |     523.87583 |    289.288027 | Scott Hartman                                                                                                                                                         |
| 464 |     185.02110 |    733.697317 | Matt Crook                                                                                                                                                            |
| 465 |     947.40725 |    318.679883 | Jagged Fang Designs                                                                                                                                                   |
| 466 |     244.34108 |    126.889212 | NA                                                                                                                                                                    |
| 467 |     681.02195 |    241.801957 | Caleb M. Brown                                                                                                                                                        |
| 468 |      95.52397 |    148.264129 | Agnello Picorelli                                                                                                                                                     |
| 469 |     560.50069 |    246.278141 | Caleb M. Brown                                                                                                                                                        |
| 470 |     907.43986 |    404.532617 | Joanna Wolfe                                                                                                                                                          |
| 471 |     783.57091 |    243.533321 | Melissa Broussard                                                                                                                                                     |
| 472 |     860.61003 |    269.081857 | NA                                                                                                                                                                    |
| 473 |     566.03022 |    498.688144 | NA                                                                                                                                                                    |
| 474 |     313.15983 |     42.284032 | Dmitry Bogdanov                                                                                                                                                       |
| 475 |     935.17856 |    628.359959 | Margot Michaud                                                                                                                                                        |
| 476 |     670.97993 |    764.562650 | Wayne Decatur                                                                                                                                                         |
| 477 |      26.73644 |     67.146229 | Matt Crook                                                                                                                                                            |
| 478 |     998.88378 |    131.533521 | T. Michael Keesey                                                                                                                                                     |
| 479 |     941.77661 |      3.503868 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 480 |     849.48789 |    798.276423 | Scott Hartman                                                                                                                                                         |
| 481 |     656.00789 |     58.548009 | Matt Crook                                                                                                                                                            |
| 482 |     870.29794 |    561.464948 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 483 |     693.23502 |    766.139299 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 484 |     951.18518 |    629.787547 | T. Michael Keesey                                                                                                                                                     |
| 485 |     836.93708 |    108.566884 | Jake Warner                                                                                                                                                           |
| 486 |      35.39119 |    108.455737 | Sharon Wegner-Larsen                                                                                                                                                  |
| 487 |      78.25332 |    351.742701 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 488 |     194.71941 |    548.781761 | Matt Crook                                                                                                                                                            |
| 489 |     222.05771 |    294.758621 | Matt Crook                                                                                                                                                            |
| 490 |     173.14267 |      4.437849 | Erika Schumacher                                                                                                                                                      |
| 491 |     131.76756 |    703.098278 | Scott Hartman                                                                                                                                                         |
| 492 |     806.16784 |     74.465763 | Caleb M. Gordon                                                                                                                                                       |
| 493 |     160.92088 |     21.738506 | Scott Hartman                                                                                                                                                         |
| 494 |     871.45442 |    129.945118 | Matt Crook                                                                                                                                                            |
| 495 |     672.20827 |    164.925525 | Hugo Gruson                                                                                                                                                           |
| 496 |     550.91959 |    491.148758 | NA                                                                                                                                                                    |
| 497 |     681.41040 |    122.989721 | Birgit Lang                                                                                                                                                           |
| 498 |     930.40210 |    503.804698 | Jagged Fang Designs                                                                                                                                                   |
| 499 |     507.42911 |    134.612956 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 500 |     479.50668 |    279.701925 | Jake Warner                                                                                                                                                           |
| 501 |     749.09925 |    158.895897 | Steven Traver                                                                                                                                                         |
| 502 |     946.62128 |    785.741505 | Markus A. Grohme                                                                                                                                                      |
| 503 |      30.15709 |    728.689141 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 504 |     706.84483 |    251.134547 | Dave Angelini                                                                                                                                                         |
| 505 |     643.83655 |    210.505654 | Scott Hartman                                                                                                                                                         |
| 506 |     846.19012 |    736.868675 | NA                                                                                                                                                                    |
| 507 |     323.46446 |    392.709197 | Tasman Dixon                                                                                                                                                          |
| 508 |      66.10953 |     37.496089 | Margot Michaud                                                                                                                                                        |
| 509 |     546.71634 |    414.181142 | Ferran Sayol                                                                                                                                                          |
| 510 |     757.18883 |    658.858928 | Beth Reinke                                                                                                                                                           |
| 511 |     409.30479 |     74.767037 | Dave Angelini                                                                                                                                                         |
| 512 |     200.00660 |    787.080562 | Michael Scroggie                                                                                                                                                      |
| 513 |     723.97765 |    414.663615 | Josefine Bohr Brask                                                                                                                                                   |
| 514 |     846.94441 |    100.236122 | Scott Hartman                                                                                                                                                         |
| 515 |     195.15770 |    494.313704 | Mason McNair                                                                                                                                                          |
| 516 |     940.64629 |     12.492691 | Tasman Dixon                                                                                                                                                          |
| 517 |     128.46967 |     18.648275 | Jaime Headden                                                                                                                                                         |
| 518 |     264.00337 |    127.461848 | Matt Crook                                                                                                                                                            |
| 519 |     368.36486 |    197.431736 | Kamil S. Jaron                                                                                                                                                        |
| 520 |     813.18461 |    409.190897 | CNZdenek                                                                                                                                                              |
| 521 |     639.45349 |    214.543321 | Carlos Cano-Barbacil                                                                                                                                                  |
| 522 |     254.75939 |    345.362636 | Steven Traver                                                                                                                                                         |
| 523 |     157.31853 |     29.658066 | Collin Gross                                                                                                                                                          |
| 524 |     204.44450 |    577.593316 | Steven Traver                                                                                                                                                         |
| 525 |     974.01711 |    123.386719 | C. Camilo Julián-Caballero                                                                                                                                            |
| 526 |     322.79658 |    183.912678 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 527 |     110.38219 |     89.635880 | C. Camilo Julián-Caballero                                                                                                                                            |
| 528 |     237.89226 |    788.552284 | Gareth Monger                                                                                                                                                         |
| 529 |     709.44566 |    322.160384 | Gareth Monger                                                                                                                                                         |
| 530 |     865.69999 |    114.394950 | NA                                                                                                                                                                    |
| 531 |      58.88067 |    353.666205 | Dean Schnabel                                                                                                                                                         |
| 532 |     432.19599 |    272.806816 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 533 |     877.72006 |    572.709181 | NA                                                                                                                                                                    |
| 534 |     335.09266 |     36.306238 | Collin Gross                                                                                                                                                          |
| 535 |     304.44854 |    357.592641 | Jaime Headden                                                                                                                                                         |
| 536 |     121.63626 |    162.667987 | Wayne Decatur                                                                                                                                                         |
| 537 |     864.38038 |    238.683455 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 538 |     251.50090 |    774.153800 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 539 |     629.36961 |    426.739381 | Tasman Dixon                                                                                                                                                          |
| 540 |     947.93817 |    564.942945 | Margot Michaud                                                                                                                                                        |
| 541 |    1004.92847 |    563.787449 | Christine Axon                                                                                                                                                        |
| 542 |     839.39130 |    468.361800 | Dean Schnabel                                                                                                                                                         |
| 543 |     921.92463 |    400.956528 | Birgit Lang                                                                                                                                                           |
| 544 |     425.16441 |    598.142432 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 545 |     521.77366 |    735.811924 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                  |
| 546 |      74.41766 |    574.072117 | Yan Wong                                                                                                                                                              |
| 547 |     942.10124 |    697.032394 | Terpsichores                                                                                                                                                          |
| 548 |     906.08080 |    575.621428 | Gareth Monger                                                                                                                                                         |
| 549 |     495.74723 |    702.361036 | Emily Willoughby                                                                                                                                                      |
| 550 |     136.97841 |    383.618608 | Marmelad                                                                                                                                                              |
| 551 |     664.78918 |    438.207581 | Jaime Headden                                                                                                                                                         |
| 552 |     208.77680 |    123.831456 | Dean Schnabel                                                                                                                                                         |
| 553 |     876.00075 |    734.626123 | Chris huh                                                                                                                                                             |
| 554 |     247.88269 |    571.693367 | Zimices                                                                                                                                                               |
| 555 |      67.81180 |    735.070188 | Ferran Sayol                                                                                                                                                          |
| 556 |     632.98266 |    156.382411 | Scott Hartman                                                                                                                                                         |
| 557 |      53.18645 |    304.020014 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 558 |     642.17956 |    695.421051 | Armin Reindl                                                                                                                                                          |
| 559 |     476.77868 |    653.994242 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 560 |    1006.85146 |    503.545824 | Karina Garcia                                                                                                                                                         |
| 561 |     920.71097 |    406.437101 | Scott Hartman                                                                                                                                                         |
| 562 |     883.73152 |    419.201430 | Jagged Fang Designs                                                                                                                                                   |
| 563 |     984.89194 |    113.933494 | Katie S. Collins                                                                                                                                                      |
| 564 |     459.72919 |    467.812302 | Zimices                                                                                                                                                               |
| 565 |     588.25310 |    796.947810 | xgirouxb                                                                                                                                                              |
| 566 |     860.30014 |    319.928658 | Zimices                                                                                                                                                               |
| 567 |     845.71930 |    225.542560 | Steven Traver                                                                                                                                                         |
| 568 |     767.11075 |    358.113524 | Andrés Sánchez                                                                                                                                                        |
| 569 |     975.25017 |    434.995533 | Matt Crook                                                                                                                                                            |
| 570 |     997.35724 |    495.426275 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 571 |     585.01682 |    490.695612 | NA                                                                                                                                                                    |
| 572 |     794.00804 |    676.865681 | Jagged Fang Designs                                                                                                                                                   |
| 573 |     887.06024 |    499.764910 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 574 |     521.40041 |    363.308236 | Gareth Monger                                                                                                                                                         |
| 575 |     723.09160 |    392.271660 | Zimices                                                                                                                                                               |
| 576 |     770.99428 |    123.167515 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                      |
| 577 |     828.80835 |    115.321950 | T. Michael Keesey                                                                                                                                                     |
| 578 |     820.37979 |    468.705913 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 579 |     853.10768 |    339.940161 | Birgit Lang                                                                                                                                                           |
| 580 |     920.74200 |     34.721169 | Matt Crook                                                                                                                                                            |
| 581 |     191.64887 |    154.857071 | Katie S. Collins                                                                                                                                                      |
| 582 |      17.81354 |    429.242660 | Matt Crook                                                                                                                                                            |
| 583 |     941.33348 |     33.906622 | Kamil S. Jaron                                                                                                                                                        |
| 584 |     985.82974 |    624.114446 | CNZdenek                                                                                                                                                              |
| 585 |     597.87074 |    166.336666 | C. Camilo Julián-Caballero                                                                                                                                            |
| 586 |    1015.04682 |    629.733030 | Steven Traver                                                                                                                                                         |
| 587 |     578.91369 |    448.696424 | Margot Michaud                                                                                                                                                        |
| 588 |     841.12702 |    278.664099 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 589 |     499.18247 |    618.880832 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 590 |     855.83024 |    248.155497 | Margot Michaud                                                                                                                                                        |
| 591 |      42.00043 |    577.300653 | Margot Michaud                                                                                                                                                        |
| 592 |     261.24612 |    175.039129 | Agnello Picorelli                                                                                                                                                     |
| 593 |     113.64217 |    379.093543 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 594 |     857.77634 |      7.234513 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 595 |     382.58096 |    640.542630 | Lily Hughes                                                                                                                                                           |
| 596 |     321.76133 |    521.126415 | Collin Gross                                                                                                                                                          |
| 597 |     577.86823 |     32.652387 | Margot Michaud                                                                                                                                                        |
| 598 |     913.93898 |    102.472436 | Zimices                                                                                                                                                               |
| 599 |     855.61195 |    287.179084 | Margot Michaud                                                                                                                                                        |
| 600 |     199.47755 |    176.545640 | Steven Traver                                                                                                                                                         |
| 601 |     582.62366 |     87.781458 | JCGiron                                                                                                                                                               |
| 602 |     845.67304 |    313.334439 | Steven Traver                                                                                                                                                         |
| 603 |      13.12378 |    729.816713 | Benjamint444                                                                                                                                                          |
| 604 |     309.37191 |     25.453008 | Zimices                                                                                                                                                               |
| 605 |     671.64727 |    697.691752 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 606 |     100.93943 |    217.531667 | NA                                                                                                                                                                    |
| 607 |     109.27418 |    364.391106 | Markus A. Grohme                                                                                                                                                      |
| 608 |     542.33693 |    233.096116 | Kamil S. Jaron                                                                                                                                                        |
| 609 |     657.69316 |    171.497878 | NA                                                                                                                                                                    |
| 610 |     135.24342 |    266.906077 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 611 |     496.04569 |    593.395772 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 612 |     136.50767 |    190.123638 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                        |
| 613 |     497.15033 |    244.455020 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 614 |     607.26521 |    243.317434 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 615 |      37.86347 |     74.767507 | Kamil S. Jaron                                                                                                                                                        |
| 616 |     449.14066 |     57.211351 | Zimices                                                                                                                                                               |
| 617 |     214.86660 |    105.643138 | Markus A. Grohme                                                                                                                                                      |
| 618 |     403.81312 |    603.838471 | Iain Reid                                                                                                                                                             |
| 619 |     897.70412 |     87.543239 | Yan Wong                                                                                                                                                              |
| 620 |     217.14203 |    768.440132 | NA                                                                                                                                                                    |
| 621 |      56.08033 |    609.787771 | Matt Wilkins                                                                                                                                                          |
| 622 |     210.92113 |    451.096833 | Margot Michaud                                                                                                                                                        |
| 623 |     894.02346 |    406.207578 | Danielle Alba                                                                                                                                                         |
| 624 |     671.38192 |    776.173019 | Zimices                                                                                                                                                               |
| 625 |     985.37034 |    452.765603 | Benjamin Monod-Broca                                                                                                                                                  |
| 626 |     247.70947 |      6.770424 | Matt Crook                                                                                                                                                            |
| 627 |     986.02213 |    550.147181 | Gareth Monger                                                                                                                                                         |
| 628 |      81.04216 |    714.447445 | Matt Crook                                                                                                                                                            |
| 629 |     820.99856 |    524.682751 | Andrew A. Farke                                                                                                                                                       |
| 630 |     669.07139 |    373.151271 | Matt Crook                                                                                                                                                            |
| 631 |      64.43169 |    514.479257 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 632 |     249.16948 |    292.144285 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 633 |      34.55013 |    329.504244 | Matt Crook                                                                                                                                                            |
| 634 |     763.43907 |    223.865685 | Margot Michaud                                                                                                                                                        |
| 635 |     156.41556 |     38.352572 | Michelle Site                                                                                                                                                         |
| 636 |     294.58590 |    451.811101 | Shyamal                                                                                                                                                               |
| 637 |     990.34953 |    126.869137 | Ferran Sayol                                                                                                                                                          |
| 638 |    1015.80694 |    196.973343 | Andy Wilson                                                                                                                                                           |
| 639 |     573.58982 |    481.605879 | Matt Crook                                                                                                                                                            |
| 640 |     278.41774 |    534.370408 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 641 |     427.47108 |    126.769032 | Michael Scroggie                                                                                                                                                      |
| 642 |     801.48848 |     25.258621 | NA                                                                                                                                                                    |
| 643 |     116.03633 |    203.957970 | Beth Reinke                                                                                                                                                           |
| 644 |     558.11596 |    426.873949 | Henry Lydecker                                                                                                                                                        |
| 645 |     624.74588 |    413.703335 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 646 |     461.20108 |     18.139345 | Mason McNair                                                                                                                                                          |
| 647 |     921.93025 |    433.665218 | Iain Reid                                                                                                                                                             |
| 648 |      93.52660 |     84.601925 | Noah Schlottman                                                                                                                                                       |
| 649 |     997.76389 |    593.091870 | Lisa Byrne                                                                                                                                                            |
| 650 |     671.77135 |     10.789702 | Michael Scroggie                                                                                                                                                      |
| 651 |     386.99150 |    452.282847 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 652 |     940.14222 |     54.159630 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 653 |      74.60645 |    314.847693 | Ferran Sayol                                                                                                                                                          |
| 654 |      97.49328 |    575.296636 | Margot Michaud                                                                                                                                                        |
| 655 |    1001.69090 |    581.402311 | Matt Crook                                                                                                                                                            |
| 656 |     819.25752 |    368.423288 | Joanna Wolfe                                                                                                                                                          |
| 657 |     285.43045 |      5.667029 | NA                                                                                                                                                                    |
| 658 |     267.45549 |    560.970596 | Matt Crook                                                                                                                                                            |
| 659 |     887.76603 |    207.105180 | C. Camilo Julián-Caballero                                                                                                                                            |
| 660 |     376.81500 |    732.299030 | Roberto Díaz Sibaja                                                                                                                                                   |
| 661 |     542.89915 |    723.691915 | Steven Traver                                                                                                                                                         |
| 662 |     793.26093 |    278.893098 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 663 |     479.01833 |    489.529774 | Margot Michaud                                                                                                                                                        |
| 664 |     286.53875 |    290.156021 | Zimices                                                                                                                                                               |
| 665 |     446.36877 |    581.723534 | Sarah Werning                                                                                                                                                         |
| 666 |     291.07015 |    544.922949 | Markus A. Grohme                                                                                                                                                      |
| 667 |     318.93405 |    291.083068 | T. Michael Keesey                                                                                                                                                     |
| 668 |     569.08102 |    222.792536 | Julio Garza                                                                                                                                                           |
| 669 |    1002.51512 |    192.425923 | Scott Reid                                                                                                                                                            |
| 670 |     756.34825 |    150.326805 | Tasman Dixon                                                                                                                                                          |
| 671 |     614.95533 |    771.449455 | Zimices                                                                                                                                                               |
| 672 |     757.93542 |    298.782546 | Scott Hartman                                                                                                                                                         |
| 673 |     104.07905 |    265.496332 | Tracy A. Heath                                                                                                                                                        |
| 674 |     881.56780 |    766.440342 | Andrew A. Farke                                                                                                                                                       |
| 675 |     256.20827 |    378.954058 | Chris Hay                                                                                                                                                             |
| 676 |     331.17915 |    401.461090 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 677 |      65.75249 |    764.324963 | Andrew A. Farke                                                                                                                                                       |
| 678 |     757.67304 |    168.080214 | Margot Michaud                                                                                                                                                        |
| 679 |      15.42191 |    223.570057 | Ferran Sayol                                                                                                                                                          |
| 680 |     274.84490 |    549.533196 | Scott Hartman                                                                                                                                                         |
| 681 |     972.34305 |    796.624338 | Markus A. Grohme                                                                                                                                                      |
| 682 |     676.63151 |     93.779495 | Gareth Monger                                                                                                                                                         |
| 683 |     646.82723 |    542.597947 | Rebecca Groom                                                                                                                                                         |
| 684 |     474.50789 |     50.695183 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 685 |     100.27104 |    565.563862 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 686 |      72.67245 |    689.353168 | Steven Traver                                                                                                                                                         |
| 687 |     162.90707 |    511.048686 | Andy Wilson                                                                                                                                                           |
| 688 |     785.96501 |    785.921909 | Margot Michaud                                                                                                                                                        |
| 689 |     923.10348 |    648.013589 | Scott Hartman                                                                                                                                                         |
| 690 |     534.56425 |    620.175854 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 691 |     609.38773 |    434.842248 | Gareth Monger                                                                                                                                                         |
| 692 |      15.45174 |     86.636866 | Ferran Sayol                                                                                                                                                          |
| 693 |     515.76333 |    592.858915 | Smokeybjb                                                                                                                                                             |
| 694 |     366.39932 |    176.411069 | Ferran Sayol                                                                                                                                                          |
| 695 |     781.07415 |    231.604239 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 696 |     989.11055 |    406.823893 | Daniel Stadtmauer                                                                                                                                                     |
| 697 |     526.69907 |    409.937187 | Kanchi Nanjo                                                                                                                                                          |
| 698 |     444.54330 |    145.372746 | Craig Dylke                                                                                                                                                           |
| 699 |     590.59059 |    400.180791 | Markus A. Grohme                                                                                                                                                      |
| 700 |     199.10282 |    735.838295 | Gareth Monger                                                                                                                                                         |
| 701 |     429.70032 |    313.536426 | Iain Reid                                                                                                                                                             |
| 702 |     380.60741 |    707.513301 | Matt Crook                                                                                                                                                            |
| 703 |     728.69301 |    783.117854 | Matt Crook                                                                                                                                                            |
| 704 |     227.42993 |    755.205380 | Matt Crook                                                                                                                                                            |
| 705 |     214.59560 |    731.952790 | Gareth Monger                                                                                                                                                         |
| 706 |     821.38619 |     94.800593 | Zimices                                                                                                                                                               |
| 707 |     452.10462 |     69.127104 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 708 |     172.57168 |    337.674987 | Tauana J. Cunha                                                                                                                                                       |
| 709 |     820.38221 |    494.519197 | Zimices                                                                                                                                                               |
| 710 |      59.19521 |    318.121281 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 711 |     137.45988 |    605.142810 | Julio Garza                                                                                                                                                           |
| 712 |     569.75202 |    279.333202 | Andy Wilson                                                                                                                                                           |
| 713 |     287.21252 |    440.090613 | Ferran Sayol                                                                                                                                                          |
| 714 |    1012.75747 |    157.556679 | Beth Reinke                                                                                                                                                           |
| 715 |     590.79844 |    293.325714 | Jagged Fang Designs                                                                                                                                                   |
| 716 |     672.86873 |    355.297735 | Margot Michaud                                                                                                                                                        |
| 717 |     247.83863 |    714.510611 | Roderic Page and Lois Page                                                                                                                                            |
| 718 |     253.42785 |    362.781054 | Gareth Monger                                                                                                                                                         |
| 719 |     971.79360 |    103.584686 | (after McCulloch 1908)                                                                                                                                                |
| 720 |     967.62647 |    709.184682 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 721 |     767.80310 |    401.669394 | Julio Garza                                                                                                                                                           |
| 722 |     128.21612 |    532.633961 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 723 |     485.58583 |     67.860656 | Gareth Monger                                                                                                                                                         |
| 724 |     383.44459 |    668.138694 | Steven Traver                                                                                                                                                         |
| 725 |     103.62475 |    152.720835 | Matt Crook                                                                                                                                                            |
| 726 |     522.00885 |    226.911670 | NA                                                                                                                                                                    |
| 727 |     391.95993 |    146.251022 | Beth Reinke                                                                                                                                                           |
| 728 |     254.61171 |    644.177544 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 729 |     744.00482 |    698.632737 | Steven Traver                                                                                                                                                         |
| 730 |     997.72235 |    537.543500 | T. Michael Keesey                                                                                                                                                     |
| 731 |     440.68714 |    728.652339 | Matt Martyniuk                                                                                                                                                        |
| 732 |     951.38369 |     43.387145 | Matt Crook                                                                                                                                                            |
| 733 |     171.37982 |     42.707836 | Chuanixn Yu                                                                                                                                                           |
| 734 |     675.29778 |    104.877071 | Roberto Díaz Sibaja                                                                                                                                                   |
| 735 |     628.06352 |    189.664205 | Scott Hartman                                                                                                                                                         |
| 736 |     859.84816 |    216.476556 | Matt Crook                                                                                                                                                            |
| 737 |     219.73262 |    396.676161 | NA                                                                                                                                                                    |
| 738 |     863.46858 |     96.148646 | Sarah Werning                                                                                                                                                         |
| 739 |      32.76706 |    786.956422 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 740 |     593.21242 |    144.577953 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 741 |    1001.07092 |    417.562990 | Kai R. Caspar                                                                                                                                                         |
| 742 |     944.13501 |    189.151837 | Matt Crook                                                                                                                                                            |
| 743 |     682.21121 |    747.708627 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 744 |      44.79104 |    789.862818 | NA                                                                                                                                                                    |
| 745 |     867.34595 |    192.174230 | Steven Traver                                                                                                                                                         |
| 746 |      11.16357 |    312.116812 | Riccardo Percudani                                                                                                                                                    |
| 747 |     454.58415 |    504.255913 | CNZdenek                                                                                                                                                              |
| 748 |     948.60252 |    767.119370 | Armin Reindl                                                                                                                                                          |
| 749 |     153.63709 |    192.423914 | Scott Reid                                                                                                                                                            |
| 750 |     317.38140 |    485.416479 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 751 |    1015.52203 |    356.034852 | Chris huh                                                                                                                                                             |
| 752 |     976.76835 |    656.230130 | Margot Michaud                                                                                                                                                        |
| 753 |     783.29370 |    491.318425 | Matt Crook                                                                                                                                                            |
| 754 |     692.66608 |    670.407860 | NA                                                                                                                                                                    |
| 755 |      63.26604 |    219.462490 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 756 |     999.21676 |    397.182208 | Gareth Monger                                                                                                                                                         |
| 757 |     524.55605 |    726.398443 | Matt Crook                                                                                                                                                            |
| 758 |     606.77705 |    320.934843 | L. Shyamal                                                                                                                                                            |
| 759 |     137.28109 |    336.091162 | Elisabeth Östman                                                                                                                                                      |
| 760 |      52.79279 |     95.959797 | David Orr                                                                                                                                                             |
| 761 |     833.84529 |    568.227068 | Alex Slavenko                                                                                                                                                         |
| 762 |     828.64781 |    762.649240 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 763 |     834.51617 |    211.060717 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 764 |     809.67213 |    724.731471 | Jagged Fang Designs                                                                                                                                                   |
| 765 |     322.12767 |    503.349535 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 766 |     136.20470 |    319.903421 | Matt Crook                                                                                                                                                            |
| 767 |     533.86163 |    217.904495 | Birgit Lang                                                                                                                                                           |
| 768 |     766.56152 |    521.271530 | Ferran Sayol                                                                                                                                                          |
| 769 |     750.81758 |    312.887321 | Andy Wilson                                                                                                                                                           |
| 770 |     428.86157 |    511.789914 | NA                                                                                                                                                                    |
| 771 |      22.02699 |    191.097090 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 772 |     390.16729 |    756.669456 | Alexandre Vong                                                                                                                                                        |
| 773 |     705.24063 |    377.403006 | Fernando Carezzano                                                                                                                                                    |
| 774 |     289.14141 |    461.505291 | Matt Crook                                                                                                                                                            |
| 775 |     178.16251 |     29.616575 | Ferran Sayol                                                                                                                                                          |
| 776 |     707.16766 |     17.303030 | NA                                                                                                                                                                    |
| 777 |     697.37312 |    491.488389 | Zimices                                                                                                                                                               |
| 778 |     556.46035 |     73.331889 | Jessica Anne Miller                                                                                                                                                   |
| 779 |     727.71071 |    505.104136 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 780 |      32.35221 |    531.872574 | Scott Hartman                                                                                                                                                         |
| 781 |     289.64258 |    393.350959 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 782 |    1002.02901 |    638.665335 | Chris huh                                                                                                                                                             |
| 783 |     370.01414 |    243.311596 | NA                                                                                                                                                                    |
| 784 |     787.43553 |    377.227106 | Melissa Broussard                                                                                                                                                     |
| 785 |     192.97480 |    394.750241 | Tasman Dixon                                                                                                                                                          |
| 786 |     172.00157 |    295.750285 | Ferran Sayol                                                                                                                                                          |
| 787 |      43.13295 |     64.915579 | Margot Michaud                                                                                                                                                        |
| 788 |     550.18197 |    627.255333 | Zimices                                                                                                                                                               |
| 789 |     410.42536 |    295.807935 | Zimices                                                                                                                                                               |
| 790 |     438.25945 |    554.591379 | Jagged Fang Designs                                                                                                                                                   |
| 791 |     758.50749 |    181.608651 | Scott Hartman                                                                                                                                                         |
| 792 |     184.30731 |    252.678806 | Steven Traver                                                                                                                                                         |
| 793 |     934.17623 |    588.647469 | Felix Vaux                                                                                                                                                            |
| 794 |     392.56413 |    282.328742 | Zimices                                                                                                                                                               |
| 795 |     111.05286 |    692.278438 | Melissa Broussard                                                                                                                                                     |
| 796 |     144.76087 |    128.365366 | Mykle Hoban                                                                                                                                                           |
| 797 |     477.05657 |    784.752072 | Armin Reindl                                                                                                                                                          |
| 798 |     406.84254 |     32.804370 | Tracy A. Heath                                                                                                                                                        |
| 799 |     452.98969 |    401.493503 | Kai R. Caspar                                                                                                                                                         |
| 800 |     556.17317 |    446.623080 | Markus A. Grohme                                                                                                                                                      |
| 801 |     772.26298 |    136.810583 | Maha Ghazal                                                                                                                                                           |
| 802 |     384.62837 |    518.465678 | Chuanixn Yu                                                                                                                                                           |
| 803 |     338.79880 |    478.486795 | Zimices                                                                                                                                                               |
| 804 |     905.26338 |    506.371283 | Matt Crook                                                                                                                                                            |
| 805 |     892.49053 |     53.283391 | CNZdenek                                                                                                                                                              |
| 806 |     440.75303 |    562.518195 | David Orr                                                                                                                                                             |
| 807 |     946.99554 |    456.841220 | C. Camilo Julián-Caballero                                                                                                                                            |
| 808 |    1008.87177 |     90.404289 | Stacy Spensley (Modified)                                                                                                                                             |
| 809 |     336.40763 |     25.921443 | Ludwik Gąsiorowski                                                                                                                                                    |
| 810 |     684.65298 |    733.017206 | Jagged Fang Designs                                                                                                                                                   |
| 811 |     537.02326 |    418.155268 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 812 |     995.72184 |    335.866882 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 813 |     660.51475 |     84.552476 | Gareth Monger                                                                                                                                                         |
| 814 |     933.29152 |    102.061666 | Kamil S. Jaron                                                                                                                                                        |
| 815 |     567.74514 |    579.438395 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 816 |     184.70984 |    747.813376 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 817 |     232.94436 |    299.011276 | M. A. Broussard                                                                                                                                                       |
| 818 |     841.45000 |    750.690907 | Chase Brownstein                                                                                                                                                      |
| 819 |     705.51412 |     39.287372 | NA                                                                                                                                                                    |
| 820 |     190.89759 |    632.280694 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 821 |     475.70040 |    351.366985 | Matt Crook                                                                                                                                                            |
| 822 |     583.62390 |    352.302304 | Zimices                                                                                                                                                               |
| 823 |     967.49481 |    256.091431 | Roberto Díaz Sibaja                                                                                                                                                   |
| 824 |     774.00589 |    167.752647 | Zimices                                                                                                                                                               |
| 825 |     240.84990 |    546.964709 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 826 |     551.67101 |    605.604951 | Louis Ranjard                                                                                                                                                         |
| 827 |      58.97254 |    777.316863 | Ferran Sayol                                                                                                                                                          |
| 828 |     609.45730 |    143.208479 | Milton Tan                                                                                                                                                            |
| 829 |      31.79782 |    494.277332 | Armin Reindl                                                                                                                                                          |
| 830 |      10.83427 |    249.668172 | S.Martini                                                                                                                                                             |
| 831 |     439.82166 |    588.227331 | Steven Traver                                                                                                                                                         |
| 832 |     315.86646 |    596.081477 | Rebecca Groom                                                                                                                                                         |
| 833 |      36.13738 |    560.588622 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 834 |     362.60147 |    707.959281 | T. Michael Keesey                                                                                                                                                     |
| 835 |     104.35641 |    633.507738 | Steven Traver                                                                                                                                                         |
| 836 |     363.34467 |    793.274973 | Beth Reinke                                                                                                                                                           |
| 837 |     780.98812 |    316.869892 | Chris huh                                                                                                                                                             |
| 838 |      90.65831 |    624.775976 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 839 |     397.59223 |    787.990536 | Matt Crook                                                                                                                                                            |
| 840 |     150.81172 |    180.141607 | Matt Crook                                                                                                                                                            |
| 841 |     913.95487 |    626.394952 | NA                                                                                                                                                                    |
| 842 |     250.33203 |    109.235833 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 843 |     742.83547 |    710.433574 | Matt Crook                                                                                                                                                            |
| 844 |     723.95398 |     22.364844 | Ferran Sayol                                                                                                                                                          |
| 845 |      34.97440 |    451.163493 | Carlos Cano-Barbacil                                                                                                                                                  |
| 846 |     343.73710 |    385.751810 | Qiang Ou                                                                                                                                                              |
| 847 |     956.89799 |    664.484213 | Harold N Eyster                                                                                                                                                       |
| 848 |      17.63774 |    107.466756 | Matt Crook                                                                                                                                                            |
| 849 |     466.31861 |    668.497063 | Shyamal                                                                                                                                                               |
| 850 |     163.91509 |    618.744633 | NA                                                                                                                                                                    |
| 851 |     377.42541 |    430.616698 | Scott Hartman                                                                                                                                                         |
| 852 |     111.93235 |    178.399308 | Raven Amos                                                                                                                                                            |
| 853 |     750.09319 |    479.191945 | Jagged Fang Designs                                                                                                                                                   |
| 854 |     780.31384 |     35.299532 | Margot Michaud                                                                                                                                                        |
| 855 |     213.22894 |    441.624861 | Zimices                                                                                                                                                               |
| 856 |     595.48882 |    559.015122 | Margot Michaud                                                                                                                                                        |
| 857 |     216.49900 |    138.348907 | Maija Karala                                                                                                                                                          |
| 858 |     463.48048 |    742.572041 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 859 |     114.92949 |    142.655233 | Michael P. Taylor                                                                                                                                                     |
| 860 |     846.41299 |    445.309898 | Scott Hartman                                                                                                                                                         |
| 861 |     517.64026 |     25.542353 | Jagged Fang Designs                                                                                                                                                   |
| 862 |     575.68828 |    570.491497 | Ferran Sayol                                                                                                                                                          |
| 863 |     303.15795 |     53.424233 | Jaime Headden                                                                                                                                                         |
| 864 |     828.92265 |    401.122270 | Tasman Dixon                                                                                                                                                          |
| 865 |     559.75410 |    561.331039 | Dann Pigdon                                                                                                                                                           |
| 866 |     125.49712 |    328.100019 | NA                                                                                                                                                                    |
| 867 |     849.82858 |    483.910028 | Jagged Fang Designs                                                                                                                                                   |
| 868 |     618.60772 |     44.085969 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 869 |     903.64163 |    474.485179 | Jagged Fang Designs                                                                                                                                                   |
| 870 |      56.93462 |    582.014556 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 871 |     423.99317 |     74.190490 | Zimices                                                                                                                                                               |
| 872 |     753.14131 |    496.615059 | Margot Michaud                                                                                                                                                        |
| 873 |     420.51992 |    415.045126 | Matt Crook                                                                                                                                                            |
| 874 |     801.45419 |    116.529191 | Jagged Fang Designs                                                                                                                                                   |
| 875 |      26.61891 |    762.364274 | Tasman Dixon                                                                                                                                                          |
| 876 |     408.66062 |    130.640002 | Zimices                                                                                                                                                               |
| 877 |     826.31714 |    727.640515 | Tasman Dixon                                                                                                                                                          |
| 878 |     377.44061 |    612.328494 | NA                                                                                                                                                                    |
| 879 |     975.69477 |    274.964170 | Yan Wong                                                                                                                                                              |
| 880 |     832.77434 |    475.871310 | Anthony Caravaggi                                                                                                                                                     |
| 881 |     571.95723 |    727.893836 | Margot Michaud                                                                                                                                                        |
| 882 |     241.06061 |     23.897680 | Scott Hartman                                                                                                                                                         |
| 883 |     158.83257 |    635.732064 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 884 |     494.13993 |    151.449372 | Chris huh                                                                                                                                                             |
| 885 |     577.11364 |    425.248496 | Christoph Schomburg                                                                                                                                                   |
| 886 |     780.38959 |    193.271272 | NA                                                                                                                                                                    |
| 887 |     847.04669 |    164.881951 | Lukas Panzarin                                                                                                                                                        |
| 888 |     303.81061 |    473.224173 | Scott Hartman                                                                                                                                                         |
| 889 |     109.81838 |    128.870159 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 890 |     650.11187 |    100.091723 | Zimices                                                                                                                                                               |
| 891 |     332.94561 |    552.304764 | Kamil S. Jaron                                                                                                                                                        |
| 892 |     968.62863 |    682.904021 | Margot Michaud                                                                                                                                                        |
| 893 |     683.84550 |    260.963026 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 894 |     331.63492 |    241.723589 | NA                                                                                                                                                                    |
| 895 |     513.98309 |    104.176249 | Gopal Murali                                                                                                                                                          |
| 896 |      71.72031 |    501.542408 | Rainer Schoch                                                                                                                                                         |
| 897 |     375.42432 |     29.053306 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 898 |     868.89404 |    257.676757 | Air Kebir NRG                                                                                                                                                         |
| 899 |     828.14990 |    410.554726 | Birgit Lang                                                                                                                                                           |
| 900 |      68.14809 |    251.502704 | Jagged Fang Designs                                                                                                                                                   |
| 901 |      36.58674 |    667.111933 | Kamil S. Jaron                                                                                                                                                        |
| 902 |     471.18747 |    458.291504 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 903 |     269.39700 |     10.312611 | Matt Crook                                                                                                                                                            |
| 904 |     678.65468 |    145.581544 | Ferran Sayol                                                                                                                                                          |
| 905 |     345.08098 |    777.511858 | Steven Traver                                                                                                                                                         |
| 906 |     927.18757 |    617.536348 | Zimices                                                                                                                                                               |
| 907 |     565.89049 |    411.340847 | NA                                                                                                                                                                    |
| 908 |     691.40095 |    117.670551 | Lukas Panzarin                                                                                                                                                        |

    #> Your tweet has been posted!
