
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

Gareth Monger, Emily Willoughby, Zimices, David Orr, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Melissa Broussard, Mali’o Kodis,
photograph by Bruno Vellutini, Matt Crook, Scott Hartman, Katie S.
Collins, Lukasiniho, Margot Michaud, Steven Traver, Curtis Clark and T.
Michael Keesey, Christian A. Masnaghetti, Kai R. Caspar, Fernando
Carezzano, Rebecca Groom, Markus A. Grohme, Maija Karala, Birgit Szabo,
Beth Reinke, C. Camilo Julián-Caballero, Agnello Picorelli, T. Michael
Keesey (vectorization) and Larry Loos (photography), Julia B McHugh,
Jagged Fang Designs, Ignacio Contreras, Nobu Tamura (modified by T.
Michael Keesey), S.Martini, Michelle Site, Dmitry Bogdanov, T. Michael
Keesey, Meliponicultor Itaymbere, Oscar Sanisidro, Tasman Dixon, Andrew
A. Farke, Steven Coombs, Gabriela Palomo-Munoz, Yan Wong from wikipedia
drawing (PD: Pearson Scott Foresman), Jaime Headden, Julio Garza, Jack
Mayer Wood, Sarah Werning, Chloé Schmidt, Smokeybjb (vectorized by T.
Michael Keesey), Archaeodontosaurus (vectorized by T. Michael Keesey),
Caleb M. Gordon, Birgit Lang, Nobu Tamura (vectorized by T. Michael
Keesey), Ferran Sayol, T. Michael Keesey (photo by Darren Swim), Ewald
Rübsamen, L. Shyamal, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Xavier Giroux-Bougard, Didier Descouens (vectorized by
T. Michael Keesey), Robert Bruce Horsfall (vectorized by T. Michael
Keesey), Mattia Menchetti, Robert Gay, Collin Gross, Harold N Eyster,
Plukenet, T. Michael Keesey (photo by J. M. Garg), Crystal Maier, T.
Michael Keesey (vectorization) and Tony Hisgett (photography), Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Roberto Díaz Sibaja, Ellen Edmonson and
Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette), Leann
Biancani, photo by Kenneth Clifton, FunkMonk, Mason McNair, Joanna
Wolfe, FJDegrange, Kelly, Yan Wong, Kamil S. Jaron, Zimices, based in
Mauricio Antón skeletal, Chris huh, Tracy A. Heath, Mathew Wedel, Armin
Reindl, Robbie N. Cada (vectorized by T. Michael Keesey), T. K.
Robinson, George Edward Lodge, Mali’o Kodis, photograph by Melissa Frey,
Metalhead64 (vectorized by T. Michael Keesey), Jan A. Venter, Herbert H.
T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Darren Naish (vectorize by T. Michael Keesey), Terpsichores, M
Kolmann, , Jan Sevcik (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Geoff Shaw, Evan-Amos (vectorized by T.
Michael Keesey), Nobu Tamura (vectorized by A. Verrière), Matt
Martyniuk, Bill Bouton (source photo) & T. Michael Keesey
(vectorization), Michael Scroggie, Felix Vaux, Smokeybjb, Andy Wilson,
Tommaso Cancellario, Ville-Veikko Sinkkonen, xgirouxb, Rene Martin, Matt
Martyniuk (modified by Serenchia), Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Rainer Schoch, Stuart
Humphries, Mali’o Kodis, photograph by Hans Hillewaert, B. Duygu
Özpolat, CNZdenek, Conty (vectorized by T. Michael Keesey), Campbell
Fleming, Jose Carlos Arenas-Monroy, Christoph Schomburg, Kailah Thorn &
Mark Hutchinson, Cagri Cevrim, Arthur S. Brum, Matt Martyniuk
(vectorized by T. Michael Keesey), Steve Hillebrand/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization), A.
H. Baldwin (vectorized by T. Michael Keesey), Maxime Dahirel, Sean
McCann, Robert Bruce Horsfall, vectorized by Zimices, Martin Kevil,
Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Erika Schumacher, Isaure Scavezzoni, Anthony Caravaggi, Christine Axon,
Tambja (vectorized by T. Michael Keesey), Ron Holmes/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), E. J. Van
Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael
Keesey), Kimberly Haddrell, Pearson Scott Foresman (vectorized by T.
Michael Keesey), Jiekun He, T. Michael Keesey (after Kukalová), Eric
Moody, Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu,
Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey, Mali’o
Kodis, image by Rebecca Ritger, Andreas Hejnol, Amanda Katzer, Mike
Hanson, Stanton F. Fink (vectorized by T. Michael Keesey), Joe Schneid
(vectorized by T. Michael Keesey), Michael P. Taylor, Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Ghedo (vectorized by T. Michael Keesey), Scott D. Sampson, Mark
A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster,
Joshua A. Smith, Alan L. Titus, Pete Buchholz, Noah Schlottman, photo by
Casey Dunn, Arthur Weasley (vectorized by T. Michael Keesey), Mathieu
Pélissié, Cesar Julian, Matt Dempsey, Haplochromis (vectorized by T.
Michael Keesey), Antonov (vectorized by T. Michael Keesey), Ingo
Braasch, Iain Reid, Richard J. Harris, U.S. National Park Service
(vectorized by William Gearty), Scott Hartman (modified by T. Michael
Keesey), Smokeybjb (modified by Mike Keesey), Stephen O’Connor
(vectorized by T. Michael Keesey), Brad McFeeters (vectorized by T.
Michael Keesey), Alex Slavenko, James Neenan, Daniel Stadtmauer, Noah
Schlottman, photo from Casey Dunn, Tony Ayling (vectorized by T. Michael
Keesey), Ghedoghedo, vectorized by Zimices, DW Bapst (modified from
Bates et al., 2005), Tony Ayling (vectorized by Milton Tan), Mette
Aumala, Julie Blommaert based on photo by Sofdrakou, Ieuan Jones, Rafael
Maia, Mo Hassan, Sibi (vectorized by T. Michael Keesey), Lauren
Anderson, Noah Schlottman, photo by Adam G. Clause, Becky Barnes

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                     |
| --: | ------------: | ------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    313.980229 |    305.658152 | Gareth Monger                                                                                                                                              |
|   2 |    656.122239 |    466.878043 | Emily Willoughby                                                                                                                                           |
|   3 |    563.813548 |    335.397593 | Zimices                                                                                                                                                    |
|   4 |    916.805584 |    414.617554 | David Orr                                                                                                                                                  |
|   5 |    272.810420 |    741.777877 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                          |
|   6 |    569.737304 |    589.548706 | Melissa Broussard                                                                                                                                          |
|   7 |    528.331814 |    741.232396 | Zimices                                                                                                                                                    |
|   8 |    419.482097 |    195.559811 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                |
|   9 |    121.182628 |    717.592211 | Matt Crook                                                                                                                                                 |
|  10 |    934.340834 |    316.818404 | Scott Hartman                                                                                                                                              |
|  11 |    886.740592 |    162.332569 | Katie S. Collins                                                                                                                                           |
|  12 |    172.948001 |    563.007951 | Zimices                                                                                                                                                    |
|  13 |    513.225170 |    226.119556 | Lukasiniho                                                                                                                                                 |
|  14 |    868.970392 |    617.902669 | Margot Michaud                                                                                                                                             |
|  15 |    930.936361 |     55.559663 | Margot Michaud                                                                                                                                             |
|  16 |    140.696511 |    419.885428 | Steven Traver                                                                                                                                              |
|  17 |    447.388484 |    672.115067 | Curtis Clark and T. Michael Keesey                                                                                                                         |
|  18 |    297.996168 |    135.381457 | Margot Michaud                                                                                                                                             |
|  19 |    751.905521 |    409.629455 | NA                                                                                                                                                         |
|  20 |    664.214521 |    654.038402 | Christian A. Masnaghetti                                                                                                                                   |
|  21 |    466.671275 |    464.778830 | Matt Crook                                                                                                                                                 |
|  22 |    114.079802 |    291.334014 | Gareth Monger                                                                                                                                              |
|  23 |    745.452134 |    527.221681 | Kai R. Caspar                                                                                                                                              |
|  24 |    329.451862 |    381.072967 | Fernando Carezzano                                                                                                                                         |
|  25 |    684.924043 |    196.104607 | Rebecca Groom                                                                                                                                              |
|  26 |    695.586235 |    776.325411 | Markus A. Grohme                                                                                                                                           |
|  27 |     75.079042 |    227.610439 | Maija Karala                                                                                                                                               |
|  28 |    264.800982 |    458.157819 | Birgit Szabo                                                                                                                                               |
|  29 |    516.776397 |    114.247013 | Beth Reinke                                                                                                                                                |
|  30 |    780.364315 |    312.264482 | Matt Crook                                                                                                                                                 |
|  31 |     96.654971 |    177.094503 | C. Camilo Julián-Caballero                                                                                                                                 |
|  32 |     86.020083 |     68.654305 | Matt Crook                                                                                                                                                 |
|  33 |    245.179359 |    338.218477 | Agnello Picorelli                                                                                                                                          |
|  34 |    205.259530 |    342.136854 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                             |
|  35 |    305.441828 |    666.993962 | Julia B McHugh                                                                                                                                             |
|  36 |    706.106828 |    268.329810 | Jagged Fang Designs                                                                                                                                        |
|  37 |    306.178399 |     44.110928 | Ignacio Contreras                                                                                                                                          |
|  38 |    202.409525 |     93.819235 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                |
|  39 |    858.183704 |    736.402284 | Beth Reinke                                                                                                                                                |
|  40 |    722.268633 |    117.971786 | Beth Reinke                                                                                                                                                |
|  41 |    833.042765 |     72.356447 | S.Martini                                                                                                                                                  |
|  42 |    943.573504 |    521.755611 | Melissa Broussard                                                                                                                                          |
|  43 |    477.062271 |    544.121375 | Zimices                                                                                                                                                    |
|  44 |    862.369803 |    487.633760 | Michelle Site                                                                                                                                              |
|  45 |    955.740104 |    230.414623 | Dmitry Bogdanov                                                                                                                                            |
|  46 |     35.770110 |    489.621806 | T. Michael Keesey                                                                                                                                          |
|  47 |     55.117693 |    622.830275 | NA                                                                                                                                                         |
|  48 |    583.111568 |    405.380103 | C. Camilo Julián-Caballero                                                                                                                                 |
|  49 |    372.741306 |    460.124765 | Meliponicultor Itaymbere                                                                                                                                   |
|  50 |    733.796843 |    246.306895 | Jagged Fang Designs                                                                                                                                        |
|  51 |    350.787170 |    573.059961 | Steven Traver                                                                                                                                              |
|  52 |    622.810633 |    727.760720 | Margot Michaud                                                                                                                                             |
|  53 |    695.958758 |    579.951092 | Oscar Sanisidro                                                                                                                                            |
|  54 |    327.263279 |    217.964598 | Scott Hartman                                                                                                                                              |
|  55 |    403.476131 |    343.550117 | Steven Traver                                                                                                                                              |
|  56 |    465.759952 |     22.697293 | NA                                                                                                                                                         |
|  57 |    237.716265 |    210.182452 | Gareth Monger                                                                                                                                              |
|  58 |    144.467040 |    777.555444 | NA                                                                                                                                                         |
|  59 |    199.892076 |    484.255942 | Tasman Dixon                                                                                                                                               |
|  60 |    625.560373 |    512.444574 | Zimices                                                                                                                                                    |
|  61 |     94.247530 |    335.113967 | Andrew A. Farke                                                                                                                                            |
|  62 |    574.264075 |     63.004911 | Steven Coombs                                                                                                                                              |
|  63 |    957.252625 |    767.512047 | Gabriela Palomo-Munoz                                                                                                                                      |
|  64 |    417.853168 |    285.584465 | Tasman Dixon                                                                                                                                               |
|  65 |    895.075093 |    687.566292 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                               |
|  66 |    706.045460 |    300.563099 | Jaime Headden                                                                                                                                              |
|  67 |    390.929750 |     95.454368 | Julio Garza                                                                                                                                                |
|  68 |    975.475109 |    401.995087 | Michelle Site                                                                                                                                              |
|  69 |    564.835107 |    686.954234 | Jack Mayer Wood                                                                                                                                            |
|  70 |    733.023251 |     44.577471 | Sarah Werning                                                                                                                                              |
|  71 |    724.358347 |    685.286744 | Chloé Schmidt                                                                                                                                              |
|  72 |    439.404080 |    785.571013 | Matt Crook                                                                                                                                                 |
|  73 |     86.955762 |    142.718937 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                |
|  74 |    950.371255 |    114.508807 | T. Michael Keesey                                                                                                                                          |
|  75 |    190.773724 |    260.314821 | Andrew A. Farke                                                                                                                                            |
|  76 |    909.089087 |    495.125461 | NA                                                                                                                                                         |
|  77 |    989.211705 |    134.137010 | Scott Hartman                                                                                                                                              |
|  78 |     23.225233 |    699.905509 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                       |
|  79 |    512.282586 |    627.022777 | Caleb M. Gordon                                                                                                                                            |
|  80 |    393.793402 |    536.497008 | Jagged Fang Designs                                                                                                                                        |
|  81 |    541.254252 |    467.889396 | Gareth Monger                                                                                                                                              |
|  82 |    829.470051 |    351.105935 | Rebecca Groom                                                                                                                                              |
|  83 |    397.939429 |    738.866500 | Christian A. Masnaghetti                                                                                                                                   |
|  84 |    655.651064 |    609.571184 | Birgit Lang                                                                                                                                                |
|  85 |    970.367533 |    584.626466 | Beth Reinke                                                                                                                                                |
|  86 |    249.249317 |    517.766435 | NA                                                                                                                                                         |
|  87 |    562.545416 |     34.402936 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                              |
|  88 |    194.002453 |     13.858916 | Birgit Lang                                                                                                                                                |
|  89 |    962.125393 |    675.900064 | NA                                                                                                                                                         |
|  90 |    792.148165 |    177.056284 | Ferran Sayol                                                                                                                                               |
|  91 |    429.585193 |    742.115302 | Markus A. Grohme                                                                                                                                           |
|  92 |    426.460926 |    421.628881 | Steven Traver                                                                                                                                              |
|  93 |    366.069435 |    649.759662 | NA                                                                                                                                                         |
|  94 |    393.961329 |    699.094587 | T. Michael Keesey (photo by Darren Swim)                                                                                                                   |
|  95 |    486.222613 |    398.082678 | Zimices                                                                                                                                                    |
|  96 |    252.009365 |    778.240038 | Ewald Rübsamen                                                                                                                                             |
|  97 |    711.058628 |    742.188336 | Melissa Broussard                                                                                                                                          |
|  98 |    323.845692 |    248.227002 | L. Shyamal                                                                                                                                                 |
|  99 |    856.080655 |    225.706861 | Matt Crook                                                                                                                                                 |
| 100 |    504.149334 |    144.178484 | Tasman Dixon                                                                                                                                               |
| 101 |    455.995286 |    171.876483 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                            |
| 102 |    445.015626 |    525.140940 | Xavier Giroux-Bougard                                                                                                                                      |
| 103 |   1002.206401 |    704.225349 | Margot Michaud                                                                                                                                             |
| 104 |     52.147785 |    375.003469 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                         |
| 105 |    563.429908 |    785.004820 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                    |
| 106 |    116.748579 |    682.617313 | Ferran Sayol                                                                                                                                               |
| 107 |     49.505609 |    415.397072 | Matt Crook                                                                                                                                                 |
| 108 |    335.832880 |     24.498158 | Mattia Menchetti                                                                                                                                           |
| 109 |    140.340901 |    495.390399 | Robert Gay                                                                                                                                                 |
| 110 |     88.106396 |    434.074867 | Collin Gross                                                                                                                                               |
| 111 |    304.609324 |    318.315935 | Harold N Eyster                                                                                                                                            |
| 112 |    608.120783 |     22.840891 | Plukenet                                                                                                                                                   |
| 113 |    170.995054 |    192.365433 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                    |
| 114 |    976.163027 |    171.464446 | NA                                                                                                                                                         |
| 115 |    358.565931 |    175.180574 | Birgit Lang                                                                                                                                                |
| 116 |    188.613289 |     39.379265 | Collin Gross                                                                                                                                               |
| 117 |    379.131255 |     34.666221 | Steven Traver                                                                                                                                              |
| 118 |    889.171536 |    564.792117 | Collin Gross                                                                                                                                               |
| 119 |    117.862484 |    651.189206 | Crystal Maier                                                                                                                                              |
| 120 |    121.883318 |    363.884445 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                           |
| 121 |    995.142072 |    552.526767 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                 |
| 122 |    539.274172 |    571.093910 | Roberto Díaz Sibaja                                                                                                                                        |
| 123 |    592.589875 |    478.837368 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                          |
| 124 |    588.014629 |    178.105046 | Leann Biancani, photo by Kenneth Clifton                                                                                                                   |
| 125 |    806.806688 |    463.294362 | FunkMonk                                                                                                                                                   |
| 126 |    140.620640 |    521.721845 | Matt Crook                                                                                                                                                 |
| 127 |    583.745544 |     13.959956 | T. Michael Keesey                                                                                                                                          |
| 128 |    906.400854 |    551.314319 | Gareth Monger                                                                                                                                              |
| 129 |    177.981750 |    144.273675 | Emily Willoughby                                                                                                                                           |
| 130 |    489.666521 |    356.513955 | Gabriela Palomo-Munoz                                                                                                                                      |
| 131 |    147.869630 |    374.134032 | Ferran Sayol                                                                                                                                               |
| 132 |    225.770546 |     36.632975 | Mason McNair                                                                                                                                               |
| 133 |    738.914677 |    466.024817 | Scott Hartman                                                                                                                                              |
| 134 |     78.195047 |    465.521384 | Ferran Sayol                                                                                                                                               |
| 135 |    812.309134 |    326.330108 | NA                                                                                                                                                         |
| 136 |    347.607710 |    141.506336 | Scott Hartman                                                                                                                                              |
| 137 |    842.466232 |    783.651730 | T. Michael Keesey                                                                                                                                          |
| 138 |    332.744949 |    192.520599 | Crystal Maier                                                                                                                                              |
| 139 |   1009.206472 |     56.302505 | Joanna Wolfe                                                                                                                                               |
| 140 |    637.236184 |     25.046661 | Margot Michaud                                                                                                                                             |
| 141 |     31.245294 |    113.536828 | Ferran Sayol                                                                                                                                               |
| 142 |    984.534529 |    545.232817 | Matt Crook                                                                                                                                                 |
| 143 |    539.833638 |    162.075129 | Scott Hartman                                                                                                                                              |
| 144 |    155.191438 |    120.171660 | FJDegrange                                                                                                                                                 |
| 145 |   1016.510611 |    326.948004 | Kelly                                                                                                                                                      |
| 146 |    608.785027 |    577.182611 | Steven Traver                                                                                                                                              |
| 147 |    368.714973 |    252.442531 | Joanna Wolfe                                                                                                                                               |
| 148 |    206.330343 |    547.285097 | Yan Wong                                                                                                                                                   |
| 149 |    646.687614 |     86.511751 | Matt Crook                                                                                                                                                 |
| 150 |    957.722929 |    465.648601 | Kamil S. Jaron                                                                                                                                             |
| 151 |    816.235446 |    173.654323 | NA                                                                                                                                                         |
| 152 |    796.836475 |    117.092705 | Ferran Sayol                                                                                                                                               |
| 153 |    231.080806 |    535.026883 | Zimices, based in Mauricio Antón skeletal                                                                                                                  |
| 154 |    439.489235 |     63.275659 | Andrew A. Farke                                                                                                                                            |
| 155 |    607.336375 |    230.513814 | Tasman Dixon                                                                                                                                               |
| 156 |    997.425077 |    343.647464 | Chris huh                                                                                                                                                  |
| 157 |    175.150618 |    226.920347 | Julio Garza                                                                                                                                                |
| 158 |    631.287910 |    270.105808 | Jagged Fang Designs                                                                                                                                        |
| 159 |    561.986352 |    450.866665 | Zimices                                                                                                                                                    |
| 160 |    276.411694 |    573.462632 | Tracy A. Heath                                                                                                                                             |
| 161 |    538.841567 |    662.645700 | Mathew Wedel                                                                                                                                               |
| 162 |    239.748926 |     60.278533 | Armin Reindl                                                                                                                                               |
| 163 |    322.869072 |    764.331935 | Mattia Menchetti                                                                                                                                           |
| 164 |    653.814795 |    762.838895 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                           |
| 165 |    462.606171 |    254.028549 | Gareth Monger                                                                                                                                              |
| 166 |    646.853721 |    122.409492 | T. K. Robinson                                                                                                                                             |
| 167 |    414.381426 |     36.098234 | George Edward Lodge                                                                                                                                        |
| 168 |    535.319037 |    642.204699 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                   |
| 169 |    915.572821 |     13.987326 | Chris huh                                                                                                                                                  |
| 170 |    328.845696 |    432.204395 | Margot Michaud                                                                                                                                             |
| 171 |     16.103813 |    113.486738 | Jagged Fang Designs                                                                                                                                        |
| 172 |     20.847476 |    275.528693 | Matt Crook                                                                                                                                                 |
| 173 |    769.641718 |    793.473572 | Gareth Monger                                                                                                                                              |
| 174 |     28.668361 |    774.091197 | Julio Garza                                                                                                                                                |
| 175 |    450.792187 |    599.230607 | Zimices                                                                                                                                                    |
| 176 |    429.931424 |    768.562482 | Margot Michaud                                                                                                                                             |
| 177 |    779.429833 |    702.335508 | Zimices                                                                                                                                                    |
| 178 |    406.099144 |    140.562762 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                              |
| 179 |    776.082440 |    263.125036 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                        |
| 180 |    987.747391 |     30.312416 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                              |
| 181 |    851.425108 |    543.189293 | Terpsichores                                                                                                                                               |
| 182 |    967.916970 |    233.733523 | Matt Crook                                                                                                                                                 |
| 183 |    404.759232 |    570.014295 | Jagged Fang Designs                                                                                                                                        |
| 184 |    428.100673 |    200.870559 | Ferran Sayol                                                                                                                                               |
| 185 |    617.036995 |    151.843862 | M Kolmann                                                                                                                                                  |
| 186 |     18.890201 |    332.113276 | T. Michael Keesey                                                                                                                                          |
| 187 |   1000.038212 |    357.712539 |                                                                                                                                                            |
| 188 |    603.770106 |    658.843515 | Jagged Fang Designs                                                                                                                                        |
| 189 |    394.678411 |     59.437246 | Zimices                                                                                                                                                    |
| 190 |    937.896688 |    453.255950 | Gabriela Palomo-Munoz                                                                                                                                      |
| 191 |    680.600364 |     58.221895 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 192 |    976.784009 |    297.512038 | Matt Crook                                                                                                                                                 |
| 193 |    323.309159 |     67.215128 | Geoff Shaw                                                                                                                                                 |
| 194 |    781.771319 |    211.791983 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                |
| 195 |    913.681650 |     97.051033 | T. Michael Keesey                                                                                                                                          |
| 196 |     40.461660 |    739.054986 | Lukasiniho                                                                                                                                                 |
| 197 |    336.150865 |    505.487743 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                    |
| 198 |     44.516453 |    283.921923 | Matt Martyniuk                                                                                                                                             |
| 199 |    149.642327 |    337.969703 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                             |
| 200 |    876.544434 |    417.036291 | Michael Scroggie                                                                                                                                           |
| 201 |    422.066977 |    450.891306 | Felix Vaux                                                                                                                                                 |
| 202 |    682.855081 |    748.118538 | Steven Traver                                                                                                                                              |
| 203 |    931.045777 |    429.420472 | Michelle Site                                                                                                                                              |
| 204 |   1002.692572 |    632.312556 | T. Michael Keesey                                                                                                                                          |
| 205 |    775.215273 |    762.196075 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                           |
| 206 |    540.746607 |     16.270806 | Gareth Monger                                                                                                                                              |
| 207 |    797.093581 |    656.748246 | Markus A. Grohme                                                                                                                                           |
| 208 |    505.951941 |    587.397281 | Smokeybjb                                                                                                                                                  |
| 209 |    158.871475 |    483.853238 | Joanna Wolfe                                                                                                                                               |
| 210 |    241.176593 |    641.735362 | Gareth Monger                                                                                                                                              |
| 211 |    309.597180 |    347.227897 | Chris huh                                                                                                                                                  |
| 212 |    899.108072 |    351.313168 | Andy Wilson                                                                                                                                                |
| 213 |    877.775381 |    764.659665 | Tommaso Cancellario                                                                                                                                        |
| 214 |    608.370547 |    552.495724 | Zimices                                                                                                                                                    |
| 215 |    689.209183 |    362.570551 | C. Camilo Julián-Caballero                                                                                                                                 |
| 216 |    245.477768 |    491.001916 | Yan Wong                                                                                                                                                   |
| 217 |    719.027685 |    632.802471 | Steven Coombs                                                                                                                                              |
| 218 |    288.187754 |    178.569031 | Zimices                                                                                                                                                    |
| 219 |    957.017765 |    194.928450 | NA                                                                                                                                                         |
| 220 |    664.813893 |    499.595712 | Lukasiniho                                                                                                                                                 |
| 221 |    598.069178 |    267.714530 | Beth Reinke                                                                                                                                                |
| 222 |    380.624548 |    235.174709 | Ville-Veikko Sinkkonen                                                                                                                                     |
| 223 |     26.232427 |    196.336956 | Steven Traver                                                                                                                                              |
| 224 |    820.621512 |    786.438628 | xgirouxb                                                                                                                                                   |
| 225 |    751.280393 |    231.055348 | Rene Martin                                                                                                                                                |
| 226 |   1006.104061 |    512.976647 | Zimices                                                                                                                                                    |
| 227 |    421.466185 |    394.621875 | Matt Martyniuk (modified by Serenchia)                                                                                                                     |
| 228 |    820.887074 |    554.081341 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 229 |     26.144229 |     23.728974 | Rainer Schoch                                                                                                                                              |
| 230 |     71.106653 |    698.468804 | Stuart Humphries                                                                                                                                           |
| 231 |    128.619338 |    607.473905 | Steven Traver                                                                                                                                              |
| 232 |    983.686598 |    650.118343 | Steven Traver                                                                                                                                              |
| 233 |    683.183226 |    149.157599 | Emily Willoughby                                                                                                                                           |
| 234 |    266.895001 |     15.544543 | Chris huh                                                                                                                                                  |
| 235 |    112.263463 |    794.803103 | Armin Reindl                                                                                                                                               |
| 236 |    444.837227 |    228.343839 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                |
| 237 |    700.949734 |    149.578836 | Margot Michaud                                                                                                                                             |
| 238 |    322.565458 |    639.273617 | B. Duygu Özpolat                                                                                                                                           |
| 239 |    882.702499 |    253.152646 | Kamil S. Jaron                                                                                                                                             |
| 240 |     19.969914 |    141.921622 | CNZdenek                                                                                                                                                   |
| 241 |    899.889733 |    474.373937 | Zimices                                                                                                                                                    |
| 242 |    830.037176 |    257.844127 | Conty (vectorized by T. Michael Keesey)                                                                                                                    |
| 243 |   1013.304850 |    395.447797 | Chloé Schmidt                                                                                                                                              |
| 244 |    998.576522 |    214.081548 | Campbell Fleming                                                                                                                                           |
| 245 |    213.500247 |    233.509764 | Margot Michaud                                                                                                                                             |
| 246 |    623.215336 |    786.152325 | Margot Michaud                                                                                                                                             |
| 247 |    187.558915 |    652.218062 | Jose Carlos Arenas-Monroy                                                                                                                                  |
| 248 |    491.457446 |    488.670247 | Margot Michaud                                                                                                                                             |
| 249 |    422.249218 |    615.174580 | Christoph Schomburg                                                                                                                                        |
| 250 |    319.898289 |    621.490447 | Matt Crook                                                                                                                                                 |
| 251 |    196.145778 |    738.299060 | Margot Michaud                                                                                                                                             |
| 252 |    228.964392 |    674.934286 | Kailah Thorn & Mark Hutchinson                                                                                                                             |
| 253 |    784.524065 |    783.901065 | Markus A. Grohme                                                                                                                                           |
| 254 |    152.320017 |     50.301146 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                               |
| 255 |     27.062771 |    558.047144 | Zimices                                                                                                                                                    |
| 256 |    314.355141 |    449.428219 | Yan Wong                                                                                                                                                   |
| 257 |    827.605271 |    699.550981 | Cagri Cevrim                                                                                                                                               |
| 258 |     48.647262 |    786.396941 | Margot Michaud                                                                                                                                             |
| 259 |    759.258903 |    287.580539 | Markus A. Grohme                                                                                                                                           |
| 260 |    589.263505 |    771.147451 | S.Martini                                                                                                                                                  |
| 261 |    152.804131 |    208.149516 | T. Michael Keesey                                                                                                                                          |
| 262 |     64.449147 |    200.355546 | Margot Michaud                                                                                                                                             |
| 263 |    581.256532 |    699.759899 | Andy Wilson                                                                                                                                                |
| 264 |    787.483331 |     20.634654 | S.Martini                                                                                                                                                  |
| 265 |    205.566572 |    290.311172 | Scott Hartman                                                                                                                                              |
| 266 |    342.684797 |    690.742735 | Arthur S. Brum                                                                                                                                             |
| 267 |    726.034483 |    612.601325 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                           |
| 268 |    392.520171 |    115.088313 | Chris huh                                                                                                                                                  |
| 269 |    879.387479 |    199.110183 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                         |
| 270 |     74.083484 |    267.784519 | Markus A. Grohme                                                                                                                                           |
| 271 |    734.617129 |    489.386950 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                            |
| 272 |     86.004198 |    569.762265 | Maxime Dahirel                                                                                                                                             |
| 273 |    103.018761 |    599.870609 | NA                                                                                                                                                         |
| 274 |    857.553630 |    121.090264 | Chris huh                                                                                                                                                  |
| 275 |    789.014706 |    537.594108 | Jagged Fang Designs                                                                                                                                        |
| 276 |    464.536648 |    274.451637 | Sean McCann                                                                                                                                                |
| 277 |    223.289256 |    787.983652 | Steven Traver                                                                                                                                              |
| 278 |    767.276189 |    354.854792 | Zimices                                                                                                                                                    |
| 279 |    277.091610 |    627.415357 | Mattia Menchetti                                                                                                                                           |
| 280 |     12.549818 |    207.197958 | Michelle Site                                                                                                                                              |
| 281 |    862.849365 |    300.129581 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                               |
| 282 |    354.978413 |    157.303163 |                                                                                                                                                            |
| 283 |    691.678540 |    790.278473 | Martin Kevil                                                                                                                                               |
| 284 |     26.433554 |    399.990824 | Andrew A. Farke                                                                                                                                            |
| 285 |    458.549278 |     46.774129 | Beth Reinke                                                                                                                                                |
| 286 |    815.248197 |    231.689194 | Mathew Wedel                                                                                                                                               |
| 287 |     97.443174 |    476.593356 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                |
| 288 |    615.941614 |    252.544697 | Gabriela Palomo-Munoz                                                                                                                                      |
| 289 |    242.917347 |    180.621660 | Erika Schumacher                                                                                                                                           |
| 290 |    289.192800 |     78.782685 | Dmitry Bogdanov                                                                                                                                            |
| 291 |    844.131392 |    376.370011 | T. Michael Keesey                                                                                                                                          |
| 292 |    159.128592 |     21.436602 | Isaure Scavezzoni                                                                                                                                          |
| 293 |    997.921245 |    576.158663 | Birgit Lang                                                                                                                                                |
| 294 |    100.378923 |    657.729780 | T. Michael Keesey                                                                                                                                          |
| 295 |    757.264865 |    181.781749 | Anthony Caravaggi                                                                                                                                          |
| 296 |    574.303153 |    427.627723 | Scott Hartman                                                                                                                                              |
| 297 |    849.748784 |    274.390216 | NA                                                                                                                                                         |
| 298 |    917.814839 |    732.023762 | Chris huh                                                                                                                                                  |
| 299 |    211.302416 |    624.996485 | Christine Axon                                                                                                                                             |
| 300 |    832.223600 |    450.888140 | NA                                                                                                                                                         |
| 301 |    161.505989 |    735.757476 | Tambja (vectorized by T. Michael Keesey)                                                                                                                   |
| 302 |    900.074359 |    574.871317 | T. Michael Keesey                                                                                                                                          |
| 303 |    838.648705 |    173.059908 | NA                                                                                                                                                         |
| 304 |    916.134308 |    334.552888 | Michelle Site                                                                                                                                              |
| 305 |    551.674208 |    518.063517 | Tracy A. Heath                                                                                                                                             |
| 306 |    523.662149 |    766.629608 | NA                                                                                                                                                         |
| 307 |   1006.348203 |    172.795642 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                 |
| 308 |    378.777728 |    137.400411 | Matt Crook                                                                                                                                                 |
| 309 |   1002.338584 |    146.107848 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                               |
| 310 |    349.488462 |    781.882735 | Michael Scroggie                                                                                                                                           |
| 311 |   1014.197771 |    475.183159 | Ferran Sayol                                                                                                                                               |
| 312 |    714.378848 |     17.867180 | T. Michael Keesey                                                                                                                                          |
| 313 |    740.435329 |    314.991776 | Zimices                                                                                                                                                    |
| 314 |    280.716966 |    332.343160 | Meliponicultor Itaymbere                                                                                                                                   |
| 315 |    950.827736 |     96.250307 | C. Camilo Julián-Caballero                                                                                                                                 |
| 316 |    143.667906 |    223.241111 | Melissa Broussard                                                                                                                                          |
| 317 |    880.655809 |    549.379063 | Zimices                                                                                                                                                    |
| 318 |    896.735988 |    410.532654 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                   |
| 319 |    521.950501 |     38.548598 | xgirouxb                                                                                                                                                   |
| 320 |     51.479126 |    702.115167 | Terpsichores                                                                                                                                               |
| 321 |    608.093358 |    765.969140 | Gabriela Palomo-Munoz                                                                                                                                      |
| 322 |    392.789668 |    758.511646 | C. Camilo Julián-Caballero                                                                                                                                 |
| 323 |    941.867539 |    135.555675 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                       |
| 324 |    273.727922 |    272.426909 | Kimberly Haddrell                                                                                                                                          |
| 325 |    737.411373 |    795.213451 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                   |
| 326 |    904.443998 |    743.505527 | Smokeybjb                                                                                                                                                  |
| 327 |    590.913281 |    373.212826 | Andy Wilson                                                                                                                                                |
| 328 |    872.059473 |    785.723499 | Markus A. Grohme                                                                                                                                           |
| 329 |    761.389552 |    479.930980 | Erika Schumacher                                                                                                                                           |
| 330 |    371.220107 |     68.639688 | Jiekun He                                                                                                                                                  |
| 331 |    217.579638 |    281.556979 | Christoph Schomburg                                                                                                                                        |
| 332 |    913.334724 |    699.024494 | Scott Hartman                                                                                                                                              |
| 333 |    746.881946 |    727.050357 | Margot Michaud                                                                                                                                             |
| 334 |    698.231522 |    454.178340 | Gabriela Palomo-Munoz                                                                                                                                      |
| 335 |    183.608621 |     54.847298 | Jose Carlos Arenas-Monroy                                                                                                                                  |
| 336 |    926.325600 |    561.074131 | T. Michael Keesey (after Kukalová)                                                                                                                         |
| 337 |     40.272177 |    306.151327 | Eric Moody                                                                                                                                                 |
| 338 |    326.866734 |    414.723602 | Scott Hartman                                                                                                                                              |
| 339 |    677.940321 |     10.873858 | Chris huh                                                                                                                                                  |
| 340 |    789.099132 |    687.452573 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                |
| 341 |     62.337755 |    190.614700 | NA                                                                                                                                                         |
| 342 |    169.364241 |    498.714800 | Chris huh                                                                                                                                                  |
| 343 |    191.276094 |    533.375579 | Emily Willoughby                                                                                                                                           |
| 344 |     13.374093 |    437.837659 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                      |
| 345 |    635.235566 |    423.720153 | NA                                                                                                                                                         |
| 346 |    743.282347 |    752.347626 | Andreas Hejnol                                                                                                                                             |
| 347 |    516.358609 |    497.252033 | Margot Michaud                                                                                                                                             |
| 348 |    824.990678 |     15.817559 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                          |
| 349 |    322.004425 |    745.368438 | Amanda Katzer                                                                                                                                              |
| 350 |    840.496436 |    329.462543 | Zimices                                                                                                                                                    |
| 351 |     82.171072 |    598.005803 | Mike Hanson                                                                                                                                                |
| 352 |     16.059322 |     68.920935 | NA                                                                                                                                                         |
| 353 |    134.264741 |    194.441884 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                          |
| 354 |    567.244419 |    145.436572 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                              |
| 355 |    449.130078 |    756.833068 | Zimices                                                                                                                                                    |
| 356 |     20.989590 |    751.584277 | Gareth Monger                                                                                                                                              |
| 357 |    825.413269 |    218.791718 | Jagged Fang Designs                                                                                                                                        |
| 358 |    388.612706 |    620.639118 | Michael P. Taylor                                                                                                                                          |
| 359 |    909.257224 |    790.206739 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                     |
| 360 |      8.565059 |    591.623834 | T. Michael Keesey                                                                                                                                          |
| 361 |    151.307149 |     31.755096 | Jagged Fang Designs                                                                                                                                        |
| 362 |    884.242428 |    437.413785 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 363 |     74.756823 |    586.658983 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                   |
| 364 |     86.237457 |    500.977513 | NA                                                                                                                                                         |
| 365 |    376.325883 |    555.239982 | Pete Buchholz                                                                                                                                              |
| 366 |    999.481165 |    198.205148 | Noah Schlottman, photo by Casey Dunn                                                                                                                       |
| 367 |    912.175120 |    290.682434 | Jagged Fang Designs                                                                                                                                        |
| 368 |    651.158660 |    574.040587 | Tasman Dixon                                                                                                                                               |
| 369 |    879.724096 |    286.599026 | NA                                                                                                                                                         |
| 370 |    683.346533 |    160.997399 | Scott Hartman                                                                                                                                              |
| 371 |    771.230642 |    465.332168 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                          |
| 372 |    865.896144 |     24.223243 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                           |
| 373 |    635.076918 |    140.027664 | Chris huh                                                                                                                                                  |
| 374 |    325.764886 |    789.010895 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                          |
| 375 |    345.214201 |    323.421944 | Gabriela Palomo-Munoz                                                                                                                                      |
| 376 |     77.767803 |    385.506201 | Beth Reinke                                                                                                                                                |
| 377 |   1006.019403 |    291.575928 | Chris huh                                                                                                                                                  |
| 378 |    989.214944 |    474.311731 | Ferran Sayol                                                                                                                                               |
| 379 |    264.502479 |     72.184446 | Ferran Sayol                                                                                                                                               |
| 380 |    589.010151 |    451.310263 | Mathieu Pélissié                                                                                                                                           |
| 381 |    510.260033 |    169.206354 | Cesar Julian                                                                                                                                               |
| 382 |     33.570917 |    255.828728 | Gareth Monger                                                                                                                                              |
| 383 |    157.622769 |    533.994041 | NA                                                                                                                                                         |
| 384 |    241.863761 |    555.486430 | Andy Wilson                                                                                                                                                |
| 385 |    437.612635 |    128.554239 | Matt Dempsey                                                                                                                                               |
| 386 |    786.106729 |    638.257551 | Michelle Site                                                                                                                                              |
| 387 |    338.849879 |      5.163916 | Chris huh                                                                                                                                                  |
| 388 |    764.378576 |    204.589556 | Andy Wilson                                                                                                                                                |
| 389 |    746.399198 |     19.256305 | Michelle Site                                                                                                                                              |
| 390 |    804.984279 |    440.227049 | Gareth Monger                                                                                                                                              |
| 391 |    350.790455 |    519.495083 | Tasman Dixon                                                                                                                                               |
| 392 |     64.161881 |    773.429313 | Sarah Werning                                                                                                                                              |
| 393 |    657.663721 |    794.258520 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                             |
| 394 |     18.466842 |    663.277325 | Tasman Dixon                                                                                                                                               |
| 395 |    335.295168 |    346.320315 | Margot Michaud                                                                                                                                             |
| 396 |    208.675104 |    244.325506 | Chris huh                                                                                                                                                  |
| 397 |    998.549810 |     90.791193 | Zimices                                                                                                                                                    |
| 398 |    376.915761 |    199.058632 | Antonov (vectorized by T. Michael Keesey)                                                                                                                  |
| 399 |    688.578907 |    337.393784 | Zimices                                                                                                                                                    |
| 400 |    822.069064 |    676.513918 | Gareth Monger                                                                                                                                              |
| 401 |    361.166069 |    712.930367 | Ingo Braasch                                                                                                                                               |
| 402 |    960.191969 |    563.152560 | Iain Reid                                                                                                                                                  |
| 403 |    753.054481 |    644.416311 | Steven Traver                                                                                                                                              |
| 404 |    159.957364 |    309.731946 | Scott Hartman                                                                                                                                              |
| 405 |    677.491176 |    656.002557 | Richard J. Harris                                                                                                                                          |
| 406 |    274.615685 |    407.650825 | Andy Wilson                                                                                                                                                |
| 407 |    663.871761 |    248.177897 | U.S. National Park Service (vectorized by William Gearty)                                                                                                  |
| 408 |    404.369897 |    554.106164 | Margot Michaud                                                                                                                                             |
| 409 |    187.058266 |    367.754226 | Felix Vaux                                                                                                                                                 |
| 410 |    632.086179 |    542.687983 | Scott Hartman (modified by T. Michael Keesey)                                                                                                              |
| 411 |    345.099505 |    697.903882 | Christoph Schomburg                                                                                                                                        |
| 412 |    661.206439 |    280.151343 | Chris huh                                                                                                                                                  |
| 413 |    874.230432 |    266.380249 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                           |
| 414 |    254.369682 |    748.022489 | Matt Crook                                                                                                                                                 |
| 415 |    435.467393 |    253.923255 | Anthony Caravaggi                                                                                                                                          |
| 416 |    488.670592 |    130.062974 | Smokeybjb (modified by Mike Keesey)                                                                                                                        |
| 417 |    360.598650 |    131.088879 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                         |
| 418 |    473.050090 |    412.470732 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                           |
| 419 |    390.158851 |    167.660252 | Margot Michaud                                                                                                                                             |
| 420 |     86.637490 |    787.785722 | Emily Willoughby                                                                                                                                           |
| 421 |    216.481528 |    147.831966 | Lukasiniho                                                                                                                                                 |
| 422 |    413.813355 |     90.613832 | Tasman Dixon                                                                                                                                               |
| 423 |     16.531039 |     87.769776 | Matt Crook                                                                                                                                                 |
| 424 |    805.784575 |      6.791675 | Margot Michaud                                                                                                                                             |
| 425 |    832.604042 |    301.871791 | Alex Slavenko                                                                                                                                              |
| 426 |     17.350922 |    409.247447 | Smokeybjb                                                                                                                                                  |
| 427 |    467.671124 |    379.673718 | Katie S. Collins                                                                                                                                           |
| 428 |    959.630046 |      8.409650 | James Neenan                                                                                                                                               |
| 429 |   1006.153934 |    561.307590 | T. Michael Keesey                                                                                                                                          |
| 430 |    605.090959 |    620.669850 | Armin Reindl                                                                                                                                               |
| 431 |    225.057044 |    320.931934 | Gabriela Palomo-Munoz                                                                                                                                      |
| 432 |    942.270402 |    164.650865 | C. Camilo Julián-Caballero                                                                                                                                 |
| 433 |    998.521694 |     17.325413 | C. Camilo Julián-Caballero                                                                                                                                 |
| 434 |    788.030165 |    515.788903 | Andy Wilson                                                                                                                                                |
| 435 |    220.702980 |     69.069092 | Scott Hartman                                                                                                                                              |
| 436 |    993.228314 |    304.085791 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                              |
| 437 |    174.713601 |    510.973069 | T. Michael Keesey                                                                                                                                          |
| 438 |    942.657635 |    293.575880 | Matt Dempsey                                                                                                                                               |
| 439 |    130.217206 |    752.041021 | Gabriela Palomo-Munoz                                                                                                                                      |
| 440 |    619.686837 |     82.329029 | Zimices                                                                                                                                                    |
| 441 |    165.984355 |    381.023180 | Steven Coombs                                                                                                                                              |
| 442 |    182.255287 |    212.319385 | Andy Wilson                                                                                                                                                |
| 443 |    128.609033 |    316.770034 | Daniel Stadtmauer                                                                                                                                          |
| 444 |    166.157270 |    329.334717 | Michelle Site                                                                                                                                              |
| 445 |    471.604110 |    162.488695 | Chris huh                                                                                                                                                  |
| 446 |    696.195675 |    539.998950 | Gareth Monger                                                                                                                                              |
| 447 |    496.194073 |    595.234299 | Margot Michaud                                                                                                                                             |
| 448 |    637.375238 |      9.974959 | Iain Reid                                                                                                                                                  |
| 449 |    882.007867 |     71.838776 | NA                                                                                                                                                         |
| 450 |    324.380338 |    518.922944 | Gareth Monger                                                                                                                                              |
| 451 |    206.915727 |    657.999336 | Harold N Eyster                                                                                                                                            |
| 452 |    802.949337 |    136.852216 | C. Camilo Julián-Caballero                                                                                                                                 |
| 453 |    379.409869 |    180.541859 | Chris huh                                                                                                                                                  |
| 454 |    976.429423 |    612.113971 | Noah Schlottman, photo from Casey Dunn                                                                                                                     |
| 455 |    633.938421 |     41.688581 | Rebecca Groom                                                                                                                                              |
| 456 |    564.534575 |    459.791965 | Scott Hartman                                                                                                                                              |
| 457 |    851.338725 |    351.477978 | Armin Reindl                                                                                                                                               |
| 458 |    783.963754 |    644.618581 | Jagged Fang Designs                                                                                                                                        |
| 459 |    622.904470 |    435.028850 | Collin Gross                                                                                                                                               |
| 460 |    111.468191 |    259.637366 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                              |
| 461 |    143.489929 |     12.540873 | Joanna Wolfe                                                                                                                                               |
| 462 |     30.231067 |    173.687450 | Zimices                                                                                                                                                    |
| 463 |    835.467752 |    128.126911 | Jagged Fang Designs                                                                                                                                        |
| 464 |    558.297530 |    497.044265 | Matt Crook                                                                                                                                                 |
| 465 |    784.630922 |    772.757592 | Erika Schumacher                                                                                                                                           |
| 466 |    340.856944 |     62.155450 | Christine Axon                                                                                                                                             |
| 467 |    556.576835 |    434.041984 | Maija Karala                                                                                                                                               |
| 468 |    259.144994 |    357.999413 | C. Camilo Julián-Caballero                                                                                                                                 |
| 469 |    125.581927 |    627.761730 | Margot Michaud                                                                                                                                             |
| 470 |    279.365456 |     92.524777 | Ghedoghedo, vectorized by Zimices                                                                                                                          |
| 471 |    167.692317 |    743.492549 | Markus A. Grohme                                                                                                                                           |
| 472 |    137.681598 |    124.109475 | Emily Willoughby                                                                                                                                           |
| 473 |    967.410510 |    701.879091 | DW Bapst (modified from Bates et al., 2005)                                                                                                                |
| 474 |    779.584560 |     68.197821 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                              |
| 475 |    624.196875 |    203.610536 | Mike Hanson                                                                                                                                                |
| 476 |    294.425496 |    775.780696 | Ferran Sayol                                                                                                                                               |
| 477 |    725.428606 |    506.641283 | Zimices                                                                                                                                                    |
| 478 |    445.669427 |    568.697248 | Tony Ayling (vectorized by Milton Tan)                                                                                                                     |
| 479 |    297.680259 |    521.476540 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                              |
| 480 |    953.287619 |     22.615286 | C. Camilo Julián-Caballero                                                                                                                                 |
| 481 |    383.585013 |      6.235317 | Mette Aumala                                                                                                                                               |
| 482 |    226.684444 |    403.875965 | T. Michael Keesey                                                                                                                                          |
| 483 |    971.126310 |    341.015874 | Julie Blommaert based on photo by Sofdrakou                                                                                                                |
| 484 |    267.171524 |    557.999923 | Ieuan Jones                                                                                                                                                |
| 485 |    184.760811 |    387.286884 | C. Camilo Julián-Caballero                                                                                                                                 |
| 486 |    333.655794 |    482.616256 | Jagged Fang Designs                                                                                                                                        |
| 487 |    866.266260 |    476.098567 | Jagged Fang Designs                                                                                                                                        |
| 488 |    629.202055 |    102.993876 | Rafael Maia                                                                                                                                                |
| 489 |    857.181766 |    421.321152 | Christoph Schomburg                                                                                                                                        |
| 490 |    128.960792 |    246.504000 | Michelle Site                                                                                                                                              |
| 491 |    699.317096 |    496.769847 | Zimices                                                                                                                                                    |
| 492 |    188.913819 |    615.049684 | Steven Traver                                                                                                                                              |
| 493 |    942.221658 |     75.759081 | Mo Hassan                                                                                                                                                  |
| 494 |    628.300959 |    774.754015 | Sibi (vectorized by T. Michael Keesey)                                                                                                                     |
| 495 |    509.922593 |    699.156686 | Joanna Wolfe                                                                                                                                               |
| 496 |    874.942083 |    706.851769 | Zimices                                                                                                                                                    |
| 497 |    338.469588 |    620.060435 | Chris huh                                                                                                                                                  |
| 498 |    298.882118 |    296.121147 | NA                                                                                                                                                         |
| 499 |    524.631195 |    448.625597 | Lauren Anderson                                                                                                                                            |
| 500 |    715.312005 |    543.338928 | NA                                                                                                                                                         |
| 501 |    328.459337 |    459.780813 | Andy Wilson                                                                                                                                                |
| 502 |   1010.455041 |    308.288745 | Felix Vaux                                                                                                                                                 |
| 503 |    981.819288 |    218.799104 | Cesar Julian                                                                                                                                               |
| 504 |    225.410116 |    361.893753 | Noah Schlottman, photo by Adam G. Clause                                                                                                                   |
| 505 |   1001.754630 |    330.866243 | Becky Barnes                                                                                                                                               |
| 506 |    922.975810 |    207.321006 | Zimices                                                                                                                                                    |
| 507 |   1012.426510 |    376.023053 | Zimices                                                                                                                                                    |
| 508 |    578.664493 |    260.773438 | Gareth Monger                                                                                                                                              |
| 509 |    907.227839 |    122.591726 | Jagged Fang Designs                                                                                                                                        |
| 510 |     24.811468 |    459.309006 | Matt Crook                                                                                                                                                 |

    #> Your tweet has been posted!
