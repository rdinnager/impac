
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

Leann Biancani, photo by Kenneth Clifton, T. Michael Keesey, Ignacio
Contreras, Matt Crook, Dmitry Bogdanov (modified by T. Michael Keesey),
Nobu Tamura, vectorized by Zimices, Gabriela Palomo-Munoz, S.Martini,
Jagged Fang Designs, John Conway, Birgit Lang, Steven Traver, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Tasman Dixon, Dmitry
Bogdanov, vectorized by Zimices, Mike Keesey (vectorization) and
Vaibhavcho (photography), Margot Michaud, Zimices, Matthew E. Clapham,
Oscar Sanisidro, Markus A. Grohme, Christoph Schomburg, Tony Ayling
(vectorized by T. Michael Keesey), Nicolas Huet le Jeune and
Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), Michele Tobias,
Ewald Rübsamen, Benchill, Ray Simpson (vectorized by T. Michael Keesey),
Armin Reindl, Scarlet23 (vectorized by T. Michael Keesey), Gareth
Monger, Ferran Sayol, Emily Willoughby, Walter Vladimir, Chris huh, Yan
Wong from photo by Denes Emoke, Zachary Quigley, Nobu Tamura (vectorized
by T. Michael Keesey), Steven Coombs, Neil Kelley, Caleb Brown, Thibaut
Brunet, Scott Hartman, Alexander Schmidt-Lebuhn, Jaime Headden, modified
by T. Michael Keesey, C. Camilo Julián-Caballero, Maxime Dahirel, Javier
Luque & Sarah Gerken, Michelle Site, Collin Gross, Michael Scroggie,
Julio Garza, Caleb M. Brown, Ghedoghedo (vectorized by T. Michael
Keesey), Joanna Wolfe, Matt Celeskey, Mykle Hoban, Sarah Werning, Katie
S. Collins, Mihai Dragos (vectorized by T. Michael Keesey), Xavier
Giroux-Bougard, Jaime Headden, Matt Martyniuk, Tony Ayling, Carlos
Cano-Barbacil, M Kolmann, Roberto Díaz Sibaja, Scott Hartman (modified
by T. Michael Keesey), Matt Hayes, Smokeybjb, Evan Swigart (photography)
and T. Michael Keesey (vectorization), Didier Descouens (vectorized by
T. Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A. Balfour
& Rob Slotow (vectorized by T. Michael Keesey), Acrocynus (vectorized by
T. Michael Keesey), SauropodomorphMonarch, Greg Schechter (original
photo), Renato Santos (vector silhouette), Ellen Edmonson and Hugh
Chrisp (vectorized by T. Michael Keesey), CNZdenek, Jon Hill, Yan Wong,
Iain Reid, Conty, Nicholas J. Czaplewski, vectorized by Zimices, Enoch
Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, xgirouxb, Alex Slavenko, Tracy A. Heath, Fcb981
(vectorized by T. Michael Keesey), Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Robert Gay, modifed from Olegivvit,
Conty (vectorized by T. Michael Keesey), Auckland Museum, Darren Naish
(vectorized by T. Michael Keesey), Mathew Wedel, Scott Reid, Eduard Solà
Vázquez, vectorised by Yan Wong, Noah Schlottman, photo by Reinhard
Jahn, Felix Vaux, U.S. Fish and Wildlife Service (illustration) and
Timothy J. Bartley (silhouette), Sharon Wegner-Larsen, Maija Karala,
Michele M Tobias, Michael Ströck (vectorized by T. Michael Keesey),
Jennifer Trimble, Lily Hughes, T. Michael Keesey (vectorization) and
Larry Loos (photography), Tauana J. Cunha, Geoff Shaw, Ingo Braasch, Jay
Matternes (vectorized by T. Michael Keesey), Mathieu Basille, terngirl,
Smokeybjb (modified by Mike Keesey), Kanchi Nanjo, Kenneth Lacovara
(vectorized by T. Michael Keesey), V. Deepak, Kamil S. Jaron, Matt
Dempsey, John Curtis (vectorized by T. Michael Keesey), Pearson Scott
Foresman (vectorized by T. Michael Keesey), Tambja (vectorized by T.
Michael Keesey), Dean Schnabel, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Jack Mayer Wood,
Anthony Caravaggi, Chuanixn Yu, Charles R. Knight (vectorized by T.
Michael Keesey), Manabu Bessho-Uehara, Beth Reinke, Armelle Ansart
(photograph), Maxime Dahirel (digitisation), Roger Witter, vectorized by
Zimices, Andrew Farke and Joseph Sertich, Agnello Picorelli, Tyler
McCraney, L. Shyamal, Francesca Belem Lopes Palmeira, Jerry Oldenettel
(vectorized by T. Michael Keesey), George Edward Lodge (vectorized by T.
Michael Keesey), Young and Zhao (1972:figure 4), modified by Michael P.
Taylor, Rebecca Groom, Darren Naish (vectorize by T. Michael Keesey),
Aleksey Nagovitsyn (vectorized by T. Michael Keesey), Cesar Julian,
Melissa Broussard, Apokryltaros (vectorized by T. Michael Keesey),
Lankester Edwin Ray (vectorized by T. Michael Keesey), Jose Carlos
Arenas-Monroy, Natasha Vitek, NASA, Matthias Buschmann (vectorized by T.
Michael Keesey), Jim Bendon (photography) and T. Michael Keesey
(vectorization), Juan Carlos Jerí, Jordan Mallon (vectorized by T.
Michael Keesey), Nobu Tamura, Andrew A. Farke, Karla Martinez, Amanda
Katzer, TaraTaylorDesign, Lukasiniho, Mali’o Kodis, photograph by Hans
Hillewaert, Darius Nau, James Neenan, Robbie N. Cada (modified by T.
Michael Keesey), (unknown), Emil Schmidt (vectorized by Maxime Dahirel),
Benjamin Monod-Broca, Milton Tan, Lip Kee Yap (vectorized by T. Michael
Keesey), Yan Wong from drawing by T. F. Zimmermann, Dexter R. Mardis,
Shyamal, Falconaumanni and T. Michael Keesey, Duane Raver (vectorized by
T. Michael Keesey), Charles R. Knight, vectorized by Zimices, Matt
Martyniuk (vectorized by T. Michael Keesey), Frank Förster, Chris
Jennings (Risiatto), C. Abraczinskas, Steven Coombs (vectorized by T.
Michael Keesey), Philip Chalmers (vectorized by T. Michael Keesey),
Harold N Eyster, Steven Haddock • Jellywatch.org, FunkMonk, T. K.
Robinson, Alexandre Vong, Johan Lindgren, Michael W. Caldwell, Takuya
Konishi, Luis M. Chiappe, Maxwell Lefroy (vectorized by T. Michael
Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     450.29288 |    251.862751 | Leann Biancani, photo by Kenneth Clifton                                                                                                                           |
|   2 |     125.56534 |    374.140122 | T. Michael Keesey                                                                                                                                                  |
|   3 |     676.03718 |    330.082786 | Ignacio Contreras                                                                                                                                                  |
|   4 |     150.30312 |    574.131395 | Matt Crook                                                                                                                                                         |
|   5 |     697.94511 |    189.248091 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                    |
|   6 |     920.44187 |    695.666560 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
|   7 |     229.76232 |    626.339595 | Gabriela Palomo-Munoz                                                                                                                                              |
|   8 |     647.17859 |    699.251961 | Matt Crook                                                                                                                                                         |
|   9 |     832.85589 |    515.849850 | S.Martini                                                                                                                                                          |
|  10 |      97.77476 |    642.894935 | Jagged Fang Designs                                                                                                                                                |
|  11 |     604.59794 |    632.126526 | John Conway                                                                                                                                                        |
|  12 |     330.42611 |    248.032815 | Birgit Lang                                                                                                                                                        |
|  13 |     583.00518 |    455.936627 | Steven Traver                                                                                                                                                      |
|  14 |     652.41352 |    147.082588 | NA                                                                                                                                                                 |
|  15 |     154.83228 |    723.235644 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  16 |     914.77390 |     76.891701 | Tasman Dixon                                                                                                                                                       |
|  17 |     326.82348 |    518.214868 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                             |
|  18 |     955.77945 |    223.004937 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                           |
|  19 |     298.18166 |    398.529668 | Margot Michaud                                                                                                                                                     |
|  20 |     660.11203 |     56.114269 | Margot Michaud                                                                                                                                                     |
|  21 |      63.72378 |    195.378467 | Margot Michaud                                                                                                                                                     |
|  22 |     495.53499 |    719.601438 | T. Michael Keesey                                                                                                                                                  |
|  23 |     909.28962 |    138.540432 | Gabriela Palomo-Munoz                                                                                                                                              |
|  24 |     343.91772 |    699.537891 | Zimices                                                                                                                                                            |
|  25 |     454.46657 |    550.046071 | Matthew E. Clapham                                                                                                                                                 |
|  26 |     463.51627 |     82.189791 | Oscar Sanisidro                                                                                                                                                    |
|  27 |     745.57419 |    722.957691 | Markus A. Grohme                                                                                                                                                   |
|  28 |     932.16651 |    740.189905 | Margot Michaud                                                                                                                                                     |
|  29 |     170.13657 |    100.525491 | Christoph Schomburg                                                                                                                                                |
|  30 |     286.04981 |    444.354127 | NA                                                                                                                                                                 |
|  31 |     364.53954 |     77.921116 | Steven Traver                                                                                                                                                      |
|  32 |     586.14028 |    249.202745 | NA                                                                                                                                                                 |
|  33 |     164.17727 |     31.890194 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                      |
|  34 |     444.16025 |    735.938828 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                    |
|  35 |     759.08711 |    310.218789 | Michele Tobias                                                                                                                                                     |
|  36 |     868.78656 |    279.947790 | NA                                                                                                                                                                 |
|  37 |     448.86532 |    444.242433 | Ewald Rübsamen                                                                                                                                                     |
|  38 |     575.91051 |    363.775656 | Benchill                                                                                                                                                           |
|  39 |     274.14310 |    134.549620 | Zimices                                                                                                                                                            |
|  40 |     231.52971 |    202.138362 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                      |
|  41 |     794.34129 |    140.489478 | Margot Michaud                                                                                                                                                     |
|  42 |     912.29936 |    338.466615 | Christoph Schomburg                                                                                                                                                |
|  43 |     521.31947 |    160.600773 | T. Michael Keesey                                                                                                                                                  |
|  44 |      57.49049 |    736.925443 | Armin Reindl                                                                                                                                                       |
|  45 |     292.79262 |     46.593482 | Tasman Dixon                                                                                                                                                       |
|  46 |     337.31177 |    634.962365 | Steven Traver                                                                                                                                                      |
|  47 |     209.46145 |    306.667867 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                        |
|  48 |     261.23721 |    711.553600 | Gareth Monger                                                                                                                                                      |
|  49 |     543.71312 |     60.995104 | Ferran Sayol                                                                                                                                                       |
|  50 |     612.93289 |    571.634044 | Emily Willoughby                                                                                                                                                   |
|  51 |     275.97215 |    590.233138 | Walter Vladimir                                                                                                                                                    |
|  52 |     683.59365 |    231.665482 | Gareth Monger                                                                                                                                                      |
|  53 |     369.87646 |    135.687052 | Chris huh                                                                                                                                                          |
|  54 |      70.02222 |    503.034023 | Chris huh                                                                                                                                                          |
|  55 |     549.80810 |    313.856827 | Yan Wong from photo by Denes Emoke                                                                                                                                 |
|  56 |     859.15519 |    780.677384 | Jagged Fang Designs                                                                                                                                                |
|  57 |     552.15619 |    772.739510 | Zachary Quigley                                                                                                                                                    |
|  58 |     544.37967 |    613.655406 | Jagged Fang Designs                                                                                                                                                |
|  59 |     606.89382 |    692.039182 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  60 |      67.06156 |     98.125316 | Steven Coombs                                                                                                                                                      |
|  61 |     348.18013 |    331.655209 | Neil Kelley                                                                                                                                                        |
|  62 |     654.72673 |    535.635228 | NA                                                                                                                                                                 |
|  63 |      52.35514 |    360.469913 | NA                                                                                                                                                                 |
|  64 |     812.85913 |    221.736469 | Steven Traver                                                                                                                                                      |
|  65 |     873.96704 |     26.346151 | Jagged Fang Designs                                                                                                                                                |
|  66 |     190.51378 |    494.054513 | Chris huh                                                                                                                                                          |
|  67 |     764.96220 |     33.892612 | Caleb Brown                                                                                                                                                        |
|  68 |     231.92367 |    783.626415 | Birgit Lang                                                                                                                                                        |
|  69 |     277.86917 |     15.777068 | Thibaut Brunet                                                                                                                                                     |
|  70 |      41.45865 |    446.050316 | Scott Hartman                                                                                                                                                      |
|  71 |     569.98330 |    166.655139 | Neil Kelley                                                                                                                                                        |
|  72 |      33.45271 |     29.012341 | Alexander Schmidt-Lebuhn                                                                                                                                           |
|  73 |      59.30073 |    134.142417 | Jaime Headden, modified by T. Michael Keesey                                                                                                                       |
|  74 |     395.99197 |    175.289353 | Tasman Dixon                                                                                                                                                       |
|  75 |      98.24523 |    290.675834 | Gareth Monger                                                                                                                                                      |
|  76 |     255.49035 |    259.328678 | C. Camilo Julián-Caballero                                                                                                                                         |
|  77 |     235.08774 |    358.148824 | Steven Traver                                                                                                                                                      |
|  78 |     196.67409 |    429.855900 | Maxime Dahirel                                                                                                                                                     |
|  79 |     984.27614 |    391.558242 | Javier Luque & Sarah Gerken                                                                                                                                        |
|  80 |     795.93724 |    788.313585 | Gareth Monger                                                                                                                                                      |
|  81 |     221.80489 |     72.867365 | T. Michael Keesey                                                                                                                                                  |
|  82 |     148.42602 |    657.800455 | Michelle Site                                                                                                                                                      |
|  83 |     483.81684 |    371.326350 | Ferran Sayol                                                                                                                                                       |
|  84 |     435.27478 |    615.853607 | Collin Gross                                                                                                                                                       |
|  85 |     250.26122 |    284.432493 | Michael Scroggie                                                                                                                                                   |
|  86 |     114.66843 |    223.658436 | Birgit Lang                                                                                                                                                        |
|  87 |     386.74154 |    463.195468 | Julio Garza                                                                                                                                                        |
|  88 |     375.66841 |    409.664716 | Caleb M. Brown                                                                                                                                                     |
|  89 |     355.17279 |    578.662313 | Zimices                                                                                                                                                            |
|  90 |     699.03065 |    610.961242 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
|  91 |     773.25369 |    760.183951 | Joanna Wolfe                                                                                                                                                       |
|  92 |     770.41611 |    166.787640 | Matt Celeskey                                                                                                                                                      |
|  93 |     354.97839 |    326.257086 | Mykle Hoban                                                                                                                                                        |
|  94 |      46.55051 |    534.182307 | NA                                                                                                                                                                 |
|  95 |     258.78428 |    536.987155 | Sarah Werning                                                                                                                                                      |
|  96 |     441.99828 |    648.357995 | Katie S. Collins                                                                                                                                                   |
|  97 |     440.52833 |    141.911919 | Sarah Werning                                                                                                                                                      |
|  98 |     940.41960 |     35.029853 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                     |
|  99 |     388.15308 |    789.679413 | Scott Hartman                                                                                                                                                      |
| 100 |     935.25163 |    628.021589 | Steven Traver                                                                                                                                                      |
| 101 |     742.40861 |    681.838650 | Steven Traver                                                                                                                                                      |
| 102 |      71.20476 |     63.546937 | Chris huh                                                                                                                                                          |
| 103 |     649.81201 |    782.159663 | Xavier Giroux-Bougard                                                                                                                                              |
| 104 |     608.33458 |     44.864830 | Scott Hartman                                                                                                                                                      |
| 105 |     385.93461 |     23.944507 | Sarah Werning                                                                                                                                                      |
| 106 |     677.43104 |    401.599626 | Matt Crook                                                                                                                                                         |
| 107 |      64.89714 |    573.874761 | Zachary Quigley                                                                                                                                                    |
| 108 |      34.36081 |    650.637971 | Steven Traver                                                                                                                                                      |
| 109 |      32.57363 |    267.675615 | Steven Traver                                                                                                                                                      |
| 110 |      74.88473 |    592.015968 | Jaime Headden                                                                                                                                                      |
| 111 |     973.08331 |    658.182488 | T. Michael Keesey                                                                                                                                                  |
| 112 |     753.73103 |     67.239700 | Matt Martyniuk                                                                                                                                                     |
| 113 |     598.67807 |    208.943152 | Gareth Monger                                                                                                                                                      |
| 114 |     706.96840 |    116.549646 | Tony Ayling                                                                                                                                                        |
| 115 |     133.29332 |    780.842974 | NA                                                                                                                                                                 |
| 116 |     443.77273 |    492.209196 | Carlos Cano-Barbacil                                                                                                                                               |
| 117 |     218.57652 |    334.535883 | Matt Crook                                                                                                                                                         |
| 118 |     455.87620 |    319.073719 | Gareth Monger                                                                                                                                                      |
| 119 |     386.57286 |    739.377549 | M Kolmann                                                                                                                                                          |
| 120 |     454.81525 |     13.582018 | Roberto Díaz Sibaja                                                                                                                                                |
| 121 |     477.33558 |    189.377275 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                      |
| 122 |     570.33878 |    291.814483 | Margot Michaud                                                                                                                                                     |
| 123 |     584.26151 |      9.883821 | Matt Hayes                                                                                                                                                         |
| 124 |      27.74214 |    471.008109 | Zimices                                                                                                                                                            |
| 125 |     856.58825 |    720.697723 | Smokeybjb                                                                                                                                                          |
| 126 |     949.29062 |    400.789888 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                   |
| 127 |     568.65608 |    192.786829 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 128 |     435.42831 |    386.246779 | Jagged Fang Designs                                                                                                                                                |
| 129 |     209.07868 |    263.106057 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 130 |     328.74283 |    779.468244 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 131 |     486.22094 |    202.392576 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                        |
| 132 |     720.35937 |    624.214761 | Steven Traver                                                                                                                                                      |
| 133 |     971.05375 |    275.025786 | Birgit Lang                                                                                                                                                        |
| 134 |     698.54099 |    274.932415 | Tasman Dixon                                                                                                                                                       |
| 135 |     375.62138 |    722.719642 | SauropodomorphMonarch                                                                                                                                              |
| 136 |      83.98121 |    240.343677 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                 |
| 137 |     711.75195 |    764.469967 | Scott Hartman                                                                                                                                                      |
| 138 |     967.90845 |    292.895235 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                   |
| 139 |     803.75812 |     87.833578 | CNZdenek                                                                                                                                                           |
| 140 |     158.98599 |    235.238931 | Jon Hill                                                                                                                                                           |
| 141 |      72.27233 |     49.949616 | Gabriela Palomo-Munoz                                                                                                                                              |
| 142 |     725.59890 |     95.366192 | Tasman Dixon                                                                                                                                                       |
| 143 |     711.24132 |     65.250038 | Ferran Sayol                                                                                                                                                       |
| 144 |    1015.23786 |    657.576869 | NA                                                                                                                                                                 |
| 145 |     831.31361 |    361.368074 | T. Michael Keesey                                                                                                                                                  |
| 146 |     165.29501 |    259.243743 | Yan Wong                                                                                                                                                           |
| 147 |     860.29289 |    712.742234 | Iain Reid                                                                                                                                                          |
| 148 |    1007.28003 |    622.079008 | Markus A. Grohme                                                                                                                                                   |
| 149 |      84.59407 |    607.424002 | M Kolmann                                                                                                                                                          |
| 150 |     993.21216 |    462.674579 | Ferran Sayol                                                                                                                                                       |
| 151 |     956.86680 |    122.553381 | Conty                                                                                                                                                              |
| 152 |     998.51440 |    205.607498 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                      |
| 153 |     993.18121 |    745.044878 | Michael Scroggie                                                                                                                                                   |
| 154 |     979.60734 |    601.145628 | Margot Michaud                                                                                                                                                     |
| 155 |     740.05380 |    796.274129 | Scott Hartman                                                                                                                                                      |
| 156 |     287.21869 |     76.475358 | Ignacio Contreras                                                                                                                                                  |
| 157 |     436.29642 |    100.095908 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 158 |     219.68617 |    462.195287 | xgirouxb                                                                                                                                                           |
| 159 |     679.42551 |    640.365854 | Gabriela Palomo-Munoz                                                                                                                                              |
| 160 |     410.54268 |    140.444329 | Steven Traver                                                                                                                                                      |
| 161 |     758.14632 |     90.568878 | Scott Hartman                                                                                                                                                      |
| 162 |     185.08791 |    265.577699 | Steven Traver                                                                                                                                                      |
| 163 |     409.46128 |    487.750203 | NA                                                                                                                                                                 |
| 164 |     901.23219 |    382.610990 | Matt Martyniuk                                                                                                                                                     |
| 165 |     866.28174 |    648.558025 | Gareth Monger                                                                                                                                                      |
| 166 |     293.93599 |    573.522924 | Jagged Fang Designs                                                                                                                                                |
| 167 |      95.67675 |    677.989964 | Birgit Lang                                                                                                                                                        |
| 168 |     874.24357 |    173.604581 | T. Michael Keesey                                                                                                                                                  |
| 169 |     554.56652 |    380.983179 | Collin Gross                                                                                                                                                       |
| 170 |     589.49893 |    128.832319 | Emily Willoughby                                                                                                                                                   |
| 171 |      23.83192 |    493.373775 | Alex Slavenko                                                                                                                                                      |
| 172 |     752.70516 |    258.583757 | Zimices                                                                                                                                                            |
| 173 |     554.03548 |    527.955309 | Tracy A. Heath                                                                                                                                                     |
| 174 |     973.92881 |     22.137127 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                     |
| 175 |     682.75491 |    262.807387 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                           |
| 176 |     922.30902 |    311.370365 | Iain Reid                                                                                                                                                          |
| 177 |     858.86281 |    738.996465 | Birgit Lang                                                                                                                                                        |
| 178 |     700.71944 |    100.322506 | Birgit Lang                                                                                                                                                        |
| 179 |     564.67825 |    589.375090 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                             |
| 180 |     983.24345 |    778.353880 | Steven Traver                                                                                                                                                      |
| 181 |     650.90800 |    280.397257 | Jon Hill                                                                                                                                                           |
| 182 |     615.93703 |    294.923208 | T. Michael Keesey                                                                                                                                                  |
| 183 |    1004.72791 |     20.405575 | Gabriela Palomo-Munoz                                                                                                                                              |
| 184 |     549.92501 |    655.702932 | Robert Gay, modifed from Olegivvit                                                                                                                                 |
| 185 |     377.70591 |    485.247144 | C. Camilo Julián-Caballero                                                                                                                                         |
| 186 |     249.84462 |    179.847240 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 187 |     409.77670 |     48.446383 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 188 |      21.15435 |    404.538645 | Matt Crook                                                                                                                                                         |
| 189 |     840.17715 |     77.797124 | Auckland Museum                                                                                                                                                    |
| 190 |     667.52884 |    466.098321 | Ignacio Contreras                                                                                                                                                  |
| 191 |     533.05981 |    750.317030 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 192 |      68.24154 |    158.425674 | Collin Gross                                                                                                                                                       |
| 193 |     634.51698 |    559.906023 | Chris huh                                                                                                                                                          |
| 194 |     138.33171 |    648.168463 | Steven Coombs                                                                                                                                                      |
| 195 |     238.83044 |     11.292086 | Mathew Wedel                                                                                                                                                       |
| 196 |     497.16099 |    239.511925 | Gareth Monger                                                                                                                                                      |
| 197 |     892.87757 |    217.672077 | Scott Reid                                                                                                                                                         |
| 198 |     161.33815 |    204.561129 | Steven Traver                                                                                                                                                      |
| 199 |     152.18162 |    272.690669 | Margot Michaud                                                                                                                                                     |
| 200 |     228.06314 |    439.939629 | NA                                                                                                                                                                 |
| 201 |     666.96163 |    607.411962 | Margot Michaud                                                                                                                                                     |
| 202 |      91.95233 |    455.957155 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                        |
| 203 |     985.14149 |    565.077133 | Tasman Dixon                                                                                                                                                       |
| 204 |     612.01860 |    745.769777 | Matt Crook                                                                                                                                                         |
| 205 |     890.38697 |    670.667761 | Margot Michaud                                                                                                                                                     |
| 206 |     765.77863 |    647.232829 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                            |
| 207 |      14.77909 |    556.142139 | Felix Vaux                                                                                                                                                         |
| 208 |      13.25041 |    360.419718 | Maxime Dahirel                                                                                                                                                     |
| 209 |     633.77860 |    758.553771 | Ferran Sayol                                                                                                                                                       |
| 210 |     499.20004 |    347.481193 | Matt Crook                                                                                                                                                         |
| 211 |     390.57881 |    214.733982 | Chris huh                                                                                                                                                          |
| 212 |     612.92312 |    656.956248 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 213 |     989.10380 |    585.427553 | Chris huh                                                                                                                                                          |
| 214 |     618.72781 |    551.688786 | Chris huh                                                                                                                                                          |
| 215 |     990.93386 |    126.481347 | Margot Michaud                                                                                                                                                     |
| 216 |     829.24892 |     50.542884 | Emily Willoughby                                                                                                                                                   |
| 217 |     170.75974 |    290.453634 | Markus A. Grohme                                                                                                                                                   |
| 218 |      72.48365 |    214.260226 | Tasman Dixon                                                                                                                                                       |
| 219 |     240.09685 |    663.890459 | Sharon Wegner-Larsen                                                                                                                                               |
| 220 |     507.27720 |    481.651412 | Ferran Sayol                                                                                                                                                       |
| 221 |     229.71223 |    473.806047 | Maija Karala                                                                                                                                                       |
| 222 |     947.30430 |    715.312016 | Ignacio Contreras                                                                                                                                                  |
| 223 |      68.38145 |    241.937995 | Michele M Tobias                                                                                                                                                   |
| 224 |     106.36564 |    618.898846 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                   |
| 225 |     256.12079 |    485.627862 | Margot Michaud                                                                                                                                                     |
| 226 |     702.36042 |    367.646288 | CNZdenek                                                                                                                                                           |
| 227 |     858.75772 |    672.738500 | Jennifer Trimble                                                                                                                                                   |
| 228 |     811.20980 |    674.234697 | Gareth Monger                                                                                                                                                      |
| 229 |     106.79605 |     40.147247 | Lily Hughes                                                                                                                                                        |
| 230 |     998.79318 |    154.877205 | Matt Crook                                                                                                                                                         |
| 231 |     391.85336 |    697.083661 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                     |
| 232 |      84.63529 |     18.698656 | Tauana J. Cunha                                                                                                                                                    |
| 233 |      42.62404 |    161.159097 | Geoff Shaw                                                                                                                                                         |
| 234 |     722.76313 |    692.612950 | C. Camilo Julián-Caballero                                                                                                                                         |
| 235 |    1004.67779 |    690.920422 | Chris huh                                                                                                                                                          |
| 236 |     193.61647 |    738.588980 | Zimices                                                                                                                                                            |
| 237 |     928.09962 |    781.996655 | Ingo Braasch                                                                                                                                                       |
| 238 |     399.85435 |    204.453692 | Steven Coombs                                                                                                                                                      |
| 239 |     200.79763 |    168.029132 | Matt Crook                                                                                                                                                         |
| 240 |     723.02745 |    207.386696 | Caleb M. Brown                                                                                                                                                     |
| 241 |     272.69055 |    675.657996 | Ferran Sayol                                                                                                                                                       |
| 242 |     508.62038 |    629.118941 | Scott Hartman                                                                                                                                                      |
| 243 |     202.12513 |    386.178634 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                    |
| 244 |      18.49734 |    328.362610 | Michael Scroggie                                                                                                                                                   |
| 245 |     871.25314 |     72.867769 | Gareth Monger                                                                                                                                                      |
| 246 |     385.60774 |    768.666009 | Scott Hartman                                                                                                                                                      |
| 247 |     117.55146 |     77.094887 | Mathieu Basille                                                                                                                                                    |
| 248 |      98.85550 |    129.963107 | Ferran Sayol                                                                                                                                                       |
| 249 |      96.42595 |    147.827989 | Zimices                                                                                                                                                            |
| 250 |     157.38004 |    178.372634 | terngirl                                                                                                                                                           |
| 251 |     263.72386 |    376.512670 | Gareth Monger                                                                                                                                                      |
| 252 |     611.92866 |    520.974349 | Smokeybjb (modified by Mike Keesey)                                                                                                                                |
| 253 |     513.48547 |    290.266985 | Matt Crook                                                                                                                                                         |
| 254 |     580.46743 |    742.911965 | Tasman Dixon                                                                                                                                                       |
| 255 |     114.26150 |    244.068999 | Kanchi Nanjo                                                                                                                                                       |
| 256 |     201.12921 |      8.087208 | Christoph Schomburg                                                                                                                                                |
| 257 |      76.29536 |    431.309106 | Gareth Monger                                                                                                                                                      |
| 258 |     957.24401 |    473.377271 | Jagged Fang Designs                                                                                                                                                |
| 259 |      58.69666 |    558.535264 | Michael Scroggie                                                                                                                                                   |
| 260 |     605.67459 |    220.719077 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                 |
| 261 |      24.50921 |    122.148493 | V. Deepak                                                                                                                                                          |
| 262 |    1010.65347 |    358.996726 | Felix Vaux                                                                                                                                                         |
| 263 |     687.93748 |    127.478746 | Birgit Lang                                                                                                                                                        |
| 264 |     934.15658 |    664.328922 | Gabriela Palomo-Munoz                                                                                                                                              |
| 265 |      19.78682 |    710.987620 | NA                                                                                                                                                                 |
| 266 |     530.54813 |    548.451562 | Kamil S. Jaron                                                                                                                                                     |
| 267 |     670.47070 |    154.416180 | Matt Dempsey                                                                                                                                                       |
| 268 |     213.01401 |    586.148422 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                      |
| 269 |     944.34230 |    147.921249 | Scott Hartman                                                                                                                                                      |
| 270 |     572.97909 |    657.408517 | S.Martini                                                                                                                                                          |
| 271 |     572.03805 |    306.425314 | Walter Vladimir                                                                                                                                                    |
| 272 |     977.66879 |    589.517674 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                 |
| 273 |     995.83365 |    406.162105 | T. Michael Keesey                                                                                                                                                  |
| 274 |     446.76131 |    359.424321 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                           |
| 275 |     708.22358 |    356.366653 | NA                                                                                                                                                                 |
| 276 |      35.94948 |    614.280789 | Chris huh                                                                                                                                                          |
| 277 |     196.49208 |    719.502496 | Tambja (vectorized by T. Michael Keesey)                                                                                                                           |
| 278 |     834.97572 |    167.721398 | Carlos Cano-Barbacil                                                                                                                                               |
| 279 |     433.91981 |     16.333372 | Dean Schnabel                                                                                                                                                      |
| 280 |     193.37489 |    661.213691 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
| 281 |     115.27016 |    760.145056 | Jack Mayer Wood                                                                                                                                                    |
| 282 |     809.63216 |    104.932938 | Anthony Caravaggi                                                                                                                                                  |
| 283 |     456.22664 |    328.860678 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                        |
| 284 |     507.21912 |    513.593114 | Zimices                                                                                                                                                            |
| 285 |     493.55320 |    649.555202 | Chuanixn Yu                                                                                                                                                        |
| 286 |     361.73787 |    432.908565 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                |
| 287 |     273.50197 |      3.780041 | Scott Hartman                                                                                                                                                      |
| 288 |     959.63123 |     14.318771 | Scott Hartman                                                                                                                                                      |
| 289 |     230.86059 |    543.144359 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 290 |     989.55540 |    521.416927 | Margot Michaud                                                                                                                                                     |
| 291 |     905.75741 |    760.388648 | Markus A. Grohme                                                                                                                                                   |
| 292 |     353.40031 |    145.139212 | Smokeybjb                                                                                                                                                          |
| 293 |     936.57665 |    763.372258 | Manabu Bessho-Uehara                                                                                                                                               |
| 294 |     444.09682 |    783.444100 | Beth Reinke                                                                                                                                                        |
| 295 |    1006.27796 |    262.121547 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                         |
| 296 |      26.18003 |    241.556756 | Roger Witter, vectorized by Zimices                                                                                                                                |
| 297 |     864.41451 |    309.354981 | NA                                                                                                                                                                 |
| 298 |     810.43709 |    650.307417 | NA                                                                                                                                                                 |
| 299 |     650.80369 |    189.589091 | Jagged Fang Designs                                                                                                                                                |
| 300 |      23.31665 |    145.081698 | Steven Coombs                                                                                                                                                      |
| 301 |     409.34868 |    472.160445 | Andrew Farke and Joseph Sertich                                                                                                                                    |
| 302 |     533.54969 |    235.347576 | Matt Crook                                                                                                                                                         |
| 303 |     526.08506 |    267.051618 | Scott Hartman                                                                                                                                                      |
| 304 |      78.72200 |    196.842977 | Kamil S. Jaron                                                                                                                                                     |
| 305 |      58.80739 |    426.383529 | Agnello Picorelli                                                                                                                                                  |
| 306 |     345.08165 |    754.491147 | Tyler McCraney                                                                                                                                                     |
| 307 |     474.41770 |    160.769608 | L. Shyamal                                                                                                                                                         |
| 308 |     889.81291 |    246.295126 | Francesca Belem Lopes Palmeira                                                                                                                                     |
| 309 |     622.16462 |    597.447975 | Maija Karala                                                                                                                                                       |
| 310 |     665.02308 |    505.905439 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 311 |     251.94979 |    100.192206 | NA                                                                                                                                                                 |
| 312 |     378.66136 |    275.459783 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                 |
| 313 |     536.85381 |     85.497517 | Ferran Sayol                                                                                                                                                       |
| 314 |     484.72398 |     56.289382 | Matt Crook                                                                                                                                                         |
| 315 |    1002.63235 |    230.362775 | Matt Crook                                                                                                                                                         |
| 316 |     577.78774 |    795.225573 | Zachary Quigley                                                                                                                                                    |
| 317 |     838.98374 |    319.120017 | Sarah Werning                                                                                                                                                      |
| 318 |     104.11596 |    768.877334 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                              |
| 319 |     921.34952 |    647.932963 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                      |
| 320 |     679.94548 |    495.013454 | Rebecca Groom                                                                                                                                                      |
| 321 |     644.98713 |    163.547512 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                      |
| 322 |      56.79800 |    603.029202 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 323 |     153.04148 |    676.708869 | C. Camilo Julián-Caballero                                                                                                                                         |
| 324 |     429.60558 |    181.294011 | Roberto Díaz Sibaja                                                                                                                                                |
| 325 |     231.02924 |    558.878712 | Jagged Fang Designs                                                                                                                                                |
| 326 |     680.97100 |    591.726614 | Gareth Monger                                                                                                                                                      |
| 327 |      68.57959 |    472.786178 | T. Michael Keesey                                                                                                                                                  |
| 328 |     914.00324 |    114.343901 | Scott Hartman                                                                                                                                                      |
| 329 |    1009.06695 |    604.503736 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                               |
| 330 |     138.65532 |    481.237388 | Chuanixn Yu                                                                                                                                                        |
| 331 |     602.73587 |     26.329956 | Cesar Julian                                                                                                                                                       |
| 332 |      24.46193 |     63.719488 | Margot Michaud                                                                                                                                                     |
| 333 |     264.54418 |     83.049799 | Ferran Sayol                                                                                                                                                       |
| 334 |      67.62529 |     21.138251 | Melissa Broussard                                                                                                                                                  |
| 335 |     427.17508 |    335.148314 | NA                                                                                                                                                                 |
| 336 |      58.13780 |    287.542776 | Ferran Sayol                                                                                                                                                       |
| 337 |     814.85569 |    753.648861 | Gareth Monger                                                                                                                                                      |
| 338 |     692.90318 |    205.097359 | Margot Michaud                                                                                                                                                     |
| 339 |     410.76760 |    376.274467 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                     |
| 340 |     998.91333 |    495.164413 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                              |
| 341 |     629.51241 |     14.612279 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 342 |     993.95293 |     96.976425 | Natasha Vitek                                                                                                                                                      |
| 343 |     526.95743 |    576.255039 | NASA                                                                                                                                                               |
| 344 |     712.25964 |     10.292088 | Steven Traver                                                                                                                                                      |
| 345 |     408.51065 |    310.439262 | Melissa Broussard                                                                                                                                                  |
| 346 |     795.38041 |    683.480733 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                               |
| 347 |     771.85717 |    274.861332 | Jagged Fang Designs                                                                                                                                                |
| 348 |    1006.00504 |    670.002495 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 349 |     934.87506 |    369.654771 | Juan Carlos Jerí                                                                                                                                                   |
| 350 |     877.94537 |    192.450049 | Christoph Schomburg                                                                                                                                                |
| 351 |     201.98660 |     42.016137 | NA                                                                                                                                                                 |
| 352 |     155.45802 |    764.327525 | Michael Scroggie                                                                                                                                                   |
| 353 |     336.85265 |     44.389953 | NA                                                                                                                                                                 |
| 354 |     680.82192 |    288.784542 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                        |
| 355 |     402.56954 |    714.833614 | NA                                                                                                                                                                 |
| 356 |     497.22507 |     12.108947 | Tracy A. Heath                                                                                                                                                     |
| 357 |     401.84030 |    230.407435 | Jagged Fang Designs                                                                                                                                                |
| 358 |    1005.53966 |    315.108242 | Gareth Monger                                                                                                                                                      |
| 359 |     667.03307 |     92.859332 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                    |
| 360 |      16.94805 |    605.825322 | Gareth Monger                                                                                                                                                      |
| 361 |     401.87281 |     26.973196 | NA                                                                                                                                                                 |
| 362 |     374.99527 |    557.025877 | Markus A. Grohme                                                                                                                                                   |
| 363 |     750.23690 |    381.425290 | Maija Karala                                                                                                                                                       |
| 364 |     641.30293 |    100.308323 | Nobu Tamura                                                                                                                                                        |
| 365 |     743.08056 |    353.548629 | Steven Traver                                                                                                                                                      |
| 366 |     656.13808 |    136.249562 | Christoph Schomburg                                                                                                                                                |
| 367 |     263.52088 |    695.556469 | NA                                                                                                                                                                 |
| 368 |     593.29151 |    274.852778 | Zimices                                                                                                                                                            |
| 369 |     141.23096 |    249.988981 | Mathew Wedel                                                                                                                                                       |
| 370 |     746.84821 |    185.607820 | Carlos Cano-Barbacil                                                                                                                                               |
| 371 |     283.35898 |    538.598875 | Andrew A. Farke                                                                                                                                                    |
| 372 |     266.45775 |    647.723811 | Jagged Fang Designs                                                                                                                                                |
| 373 |    1003.54637 |    713.123127 | Zimices                                                                                                                                                            |
| 374 |     201.65138 |    750.882214 | Michael Scroggie                                                                                                                                                   |
| 375 |     695.41613 |    475.746162 | Karla Martinez                                                                                                                                                     |
| 376 |     424.93247 |    664.082609 | Gareth Monger                                                                                                                                                      |
| 377 |     985.88232 |    763.359328 | Zimices                                                                                                                                                            |
| 378 |     195.32741 |    247.894110 | NA                                                                                                                                                                 |
| 379 |     353.24084 |    449.398654 | Amanda Katzer                                                                                                                                                      |
| 380 |     511.38219 |    362.849904 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 381 |      50.45185 |    235.775684 | Ferran Sayol                                                                                                                                                       |
| 382 |     683.25453 |    709.778915 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 383 |     561.16049 |    228.306114 | Matt Dempsey                                                                                                                                                       |
| 384 |     387.13816 |    506.309166 | TaraTaylorDesign                                                                                                                                                   |
| 385 |      31.19605 |    289.209682 | Lukasiniho                                                                                                                                                         |
| 386 |      14.62663 |    648.273552 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                        |
| 387 |     625.14931 |    280.568816 | Christoph Schomburg                                                                                                                                                |
| 388 |     299.43951 |     87.756820 | Darius Nau                                                                                                                                                         |
| 389 |     996.34523 |    791.750973 | James Neenan                                                                                                                                                       |
| 390 |     728.22475 |    138.070416 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                     |
| 391 |     476.52400 |    622.767498 | Jagged Fang Designs                                                                                                                                                |
| 392 |     137.50405 |    163.856949 | Mathew Wedel                                                                                                                                                       |
| 393 |      77.31371 |    310.983243 | Zimices                                                                                                                                                            |
| 394 |    1004.58715 |    203.292360 | Alex Slavenko                                                                                                                                                      |
| 395 |     428.47135 |     91.620865 | (unknown)                                                                                                                                                          |
| 396 |     900.06408 |    720.502034 | Jagged Fang Designs                                                                                                                                                |
| 397 |     821.45907 |    740.599797 | Scott Hartman                                                                                                                                                      |
| 398 |     855.05051 |    145.209216 | T. Michael Keesey                                                                                                                                                  |
| 399 |     651.11443 |    573.653453 | Zimices                                                                                                                                                            |
| 400 |     469.99567 |    403.900469 | NA                                                                                                                                                                 |
| 401 |     404.86158 |    601.325705 | Matt Crook                                                                                                                                                         |
| 402 |     518.82695 |    404.939352 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                        |
| 403 |      78.64908 |    339.745212 | Benjamin Monod-Broca                                                                                                                                               |
| 404 |     429.85176 |    299.362696 | Zimices                                                                                                                                                            |
| 405 |     981.78403 |    362.211051 | Jagged Fang Designs                                                                                                                                                |
| 406 |     601.47448 |    193.179048 | Milton Tan                                                                                                                                                         |
| 407 |      28.87465 |     75.620245 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 408 |     900.87372 |    790.115960 | Maxime Dahirel                                                                                                                                                     |
| 409 |      28.18860 |    585.989754 | Mathew Wedel                                                                                                                                                       |
| 410 |     865.82166 |    757.590823 | Caleb Brown                                                                                                                                                        |
| 411 |     779.74859 |    351.833682 | Zimices                                                                                                                                                            |
| 412 |     337.13462 |    764.700020 | Margot Michaud                                                                                                                                                     |
| 413 |     371.74152 |    151.319760 | Jagged Fang Designs                                                                                                                                                |
| 414 |     943.45623 |    789.408302 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                      |
| 415 |      87.55192 |    348.946601 | Scott Hartman                                                                                                                                                      |
| 416 |     868.77786 |    210.781107 | Gareth Monger                                                                                                                                                      |
| 417 |     956.50080 |    683.054707 | Sarah Werning                                                                                                                                                      |
| 418 |     414.30178 |    748.624650 | Matt Crook                                                                                                                                                         |
| 419 |     405.45836 |     63.099895 | Scott Hartman                                                                                                                                                      |
| 420 |     146.95769 |    187.250226 | Jagged Fang Designs                                                                                                                                                |
| 421 |     672.81901 |    108.193371 | Scott Hartman                                                                                                                                                      |
| 422 |     279.34888 |    251.512139 | Melissa Broussard                                                                                                                                                  |
| 423 |     127.54637 |    266.672425 | T. Michael Keesey                                                                                                                                                  |
| 424 |     950.36939 |    317.940440 | Julio Garza                                                                                                                                                        |
| 425 |     527.64682 |    645.532509 | Anthony Caravaggi                                                                                                                                                  |
| 426 |     862.40223 |    127.580223 | NA                                                                                                                                                                 |
| 427 |     718.31766 |    413.365625 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                          |
| 428 |     749.91008 |      5.815519 | Margot Michaud                                                                                                                                                     |
| 429 |     447.33594 |    675.541663 | Dexter R. Mardis                                                                                                                                                   |
| 430 |     554.50978 |    678.953865 | Zimices                                                                                                                                                            |
| 431 |     180.01504 |    342.369281 | Ferran Sayol                                                                                                                                                       |
| 432 |     521.90427 |    385.244721 | Scott Hartman                                                                                                                                                      |
| 433 |     708.24665 |    160.537239 | Shyamal                                                                                                                                                            |
| 434 |     166.50037 |    433.909579 | Gareth Monger                                                                                                                                                      |
| 435 |     634.57260 |    639.464865 | Gareth Monger                                                                                                                                                      |
| 436 |     382.54673 |    378.073174 | Jack Mayer Wood                                                                                                                                                    |
| 437 |      76.79920 |    619.906674 | Agnello Picorelli                                                                                                                                                  |
| 438 |     713.65551 |    708.259649 | Chris huh                                                                                                                                                          |
| 439 |    1000.89457 |    183.205532 | Margot Michaud                                                                                                                                                     |
| 440 |     733.02846 |     42.814382 | Gareth Monger                                                                                                                                                      |
| 441 |     854.91976 |    694.263366 | Gareth Monger                                                                                                                                                      |
| 442 |     631.45290 |    617.026966 | Chris huh                                                                                                                                                          |
| 443 |      53.51577 |    483.244706 | Falconaumanni and T. Michael Keesey                                                                                                                                |
| 444 |     780.34664 |      6.762002 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                      |
| 445 |     718.41409 |    576.216500 | NA                                                                                                                                                                 |
| 446 |      95.59709 |    478.837604 | Charles R. Knight, vectorized by Zimices                                                                                                                           |
| 447 |     203.88913 |    469.982634 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                   |
| 448 |     956.56030 |    555.962645 | Frank Förster                                                                                                                                                      |
| 449 |     655.90342 |    243.793146 | Roberto Díaz Sibaja                                                                                                                                                |
| 450 |     517.62547 |    796.907648 | Smokeybjb                                                                                                                                                          |
| 451 |     415.11000 |    356.159024 | Scott Hartman                                                                                                                                                      |
| 452 |     332.13162 |     32.801525 | Chris Jennings (Risiatto)                                                                                                                                          |
| 453 |     253.23842 |     68.944635 | C. Abraczinskas                                                                                                                                                    |
| 454 |     728.78792 |    276.297665 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                    |
| 455 |     580.27692 |    787.967624 | Armin Reindl                                                                                                                                                       |
| 456 |     492.48207 |    161.292665 | T. Michael Keesey                                                                                                                                                  |
| 457 |    1006.75975 |    436.068790 | Jagged Fang Designs                                                                                                                                                |
| 458 |      11.50953 |    742.714150 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                  |
| 459 |     432.75907 |    194.088643 | Markus A. Grohme                                                                                                                                                   |
| 460 |     556.26133 |    179.533143 | Roberto Díaz Sibaja                                                                                                                                                |
| 461 |     185.95729 |    373.211851 | Scott Hartman                                                                                                                                                      |
| 462 |     161.02530 |    777.738470 | Chris huh                                                                                                                                                          |
| 463 |     589.38068 |    544.970222 | Scott Hartman                                                                                                                                                      |
| 464 |     588.48249 |    390.637407 | Markus A. Grohme                                                                                                                                                   |
| 465 |     235.05098 |    373.601793 | Tasman Dixon                                                                                                                                                       |
| 466 |     980.69565 |    148.533287 | Jagged Fang Designs                                                                                                                                                |
| 467 |     927.92341 |    215.025313 | Chuanixn Yu                                                                                                                                                        |
| 468 |     302.33718 |    791.962007 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 469 |     711.64132 |    652.720513 | C. Camilo Julián-Caballero                                                                                                                                         |
| 470 |     730.24978 |    786.327075 | Alex Slavenko                                                                                                                                                      |
| 471 |     670.25219 |    671.447019 | Steven Traver                                                                                                                                                      |
| 472 |     915.27415 |    318.290137 | NA                                                                                                                                                                 |
| 473 |     383.26815 |    340.359405 | Ignacio Contreras                                                                                                                                                  |
| 474 |     379.46184 |    111.852853 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 475 |     761.53813 |     56.238875 | Chris huh                                                                                                                                                          |
| 476 |     223.08532 |    284.716308 | NA                                                                                                                                                                 |
| 477 |     747.35989 |    245.131447 | Markus A. Grohme                                                                                                                                                   |
| 478 |     508.83197 |    789.722994 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 479 |     459.66692 |    388.575256 | Harold N Eyster                                                                                                                                                    |
| 480 |     867.11460 |    355.199767 | NA                                                                                                                                                                 |
| 481 |      85.31248 |    528.730436 | Steven Haddock • Jellywatch.org                                                                                                                                    |
| 482 |     799.21522 |     67.669654 | Matt Crook                                                                                                                                                         |
| 483 |     189.61259 |    276.023139 | Margot Michaud                                                                                                                                                     |
| 484 |     502.72594 |    500.053015 | Scott Hartman                                                                                                                                                      |
| 485 |     599.68514 |    154.072098 | FunkMonk                                                                                                                                                           |
| 486 |      70.06520 |     80.105688 | Margot Michaud                                                                                                                                                     |
| 487 |     700.19708 |    790.076695 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 488 |     547.32658 |    567.585381 | Andrew A. Farke                                                                                                                                                    |
| 489 |     114.90904 |    690.183707 | Markus A. Grohme                                                                                                                                                   |
| 490 |     368.40634 |    599.947502 | Scott Hartman                                                                                                                                                      |
| 491 |     930.27672 |    321.592743 | T. K. Robinson                                                                                                                                                     |
| 492 |     386.39491 |    527.564438 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                 |
| 493 |     959.92517 |    772.894850 | Alexandre Vong                                                                                                                                                     |
| 494 |     898.02728 |    710.760378 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                               |
| 495 |     204.57852 |     94.731374 | Smokeybjb                                                                                                                                                          |
| 496 |     625.95271 |     32.156493 | NA                                                                                                                                                                 |
| 497 |     646.52181 |    795.275094 | Ignacio Contreras                                                                                                                                                  |
| 498 |     608.56326 |    616.546006 | Jaime Headden                                                                                                                                                      |
| 499 |     129.57829 |    121.112861 | Gareth Monger                                                                                                                                                      |
| 500 |     391.32744 |    749.157170 | Xavier Giroux-Bougard                                                                                                                                              |
| 501 |     475.16222 |    219.154479 | T. Michael Keesey                                                                                                                                                  |
| 502 |     637.80331 |    734.061871 | Gareth Monger                                                                                                                                                      |
| 503 |     106.15386 |    316.979242 | Gareth Monger                                                                                                                                                      |
| 504 |     555.75225 |    140.227516 | Darius Nau                                                                                                                                                         |
| 505 |     573.37343 |    759.069675 | Jagged Fang Designs                                                                                                                                                |
| 506 |     718.61525 |    172.465881 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                   |
| 507 |     637.62938 |    609.167623 | Scott Reid                                                                                                                                                         |

    #> Your tweet has been posted!
