
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

Matt Dempsey, Evan Swigart (photography) and T. Michael Keesey
(vectorization), Chris A. Hamilton, Heinrich Harder (vectorized by
William Gearty), Margot Michaud, U.S. National Park Service (vectorized
by William Gearty), Anthony Caravaggi, Katie S. Collins, Birgit Lang,
Shyamal, Christoph Schomburg, Tasman Dixon, Joanna Wolfe, Steven Traver,
Harold N Eyster, Sarah Alewijnse, Scott Hartman, C. Camilo
Julián-Caballero, Chris huh, Jagged Fang Designs, Burton Robert, USFWS,
Sarah Werning, Zimices, Apokryltaros (vectorized by T. Michael Keesey),
Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Matt Crook, Tauana
J. Cunha, Steven Coombs, Dmitry Bogdanov, Gabriela Palomo-Munoz, T.
Michael Keesey, Gareth Monger, RS, Kai R. Caspar, Beth Reinke, Ferran
Sayol, Rebecca Groom, David Sim (photograph) and T. Michael Keesey
(vectorization), David Orr, Sergio A. Muñoz-Gómez, Hanyong Pu,
Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming
Zhang, Songhai Jia & T. Michael Keesey, Nobu Tamura (vectorized by T.
Michael Keesey), T. Michael Keesey (after A. Y. Ivantsov), FunkMonk,
Alex Slavenko, Erika Schumacher, Ignacio Contreras, Mihai Dragos
(vectorized by T. Michael Keesey), Dean Schnabel, Gregor Bucher, Max
Farnworth, Amanda Katzer, Pete Buchholz, Jack Mayer Wood, Chase
Brownstein, Andy Wilson, Alexander Schmidt-Lebuhn, Jaime Headden, Emily
Willoughby, Nobu Tamura, modified by Andrew A. Farke, Mathew Wedel,
Armin Reindl, Noah Schlottman, Nobu Tamura (modified by T. Michael
Keesey), Lily Hughes, Robert Bruce Horsfall (vectorized by William
Gearty), Heinrich Harder (vectorized by T. Michael Keesey), Henry
Lydecker, Lee Harding (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Francesco “Architetto” Rollandin, T.
Michael Keesey (vectorization) and Larry Loos (photography), Lukasiniho,
Jonathan Wells, Cristina Guijarro, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Falconaumanni and T. Michael Keesey, Meliponicultor Itaymbere, Dmitry
Bogdanov (vectorized by T. Michael Keesey), T. Michael Keesey (after
Walker & al.), Andrew A. Farke, Henry Fairfield Osborn, vectorized by
Zimices, Felix Vaux, Carlos Cano-Barbacil, FunkMonk (Michael B.H.;
vectorized by T. Michael Keesey), Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Ingo
Braasch, Javier Luque, E. J. Van Nieukerken, A. Laštuvka, and Z.
Laštuvka (vectorized by T. Michael Keesey), Todd Marshall, vectorized
by Zimices, xgirouxb, Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, Smokeybjb, Sean McCann, Diana Pomeroy, Charles
R. Knight, vectorized by Zimices, Zimices, based in Mauricio Antón
skeletal, Smokeybjb (vectorized by T. Michael Keesey),
Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, CNZdenek, Francesco Veronesi (vectorized
by T. Michael Keesey), Iain Reid, Mathieu Pélissié, Kamil S. Jaron,
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Agnello Picorelli, Zsoldos Márton (vectorized by T. Michael
Keesey), Robert Bruce Horsfall (vectorized by T. Michael Keesey), Darren
Naish, Nemo, and T. Michael Keesey, T. Michael Keesey (vectorization)
and Nadiatalent (photography), Bruno C. Vellutini, Scott Hartman
(vectorized by William Gearty), Markus A. Grohme, Josefine Bohr Brask,
Ghedo (vectorized by T. Michael Keesey), Melissa Broussard, Michelle
Site, Peter Coxhead, Mette Aumala, Christopher Laumer (vectorized by T.
Michael Keesey), Chuanixn Yu, Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Rainer Schoch, Marmelad,
Kristina Gagalova, White Wolf, Nina Skinner, Emma Kissling, Mali’o
Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), M Kolmann, Renata F.
Martins, Nobu Tamura, vectorized by Zimices, Geoff Shaw, Stanton F. Fink
(vectorized by T. Michael Keesey), Jose Carlos Arenas-Monroy, Mathilde
Cordellier, Dann Pigdon, Michael Day, Verdilak, Michael Scroggie,
Maxwell Lefroy (vectorized by T. Michael Keesey), Stemonitis
(photography) and T. Michael Keesey (vectorization), Trond R. Oskars,
Milton Tan, Samanta Orellana, Haplochromis (vectorized by T. Michael
Keesey), Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman),
Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Jimmy
Bernot, Darren Naish (vectorized by T. Michael Keesey), Tony Ayling
(vectorized by Milton Tan), Noah Schlottman, photo by Casey Dunn,
Anilocra (vectorization by Yan Wong), Ludwik Gasiorowski, Rene Martin,
Mali’o Kodis, photograph by Bruno Vellutini, Kailah Thorn & Mark
Hutchinson, Lafage, Original drawing by Antonov, vectorized by Roberto
Díaz Sibaja, Benchill, Kimberly Haddrell, Maija Karala, Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Doug
Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Gabriel Lio, vectorized by Zimices, Yan Wong from
drawing by T. F. Zimmermann, Martin R. Smith, Inessa Voet, B. Duygu
Özpolat, Ghedoghedo (vectorized by T. Michael Keesey), Robert Gay,
Thibaut Brunet, Christine Axon, Robbie N. Cada (vectorized by T. Michael
Keesey), www.studiospectre.com

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    581.457030 |    174.857233 | Matt Dempsey                                                                                                                                                          |
|   2 |     85.672839 |    334.507478 | NA                                                                                                                                                                    |
|   3 |    700.224347 |    161.775460 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
|   4 |    325.473174 |    106.117937 | Chris A. Hamilton                                                                                                                                                     |
|   5 |    811.334527 |    612.148179 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
|   6 |    405.319794 |    586.753637 | Margot Michaud                                                                                                                                                        |
|   7 |    148.022566 |     40.180298 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
|   8 |    560.375605 |    394.784587 | Anthony Caravaggi                                                                                                                                                     |
|   9 |    158.948852 |    617.221299 | Katie S. Collins                                                                                                                                                      |
|  10 |    149.511584 |    465.139205 | Birgit Lang                                                                                                                                                           |
|  11 |    891.544754 |    243.048170 | Shyamal                                                                                                                                                               |
|  12 |    304.991400 |    693.788083 | Christoph Schomburg                                                                                                                                                   |
|  13 |    887.498681 |     95.841047 | Tasman Dixon                                                                                                                                                          |
|  14 |    430.184426 |    341.041289 | Joanna Wolfe                                                                                                                                                          |
|  15 |    174.161605 |    327.214802 | Steven Traver                                                                                                                                                         |
|  16 |    502.222672 |    733.830537 | Margot Michaud                                                                                                                                                        |
|  17 |    897.710119 |    349.659198 | Harold N Eyster                                                                                                                                                       |
|  18 |    246.236852 |    377.463508 | Sarah Alewijnse                                                                                                                                                       |
|  19 |    421.921645 |     37.977422 | Scott Hartman                                                                                                                                                         |
|  20 |    830.573121 |    416.915180 | Birgit Lang                                                                                                                                                           |
|  21 |    598.349672 |    504.946049 | C. Camilo Julián-Caballero                                                                                                                                            |
|  22 |     76.354879 |    184.832636 | Margot Michaud                                                                                                                                                        |
|  23 |    847.939035 |    180.617410 | Chris huh                                                                                                                                                             |
|  24 |    324.212112 |    509.552180 | Jagged Fang Designs                                                                                                                                                   |
|  25 |    505.446346 |    646.157523 | Burton Robert, USFWS                                                                                                                                                  |
|  26 |    922.061788 |    527.111672 | Sarah Werning                                                                                                                                                         |
|  27 |    726.891822 |    739.125613 | Zimices                                                                                                                                                               |
|  28 |    596.693734 |    311.817775 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
|  29 |    954.267719 |     45.385537 | Zimices                                                                                                                                                               |
|  30 |    718.443434 |    505.267966 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
|  31 |    917.654243 |    638.234220 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  32 |    226.819410 |    238.824706 | Matt Crook                                                                                                                                                            |
|  33 |    419.460182 |    247.632955 | Tauana J. Cunha                                                                                                                                                       |
|  34 |    451.821127 |     78.554883 | Matt Crook                                                                                                                                                            |
|  35 |    110.764088 |    756.851939 | Steven Coombs                                                                                                                                                         |
|  36 |    939.667858 |    145.452262 | Dmitry Bogdanov                                                                                                                                                       |
|  37 |    436.500219 |    473.483950 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  38 |    512.522178 |    207.513561 | T. Michael Keesey                                                                                                                                                     |
|  39 |    627.028058 |    638.306680 | Gareth Monger                                                                                                                                                         |
|  40 |    929.663776 |    717.558864 | Zimices                                                                                                                                                               |
|  41 |    795.037411 |    268.455659 | RS                                                                                                                                                                    |
|  42 |    609.418573 |     89.058818 | T. Michael Keesey                                                                                                                                                     |
|  43 |    506.516568 |    119.481489 | Scott Hartman                                                                                                                                                         |
|  44 |    107.505329 |     89.418172 | Kai R. Caspar                                                                                                                                                         |
|  45 |    322.433033 |     26.662208 | Beth Reinke                                                                                                                                                           |
|  46 |     58.625421 |    486.112279 | Ferran Sayol                                                                                                                                                          |
|  47 |    787.275696 |    141.487415 | Rebecca Groom                                                                                                                                                         |
|  48 |    256.703430 |    767.509477 | Steven Traver                                                                                                                                                         |
|  49 |    180.350370 |    694.400920 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
|  50 |    288.848235 |    438.181093 | David Orr                                                                                                                                                             |
|  51 |    613.300951 |    423.387452 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  52 |    806.693132 |    685.180634 | Christoph Schomburg                                                                                                                                                   |
|  53 |    330.839711 |    359.202129 | Joanna Wolfe                                                                                                                                                          |
|  54 |    634.867048 |    560.669341 | Scott Hartman                                                                                                                                                         |
|  55 |    378.294650 |    163.841098 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  56 |     63.746416 |    671.004225 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
|  57 |    719.094943 |    345.804663 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  58 |    645.712989 |    776.474328 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
|  59 |    302.775681 |    306.952623 | FunkMonk                                                                                                                                                              |
|  60 |    616.695958 |    260.572215 | T. Michael Keesey                                                                                                                                                     |
|  61 |    759.211063 |     41.205757 | Alex Slavenko                                                                                                                                                         |
|  62 |    382.099621 |    764.465967 | Erika Schumacher                                                                                                                                                      |
|  63 |    218.523311 |    162.279321 | Zimices                                                                                                                                                               |
|  64 |     88.831588 |    543.150788 | Ignacio Contreras                                                                                                                                                     |
|  65 |    718.117094 |    664.482535 | Matt Crook                                                                                                                                                            |
|  66 |    830.485520 |    776.611116 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
|  67 |    216.341967 |    107.565478 | Chris huh                                                                                                                                                             |
|  68 |    135.731629 |    406.856799 | Dean Schnabel                                                                                                                                                         |
|  69 |    968.153743 |    424.483603 | Zimices                                                                                                                                                               |
|  70 |    804.337457 |    527.220659 | Gregor Bucher, Max Farnworth                                                                                                                                          |
|  71 |    427.464651 |    648.986562 | Amanda Katzer                                                                                                                                                         |
|  72 |    852.757948 |    746.014175 | Matt Dempsey                                                                                                                                                          |
|  73 |    257.078698 |    564.057798 | Pete Buchholz                                                                                                                                                         |
|  74 |    825.306984 |    309.860207 | Jack Mayer Wood                                                                                                                                                       |
|  75 |    204.453216 |    743.596638 | Jagged Fang Designs                                                                                                                                                   |
|  76 |    606.766508 |    728.154259 | C. Camilo Julián-Caballero                                                                                                                                            |
|  77 |    358.337074 |    442.546350 | NA                                                                                                                                                                    |
|  78 |    850.885300 |     30.130465 | Scott Hartman                                                                                                                                                         |
|  79 |    522.408048 |    568.549556 | Matt Crook                                                                                                                                                            |
|  80 |    739.561700 |    231.628762 | Chris huh                                                                                                                                                             |
|  81 |    991.785059 |    683.852135 | T. Michael Keesey                                                                                                                                                     |
|  82 |    667.702239 |    110.718608 | Zimices                                                                                                                                                               |
|  83 |    230.030508 |    511.817386 | Kai R. Caspar                                                                                                                                                         |
|  84 |     33.361415 |    765.362848 | Chase Brownstein                                                                                                                                                      |
|  85 |    554.530460 |    775.130487 | Andy Wilson                                                                                                                                                           |
|  86 |    751.066274 |    428.852313 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  87 |    709.992399 |    401.679959 | NA                                                                                                                                                                    |
|  88 |     62.543461 |    711.606866 | Jaime Headden                                                                                                                                                         |
|  89 |    108.915935 |    507.594891 | Emily Willoughby                                                                                                                                                      |
|  90 |    752.605933 |    600.559653 | Rebecca Groom                                                                                                                                                         |
|  91 |    424.404634 |      6.292339 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
|  92 |    100.794710 |    263.169200 | Zimices                                                                                                                                                               |
|  93 |    289.130711 |     60.844830 | Steven Traver                                                                                                                                                         |
|  94 |    375.992721 |    522.846214 | Mathew Wedel                                                                                                                                                          |
|  95 |    294.991374 |    537.455968 | Armin Reindl                                                                                                                                                          |
|  96 |    634.718228 |    758.701292 | Shyamal                                                                                                                                                               |
|  97 |    238.390436 |     18.566416 | Zimices                                                                                                                                                               |
|  98 |    570.247068 |     67.631274 | Noah Schlottman                                                                                                                                                       |
|  99 |    930.869680 |    464.909043 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 100 |    526.989973 |    303.390293 | Ignacio Contreras                                                                                                                                                     |
| 101 |    316.302819 |    219.184018 | Scott Hartman                                                                                                                                                         |
| 102 |    957.050227 |    284.529940 | Zimices                                                                                                                                                               |
| 103 |    728.269493 |    301.861377 | Lily Hughes                                                                                                                                                           |
| 104 |     35.666536 |     33.040257 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 105 |    951.807800 |    263.122178 | NA                                                                                                                                                                    |
| 106 |    232.717138 |    469.809538 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 107 |    984.342006 |    525.376482 | Armin Reindl                                                                                                                                                          |
| 108 |    320.876092 |    396.707613 | Shyamal                                                                                                                                                               |
| 109 |    521.692533 |     38.840647 | Jaime Headden                                                                                                                                                         |
| 110 |    989.895512 |    158.202384 | Matt Crook                                                                                                                                                            |
| 111 |    948.295310 |    686.865304 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 112 |    932.073557 |    777.411489 | T. Michael Keesey                                                                                                                                                     |
| 113 |    859.601502 |    286.868836 | Gareth Monger                                                                                                                                                         |
| 114 |     38.876342 |    397.485901 | Henry Lydecker                                                                                                                                                        |
| 115 |    727.209789 |    115.637490 | Zimices                                                                                                                                                               |
| 116 |    305.586183 |    255.190825 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 117 |    646.012461 |      8.216673 | Zimices                                                                                                                                                               |
| 118 |     69.329269 |    233.413521 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 119 |    384.948458 |    714.425357 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 120 |    976.378928 |    333.295175 | Gareth Monger                                                                                                                                                         |
| 121 |    177.323113 |    266.726103 | Steven Traver                                                                                                                                                         |
| 122 |    849.783966 |    515.245192 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 123 |    728.185119 |    707.936609 | Gareth Monger                                                                                                                                                         |
| 124 |    677.488146 |    297.979372 | Lukasiniho                                                                                                                                                            |
| 125 |    343.810621 |    204.473075 | Jonathan Wells                                                                                                                                                        |
| 126 |    983.538370 |    619.893811 | NA                                                                                                                                                                    |
| 127 |    875.945779 |    587.404565 | Cristina Guijarro                                                                                                                                                     |
| 128 |    399.365860 |     81.641330 | Zimices                                                                                                                                                               |
| 129 |    520.664156 |    483.306408 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 130 |    345.846409 |    458.021403 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 131 |    282.505087 |    598.270771 | Meliponicultor Itaymbere                                                                                                                                              |
| 132 |    983.370541 |    108.568023 | Zimices                                                                                                                                                               |
| 133 |    324.284608 |    480.769386 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 134 |    739.597539 |    564.469497 | NA                                                                                                                                                                    |
| 135 |    811.681855 |    717.502218 | Scott Hartman                                                                                                                                                         |
| 136 |    496.829101 |    520.484224 | Gareth Monger                                                                                                                                                         |
| 137 |    926.749826 |    424.401403 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 138 |     16.369740 |    108.039274 | Andrew A. Farke                                                                                                                                                       |
| 139 |    750.728194 |    777.014055 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 140 |    449.072432 |    414.028587 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 141 |    466.104072 |    202.634143 | Felix Vaux                                                                                                                                                            |
| 142 |    944.104208 |     82.753170 | T. Michael Keesey                                                                                                                                                     |
| 143 |    913.826875 |    576.479047 | Andrew A. Farke                                                                                                                                                       |
| 144 |    577.337910 |    214.626696 | Scott Hartman                                                                                                                                                         |
| 145 |      6.038446 |    271.548082 | T. Michael Keesey                                                                                                                                                     |
| 146 |    922.417959 |    173.640230 | Steven Traver                                                                                                                                                         |
| 147 |    379.201240 |    688.464568 | Carlos Cano-Barbacil                                                                                                                                                  |
| 148 |    520.798667 |     74.548325 | Margot Michaud                                                                                                                                                        |
| 149 |    985.395848 |    206.645386 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 150 |    726.321048 |    436.632755 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 151 |    879.012163 |     57.100200 | Matt Crook                                                                                                                                                            |
| 152 |    999.132262 |    274.987099 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 153 |    374.973479 |    636.734285 | Matt Crook                                                                                                                                                            |
| 154 |    318.974813 |    240.401328 | Ingo Braasch                                                                                                                                                          |
| 155 |    656.867728 |     59.109873 | Harold N Eyster                                                                                                                                                       |
| 156 |    473.134389 |    150.060141 | Margot Michaud                                                                                                                                                        |
| 157 |    543.434412 |    285.411863 | Jagged Fang Designs                                                                                                                                                   |
| 158 |    226.034314 |    722.340670 | C. Camilo Julián-Caballero                                                                                                                                            |
| 159 |     51.987812 |    443.008285 | Andy Wilson                                                                                                                                                           |
| 160 |    635.133560 |    215.002874 | Chris huh                                                                                                                                                             |
| 161 |    411.943165 |    125.651795 | Scott Hartman                                                                                                                                                         |
| 162 |    569.299170 |      9.522400 | Javier Luque                                                                                                                                                          |
| 163 |    519.578243 |    316.798047 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 164 |     58.807822 |    114.471776 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
| 165 |    718.357783 |    268.571002 | Birgit Lang                                                                                                                                                           |
| 166 |    239.896470 |    404.922943 | Margot Michaud                                                                                                                                                        |
| 167 |     42.527855 |    105.212406 | Gareth Monger                                                                                                                                                         |
| 168 |    352.160656 |    255.661746 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 169 |    889.446337 |     17.827596 | Margot Michaud                                                                                                                                                        |
| 170 |    811.410474 |    358.968099 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 171 |    646.415278 |     94.522966 | Matt Crook                                                                                                                                                            |
| 172 |    732.286862 |    457.926396 | Jagged Fang Designs                                                                                                                                                   |
| 173 |    765.532707 |    322.121215 | xgirouxb                                                                                                                                                              |
| 174 |    557.161470 |    588.607854 | Zimices                                                                                                                                                               |
| 175 |    703.996520 |    600.021283 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 176 |    535.649897 |     10.647486 | Smokeybjb                                                                                                                                                             |
| 177 |    465.972260 |     44.989938 | Sean McCann                                                                                                                                                           |
| 178 |     25.905241 |    271.442012 | Steven Traver                                                                                                                                                         |
| 179 |    150.835561 |    202.835337 | Margot Michaud                                                                                                                                                        |
| 180 |    243.461863 |     54.889489 | Diana Pomeroy                                                                                                                                                         |
| 181 |    798.045116 |    455.537638 | Matt Crook                                                                                                                                                            |
| 182 |    891.613833 |    551.530219 | Steven Traver                                                                                                                                                         |
| 183 |    706.154734 |    635.666687 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 184 |    771.239482 |    279.104107 | Zimices                                                                                                                                                               |
| 185 |    492.639900 |    767.085273 | Zimices, based in Mauricio Antón skeletal                                                                                                                             |
| 186 |    700.528781 |    571.848060 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 187 |    493.205582 |    324.876976 | Zimices                                                                                                                                                               |
| 188 |    141.476969 |    313.701659 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 189 |     28.561746 |    567.999351 | Zimices                                                                                                                                                               |
| 190 |    850.159536 |     55.787828 | Zimices                                                                                                                                                               |
| 191 |    583.419786 |    702.456430 | Tasman Dixon                                                                                                                                                          |
| 192 |   1010.966495 |    574.214703 | Birgit Lang                                                                                                                                                           |
| 193 |    342.528616 |    232.892940 | Rebecca Groom                                                                                                                                                         |
| 194 |    899.399577 |    423.478099 | Gareth Monger                                                                                                                                                         |
| 195 |    308.367697 |    328.056891 | CNZdenek                                                                                                                                                              |
| 196 |     30.050948 |     70.937554 | NA                                                                                                                                                                    |
| 197 |    454.929310 |    173.763068 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 198 |     16.384608 |    159.251044 | Joanna Wolfe                                                                                                                                                          |
| 199 |    977.043296 |    355.885988 | C. Camilo Julián-Caballero                                                                                                                                            |
| 200 |    973.008804 |    260.328662 | Scott Hartman                                                                                                                                                         |
| 201 |    720.842125 |     82.567904 | Jagged Fang Designs                                                                                                                                                   |
| 202 |    772.212949 |    509.567747 | Chris huh                                                                                                                                                             |
| 203 |    367.578900 |    291.522704 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 204 |    964.299298 |    306.720761 | NA                                                                                                                                                                    |
| 205 |    413.889849 |    706.686022 | Jagged Fang Designs                                                                                                                                                   |
| 206 |    869.540010 |      8.854966 | Iain Reid                                                                                                                                                             |
| 207 |    502.309517 |    491.386066 | T. Michael Keesey                                                                                                                                                     |
| 208 |    537.336935 |    207.006978 | Scott Hartman                                                                                                                                                         |
| 209 |    510.893635 |    597.395076 | Jagged Fang Designs                                                                                                                                                   |
| 210 |    526.537957 |    683.560672 | Mathieu Pélissié                                                                                                                                                      |
| 211 |    829.780313 |     76.178436 | Joanna Wolfe                                                                                                                                                          |
| 212 |    166.429866 |    131.150931 | Margot Michaud                                                                                                                                                        |
| 213 |     27.213443 |    585.057967 | NA                                                                                                                                                                    |
| 214 |    997.818945 |    728.533659 | Zimices                                                                                                                                                               |
| 215 |    626.234775 |    347.466809 | Kamil S. Jaron                                                                                                                                                        |
| 216 |    301.130244 |    279.699143 | Zimices                                                                                                                                                               |
| 217 |     81.415195 |    413.147590 | Jagged Fang Designs                                                                                                                                                   |
| 218 |    270.886899 |    170.825172 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 219 |   1008.771947 |    311.598876 | Andy Wilson                                                                                                                                                           |
| 220 |    613.709704 |    148.789259 | Christoph Schomburg                                                                                                                                                   |
| 221 |    370.058441 |    393.413279 | Margot Michaud                                                                                                                                                        |
| 222 |     24.035579 |    467.199855 | Steven Traver                                                                                                                                                         |
| 223 |    377.863848 |    511.593228 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 224 |    911.868208 |    123.862680 | Zimices                                                                                                                                                               |
| 225 |    433.971739 |    726.248611 | Matt Crook                                                                                                                                                            |
| 226 |    914.733375 |    787.132241 | Agnello Picorelli                                                                                                                                                     |
| 227 |    687.422204 |    253.356221 | Chris huh                                                                                                                                                             |
| 228 |    481.669773 |      8.934583 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 229 |    426.848145 |    686.682559 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 230 |    345.765917 |     57.704009 | Margot Michaud                                                                                                                                                        |
| 231 |   1013.508354 |    123.234359 | NA                                                                                                                                                                    |
| 232 |    844.419906 |    491.425480 | Mathieu Pélissié                                                                                                                                                      |
| 233 |    171.988033 |    291.035495 | Gareth Monger                                                                                                                                                         |
| 234 |    677.787444 |    608.132246 | Zimices                                                                                                                                                               |
| 235 |     33.300702 |    246.288406 | Ferran Sayol                                                                                                                                                          |
| 236 |   1003.191767 |    650.768386 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 237 |    156.897202 |    773.265958 | Matt Crook                                                                                                                                                            |
| 238 |    526.060041 |    526.800490 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 239 |     17.303097 |    371.194484 | Rebecca Groom                                                                                                                                                         |
| 240 |    974.038744 |    183.028520 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                             |
| 241 |    145.813549 |    279.908595 | Matt Crook                                                                                                                                                            |
| 242 |    684.906090 |     37.315164 | David Orr                                                                                                                                                             |
| 243 |    841.727264 |    110.610307 | Tasman Dixon                                                                                                                                                          |
| 244 |    919.544213 |    597.848655 | Jagged Fang Designs                                                                                                                                                   |
| 245 |    817.324936 |    342.950516 | Shyamal                                                                                                                                                               |
| 246 |    650.363039 |    382.222525 | Tasman Dixon                                                                                                                                                          |
| 247 |    373.409769 |     53.636697 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 248 |    212.084190 |    340.773903 | Zimices                                                                                                                                                               |
| 249 |    125.614432 |    338.929740 | Scott Hartman                                                                                                                                                         |
| 250 |    521.699189 |    510.364135 | Steven Traver                                                                                                                                                         |
| 251 |    562.920873 |     27.179560 | Zimices                                                                                                                                                               |
| 252 |    621.190675 |    404.905809 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 253 |    361.678723 |    716.266364 | Christoph Schomburg                                                                                                                                                   |
| 254 |    657.113353 |    357.333811 | Bruno C. Vellutini                                                                                                                                                    |
| 255 |    514.287962 |    292.207653 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 256 |     27.176899 |    203.414081 | Beth Reinke                                                                                                                                                           |
| 257 |    516.864318 |    454.102399 | Ignacio Contreras                                                                                                                                                     |
| 258 |    436.908986 |    148.411907 | Margot Michaud                                                                                                                                                        |
| 259 |    169.223945 |    220.571834 | Scott Hartman (vectorized by William Gearty)                                                                                                                          |
| 260 |    183.195268 |    365.823794 | Zimices                                                                                                                                                               |
| 261 |    161.395612 |    420.417397 | Felix Vaux                                                                                                                                                            |
| 262 |   1008.510810 |    368.436505 | Gareth Monger                                                                                                                                                         |
| 263 |    794.630803 |    635.980780 | T. Michael Keesey                                                                                                                                                     |
| 264 |     16.891784 |    307.192250 | NA                                                                                                                                                                    |
| 265 |    128.032801 |    161.721661 | Markus A. Grohme                                                                                                                                                      |
| 266 |    562.199686 |    677.219495 | NA                                                                                                                                                                    |
| 267 |    527.589090 |    463.291937 | Steven Coombs                                                                                                                                                         |
| 268 |    743.213750 |    471.850845 | Kamil S. Jaron                                                                                                                                                        |
| 269 |    454.029592 |    783.607662 | Joanna Wolfe                                                                                                                                                          |
| 270 |    743.723170 |    378.562803 | Zimices                                                                                                                                                               |
| 271 |    590.540452 |    739.345525 | Birgit Lang                                                                                                                                                           |
| 272 |    150.166183 |    233.189180 | T. Michael Keesey                                                                                                                                                     |
| 273 |    396.839770 |    497.711630 | Chris huh                                                                                                                                                             |
| 274 |    297.715905 |    185.691874 | Mathieu Pélissié                                                                                                                                                      |
| 275 |    315.232076 |    621.382863 | Josefine Bohr Brask                                                                                                                                                   |
| 276 |   1000.032825 |     69.309619 | NA                                                                                                                                                                    |
| 277 |    944.870127 |    186.352519 | Chris huh                                                                                                                                                             |
| 278 |    140.361895 |    677.564300 | Markus A. Grohme                                                                                                                                                      |
| 279 |    671.287268 |    275.714682 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 280 |    816.416086 |     53.136145 | Zimices                                                                                                                                                               |
| 281 |     45.060691 |    603.006190 | Gareth Monger                                                                                                                                                         |
| 282 |     14.964762 |    405.705910 | NA                                                                                                                                                                    |
| 283 |    980.739341 |    721.468656 | Jagged Fang Designs                                                                                                                                                   |
| 284 |    531.610549 |    249.198761 | Jagged Fang Designs                                                                                                                                                   |
| 285 |   1014.998746 |    194.987517 | Armin Reindl                                                                                                                                                          |
| 286 |    664.570559 |     96.332391 | Chris huh                                                                                                                                                             |
| 287 |    167.847118 |    537.202596 | Melissa Broussard                                                                                                                                                     |
| 288 |    368.653240 |    117.470592 | Scott Hartman                                                                                                                                                         |
| 289 |     26.690096 |    445.178396 | Zimices                                                                                                                                                               |
| 290 |    659.558742 |    476.940178 | Mathew Wedel                                                                                                                                                          |
| 291 |     31.587989 |    422.991700 | Margot Michaud                                                                                                                                                        |
| 292 |    949.890162 |    553.350242 | Melissa Broussard                                                                                                                                                     |
| 293 |    644.097832 |     34.102681 | Scott Hartman                                                                                                                                                         |
| 294 |    650.179955 |    164.748367 | Michelle Site                                                                                                                                                         |
| 295 |    753.881075 |    151.013044 | FunkMonk                                                                                                                                                              |
| 296 |    696.586876 |     94.587543 | Steven Traver                                                                                                                                                         |
| 297 |    135.602163 |    493.811774 | Chris huh                                                                                                                                                             |
| 298 |    577.760849 |    111.393953 | Peter Coxhead                                                                                                                                                         |
| 299 |    258.456368 |    352.501076 | NA                                                                                                                                                                    |
| 300 |    605.167045 |    289.526823 | Mette Aumala                                                                                                                                                          |
| 301 |    490.992218 |    399.931784 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 302 |    772.885755 |    208.648813 | Chuanixn Yu                                                                                                                                                           |
| 303 |    986.158174 |    776.970998 | Birgit Lang                                                                                                                                                           |
| 304 |    830.122744 |    638.360708 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 305 |    765.538836 |    490.235767 | Kai R. Caspar                                                                                                                                                         |
| 306 |    336.945255 |    280.392741 | Rainer Schoch                                                                                                                                                         |
| 307 |    644.871307 |    525.927460 | Matt Crook                                                                                                                                                            |
| 308 |    342.810672 |    534.315328 | T. Michael Keesey                                                                                                                                                     |
| 309 |   1007.150523 |    766.065724 | Birgit Lang                                                                                                                                                           |
| 310 |     19.187188 |    699.685055 | Matt Crook                                                                                                                                                            |
| 311 |    362.017823 |    489.609837 | Margot Michaud                                                                                                                                                        |
| 312 |    256.064872 |     91.832106 | Steven Traver                                                                                                                                                         |
| 313 |    526.980970 |    142.522955 | Marmelad                                                                                                                                                              |
| 314 |    579.493501 |    561.296367 | Jagged Fang Designs                                                                                                                                                   |
| 315 |    369.472671 |    129.480538 | Zimices                                                                                                                                                               |
| 316 |     31.826048 |    628.985362 | Kristina Gagalova                                                                                                                                                     |
| 317 |    675.615677 |    579.692302 | Scott Hartman                                                                                                                                                         |
| 318 |     23.566424 |    226.772293 | NA                                                                                                                                                                    |
| 319 |    220.425199 |    189.699049 | Scott Hartman                                                                                                                                                         |
| 320 |     20.221138 |     83.437588 | Scott Hartman                                                                                                                                                         |
| 321 |    681.372488 |    317.438667 | White Wolf                                                                                                                                                            |
| 322 |    806.951681 |     91.945340 | Zimices                                                                                                                                                               |
| 323 |    737.987882 |    786.460508 | Nina Skinner                                                                                                                                                          |
| 324 |    412.494690 |     70.194067 | Emma Kissling                                                                                                                                                         |
| 325 |    847.531722 |    123.648480 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 326 |    853.705966 |    567.451971 | Steven Traver                                                                                                                                                         |
| 327 |     20.255136 |    337.846601 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 328 |    385.468131 |    405.656299 | Ferran Sayol                                                                                                                                                          |
| 329 |    136.848834 |    148.291147 | Sarah Werning                                                                                                                                                         |
| 330 |   1002.566338 |     85.779053 | Margot Michaud                                                                                                                                                        |
| 331 |    262.734471 |    243.262202 | M Kolmann                                                                                                                                                             |
| 332 |     50.254312 |    789.739736 | Markus A. Grohme                                                                                                                                                      |
| 333 |    492.235387 |    351.354945 | Renata F. Martins                                                                                                                                                     |
| 334 |    723.418504 |    773.485133 | Chuanixn Yu                                                                                                                                                           |
| 335 |    690.663422 |    433.039155 | Zimices                                                                                                                                                               |
| 336 |    947.824183 |      4.554972 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 337 |    494.637166 |    684.169389 | Matt Crook                                                                                                                                                            |
| 338 |    859.440206 |    275.183168 | Kamil S. Jaron                                                                                                                                                        |
| 339 |    127.550985 |    523.506897 | NA                                                                                                                                                                    |
| 340 |    808.494448 |    157.785971 | Geoff Shaw                                                                                                                                                            |
| 341 |    181.373510 |    779.073270 | Matt Crook                                                                                                                                                            |
| 342 |    374.370277 |    543.057628 | Renata F. Martins                                                                                                                                                     |
| 343 |    432.857951 |    198.848996 | Markus A. Grohme                                                                                                                                                      |
| 344 |    880.171839 |    374.091784 | Mathieu Pélissié                                                                                                                                                      |
| 345 |    129.756028 |    442.687311 | Scott Hartman                                                                                                                                                         |
| 346 |    378.972193 |     88.202080 | Tasman Dixon                                                                                                                                                          |
| 347 |    483.148259 |    102.327257 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 348 |    514.659792 |    264.059614 | Birgit Lang                                                                                                                                                           |
| 349 |    918.406242 |    397.255156 | Ferran Sayol                                                                                                                                                          |
| 350 |    478.786773 |    547.306293 | Melissa Broussard                                                                                                                                                     |
| 351 |    455.997496 |    190.268824 | David Orr                                                                                                                                                             |
| 352 |   1004.600380 |    231.516622 | NA                                                                                                                                                                    |
| 353 |    907.060993 |     85.955041 | Zimices                                                                                                                                                               |
| 354 |    882.199814 |    756.998690 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 355 |    326.778946 |    130.884419 | NA                                                                                                                                                                    |
| 356 |    662.689221 |    234.812524 | Mathilde Cordellier                                                                                                                                                   |
| 357 |    629.208646 |    704.310461 | NA                                                                                                                                                                    |
| 358 |    177.266716 |    383.097011 | Birgit Lang                                                                                                                                                           |
| 359 |    392.723247 |    199.369480 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 360 |    856.275177 |    792.634915 | Kai R. Caspar                                                                                                                                                         |
| 361 |    584.313506 |    530.394077 | Dann Pigdon                                                                                                                                                           |
| 362 |    423.029719 |    423.396633 | Michael Day                                                                                                                                                           |
| 363 |    875.081127 |    474.486642 | Verdilak                                                                                                                                                              |
| 364 |    546.680193 |    103.337684 | Margot Michaud                                                                                                                                                        |
| 365 |    231.291633 |     73.253717 | NA                                                                                                                                                                    |
| 366 |    553.877190 |    269.455897 | Michael Scroggie                                                                                                                                                      |
| 367 |    572.386065 |    617.712311 | NA                                                                                                                                                                    |
| 368 |    690.554282 |    235.868740 | Matt Crook                                                                                                                                                            |
| 369 |    368.119851 |    193.656632 | Tasman Dixon                                                                                                                                                          |
| 370 |    102.053940 |    381.201748 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 371 |    148.549658 |    552.094713 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 372 |    144.142434 |    178.327673 | Trond R. Oskars                                                                                                                                                       |
| 373 |    395.343580 |    730.524262 | Milton Tan                                                                                                                                                            |
| 374 |    755.372318 |    177.678565 | Samanta Orellana                                                                                                                                                      |
| 375 |    947.466490 |    789.136091 | Steven Traver                                                                                                                                                         |
| 376 |    129.136686 |    243.745418 | Chris huh                                                                                                                                                             |
| 377 |    272.238371 |    475.890480 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 378 |    132.579849 |    359.613395 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 379 |    386.177199 |    484.213492 | Emily Willoughby                                                                                                                                                      |
| 380 |    249.831158 |    454.472332 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 381 |    138.298983 |    419.810891 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 382 |     29.501440 |    745.410010 | Gareth Monger                                                                                                                                                         |
| 383 |    536.573960 |    752.906740 | Matt Crook                                                                                                                                                            |
| 384 |    421.008344 |    675.547023 | Jagged Fang Designs                                                                                                                                                   |
| 385 |    265.306210 |    520.814646 | Birgit Lang                                                                                                                                                           |
| 386 |     47.661038 |     15.258446 | NA                                                                                                                                                                    |
| 387 |    482.465792 |    775.552364 | Dmitry Bogdanov                                                                                                                                                       |
| 388 |    608.743195 |     30.217718 | Michelle Site                                                                                                                                                         |
| 389 |    594.580153 |    538.211245 | Scott Hartman                                                                                                                                                         |
| 390 |    121.077120 |    788.336352 | Jimmy Bernot                                                                                                                                                          |
| 391 |     45.972771 |     50.102900 | Zimices                                                                                                                                                               |
| 392 |    864.418638 |    255.752231 | Jagged Fang Designs                                                                                                                                                   |
| 393 |    679.651520 |     13.551763 | Jagged Fang Designs                                                                                                                                                   |
| 394 |    108.566086 |     44.605007 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 395 |    810.939343 |    205.634085 | Matt Crook                                                                                                                                                            |
| 396 |    985.307645 |    577.361920 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 397 |    210.236005 |    540.661206 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 398 |    689.650283 |    263.048934 | Scott Hartman                                                                                                                                                         |
| 399 |    963.663890 |    115.227280 | Kamil S. Jaron                                                                                                                                                        |
| 400 |     96.448327 |    531.442806 | Chris huh                                                                                                                                                             |
| 401 |    490.905325 |    277.913626 | Erika Schumacher                                                                                                                                                      |
| 402 |    578.840273 |    237.306787 | Scott Hartman                                                                                                                                                         |
| 403 |    660.473026 |    561.881213 | Markus A. Grohme                                                                                                                                                      |
| 404 |    297.131813 |    206.324434 | Gareth Monger                                                                                                                                                         |
| 405 |    794.434638 |    793.619369 | Amanda Katzer                                                                                                                                                         |
| 406 |    531.809744 |    610.033827 | Steven Traver                                                                                                                                                         |
| 407 |    559.176255 |    540.486573 | Felix Vaux                                                                                                                                                            |
| 408 |     22.183567 |    791.226216 | Birgit Lang                                                                                                                                                           |
| 409 |    664.246879 |    555.469040 | Gareth Monger                                                                                                                                                         |
| 410 |    391.405770 |    265.213499 | Christoph Schomburg                                                                                                                                                   |
| 411 |    295.235912 |    165.801948 | Scott Hartman                                                                                                                                                         |
| 412 |    238.530316 |    339.275719 | Steven Traver                                                                                                                                                         |
| 413 |    296.955123 |    556.597603 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 414 |     73.992966 |     25.336756 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 415 |    933.420347 |    298.751701 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 416 |    329.365414 |     45.771757 | Scott Hartman                                                                                                                                                         |
| 417 |    567.589888 |    296.615373 | Gareth Monger                                                                                                                                                         |
| 418 |    716.391290 |    623.821250 | Ludwik Gasiorowski                                                                                                                                                    |
| 419 |    156.580700 |    377.087882 | Andy Wilson                                                                                                                                                           |
| 420 |    911.374232 |    743.545721 | White Wolf                                                                                                                                                            |
| 421 |    108.525999 |    462.618993 | Armin Reindl                                                                                                                                                          |
| 422 |    906.679988 |    162.459379 | Markus A. Grohme                                                                                                                                                      |
| 423 |    354.055254 |    794.341057 | Chris huh                                                                                                                                                             |
| 424 |    393.877830 |    128.225493 | NA                                                                                                                                                                    |
| 425 |    443.190489 |    431.420403 | Rebecca Groom                                                                                                                                                         |
| 426 |    569.147498 |    352.187850 | Scott Hartman                                                                                                                                                         |
| 427 |    756.263132 |    504.252878 | Steven Coombs                                                                                                                                                         |
| 428 |    494.677639 |     91.749831 | Tasman Dixon                                                                                                                                                          |
| 429 |    224.816539 |    356.415076 | Rene Martin                                                                                                                                                           |
| 430 |    417.898211 |    147.298819 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 431 |    541.179460 |    659.115995 | NA                                                                                                                                                                    |
| 432 |    878.322901 |    136.566254 | NA                                                                                                                                                                    |
| 433 |    863.429246 |    249.557495 | Beth Reinke                                                                                                                                                           |
| 434 |    778.799465 |    582.009662 | Zimices                                                                                                                                                               |
| 435 |    247.213384 |    538.207921 | Zimices                                                                                                                                                               |
| 436 |    185.112173 |    495.015954 | Andy Wilson                                                                                                                                                           |
| 437 |    662.000553 |    746.169745 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 438 |    984.474055 |     10.614864 | Lafage                                                                                                                                                                |
| 439 |    660.626286 |    126.876359 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 440 |    504.650154 |    469.029225 | NA                                                                                                                                                                    |
| 441 |    507.311019 |    797.631690 | Jagged Fang Designs                                                                                                                                                   |
| 442 |    910.324266 |    663.638333 | Benchill                                                                                                                                                              |
| 443 |    841.543584 |    335.762287 | Scott Hartman                                                                                                                                                         |
| 444 |    338.137556 |    328.983074 | Lily Hughes                                                                                                                                                           |
| 445 |    180.805103 |     89.415463 | Margot Michaud                                                                                                                                                        |
| 446 |    688.631087 |    381.462476 | Steven Traver                                                                                                                                                         |
| 447 |    570.121588 |    716.747634 | Sarah Werning                                                                                                                                                         |
| 448 |    839.247813 |    348.649204 | Tasman Dixon                                                                                                                                                          |
| 449 |    950.937939 |    434.725712 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 450 |    730.895645 |    699.003881 | Markus A. Grohme                                                                                                                                                      |
| 451 |    234.243700 |    298.289528 | Kimberly Haddrell                                                                                                                                                     |
| 452 |    113.485146 |    143.143586 | Ferran Sayol                                                                                                                                                          |
| 453 |     71.602334 |      6.430000 | FunkMonk                                                                                                                                                              |
| 454 |    477.916490 |    413.872863 | Gareth Monger                                                                                                                                                         |
| 455 |    928.830168 |    547.696649 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 456 |    147.992830 |    669.221390 | Markus A. Grohme                                                                                                                                                      |
| 457 |    629.539986 |    367.580030 | Tasman Dixon                                                                                                                                                          |
| 458 |     73.823611 |    372.842132 | Steven Traver                                                                                                                                                         |
| 459 |    632.356898 |    480.265374 | Maija Karala                                                                                                                                                          |
| 460 |    572.720998 |    664.750943 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 461 |     90.430328 |    648.833637 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 462 |    214.984076 |    128.661822 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 463 |     70.738159 |    247.267233 | Scott Hartman                                                                                                                                                         |
| 464 |    538.968372 |    680.778223 | Zimices                                                                                                                                                               |
| 465 |    713.068529 |    459.719231 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 466 |    716.184894 |    421.695396 | Smokeybjb                                                                                                                                                             |
| 467 |    657.123459 |    466.607396 | Tasman Dixon                                                                                                                                                          |
| 468 |    906.874884 |    272.350473 | NA                                                                                                                                                                    |
| 469 |    380.328754 |    463.281367 | Gareth Monger                                                                                                                                                         |
| 470 |    629.693940 |    489.750302 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 471 |    575.441741 |    748.210841 | Tasman Dixon                                                                                                                                                          |
| 472 |    454.532150 |    160.562823 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 473 |    666.447525 |    532.735020 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 474 |    927.424309 |    675.803385 | Ignacio Contreras                                                                                                                                                     |
| 475 |     56.664969 |    271.404001 | Margot Michaud                                                                                                                                                        |
| 476 |    902.224312 |    321.912286 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 477 |    829.201500 |    189.261465 | Chris huh                                                                                                                                                             |
| 478 |    936.080044 |    309.750630 | Scott Hartman                                                                                                                                                         |
| 479 |     64.346416 |     94.742991 | Margot Michaud                                                                                                                                                        |
| 480 |    439.315099 |    499.893792 | Ferran Sayol                                                                                                                                                          |
| 481 |    777.443686 |    228.378801 | Martin R. Smith                                                                                                                                                       |
| 482 |    527.322159 |    188.626097 | Chris huh                                                                                                                                                             |
| 483 |    959.718417 |    611.092838 | Tasman Dixon                                                                                                                                                          |
| 484 |   1001.168506 |    257.860916 | Ignacio Contreras                                                                                                                                                     |
| 485 |     82.040667 |    674.621573 | Zimices                                                                                                                                                               |
| 486 |    660.648690 |    721.799037 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 487 |    448.021207 |    108.557302 | Chris huh                                                                                                                                                             |
| 488 |    668.095540 |    438.915196 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 489 |    608.561029 |      8.800511 | Margot Michaud                                                                                                                                                        |
| 490 |    653.660604 |    332.411814 | Jagged Fang Designs                                                                                                                                                   |
| 491 |    989.688304 |    559.935047 | Inessa Voet                                                                                                                                                           |
| 492 |    570.697721 |    452.441223 | Chris huh                                                                                                                                                             |
| 493 |    844.374856 |    317.995942 | NA                                                                                                                                                                    |
| 494 |    252.673464 |    715.528871 | Birgit Lang                                                                                                                                                           |
| 495 |    688.864259 |    649.366792 | B. Duygu Özpolat                                                                                                                                                      |
| 496 |     93.772422 |    791.654212 | Scott Hartman                                                                                                                                                         |
| 497 |    526.130751 |     28.043062 | Smokeybjb                                                                                                                                                             |
| 498 |    529.275345 |    543.393785 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 499 |    780.829544 |    348.587484 | Robert Gay                                                                                                                                                            |
| 500 |   1015.343593 |    606.568603 | Gareth Monger                                                                                                                                                         |
| 501 |    116.420352 |    718.219684 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 502 |    590.126068 |     34.302602 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 503 |    309.424444 |    599.779645 | Thibaut Brunet                                                                                                                                                        |
| 504 |    552.837794 |    702.991169 | Andy Wilson                                                                                                                                                           |
| 505 |    699.113977 |      6.597108 | Christine Axon                                                                                                                                                        |
| 506 |    761.984601 |    564.798474 | Gareth Monger                                                                                                                                                         |
| 507 |    992.160758 |     78.783983 | Markus A. Grohme                                                                                                                                                      |
| 508 |     53.773324 |    565.228521 | Zimices                                                                                                                                                               |
| 509 |    472.903997 |    137.055531 | Christine Axon                                                                                                                                                        |
| 510 |     66.701492 |    130.582156 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 511 |    324.979216 |    470.745197 | Jagged Fang Designs                                                                                                                                                   |
| 512 |    405.309431 |    709.428556 | Jagged Fang Designs                                                                                                                                                   |
| 513 |    208.493106 |    299.977944 | www.studiospectre.com                                                                                                                                                 |
| 514 |    227.399870 |    414.590205 | Markus A. Grohme                                                                                                                                                      |

    #> Your tweet has been posted!
