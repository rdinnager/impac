
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

Andrew A. Farke, Birgit Lang, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Roberto Díaz Sibaja, Emily Willoughby, Gabriela Palomo-Munoz,
Zimices, Scott Hartman, Mathieu Pélissié, Margot Michaud, Agnello
Picorelli, Steven Traver, Andy Wilson, Matt Crook, Mathilde Cordellier,
Joedison Rocha, Mali’o Kodis, photograph by Bruno Vellutini, RS, Oscar
Sanisidro, Chuanixn Yu, Mathieu Basille, Robert Hering, Gareth Monger,
Alexandre Vong, Michael Day, Sergio A. Muñoz-Gómez, Matus Valach,
CNZdenek, Chris huh, Ferran Sayol, L.M. Davalos, Timothy Knepp
(vectorized by T. Michael Keesey), Jakovche, Michelle Site, Juan Carlos
Jerí, Beth Reinke, Jagged Fang Designs, Dean Schnabel, Walter Vladimir,
Tasman Dixon, Smokeybjb, Lee Harding (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Nobu Tamura (vectorized by T.
Michael Keesey), Johan Lindgren, Michael W. Caldwell, Takuya Konishi,
Luis M. Chiappe, S.Martini, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Tyler
McCraney, Brad McFeeters (vectorized by T. Michael Keesey), Jose Carlos
Arenas-Monroy, Stacy Spensley (Modified), Ignacio Contreras, Jack Mayer
Wood, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Gabriele Midolo, Tony Ayling
(vectorized by Milton Tan), Markus A. Grohme, T. Michael Keesey, L.
Shyamal, Ghedoghedo (vectorized by T. Michael Keesey), Carlos
Cano-Barbacil, Kamil S. Jaron, Sean McCann, Steven Coombs, Mathew Wedel,
Collin Gross, Anthony Caravaggi, Javiera Constanzo, Evan-Amos
(vectorized by T. Michael Keesey), Alex Slavenko, Noah Schlottman, photo
from Casey Dunn, Andrés Sánchez, C. Camilo Julián-Caballero,
Apokryltaros (vectorized by T. Michael Keesey), George Edward Lodge,
Andrew A. Farke, modified from original by H. Milne Edwards, Blair
Perry, Harold N Eyster, Hans Hillewaert, Anilocra (vectorization by Yan
Wong), T. Michael Keesey (after A. Y. Ivantsov), M Kolmann, Don
Armstrong, Pollyanna von Knorring and T. Michael Keesey, Ray Simpson
(vectorized by T. Michael Keesey), Tauana J. Cunha, Jerry Oldenettel
(vectorized by T. Michael Keesey), Xavier Giroux-Bougard, Joshua Fowler,
Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Dmitry Bogdanov, Paul O. Lewis, Jonathan Wells, Kanchi
Nanjo, Roberto Diaz Sibaja, based on Domser, Noah Schlottman, Jaime
Headden, Richard Ruggiero, vectorized by Zimices, Leon P. A. M.
Claessens, Patrick M. O’Connor, David M. Unwin, Julio Garza, James R.
Spotila and Ray Chatterji, White Wolf, Jon M Laurent, Henry Lydecker,
Cesar Julian, DW Bapst, modified from Ishitani et al. 2016, Darren
Naish, Nemo, and T. Michael Keesey, wsnaccad, Maxime Dahirel, Kai R.
Caspar, Gustav Mützel, Birgit Lang; original image by virmisco.org,
Sharon Wegner-Larsen, Milton Tan, Nobu Tamura, Sarah Werning, Enoch
Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, T. Michael Keesey (from a photo by Maximilian Paradiz),
Ville Koistinen (vectorized by T. Michael Keesey), Eduard Solà Vázquez,
vectorised by Yan Wong, Caleb M. Brown, Maha Ghazal, Maija Karala, Noah
Schlottman, photo by Casey Dunn, Geoff Shaw, Terpsichores, Yan Wong,
Marmelad, Eduard Solà (vectorized by T. Michael Keesey), Joanna Wolfe,
xgirouxb, Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael
Keesey), Ghedo (vectorized by T. Michael Keesey), Original photo by
Andrew Murray, vectorized by Roberto Díaz Sibaja, Yan Wong from
wikipedia drawing (PD: Pearson Scott Foresman), Jon Hill, FunkMonk, T.
Tischler, Neil Kelley, Elisabeth Östman, Christian A. Masnaghetti, Mykle
Hoban, Sarah Alewijnse, Chris Jennings (vectorized by A. Verrière),
Renato de Carvalho Ferreira, Obsidian Soul (vectorized by T. Michael
Keesey), Shyamal, Christoph Schomburg, Tony Ayling (vectorized by T.
Michael Keesey), Myriam\_Ramirez,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Iain Reid, Steven Blackwood, Felix
Vaux, Pearson Scott Foresman (vectorized by T. Michael Keesey), Conty
(vectorized by T. Michael Keesey), H. Filhol (vectorized by T. Michael
Keesey), Martin R. Smith, after Skovsted et al 2015, Robert Bruce
Horsfall, vectorized by Zimices, T. Michael Keesey (after Monika
Betley), Dann Pigdon, Smokeybjb (modified by Mike Keesey), Robbie N.
Cada (vectorized by T. Michael Keesey), Zachary Quigley, Mali’o Kodis,
photograph by P. Funch and R.M. Kristensen, M. Antonio Todaro, Tobias
Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael
Keesey), Jaime Headden, modified by T. Michael Keesey, Aviceda (photo) &
T. Michael Keesey, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Stuart Humphries, T. Michael Keesey
(vectorization) and Larry Loos (photography), Brian Swartz (vectorized
by T. Michael Keesey), Scott Hartman (modified by T. Michael Keesey),
Didier Descouens (vectorized by T. Michael Keesey), Mattia Menchetti,
Bob Goldstein, Vectorization:Jake Warner, Michael Ströck (vectorized by
T. Michael Keesey), Catherine Yasuda

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    167.774763 |    655.826854 | Andrew A. Farke                                                                                                                                                       |
|   2 |    425.622342 |    447.506366 | Birgit Lang                                                                                                                                                           |
|   3 |    416.880669 |    232.143795 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|   4 |    829.825354 |    264.527098 | Roberto Díaz Sibaja                                                                                                                                                   |
|   5 |    584.808087 |    243.912911 | Emily Willoughby                                                                                                                                                      |
|   6 |    783.486120 |    478.676408 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   7 |    411.345358 |    360.913670 | Emily Willoughby                                                                                                                                                      |
|   8 |    285.276921 |    581.446682 | Zimices                                                                                                                                                               |
|   9 |    121.275382 |    566.018231 | Scott Hartman                                                                                                                                                         |
|  10 |    552.326827 |     88.609529 | Mathieu Pélissié                                                                                                                                                      |
|  11 |    663.135477 |    266.789817 | Margot Michaud                                                                                                                                                        |
|  12 |    763.818020 |     53.039433 | Agnello Picorelli                                                                                                                                                     |
|  13 |    802.120268 |    696.361425 | Steven Traver                                                                                                                                                         |
|  14 |    647.995318 |    377.813493 | Andy Wilson                                                                                                                                                           |
|  15 |     73.268385 |    103.767595 | Matt Crook                                                                                                                                                            |
|  16 |    255.646943 |    760.106471 | Scott Hartman                                                                                                                                                         |
|  17 |    185.423312 |    256.888604 | Matt Crook                                                                                                                                                            |
|  18 |    896.243338 |     75.653359 | Mathilde Cordellier                                                                                                                                                   |
|  19 |    751.756651 |    179.504206 | Joedison Rocha                                                                                                                                                        |
|  20 |    581.789180 |    654.750197 | Matt Crook                                                                                                                                                            |
|  21 |    290.779285 |    129.279783 | Matt Crook                                                                                                                                                            |
|  22 |    522.298903 |    348.924573 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
|  23 |    456.399669 |    726.974481 | RS                                                                                                                                                                    |
|  24 |    138.157294 |    380.017866 | Oscar Sanisidro                                                                                                                                                       |
|  25 |    647.931326 |    172.286202 | Chuanixn Yu                                                                                                                                                           |
|  26 |    639.142983 |    438.246775 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  27 |    942.231191 |    717.712068 | Mathieu Basille                                                                                                                                                       |
|  28 |    112.009444 |    498.084995 | Robert Hering                                                                                                                                                         |
|  29 |    301.913599 |    431.302706 | Gareth Monger                                                                                                                                                         |
|  30 |    430.598937 |    575.707644 | Alexandre Vong                                                                                                                                                        |
|  31 |    110.115537 |    738.177279 | NA                                                                                                                                                                    |
|  32 |    702.546507 |    535.930869 | Michael Day                                                                                                                                                           |
|  33 |    918.919857 |    534.018240 | Matt Crook                                                                                                                                                            |
|  34 |    966.730622 |    280.367775 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  35 |    566.075017 |    530.465346 | Matus Valach                                                                                                                                                          |
|  36 |    687.780707 |    729.898947 | CNZdenek                                                                                                                                                              |
|  37 |    406.184085 |     27.332279 | Chris huh                                                                                                                                                             |
|  38 |    330.050463 |    678.839149 | Ferran Sayol                                                                                                                                                          |
|  39 |     62.347291 |    348.162833 | L.M. Davalos                                                                                                                                                          |
|  40 |    821.072091 |    328.776348 | Zimices                                                                                                                                                               |
|  41 |    899.197498 |    411.981730 | Gareth Monger                                                                                                                                                         |
|  42 |    877.809076 |    150.265778 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
|  43 |    166.935332 |    436.424501 | Jakovche                                                                                                                                                              |
|  44 |    204.646661 |     68.622910 | Michelle Site                                                                                                                                                         |
|  45 |    787.319242 |    573.078999 | Andy Wilson                                                                                                                                                           |
|  46 |    327.240742 |    283.427220 | Zimices                                                                                                                                                               |
|  47 |    148.568461 |    156.300468 | Juan Carlos Jerí                                                                                                                                                      |
|  48 |     70.071306 |    229.510471 | Beth Reinke                                                                                                                                                           |
|  49 |    405.869022 |    692.517609 | Jagged Fang Designs                                                                                                                                                   |
|  50 |    455.426586 |     77.797758 | Scott Hartman                                                                                                                                                         |
|  51 |    884.766120 |    214.063390 | Michelle Site                                                                                                                                                         |
|  52 |    909.566191 |    633.924044 | Dean Schnabel                                                                                                                                                         |
|  53 |    947.980498 |    361.728785 | Margot Michaud                                                                                                                                                        |
|  54 |     74.170720 |     41.768165 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  55 |    510.801924 |    770.383321 | Walter Vladimir                                                                                                                                                       |
|  56 |    695.770485 |     93.096085 | Emily Willoughby                                                                                                                                                      |
|  57 |    859.474614 |    652.129012 | Jagged Fang Designs                                                                                                                                                   |
|  58 |    766.840867 |    398.069146 | Margot Michaud                                                                                                                                                        |
|  59 |    988.965540 |    572.574082 | NA                                                                                                                                                                    |
|  60 |    710.268023 |    307.089451 | Tasman Dixon                                                                                                                                                          |
|  61 |    980.407430 |    161.471042 | Andrew A. Farke                                                                                                                                                       |
|  62 |    583.348771 |     21.580336 | Chris huh                                                                                                                                                             |
|  63 |    651.542529 |    491.374932 | NA                                                                                                                                                                    |
|  64 |    478.153579 |    148.026460 | Smokeybjb                                                                                                                                                             |
|  65 |    423.815075 |    125.201385 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  66 |    642.353238 |    566.463460 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  67 |    952.088767 |    464.284410 | Jagged Fang Designs                                                                                                                                                   |
|  68 |    346.866621 |    782.648291 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  69 |    230.800334 |    350.870622 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
|  70 |    276.827804 |    518.744820 | NA                                                                                                                                                                    |
|  71 |    438.944675 |    322.065287 | Chris huh                                                                                                                                                             |
|  72 |    253.275137 |    664.665964 | S.Martini                                                                                                                                                             |
|  73 |    313.570701 |     52.898050 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  74 |    718.742300 |    772.713389 | CNZdenek                                                                                                                                                              |
|  75 |    823.287373 |    614.332649 | Chris huh                                                                                                                                                             |
|  76 |    700.282339 |    630.926132 | Jagged Fang Designs                                                                                                                                                   |
|  77 |    995.379994 |     88.518740 | Gareth Monger                                                                                                                                                         |
|  78 |     47.169064 |    619.387308 | Margot Michaud                                                                                                                                                        |
|  79 |     32.840678 |    258.492651 | NA                                                                                                                                                                    |
|  80 |    859.858058 |    583.416199 | Tyler McCraney                                                                                                                                                        |
|  81 |    731.985784 |    633.706337 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  82 |    595.703808 |    737.057635 | Mathieu Pélissié                                                                                                                                                      |
|  83 |    569.142647 |    338.473688 | Zimices                                                                                                                                                               |
|  84 |    892.540047 |    682.075530 | Ferran Sayol                                                                                                                                                          |
|  85 |     35.566161 |    702.953048 | Zimices                                                                                                                                                               |
|  86 |     30.710461 |    455.732763 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  87 |     82.645479 |    783.547384 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  88 |    171.092746 |    687.859457 | Tasman Dixon                                                                                                                                                          |
|  89 |    508.255357 |    626.675206 | NA                                                                                                                                                                    |
|  90 |    498.089511 |    670.378915 | Ferran Sayol                                                                                                                                                          |
|  91 |    668.455394 |    686.068623 | Stacy Spensley (Modified)                                                                                                                                             |
|  92 |    446.683784 |     38.737592 | Scott Hartman                                                                                                                                                         |
|  93 |    331.507906 |    225.517470 | Matt Crook                                                                                                                                                            |
|  94 |    509.617848 |    556.298223 | Ignacio Contreras                                                                                                                                                     |
|  95 |    932.136005 |    787.457019 | Jack Mayer Wood                                                                                                                                                       |
|  96 |    373.356919 |    568.341435 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  97 |    106.611443 |    198.898878 | Matt Crook                                                                                                                                                            |
|  98 |    203.222813 |    520.602782 | Gabriele Midolo                                                                                                                                                       |
|  99 |    464.071795 |    520.321806 | Scott Hartman                                                                                                                                                         |
| 100 |    279.953575 |    179.406481 | NA                                                                                                                                                                    |
| 101 |    499.780864 |    418.564872 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 102 |    402.966699 |    642.795617 | Matt Crook                                                                                                                                                            |
| 103 |    214.662491 |    182.988928 | Margot Michaud                                                                                                                                                        |
| 104 |    533.074484 |    187.242705 | Jagged Fang Designs                                                                                                                                                   |
| 105 |    351.362384 |     74.512714 | Markus A. Grohme                                                                                                                                                      |
| 106 |    918.367694 |    484.856068 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 107 |    488.938230 |    583.818753 | T. Michael Keesey                                                                                                                                                     |
| 108 |     91.399141 |     68.831618 | Tasman Dixon                                                                                                                                                          |
| 109 |    551.062137 |    741.992138 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 110 |    328.054173 |    362.910092 | Margot Michaud                                                                                                                                                        |
| 111 |    605.547399 |    736.955094 | L. Shyamal                                                                                                                                                            |
| 112 |    963.287530 |     89.412116 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 113 |    348.077116 |     89.854580 | Markus A. Grohme                                                                                                                                                      |
| 114 |    342.648832 |    545.133389 | Andrew A. Farke                                                                                                                                                       |
| 115 |    934.138295 |    661.195635 | Ferran Sayol                                                                                                                                                          |
| 116 |    945.792462 |     72.869103 | Tasman Dixon                                                                                                                                                          |
| 117 |     76.164012 |    728.802906 | NA                                                                                                                                                                    |
| 118 |    785.180990 |    558.246933 | Zimices                                                                                                                                                               |
| 119 |    706.995591 |    358.956942 | Steven Traver                                                                                                                                                         |
| 120 |    467.592796 |      8.536636 | Jagged Fang Designs                                                                                                                                                   |
| 121 |    757.529046 |    782.630928 | Zimices                                                                                                                                                               |
| 122 |    898.676441 |    542.781787 | Carlos Cano-Barbacil                                                                                                                                                  |
| 123 |    676.125711 |    415.935663 | Zimices                                                                                                                                                               |
| 124 |    689.951986 |    224.381534 | NA                                                                                                                                                                    |
| 125 |     93.742529 |    636.574046 | Kamil S. Jaron                                                                                                                                                        |
| 126 |    853.692904 |    456.817902 | Zimices                                                                                                                                                               |
| 127 |    266.656228 |    242.748635 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 128 |    904.407471 |    725.781374 | Sean McCann                                                                                                                                                           |
| 129 |    989.348941 |    642.586393 | Steven Traver                                                                                                                                                         |
| 130 |    147.040853 |     66.137680 | Margot Michaud                                                                                                                                                        |
| 131 |    971.358797 |    768.223373 | Scott Hartman                                                                                                                                                         |
| 132 |    853.187769 |    237.588414 | Ignacio Contreras                                                                                                                                                     |
| 133 |     60.638466 |    282.654831 | Steven Traver                                                                                                                                                         |
| 134 |    232.300714 |    121.841035 | Steven Coombs                                                                                                                                                         |
| 135 |    353.805288 |    739.265171 | Mathew Wedel                                                                                                                                                          |
| 136 |    285.956608 |    202.739948 | Collin Gross                                                                                                                                                          |
| 137 |    198.742722 |    609.440018 | Anthony Caravaggi                                                                                                                                                     |
| 138 |     24.072602 |    424.792819 | Javiera Constanzo                                                                                                                                                     |
| 139 |     85.432204 |    663.280193 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 140 |    229.513215 |    489.733816 | Alex Slavenko                                                                                                                                                         |
| 141 |     69.979247 |     98.360875 | NA                                                                                                                                                                    |
| 142 |    222.331693 |    372.213584 | Gareth Monger                                                                                                                                                         |
| 143 |    855.376546 |    779.809845 | Zimices                                                                                                                                                               |
| 144 |    833.333774 |    398.968116 | Kamil S. Jaron                                                                                                                                                        |
| 145 |    639.975509 |    310.698206 | Matt Crook                                                                                                                                                            |
| 146 |    236.879273 |     71.074629 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 147 |    958.086116 |    195.108728 | Andrés Sánchez                                                                                                                                                        |
| 148 |    455.433574 |    648.293095 | Margot Michaud                                                                                                                                                        |
| 149 |    223.850597 |    635.532258 | NA                                                                                                                                                                    |
| 150 |     50.315534 |      4.960911 | C. Camilo Julián-Caballero                                                                                                                                            |
| 151 |     26.062080 |    760.436881 | Gareth Monger                                                                                                                                                         |
| 152 |    514.005652 |    263.983921 | Scott Hartman                                                                                                                                                         |
| 153 |    840.998051 |     75.535663 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 154 |    138.040162 |     85.617965 | Chris huh                                                                                                                                                             |
| 155 |    932.634434 |     15.330367 | Jagged Fang Designs                                                                                                                                                   |
| 156 |    593.603256 |    295.191898 | Scott Hartman                                                                                                                                                         |
| 157 |    250.458179 |    325.307114 | Margot Michaud                                                                                                                                                        |
| 158 |    824.850977 |    770.989527 | George Edward Lodge                                                                                                                                                   |
| 159 |    156.553287 |    618.873505 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 160 |    480.780150 |    474.237594 | Blair Perry                                                                                                                                                           |
| 161 |    380.921133 |    749.015072 | Harold N Eyster                                                                                                                                                       |
| 162 |    462.456327 |    535.933799 | Zimices                                                                                                                                                               |
| 163 |    654.344005 |    223.251564 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 164 |    692.462008 |    569.588486 | Andy Wilson                                                                                                                                                           |
| 165 |    610.843123 |    601.301251 | NA                                                                                                                                                                    |
| 166 |    676.373660 |     63.235884 | Gareth Monger                                                                                                                                                         |
| 167 |     86.168946 |    156.096951 | Zimices                                                                                                                                                               |
| 168 |    983.447679 |    436.725938 | Emily Willoughby                                                                                                                                                      |
| 169 |    211.491576 |    780.545122 | Hans Hillewaert                                                                                                                                                       |
| 170 |    572.832107 |    401.417182 | L. Shyamal                                                                                                                                                            |
| 171 |    807.644021 |    118.388216 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 172 |    680.236567 |    790.551804 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 173 |    311.566673 |     12.956846 | NA                                                                                                                                                                    |
| 174 |    569.736791 |    142.277855 | Jagged Fang Designs                                                                                                                                                   |
| 175 |     42.228858 |    124.310785 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 176 |    123.082112 |    248.436431 | M Kolmann                                                                                                                                                             |
| 177 |     25.733918 |    570.225925 | Don Armstrong                                                                                                                                                         |
| 178 |    674.863308 |     32.010637 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 179 |    888.634985 |    775.499282 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 180 |    814.832700 |    539.292700 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 181 |    664.164372 |    650.152329 | Birgit Lang                                                                                                                                                           |
| 182 |    384.948093 |    455.923871 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 183 |    495.731890 |    290.475048 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 184 |    590.728461 |    376.645088 | Tauana J. Cunha                                                                                                                                                       |
| 185 |     24.394232 |     73.708290 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 186 |    991.380516 |     11.814861 | Matt Crook                                                                                                                                                            |
| 187 |    424.194054 |    487.172007 | Xavier Giroux-Bougard                                                                                                                                                 |
| 188 |     54.170890 |    412.087273 | Gareth Monger                                                                                                                                                         |
| 189 |    797.121232 |    781.763317 | Ferran Sayol                                                                                                                                                          |
| 190 |    468.817980 |    405.482845 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 191 |    514.989342 |    459.770105 | Joshua Fowler                                                                                                                                                         |
| 192 |    355.544225 |    507.970761 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 193 |     18.587922 |     99.753047 | Margot Michaud                                                                                                                                                        |
| 194 |    112.024374 |    260.294148 | Dmitry Bogdanov                                                                                                                                                       |
| 195 |    120.518330 |    459.701814 | Paul O. Lewis                                                                                                                                                         |
| 196 |    735.899802 |    620.516626 | Matt Crook                                                                                                                                                            |
| 197 |     94.085970 |    743.526634 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 198 |    554.758091 |    380.362694 | Andy Wilson                                                                                                                                                           |
| 199 |    616.260935 |    773.678315 | Collin Gross                                                                                                                                                          |
| 200 |    893.167285 |    178.788516 | Jonathan Wells                                                                                                                                                        |
| 201 |    176.753699 |    466.483417 | Emily Willoughby                                                                                                                                                      |
| 202 |    889.706915 |    564.484457 | Kanchi Nanjo                                                                                                                                                          |
| 203 |    887.680136 |    737.022817 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 204 |    269.878668 |    386.102774 | Steven Traver                                                                                                                                                         |
| 205 |    879.262347 |    331.716672 | Andy Wilson                                                                                                                                                           |
| 206 |    539.080509 |    594.304304 | Noah Schlottman                                                                                                                                                       |
| 207 |    518.212619 |    741.851645 | Jaime Headden                                                                                                                                                         |
| 208 |    976.887651 |    414.037597 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 209 |    875.339948 |    386.797660 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 210 |    183.253985 |    556.302321 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 211 |    859.806204 |    679.537457 | Matt Crook                                                                                                                                                            |
| 212 |    698.231618 |    602.498781 | Zimices                                                                                                                                                               |
| 213 |    498.143884 |    443.484371 | Julio Garza                                                                                                                                                           |
| 214 |    599.564656 |     83.221114 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 215 |    469.298131 |    383.562423 | Margot Michaud                                                                                                                                                        |
| 216 |    933.595802 |    594.722022 | Scott Hartman                                                                                                                                                         |
| 217 |    684.138074 |    238.937139 | Chris huh                                                                                                                                                             |
| 218 |    646.468422 |     44.469755 | Dean Schnabel                                                                                                                                                         |
| 219 |    978.151777 |    390.717532 | Steven Traver                                                                                                                                                         |
| 220 |    560.928791 |    444.407331 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 221 |     19.785411 |    497.268033 | Zimices                                                                                                                                                               |
| 222 |    555.257958 |    162.639803 | White Wolf                                                                                                                                                            |
| 223 |    238.908154 |    272.606162 | T. Michael Keesey                                                                                                                                                     |
| 224 |    987.269695 |    737.197026 | Scott Hartman                                                                                                                                                         |
| 225 |    452.543266 |    561.465692 | Kamil S. Jaron                                                                                                                                                        |
| 226 |    724.304829 |    690.371721 | Steven Traver                                                                                                                                                         |
| 227 |     56.431624 |    755.025366 | Jon M Laurent                                                                                                                                                         |
| 228 |    219.752643 |    142.316217 | Zimices                                                                                                                                                               |
| 229 |    490.409665 |    171.118346 | Henry Lydecker                                                                                                                                                        |
| 230 |    566.360268 |    727.702828 | M Kolmann                                                                                                                                                             |
| 231 |    859.870715 |    370.784049 | Cesar Julian                                                                                                                                                          |
| 232 |    690.355109 |    333.311550 | Matt Crook                                                                                                                                                            |
| 233 |    706.628522 |    410.124372 | Zimices                                                                                                                                                               |
| 234 |    141.920600 |    339.834761 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 235 |    544.411861 |    427.641130 | Collin Gross                                                                                                                                                          |
| 236 |     26.879789 |     20.716624 | Steven Traver                                                                                                                                                         |
| 237 |    612.573083 |    113.814679 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 238 |    470.424123 |    351.684897 | Jagged Fang Designs                                                                                                                                                   |
| 239 |    937.934402 |    682.442599 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                             |
| 240 |    206.678822 |    624.910743 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 241 |    995.189617 |    724.491980 | wsnaccad                                                                                                                                                              |
| 242 |    809.005121 |    182.322784 | Gareth Monger                                                                                                                                                         |
| 243 |    570.855532 |    583.345064 | T. Michael Keesey                                                                                                                                                     |
| 244 |    217.639719 |    319.420201 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 245 |    508.380517 |     34.952714 | Matt Crook                                                                                                                                                            |
| 246 |    875.985860 |    660.466289 | Maxime Dahirel                                                                                                                                                        |
| 247 |    552.852410 |     44.807858 | Margot Michaud                                                                                                                                                        |
| 248 |    559.001254 |    563.470324 | Kai R. Caspar                                                                                                                                                         |
| 249 |    542.949669 |    223.391325 | Matt Crook                                                                                                                                                            |
| 250 |    716.123452 |    112.177275 | Gustav Mützel                                                                                                                                                         |
| 251 |    585.171406 |    769.996348 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 252 |    289.872917 |    715.557250 | NA                                                                                                                                                                    |
| 253 |    471.029278 |     58.669038 | Margot Michaud                                                                                                                                                        |
| 254 |    714.235948 |     84.910503 | Andy Wilson                                                                                                                                                           |
| 255 |    716.247239 |    448.573349 | Scott Hartman                                                                                                                                                         |
| 256 |    803.376480 |    147.452151 | Margot Michaud                                                                                                                                                        |
| 257 |    205.258103 |    657.344095 | Tasman Dixon                                                                                                                                                          |
| 258 |    682.881278 |      8.673143 | Scott Hartman                                                                                                                                                         |
| 259 |    905.358953 |    755.348613 | Scott Hartman                                                                                                                                                         |
| 260 |    361.332488 |     95.105206 | Ferran Sayol                                                                                                                                                          |
| 261 |    925.594806 |    232.635176 | NA                                                                                                                                                                    |
| 262 |    816.983352 |     20.444151 | Gareth Monger                                                                                                                                                         |
| 263 |    279.847597 |    118.808698 | Sharon Wegner-Larsen                                                                                                                                                  |
| 264 |    427.950707 |    768.611534 | NA                                                                                                                                                                    |
| 265 |    889.764221 |    289.048587 | Kamil S. Jaron                                                                                                                                                        |
| 266 |    996.338890 |    498.771531 | Gareth Monger                                                                                                                                                         |
| 267 |    225.525691 |    551.478550 | Milton Tan                                                                                                                                                            |
| 268 |    685.592006 |    399.402510 | Ferran Sayol                                                                                                                                                          |
| 269 |    609.533399 |    331.553867 | T. Michael Keesey                                                                                                                                                     |
| 270 |    139.548348 |     17.757359 | Margot Michaud                                                                                                                                                        |
| 271 |    545.658779 |    797.881195 | T. Michael Keesey                                                                                                                                                     |
| 272 |    521.750464 |    270.043343 | Nobu Tamura                                                                                                                                                           |
| 273 |    168.063735 |    781.337821 | Harold N Eyster                                                                                                                                                       |
| 274 |    803.753807 |     13.325816 | Sarah Werning                                                                                                                                                         |
| 275 |    532.081498 |    357.999549 | NA                                                                                                                                                                    |
| 276 |    480.979763 |     85.130730 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 277 |     23.500307 |    173.590786 | Steven Traver                                                                                                                                                         |
| 278 |    309.530674 |    633.327992 | Zimices                                                                                                                                                               |
| 279 |    678.910506 |    757.084328 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 280 |    752.404117 |    739.366592 | T. Michael Keesey                                                                                                                                                     |
| 281 |    165.687943 |    217.986714 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 282 |    350.713100 |    719.963512 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                     |
| 283 |    533.015043 |    709.597825 | Beth Reinke                                                                                                                                                           |
| 284 |    120.609027 |    627.588595 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                           |
| 285 |    270.995174 |    634.611187 | Caleb M. Brown                                                                                                                                                        |
| 286 |    849.365284 |     39.275449 | Maha Ghazal                                                                                                                                                           |
| 287 |    613.931385 |    467.174971 | Matt Crook                                                                                                                                                            |
| 288 |   1008.286740 |    412.899384 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 289 |    372.557008 |    723.979172 | S.Martini                                                                                                                                                             |
| 290 |   1007.791798 |    694.925047 | Jagged Fang Designs                                                                                                                                                   |
| 291 |    854.602138 |    540.059827 | Jagged Fang Designs                                                                                                                                                   |
| 292 |    683.085730 |    673.190817 | Mathew Wedel                                                                                                                                                          |
| 293 |    865.684007 |    331.572837 | Matt Crook                                                                                                                                                            |
| 294 |    460.664682 |    785.041903 | T. Michael Keesey                                                                                                                                                     |
| 295 |    303.585350 |     86.832319 | Maija Karala                                                                                                                                                          |
| 296 |    826.497922 |    123.010667 | NA                                                                                                                                                                    |
| 297 |    201.927876 |    135.580918 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 298 |     38.726202 |    296.585528 | Geoff Shaw                                                                                                                                                            |
| 299 |    854.107795 |    127.269594 | Terpsichores                                                                                                                                                          |
| 300 |    358.328962 |    606.473734 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 301 |    999.086750 |    672.643094 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 302 |    400.006384 |    512.004383 | Jagged Fang Designs                                                                                                                                                   |
| 303 |    516.809914 |    126.129485 | Carlos Cano-Barbacil                                                                                                                                                  |
| 304 |    527.017453 |    633.193187 | Zimices                                                                                                                                                               |
| 305 |    495.044585 |    512.248450 | Yan Wong                                                                                                                                                              |
| 306 |    926.513465 |    764.598588 | Gareth Monger                                                                                                                                                         |
| 307 |    916.384705 |    435.303602 | Matt Crook                                                                                                                                                            |
| 308 |    465.160300 |    674.351629 | Marmelad                                                                                                                                                              |
| 309 |    198.049576 |    217.150721 | Matt Crook                                                                                                                                                            |
| 310 |    173.801708 |    120.706366 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 311 |    907.266175 |    314.861571 | Matt Crook                                                                                                                                                            |
| 312 |    535.515752 |    207.320524 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 313 |    526.148993 |    648.874817 | Jagged Fang Designs                                                                                                                                                   |
| 314 |    870.691637 |    515.219637 | Joanna Wolfe                                                                                                                                                          |
| 315 |    779.203073 |     96.403201 | Zimices                                                                                                                                                               |
| 316 |    399.452798 |     49.453736 | Zimices                                                                                                                                                               |
| 317 |    225.349033 |    718.307468 | Jagged Fang Designs                                                                                                                                                   |
| 318 |    895.019851 |      8.169871 | Scott Hartman                                                                                                                                                         |
| 319 |    739.699776 |    749.583202 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 320 |    574.178606 |    524.373920 | xgirouxb                                                                                                                                                              |
| 321 |    591.551556 |    789.385651 | Oscar Sanisidro                                                                                                                                                       |
| 322 |    349.088363 |    189.577209 | Zimices                                                                                                                                                               |
| 323 |    693.316032 |    614.474580 | Steven Traver                                                                                                                                                         |
| 324 |    779.040308 |    507.970001 | Noah Schlottman                                                                                                                                                       |
| 325 |    144.697870 |    191.569561 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 326 |     91.658307 |    416.826879 | Matt Crook                                                                                                                                                            |
| 327 |    260.508667 |     74.538964 | Michelle Site                                                                                                                                                         |
| 328 |    531.776490 |      9.494255 | Julio Garza                                                                                                                                                           |
| 329 |    675.205662 |     17.790475 | Caleb M. Brown                                                                                                                                                        |
| 330 |    124.117384 |    747.038714 | Margot Michaud                                                                                                                                                        |
| 331 |    733.097252 |    192.049582 | Gareth Monger                                                                                                                                                         |
| 332 |    239.298360 |    285.263099 | Matt Crook                                                                                                                                                            |
| 333 |    687.014641 |    366.409127 | Jagged Fang Designs                                                                                                                                                   |
| 334 |    476.368279 |    103.987206 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 335 |    971.403443 |    448.011615 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 336 |    378.686078 |    217.508208 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 337 |    302.260668 |    759.375689 | Margot Michaud                                                                                                                                                        |
| 338 |    995.959119 |    339.121345 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 339 |    146.789912 |    557.736883 | Ferran Sayol                                                                                                                                                          |
| 340 |    133.494852 |    682.031607 | Nobu Tamura                                                                                                                                                           |
| 341 |    148.822513 |     34.594397 | Gareth Monger                                                                                                                                                         |
| 342 |    757.214600 |    580.173616 | Scott Hartman                                                                                                                                                         |
| 343 |    868.666750 |    358.847338 | Gareth Monger                                                                                                                                                         |
| 344 |    169.769341 |    324.866265 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 345 |     64.497693 |    522.336323 | Ferran Sayol                                                                                                                                                          |
| 346 |    625.837776 |    537.378925 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 347 |    768.484849 |    543.060221 | Jon Hill                                                                                                                                                              |
| 348 |    243.791556 |    617.635185 | FunkMonk                                                                                                                                                              |
| 349 |    597.530338 |    400.971639 | T. Michael Keesey                                                                                                                                                     |
| 350 |     18.855888 |    216.342616 | Sean McCann                                                                                                                                                           |
| 351 |    241.655848 |     43.703477 | T. Tischler                                                                                                                                                           |
| 352 |    955.122019 |    610.170769 | Neil Kelley                                                                                                                                                           |
| 353 |    454.615121 |    691.889789 | Elisabeth Östman                                                                                                                                                      |
| 354 |    639.015669 |    705.240767 | Ferran Sayol                                                                                                                                                          |
| 355 |    264.779617 |    213.932925 | Christian A. Masnaghetti                                                                                                                                              |
| 356 |    104.705182 |    131.526714 | Jagged Fang Designs                                                                                                                                                   |
| 357 |    798.586603 |    285.870846 | Mykle Hoban                                                                                                                                                           |
| 358 |    867.787752 |    757.956849 | Zimices                                                                                                                                                               |
| 359 |    392.308473 |    601.518438 | Carlos Cano-Barbacil                                                                                                                                                  |
| 360 |    636.530868 |    520.898175 | Margot Michaud                                                                                                                                                        |
| 361 |    105.001221 |     26.229115 | Jaime Headden                                                                                                                                                         |
| 362 |    673.665774 |     76.241397 | Sarah Alewijnse                                                                                                                                                       |
| 363 |    297.864093 |    377.147995 | Zimices                                                                                                                                                               |
| 364 |    818.886389 |    521.401366 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 365 |    937.005363 |    181.876014 | Joanna Wolfe                                                                                                                                                          |
| 366 |    802.604717 |    669.230756 | Yan Wong                                                                                                                                                              |
| 367 |    303.842226 |    335.473194 | Markus A. Grohme                                                                                                                                                      |
| 368 |     38.386880 |    435.606954 | Renato de Carvalho Ferreira                                                                                                                                           |
| 369 |    509.518596 |     18.365720 | Gareth Monger                                                                                                                                                         |
| 370 |    889.506796 |    372.597667 | Gareth Monger                                                                                                                                                         |
| 371 |    486.961545 |    594.783117 | Jagged Fang Designs                                                                                                                                                   |
| 372 |    854.478586 |    184.576360 | Steven Traver                                                                                                                                                         |
| 373 |     40.749514 |    676.943711 | Chris huh                                                                                                                                                             |
| 374 |    855.750025 |    565.152422 | Zimices                                                                                                                                                               |
| 375 |    206.611065 |    567.708275 | Chuanixn Yu                                                                                                                                                           |
| 376 |    743.189500 |     93.835567 | NA                                                                                                                                                                    |
| 377 |    409.287684 |    269.336497 | Zimices                                                                                                                                                               |
| 378 |    942.945548 |    565.122359 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 379 |    107.448681 |    118.960340 | Mathieu Pélissié                                                                                                                                                      |
| 380 |    724.845585 |    235.532526 | Anthony Caravaggi                                                                                                                                                     |
| 381 |    312.668407 |    349.201461 | Shyamal                                                                                                                                                               |
| 382 |    999.993540 |    508.319594 | Christoph Schomburg                                                                                                                                                   |
| 383 |    256.105400 |    365.970651 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 384 |    519.929581 |    164.252163 | Scott Hartman                                                                                                                                                         |
| 385 |    624.476507 |     82.196340 | Zimices                                                                                                                                                               |
| 386 |    233.229867 |    505.404848 | T. Michael Keesey                                                                                                                                                     |
| 387 |    995.588651 |    481.546817 | Scott Hartman                                                                                                                                                         |
| 388 |    182.903254 |    603.993568 | Myriam\_Ramirez                                                                                                                                                       |
| 389 |    802.298998 |    762.208965 | Margot Michaud                                                                                                                                                        |
| 390 |   1013.971744 |    104.854978 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                          |
| 391 |    392.153127 |    613.041541 | Iain Reid                                                                                                                                                             |
| 392 |    417.506185 |    222.678768 | Sarah Werning                                                                                                                                                         |
| 393 |    146.533402 |    570.835624 | Steven Blackwood                                                                                                                                                      |
| 394 |    174.820297 |    713.554986 | Felix Vaux                                                                                                                                                            |
| 395 |    996.788759 |    224.510859 | Jagged Fang Designs                                                                                                                                                   |
| 396 |    325.874283 |    212.464566 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 397 |    781.284078 |    758.172060 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 398 |    649.366175 |    787.965666 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                           |
| 399 |    329.780771 |    642.629739 | Margot Michaud                                                                                                                                                        |
| 400 |    906.518737 |    249.825150 | Andy Wilson                                                                                                                                                           |
| 401 |    425.639604 |    548.642026 | T. Michael Keesey                                                                                                                                                     |
| 402 |    481.532987 |    624.984130 | Ignacio Contreras                                                                                                                                                     |
| 403 |    358.739429 |    326.845150 | Jagged Fang Designs                                                                                                                                                   |
| 404 |    432.480985 |    729.922332 | S.Martini                                                                                                                                                             |
| 405 |    714.027886 |    128.322836 | Ferran Sayol                                                                                                                                                          |
| 406 |    439.204811 |     53.643426 | Steven Traver                                                                                                                                                         |
| 407 |    398.309840 |    305.587851 | Jagged Fang Designs                                                                                                                                                   |
| 408 |    166.393552 |    101.149844 | Joanna Wolfe                                                                                                                                                          |
| 409 |    400.928404 |     95.255835 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 410 |    484.167290 |    694.043350 | Margot Michaud                                                                                                                                                        |
| 411 |   1007.726953 |    780.286780 | Maija Karala                                                                                                                                                          |
| 412 |     27.614351 |     34.533849 | Steven Traver                                                                                                                                                         |
| 413 |    658.532593 |    549.468868 | Gareth Monger                                                                                                                                                         |
| 414 |    472.666115 |     21.819359 | T. Michael Keesey                                                                                                                                                     |
| 415 |    783.262663 |    170.194207 | Matt Crook                                                                                                                                                            |
| 416 |    548.806203 |    455.517841 | Gareth Monger                                                                                                                                                         |
| 417 |    874.838991 |    719.617185 | Smokeybjb                                                                                                                                                             |
| 418 |    517.449958 |    221.971056 | T. Michael Keesey                                                                                                                                                     |
| 419 |    601.529091 |    308.497505 | Margot Michaud                                                                                                                                                        |
| 420 |    642.254942 |    117.521167 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 421 |    764.838962 |    248.090254 | Iain Reid                                                                                                                                                             |
| 422 |    123.944137 |    129.559244 | Ferran Sayol                                                                                                                                                          |
| 423 |    193.614062 |    481.483853 | NA                                                                                                                                                                    |
| 424 |    158.709935 |    409.387662 | T. Michael Keesey                                                                                                                                                     |
| 425 |    808.898120 |    388.674245 | NA                                                                                                                                                                    |
| 426 |    821.320264 |     34.719768 | Markus A. Grohme                                                                                                                                                      |
| 427 |    752.350558 |    613.727881 | Markus A. Grohme                                                                                                                                                      |
| 428 |    848.797789 |     13.197265 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 429 |    324.755730 |    190.676424 | Zimices                                                                                                                                                               |
| 430 |   1006.987302 |    325.251178 | Iain Reid                                                                                                                                                             |
| 431 |    692.768129 |    430.650812 | Jagged Fang Designs                                                                                                                                                   |
| 432 |    257.056918 |    304.621579 | Birgit Lang                                                                                                                                                           |
| 433 |    652.498027 |    468.322638 | Chris huh                                                                                                                                                             |
| 434 |    748.955335 |    545.592741 | T. Michael Keesey                                                                                                                                                     |
| 435 |    278.495949 |     27.312740 | Margot Michaud                                                                                                                                                        |
| 436 |    890.171029 |    599.687214 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 437 |    843.829519 |    226.145943 | Emily Willoughby                                                                                                                                                      |
| 438 |    557.799287 |    416.296318 | Gareth Monger                                                                                                                                                         |
| 439 |    620.639623 |    294.338549 | Kanchi Nanjo                                                                                                                                                          |
| 440 |    252.607230 |    788.954085 | Jagged Fang Designs                                                                                                                                                   |
| 441 |    704.756509 |    665.652145 | Dann Pigdon                                                                                                                                                           |
| 442 |    810.348766 |    635.167487 | Markus A. Grohme                                                                                                                                                      |
| 443 |    743.746966 |    647.188005 | Chris huh                                                                                                                                                             |
| 444 |    307.852520 |    220.632986 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 445 |     16.807165 |    309.225753 | CNZdenek                                                                                                                                                              |
| 446 |    802.334402 |    658.207574 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 447 |    543.889987 |    122.210066 | Zachary Quigley                                                                                                                                                       |
| 448 |    547.917360 |    260.716080 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 449 |    819.542077 |    214.716655 | Ferran Sayol                                                                                                                                                          |
| 450 |    548.983139 |    580.698811 | Chuanixn Yu                                                                                                                                                           |
| 451 |    771.261110 |    119.823131 | Steven Coombs                                                                                                                                                         |
| 452 |     77.462167 |    393.463703 | Markus A. Grohme                                                                                                                                                      |
| 453 |    583.654312 |    477.341260 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 454 |    103.875842 |    300.827395 | Scott Hartman                                                                                                                                                         |
| 455 |    709.355231 |    743.123698 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 456 |    711.363989 |      6.332272 | Shyamal                                                                                                                                                               |
| 457 |    853.405928 |    172.410243 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 458 |     67.186817 |    447.220823 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 459 |    611.115203 |    713.445803 | Ferran Sayol                                                                                                                                                          |
| 460 |    374.731296 |    766.182618 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 461 |    931.759217 |    332.649145 | Scott Hartman                                                                                                                                                         |
| 462 |    867.875276 |    190.328578 | Xavier Giroux-Bougard                                                                                                                                                 |
| 463 |   1014.391059 |    608.118375 | Steven Traver                                                                                                                                                         |
| 464 |    350.407771 |    377.198742 | Markus A. Grohme                                                                                                                                                      |
| 465 |    958.519582 |    527.536042 | Alex Slavenko                                                                                                                                                         |
| 466 |     71.486794 |    459.762070 | Neil Kelley                                                                                                                                                           |
| 467 |     77.212581 |    590.222873 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 468 |    271.511780 |     84.140659 | Markus A. Grohme                                                                                                                                                      |
| 469 |    430.087533 |    347.786582 | Chris huh                                                                                                                                                             |
| 470 |    235.506833 |      7.121044 | Chris huh                                                                                                                                                             |
| 471 |    998.075610 |    427.860847 | Chris huh                                                                                                                                                             |
| 472 |    910.808017 |     28.030048 | CNZdenek                                                                                                                                                              |
| 473 |    702.835181 |    687.456859 | Ferran Sayol                                                                                                                                                          |
| 474 |     18.462040 |    544.402374 | Matt Crook                                                                                                                                                            |
| 475 |    954.221208 |     45.981954 | Michelle Site                                                                                                                                                         |
| 476 |    642.801848 |    625.947188 | NA                                                                                                                                                                    |
| 477 |     49.656509 |    773.574481 | Scott Hartman                                                                                                                                                         |
| 478 |    898.095618 |    451.903244 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 479 |     21.339392 |    402.546407 | Steven Traver                                                                                                                                                         |
| 480 |    619.588274 |    219.558619 | Gareth Monger                                                                                                                                                         |
| 481 |    411.147334 |    136.830340 | Alex Slavenko                                                                                                                                                         |
| 482 |    264.009959 |      9.530933 | Birgit Lang                                                                                                                                                           |
| 483 |    612.024771 |    244.968300 | Renato de Carvalho Ferreira                                                                                                                                           |
| 484 |     49.387068 |    726.740755 | Harold N Eyster                                                                                                                                                       |
| 485 |    642.773228 |    651.046703 | Jagged Fang Designs                                                                                                                                                   |
| 486 |   1006.577747 |    545.770570 | Stuart Humphries                                                                                                                                                      |
| 487 |    230.960365 |    263.331908 | Jaime Headden                                                                                                                                                         |
| 488 |    721.263435 |     68.993206 | Chuanixn Yu                                                                                                                                                           |
| 489 |    498.637232 |     57.257363 | Zimices                                                                                                                                                               |
| 490 |    658.369139 |    397.910676 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 491 |   1007.764979 |    632.108917 | Emily Willoughby                                                                                                                                                      |
| 492 |    701.532275 |    204.673075 | Matt Crook                                                                                                                                                            |
| 493 |    807.585036 |    299.812746 | Yan Wong                                                                                                                                                              |
| 494 |    935.454634 |    388.883742 | Margot Michaud                                                                                                                                                        |
| 495 |     76.798742 |    252.978602 | Gareth Monger                                                                                                                                                         |
| 496 |    537.472126 |    284.391551 | Zimices                                                                                                                                                               |
| 497 |    876.070063 |    727.067698 | Tauana J. Cunha                                                                                                                                                       |
| 498 |    428.754452 |    526.566224 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 499 |    291.244253 |    786.149719 | Zimices                                                                                                                                                               |
| 500 |    982.757295 |    790.844479 | Jagged Fang Designs                                                                                                                                                   |
| 501 |    170.281462 |    490.265894 | NA                                                                                                                                                                    |
| 502 |    412.076966 |     11.992678 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
| 503 |    427.278431 |    667.832340 | Zimices                                                                                                                                                               |
| 504 |    112.459762 |    554.763908 | Chris huh                                                                                                                                                             |
| 505 |     24.659266 |    115.703413 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 506 |    952.953837 |     24.294186 | NA                                                                                                                                                                    |
| 507 |    848.253454 |    574.163313 | Smokeybjb                                                                                                                                                             |
| 508 |    173.299738 |    566.131315 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 509 |     41.144747 |    482.322176 | NA                                                                                                                                                                    |
| 510 |    260.582880 |    143.946432 | Gareth Monger                                                                                                                                                         |
| 511 |    554.652758 |    605.967094 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 512 |    230.672269 |    534.661941 | Steven Traver                                                                                                                                                         |
| 513 |    944.986673 |     82.575691 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 514 |    366.331230 |    388.481486 | NA                                                                                                                                                                    |
| 515 |    499.020659 |    486.130011 | NA                                                                                                                                                                    |
| 516 |    691.285797 |     34.589455 | Gareth Monger                                                                                                                                                         |
| 517 |    264.582990 |    710.772624 | Birgit Lang                                                                                                                                                           |
| 518 |    646.979578 |    332.890875 | Scott Hartman                                                                                                                                                         |
| 519 |    756.081615 |    603.842905 | Chris huh                                                                                                                                                             |
| 520 |    799.887536 |    139.871804 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 521 |    730.631126 |    583.964488 | Mattia Menchetti                                                                                                                                                      |
| 522 |    589.259104 |    556.132122 | Felix Vaux                                                                                                                                                            |
| 523 |    743.251864 |    355.549248 | Jagged Fang Designs                                                                                                                                                   |
| 524 |    862.882967 |    485.819069 | NA                                                                                                                                                                    |
| 525 |    644.869149 |    763.138377 | NA                                                                                                                                                                    |
| 526 |    274.606181 |    766.280828 | Tasman Dixon                                                                                                                                                          |
| 527 |      5.022197 |     67.006554 | Gareth Monger                                                                                                                                                         |
| 528 |    736.217806 |    362.560568 | Margot Michaud                                                                                                                                                        |
| 529 |    423.268861 |    502.989851 | Andy Wilson                                                                                                                                                           |
| 530 |    502.350734 |    533.853162 | Ignacio Contreras                                                                                                                                                     |
| 531 |   1019.880432 |    525.978983 | Gareth Monger                                                                                                                                                         |
| 532 |    627.506597 |     63.414194 | NA                                                                                                                                                                    |
| 533 |    661.667764 |    208.368867 | Scott Hartman                                                                                                                                                         |
| 534 |    419.497597 |    256.429629 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
| 535 |    420.419913 |    695.213114 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                              |
| 536 |     84.576814 |    526.773577 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 537 |    596.304923 |    276.081472 | Gareth Monger                                                                                                                                                         |
| 538 |     16.123234 |    236.012199 | Zimices                                                                                                                                                               |
| 539 |    115.008506 |    315.411836 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 540 |    391.602938 |    319.385382 | Catherine Yasuda                                                                                                                                                      |

    #> Your tweet has been posted!
