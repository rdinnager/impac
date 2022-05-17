
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

Steven Coombs, Gareth Monger, Margot Michaud, Matt Crook, Timothy Knepp
(vectorized by T. Michael Keesey), Roberto Díaz Sibaja, Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Jagged Fang Designs, Rebecca Groom,
Martin R. Smith, Ferran Sayol, Joanna Wolfe, DW Bapst (modified from
Bulman, 1970), Mo Hassan, Diana Pomeroy, Zimices, Cagri Cevrim, Leann
Biancani, photo by Kenneth Clifton, Paul O. Lewis, Birgit Lang, T. K.
Robinson, Collin Gross, Dean Schnabel, Markus A. Grohme, Nobu Tamura
(vectorized by T. Michael Keesey), Mattia Menchetti, T. Michael Keesey
(after MPF), T. Michael Keesey, Scott Hartman, Felix Vaux and Steven A.
Trewick, Eduard Solà Vázquez, vectorised by Yan Wong, Jose Carlos
Arenas-Monroy, Andy Wilson, Mykle Hoban, Alexander Schmidt-Lebuhn, Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), Philip Chalmers (vectorized by T. Michael
Keesey), Ignacio Contreras, CNZdenek, Maxime Dahirel, C. Camilo
Julián-Caballero, Walter Vladimir, Michelle Site, Haplochromis
(vectorized by T. Michael Keesey), Ghedoghedo, Tasman Dixon, Ingo
Braasch, Joe Schneid (vectorized by T. Michael Keesey), Michael P.
Taylor, Mariana Ruiz (vectorized by T. Michael Keesey), Stephen O’Connor
(vectorized by T. Michael Keesey), FJDegrange, B. Duygu Özpolat, Lukas
Panzarin, Alex Slavenko, Chris huh, Ghedoghedo (vectorized by T. Michael
Keesey), Melissa Broussard, Mali’o Kodis, photograph property of
National Museums of Northern Ireland, Kevin Sánchez, Chloé Schmidt,
Rachel Shoop, Andrew A. Farke, Skye McDavid, Pedro de Siracusa, Nobu
Tamura, vectorized by Zimices, T. Michael Keesey (after Mauricio Antón),
Steven Traver, Arthur S. Brum, Roderic Page and Lois Page, Sharon
Wegner-Larsen, Christoph Schomburg, Kanchi Nanjo, Michele M Tobias,
Kamil S. Jaron, Eric Moody, Harold N Eyster, Michael Scroggie, Tauana J.
Cunha, Marmelad, Dmitry Bogdanov, Erika Schumacher, Mason McNair,
nicubunu, Kimberly Haddrell, Alexis Simon, Warren H (photography), T.
Michael Keesey (vectorization), xgirouxb, Christine Axon, Robert Bruce
Horsfall, vectorized by Zimices, Caleb M. Gordon, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Hans Hillewaert (vectorized by T.
Michael Keesey), Matt Dempsey, Mateus Zica (modified by T. Michael
Keesey), Henry Fairfield Osborn, vectorized by Zimices, Gabriela
Palomo-Munoz, James R. Spotila and Ray Chatterji, Kai R. Caspar, Jessica
Anne Miller, Juan Carlos Jerí, T. Michael Keesey (after Walker & al.),
Scott Hartman (vectorized by William Gearty), Matus Valach, Felix Vaux,
Jim Bendon (photography) and T. Michael Keesey (vectorization), Chuanixn
Yu, Fernando Carezzano, Julien Louys, James Neenan, Lily Hughes, Noah
Schlottman, Ben Liebeskind, Javiera Constanzo, Sebastian Stabinger,
Gopal Murali, Emily Willoughby, Matt Martyniuk (modified by Serenchia),
Verdilak, Luc Viatour (source photo) and Andreas Plank, Tod Robbins,
Agnello Picorelli, Yusan Yang, FunkMonk (Michael B. H.), Crystal Maier,
Jaime Headden, Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Kent Elson Sorgon, David
Liao, Mathieu Pélissié, Tim Bertelink (modified by T. Michael Keesey),
Sarah Werning, Joseph Smit (modified by T. Michael Keesey), Carlos
Cano-Barbacil, Sean McCann, T. Michael Keesey (vectorization) and
HuttyMcphoo (photography), Scott D. Sampson, Mark A. Loewen, Andrew A.
Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L.
Titus, Jake Warner, Richard J. Harris, Dianne Bray / Museum Victoria
(vectorized by T. Michael Keesey), Caleb M. Brown, Liftarn, Oscar
Sanisidro, Antonov (vectorized by T. Michael Keesey), Beth Reinke,
terngirl, Chase Brownstein, Mette Aumala, Eyal Bartov, Noah Schlottman,
photo from Moorea Biocode, FunkMonk, Katie S. Collins, T. Michael Keesey
(from a photo by Maximilian Paradiz), Iain Reid, Obsidian Soul
(vectorized by T. Michael Keesey), Andreas Trepte (vectorized by T.
Michael Keesey), Tom Tarrant (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Armelle Ansart (photograph), Maxime
Dahirel (digitisation), U.S. Fish and Wildlife Service (illustration)
and Timothy J. Bartley (silhouette), Yan Wong from illustration by
Charles Orbigny, Armin Reindl, Bennet McComish, photo by Avenue, Jessica
Rick, S.Martini, Becky Barnes, Xavier Giroux-Bougard, Amanda Katzer,
Anthony Caravaggi, Ludwik Gąsiorowski, Daniel Stadtmauer, Benjamint444,
L. Shyamal, (after Spotila 2004), JCGiron, Dmitry Bogdanov (modified by
T. Michael Keesey), James I. Kirkland, Luis Alcalá, Mark A. Loewen,
Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T.
Michael Keesey), Zimices, based in Mauricio Antón skeletal, Dmitry
Bogdanov and FunkMonk (vectorized by T. Michael Keesey), Lukasiniho,
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Michael Day, Adrian Reich, Maija Karala, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Mathieu Basille,
Noah Schlottman, photo from Casey Dunn, Francis de Laporte de Castelnau
(vectorized by T. Michael Keesey), Jiekun He, V. Deepak, Trond R.
Oskars, Michael Wolf (photo), Hans Hillewaert (editing), T. Michael
Keesey (vectorization), ArtFavor & annaleeblysse, DFoidl (vectorized by
T. Michael Keesey), Stanton F. Fink, vectorized by Zimices, Javier
Luque, SauropodomorphMonarch, Joseph Wolf, 1863 (vectorization by Dinah
Challen), Chris Jennings (Risiatto), Prin Pattawaro (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Matt Martyniuk,
Tyler Greenfield, Noah Schlottman, photo by Hans De Blauwe, Julia B
McHugh, Taro Maeda, Mercedes Yrayzoz (vectorized by T. Michael Keesey),
M Kolmann, Tracy A. Heath, Hugo Gruson, Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Matthew
E. Clapham, Karkemish (vectorized by T. Michael Keesey), Cristina
Guijarro, Yan Wong from photo by Gyik Toma, Ghedo (vectorized by T.
Michael Keesey), T. Michael Keesey (photo by J. M. Garg), Gordon E.
Robertson, Sarah Alewijnse, Unknown (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Kanako Bessho-Uehara, Anna
Willoughby, T. Michael Keesey and Tanetahi, C. W. Nash (illustration)
and Timothy J. Bartley (silhouette), Sergio A. Muñoz-Gómez,
Falconaumanni and T. Michael Keesey, Marcos Pérez-Losada, Jens T. Høeg &
Keith A. Crandall, Shyamal, Taenadoman, Jerry Oldenettel (vectorized by
T. Michael Keesey), Tony Ayling (vectorized by T. Michael Keesey), Conty
(vectorized by T. Michael Keesey), Ekaterina Kopeykina (vectorized by T.
Michael Keesey), Oliver Voigt, Acrocynus (vectorized by T. Michael
Keesey), LeonardoG (photography) and T. Michael Keesey (vectorization),
Matt Hayes, Mathew Wedel, François Michonneau, Chris Hay, Alexandre
Vong, Tomas Willems (vectorized by T. Michael Keesey), Mike Hanson,
Darren Naish (vectorized by T. Michael Keesey), Mali’o Kodis, image from
Higgins and Kristensen, 1986, Oren Peles / vectorized by Yan Wong,
Renata F. Martins, Xavier A. Jenkins, Gabriel Ugueto, Noah Schlottman,
photo by Reinhard Jahn, John Conway, Caio Bernardes, vectorized by
Zimices, Original drawing by Nobu Tamura, vectorized by Roberto Díaz
Sibaja, Andrés Sánchez, Nobu Tamura (modified by T. Michael Keesey),
Nina Skinner, Louis Ranjard, Mathilde Cordellier, Tommaso Cancellario,
Aleksey Nagovitsyn (vectorized by T. Michael Keesey), Ben Moon, Sarefo
(vectorized by T. Michael Keesey), Mareike C. Janiak, Philippe Janvier
(vectorized by T. Michael Keesey), Manabu Sakamoto, Kosta Mumcuoglu
(vectorized by T. Michael Keesey), Noah Schlottman, photo from National
Science Foundation - Turbellarian Taxonomic Database, mystica

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    844.349941 |    712.161349 | Steven Coombs                                                                                                                                                  |
|   2 |    844.240569 |    191.572283 | Gareth Monger                                                                                                                                                  |
|   3 |    566.963238 |    277.214854 | Margot Michaud                                                                                                                                                 |
|   4 |    174.868485 |    559.981189 | Matt Crook                                                                                                                                                     |
|   5 |    626.784865 |    757.629062 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                |
|   6 |    271.674260 |    252.527687 | Roberto Díaz Sibaja                                                                                                                                            |
|   7 |    229.163221 |    383.391097 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                     |
|   8 |    473.423124 |    561.219693 | NA                                                                                                                                                             |
|   9 |    673.927112 |    497.361541 | Margot Michaud                                                                                                                                                 |
|  10 |    769.740559 |    323.956348 | Margot Michaud                                                                                                                                                 |
|  11 |    415.782676 |     34.300698 | Jagged Fang Designs                                                                                                                                            |
|  12 |    585.124827 |     57.350351 | Matt Crook                                                                                                                                                     |
|  13 |    167.342667 |    149.523419 | Margot Michaud                                                                                                                                                 |
|  14 |    130.439580 |    319.027963 | Rebecca Groom                                                                                                                                                  |
|  15 |    395.202604 |    503.850475 | Martin R. Smith                                                                                                                                                |
|  16 |     71.201627 |    483.260682 | Ferran Sayol                                                                                                                                                   |
|  17 |    185.147236 |    715.451096 | Joanna Wolfe                                                                                                                                                   |
|  18 |    940.631724 |    551.526355 | Gareth Monger                                                                                                                                                  |
|  19 |    696.904391 |    176.792128 | DW Bapst (modified from Bulman, 1970)                                                                                                                          |
|  20 |    546.805724 |    419.879940 | Mo Hassan                                                                                                                                                      |
|  21 |     74.542943 |    265.544405 | Margot Michaud                                                                                                                                                 |
|  22 |    637.193224 |    331.870583 | Diana Pomeroy                                                                                                                                                  |
|  23 |    682.328340 |     53.911471 | Jagged Fang Designs                                                                                                                                            |
|  24 |    851.349165 |    612.846280 | Zimices                                                                                                                                                        |
|  25 |    847.376424 |    117.901132 | Cagri Cevrim                                                                                                                                                   |
|  26 |    265.983461 |    491.058581 | Leann Biancani, photo by Kenneth Clifton                                                                                                                       |
|  27 |    952.463058 |    117.415570 | Paul O. Lewis                                                                                                                                                  |
|  28 |    570.152055 |    242.267482 | Birgit Lang                                                                                                                                                    |
|  29 |    800.560487 |    674.372463 | T. K. Robinson                                                                                                                                                 |
|  30 |    443.309944 |    113.010848 | Zimices                                                                                                                                                        |
|  31 |    611.638480 |    660.049445 | Collin Gross                                                                                                                                                   |
|  32 |    295.829973 |    579.355945 | Zimices                                                                                                                                                        |
|  33 |    285.688343 |    116.464715 | Matt Crook                                                                                                                                                     |
|  34 |    482.184068 |    204.410059 | Matt Crook                                                                                                                                                     |
|  35 |    392.357746 |    656.432840 | Joanna Wolfe                                                                                                                                                   |
|  36 |    369.622477 |    178.817144 | Dean Schnabel                                                                                                                                                  |
|  37 |    950.971519 |    355.916390 | Gareth Monger                                                                                                                                                  |
|  38 |    764.753216 |    573.534161 | Markus A. Grohme                                                                                                                                               |
|  39 |    690.807053 |    260.488390 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  40 |     60.202865 |    664.526639 | Mattia Menchetti                                                                                                                                               |
|  41 |     63.966049 |    101.816902 | T. Michael Keesey (after MPF)                                                                                                                                  |
|  42 |    195.682307 |     38.622995 | T. Michael Keesey                                                                                                                                              |
|  43 |    537.201595 |    610.281135 | Matt Crook                                                                                                                                                     |
|  44 |    705.132787 |    588.574243 | Scott Hartman                                                                                                                                                  |
|  45 |    399.059014 |    310.740190 | Felix Vaux and Steven A. Trewick                                                                                                                               |
|  46 |    500.934352 |    731.288383 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                    |
|  47 |    926.960878 |    747.944914 | Jose Carlos Arenas-Monroy                                                                                                                                      |
|  48 |    795.148085 |    472.443291 | Andy Wilson                                                                                                                                                    |
|  49 |    815.916689 |    408.010862 | Mykle Hoban                                                                                                                                                    |
|  50 |    119.210230 |    232.871295 | Margot Michaud                                                                                                                                                 |
|  51 |    134.564759 |    433.877303 | Alexander Schmidt-Lebuhn                                                                                                                                       |
|  52 |    389.902078 |    747.625997 | NA                                                                                                                                                             |
|  53 |    341.858307 |    405.839275 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                             |
|  54 |    291.942837 |    673.643037 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                              |
|  55 |    519.988157 |    490.134467 | Markus A. Grohme                                                                                                                                               |
|  56 |    654.716238 |    106.860737 | Ignacio Contreras                                                                                                                                              |
|  57 |    709.085082 |    452.776069 | Gareth Monger                                                                                                                                                  |
|  58 |    787.350607 |     39.439227 | CNZdenek                                                                                                                                                       |
|  59 |    938.937657 |     32.081631 | NA                                                                                                                                                             |
|  60 |    971.208099 |    233.018542 | Maxime Dahirel                                                                                                                                                 |
|  61 |     68.601356 |    766.307244 | C. Camilo Julián-Caballero                                                                                                                                     |
|  62 |    199.808001 |    644.034716 | NA                                                                                                                                                             |
|  63 |    611.144880 |    138.284236 | Walter Vladimir                                                                                                                                                |
|  64 |    894.265628 |    438.775838 | Michelle Site                                                                                                                                                  |
|  65 |    812.411238 |    778.654894 | Ignacio Contreras                                                                                                                                              |
|  66 |    783.995036 |    537.079100 | Birgit Lang                                                                                                                                                    |
|  67 |    191.461605 |    195.512708 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
|  68 |    647.095721 |    721.537072 | Ignacio Contreras                                                                                                                                              |
|  69 |    948.450831 |    661.148335 | NA                                                                                                                                                             |
|  70 |    178.428039 |     89.646928 | Ghedoghedo                                                                                                                                                     |
|  71 |    224.236411 |    150.213366 | Tasman Dixon                                                                                                                                                   |
|  72 |    810.851862 |     11.327816 | Ingo Braasch                                                                                                                                                   |
|  73 |    258.557248 |     60.708076 | Matt Crook                                                                                                                                                     |
|  74 |    658.854355 |    224.936859 | Matt Crook                                                                                                                                                     |
|  75 |    881.383412 |    539.420570 | Margot Michaud                                                                                                                                                 |
|  76 |     99.680497 |     27.856539 | Matt Crook                                                                                                                                                     |
|  77 |     49.105196 |    781.888412 | Jagged Fang Designs                                                                                                                                            |
|  78 |    309.504684 |    466.914407 | Margot Michaud                                                                                                                                                 |
|  79 |    124.969654 |    679.990715 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                  |
|  80 |    230.220326 |      7.721729 | Diana Pomeroy                                                                                                                                                  |
|  81 |    566.934078 |    595.084929 | Michael P. Taylor                                                                                                                                              |
|  82 |    759.680247 |    711.453755 | Ignacio Contreras                                                                                                                                              |
|  83 |    631.280596 |    513.597010 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                 |
|  84 |     58.063359 |    351.806450 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                             |
|  85 |    874.675183 |    147.242502 | T. Michael Keesey (after MPF)                                                                                                                                  |
|  86 |    709.776666 |    306.716429 | FJDegrange                                                                                                                                                     |
|  87 |    518.173267 |    127.625541 | NA                                                                                                                                                             |
|  88 |    188.165233 |    346.048367 | Matt Crook                                                                                                                                                     |
|  89 |    538.530907 |    319.622196 | B. Duygu Özpolat                                                                                                                                               |
|  90 |    204.003695 |    605.880926 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  91 |    551.726796 |    542.892986 | Lukas Panzarin                                                                                                                                                 |
|  92 |    906.646571 |    251.443274 | Matt Crook                                                                                                                                                     |
|  93 |    827.143789 |    740.433448 | Alex Slavenko                                                                                                                                                  |
|  94 |    660.807129 |    298.479138 | Chris huh                                                                                                                                                      |
|  95 |    313.410421 |    312.104138 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
|  96 |    986.264569 |    470.396555 | Melissa Broussard                                                                                                                                              |
|  97 |    737.600149 |    547.384425 | Gareth Monger                                                                                                                                                  |
|  98 |    706.735901 |    364.391779 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                      |
|  99 |    596.495835 |    207.292646 | Zimices                                                                                                                                                        |
| 100 |     75.326264 |    204.983448 | Ghedoghedo                                                                                                                                                     |
| 101 |    682.370317 |    383.362305 | Andy Wilson                                                                                                                                                    |
| 102 |    805.320659 |    694.679458 | Chris huh                                                                                                                                                      |
| 103 |    758.876936 |    584.160888 | Margot Michaud                                                                                                                                                 |
| 104 |    651.812113 |     81.073898 | Ignacio Contreras                                                                                                                                              |
| 105 |    608.451033 |    599.637994 | Andy Wilson                                                                                                                                                    |
| 106 |    848.693155 |    577.491689 | Scott Hartman                                                                                                                                                  |
| 107 |    193.673617 |    488.889217 | Kevin Sánchez                                                                                                                                                  |
| 108 |    265.008965 |    379.869138 | Chloé Schmidt                                                                                                                                                  |
| 109 |    297.859521 |    413.126595 | Rachel Shoop                                                                                                                                                   |
| 110 |    990.817900 |    147.423227 | Andrew A. Farke                                                                                                                                                |
| 111 |     97.537513 |    388.550000 | Margot Michaud                                                                                                                                                 |
| 112 |    973.497169 |    550.420060 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 113 |    695.550996 |     22.480221 | Scott Hartman                                                                                                                                                  |
| 114 |    240.008285 |    324.240290 | Skye McDavid                                                                                                                                                   |
| 115 |    258.575226 |    715.641336 | Scott Hartman                                                                                                                                                  |
| 116 |    521.069718 |    514.973422 | Jagged Fang Designs                                                                                                                                            |
| 117 |    998.388301 |    583.392354 | Matt Crook                                                                                                                                                     |
| 118 |    863.084109 |    342.946267 | Pedro de Siracusa                                                                                                                                              |
| 119 |    989.671723 |    435.110529 | Matt Crook                                                                                                                                                     |
| 120 |    591.258475 |    576.493092 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                     |
| 121 |    356.402384 |    792.549055 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 122 |    245.144734 |    401.322439 | T. Michael Keesey (after Mauricio Antón)                                                                                                                       |
| 123 |    574.560933 |    512.913272 | T. Michael Keesey                                                                                                                                              |
| 124 |    630.098568 |    593.813338 | Steven Traver                                                                                                                                                  |
| 125 |     13.716114 |    294.124262 | T. Michael Keesey                                                                                                                                              |
| 126 |    759.287816 |    738.918377 | Arthur S. Brum                                                                                                                                                 |
| 127 |    899.823351 |    677.527968 | Gareth Monger                                                                                                                                                  |
| 128 |    376.050740 |     72.960501 | Steven Traver                                                                                                                                                  |
| 129 |    980.193672 |    782.371565 | Michelle Site                                                                                                                                                  |
| 130 |    811.776195 |    100.500437 | Margot Michaud                                                                                                                                                 |
| 131 |    456.807594 |    713.403934 | Roderic Page and Lois Page                                                                                                                                     |
| 132 |    378.786089 |    344.747266 | Sharon Wegner-Larsen                                                                                                                                           |
| 133 |    164.970107 |    362.659443 | Christoph Schomburg                                                                                                                                            |
| 134 |    147.632492 |    261.334482 | Kanchi Nanjo                                                                                                                                                   |
| 135 |    232.392907 |    446.043807 | Michele M Tobias                                                                                                                                               |
| 136 |    772.480284 |    344.977405 | Kamil S. Jaron                                                                                                                                                 |
| 137 |    590.303651 |    223.814036 | Birgit Lang                                                                                                                                                    |
| 138 |    546.250906 |    477.822238 | Markus A. Grohme                                                                                                                                               |
| 139 |    349.283062 |    154.991228 | Eric Moody                                                                                                                                                     |
| 140 |    421.675822 |    351.859035 | Margot Michaud                                                                                                                                                 |
| 141 |    400.747134 |     75.451262 | Steven Traver                                                                                                                                                  |
| 142 |      8.873367 |    601.075731 | Harold N Eyster                                                                                                                                                |
| 143 |    699.131007 |     70.189655 | Michael Scroggie                                                                                                                                               |
| 144 |     28.981597 |     22.398284 | Tauana J. Cunha                                                                                                                                                |
| 145 |     46.480433 |    733.789917 | Margot Michaud                                                                                                                                                 |
| 146 |    491.975086 |    339.472202 | Andy Wilson                                                                                                                                                    |
| 147 |    393.052655 |    234.846550 | Marmelad                                                                                                                                                       |
| 148 |     48.847446 |    325.798828 | Steven Coombs                                                                                                                                                  |
| 149 |    994.791363 |    449.610213 | Dmitry Bogdanov                                                                                                                                                |
| 150 |    157.054287 |    502.153390 | Erika Schumacher                                                                                                                                               |
| 151 |    529.057117 |    358.187784 | Mason McNair                                                                                                                                                   |
| 152 |     11.969995 |     88.354433 | Andy Wilson                                                                                                                                                    |
| 153 |    572.773261 |    696.571168 | nicubunu                                                                                                                                                       |
| 154 |    905.408603 |     53.497721 | Kimberly Haddrell                                                                                                                                              |
| 155 |    611.850589 |     70.176060 | Christoph Schomburg                                                                                                                                            |
| 156 |    551.612220 |    565.417829 | Alexis Simon                                                                                                                                                   |
| 157 |    775.395620 |    654.959715 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                      |
| 158 |    838.951490 |    272.276552 | Ferran Sayol                                                                                                                                                   |
| 159 |    481.186336 |     79.700580 | Zimices                                                                                                                                                        |
| 160 |    895.718160 |    223.605931 | xgirouxb                                                                                                                                                       |
| 161 |    822.068482 |     85.237597 | Christine Axon                                                                                                                                                 |
| 162 |    210.136131 |    475.885652 | Andy Wilson                                                                                                                                                    |
| 163 |    173.035985 |    120.720841 | NA                                                                                                                                                             |
| 164 |    908.560138 |    534.561961 | Andrew A. Farke                                                                                                                                                |
| 165 |    168.450435 |    419.681937 | Andy Wilson                                                                                                                                                    |
| 166 |    471.668845 |    305.135796 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                   |
| 167 |    512.870191 |    297.018976 | Caleb M. Gordon                                                                                                                                                |
| 168 |    744.577182 |    217.480103 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 169 |    136.592899 |    109.708515 | NA                                                                                                                                                             |
| 170 |    740.475815 |    623.989943 | Michael Scroggie                                                                                                                                               |
| 171 |    375.360196 |    718.037084 | Margot Michaud                                                                                                                                                 |
| 172 |     89.016801 |    612.489674 | C. Camilo Julián-Caballero                                                                                                                                     |
| 173 |     23.758336 |    761.216876 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 174 |    309.377673 |     42.485339 | T. Michael Keesey                                                                                                                                              |
| 175 |    429.979666 |    467.918308 | Chris huh                                                                                                                                                      |
| 176 |    594.394260 |    633.998774 | Matt Dempsey                                                                                                                                                   |
| 177 |    358.895665 |    349.860224 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                    |
| 178 |    794.254735 |    289.503148 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                  |
| 179 |     66.517262 |    337.419813 | NA                                                                                                                                                             |
| 180 |    626.244455 |    174.287015 | Scott Hartman                                                                                                                                                  |
| 181 |    706.415415 |    541.343655 | Gabriela Palomo-Munoz                                                                                                                                          |
| 182 |    936.000134 |    281.552280 | Jagged Fang Designs                                                                                                                                            |
| 183 |    734.531225 |    342.571663 | Zimices                                                                                                                                                        |
| 184 |    397.996420 |    347.980442 | Zimices                                                                                                                                                        |
| 185 |    219.693985 |    455.008906 | NA                                                                                                                                                             |
| 186 |    531.767988 |    567.073374 | Maxime Dahirel                                                                                                                                                 |
| 187 |    209.935120 |    284.835722 | Steven Coombs                                                                                                                                                  |
| 188 |    811.745077 |    794.773298 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 189 |    275.572591 |    404.417130 | Andy Wilson                                                                                                                                                    |
| 190 |    602.452217 |    520.857996 | NA                                                                                                                                                             |
| 191 |    106.442893 |    191.802699 | xgirouxb                                                                                                                                                       |
| 192 |    552.355882 |    175.498143 | Tasman Dixon                                                                                                                                                   |
| 193 |    950.623816 |    171.706644 | Gareth Monger                                                                                                                                                  |
| 194 |    438.881108 |    545.657469 | Zimices                                                                                                                                                        |
| 195 |      9.006150 |    244.967676 | Matt Crook                                                                                                                                                     |
| 196 |    564.884208 |    620.172336 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 197 |    150.105873 |     51.407740 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 198 |     14.254069 |    543.868932 | Mason McNair                                                                                                                                                   |
| 199 |    747.347797 |    476.918499 | NA                                                                                                                                                             |
| 200 |    735.961680 |    160.409141 | Rebecca Groom                                                                                                                                                  |
| 201 |    515.644568 |    632.505951 | NA                                                                                                                                                             |
| 202 |    162.377429 |    342.713463 | Steven Traver                                                                                                                                                  |
| 203 |    273.825479 |    605.750413 | NA                                                                                                                                                             |
| 204 |    969.490219 |    792.251093 | Alex Slavenko                                                                                                                                                  |
| 205 |    921.345684 |    233.678585 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 206 |    608.398085 |    783.802920 | Kai R. Caspar                                                                                                                                                  |
| 207 |    499.168845 |      7.191815 | Matt Crook                                                                                                                                                     |
| 208 |   1007.597715 |    305.316929 | FJDegrange                                                                                                                                                     |
| 209 |    994.512075 |    648.033314 | Steven Traver                                                                                                                                                  |
| 210 |   1003.206094 |     31.901226 | Matt Crook                                                                                                                                                     |
| 211 |    987.783645 |    122.664353 | Jessica Anne Miller                                                                                                                                            |
| 212 |     78.249751 |    639.326174 | Ferran Sayol                                                                                                                                                   |
| 213 |    224.084963 |    631.564779 | Juan Carlos Jerí                                                                                                                                               |
| 214 |     84.321183 |    179.458007 | Michael Scroggie                                                                                                                                               |
| 215 |    138.212675 |    623.541728 | Andy Wilson                                                                                                                                                    |
| 216 |   1019.802941 |    694.964209 | T. Michael Keesey (after Walker & al.)                                                                                                                         |
| 217 |    438.628902 |    776.966773 | Scott Hartman (vectorized by William Gearty)                                                                                                                   |
| 218 |    472.951594 |    729.328541 | Matus Valach                                                                                                                                                   |
| 219 |    249.482658 |    624.910324 | Matt Crook                                                                                                                                                     |
| 220 |    547.381251 |    347.772364 | Birgit Lang                                                                                                                                                    |
| 221 |    825.668429 |     13.956302 | Matt Crook                                                                                                                                                     |
| 222 |    452.186312 |    304.493751 | Felix Vaux                                                                                                                                                     |
| 223 |    825.349656 |    298.655242 | Gareth Monger                                                                                                                                                  |
| 224 |    461.222411 |    317.149719 | Steven Traver                                                                                                                                                  |
| 225 |    267.836819 |    769.803646 | Ignacio Contreras                                                                                                                                              |
| 226 |    203.552227 |    118.221397 | Andy Wilson                                                                                                                                                    |
| 227 |    865.608328 |     67.921930 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                 |
| 228 |    107.867873 |    108.166981 | Chuanixn Yu                                                                                                                                                    |
| 229 |    501.440800 |    294.320902 | Fernando Carezzano                                                                                                                                             |
| 230 |    186.133007 |    291.240797 | Steven Traver                                                                                                                                                  |
| 231 |    573.792309 |    532.815927 | Steven Traver                                                                                                                                                  |
| 232 |   1005.333767 |    136.244258 | NA                                                                                                                                                             |
| 233 |    222.521709 |    360.475844 | Felix Vaux                                                                                                                                                     |
| 234 |    393.648187 |    216.902698 | Julien Louys                                                                                                                                                   |
| 235 |    799.043094 |    499.117609 | Andrew A. Farke                                                                                                                                                |
| 236 |    976.209456 |    718.900295 | Ferran Sayol                                                                                                                                                   |
| 237 |    126.350559 |    641.338418 | James Neenan                                                                                                                                                   |
| 238 |    863.750322 |    360.802408 | Lily Hughes                                                                                                                                                    |
| 239 |    887.938085 |    319.930047 | Noah Schlottman                                                                                                                                                |
| 240 |    663.735179 |    471.511582 | Ben Liebeskind                                                                                                                                                 |
| 241 |    441.524069 |    487.911397 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 242 |    316.526588 |    664.870957 | Matt Crook                                                                                                                                                     |
| 243 |    738.854341 |    699.675785 | Matt Crook                                                                                                                                                     |
| 244 |    277.836151 |    188.544491 | Javiera Constanzo                                                                                                                                              |
| 245 |    909.238891 |    627.248345 | Birgit Lang                                                                                                                                                    |
| 246 |     27.855176 |    372.960124 | Sebastian Stabinger                                                                                                                                            |
| 247 |    294.235531 |    767.374902 | Dmitry Bogdanov                                                                                                                                                |
| 248 |    240.255634 |    385.321518 | Gopal Murali                                                                                                                                                   |
| 249 |    659.593072 |    190.805711 | Matt Crook                                                                                                                                                     |
| 250 |    524.637254 |    771.904065 | Emily Willoughby                                                                                                                                               |
| 251 |    792.567286 |     70.780003 | Mykle Hoban                                                                                                                                                    |
| 252 |    697.858779 |    785.795316 | Matt Martyniuk (modified by Serenchia)                                                                                                                         |
| 253 |    375.769859 |    220.354612 | C. Camilo Julián-Caballero                                                                                                                                     |
| 254 |    775.789895 |    378.613763 | Verdilak                                                                                                                                                       |
| 255 |    161.799961 |    328.175432 | Scott Hartman                                                                                                                                                  |
| 256 |    737.031373 |    678.328888 | Birgit Lang                                                                                                                                                    |
| 257 |    588.852284 |    486.682166 | NA                                                                                                                                                             |
| 258 |    484.884146 |    284.775521 | T. Michael Keesey                                                                                                                                              |
| 259 |    757.894050 |    438.027021 | Luc Viatour (source photo) and Andreas Plank                                                                                                                   |
| 260 |    313.882019 |     63.190246 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 261 |    490.305190 |    754.870009 | Steven Coombs                                                                                                                                                  |
| 262 |    262.632499 |    754.425544 | Jagged Fang Designs                                                                                                                                            |
| 263 |    361.762653 |    132.083246 | Kai R. Caspar                                                                                                                                                  |
| 264 |    350.747427 |     52.836425 | NA                                                                                                                                                             |
| 265 |    909.160264 |    182.145856 | NA                                                                                                                                                             |
| 266 |    508.362686 |     60.155811 | Tod Robbins                                                                                                                                                    |
| 267 |    901.386984 |     57.774759 | Jagged Fang Designs                                                                                                                                            |
| 268 |    745.734311 |    189.847261 | Steven Traver                                                                                                                                                  |
| 269 |    575.030194 |    730.563160 | CNZdenek                                                                                                                                                       |
| 270 |    749.566973 |    233.887485 | Birgit Lang                                                                                                                                                    |
| 271 |     36.401299 |    199.624793 | Andy Wilson                                                                                                                                                    |
| 272 |    778.153041 |    616.964432 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 273 |    110.097163 |    717.797729 | Agnello Picorelli                                                                                                                                              |
| 274 |     33.518363 |    307.439792 | Matt Crook                                                                                                                                                     |
| 275 |     60.723315 |    370.824196 | Yusan Yang                                                                                                                                                     |
| 276 |    397.041362 |    709.673276 | Jagged Fang Designs                                                                                                                                            |
| 277 |    932.803431 |     62.389303 | Zimices                                                                                                                                                        |
| 278 |    256.311733 |     84.591358 | Margot Michaud                                                                                                                                                 |
| 279 |    763.671833 |     95.846283 | Gareth Monger                                                                                                                                                  |
| 280 |    802.065056 |    753.333695 | FunkMonk (Michael B. H.)                                                                                                                                       |
| 281 |    671.551793 |    145.058828 | Matt Crook                                                                                                                                                     |
| 282 |    826.575462 |    505.239656 | Gareth Monger                                                                                                                                                  |
| 283 |    356.331536 |    510.480779 | Margot Michaud                                                                                                                                                 |
| 284 |    656.277422 |    705.312727 | Crystal Maier                                                                                                                                                  |
| 285 |    145.970044 |    507.920883 | Markus A. Grohme                                                                                                                                               |
| 286 |    400.930789 |    249.717964 | NA                                                                                                                                                             |
| 287 |    908.289416 |    516.060272 | Ferran Sayol                                                                                                                                                   |
| 288 |    353.560362 |    546.531559 | NA                                                                                                                                                             |
| 289 |    836.102897 |    319.226374 | Margot Michaud                                                                                                                                                 |
| 290 |    763.221487 |     84.885079 | Ignacio Contreras                                                                                                                                              |
| 291 |    366.641736 |    153.759504 | Birgit Lang                                                                                                                                                    |
| 292 |     18.929595 |    338.061558 | T. Michael Keesey                                                                                                                                              |
| 293 |    981.509582 |    565.494435 | Jaime Headden                                                                                                                                                  |
| 294 |    778.832931 |    504.917200 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 295 |    992.891431 |    637.531372 | Kent Elson Sorgon                                                                                                                                              |
| 296 |    726.202698 |    304.033731 | NA                                                                                                                                                             |
| 297 |     86.252728 |    368.481456 | Zimices                                                                                                                                                        |
| 298 |    481.253936 |    685.356506 | Scott Hartman                                                                                                                                                  |
| 299 |    159.962167 |    269.496437 | C. Camilo Julián-Caballero                                                                                                                                     |
| 300 |    326.319029 |    427.866350 | Gareth Monger                                                                                                                                                  |
| 301 |    994.037248 |    761.668809 | David Liao                                                                                                                                                     |
| 302 |    971.646986 |     57.395790 | Mathieu Pélissié                                                                                                                                               |
| 303 |    362.799826 |    647.676852 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                  |
| 304 |    929.531123 |    691.957378 | T. Michael Keesey                                                                                                                                              |
| 305 |    315.695895 |    533.473512 | Chris huh                                                                                                                                                      |
| 306 |    833.037350 |    476.649740 | Gabriela Palomo-Munoz                                                                                                                                          |
| 307 |    848.523182 |    287.982037 | Margot Michaud                                                                                                                                                 |
| 308 |    799.851050 |    465.879213 | Sarah Werning                                                                                                                                                  |
| 309 |    661.143769 |    596.484456 | Dean Schnabel                                                                                                                                                  |
| 310 |    903.399966 |    554.943597 | Collin Gross                                                                                                                                                   |
| 311 |    736.457579 |     14.545809 | Matt Crook                                                                                                                                                     |
| 312 |    252.398631 |    734.828578 | Emily Willoughby                                                                                                                                               |
| 313 |    378.494229 |    698.088976 | NA                                                                                                                                                             |
| 314 |    286.025682 |    729.255987 | Margot Michaud                                                                                                                                                 |
| 315 |   1019.057705 |    785.000593 | Andy Wilson                                                                                                                                                    |
| 316 |    579.693122 |    611.474994 | Gabriela Palomo-Munoz                                                                                                                                          |
| 317 |    488.877965 |    676.607470 | NA                                                                                                                                                             |
| 318 |    876.779260 |    397.101897 | Scott Hartman                                                                                                                                                  |
| 319 |    259.430111 |    179.304300 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                    |
| 320 |    537.967477 |    710.874560 | Zimices                                                                                                                                                        |
| 321 |    646.416436 |    136.242195 | Carlos Cano-Barbacil                                                                                                                                           |
| 322 |    691.586789 |    372.542617 | Sean McCann                                                                                                                                                    |
| 323 |    345.782348 |    518.761558 | Margot Michaud                                                                                                                                                 |
| 324 |    171.961950 |    794.464420 | Zimices                                                                                                                                                        |
| 325 |    201.670589 |    104.651858 | Gareth Monger                                                                                                                                                  |
| 326 |    766.720032 |    288.416500 | Steven Traver                                                                                                                                                  |
| 327 |     41.400969 |    283.675394 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                |
| 328 |    782.347065 |     36.609888 | Zimices                                                                                                                                                        |
| 329 |    866.771431 |     34.226727 | Matt Crook                                                                                                                                                     |
| 330 |    472.021523 |    659.423644 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                       |
| 331 |    369.690871 |    246.340014 | Jake Warner                                                                                                                                                    |
| 332 |    902.576242 |    644.770037 | Richard J. Harris                                                                                                                                              |
| 333 |    280.818456 |     42.280573 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                |
| 334 |    919.836364 |    214.880533 | Jagged Fang Designs                                                                                                                                            |
| 335 |    817.928358 |    451.131264 | Roberto Díaz Sibaja                                                                                                                                            |
| 336 |    563.723041 |    553.857496 | Caleb M. Brown                                                                                                                                                 |
| 337 |    737.726203 |    482.446801 | Crystal Maier                                                                                                                                                  |
| 338 |    878.688478 |     65.606338 | Andrew A. Farke                                                                                                                                                |
| 339 |    232.489020 |    304.834539 | Steven Traver                                                                                                                                                  |
| 340 |   1016.400461 |     48.949233 | Margot Michaud                                                                                                                                                 |
| 341 |    321.098131 |    704.934863 | Zimices                                                                                                                                                        |
| 342 |    933.268049 |    442.540657 | Matt Crook                                                                                                                                                     |
| 343 |    877.076872 |    675.034925 | Liftarn                                                                                                                                                        |
| 344 |     96.549379 |    681.631576 | Markus A. Grohme                                                                                                                                               |
| 345 |    646.301948 |    247.520422 | Oscar Sanisidro                                                                                                                                                |
| 346 |    337.149511 |     70.317536 | Ferran Sayol                                                                                                                                                   |
| 347 |    554.953307 |    781.610060 | Chris huh                                                                                                                                                      |
| 348 |    322.417988 |    338.874123 | Roberto Díaz Sibaja                                                                                                                                            |
| 349 |    105.834440 |    770.342527 | Gareth Monger                                                                                                                                                  |
| 350 |    619.723458 |    192.308310 | Antonov (vectorized by T. Michael Keesey)                                                                                                                      |
| 351 |    317.460209 |    283.973862 | Gareth Monger                                                                                                                                                  |
| 352 |    324.667830 |    486.802706 | Beth Reinke                                                                                                                                                    |
| 353 |    952.423351 |    451.066068 | terngirl                                                                                                                                                       |
| 354 |    889.046551 |     83.909439 | Chris huh                                                                                                                                                      |
| 355 |    114.094232 |    173.771411 | Zimices                                                                                                                                                        |
| 356 |    740.253543 |     94.506347 | Kanchi Nanjo                                                                                                                                                   |
| 357 |    854.110769 |    178.120126 | Gareth Monger                                                                                                                                                  |
| 358 |    917.067581 |    156.047117 | Zimices                                                                                                                                                        |
| 359 |    416.626266 |    378.451140 | Chase Brownstein                                                                                                                                               |
| 360 |    297.768538 |    366.827808 | Steven Traver                                                                                                                                                  |
| 361 |     22.498275 |    506.274107 | Zimices                                                                                                                                                        |
| 362 |    152.430851 |    212.232804 | Mette Aumala                                                                                                                                                   |
| 363 |    588.881666 |     85.417443 | Gareth Monger                                                                                                                                                  |
| 364 |    314.681150 |    188.299533 | Jagged Fang Designs                                                                                                                                            |
| 365 |     98.533475 |    374.993721 | Matt Crook                                                                                                                                                     |
| 366 |    101.111767 |      5.377370 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 367 |    674.425214 |     93.477129 | Ignacio Contreras                                                                                                                                              |
| 368 |    236.344917 |    554.400861 | Christoph Schomburg                                                                                                                                            |
| 369 |   1009.845227 |    389.064756 | Steven Traver                                                                                                                                                  |
| 370 |    552.948391 |      8.010532 | Matt Crook                                                                                                                                                     |
| 371 |    258.165670 |    417.789392 | Steven Traver                                                                                                                                                  |
| 372 |    495.320221 |    517.256003 | Eyal Bartov                                                                                                                                                    |
| 373 |    564.224184 |    355.462329 | Noah Schlottman, photo from Moorea Biocode                                                                                                                     |
| 374 |    352.336172 |    180.050152 | FunkMonk                                                                                                                                                       |
| 375 |    781.272237 |    592.517926 | Ferran Sayol                                                                                                                                                   |
| 376 |   1009.543483 |    162.682661 | Mykle Hoban                                                                                                                                                    |
| 377 |    442.717634 |    270.859111 | Katie S. Collins                                                                                                                                               |
| 378 |    476.193276 |    321.108607 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                         |
| 379 |    262.869175 |    204.941309 | Iain Reid                                                                                                                                                      |
| 380 |    620.020266 |    222.956643 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 381 |    516.920108 |     89.657218 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 382 |     32.943323 |    227.541722 | Jagged Fang Designs                                                                                                                                            |
| 383 |    532.591031 |    619.972501 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                               |
| 384 |    421.395863 |    232.749706 | Chase Brownstein                                                                                                                                               |
| 385 |    938.328891 |    623.067213 | Scott Hartman                                                                                                                                                  |
| 386 |     52.912266 |    600.367733 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 387 |    191.156212 |    219.877525 | Ferran Sayol                                                                                                                                                   |
| 388 |    737.797363 |    643.419028 | NA                                                                                                                                                             |
| 389 |    433.696477 |    419.582129 | Zimices                                                                                                                                                        |
| 390 |    126.784188 |     69.230655 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                     |
| 391 |    749.053201 |    455.096484 | Kent Elson Sorgon                                                                                                                                              |
| 392 |    436.011502 |    152.232713 | Matt Crook                                                                                                                                                     |
| 393 |    145.559951 |    516.533896 | Chloé Schmidt                                                                                                                                                  |
| 394 |    842.573189 |    500.536642 | T. Michael Keesey                                                                                                                                              |
| 395 |    286.052818 |    313.646975 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 396 |    758.593829 |    246.300228 | NA                                                                                                                                                             |
| 397 |    324.155600 |    399.960147 | Gareth Monger                                                                                                                                                  |
| 398 |    867.249331 |    379.785940 | Gabriela Palomo-Munoz                                                                                                                                          |
| 399 |    976.917318 |    581.401616 | Yan Wong from illustration by Charles Orbigny                                                                                                                  |
| 400 |    335.143354 |      6.572606 | Lily Hughes                                                                                                                                                    |
| 401 |     41.479206 |    587.236721 | Armin Reindl                                                                                                                                                   |
| 402 |    111.796578 |    612.895201 | Gabriela Palomo-Munoz                                                                                                                                          |
| 403 |    693.013697 |    467.095628 | Bennet McComish, photo by Avenue                                                                                                                               |
| 404 |    763.432452 |    108.232512 | Kamil S. Jaron                                                                                                                                                 |
| 405 |    773.738027 |    278.143626 | Jessica Rick                                                                                                                                                   |
| 406 |    905.923950 |    491.661427 | Scott Hartman                                                                                                                                                  |
| 407 |     24.469284 |    574.980270 | S.Martini                                                                                                                                                      |
| 408 |    425.019700 |     80.930136 | Gabriela Palomo-Munoz                                                                                                                                          |
| 409 |    119.875696 |    594.300351 | Becky Barnes                                                                                                                                                   |
| 410 |    954.912762 |    418.109974 | NA                                                                                                                                                             |
| 411 |    848.230413 |    540.885342 | Xavier Giroux-Bougard                                                                                                                                          |
| 412 |    699.814002 |     45.779243 | Sarah Werning                                                                                                                                                  |
| 413 |    191.476097 |    277.847707 | Amanda Katzer                                                                                                                                                  |
| 414 |     96.449447 |    450.726722 | NA                                                                                                                                                             |
| 415 |    835.656297 |    364.697413 | Anthony Caravaggi                                                                                                                                              |
| 416 |    781.077745 |    491.948356 | Zimices                                                                                                                                                        |
| 417 |    559.018656 |    665.757603 | Gabriela Palomo-Munoz                                                                                                                                          |
| 418 |    391.055650 |    393.610359 | Matt Crook                                                                                                                                                     |
| 419 |    658.756591 |    371.758955 | Scott Hartman                                                                                                                                                  |
| 420 |    352.194093 |    484.193840 | Jagged Fang Designs                                                                                                                                            |
| 421 |     87.207939 |    729.729411 | Ludwik Gąsiorowski                                                                                                                                             |
| 422 |     55.536712 |    284.947762 | Oscar Sanisidro                                                                                                                                                |
| 423 |    993.818718 |      9.048042 | Roberto Díaz Sibaja                                                                                                                                            |
| 424 |    504.337669 |    789.488462 | Daniel Stadtmauer                                                                                                                                              |
| 425 |      8.498341 |    772.911381 | Gareth Monger                                                                                                                                                  |
| 426 |     45.559100 |     30.470368 | Gareth Monger                                                                                                                                                  |
| 427 |     38.381320 |    177.482514 | Jaime Headden                                                                                                                                                  |
| 428 |   1004.900430 |    462.633796 | Ferran Sayol                                                                                                                                                   |
| 429 |     38.631627 |     11.772906 | Birgit Lang                                                                                                                                                    |
| 430 |    628.081927 |     81.263856 | Gabriela Palomo-Munoz                                                                                                                                          |
| 431 |   1020.399882 |    118.220618 | Benjamint444                                                                                                                                                   |
| 432 |    630.228849 |    482.386564 | Andy Wilson                                                                                                                                                    |
| 433 |    420.758638 |    633.678941 | Melissa Broussard                                                                                                                                              |
| 434 |    395.352139 |     87.250056 | Zimices                                                                                                                                                        |
| 435 |    539.899170 |    654.973058 | NA                                                                                                                                                             |
| 436 |    318.852653 |    757.071648 | L. Shyamal                                                                                                                                                     |
| 437 |    108.446453 |     79.108705 | Zimices                                                                                                                                                        |
| 438 |    894.040248 |    606.498698 | Jagged Fang Designs                                                                                                                                            |
| 439 |    717.955192 |    138.971517 | Ferran Sayol                                                                                                                                                   |
| 440 |    678.106781 |    610.534584 | (after Spotila 2004)                                                                                                                                           |
| 441 |    415.239844 |    703.168291 | JCGiron                                                                                                                                                        |
| 442 |    545.804263 |    741.948188 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                |
| 443 |    983.850393 |     12.922337 | Chris huh                                                                                                                                                      |
| 444 |    156.512929 |    289.958733 | Gareth Monger                                                                                                                                                  |
| 445 |    726.988883 |    177.028598 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                           |
| 446 |    883.694273 |    634.136881 | Tasman Dixon                                                                                                                                                   |
| 447 |     50.040480 |    583.761533 | Zimices, based in Mauricio Antón skeletal                                                                                                                      |
| 448 |    605.600143 |    481.165047 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                 |
| 449 |     18.480430 |    622.680758 | Collin Gross                                                                                                                                                   |
| 450 |    557.705887 |    503.907658 | Steven Traver                                                                                                                                                  |
| 451 |    804.295741 |    506.512927 | Tasman Dixon                                                                                                                                                   |
| 452 |    387.532147 |    610.352219 | Lukasiniho                                                                                                                                                     |
| 453 |    609.901789 |    293.278728 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 454 |    776.902857 |    792.702981 | Noah Schlottman                                                                                                                                                |
| 455 |    558.206677 |    318.486933 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 456 |    261.485473 |      9.434158 | Anthony Caravaggi                                                                                                                                              |
| 457 |    365.004488 |    583.484008 | Ferran Sayol                                                                                                                                                   |
| 458 |    732.040101 |    130.774767 | Michael Day                                                                                                                                                    |
| 459 |    835.222417 |    284.949344 | NA                                                                                                                                                             |
| 460 |      7.836999 |    211.408349 | Adrian Reich                                                                                                                                                   |
| 461 |    800.360254 |    738.125662 | Maija Karala                                                                                                                                                   |
| 462 |   1001.166538 |    308.467322 | Beth Reinke                                                                                                                                                    |
| 463 |   1016.363314 |    473.210377 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 464 |    252.733278 |    581.365254 | Collin Gross                                                                                                                                                   |
| 465 |    413.420269 |    218.042745 | L. Shyamal                                                                                                                                                     |
| 466 |    127.721170 |     35.433590 | Zimices                                                                                                                                                        |
| 467 |     91.806007 |     13.382310 | xgirouxb                                                                                                                                                       |
| 468 |    435.775201 |    398.502117 | Tasman Dixon                                                                                                                                                   |
| 469 |    223.329480 |    208.069684 | Steven Traver                                                                                                                                                  |
| 470 |    721.932331 |     82.231436 | Chris huh                                                                                                                                                      |
| 471 |    753.447156 |    492.131496 | T. Michael Keesey                                                                                                                                              |
| 472 |    675.466127 |    427.558280 | NA                                                                                                                                                             |
| 473 |     70.102791 |    381.618344 | Margot Michaud                                                                                                                                                 |
| 474 |    131.233453 |    355.498921 | Ferran Sayol                                                                                                                                                   |
| 475 |   1006.883460 |    356.845820 | Michael Scroggie                                                                                                                                               |
| 476 |    579.676035 |     33.999363 | Matt Crook                                                                                                                                                     |
| 477 |     83.316383 |    169.377729 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                        |
| 478 |    884.987095 |    306.439934 | Ferran Sayol                                                                                                                                                   |
| 479 |    249.219837 |    785.805282 | NA                                                                                                                                                             |
| 480 |    209.317828 |    617.143444 | Mathieu Basille                                                                                                                                                |
| 481 |    612.091744 |    120.920432 | FunkMonk                                                                                                                                                       |
| 482 |    651.321731 |    683.834233 | Lukasiniho                                                                                                                                                     |
| 483 |    858.582703 |    212.852837 | Ludwik Gąsiorowski                                                                                                                                             |
| 484 |     57.557118 |    320.704079 | Ignacio Contreras                                                                                                                                              |
| 485 |    518.986572 |    547.985688 | Zimices                                                                                                                                                        |
| 486 |     52.780476 |    309.858650 | Matt Crook                                                                                                                                                     |
| 487 |    729.867971 |    791.779791 | Michelle Site                                                                                                                                                  |
| 488 |    567.825038 |     29.328910 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 489 |    363.539171 |    339.076473 | Ferran Sayol                                                                                                                                                   |
| 490 |    844.623765 |     23.942578 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                              |
| 491 |     63.527706 |    215.488943 | Ignacio Contreras                                                                                                                                              |
| 492 |    988.134250 |    505.926170 | Becky Barnes                                                                                                                                                   |
| 493 |     35.040914 |    579.921478 | Jiekun He                                                                                                                                                      |
| 494 |    128.027141 |     22.953300 | Margot Michaud                                                                                                                                                 |
| 495 |    181.119796 |    785.438919 | Jessica Anne Miller                                                                                                                                            |
| 496 |    200.672891 |     55.037356 | Dmitry Bogdanov                                                                                                                                                |
| 497 |    165.764894 |      9.131547 | Steven Traver                                                                                                                                                  |
| 498 |    212.083838 |     65.527785 | Markus A. Grohme                                                                                                                                               |
| 499 |    300.093754 |     16.695126 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 500 |     19.288409 |    703.474809 | V. Deepak                                                                                                                                                      |
| 501 |   1002.623168 |    368.063197 | Mathieu Pélissié                                                                                                                                               |
| 502 |    518.915985 |    788.166875 | Agnello Picorelli                                                                                                                                              |
| 503 |     86.399917 |    331.049754 | Trond R. Oskars                                                                                                                                                |
| 504 |    251.134485 |    599.373973 | Matt Crook                                                                                                                                                     |
| 505 |    779.000073 |    627.236460 | Jagged Fang Designs                                                                                                                                            |
| 506 |    125.824868 |    648.153683 | Agnello Picorelli                                                                                                                                              |
| 507 |    328.300327 |    729.864168 | Matt Crook                                                                                                                                                     |
| 508 |     94.047290 |    441.387553 | Steven Traver                                                                                                                                                  |
| 509 |    560.450594 |    143.530472 | Felix Vaux                                                                                                                                                     |
| 510 |     15.098583 |    109.302055 | T. Michael Keesey                                                                                                                                              |
| 511 |    309.104775 |    274.359655 | Steven Traver                                                                                                                                                  |
| 512 |    597.070840 |    174.970930 | Carlos Cano-Barbacil                                                                                                                                           |
| 513 |    387.487847 |    767.969108 | Kamil S. Jaron                                                                                                                                                 |
| 514 |    105.693490 |    418.176390 | Birgit Lang                                                                                                                                                    |
| 515 |    532.721271 |    788.444180 | Margot Michaud                                                                                                                                                 |
| 516 |    840.780848 |    519.096127 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                             |
| 517 |     27.264530 |     56.590666 | Ferran Sayol                                                                                                                                                   |
| 518 |    635.813013 |    216.999610 | Margot Michaud                                                                                                                                                 |
| 519 |      8.707371 |    136.249107 | Ferran Sayol                                                                                                                                                   |
| 520 |    179.672244 |     77.274509 | Zimices                                                                                                                                                        |
| 521 |    186.667639 |    363.345997 | T. Michael Keesey                                                                                                                                              |
| 522 |     47.696746 |    557.999489 | Tasman Dixon                                                                                                                                                   |
| 523 |     65.100424 |    723.309871 | ArtFavor & annaleeblysse                                                                                                                                       |
| 524 |    394.798791 |    153.187174 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                       |
| 525 |    711.795172 |    523.282256 | Chris huh                                                                                                                                                      |
| 526 |    676.506849 |    415.928239 | Mathieu Pélissié                                                                                                                                               |
| 527 |    248.479751 |    203.531401 | Margot Michaud                                                                                                                                                 |
| 528 |    267.492479 |    593.223947 | Carlos Cano-Barbacil                                                                                                                                           |
| 529 |    546.134527 |     60.512377 | Felix Vaux                                                                                                                                                     |
| 530 |    751.141723 |    647.250847 | Kimberly Haddrell                                                                                                                                              |
| 531 |    628.364364 |    559.806699 | NA                                                                                                                                                             |
| 532 |    721.323335 |    667.918386 | Gabriela Palomo-Munoz                                                                                                                                          |
| 533 |    393.075644 |    256.492082 | Felix Vaux                                                                                                                                                     |
| 534 |    551.895019 |    165.907426 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 535 |      9.741760 |    431.028777 | Stanton F. Fink, vectorized by Zimices                                                                                                                         |
| 536 |    533.006184 |    126.584086 | Dean Schnabel                                                                                                                                                  |
| 537 |    331.911898 |    305.403628 | Juan Carlos Jerí                                                                                                                                               |
| 538 |    450.552122 |    291.321843 | C. Camilo Julián-Caballero                                                                                                                                     |
| 539 |   1015.930310 |    637.472876 | NA                                                                                                                                                             |
| 540 |    669.570319 |    201.197622 | Matt Crook                                                                                                                                                     |
| 541 |    306.330567 |    437.301320 | Margot Michaud                                                                                                                                                 |
| 542 |    896.452361 |    148.111451 | Scott Hartman                                                                                                                                                  |
| 543 |    544.396379 |    686.795201 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                      |
| 544 |    226.920865 |    101.919023 | Javier Luque                                                                                                                                                   |
| 545 |    164.414810 |    428.000070 | Sebastian Stabinger                                                                                                                                            |
| 546 |    822.262941 |    634.283676 | Erika Schumacher                                                                                                                                               |
| 547 |    733.416704 |    630.356022 | SauropodomorphMonarch                                                                                                                                          |
| 548 |    105.828366 |    129.786563 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                             |
| 549 |    665.795735 |    681.948377 | Chris Jennings (Risiatto)                                                                                                                                      |
| 550 |    397.042764 |    636.264954 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 551 |     55.241664 |    186.656445 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 552 |    190.171704 |    591.650108 | Matt Crook                                                                                                                                                     |
| 553 |    173.107228 |    619.758876 | Jaime Headden                                                                                                                                                  |
| 554 |    654.465529 |    794.260851 | NA                                                                                                                                                             |
| 555 |   1010.001683 |    196.516730 | Steven Traver                                                                                                                                                  |
| 556 |     15.616728 |    315.724524 | Steven Traver                                                                                                                                                  |
| 557 |     78.308407 |    194.730736 | T. Michael Keesey                                                                                                                                              |
| 558 |    882.999141 |    512.025125 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 559 |    782.267598 |    443.647962 | Gabriela Palomo-Munoz                                                                                                                                          |
| 560 |    804.377462 |    649.976946 | Matt Martyniuk                                                                                                                                                 |
| 561 |    829.346872 |    752.767454 | Markus A. Grohme                                                                                                                                               |
| 562 |    878.089068 |    488.426058 | Scott Hartman                                                                                                                                                  |
| 563 |    781.647417 |    634.045595 | Tyler Greenfield                                                                                                                                               |
| 564 |     33.697451 |    568.504939 | Margot Michaud                                                                                                                                                 |
| 565 |    593.371756 |    787.982177 | Oscar Sanisidro                                                                                                                                                |
| 566 |    643.428933 |    165.600601 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                       |
| 567 |    956.620962 |     57.925111 | Matt Crook                                                                                                                                                     |
| 568 |    882.272569 |    366.948862 | Margot Michaud                                                                                                                                                 |
| 569 |    913.687535 |    363.706317 | Carlos Cano-Barbacil                                                                                                                                           |
| 570 |    500.683337 |    536.544431 | Gareth Monger                                                                                                                                                  |
| 571 |    870.066527 |    323.381064 | Julia B McHugh                                                                                                                                                 |
| 572 |    509.076455 |    478.161715 | Chris huh                                                                                                                                                      |
| 573 |    294.731734 |    715.857707 | Matt Crook                                                                                                                                                     |
| 574 |    156.123832 |    491.697400 | Taro Maeda                                                                                                                                                     |
| 575 |    436.470491 |    530.785066 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                             |
| 576 |    634.202899 |    492.326064 | Sarah Werning                                                                                                                                                  |
| 577 |    589.416760 |    353.094686 | M Kolmann                                                                                                                                                      |
| 578 |    861.538199 |    317.992297 | Steven Traver                                                                                                                                                  |
| 579 |    243.100256 |    171.304723 | Tracy A. Heath                                                                                                                                                 |
| 580 |    204.658008 |    313.421303 | Hugo Gruson                                                                                                                                                    |
| 581 |    646.879583 |     14.365683 | Chase Brownstein                                                                                                                                               |
| 582 |    229.124975 |    427.276091 | Margot Michaud                                                                                                                                                 |
| 583 |     78.447976 |    722.862726 | Michele M Tobias                                                                                                                                               |
| 584 |    834.256156 |    638.374921 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                        |
| 585 |    758.207207 |    424.301595 | Ferran Sayol                                                                                                                                                   |
| 586 |    474.480260 |    676.930342 | Matthew E. Clapham                                                                                                                                             |
| 587 |    796.699682 |    110.697877 | L. Shyamal                                                                                                                                                     |
| 588 |    495.966819 |     68.891057 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                    |
| 589 |      6.981898 |    379.909339 | Mattia Menchetti                                                                                                                                               |
| 590 |    524.085378 |     60.388586 | Jagged Fang Designs                                                                                                                                            |
| 591 |    238.794598 |    531.238694 | Cristina Guijarro                                                                                                                                              |
| 592 |    104.627320 |     55.431989 | Margot Michaud                                                                                                                                                 |
| 593 |    507.076376 |    671.425729 | NA                                                                                                                                                             |
| 594 |    737.952489 |     57.924993 | NA                                                                                                                                                             |
| 595 |    292.890829 |    701.002185 | Yan Wong from photo by Gyik Toma                                                                                                                               |
| 596 |    914.394796 |    268.765812 | Carlos Cano-Barbacil                                                                                                                                           |
| 597 |    264.222736 |    690.078560 | NA                                                                                                                                                             |
| 598 |    105.778511 |    363.470821 | Gabriela Palomo-Munoz                                                                                                                                          |
| 599 |    751.709076 |    517.282778 | T. Michael Keesey                                                                                                                                              |
| 600 |    744.477499 |    656.255164 | xgirouxb                                                                                                                                                       |
| 601 |    472.429671 |    641.770113 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                        |
| 602 |    289.082493 |    356.002055 | Emily Willoughby                                                                                                                                               |
| 603 |    834.701089 |    346.769058 | NA                                                                                                                                                             |
| 604 |    871.706709 |      9.159444 | Maija Karala                                                                                                                                                   |
| 605 |     73.659561 |    597.008137 | Scott Hartman                                                                                                                                                  |
| 606 |    858.040698 |    744.006118 | Margot Michaud                                                                                                                                                 |
| 607 |    630.462067 |    276.091122 | Matt Crook                                                                                                                                                     |
| 608 |    739.137539 |    409.816910 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                        |
| 609 |    503.346517 |    758.494700 | Margot Michaud                                                                                                                                                 |
| 610 |    725.734601 |    379.492088 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 611 |    434.494866 |    362.067211 | Caleb M. Brown                                                                                                                                                 |
| 612 |    466.959043 |    269.314632 | Matt Martyniuk                                                                                                                                                 |
| 613 |    526.368467 |    333.510393 | Beth Reinke                                                                                                                                                    |
| 614 |    530.219557 |    340.261398 | Erika Schumacher                                                                                                                                               |
| 615 |   1013.419260 |    490.149026 | Gordon E. Robertson                                                                                                                                            |
| 616 |    494.766978 |     94.679118 | NA                                                                                                                                                             |
| 617 |    405.144454 |    266.387558 | Matt Martyniuk                                                                                                                                                 |
| 618 |    877.556248 |    188.403026 | Roberto Díaz Sibaja                                                                                                                                            |
| 619 |    685.412284 |    567.094864 | Sarah Alewijnse                                                                                                                                                |
| 620 |    177.253929 |    385.012582 | Gareth Monger                                                                                                                                                  |
| 621 |    747.073280 |    389.142270 | Matt Crook                                                                                                                                                     |
| 622 |    488.464942 |    355.841965 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 623 |    728.610695 |    256.380468 | Kanako Bessho-Uehara                                                                                                                                           |
| 624 |    146.552597 |     38.717053 | Anna Willoughby                                                                                                                                                |
| 625 |    241.862209 |    587.312233 | Kamil S. Jaron                                                                                                                                                 |
| 626 |    362.261146 |    496.298723 | Matt Crook                                                                                                                                                     |
| 627 |    856.369874 |    489.531277 | Collin Gross                                                                                                                                                   |
| 628 |    569.892326 |    327.609745 | Maija Karala                                                                                                                                                   |
| 629 |    443.273153 |     76.233830 | Tasman Dixon                                                                                                                                                   |
| 630 |    732.047486 |    114.898894 | Matt Crook                                                                                                                                                     |
| 631 |    127.089440 |    726.279287 | Dean Schnabel                                                                                                                                                  |
| 632 |    728.855007 |    562.507893 | Matt Dempsey                                                                                                                                                   |
| 633 |    499.303550 |    255.273341 | Margot Michaud                                                                                                                                                 |
| 634 |    745.926215 |    787.533120 | T. Michael Keesey and Tanetahi                                                                                                                                 |
| 635 |     60.472940 |     13.531142 | T. Michael Keesey                                                                                                                                              |
| 636 |    575.023410 |    640.092827 | Gareth Monger                                                                                                                                                  |
| 637 |    786.434145 |    359.878187 | NA                                                                                                                                                             |
| 638 |    872.799797 |    168.534440 | Scott Hartman                                                                                                                                                  |
| 639 |   1008.889978 |    726.602869 | C. Camilo Julián-Caballero                                                                                                                                     |
| 640 |    518.460769 |    571.352912 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                  |
| 641 |    282.007017 |    468.313073 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 642 |     13.740560 |    366.032476 | Matt Crook                                                                                                                                                     |
| 643 |    288.190082 |     10.480346 | Mathieu Pélissié                                                                                                                                               |
| 644 |    209.287249 |    790.747728 | Steven Traver                                                                                                                                                  |
| 645 |    702.384254 |    568.617916 | NA                                                                                                                                                             |
| 646 |      9.316036 |    452.648023 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 647 |    911.464765 |    450.695420 | Tasman Dixon                                                                                                                                                   |
| 648 |    774.711081 |    723.977865 | NA                                                                                                                                                             |
| 649 |    850.850849 |    473.779726 | T. Michael Keesey                                                                                                                                              |
| 650 |    318.974931 |    644.227126 | Falconaumanni and T. Michael Keesey                                                                                                                            |
| 651 |    755.174010 |    202.303865 | Markus A. Grohme                                                                                                                                               |
| 652 |    279.569791 |    586.890161 | CNZdenek                                                                                                                                                       |
| 653 |    270.011566 |    430.459894 | Chris huh                                                                                                                                                      |
| 654 |    865.970098 |    428.673910 | Ferran Sayol                                                                                                                                                   |
| 655 |    395.609028 |    204.939347 | Matt Crook                                                                                                                                                     |
| 656 |    632.722751 |    576.212058 | Steven Traver                                                                                                                                                  |
| 657 |    433.999219 |    432.023498 | Michelle Site                                                                                                                                                  |
| 658 |    304.003599 |    393.332106 | Michele M Tobias                                                                                                                                               |
| 659 |    709.952576 |     32.893698 | Jagged Fang Designs                                                                                                                                            |
| 660 |    660.010673 |     10.805985 | Markus A. Grohme                                                                                                                                               |
| 661 |    743.244548 |     78.604408 | Jagged Fang Designs                                                                                                                                            |
| 662 |     67.397579 |    763.894886 | Chris huh                                                                                                                                                      |
| 663 |    305.613806 |    498.645092 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 664 |    589.877799 |    306.152680 | L. Shyamal                                                                                                                                                     |
| 665 |    411.312103 |     87.117927 | Ferran Sayol                                                                                                                                                   |
| 666 |    346.983648 |     78.063669 | NA                                                                                                                                                             |
| 667 |    467.879842 |    354.252238 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 668 |    765.676281 |    515.606306 | Ferran Sayol                                                                                                                                                   |
| 669 |    437.441830 |    173.233630 | Gareth Monger                                                                                                                                                  |
| 670 |    925.951083 |    678.222058 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                          |
| 671 |    593.721580 |    702.100084 | Zimices                                                                                                                                                        |
| 672 |    906.281307 |    141.930915 | Margot Michaud                                                                                                                                                 |
| 673 |    633.745650 |    124.843090 | Michael Scroggie                                                                                                                                               |
| 674 |    744.184164 |    144.093483 | Maija Karala                                                                                                                                                   |
| 675 |    120.865662 |    521.184415 | C. Camilo Julián-Caballero                                                                                                                                     |
| 676 |    551.263168 |    729.020040 | Anthony Caravaggi                                                                                                                                              |
| 677 |    861.384680 |     26.123308 | Steven Traver                                                                                                                                                  |
| 678 |    306.416195 |      7.358476 | Jagged Fang Designs                                                                                                                                            |
| 679 |    564.829814 |    629.521437 | Shyamal                                                                                                                                                        |
| 680 |    513.070871 |    560.847186 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                    |
| 681 |    370.556935 |     60.723724 | Taenadoman                                                                                                                                                     |
| 682 |    736.708660 |    766.103614 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                             |
| 683 |    111.586964 |    659.574645 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 684 |    703.104689 |    327.618054 | Michelle Site                                                                                                                                                  |
| 685 |    355.152811 |     99.382419 | Zimices                                                                                                                                                        |
| 686 |    552.929237 |    117.474321 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 687 |    435.990127 |    194.991257 | Tracy A. Heath                                                                                                                                                 |
| 688 |    289.630634 |    400.903410 | Tracy A. Heath                                                                                                                                                 |
| 689 |    708.914202 |    718.006612 | Felix Vaux                                                                                                                                                     |
| 690 |     26.309805 |     43.022133 | Matt Crook                                                                                                                                                     |
| 691 |    994.316069 |    549.563746 | Melissa Broussard                                                                                                                                              |
| 692 |    300.320030 |    737.295080 | NA                                                                                                                                                             |
| 693 |     24.581768 |     29.834467 | Caleb M. Brown                                                                                                                                                 |
| 694 |     85.906193 |    786.612036 | Maija Karala                                                                                                                                                   |
| 695 |   1008.943698 |    412.125163 | Margot Michaud                                                                                                                                                 |
| 696 |    508.009748 |     77.352014 | Skye McDavid                                                                                                                                                   |
| 697 |    899.772853 |    593.444231 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 698 |    427.046438 |    790.671514 | Margot Michaud                                                                                                                                                 |
| 699 |    123.691868 |    702.503523 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 700 |    544.475469 |     30.226339 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 701 |    270.757023 |    167.012597 | Scott Hartman                                                                                                                                                  |
| 702 |     94.716943 |    694.397283 | Dean Schnabel                                                                                                                                                  |
| 703 |    649.261978 |    126.140288 | Joanna Wolfe                                                                                                                                                   |
| 704 |    821.605905 |    457.376720 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 705 |    985.529260 |    492.621402 | Jaime Headden                                                                                                                                                  |
| 706 |    980.929029 |    592.319466 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                          |
| 707 |    486.250416 |    298.531680 | NA                                                                                                                                                             |
| 708 |    492.668599 |    508.621516 | Matt Crook                                                                                                                                                     |
| 709 |    550.114151 |    612.700721 | Oliver Voigt                                                                                                                                                   |
| 710 |     24.826383 |     77.145220 | Bennet McComish, photo by Avenue                                                                                                                               |
| 711 |    176.583095 |    283.212190 | Ferran Sayol                                                                                                                                                   |
| 712 |    292.898767 |    428.386756 | Steven Traver                                                                                                                                                  |
| 713 |    189.086819 |    628.573071 | xgirouxb                                                                                                                                                       |
| 714 |    892.601798 |    345.102467 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 715 |     57.045435 |    532.186057 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                    |
| 716 |     29.932788 |    725.487789 | Joanna Wolfe                                                                                                                                                   |
| 717 |    203.175879 |    407.146238 | Kanchi Nanjo                                                                                                                                                   |
| 718 |    765.691549 |    752.956495 | Markus A. Grohme                                                                                                                                               |
| 719 |   1014.370452 |    293.648333 | Erika Schumacher                                                                                                                                               |
| 720 |     23.016839 |    602.711109 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                  |
| 721 |    317.205683 |    304.942233 | Jagged Fang Designs                                                                                                                                            |
| 722 |    329.917449 |    625.529966 | Matt Crook                                                                                                                                                     |
| 723 |    405.204898 |    360.725880 | T. Michael Keesey                                                                                                                                              |
| 724 |    120.442136 |    508.711937 | Gareth Monger                                                                                                                                                  |
| 725 |    420.000215 |    391.580137 | NA                                                                                                                                                             |
| 726 |    955.237514 |    597.064963 | Tracy A. Heath                                                                                                                                                 |
| 727 |    104.127337 |    429.206518 | Gabriela Palomo-Munoz                                                                                                                                          |
| 728 |    608.689692 |    272.181735 | Matt Hayes                                                                                                                                                     |
| 729 |    159.318840 |    443.881990 | Matt Crook                                                                                                                                                     |
| 730 |    385.648476 |    120.880188 | Zimices                                                                                                                                                        |
| 731 |    632.957382 |    227.403338 | Mathew Wedel                                                                                                                                                   |
| 732 |    811.040422 |    564.067478 | Emily Willoughby                                                                                                                                               |
| 733 |    897.969257 |    503.826337 | Arthur S. Brum                                                                                                                                                 |
| 734 |    461.481140 |    157.191225 | Zimices                                                                                                                                                        |
| 735 |    782.118694 |     11.798561 | CNZdenek                                                                                                                                                       |
| 736 |    369.049582 |    111.153610 | Matt Crook                                                                                                                                                     |
| 737 |    611.074770 |     93.505453 | Kamil S. Jaron                                                                                                                                                 |
| 738 |    261.241178 |    193.335151 | NA                                                                                                                                                             |
| 739 |    949.216558 |    628.036191 | François Michonneau                                                                                                                                            |
| 740 |    731.533356 |    205.764733 | Gabriela Palomo-Munoz                                                                                                                                          |
| 741 |    523.034224 |    535.343762 | Steven Traver                                                                                                                                                  |
| 742 |    354.568583 |    714.924654 | Javier Luque                                                                                                                                                   |
| 743 |    958.732785 |    615.812616 | Chris Hay                                                                                                                                                      |
| 744 |    199.317018 |    144.913617 | CNZdenek                                                                                                                                                       |
| 745 |    456.412024 |    501.278189 | Alexandre Vong                                                                                                                                                 |
| 746 |    238.833337 |    720.996536 | Armin Reindl                                                                                                                                                   |
| 747 |    271.769551 |    667.654216 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                    |
| 748 |    378.091319 |     96.256078 | Tasman Dixon                                                                                                                                                   |
| 749 |     67.319902 |    308.331294 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                |
| 750 |    643.727414 |    549.270105 | Dean Schnabel                                                                                                                                                  |
| 751 |     10.951016 |     60.513331 | S.Martini                                                                                                                                                      |
| 752 |    311.743023 |    679.601297 | Andy Wilson                                                                                                                                                    |
| 753 |    871.527757 |    439.373092 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 754 |    992.834409 |    417.768396 | Scott Hartman                                                                                                                                                  |
| 755 |    989.294362 |     49.789505 | Mike Hanson                                                                                                                                                    |
| 756 |    329.394265 |    745.459461 | Matt Crook                                                                                                                                                     |
| 757 |    685.050013 |    310.158516 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                 |
| 758 |    334.855657 |     54.580046 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 759 |     81.204488 |      8.898146 | Mathieu Pélissié                                                                                                                                               |
| 760 |    993.677178 |    179.760445 | Zimices                                                                                                                                                        |
| 761 |    993.342769 |    609.486064 | Andrew A. Farke                                                                                                                                                |
| 762 |    282.613405 |    785.022762 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 763 |     36.190525 |    605.821986 | Birgit Lang                                                                                                                                                    |
| 764 |    994.919552 |    361.169497 | Joanna Wolfe                                                                                                                                                   |
| 765 |    727.935597 |    217.795815 | Zimices                                                                                                                                                        |
| 766 |    961.742545 |    516.491013 | Rebecca Groom                                                                                                                                                  |
| 767 |    880.452814 |    236.814111 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                          |
| 768 |    515.326440 |    323.016375 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 769 |    844.590771 |      4.218243 | CNZdenek                                                                                                                                                       |
| 770 |    719.613159 |    695.441599 | Oren Peles / vectorized by Yan Wong                                                                                                                            |
| 771 |     97.559575 |    213.707589 | Chris huh                                                                                                                                                      |
| 772 |    984.139289 |    697.223978 | Anthony Caravaggi                                                                                                                                              |
| 773 |    438.904685 |    790.316190 | T. Michael Keesey                                                                                                                                              |
| 774 |    454.849098 |    287.196364 | Tasman Dixon                                                                                                                                                   |
| 775 |    397.435562 |    719.100018 | Renata F. Martins                                                                                                                                              |
| 776 |    648.701497 |    281.367107 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 777 |    713.227069 |    391.601072 | T. Michael Keesey                                                                                                                                              |
| 778 |     73.272887 |    792.182906 | T. Michael Keesey and Tanetahi                                                                                                                                 |
| 779 |    494.462522 |    140.258011 | Steven Traver                                                                                                                                                  |
| 780 |    111.287848 |    633.952455 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 781 |    668.272226 |    396.194038 | Markus A. Grohme                                                                                                                                               |
| 782 |    469.745661 |    292.471471 | Matt Crook                                                                                                                                                     |
| 783 |    615.383683 |     80.153728 | Margot Michaud                                                                                                                                                 |
| 784 |    268.593941 |    630.913811 | Matt Crook                                                                                                                                                     |
| 785 |    546.390027 |    217.764430 | Oscar Sanisidro                                                                                                                                                |
| 786 |     26.087241 |     16.184799 | Tasman Dixon                                                                                                                                                   |
| 787 |    667.116159 |     77.768580 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                              |
| 788 |    848.821948 |    733.865826 | Matt Crook                                                                                                                                                     |
| 789 |    341.867217 |    498.291193 | Michelle Site                                                                                                                                                  |
| 790 |    376.242714 |    660.081397 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 791 |    227.118706 |    468.443585 | Kanchi Nanjo                                                                                                                                                   |
| 792 |    195.840433 |    782.377529 | Paul O. Lewis                                                                                                                                                  |
| 793 |    662.438626 |    418.311236 | Chris huh                                                                                                                                                      |
| 794 |    414.091453 |    144.600721 | Ferran Sayol                                                                                                                                                   |
| 795 |    143.706642 |    285.014338 | Zimices                                                                                                                                                        |
| 796 |   1008.271908 |    678.251725 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 797 |    675.569550 |    790.931794 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 798 |    212.724126 |    346.638997 | Gareth Monger                                                                                                                                                  |
| 799 |   1008.161518 |    209.877868 | Steven Traver                                                                                                                                                  |
| 800 |    662.494607 |    405.303004 | Scott Hartman                                                                                                                                                  |
| 801 |    573.395936 |    104.793072 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                        |
| 802 |    236.784223 |    415.082662 | John Conway                                                                                                                                                    |
| 803 |    936.320300 |    496.254972 | T. Michael Keesey                                                                                                                                              |
| 804 |    853.257187 |    327.464395 | James Neenan                                                                                                                                                   |
| 805 |    509.803462 |    332.598534 | L. Shyamal                                                                                                                                                     |
| 806 |    682.559278 |    602.411802 | C. Camilo Julián-Caballero                                                                                                                                     |
| 807 |    999.330336 |    293.362594 | V. Deepak                                                                                                                                                      |
| 808 |    753.983295 |    689.332487 | Caio Bernardes, vectorized by Zimices                                                                                                                          |
| 809 |    294.832037 |    171.831629 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                             |
| 810 |    518.635052 |     34.982971 | xgirouxb                                                                                                                                                       |
| 811 |    888.761351 |     94.154752 | Andrés Sánchez                                                                                                                                                 |
| 812 |    634.182809 |    788.648677 | Maija Karala                                                                                                                                                   |
| 813 |    815.194994 |    515.162516 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 814 |    672.216050 |    705.932251 | Zimices                                                                                                                                                        |
| 815 |    970.456801 |    574.985478 | Tasman Dixon                                                                                                                                                   |
| 816 |    958.309444 |    558.278019 | Nina Skinner                                                                                                                                                   |
| 817 |    756.461019 |    771.954529 | Louis Ranjard                                                                                                                                                  |
| 818 |     65.945799 |    556.342389 | Mathilde Cordellier                                                                                                                                            |
| 819 |    525.450208 |    645.124544 | Jagged Fang Designs                                                                                                                                            |
| 820 |    904.948229 |    156.491941 | Jake Warner                                                                                                                                                    |
| 821 |      5.799149 |    623.771322 | Michelle Site                                                                                                                                                  |
| 822 |    807.236249 |    444.969866 | Chris huh                                                                                                                                                      |
| 823 |    807.823246 |    285.212314 | Zimices                                                                                                                                                        |
| 824 |    356.445071 |      8.481452 | Gareth Monger                                                                                                                                                  |
| 825 |    378.486490 |    130.727010 | Tommaso Cancellario                                                                                                                                            |
| 826 |     32.358938 |    378.011368 | SauropodomorphMonarch                                                                                                                                          |
| 827 |    647.051130 |    201.520349 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 828 |    594.504870 |     17.218456 | Martin R. Smith                                                                                                                                                |
| 829 |    867.086369 |    469.466511 | Margot Michaud                                                                                                                                                 |
| 830 |    471.466889 |      8.072907 | NA                                                                                                                                                             |
| 831 |   1019.862617 |    231.584176 | T. Michael Keesey                                                                                                                                              |
| 832 |    486.739770 |     21.480092 | Steven Traver                                                                                                                                                  |
| 833 |    217.244785 |    443.203125 | Zimices                                                                                                                                                        |
| 834 |    848.583057 |    691.428639 | Matt Crook                                                                                                                                                     |
| 835 |    874.912304 |     54.012484 | Michael Scroggie                                                                                                                                               |
| 836 |    923.831833 |    205.332661 | FunkMonk                                                                                                                                                       |
| 837 |    307.275428 |    779.126190 | Emily Willoughby                                                                                                                                               |
| 838 |   1001.858251 |    376.254624 | Kai R. Caspar                                                                                                                                                  |
| 839 |    367.675962 |    627.353528 | Tasman Dixon                                                                                                                                                   |
| 840 |    921.664414 |    197.668071 | Ferran Sayol                                                                                                                                                   |
| 841 |    879.757067 |    296.787094 | Beth Reinke                                                                                                                                                    |
| 842 |    783.164553 |    767.794541 | Michael P. Taylor                                                                                                                                              |
| 843 |    855.657712 |    497.920957 | Margot Michaud                                                                                                                                                 |
| 844 |    812.157924 |    553.491225 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                           |
| 845 |    183.893786 |    467.358775 | Mathilde Cordellier                                                                                                                                            |
| 846 |    894.328559 |    123.582284 | Jagged Fang Designs                                                                                                                                            |
| 847 |    248.666473 |    744.012134 | Ingo Braasch                                                                                                                                                   |
| 848 |    873.401403 |     15.002745 | Markus A. Grohme                                                                                                                                               |
| 849 |    574.775835 |    174.554739 | Gabriela Palomo-Munoz                                                                                                                                          |
| 850 |     42.890326 |    547.229657 | Melissa Broussard                                                                                                                                              |
| 851 |    238.775887 |    351.520979 | Markus A. Grohme                                                                                                                                               |
| 852 |    804.013551 |    438.042680 | Ignacio Contreras                                                                                                                                              |
| 853 |    883.484864 |    405.133632 | FunkMonk                                                                                                                                                       |
| 854 |     12.321481 |     35.262836 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 855 |    913.478134 |    480.661145 | Matt Crook                                                                                                                                                     |
| 856 |    336.827913 |     22.034322 | Dean Schnabel                                                                                                                                                  |
| 857 |    705.689252 |     87.372384 | Gareth Monger                                                                                                                                                  |
| 858 |    445.145705 |    743.316960 | Ben Moon                                                                                                                                                       |
| 859 |   1006.533123 |    736.005856 | Ferran Sayol                                                                                                                                                   |
| 860 |   1009.437554 |     87.985413 | Steven Traver                                                                                                                                                  |
| 861 |    772.631021 |     47.143407 | Chris huh                                                                                                                                                      |
| 862 |    237.611701 |     82.381740 | Oscar Sanisidro                                                                                                                                                |
| 863 |    714.509519 |    277.844464 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                          |
| 864 |    905.869534 |    203.001531 | Caleb M. Brown                                                                                                                                                 |
| 865 |    798.822796 |     39.980666 | Gareth Monger                                                                                                                                                  |
| 866 |    433.953126 |    183.178731 | Tasman Dixon                                                                                                                                                   |
| 867 |    682.027088 |    487.573101 | Margot Michaud                                                                                                                                                 |
| 868 |    498.150300 |    309.174294 | NA                                                                                                                                                             |
| 869 |    920.090523 |    430.302413 | Gareth Monger                                                                                                                                                  |
| 870 |    519.715447 |      8.544746 | Noah Schlottman, photo from Moorea Biocode                                                                                                                     |
| 871 |    301.336619 |    197.930695 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                       |
| 872 |    801.627335 |    129.680916 | Mareike C. Janiak                                                                                                                                              |
| 873 |    954.002135 |    605.874591 | Steven Traver                                                                                                                                                  |
| 874 |     37.900919 |    239.661495 | Gareth Monger                                                                                                                                                  |
| 875 |    304.040377 |    182.904808 | Zimices                                                                                                                                                        |
| 876 |    344.963902 |    694.834568 | Zimices                                                                                                                                                        |
| 877 |    306.541564 |    297.196748 | Zimices                                                                                                                                                        |
| 878 |    713.894193 |    333.214915 | Lukasiniho                                                                                                                                                     |
| 879 |     46.195298 |    274.347409 | CNZdenek                                                                                                                                                       |
| 880 |    713.055844 |    230.462994 | CNZdenek                                                                                                                                                       |
| 881 |    590.310700 |    624.560907 | Gabriela Palomo-Munoz                                                                                                                                          |
| 882 |    135.498992 |    178.193806 | Zimices                                                                                                                                                        |
| 883 |    850.638881 |    434.307499 | T. Michael Keesey                                                                                                                                              |
| 884 |     36.964007 |    216.052759 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                             |
| 885 |    958.466940 |     71.371555 | Jagged Fang Designs                                                                                                                                            |
| 886 |    458.724743 |    791.411973 | Ferran Sayol                                                                                                                                                   |
| 887 |    494.546166 |    330.017642 | Ferran Sayol                                                                                                                                                   |
| 888 |    106.475951 |    205.881903 | Zimices                                                                                                                                                        |
| 889 |    156.196144 |    276.504252 | Manabu Sakamoto                                                                                                                                                |
| 890 |    690.440121 |     82.374121 | Gareth Monger                                                                                                                                                  |
| 891 |     12.404129 |    271.435397 | Gareth Monger                                                                                                                                                  |
| 892 |    315.870069 |    415.751638 | CNZdenek                                                                                                                                                       |
| 893 |    972.929658 |    487.284575 | Zimices                                                                                                                                                        |
| 894 |    857.794893 |     51.894088 | Tasman Dixon                                                                                                                                                   |
| 895 |    756.039997 |    178.815715 | Kai R. Caspar                                                                                                                                                  |
| 896 |    729.267212 |    361.309829 | Kamil S. Jaron                                                                                                                                                 |
| 897 |    900.883467 |    353.678875 | Matt Crook                                                                                                                                                     |
| 898 |    730.269296 |    503.192201 | Markus A. Grohme                                                                                                                                               |
| 899 |    283.594318 |    760.488115 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                              |
| 900 |    493.621512 |     53.936081 | Jagged Fang Designs                                                                                                                                            |
| 901 |    169.248313 |    245.039324 | Michelle Site                                                                                                                                                  |
| 902 |    339.928942 |    687.319235 | Gabriela Palomo-Munoz                                                                                                                                          |
| 903 |    106.739317 |    647.685689 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 904 |    507.811068 |    353.867380 | Matt Crook                                                                                                                                                     |
| 905 |    669.966265 |     21.710390 | Katie S. Collins                                                                                                                                               |
| 906 |    171.045934 |    299.011780 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                      |
| 907 |    919.909123 |      7.398062 | Scott Hartman                                                                                                                                                  |
| 908 |    233.576780 |    163.878992 | Gareth Monger                                                                                                                                                  |
| 909 |    896.622326 |    102.732310 | Michelle Site                                                                                                                                                  |
| 910 |    601.705078 |    679.290163 | NA                                                                                                                                                             |
| 911 |    917.921162 |    523.933690 | Steven Traver                                                                                                                                                  |
| 912 |    699.476568 |    733.205324 | Margot Michaud                                                                                                                                                 |
| 913 |     47.257018 |    379.124068 | mystica                                                                                                                                                        |
| 914 |    722.638614 |    717.083778 | Matt Crook                                                                                                                                                     |
| 915 |    759.730309 |     12.492701 | Chris huh                                                                                                                                                      |
| 916 |    138.081968 |    364.987712 | Michelle Site                                                                                                                                                  |
| 917 |    573.782582 |    710.670243 | mystica                                                                                                                                                        |
| 918 |    325.951934 |    319.268470 | NA                                                                                                                                                             |
| 919 |    985.410774 |    573.256562 | Lukasiniho                                                                                                                                                     |
| 920 |    220.897494 |    400.137922 | Margot Michaud                                                                                                                                                 |
| 921 |    994.796862 |    110.381725 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 922 |    343.086137 |    224.289013 | NA                                                                                                                                                             |
| 923 |    571.408527 |      7.590804 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 924 |    658.613430 |    382.841116 | Zimices                                                                                                                                                        |
| 925 |    852.756017 |    387.500497 | Tasman Dixon                                                                                                                                                   |

    #> Your tweet has been posted!
