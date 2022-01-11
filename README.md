
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

Gareth Monger, Collin Gross, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Kai R. Caspar, Zimices, T. Michael Keesey, Mali’o Kodis,
photograph by Melissa Frey, Matus Valach, Matt Celeskey, George Edward
Lodge, Lisa Byrne, Scott Hartman, Armin Reindl, FunkMonk, Emily
Willoughby, Michelle Site, Verdilak, Scott D. Sampson, Mark A. Loewen,
Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith,
Alan L. Titus, Matt Crook, Margot Michaud, Jiekun He, Jagged Fang
Designs, Milton Tan, Dean Schnabel, Rebecca Groom, Ferran Sayol,
terngirl, Katie S. Collins, Saguaro Pictures (source photo) and T.
Michael Keesey, Ray Simpson (vectorized by T. Michael Keesey), NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), Steven Traver, Felix Vaux, Oscar Sanisidro,
Tracy A. Heath, Noah Schlottman, photo by Carlos Sánchez-Ortiz, Yan
Wong, Matt Martyniuk, Ieuan Jones, Andrew A. Farke, Chris huh, Mali’o
Kodis, photograph by P. Funch and R.M. Kristensen, Robbie N. Cada
(vectorized by T. Michael Keesey), Iain Reid, Stephen O’Connor
(vectorized by T. Michael Keesey), Scarlet23 (vectorized by T. Michael
Keesey), Brad McFeeters (vectorized by T. Michael Keesey), Mark
Hofstetter (vectorized by T. Michael Keesey), Nobu Tamura, vectorized by
Zimices, Jaime Headden, Tasman Dixon, Markus A. Grohme, Birgit Lang,
Steven Haddock • Jellywatch.org, Sean McCann, Nobu Tamura (vectorized by
T. Michael Keesey), Alexander Schmidt-Lebuhn, Smokeybjb, Kamil S. Jaron,
Noah Schlottman, photo by David J Patterson, Christoph Schomburg,
Gabriela Palomo-Munoz, Gopal Murali, Caio Bernardes, vectorized by
Zimices, Acrocynus (vectorized by T. Michael Keesey), Ignacio Contreras,
Becky Barnes, Roberto Díaz Sibaja, Tony Ayling (vectorized by T. Michael
Keesey), Mathew Wedel, L. Shyamal, C. Camilo Julián-Caballero, Kenneth
Lacovara (vectorized by T. Michael Keesey), Nobu Tamura (vectorized by
A. Verrière), Ingo Braasch, Alex Slavenko, M Hutchinson, Fernando
Carezzano, Maija Karala, Emily Jane McTavish, Mathilde Cordellier,
Jennifer Trimble, T. Michael Keesey (after Walker & al.), Peter Coxhead,
Sharon Wegner-Larsen, Francesca Belem Lopes Palmeira, Matt Wilkins
(photo by Patrick Kavanagh), Lukasiniho, Fernando Campos De Domenico,
David Liao, Alexandre Vong, Timothy Knepp (vectorized by T. Michael
Keesey), Joanna Wolfe, Melissa Broussard, Inessa Voet, Remes K, Ortega
F, Fierro I, Joger U, Kosma R, et al., Scott Reid, Mathieu Basille, Beth
Reinke, Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B.
Chaves), Pete Buchholz, Ekaterina Kopeykina (vectorized by T. Michael
Keesey), Carlos Cano-Barbacil, Conty (vectorized by T. Michael Keesey),
Juan Carlos Jerí, Ghedoghedo (vectorized by T. Michael Keesey), Cristina
Guijarro, Chase Brownstein, Smokeybjb (vectorized by T. Michael Keesey),
Nicholas J. Czaplewski, vectorized by Zimices, T. Michael Keesey (after
Joseph Wolf), Alan Manson (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Noah Schlottman, photo by Casey Dunn,
Sarah Werning, Jack Mayer Wood, Renato de Carvalho Ferreira, Zimices /
Julián Bayona, C. Abraczinskas, FunkMonk \[Michael B.H.\] (modified by
T. Michael Keesey), Ville-Veikko Sinkkonen, Mattia Menchetti, Joseph J.
W. Sertich, Mark A. Loewen, Michael Scroggie, Robbie Cada (vectorized by
T. Michael Keesey), T. Tischler, James I. Kirkland, Luis Alcalá, Mark A.
Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized
by T. Michael Keesey), Alexandra van der Geer, Matt Dempsey, Joedison
Rocha, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Michele M Tobias, Filip em, Farelli (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Henry Lydecker, Andreas Hejnol,
G. M. Woodward, Mason McNair, Mali’o Kodis, photograph by Hans
Hillewaert, Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen
(vectorized by T. Michael Keesey), Chloé Schmidt, DW Bapst (Modified
from Bulman, 1964), Neil Kelley, Harold N Eyster, Isaure Scavezzoni,
Tauana J. Cunha, Emil Schmidt (vectorized by Maxime Dahirel), Lauren
Sumner-Rooney, Richard Ruggiero, vectorized by Zimices, Sherman F.
Denton via rawpixel.com (illustration) and Timothy J. Bartley
(silhouette), Jan Sevcik (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Esme Ashe-Jepson, Haplochromis
(vectorized by T. Michael Keesey), Tomas Willems (vectorized by T.
Michael Keesey), Dmitry Bogdanov and FunkMonk (vectorized by T. Michael
Keesey), Steven Coombs, SecretJellyMan, Yan Wong from photo by Denes
Emoke, Mihai Dragos (vectorized by T. Michael Keesey), T. Michael Keesey
(from a mount by Allis Markham), Chuanixn Yu, T. Michael Keesey (after
James & al.), Robert Gay, Pranav Iyer (grey ideas), Oren Peles /
vectorized by Yan Wong, Scott Hartman (modified by T. Michael Keesey),
wsnaccad

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |     203.39278 |    682.225342 | Gareth Monger                                                                                                                                                                   |
|   2 |     241.02444 |    570.981748 | Collin Gross                                                                                                                                                                    |
|   3 |     533.33774 |    253.645673 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|   4 |     207.57074 |    289.151583 | Kai R. Caspar                                                                                                                                                                   |
|   5 |     119.50581 |    174.113830 | Zimices                                                                                                                                                                         |
|   6 |     117.06824 |    416.360564 | T. Michael Keesey                                                                                                                                                               |
|   7 |     648.27769 |     46.159913 | Gareth Monger                                                                                                                                                                   |
|   8 |     719.80670 |    638.683334 | Gareth Monger                                                                                                                                                                   |
|   9 |     504.15068 |    410.232435 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                        |
|  10 |     547.48521 |    534.742102 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  11 |     347.61811 |    346.044823 | Gareth Monger                                                                                                                                                                   |
|  12 |     831.29209 |    232.168593 | Matus Valach                                                                                                                                                                    |
|  13 |     827.93765 |    458.341729 | Matt Celeskey                                                                                                                                                                   |
|  14 |     614.73312 |    133.600245 | George Edward Lodge                                                                                                                                                             |
|  15 |     520.92875 |    267.910762 | Lisa Byrne                                                                                                                                                                      |
|  16 |     478.94965 |    710.913822 | Scott Hartman                                                                                                                                                                   |
|  17 |     643.72216 |    378.010075 | Armin Reindl                                                                                                                                                                    |
|  18 |     905.96120 |     64.682476 | Scott Hartman                                                                                                                                                                   |
|  19 |     700.29816 |    260.144693 | FunkMonk                                                                                                                                                                        |
|  20 |     343.00076 |    671.993477 | Emily Willoughby                                                                                                                                                                |
|  21 |     969.22208 |    244.345290 | Michelle Site                                                                                                                                                                   |
|  22 |     227.98647 |    393.758752 | Verdilak                                                                                                                                                                        |
|  23 |     383.36981 |    491.108563 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                                        |
|  24 |     340.26443 |     54.843840 | Kai R. Caspar                                                                                                                                                                   |
|  25 |     427.21627 |    146.367014 | Matt Crook                                                                                                                                                                      |
|  26 |     815.16639 |    336.167082 | Margot Michaud                                                                                                                                                                  |
|  27 |     839.40900 |    667.135967 | Jiekun He                                                                                                                                                                       |
|  28 |     499.41353 |    317.964072 | Jagged Fang Designs                                                                                                                                                             |
|  29 |     765.00444 |    766.359421 | Milton Tan                                                                                                                                                                      |
|  30 |      82.48087 |    692.035237 | Dean Schnabel                                                                                                                                                                   |
|  31 |      75.92801 |    313.829701 | Rebecca Groom                                                                                                                                                                   |
|  32 |     281.65096 |    445.159872 | Ferran Sayol                                                                                                                                                                    |
|  33 |     597.21528 |    630.522612 | terngirl                                                                                                                                                                        |
|  34 |     882.28857 |    140.192455 | Katie S. Collins                                                                                                                                                                |
|  35 |     859.26812 |    564.493270 | Zimices                                                                                                                                                                         |
|  36 |     974.86973 |    355.487209 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                           |
|  37 |      70.60235 |    485.473380 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                   |
|  38 |     279.57998 |    196.472218 | Dean Schnabel                                                                                                                                                                   |
|  39 |      95.32654 |     78.929493 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
|  40 |     449.91027 |    575.789474 | Steven Traver                                                                                                                                                                   |
|  41 |     362.07291 |    733.079911 | Ferran Sayol                                                                                                                                                                    |
|  42 |     985.34841 |    126.605954 | NA                                                                                                                                                                              |
|  43 |     109.72969 |    588.282667 | NA                                                                                                                                                                              |
|  44 |     625.16819 |    766.922348 | Scott Hartman                                                                                                                                                                   |
|  45 |     922.10566 |    768.676446 | Ferran Sayol                                                                                                                                                                    |
|  46 |     500.52210 |     98.324336 | Felix Vaux                                                                                                                                                                      |
|  47 |     963.50168 |    491.692588 | Margot Michaud                                                                                                                                                                  |
|  48 |     315.69882 |    618.915300 | Matt Crook                                                                                                                                                                      |
|  49 |     624.28328 |    500.110021 | Oscar Sanisidro                                                                                                                                                                 |
|  50 |     957.13807 |    708.586810 | Ferran Sayol                                                                                                                                                                    |
|  51 |     773.52469 |    114.849433 | Tracy A. Heath                                                                                                                                                                  |
|  52 |     110.17377 |    743.695371 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                                  |
|  53 |     170.58504 |     36.108564 | Yan Wong                                                                                                                                                                        |
|  54 |     423.70495 |    254.396287 | T. Michael Keesey                                                                                                                                                               |
|  55 |     265.55134 |    770.917965 | Matt Martyniuk                                                                                                                                                                  |
|  56 |     394.33272 |    630.774640 | Margot Michaud                                                                                                                                                                  |
|  57 |     209.43132 |    496.564021 | Ieuan Jones                                                                                                                                                                     |
|  58 |     721.46048 |     10.589854 | Gareth Monger                                                                                                                                                                   |
|  59 |     667.87200 |    721.235189 | Andrew A. Farke                                                                                                                                                                 |
|  60 |     237.61372 |    101.016983 | Margot Michaud                                                                                                                                                                  |
|  61 |     279.85895 |    738.148485 | Chris huh                                                                                                                                                                       |
|  62 |     414.06357 |    360.129097 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                        |
|  63 |     743.00330 |    565.871723 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
|  64 |     211.31221 |     63.256081 | Iain Reid                                                                                                                                                                       |
|  65 |     294.76878 |    704.679246 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                              |
|  66 |     519.65094 |    501.427102 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                     |
|  67 |     121.52787 |    271.508589 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
|  68 |     589.97718 |     13.009508 | Chris huh                                                                                                                                                                       |
|  69 |     174.56424 |    533.024991 | Scott Hartman                                                                                                                                                                   |
|  70 |     910.03040 |    343.620322 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                               |
|  71 |     619.68066 |    311.968531 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
|  72 |     518.45275 |    183.299176 | Armin Reindl                                                                                                                                                                    |
|  73 |     919.93087 |     15.498038 | NA                                                                                                                                                                              |
|  74 |     962.20854 |    642.805593 | Zimices                                                                                                                                                                         |
|  75 |     441.92495 |     55.149438 | NA                                                                                                                                                                              |
|  76 |     392.36727 |    452.119598 | Steven Traver                                                                                                                                                                   |
|  77 |     451.24718 |    784.316205 | Chris huh                                                                                                                                                                       |
|  78 |     762.28634 |    214.921822 | Jaime Headden                                                                                                                                                                   |
|  79 |     835.84011 |    740.432923 | T. Michael Keesey                                                                                                                                                               |
|  80 |     525.03829 |    606.484208 | Tasman Dixon                                                                                                                                                                    |
|  81 |      77.21478 |    109.051074 | Markus A. Grohme                                                                                                                                                                |
|  82 |     700.79951 |    372.636027 | NA                                                                                                                                                                              |
|  83 |     325.03227 |    250.712794 | Zimices                                                                                                                                                                         |
|  84 |     521.85505 |     65.173625 | Steven Traver                                                                                                                                                                   |
|  85 |     687.50656 |    461.743550 | Zimices                                                                                                                                                                         |
|  86 |     948.22724 |    436.265632 | Birgit Lang                                                                                                                                                                     |
|  87 |      40.35001 |    591.672498 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
|  88 |      63.34453 |     32.970622 | Gareth Monger                                                                                                                                                                   |
|  89 |     577.78572 |    396.424442 | Sean McCann                                                                                                                                                                     |
|  90 |     467.42699 |    245.268936 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  91 |      28.32459 |    382.182202 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
|  92 |     332.01914 |     92.919633 | Steven Traver                                                                                                                                                                   |
|  93 |      90.77042 |    379.171343 | Chris huh                                                                                                                                                                       |
|  94 |     869.60769 |    747.645523 | Matt Crook                                                                                                                                                                      |
|  95 |     626.49186 |    265.872740 | Gareth Monger                                                                                                                                                                   |
|  96 |     427.36437 |     29.512225 | Smokeybjb                                                                                                                                                                       |
|  97 |     137.29332 |    115.598343 | Markus A. Grohme                                                                                                                                                                |
|  98 |     700.99831 |     98.449718 | Zimices                                                                                                                                                                         |
|  99 |     648.83379 |    561.909434 | Kamil S. Jaron                                                                                                                                                                  |
| 100 |     157.51021 |    455.620142 | Zimices                                                                                                                                                                         |
| 101 |     786.19853 |    720.659499 | Noah Schlottman, photo by David J Patterson                                                                                                                                     |
| 102 |     554.97518 |    766.503376 | Scott Hartman                                                                                                                                                                   |
| 103 |     176.73358 |    723.343529 | Felix Vaux                                                                                                                                                                      |
| 104 |     380.24917 |    554.317201 | Christoph Schomburg                                                                                                                                                             |
| 105 |     348.34762 |    179.033175 | NA                                                                                                                                                                              |
| 106 |     230.45123 |    133.786678 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 107 |     814.75390 |     17.634709 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 108 |     441.11797 |    658.453883 | Gopal Murali                                                                                                                                                                    |
| 109 |     343.21859 |    724.227309 | Caio Bernardes, vectorized by Zimices                                                                                                                                           |
| 110 |     143.36539 |    671.594169 | Zimices                                                                                                                                                                         |
| 111 |     102.41446 |    356.825116 | Scott Hartman                                                                                                                                                                   |
| 112 |     572.71731 |    711.601935 | Ferran Sayol                                                                                                                                                                    |
| 113 |    1002.73104 |    217.598735 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                     |
| 114 |     700.17886 |     70.203236 | Matt Crook                                                                                                                                                                      |
| 115 |     920.79822 |    223.303648 | Matt Crook                                                                                                                                                                      |
| 116 |      84.13239 |    230.071466 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 117 |      27.42891 |    211.408247 | Ignacio Contreras                                                                                                                                                               |
| 118 |     908.63066 |     30.364934 | Becky Barnes                                                                                                                                                                    |
| 119 |     243.07908 |    712.419258 | Roberto Díaz Sibaja                                                                                                                                                             |
| 120 |     714.02250 |    728.251064 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 121 |     989.12883 |    574.594650 | Zimices                                                                                                                                                                         |
| 122 |     725.70633 |    527.437943 | Mathew Wedel                                                                                                                                                                    |
| 123 |     530.14045 |    156.516427 | Matt Crook                                                                                                                                                                      |
| 124 |     171.64371 |    375.769196 | NA                                                                                                                                                                              |
| 125 |     139.16630 |    245.492874 | L. Shyamal                                                                                                                                                                      |
| 126 |     552.90738 |    630.652206 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 127 |      30.75956 |    459.884889 | Chris huh                                                                                                                                                                       |
| 128 |     716.14959 |     24.009728 | Tracy A. Heath                                                                                                                                                                  |
| 129 |     943.93515 |    321.985072 | Markus A. Grohme                                                                                                                                                                |
| 130 |    1011.63037 |     49.133446 | NA                                                                                                                                                                              |
| 131 |     333.61604 |    716.186878 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 132 |     789.34662 |    267.202252 | Zimices                                                                                                                                                                         |
| 133 |     328.83912 |    141.381547 | Zimices                                                                                                                                                                         |
| 134 |     534.23572 |    646.252566 | Emily Willoughby                                                                                                                                                                |
| 135 |     360.72119 |    122.403076 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 136 |     560.00664 |    175.252416 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                              |
| 137 |     492.55125 |    635.479985 | Margot Michaud                                                                                                                                                                  |
| 138 |     387.98236 |    207.914539 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 139 |      57.97630 |    429.571950 | Ferran Sayol                                                                                                                                                                    |
| 140 |     251.08908 |     33.904112 | Andrew A. Farke                                                                                                                                                                 |
| 141 |      32.33125 |    735.570871 | NA                                                                                                                                                                              |
| 142 |     483.56699 |     12.859523 | Markus A. Grohme                                                                                                                                                                |
| 143 |     200.37617 |     18.419219 | Zimices                                                                                                                                                                         |
| 144 |     744.82759 |    538.917813 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                         |
| 145 |      25.40808 |    188.924058 | Rebecca Groom                                                                                                                                                                   |
| 146 |     973.87442 |    555.743232 | Gareth Monger                                                                                                                                                                   |
| 147 |      26.09821 |     89.314339 | NA                                                                                                                                                                              |
| 148 |     437.47302 |     69.594373 | Ingo Braasch                                                                                                                                                                    |
| 149 |     566.80345 |    569.938368 | Alex Slavenko                                                                                                                                                                   |
| 150 |      42.30749 |    723.769701 | NA                                                                                                                                                                              |
| 151 |     628.39340 |     66.109715 | Zimices                                                                                                                                                                         |
| 152 |     842.12966 |    788.978275 | M Hutchinson                                                                                                                                                                    |
| 153 |     357.15247 |    675.577036 | NA                                                                                                                                                                              |
| 154 |     159.93434 |    349.013741 | L. Shyamal                                                                                                                                                                      |
| 155 |     436.41527 |    522.709339 | Fernando Carezzano                                                                                                                                                              |
| 156 |    1002.37781 |     17.057398 | Maija Karala                                                                                                                                                                    |
| 157 |      18.97460 |    532.525257 | Matt Crook                                                                                                                                                                      |
| 158 |      28.11938 |    421.864850 | Zimices                                                                                                                                                                         |
| 159 |     844.29986 |     77.203258 | Andrew A. Farke                                                                                                                                                                 |
| 160 |     978.38550 |    596.434351 | Tracy A. Heath                                                                                                                                                                  |
| 161 |     759.42173 |     55.959452 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 162 |     653.75848 |    450.945113 | Emily Jane McTavish                                                                                                                                                             |
| 163 |     586.62993 |    428.600568 | Michelle Site                                                                                                                                                                   |
| 164 |     637.59006 |    691.135363 | Birgit Lang                                                                                                                                                                     |
| 165 |     825.23979 |    640.349457 | Steven Traver                                                                                                                                                                   |
| 166 |     296.52287 |    674.719618 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 167 |     314.44051 |    568.171411 | Gareth Monger                                                                                                                                                                   |
| 168 |     999.61752 |    678.197021 | Katie S. Collins                                                                                                                                                                |
| 169 |     775.67105 |    610.110959 | Mathilde Cordellier                                                                                                                                                             |
| 170 |     567.61085 |    788.003111 | Jennifer Trimble                                                                                                                                                                |
| 171 |     253.42261 |    634.788330 | T. Michael Keesey (after Walker & al.)                                                                                                                                          |
| 172 |      41.66954 |    229.993777 | Peter Coxhead                                                                                                                                                                   |
| 173 |     330.89115 |    780.675183 | Sharon Wegner-Larsen                                                                                                                                                            |
| 174 |     965.14702 |     38.028833 | Francesca Belem Lopes Palmeira                                                                                                                                                  |
| 175 |     299.68197 |    485.726266 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                                        |
| 176 |     740.88628 |    330.006087 | Lukasiniho                                                                                                                                                                      |
| 177 |     293.32258 |    326.434020 | Oscar Sanisidro                                                                                                                                                                 |
| 178 |     831.52420 |    236.184246 | Fernando Campos De Domenico                                                                                                                                                     |
| 179 |     446.25224 |    338.498845 | Kamil S. Jaron                                                                                                                                                                  |
| 180 |     595.19298 |    724.672452 | Jagged Fang Designs                                                                                                                                                             |
| 181 |     244.21934 |    766.803278 | David Liao                                                                                                                                                                      |
| 182 |     144.08847 |    755.170527 | Gareth Monger                                                                                                                                                                   |
| 183 |     801.61589 |     37.937999 | Jagged Fang Designs                                                                                                                                                             |
| 184 |     333.95500 |      8.109118 | Roberto Díaz Sibaja                                                                                                                                                             |
| 185 |     594.80835 |    340.942982 | Alexandre Vong                                                                                                                                                                  |
| 186 |     602.65769 |    674.704432 | Roberto Díaz Sibaja                                                                                                                                                             |
| 187 |     279.22363 |    521.069609 | Smokeybjb                                                                                                                                                                       |
| 188 |     529.20640 |    722.035394 | Maija Karala                                                                                                                                                                    |
| 189 |     354.13283 |    269.325903 | NA                                                                                                                                                                              |
| 190 |    1008.09944 |    327.981157 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 191 |      33.25584 |    657.210274 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                                 |
| 192 |     384.83718 |     92.194526 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 193 |     718.68356 |    497.908900 | Ferran Sayol                                                                                                                                                                    |
| 194 |     239.87023 |    225.017552 | Margot Michaud                                                                                                                                                                  |
| 195 |      23.95063 |    123.705000 | Margot Michaud                                                                                                                                                                  |
| 196 |     399.93520 |     85.995229 | Gareth Monger                                                                                                                                                                   |
| 197 |     717.20449 |    417.741220 | Joanna Wolfe                                                                                                                                                                    |
| 198 |     115.21250 |    753.793302 | Tasman Dixon                                                                                                                                                                    |
| 199 |     678.28785 |    601.152699 | Melissa Broussard                                                                                                                                                               |
| 200 |     996.37017 |    547.250211 | Inessa Voet                                                                                                                                                                     |
| 201 |     906.53938 |    209.910404 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                           |
| 202 |      31.25526 |    705.592310 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 203 |     464.05433 |    624.606569 | NA                                                                                                                                                                              |
| 204 |     563.76466 |    608.349768 | Andrew A. Farke                                                                                                                                                                 |
| 205 |     552.69384 |    432.856112 | Gareth Monger                                                                                                                                                                   |
| 206 |     269.39497 |    260.430152 | Scott Reid                                                                                                                                                                      |
| 207 |     294.45218 |    286.888951 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 208 |     190.55345 |    790.124455 | Chris huh                                                                                                                                                                       |
| 209 |     173.49200 |    332.464913 | Jagged Fang Designs                                                                                                                                                             |
| 210 |     261.00768 |    675.800024 | Ferran Sayol                                                                                                                                                                    |
| 211 |     740.39775 |    177.217314 | Michelle Site                                                                                                                                                                   |
| 212 |     506.18524 |    146.524792 | Mathieu Basille                                                                                                                                                                 |
| 213 |     877.94973 |    378.924944 | Ferran Sayol                                                                                                                                                                    |
| 214 |     385.17743 |      5.962769 | Ieuan Jones                                                                                                                                                                     |
| 215 |     582.69325 |    306.794716 | NA                                                                                                                                                                              |
| 216 |     437.45450 |    304.778832 | Christoph Schomburg                                                                                                                                                             |
| 217 |     890.85319 |    608.002050 | Francesca Belem Lopes Palmeira                                                                                                                                                  |
| 218 |     150.09665 |    334.571131 | Scott Hartman                                                                                                                                                                   |
| 219 |     805.73588 |    612.100677 | Tasman Dixon                                                                                                                                                                    |
| 220 |     861.67810 |    375.736663 | T. Michael Keesey                                                                                                                                                               |
| 221 |     357.06937 |    607.776792 | Margot Michaud                                                                                                                                                                  |
| 222 |     920.52101 |    236.974784 | Matt Crook                                                                                                                                                                      |
| 223 |     461.36816 |    286.181931 | Chris huh                                                                                                                                                                       |
| 224 |     322.48055 |    545.882136 | Beth Reinke                                                                                                                                                                     |
| 225 |     887.92295 |    506.813841 | Margot Michaud                                                                                                                                                                  |
| 226 |     932.85483 |      4.581208 | Margot Michaud                                                                                                                                                                  |
| 227 |     333.45507 |    221.742609 | Ingo Braasch                                                                                                                                                                    |
| 228 |     678.68115 |    284.271209 | L. Shyamal                                                                                                                                                                      |
| 229 |    1001.52550 |    784.074766 | Matt Crook                                                                                                                                                                      |
| 230 |     130.24289 |    553.273823 | Gareth Monger                                                                                                                                                                   |
| 231 |     716.94834 |    140.282270 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                             |
| 232 |     450.15235 |    703.668436 | Matt Crook                                                                                                                                                                      |
| 233 |     804.27986 |    392.117934 | Pete Buchholz                                                                                                                                                                   |
| 234 |     695.53273 |    196.037730 | Matt Crook                                                                                                                                                                      |
| 235 |    1000.99836 |    424.977763 | T. Michael Keesey                                                                                                                                                               |
| 236 |    1006.29517 |    243.559590 | Margot Michaud                                                                                                                                                                  |
| 237 |     480.80543 |    346.877561 | Michelle Site                                                                                                                                                                   |
| 238 |     307.90169 |    526.966697 | Chris huh                                                                                                                                                                       |
| 239 |     981.33560 |    437.149445 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                           |
| 240 |     457.01308 |    217.855048 | Matt Crook                                                                                                                                                                      |
| 241 |     599.73888 |    360.808016 | Scott Hartman                                                                                                                                                                   |
| 242 |      54.13103 |     57.535150 | NA                                                                                                                                                                              |
| 243 |     681.59866 |    329.407444 | Carlos Cano-Barbacil                                                                                                                                                            |
| 244 |     569.64521 |    701.351497 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 245 |      17.04833 |    670.783523 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 246 |     111.59690 |     62.735748 | Jagged Fang Designs                                                                                                                                                             |
| 247 |     210.30142 |    522.025392 | Margot Michaud                                                                                                                                                                  |
| 248 |    1001.93268 |    396.271754 | Gareth Monger                                                                                                                                                                   |
| 249 |     896.96788 |    267.579758 | Scott Reid                                                                                                                                                                      |
| 250 |    1008.63509 |    257.022835 | Margot Michaud                                                                                                                                                                  |
| 251 |     454.67506 |    294.512934 | NA                                                                                                                                                                              |
| 252 |     322.80860 |     24.759265 | Juan Carlos Jerí                                                                                                                                                                |
| 253 |     973.50626 |    676.411820 | Iain Reid                                                                                                                                                                       |
| 254 |      55.17684 |    174.783049 | Dean Schnabel                                                                                                                                                                   |
| 255 |     655.65686 |    790.294407 | T. Michael Keesey                                                                                                                                                               |
| 256 |     544.95775 |    350.256518 | Zimices                                                                                                                                                                         |
| 257 |     936.93721 |    375.466137 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 258 |     577.98647 |    614.477827 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                         |
| 259 |     457.58576 |    380.210672 | Cristina Guijarro                                                                                                                                                               |
| 260 |     621.61301 |    749.687736 | Chase Brownstein                                                                                                                                                                |
| 261 |     542.06480 |    468.614020 | Scott Hartman                                                                                                                                                                   |
| 262 |     216.65568 |    238.107153 | L. Shyamal                                                                                                                                                                      |
| 263 |     539.89018 |    119.596138 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 264 |     156.43652 |    512.423132 | Jagged Fang Designs                                                                                                                                                             |
| 265 |     701.89599 |    762.265054 | Gareth Monger                                                                                                                                                                   |
| 266 |      62.21139 |     11.358287 | Steven Traver                                                                                                                                                                   |
| 267 |     430.20244 |    688.667684 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 268 |     376.46118 |    312.089940 | Chris huh                                                                                                                                                                       |
| 269 |     265.17589 |     13.451762 | Margot Michaud                                                                                                                                                                  |
| 270 |     796.95959 |    483.022559 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 271 |     566.35004 |    587.323754 | Chris huh                                                                                                                                                                       |
| 272 |     645.71864 |    594.464208 | Steven Traver                                                                                                                                                                   |
| 273 |     888.10607 |    625.074896 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                   |
| 274 |     400.59417 |    566.810736 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 275 |     288.30631 |    406.722000 | Verdilak                                                                                                                                                                        |
| 276 |     824.47075 |    795.967755 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 277 |     280.39613 |    599.914148 | Dean Schnabel                                                                                                                                                                   |
| 278 |     451.35994 |    444.646518 | Felix Vaux                                                                                                                                                                      |
| 279 |     729.50530 |    184.474018 | Kamil S. Jaron                                                                                                                                                                  |
| 280 |     349.75124 |    540.817764 | Zimices                                                                                                                                                                         |
| 281 |     264.72114 |     48.019293 | Markus A. Grohme                                                                                                                                                                |
| 282 |     167.44259 |     82.162342 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                           |
| 283 |     378.44814 |    286.861193 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 284 |     740.41774 |    374.545491 | Milton Tan                                                                                                                                                                      |
| 285 |     933.80199 |     84.056849 | Christoph Schomburg                                                                                                                                                             |
| 286 |     212.16236 |    465.228924 | Steven Traver                                                                                                                                                                   |
| 287 |     263.99565 |    328.388619 | Scott Hartman                                                                                                                                                                   |
| 288 |     401.39924 |    770.438464 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
| 289 |     570.85611 |    165.621617 | Scott Hartman                                                                                                                                                                   |
| 290 |     297.93466 |    105.609525 | Sarah Werning                                                                                                                                                                   |
| 291 |     728.77939 |     42.827390 | Ignacio Contreras                                                                                                                                                               |
| 292 |     207.88420 |    558.075871 | Jack Mayer Wood                                                                                                                                                                 |
| 293 |     554.05552 |    244.263552 | Renato de Carvalho Ferreira                                                                                                                                                     |
| 294 |     888.94214 |    485.662372 | Christoph Schomburg                                                                                                                                                             |
| 295 |     948.19856 |    333.745779 | Zimices / Julián Bayona                                                                                                                                                         |
| 296 |     990.20553 |      7.413976 | C. Abraczinskas                                                                                                                                                                 |
| 297 |      48.63255 |    753.353133 | Markus A. Grohme                                                                                                                                                                |
| 298 |     372.87940 |    466.524878 | Scott Hartman                                                                                                                                                                   |
| 299 |      17.78432 |     21.012750 | Zimices                                                                                                                                                                         |
| 300 |     283.94958 |     27.745096 | Zimices                                                                                                                                                                         |
| 301 |     369.83824 |     14.636924 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                                       |
| 302 |     433.87116 |    756.084071 | L. Shyamal                                                                                                                                                                      |
| 303 |     308.60399 |    647.254702 | Matt Crook                                                                                                                                                                      |
| 304 |    1009.23111 |    746.297536 | Emily Willoughby                                                                                                                                                                |
| 305 |     523.61278 |    574.380693 | NA                                                                                                                                                                              |
| 306 |     627.78742 |     80.769916 | Ville-Veikko Sinkkonen                                                                                                                                                          |
| 307 |     218.51708 |    148.701242 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 308 |     153.07247 |      8.158905 | Mattia Menchetti                                                                                                                                                                |
| 309 |     745.42652 |     61.835473 | Jagged Fang Designs                                                                                                                                                             |
| 310 |     407.75710 |    674.440508 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                                       |
| 311 |     420.84892 |    203.344153 | FunkMonk                                                                                                                                                                        |
| 312 |     769.52922 |    515.203279 | T. Michael Keesey                                                                                                                                                               |
| 313 |      18.75395 |    715.235417 | Chris huh                                                                                                                                                                       |
| 314 |     665.13379 |     79.871931 | Kamil S. Jaron                                                                                                                                                                  |
| 315 |     425.64186 |    504.199576 | NA                                                                                                                                                                              |
| 316 |     680.06129 |    576.741048 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                            |
| 317 |      29.18261 |     54.898244 | Michael Scroggie                                                                                                                                                                |
| 318 |     231.78641 |    158.153468 | Markus A. Grohme                                                                                                                                                                |
| 319 |      15.27571 |    445.544439 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                                   |
| 320 |     569.16625 |    339.765699 | Christoph Schomburg                                                                                                                                                             |
| 321 |      64.37002 |    394.373642 | Ingo Braasch                                                                                                                                                                    |
| 322 |     707.80040 |    124.742171 | Steven Traver                                                                                                                                                                   |
| 323 |     527.25567 |     31.360605 | Jagged Fang Designs                                                                                                                                                             |
| 324 |     796.11829 |     52.832591 | T. Tischler                                                                                                                                                                     |
| 325 |     656.60979 |    288.553863 | Tasman Dixon                                                                                                                                                                    |
| 326 |    1013.57921 |    356.297270 | T. Michael Keesey                                                                                                                                                               |
| 327 |     779.62952 |    694.542860 | Jagged Fang Designs                                                                                                                                                             |
| 328 |      49.56137 |    247.490662 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 329 |     865.77012 |    518.168996 | Andrew A. Farke                                                                                                                                                                 |
| 330 |     742.58791 |    714.958337 | NA                                                                                                                                                                              |
| 331 |     186.04894 |    253.100305 | Alexandra van der Geer                                                                                                                                                          |
| 332 |     862.18772 |     32.482641 | Margot Michaud                                                                                                                                                                  |
| 333 |     388.26015 |    650.562531 | Matt Dempsey                                                                                                                                                                    |
| 334 |     855.23233 |    625.082354 | Ignacio Contreras                                                                                                                                                               |
| 335 |      16.05991 |    782.153236 | Joedison Rocha                                                                                                                                                                  |
| 336 |     331.49066 |    393.906878 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 337 |     936.61422 |    495.482547 | Jaime Headden                                                                                                                                                                   |
| 338 |     530.54243 |    301.074631 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 339 |     675.42127 |    190.133476 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 340 |     808.42202 |    167.845419 | NA                                                                                                                                                                              |
| 341 |     868.00507 |    203.030502 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 342 |     497.52012 |    333.298750 | Smokeybjb                                                                                                                                                                       |
| 343 |     531.26077 |    679.246747 | Michele M Tobias                                                                                                                                                                |
| 344 |     476.03126 |    606.384851 | Rebecca Groom                                                                                                                                                                   |
| 345 |     156.73585 |    696.511194 | Jagged Fang Designs                                                                                                                                                             |
| 346 |     944.86944 |    475.781730 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 347 |     406.06807 |    464.528131 | Filip em                                                                                                                                                                        |
| 348 |     893.79352 |    223.873388 | Jaime Headden                                                                                                                                                                   |
| 349 |    1004.90264 |    272.465811 | Jagged Fang Designs                                                                                                                                                             |
| 350 |     157.37769 |    328.421069 | Jagged Fang Designs                                                                                                                                                             |
| 351 |     615.11017 |    450.691910 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 352 |     410.28694 |    616.435314 | Jaime Headden                                                                                                                                                                   |
| 353 |     644.45853 |     22.799479 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 354 |     942.98951 |    113.592814 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 355 |     378.25950 |    404.645225 | Gareth Monger                                                                                                                                                                   |
| 356 |     717.21657 |    326.144863 | Steven Traver                                                                                                                                                                   |
| 357 |     921.89177 |    197.743587 | Sarah Werning                                                                                                                                                                   |
| 358 |     467.18868 |     40.780285 | Henry Lydecker                                                                                                                                                                  |
| 359 |     563.07016 |    555.204273 | Andreas Hejnol                                                                                                                                                                  |
| 360 |     123.69933 |    461.679736 | G. M. Woodward                                                                                                                                                                  |
| 361 |     358.41247 |    743.980649 | Mason McNair                                                                                                                                                                    |
| 362 |     957.46127 |    115.905702 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                     |
| 363 |     675.68093 |    768.464731 | Birgit Lang                                                                                                                                                                     |
| 364 |     695.83490 |    483.434304 | Zimices                                                                                                                                                                         |
| 365 |     306.59652 |    382.377860 | Sarah Werning                                                                                                                                                                   |
| 366 |     368.43537 |    703.324619 | Matt Crook                                                                                                                                                                      |
| 367 |     745.95842 |    153.766056 | Scott Hartman                                                                                                                                                                   |
| 368 |      36.98375 |    445.515841 | Mathieu Basille                                                                                                                                                                 |
| 369 |      48.80988 |    670.169464 | Margot Michaud                                                                                                                                                                  |
| 370 |     156.50548 |    645.146537 | Felix Vaux                                                                                                                                                                      |
| 371 |     694.63488 |    730.807376 | Jagged Fang Designs                                                                                                                                                             |
| 372 |     791.54442 |    181.686374 | Jagged Fang Designs                                                                                                                                                             |
| 373 |     135.85364 |    480.028416 | Andrew A. Farke                                                                                                                                                                 |
| 374 |     740.01913 |    242.606813 | Ingo Braasch                                                                                                                                                                    |
| 375 |     496.03267 |    478.564330 | NA                                                                                                                                                                              |
| 376 |     139.32264 |    219.272594 | Sarah Werning                                                                                                                                                                   |
| 377 |     472.50746 |    524.526657 | Iain Reid                                                                                                                                                                       |
| 378 |     934.38586 |    673.614555 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                          |
| 379 |     324.67590 |    313.939882 | Chloé Schmidt                                                                                                                                                                   |
| 380 |     943.05878 |    738.050356 | Steven Traver                                                                                                                                                                   |
| 381 |     434.35123 |    364.896249 | Gareth Monger                                                                                                                                                                   |
| 382 |     730.30262 |    472.813967 | Mathew Wedel                                                                                                                                                                    |
| 383 |     236.69404 |    543.298624 | Armin Reindl                                                                                                                                                                    |
| 384 |     356.09524 |    525.335154 | Zimices                                                                                                                                                                         |
| 385 |     337.69935 |    708.586447 | Ignacio Contreras                                                                                                                                                               |
| 386 |     703.97894 |    796.054192 | Christoph Schomburg                                                                                                                                                             |
| 387 |     802.58095 |    298.169486 | Markus A. Grohme                                                                                                                                                                |
| 388 |     537.29532 |    662.971281 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                           |
| 389 |     485.13703 |      6.666309 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 390 |     444.09912 |    266.128054 | Neil Kelley                                                                                                                                                                     |
| 391 |     296.08763 |    466.429337 | Sarah Werning                                                                                                                                                                   |
| 392 |     336.73120 |    601.014812 | Gareth Monger                                                                                                                                                                   |
| 393 |     579.17929 |    683.937500 | Maija Karala                                                                                                                                                                    |
| 394 |     436.66552 |     12.977338 | Scott Hartman                                                                                                                                                                   |
| 395 |     411.35559 |     15.262420 | Markus A. Grohme                                                                                                                                                                |
| 396 |     542.86209 |    205.407470 | Chris huh                                                                                                                                                                       |
| 397 |      18.51750 |    328.085978 | NA                                                                                                                                                                              |
| 398 |     354.64960 |     26.945723 | Harold N Eyster                                                                                                                                                                 |
| 399 |     329.06316 |    272.510174 | Isaure Scavezzoni                                                                                                                                                               |
| 400 |     305.94744 |    118.920190 | Christoph Schomburg                                                                                                                                                             |
| 401 |     123.02905 |      8.918385 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 402 |     565.53455 |    292.200879 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 403 |     819.55537 |    369.129691 | Margot Michaud                                                                                                                                                                  |
| 404 |      20.42625 |    352.203360 | Jagged Fang Designs                                                                                                                                                             |
| 405 |     363.00091 |    138.078143 | Matt Celeskey                                                                                                                                                                   |
| 406 |     565.72074 |    376.070562 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 407 |     601.19809 |    269.189558 | Michael Scroggie                                                                                                                                                                |
| 408 |     526.06047 |     14.414665 | Matt Crook                                                                                                                                                                      |
| 409 |     194.61544 |      6.640395 | Tauana J. Cunha                                                                                                                                                                 |
| 410 |    1008.70434 |    565.544508 | Steven Traver                                                                                                                                                                   |
| 411 |     652.86247 |     68.093638 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                     |
| 412 |     417.79213 |    309.510883 | Scott Hartman                                                                                                                                                                   |
| 413 |     468.04469 |    162.369585 | Chris huh                                                                                                                                                                       |
| 414 |     405.81809 |     33.258567 | Jagged Fang Designs                                                                                                                                                             |
| 415 |     437.02955 |    606.252260 | Steven Traver                                                                                                                                                                   |
| 416 |     169.96922 |    786.168811 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 417 |     271.65601 |    537.454296 | Matt Dempsey                                                                                                                                                                    |
| 418 |      12.60888 |    107.503662 | Lauren Sumner-Rooney                                                                                                                                                            |
| 419 |     181.27487 |    116.551077 | Richard Ruggiero, vectorized by Zimices                                                                                                                                         |
| 420 |     869.71309 |    793.478779 | Tasman Dixon                                                                                                                                                                    |
| 421 |     473.20044 |     28.900923 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 422 |     138.12668 |    687.302551 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 423 |     168.34673 |     46.463975 | Tracy A. Heath                                                                                                                                                                  |
| 424 |     337.15686 |    751.836276 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                           |
| 425 |      82.97811 |    337.837114 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                      |
| 426 |     270.53073 |    633.084521 | Esme Ashe-Jepson                                                                                                                                                                |
| 427 |     584.46258 |    444.299792 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                  |
| 428 |     650.54300 |    529.623487 | Tasman Dixon                                                                                                                                                                    |
| 429 |      74.32426 |    650.969618 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                                 |
| 430 |     333.73935 |    335.236498 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                                  |
| 431 |     145.42786 |     98.589768 | Scott Hartman                                                                                                                                                                   |
| 432 |     699.39967 |    546.053838 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 433 |     660.46866 |    650.471954 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 434 |     380.60668 |    354.416150 | Steven Traver                                                                                                                                                                   |
| 435 |     959.06185 |    586.130033 | Pete Buchholz                                                                                                                                                                   |
| 436 |     797.39171 |    747.096290 | Roberto Díaz Sibaja                                                                                                                                                             |
| 437 |     265.20672 |    615.032139 | Zimices                                                                                                                                                                         |
| 438 |     115.63899 |    473.490393 | Jagged Fang Designs                                                                                                                                                             |
| 439 |      34.71415 |    782.387806 | Steven Coombs                                                                                                                                                                   |
| 440 |     983.05503 |     58.669056 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 441 |      66.88523 |    120.812100 | Scott Hartman                                                                                                                                                                   |
| 442 |     596.21912 |    709.096071 | SecretJellyMan                                                                                                                                                                  |
| 443 |     361.51110 |    296.206056 | Birgit Lang                                                                                                                                                                     |
| 444 |     913.78649 |    645.836667 | NA                                                                                                                                                                              |
| 445 |     601.47831 |     66.061202 | T. Michael Keesey                                                                                                                                                               |
| 446 |      70.80704 |    796.212556 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                  |
| 447 |     131.97754 |    103.715257 | Tasman Dixon                                                                                                                                                                    |
| 448 |     924.79409 |    417.686172 | Chris huh                                                                                                                                                                       |
| 449 |     801.95888 |    734.100502 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 450 |     383.94842 |     40.422033 | Margot Michaud                                                                                                                                                                  |
| 451 |      16.02577 |    248.401477 | Joanna Wolfe                                                                                                                                                                    |
| 452 |     526.42933 |    710.819175 | Matt Crook                                                                                                                                                                      |
| 453 |     529.50527 |    780.265325 | Yan Wong from photo by Denes Emoke                                                                                                                                              |
| 454 |     508.54103 |     67.651521 | Carlos Cano-Barbacil                                                                                                                                                            |
| 455 |     988.42960 |    304.707173 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                  |
| 456 |      50.87147 |    710.872101 | Markus A. Grohme                                                                                                                                                                |
| 457 |     904.08800 |    665.852437 | Steven Traver                                                                                                                                                                   |
| 458 |     647.77168 |    447.593884 | FunkMonk                                                                                                                                                                        |
| 459 |     971.20663 |    781.804214 | Jagged Fang Designs                                                                                                                                                             |
| 460 |     887.77009 |    713.439806 | Kai R. Caspar                                                                                                                                                                   |
| 461 |      13.53487 |    751.033682 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                               |
| 462 |     886.94766 |    355.487189 | Chloé Schmidt                                                                                                                                                                   |
| 463 |      10.40420 |    293.429600 | NA                                                                                                                                                                              |
| 464 |     236.85494 |    730.544739 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 465 |     551.48226 |    747.295438 | Michelle Site                                                                                                                                                                   |
| 466 |     594.49288 |    501.700693 | Chuanixn Yu                                                                                                                                                                     |
| 467 |      69.72709 |    214.637121 | Chris huh                                                                                                                                                                       |
| 468 |     791.17120 |    194.810512 | Jagged Fang Designs                                                                                                                                                             |
| 469 |     858.87408 |    715.477010 | Iain Reid                                                                                                                                                                       |
| 470 |     558.89709 |    694.234862 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 471 |     157.77342 |    303.496553 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 472 |     456.90966 |    356.752060 | Margot Michaud                                                                                                                                                                  |
| 473 |     672.96016 |     25.976471 | Gareth Monger                                                                                                                                                                   |
| 474 |     611.95426 |    346.792728 | Robert Gay                                                                                                                                                                      |
| 475 |     655.17972 |    311.169191 | Chris huh                                                                                                                                                                       |
| 476 |     768.83583 |    385.741336 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 477 |     288.07846 |    134.713446 | Steven Traver                                                                                                                                                                   |
| 478 |     842.85354 |    391.794268 | Zimices                                                                                                                                                                         |
| 479 |     749.17277 |    551.239692 | Joanna Wolfe                                                                                                                                                                    |
| 480 |     772.33131 |    232.642294 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 481 |     361.42597 |    787.014679 | Jaime Headden                                                                                                                                                                   |
| 482 |      20.67759 |    473.006170 | Scott Hartman                                                                                                                                                                   |
| 483 |     434.62958 |    194.992070 | Jack Mayer Wood                                                                                                                                                                 |
| 484 |      97.04531 |     15.376798 | Birgit Lang                                                                                                                                                                     |
| 485 |     328.45374 |    654.140829 | Markus A. Grohme                                                                                                                                                                |
| 486 |     539.37808 |    480.023367 | Christoph Schomburg                                                                                                                                                             |
| 487 |     567.72554 |    365.005457 | Margot Michaud                                                                                                                                                                  |
| 488 |      54.20967 |    534.904803 | Ferran Sayol                                                                                                                                                                    |
| 489 |     651.86076 |    757.715723 | Jagged Fang Designs                                                                                                                                                             |
| 490 |     278.09187 |    369.714995 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 491 |      12.69895 |    567.253882 | Oren Peles / vectorized by Yan Wong                                                                                                                                             |
| 492 |      17.73661 |    594.767603 | Tasman Dixon                                                                                                                                                                    |
| 493 |     427.62582 |     89.104342 | Dean Schnabel                                                                                                                                                                   |
| 494 |     289.63109 |    506.978996 | Maija Karala                                                                                                                                                                    |
| 495 |     143.50967 |    378.440827 | Sharon Wegner-Larsen                                                                                                                                                            |
| 496 |     740.24967 |    128.923823 | NA                                                                                                                                                                              |
| 497 |     898.93111 |    410.719073 | T. Michael Keesey                                                                                                                                                               |
| 498 |     678.62834 |     64.768171 | Markus A. Grohme                                                                                                                                                                |
| 499 |     570.96424 |    732.625138 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 500 |    1007.72905 |    589.011143 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                     |
| 501 |     295.09559 |      7.831552 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 502 |     429.21997 |    353.795597 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 503 |      95.66800 |     50.627669 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                         |
| 504 |     334.72593 |    570.934656 | wsnaccad                                                                                                                                                                        |
| 505 |     353.08767 |    650.941103 | Jack Mayer Wood                                                                                                                                                                 |
| 506 |    1007.67205 |    693.821259 | Sarah Werning                                                                                                                                                                   |
| 507 |     931.70773 |    262.793595 | NA                                                                                                                                                                              |
| 508 |     746.70913 |    595.281092 | Verdilak                                                                                                                                                                        |
| 509 |     315.42122 |    534.093595 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 510 |     791.41648 |    499.801510 | Iain Reid                                                                                                                                                                       |
| 511 |     161.61114 |    422.229263 | NA                                                                                                                                                                              |

    #> Your tweet has been posted!
