
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

Steven Traver, T. Michael Keesey, Nobu Tamura (vectorized by T. Michael
Keesey), Tony Ayling (vectorized by T. Michael Keesey), Dean Schnabel,
Chris huh, Sarah Werning, Melissa Broussard, Tasman Dixon, Matt
Martyniuk (vectorized by T. Michael Keesey), Smokeybjb, Apokryltaros
(vectorized by T. Michael Keesey), Adam Stuart Smith (vectorized by T.
Michael Keesey), Roberto Díaz Sibaja, Markus A. Grohme, Margot Michaud,
Ignacio Contreras, Taenadoman, Jaime Headden, Matt Crook, Nicolas Huet
le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey),
Birgit Lang, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Ferran Sayol, Scott Hartman, Michael
Scroggie, Beth Reinke, Gareth Monger, Matt Celeskey, Obsidian Soul
(vectorized by T. Michael Keesey), Andrew A. Farke, modified from
original by Robert Bruce Horsfall, from Scott 1912, Oscar Sanisidro,
Dmitry Bogdanov, Gabriela Palomo-Munoz, Oliver Voigt, Armelle Ansart
(photograph), Maxime Dahirel (digitisation), Zimices, Felix Vaux, Remes
K, Ortega F, Fierro I, Joger U, Kosma R, et al., Martien Brand (original
photo), Renato Santos (vector silhouette), NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), DW Bapst (modified from Bates et al., 2005), Raven Amos,
Yan Wong, xgirouxb, Martin R. Smith, from photo by Jürgen Schoner,
Harold N Eyster, Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Lip Kee Yap (vectorized by T.
Michael Keesey), Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric
M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, C.
Abraczinskas, Jagged Fang Designs, Andy Wilson, NASA, T. Michael Keesey
(after Monika Betley), Francesco “Architetto” Rollandin, DFoidl
(vectorized by T. Michael Keesey), Noah Schlottman, photo by Reinhard
Jahn, Karla Martinez, Alan Manson (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Shyamal, CNZdenek, Kai R. Caspar,
Mali’o Kodis, photograph from Jersabek et al, 2003, Emily Willoughby,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Cagri Cevrim, Espen
Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell),
Becky Barnes, L. Shyamal, Chloé Schmidt, Walter Vladimir, James I.
Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and
Jelle P. Wiersma (vectorized by T. Michael Keesey), Maija Karala, John
Gould (vectorized by T. Michael Keesey), T. Michael Keesey (after
Heinrich Harder), M. Garfield & K. Anderson (modified by T. Michael
Keesey), Natalie Claunch, Cesar Julian, Dave Souza (vectorized by T.
Michael Keesey), Joe Schneid (vectorized by T. Michael Keesey), Darren
Naish (vectorized by T. Michael Keesey), Andrew A. Farke, Donovan
Reginald Rosevear (vectorized by T. Michael Keesey), Noah Schlottman,
photo by Casey Dunn, Noah Schlottman, photo by David J Patterson, Tod
Robbins, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Charles R. Knight,
vectorized by Zimices, Myriam\_Ramirez, David Orr, Robert Hering, Noah
Schlottman, photo by Hans De Blauwe, Julien Louys, Anthony Caravaggi, Mr
E? (vectorized by T. Michael Keesey), FunkMonk, Abraão Leite, Brian
Gratwicke (photo) and T. Michael Keesey (vectorization), Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Iain Reid,
Alexander Schmidt-Lebuhn, Meliponicultor Itaymbere, Xavier
Giroux-Bougard, Rebecca Groom, Michael B. H. (vectorized by T. Michael
Keesey), Brad McFeeters (vectorized by T. Michael Keesey), François
Michonneau, Patrick Fisher (vectorized by T. Michael Keesey), Erika
Schumacher, Josep Marti Solans, Steven Coombs, Bennet McComish, photo by
Hans Hillewaert, Collin Gross, Felix Vaux and Steven A. Trewick,
Christoph Schomburg, Tracy A. Heath, Michelle Site, Archaeodontosaurus
(vectorized by T. Michael Keesey), Crystal Maier, Conty (vectorized by
T. Michael Keesey), Joanna Wolfe, Scott Reid, Nobu Tamura, Milton Tan,
Ingo Braasch, Ekaterina Kopeykina (vectorized by T. Michael Keesey),
Kamil S. Jaron, T. Michael Keesey (vectorization); Yves Bousquet
(photography), Robbie N. Cada (modified by T. Michael Keesey), Matt
Martyniuk, Caleb M. Brown, Mattia Menchetti / Yan Wong, Elizabeth
Parker, Thea Boodhoo (photograph) and T. Michael Keesey (vectorization),
Cathy, FJDegrange, Tomas Willems (vectorized by T. Michael Keesey),
Charles R. Knight (vectorized by T. Michael Keesey), Lukasiniho,
Madeleine Price Ball, T. Michael Keesey (photo by J. M. Garg), C. Camilo
Julián-Caballero, Julio Garza, Michael P. Taylor, Chris A. Hamilton, V.
Deepak, T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler,
Ted M. Townsend & Miguel Vences), John Conway, Konsta Happonen, from a
CC-BY-NC image by pelhonen on iNaturalist, Thibaut Brunet, Caroline
Harding, MAF (vectorized by T. Michael Keesey), Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Noah Schlottman,
photo by Carol Cummings, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), T. Michael Keesey
(from a photo by Maximilian Paradiz), Armin Reindl, Pete Buchholz,
Robbie N. Cada (vectorized by T. Michael Keesey), Smokeybjb (modified by
T. Michael Keesey), Joris van der Ham (vectorized by T. Michael Keesey),
Campbell Fleming, E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka
(vectorized by T. Michael Keesey), Carlos Cano-Barbacil, Kailah Thorn &
Mark Hutchinson, Michael Ströck (vectorized by T. Michael Keesey), Jaime
Headden, modified by T. Michael Keesey, Sharon Wegner-Larsen, Todd
Marshall, vectorized by Zimices, Juan Carlos Jerí, Smokeybjb (vectorized
by T. Michael Keesey), Tyler McCraney, Vanessa Guerra, Christine Axon,
Jiekun He, Alex Slavenko, Darius Nau, Ralf Janssen, Nikola-Michael Prpic
& Wim G. M. Damen (vectorized by T. Michael Keesey), Kanchi Nanjo,
Robert Gay, Tauana J. Cunha, Mykle Hoban, Ghedoghedo, Terpsichores, Nobu
Tamura, modified by Andrew A. Farke, M Kolmann

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     408.39822 |    718.002315 | Steven Traver                                                                                                                                                         |
|   2 |     818.20926 |    105.701917 | T. Michael Keesey                                                                                                                                                     |
|   3 |     537.63954 |     37.674838 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|   4 |     143.60975 |    389.799552 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|   5 |     279.33542 |    543.233243 | Dean Schnabel                                                                                                                                                         |
|   6 |     434.70921 |    433.028215 | Chris huh                                                                                                                                                             |
|   7 |     207.14748 |    180.042228 | Sarah Werning                                                                                                                                                         |
|   8 |     959.45128 |     68.521412 | Melissa Broussard                                                                                                                                                     |
|   9 |     194.50409 |    522.543712 | Tasman Dixon                                                                                                                                                          |
|  10 |     219.60792 |    673.043879 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
|  11 |     160.50958 |    237.721506 | Smokeybjb                                                                                                                                                             |
|  12 |     126.43238 |    111.618007 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
|  13 |     745.34818 |    527.454603 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
|  14 |     722.16372 |    371.519001 | Dean Schnabel                                                                                                                                                         |
|  15 |     331.67122 |     31.651980 | Roberto Díaz Sibaja                                                                                                                                                   |
|  16 |     590.01565 |    697.512497 | Markus A. Grohme                                                                                                                                                      |
|  17 |     831.24739 |    218.440224 | Margot Michaud                                                                                                                                                        |
|  18 |     327.32068 |    259.066595 | Ignacio Contreras                                                                                                                                                     |
|  19 |     451.74538 |    533.194649 | Steven Traver                                                                                                                                                         |
|  20 |     469.27831 |    140.497654 | Margot Michaud                                                                                                                                                        |
|  21 |     588.50047 |    126.635903 | Taenadoman                                                                                                                                                            |
|  22 |     516.62542 |    214.110802 | Jaime Headden                                                                                                                                                         |
|  23 |     650.19361 |     55.000359 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  24 |     313.22204 |    401.202224 | Matt Crook                                                                                                                                                            |
|  25 |     933.13324 |    652.747921 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
|  26 |     964.06283 |    526.089014 | Birgit Lang                                                                                                                                                           |
|  27 |     189.67207 |    313.177797 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
|  28 |     807.71278 |    599.077178 | Ferran Sayol                                                                                                                                                          |
|  29 |     725.94889 |    164.107798 | Scott Hartman                                                                                                                                                         |
|  30 |     638.80056 |    572.140028 | Michael Scroggie                                                                                                                                                      |
|  31 |     184.86059 |     45.701152 | Margot Michaud                                                                                                                                                        |
|  32 |     342.01544 |    601.759161 | Scott Hartman                                                                                                                                                         |
|  33 |     320.02350 |    159.928929 | Beth Reinke                                                                                                                                                           |
|  34 |     876.00941 |    729.253751 | Gareth Monger                                                                                                                                                         |
|  35 |     123.53291 |    439.410380 | Scott Hartman                                                                                                                                                         |
|  36 |     137.29471 |    680.866971 | Birgit Lang                                                                                                                                                           |
|  37 |     871.62601 |    305.184108 | Gareth Monger                                                                                                                                                         |
|  38 |     471.43891 |    310.872558 | Matt Celeskey                                                                                                                                                         |
|  39 |     454.20762 |    604.327900 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  40 |     699.20468 |    225.408576 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
|  41 |      76.61232 |    270.555111 | Oscar Sanisidro                                                                                                                                                       |
|  42 |     244.80261 |     79.846228 | Dmitry Bogdanov                                                                                                                                                       |
|  43 |     294.88733 |    228.669388 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  44 |     635.48946 |    307.865020 | Oliver Voigt                                                                                                                                                          |
|  45 |     976.63616 |    207.648486 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                            |
|  46 |     207.74542 |    769.046866 | Smokeybjb                                                                                                                                                             |
|  47 |      94.28987 |    611.848110 | Zimices                                                                                                                                                               |
|  48 |      59.95556 |    501.648183 | Margot Michaud                                                                                                                                                        |
|  49 |     413.55822 |    127.122430 | Felix Vaux                                                                                                                                                            |
|  50 |      72.29963 |     78.341491 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
|  51 |      67.97050 |     16.242528 | Scott Hartman                                                                                                                                                         |
|  52 |     982.48121 |    347.785133 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
|  53 |      63.78065 |    566.895257 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  54 |     880.76194 |     45.511792 | Margot Michaud                                                                                                                                                        |
|  55 |     746.01089 |    746.017215 | Scott Hartman                                                                                                                                                         |
|  56 |     943.97336 |    428.840356 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
|  57 |     894.74669 |    168.386663 | Tasman Dixon                                                                                                                                                          |
|  58 |     631.30794 |    746.156226 | Raven Amos                                                                                                                                                            |
|  59 |     265.30524 |    639.024127 | Yan Wong                                                                                                                                                              |
|  60 |     486.18935 |    774.741777 | xgirouxb                                                                                                                                                              |
|  61 |     710.07292 |    615.362658 | Ferran Sayol                                                                                                                                                          |
|  62 |     232.15718 |    344.296739 | Chris huh                                                                                                                                                             |
|  63 |      63.60269 |    683.473891 | Zimices                                                                                                                                                               |
|  64 |     528.20998 |    631.760200 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
|  65 |     582.46192 |    533.214164 | Gareth Monger                                                                                                                                                         |
|  66 |     201.09848 |    434.476495 | Harold N Eyster                                                                                                                                                       |
|  67 |      62.83251 |    180.744632 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
|  68 |     312.66856 |    303.886431 | Scott Hartman                                                                                                                                                         |
|  69 |     867.99650 |    465.544079 | Matt Crook                                                                                                                                                            |
|  70 |     108.27489 |    347.133204 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
|  71 |     668.12287 |     97.878771 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
|  72 |     286.21118 |    741.726808 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
|  73 |     720.44076 |    708.860695 | Zimices                                                                                                                                                               |
|  74 |     673.73228 |     11.651818 | C. Abraczinskas                                                                                                                                                       |
|  75 |     210.96807 |    269.280534 | Jagged Fang Designs                                                                                                                                                   |
|  76 |     204.88296 |    124.591870 | Chris huh                                                                                                                                                             |
|  77 |     386.32637 |    263.517016 | Andy Wilson                                                                                                                                                           |
|  78 |     905.83158 |    268.047533 | Felix Vaux                                                                                                                                                            |
|  79 |      52.74635 |    770.954370 | Jagged Fang Designs                                                                                                                                                   |
|  80 |     381.23481 |    337.267617 | NASA                                                                                                                                                                  |
|  81 |     796.49778 |     34.806136 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
|  82 |      52.43830 |    309.653561 | Francesco “Architetto” Rollandin                                                                                                                                      |
|  83 |     992.53733 |    745.872707 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
|  84 |      23.74373 |    361.918930 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
|  85 |     898.44993 |    233.895352 | Chris huh                                                                                                                                                             |
|  86 |      88.07723 |    790.636786 | Chris huh                                                                                                                                                             |
|  87 |     689.97825 |    575.556278 | Karla Martinez                                                                                                                                                        |
|  88 |     311.18941 |     79.749842 | Jagged Fang Designs                                                                                                                                                   |
|  89 |     391.81136 |    783.885449 | Jagged Fang Designs                                                                                                                                                   |
|  90 |     762.98319 |    324.172714 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  91 |     776.92666 |    720.538383 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
|  92 |      59.72287 |    738.239194 | Steven Traver                                                                                                                                                         |
|  93 |     313.78064 |    652.700839 | Zimices                                                                                                                                                               |
|  94 |     702.30527 |    781.988880 | Zimices                                                                                                                                                               |
|  95 |     678.63980 |    473.409534 | Shyamal                                                                                                                                                               |
|  96 |     317.82918 |    787.340166 | CNZdenek                                                                                                                                                              |
|  97 |     832.62548 |    398.986991 | Kai R. Caspar                                                                                                                                                         |
|  98 |      96.01981 |    473.482528 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
|  99 |     552.45441 |    383.734723 | NA                                                                                                                                                                    |
| 100 |     522.47023 |    361.680111 | Emily Willoughby                                                                                                                                                      |
| 101 |     342.62369 |    124.325386 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 102 |     182.25280 |    575.473147 | Zimices                                                                                                                                                               |
| 103 |     699.18366 |     36.998836 | Jagged Fang Designs                                                                                                                                                   |
| 104 |     137.42632 |    476.641951 | Margot Michaud                                                                                                                                                        |
| 105 |     240.88267 |    271.995259 | Chris huh                                                                                                                                                             |
| 106 |     412.66618 |     59.903010 | Cagri Cevrim                                                                                                                                                          |
| 107 |     500.34166 |     80.784176 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 108 |     440.09094 |     27.937391 | Becky Barnes                                                                                                                                                          |
| 109 |     303.10218 |    188.184120 | Gareth Monger                                                                                                                                                         |
| 110 |     988.12683 |    649.838708 | Sarah Werning                                                                                                                                                         |
| 111 |     332.03364 |    332.632970 | L. Shyamal                                                                                                                                                            |
| 112 |     406.35805 |     13.184035 | Chris huh                                                                                                                                                             |
| 113 |     565.17931 |    309.830849 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 114 |     817.98334 |    299.361006 | Scott Hartman                                                                                                                                                         |
| 115 |     395.98247 |    481.765275 | Zimices                                                                                                                                                               |
| 116 |     635.12083 |    524.504290 | Chris huh                                                                                                                                                             |
| 117 |     799.76023 |    519.634195 | Chloé Schmidt                                                                                                                                                         |
| 118 |     157.19683 |    147.757824 | Scott Hartman                                                                                                                                                         |
| 119 |     415.03423 |    199.027767 | Zimices                                                                                                                                                               |
| 120 |     151.95843 |    504.689628 | Walter Vladimir                                                                                                                                                       |
| 121 |     198.21887 |    620.388199 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 122 |     863.13147 |    416.296402 | Maija Karala                                                                                                                                                          |
| 123 |     902.38187 |    660.959711 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 124 |     958.70908 |    783.201393 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 125 |     689.71532 |     24.181948 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 126 |     963.69656 |    631.450930 | Matt Crook                                                                                                                                                            |
| 127 |     593.46345 |     83.193305 | Roberto Díaz Sibaja                                                                                                                                                   |
| 128 |      88.42228 |     48.148054 | Steven Traver                                                                                                                                                         |
| 129 |     129.85556 |     39.246845 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 130 |     961.06919 |    501.188796 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 131 |     892.63072 |     14.852404 | Chloé Schmidt                                                                                                                                                         |
| 132 |     627.12934 |    213.984099 | Natalie Claunch                                                                                                                                                       |
| 133 |     487.78014 |    169.413761 | Scott Hartman                                                                                                                                                         |
| 134 |     287.87743 |    366.977599 | Cesar Julian                                                                                                                                                          |
| 135 |     501.02996 |    102.559474 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 136 |     912.62908 |    214.404186 | NA                                                                                                                                                                    |
| 137 |     717.01212 |     44.671529 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 138 |      37.62197 |    647.173630 | Birgit Lang                                                                                                                                                           |
| 139 |     670.98597 |    439.182944 | Matt Crook                                                                                                                                                            |
| 140 |      19.12387 |    127.004941 | NA                                                                                                                                                                    |
| 141 |     588.04608 |    788.747039 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 142 |     710.69361 |    113.642475 | Andrew A. Farke                                                                                                                                                       |
| 143 |     325.57486 |    221.560967 | Matt Crook                                                                                                                                                            |
| 144 |     619.55838 |    495.412891 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                           |
| 145 |     880.70269 |     96.918536 | NA                                                                                                                                                                    |
| 146 |     472.64268 |    100.672906 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 147 |    1001.89225 |    393.289328 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 148 |     626.48837 |    414.477388 | Tod Robbins                                                                                                                                                           |
| 149 |     134.92893 |    510.000143 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 150 |     419.88735 |    661.383340 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 151 |     269.39182 |     41.118032 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 152 |     994.53393 |    715.361162 | Jagged Fang Designs                                                                                                                                                   |
| 153 |     880.89301 |    643.631832 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 154 |      19.29448 |    424.555945 | Ferran Sayol                                                                                                                                                          |
| 155 |     794.28673 |    738.167729 | Andy Wilson                                                                                                                                                           |
| 156 |     947.94140 |    270.006862 | Myriam\_Ramirez                                                                                                                                                       |
| 157 |     977.02814 |    449.808965 | Steven Traver                                                                                                                                                         |
| 158 |     562.62759 |    575.878753 | NA                                                                                                                                                                    |
| 159 |      20.03167 |    236.919374 | Matt Crook                                                                                                                                                            |
| 160 |     524.44572 |    270.097586 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 161 |     961.55896 |    656.567456 | NA                                                                                                                                                                    |
| 162 |     895.28441 |    571.670030 | David Orr                                                                                                                                                             |
| 163 |      79.22712 |    389.409309 | Matt Crook                                                                                                                                                            |
| 164 |     914.64556 |     67.866906 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 165 |      45.09938 |     38.260782 | Robert Hering                                                                                                                                                         |
| 166 |     236.30049 |    439.376303 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
| 167 |    1001.89435 |    110.615476 | Zimices                                                                                                                                                               |
| 168 |     532.45150 |    153.754514 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 169 |     584.49839 |     32.118062 | Zimices                                                                                                                                                               |
| 170 |     783.80710 |    274.788772 | Tasman Dixon                                                                                                                                                          |
| 171 |     132.70784 |    494.566414 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 172 |     974.85965 |    759.832814 | Julien Louys                                                                                                                                                          |
| 173 |      18.30243 |    599.781705 | Anthony Caravaggi                                                                                                                                                     |
| 174 |     773.19267 |    339.335459 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 175 |     735.55277 |    477.748594 | Birgit Lang                                                                                                                                                           |
| 176 |     287.51828 |    712.791292 | Tasman Dixon                                                                                                                                                          |
| 177 |     696.64357 |    673.040095 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 178 |     473.39098 |    356.389997 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 179 |     121.32698 |    528.718899 | Steven Traver                                                                                                                                                         |
| 180 |     811.37932 |    547.268872 | FunkMonk                                                                                                                                                              |
| 181 |     336.27218 |    570.799172 | Abraão Leite                                                                                                                                                          |
| 182 |     125.31154 |    543.061746 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 183 |     205.72714 |    212.355096 | Gareth Monger                                                                                                                                                         |
| 184 |     775.98691 |    776.292795 | NA                                                                                                                                                                    |
| 185 |     688.75998 |    134.884947 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 186 |     177.87490 |    416.588640 | T. Michael Keesey                                                                                                                                                     |
| 187 |     936.53300 |    739.819167 | Ferran Sayol                                                                                                                                                          |
| 188 |     222.61921 |    394.549426 | Zimices                                                                                                                                                               |
| 189 |     258.13785 |    775.480602 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 190 |     124.52936 |    657.819288 | Jaime Headden                                                                                                                                                         |
| 191 |     749.90178 |    674.215150 | Iain Reid                                                                                                                                                             |
| 192 |    1014.27712 |    670.160632 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 193 |     334.92309 |     60.776798 | Meliponicultor Itaymbere                                                                                                                                              |
| 194 |     558.36850 |    751.941480 | Dean Schnabel                                                                                                                                                         |
| 195 |     601.32040 |    109.943719 | Dean Schnabel                                                                                                                                                         |
| 196 |     800.11875 |    783.586527 | Ferran Sayol                                                                                                                                                          |
| 197 |     486.23843 |    673.011459 | Yan Wong                                                                                                                                                              |
| 198 |     647.05686 |    131.379732 | Xavier Giroux-Bougard                                                                                                                                                 |
| 199 |     595.39212 |    464.210299 | Rebecca Groom                                                                                                                                                         |
| 200 |     837.87340 |    441.955123 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 201 |     687.89780 |     79.143815 | Andy Wilson                                                                                                                                                           |
| 202 |     873.94383 |    322.361694 | Scott Hartman                                                                                                                                                         |
| 203 |     179.31991 |    505.628424 | Chris huh                                                                                                                                                             |
| 204 |    1006.37824 |    594.550909 | Scott Hartman                                                                                                                                                         |
| 205 |     217.79487 |    627.788205 | Matt Crook                                                                                                                                                            |
| 206 |     945.87333 |    332.423822 | Margot Michaud                                                                                                                                                        |
| 207 |     145.91079 |    174.406151 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 208 |     775.49525 |    542.000396 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 209 |     863.00737 |    265.272709 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 210 |     104.97576 |    420.945884 | François Michonneau                                                                                                                                                   |
| 211 |      64.69320 |    458.635452 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 212 |     311.98571 |     56.488747 | Jagged Fang Designs                                                                                                                                                   |
| 213 |     989.53347 |    139.105523 | Erika Schumacher                                                                                                                                                      |
| 214 |    1001.17147 |    791.947486 | Jaime Headden                                                                                                                                                         |
| 215 |     801.74341 |    145.161538 | Josep Marti Solans                                                                                                                                                    |
| 216 |     572.36028 |    182.828024 | Andy Wilson                                                                                                                                                           |
| 217 |     363.48254 |    655.064473 | Steven Coombs                                                                                                                                                         |
| 218 |    1008.75712 |     14.633501 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 219 |     722.66761 |    261.315730 | Andrew A. Farke                                                                                                                                                       |
| 220 |     372.33027 |    603.347935 | Collin Gross                                                                                                                                                          |
| 221 |     881.55819 |    555.222914 | Matt Crook                                                                                                                                                            |
| 222 |     408.51421 |    318.177815 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
| 223 |     980.39638 |    414.522921 | Christoph Schomburg                                                                                                                                                   |
| 224 |     657.28116 |    241.794574 | Christoph Schomburg                                                                                                                                                   |
| 225 |     948.78858 |    715.138631 | Tracy A. Heath                                                                                                                                                        |
| 226 |     971.21784 |    594.174667 | Michelle Site                                                                                                                                                         |
| 227 |      48.95857 |    378.420168 | Ferran Sayol                                                                                                                                                          |
| 228 |     769.45582 |    690.157754 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 229 |     322.88552 |    353.519280 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 230 |     162.97799 |    261.601642 | T. Michael Keesey                                                                                                                                                     |
| 231 |     626.64708 |    464.942398 | Rebecca Groom                                                                                                                                                         |
| 232 |     748.06418 |    536.948077 | Crystal Maier                                                                                                                                                         |
| 233 |     238.36660 |    381.174130 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 234 |     998.68843 |    575.020844 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 235 |      58.31248 |    227.411459 | Joanna Wolfe                                                                                                                                                          |
| 236 |     948.13954 |    567.036952 | NA                                                                                                                                                                    |
| 237 |      93.19767 |    763.576592 | Meliponicultor Itaymbere                                                                                                                                              |
| 238 |     572.51088 |    722.386078 | Scott Hartman                                                                                                                                                         |
| 239 |     759.04073 |     43.712291 | Scott Reid                                                                                                                                                            |
| 240 |     657.33860 |    405.180177 | Nobu Tamura                                                                                                                                                           |
| 241 |     921.96739 |    705.048348 | Ferran Sayol                                                                                                                                                          |
| 242 |     409.80300 |    342.799903 | Tracy A. Heath                                                                                                                                                        |
| 243 |     619.55552 |    517.211395 | Milton Tan                                                                                                                                                            |
| 244 |     912.60996 |    475.547080 | Ingo Braasch                                                                                                                                                          |
| 245 |     385.04508 |     52.894629 | Jagged Fang Designs                                                                                                                                                   |
| 246 |     319.29121 |    758.927922 | Rebecca Groom                                                                                                                                                         |
| 247 |     654.16424 |    160.073128 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                 |
| 248 |      62.80211 |    424.943315 | Shyamal                                                                                                                                                               |
| 249 |      43.87159 |    126.618840 | T. Michael Keesey                                                                                                                                                     |
| 250 |     781.15377 |      8.349530 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 251 |    1015.09254 |     68.042922 | NA                                                                                                                                                                    |
| 252 |    1007.76169 |    442.660160 | Milton Tan                                                                                                                                                            |
| 253 |     578.59680 |    158.390211 | Zimices                                                                                                                                                               |
| 254 |     908.62106 |    508.148675 | Kamil S. Jaron                                                                                                                                                        |
| 255 |     879.62796 |    485.205594 | Matt Crook                                                                                                                                                            |
| 256 |     423.23081 |    583.531562 | Steven Traver                                                                                                                                                         |
| 257 |     934.69773 |    364.910675 | Matt Crook                                                                                                                                                            |
| 258 |     621.06647 |    347.544188 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 259 |     717.65471 |    644.450389 | T. Michael Keesey                                                                                                                                                     |
| 260 |     257.06901 |    194.719527 | Margot Michaud                                                                                                                                                        |
| 261 |     166.78051 |    202.812940 | Gareth Monger                                                                                                                                                         |
| 262 |     179.31291 |    733.034867 | Tasman Dixon                                                                                                                                                          |
| 263 |     987.82265 |    619.832811 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 264 |     824.01435 |    416.769419 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 265 |     908.99361 |    397.635190 | Matt Martyniuk                                                                                                                                                        |
| 266 |     162.90494 |    665.147401 | Gareth Monger                                                                                                                                                         |
| 267 |     123.35470 |    332.114706 | T. Michael Keesey                                                                                                                                                     |
| 268 |     927.65051 |    451.118698 | Kai R. Caspar                                                                                                                                                         |
| 269 |     375.68909 |    630.770092 | Caleb M. Brown                                                                                                                                                        |
| 270 |     562.35715 |    781.513075 | Matt Crook                                                                                                                                                            |
| 271 |     592.47090 |    216.310599 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 272 |      49.11364 |    406.730807 | Kamil S. Jaron                                                                                                                                                        |
| 273 |      26.02116 |     50.113847 | Michelle Site                                                                                                                                                         |
| 274 |     209.00656 |    503.478982 | Nobu Tamura                                                                                                                                                           |
| 275 |     443.12589 |    794.141657 | Jagged Fang Designs                                                                                                                                                   |
| 276 |     550.01782 |    274.050732 | T. Michael Keesey                                                                                                                                                     |
| 277 |     105.00537 |    201.677710 | Gareth Monger                                                                                                                                                         |
| 278 |     990.04227 |    671.828451 | Beth Reinke                                                                                                                                                           |
| 279 |     994.66247 |    284.491969 | Scott Hartman                                                                                                                                                         |
| 280 |     633.94790 |    146.622931 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 281 |     702.83283 |    371.355680 | Elizabeth Parker                                                                                                                                                      |
| 282 |     127.52442 |    306.790654 | Chris huh                                                                                                                                                             |
| 283 |     139.02020 |    421.726452 | Tasman Dixon                                                                                                                                                          |
| 284 |     144.96372 |     13.538076 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 285 |     207.26403 |    364.426752 | Markus A. Grohme                                                                                                                                                      |
| 286 |     278.14655 |    287.732427 | Gareth Monger                                                                                                                                                         |
| 287 |     600.84344 |    655.125621 | Melissa Broussard                                                                                                                                                     |
| 288 |     639.56558 |    667.197747 | Ignacio Contreras                                                                                                                                                     |
| 289 |     746.31540 |    773.400965 | Oliver Voigt                                                                                                                                                          |
| 290 |     248.85118 |    707.062669 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 291 |     415.33921 |    485.531437 | Zimices                                                                                                                                                               |
| 292 |     641.04348 |     84.148454 | Matt Crook                                                                                                                                                            |
| 293 |     534.32790 |     10.742158 | Ingo Braasch                                                                                                                                                          |
| 294 |      25.98086 |     81.509592 | Cathy                                                                                                                                                                 |
| 295 |     150.19100 |    292.908056 | Steven Traver                                                                                                                                                         |
| 296 |     736.52129 |     15.002746 | xgirouxb                                                                                                                                                              |
| 297 |     710.85638 |    456.077141 | FJDegrange                                                                                                                                                            |
| 298 |     197.24885 |    550.318511 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 299 |     142.82785 |    124.000219 | NA                                                                                                                                                                    |
| 300 |     899.25044 |    413.656426 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 301 |     925.46467 |    502.070905 | Jagged Fang Designs                                                                                                                                                   |
| 302 |     415.97036 |    637.979146 | xgirouxb                                                                                                                                                              |
| 303 |      20.60661 |    693.305261 | Ferran Sayol                                                                                                                                                          |
| 304 |     354.53773 |    348.297617 | Ingo Braasch                                                                                                                                                          |
| 305 |    1008.02788 |    465.667708 | Gareth Monger                                                                                                                                                         |
| 306 |     644.80100 |    785.820378 | Margot Michaud                                                                                                                                                        |
| 307 |     566.63166 |    104.968946 | Markus A. Grohme                                                                                                                                                      |
| 308 |     447.70126 |    470.232994 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 309 |     591.97315 |    336.056613 | Andy Wilson                                                                                                                                                           |
| 310 |      12.37954 |     97.959128 | Gareth Monger                                                                                                                                                         |
| 311 |     614.42377 |    546.350703 | Lukasiniho                                                                                                                                                            |
| 312 |     181.09068 |    599.858236 | NA                                                                                                                                                                    |
| 313 |     449.07212 |      6.216628 | Chris huh                                                                                                                                                             |
| 314 |     945.69444 |     23.335682 | Madeleine Price Ball                                                                                                                                                  |
| 315 |     938.37317 |    614.954640 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 316 |      19.07040 |    140.604673 | C. Camilo Julián-Caballero                                                                                                                                            |
| 317 |     669.06249 |    676.581409 | Ingo Braasch                                                                                                                                                          |
| 318 |     111.51034 |    316.515323 | Julio Garza                                                                                                                                                           |
| 319 |     200.63993 |    373.910717 | Michael P. Taylor                                                                                                                                                     |
| 320 |     231.44509 |    254.807884 | Markus A. Grohme                                                                                                                                                      |
| 321 |     291.66679 |    317.607556 | Jagged Fang Designs                                                                                                                                                   |
| 322 |     996.54310 |    542.960787 | Matt Crook                                                                                                                                                            |
| 323 |     215.02055 |    245.356792 | Maija Karala                                                                                                                                                          |
| 324 |     878.86241 |    622.276740 | Chris A. Hamilton                                                                                                                                                     |
| 325 |     970.11376 |    273.231662 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 326 |     178.85638 |    106.961414 | V. Deepak                                                                                                                                                             |
| 327 |     281.35393 |    242.727466 | Scott Hartman                                                                                                                                                         |
| 328 |     174.79427 |    338.287191 | Zimices                                                                                                                                                               |
| 329 |     821.70022 |    720.142496 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 330 |     779.06134 |    464.347737 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 331 |     240.97547 |    424.366193 | John Conway                                                                                                                                                           |
| 332 |     245.83358 |    117.135590 | NA                                                                                                                                                                    |
| 333 |     206.76511 |    142.605971 | Matt Crook                                                                                                                                                            |
| 334 |     566.22379 |     49.788823 | NA                                                                                                                                                                    |
| 335 |      99.05746 |    533.418613 | Maija Karala                                                                                                                                                          |
| 336 |     695.20206 |     92.171092 | Collin Gross                                                                                                                                                          |
| 337 |     373.42277 |    768.745897 | Matt Martyniuk                                                                                                                                                        |
| 338 |     765.14542 |    220.649586 | T. Michael Keesey                                                                                                                                                     |
| 339 |     876.41856 |    653.040997 | Chris huh                                                                                                                                                             |
| 340 |     682.93973 |    413.156400 | Jagged Fang Designs                                                                                                                                                   |
| 341 |     116.12423 |    738.968594 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 342 |     629.25703 |    394.505115 | Scott Hartman                                                                                                                                                         |
| 343 |     624.31637 |    155.060711 | Ignacio Contreras                                                                                                                                                     |
| 344 |      19.71326 |    160.112240 | C. Camilo Julián-Caballero                                                                                                                                            |
| 345 |     177.91296 |     24.838715 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 346 |     783.21091 |     62.023201 | Thibaut Brunet                                                                                                                                                        |
| 347 |     338.37293 |    493.822446 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 348 |     536.18619 |    584.885599 | Ferran Sayol                                                                                                                                                          |
| 349 |     527.80972 |    749.262730 | Margot Michaud                                                                                                                                                        |
| 350 |     792.97366 |    342.673545 | Michelle Site                                                                                                                                                         |
| 351 |      43.37686 |    793.189648 | Kai R. Caspar                                                                                                                                                         |
| 352 |      78.83657 |    216.044896 | Scott Hartman                                                                                                                                                         |
| 353 |     256.12898 |    290.790217 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 354 |     842.85084 |    700.799107 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 355 |     310.32129 |      6.296142 | Zimices                                                                                                                                                               |
| 356 |     568.27586 |    330.131666 | Matt Crook                                                                                                                                                            |
| 357 |     626.32364 |    477.208102 | Markus A. Grohme                                                                                                                                                      |
| 358 |     727.35107 |     93.841548 | Tasman Dixon                                                                                                                                                          |
| 359 |     593.31826 |    375.726554 | Emily Willoughby                                                                                                                                                      |
| 360 |     370.56455 |    218.990385 | NA                                                                                                                                                                    |
| 361 |     570.51518 |    463.499071 | Jagged Fang Designs                                                                                                                                                   |
| 362 |     879.74218 |    429.723135 | NA                                                                                                                                                                    |
| 363 |     692.06318 |    520.237356 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 364 |     547.83766 |    296.696320 | NA                                                                                                                                                                    |
| 365 |     640.42315 |    235.201044 | Gareth Monger                                                                                                                                                         |
| 366 |     488.65315 |    371.421705 | C. Camilo Julián-Caballero                                                                                                                                            |
| 367 |     449.90321 |    353.857688 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 368 |     358.95464 |    475.405403 | Sarah Werning                                                                                                                                                         |
| 369 |     864.54117 |    109.510044 | Armin Reindl                                                                                                                                                          |
| 370 |     743.11245 |    290.814348 | Matt Crook                                                                                                                                                            |
| 371 |     121.04511 |    194.119050 | Matt Crook                                                                                                                                                            |
| 372 |     517.63197 |    485.623577 | Pete Buchholz                                                                                                                                                         |
| 373 |     871.58231 |    390.712555 | Myriam\_Ramirez                                                                                                                                                       |
| 374 |     522.80230 |    170.209173 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 375 |     967.16008 |    476.313869 | Gareth Monger                                                                                                                                                         |
| 376 |     801.52053 |    177.145058 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 377 |     266.00327 |    795.249743 | Scott Hartman                                                                                                                                                         |
| 378 |     353.09846 |    320.347808 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 379 |     241.10355 |    208.025651 | Felix Vaux                                                                                                                                                            |
| 380 |     391.68590 |    379.013132 | Tasman Dixon                                                                                                                                                          |
| 381 |     391.95610 |    293.438943 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 382 |      92.01510 |    305.471215 | NA                                                                                                                                                                    |
| 383 |     595.94236 |    389.256476 | Markus A. Grohme                                                                                                                                                      |
| 384 |      72.04977 |    716.973735 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 385 |     840.21791 |    302.005294 | Jaime Headden                                                                                                                                                         |
| 386 |     961.22198 |     31.180796 | Matt Crook                                                                                                                                                            |
| 387 |     689.57201 |    288.621565 | Campbell Fleming                                                                                                                                                      |
| 388 |     226.08004 |     10.516560 | Tasman Dixon                                                                                                                                                          |
| 389 |     453.31201 |    179.017100 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
| 390 |     275.34617 |    381.851056 | Chris huh                                                                                                                                                             |
| 391 |     809.67669 |    256.673072 | Jaime Headden                                                                                                                                                         |
| 392 |     203.94910 |    703.437557 | Carlos Cano-Barbacil                                                                                                                                                  |
| 393 |     129.18161 |    774.215105 | Carlos Cano-Barbacil                                                                                                                                                  |
| 394 |     582.38864 |    598.149326 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 395 |      14.57247 |    284.806529 | Ferran Sayol                                                                                                                                                          |
| 396 |     678.12744 |    610.070790 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 397 |     526.64339 |     95.048003 | Ignacio Contreras                                                                                                                                                     |
| 398 |     499.55603 |     60.852786 | Yan Wong                                                                                                                                                              |
| 399 |     700.03202 |    427.955557 | Carlos Cano-Barbacil                                                                                                                                                  |
| 400 |     599.54235 |    317.187072 | Walter Vladimir                                                                                                                                                       |
| 401 |     229.93265 |    747.755453 | Scott Hartman                                                                                                                                                         |
| 402 |     264.96761 |    574.540867 | Birgit Lang                                                                                                                                                           |
| 403 |     213.88527 |    717.613619 | Michael Scroggie                                                                                                                                                      |
| 404 |     329.32698 |     90.176371 | Andy Wilson                                                                                                                                                           |
| 405 |     590.29941 |    771.617736 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 406 |     537.85037 |    249.666520 | Chris huh                                                                                                                                                             |
| 407 |     926.32313 |    288.161660 | Pete Buchholz                                                                                                                                                         |
| 408 |     405.23884 |    750.493452 | Sarah Werning                                                                                                                                                         |
| 409 |     994.90400 |    687.341810 | Maija Karala                                                                                                                                                          |
| 410 |     327.14263 |    420.609321 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 411 |     425.87609 |    254.653032 | Christoph Schomburg                                                                                                                                                   |
| 412 |      26.94206 |    622.590546 | Tracy A. Heath                                                                                                                                                        |
| 413 |     822.10133 |     11.608267 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 414 |     627.68151 |     19.362595 | Michael Scroggie                                                                                                                                                      |
| 415 |     547.03869 |    483.441418 | Sharon Wegner-Larsen                                                                                                                                                  |
| 416 |     334.74777 |    515.293974 | Gareth Monger                                                                                                                                                         |
| 417 |     332.49669 |    282.759272 | Steven Traver                                                                                                                                                         |
| 418 |     449.02961 |    645.076020 | Thibaut Brunet                                                                                                                                                        |
| 419 |     281.09528 |    394.477245 | Chris huh                                                                                                                                                             |
| 420 |     259.58821 |     17.753329 | Gareth Monger                                                                                                                                                         |
| 421 |     269.39467 |    214.166031 | Gareth Monger                                                                                                                                                         |
| 422 |     663.55408 |    377.639914 | Jagged Fang Designs                                                                                                                                                   |
| 423 |     344.38224 |    665.407003 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 424 |     962.83873 |    317.095019 | Matt Crook                                                                                                                                                            |
| 425 |     364.30390 |      8.416557 | Jagged Fang Designs                                                                                                                                                   |
| 426 |     892.09366 |    592.472140 | Smokeybjb                                                                                                                                                             |
| 427 |     818.01075 |    752.323864 | Ferran Sayol                                                                                                                                                          |
| 428 |     694.76164 |    687.401327 | Juan Carlos Jerí                                                                                                                                                      |
| 429 |     481.77816 |    580.624199 | Markus A. Grohme                                                                                                                                                      |
| 430 |     742.46484 |    127.315123 | Margot Michaud                                                                                                                                                        |
| 431 |     895.97085 |    285.837721 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 432 |     109.34376 |     87.355096 | Chris huh                                                                                                                                                             |
| 433 |      81.33155 |    406.945630 | Scott Hartman                                                                                                                                                         |
| 434 |      54.24294 |    290.558118 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 435 |     656.77038 |    418.705012 | Markus A. Grohme                                                                                                                                                      |
| 436 |     192.30756 |     12.574215 | Tasman Dixon                                                                                                                                                          |
| 437 |      91.92398 |    645.391646 | T. Michael Keesey                                                                                                                                                     |
| 438 |     797.19026 |    706.863082 | Gareth Monger                                                                                                                                                         |
| 439 |     326.06631 |    736.703552 | Steven Traver                                                                                                                                                         |
| 440 |     704.55165 |    324.197990 | Ferran Sayol                                                                                                                                                          |
| 441 |     709.34175 |    421.523999 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 442 |     316.08558 |    749.385348 | Tyler McCraney                                                                                                                                                        |
| 443 |     221.01734 |    588.162988 | Vanessa Guerra                                                                                                                                                        |
| 444 |     140.49332 |    579.354680 | Smokeybjb                                                                                                                                                             |
| 445 |     257.36301 |    411.603315 | Erika Schumacher                                                                                                                                                      |
| 446 |      96.91978 |     99.585369 | Chris huh                                                                                                                                                             |
| 447 |     365.91930 |    616.698783 | Chris huh                                                                                                                                                             |
| 448 |     659.05474 |     29.368701 | Jagged Fang Designs                                                                                                                                                   |
| 449 |     384.26867 |    581.704065 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 450 |     421.71939 |    212.884968 | Iain Reid                                                                                                                                                             |
| 451 |      19.87786 |    220.707254 | Shyamal                                                                                                                                                               |
| 452 |     996.87478 |    375.454735 | Markus A. Grohme                                                                                                                                                      |
| 453 |     308.23543 |    494.269698 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 454 |     262.36112 |     54.319408 | Sarah Werning                                                                                                                                                         |
| 455 |     301.18329 |     12.378979 | Andy Wilson                                                                                                                                                           |
| 456 |     506.72537 |    340.565607 | Andrew A. Farke                                                                                                                                                       |
| 457 |     445.27516 |    197.208844 | Harold N Eyster                                                                                                                                                       |
| 458 |     507.55271 |    731.566344 | Ferran Sayol                                                                                                                                                          |
| 459 |     775.53945 |    755.901985 | Christine Axon                                                                                                                                                        |
| 460 |     830.77512 |    159.181086 | Jiekun He                                                                                                                                                             |
| 461 |     610.76795 |    786.465160 | NA                                                                                                                                                                    |
| 462 |     745.51580 |    316.269798 | Alex Slavenko                                                                                                                                                         |
| 463 |     681.39080 |    174.952749 | Margot Michaud                                                                                                                                                        |
| 464 |     515.51256 |      4.910882 | Caleb M. Brown                                                                                                                                                        |
| 465 |     550.01175 |    602.852504 | Jagged Fang Designs                                                                                                                                                   |
| 466 |     572.69614 |    362.535661 | Becky Barnes                                                                                                                                                          |
| 467 |     446.32059 |    343.450961 | Beth Reinke                                                                                                                                                           |
| 468 |     593.08430 |     14.287148 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 469 |     633.00567 |    182.332329 | Gareth Monger                                                                                                                                                         |
| 470 |     375.99321 |    642.266171 | Darius Nau                                                                                                                                                            |
| 471 |     936.05841 |    783.562173 | Ferran Sayol                                                                                                                                                          |
| 472 |     145.99491 |    214.975458 | Scott Hartman                                                                                                                                                         |
| 473 |     683.58858 |    654.297280 | Zimices                                                                                                                                                               |
| 474 |     405.43513 |     22.907525 | Markus A. Grohme                                                                                                                                                      |
| 475 |     976.39233 |    426.282040 | Markus A. Grohme                                                                                                                                                      |
| 476 |     643.29211 |    642.561789 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 477 |      13.21071 |    770.101235 | Michael Scroggie                                                                                                                                                      |
| 478 |     658.61737 |    488.751318 | Kanchi Nanjo                                                                                                                                                          |
| 479 |     630.96323 |    364.421608 | NA                                                                                                                                                                    |
| 480 |     120.73132 |    553.417367 | Gareth Monger                                                                                                                                                         |
| 481 |     704.43020 |    347.160562 | Robert Gay                                                                                                                                                            |
| 482 |     547.38337 |    727.760323 | Tauana J. Cunha                                                                                                                                                       |
| 483 |     853.11667 |    793.127166 | Mykle Hoban                                                                                                                                                           |
| 484 |     386.68452 |    395.852273 | Ghedoghedo                                                                                                                                                            |
| 485 |      14.51310 |    714.493360 | T. Michael Keesey                                                                                                                                                     |
| 486 |     321.35021 |    577.329732 | Dmitry Bogdanov                                                                                                                                                       |
| 487 |     230.22979 |    151.866915 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 488 |     813.22504 |     62.315261 | Jagged Fang Designs                                                                                                                                                   |
| 489 |     264.27190 |    780.654839 | Jagged Fang Designs                                                                                                                                                   |
| 490 |     940.93875 |    760.222080 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 491 |     461.04578 |    260.372396 | Terpsichores                                                                                                                                                          |
| 492 |     466.89457 |    634.125172 | Gareth Monger                                                                                                                                                         |
| 493 |     847.76342 |    654.590664 | Zimices                                                                                                                                                               |
| 494 |     421.84291 |    180.924430 | Margot Michaud                                                                                                                                                        |
| 495 |     886.42062 |    635.513162 | Beth Reinke                                                                                                                                                           |
| 496 |     811.59135 |    232.603068 | Gareth Monger                                                                                                                                                         |
| 497 |     606.12019 |    226.287945 | Steven Traver                                                                                                                                                         |
| 498 |     898.54067 |    241.656534 | Scott Hartman                                                                                                                                                         |
| 499 |     988.01267 |     80.894756 | Markus A. Grohme                                                                                                                                                      |
| 500 |     692.77921 |    766.331866 | Dmitry Bogdanov                                                                                                                                                       |
| 501 |      61.83041 |    767.262504 | NA                                                                                                                                                                    |
| 502 |     295.70361 |    700.598170 | Jagged Fang Designs                                                                                                                                                   |
| 503 |     800.69368 |    168.495480 | Roberto Díaz Sibaja                                                                                                                                                   |
| 504 |     787.26172 |    311.864977 | Christoph Schomburg                                                                                                                                                   |
| 505 |     314.76061 |    482.001151 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 506 |     694.16706 |    727.770753 | M Kolmann                                                                                                                                                             |
| 507 |     132.69447 |    643.529271 | Emily Willoughby                                                                                                                                                      |
| 508 |     260.64751 |    188.280741 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 509 |     176.68323 |    726.183805 | Scott Hartman                                                                                                                                                         |
| 510 |     490.36045 |    662.304629 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 511 |     261.34583 |    254.178225 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 512 |     879.92774 |    119.814842 | Maija Karala                                                                                                                                                          |
| 513 |     615.94683 |    194.022500 | Ignacio Contreras                                                                                                                                                     |
| 514 |      71.65927 |    110.555033 | Jagged Fang Designs                                                                                                                                                   |
| 515 |     254.27220 |    639.766041 | Chris huh                                                                                                                                                             |
| 516 |     383.54951 |     68.294115 | Andy Wilson                                                                                                                                                           |
| 517 |    1000.43678 |    779.243599 | Matt Crook                                                                                                                                                            |
| 518 |     570.58929 |    249.273513 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 519 |     256.41369 |    457.544738 | Emily Willoughby                                                                                                                                                      |
| 520 |     136.61936 |     72.635296 | Margot Michaud                                                                                                                                                        |

    #> Your tweet has been posted!
