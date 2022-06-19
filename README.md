
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

Andrew A. Farke, Martin R. Smith, after Skovsted et al 2015, Jaime
Headden, T. Michael Keesey, L. Shyamal, Steven Traver, Ferran Sayol,
Ewald Rübsamen, Zimices, Maija Karala, Tauana J. Cunha, Jesús Gómez,
vectorized by Zimices, T. Michael Keesey (after Tillyard), Jagged Fang
Designs, Matt Crook, Margot Michaud, Gareth Monger, Beth Reinke, Sarah
Werning, Carlos Cano-Barbacil, Josep Marti Solans, Tasman Dixon, Birgit
Lang, david maas / dave hone, Christopher Watson (photo) and T. Michael
Keesey (vectorization), Scott Hartman, Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Kamil S. Jaron, Darren Naish (vectorize by T. Michael Keesey), Gabriela
Palomo-Munoz, Emma Kissling, Derek Bakken (photograph) and T. Michael
Keesey (vectorization), Mason McNair, Chris huh, Ingo Braasch, Lisa
Byrne, Smokeybjb, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Lankester Edwin Ray (vectorized by T. Michael Keesey), Mali’o Kodis,
photograph by G. Giribet, Patrick Fisher (vectorized by T. Michael
Keesey), Nobu Tamura, Alexander Schmidt-Lebuhn, T. K. Robinson, NASA, C.
Camilo Julián-Caballero, Tracy A. Heath, Nobu Tamura (vectorized by T.
Michael Keesey), Armin Reindl, Jose Carlos Arenas-Monroy, Didier
Descouens (vectorized by T. Michael Keesey), Collin Gross, Ignacio
Contreras, Andy Wilson, CNZdenek, Markus A. Grohme, Noah Schlottman,
photo from Casey Dunn, Mathew Wedel, xgirouxb, Julia B McHugh, Scarlet23
(vectorized by T. Michael Keesey), Matt Martyniuk, Tony Ayling
(vectorized by T. Michael Keesey), Jimmy Bernot, Owen Jones (derived
from a CC-BY 2.0 photograph by Paulo B. Chaves), Ernst Haeckel
(vectorized by T. Michael Keesey), Dave Angelini, Scott Reid, Dean
Schnabel, Steven Coombs, Nobu Tamura, vectorized by Zimices, FJDegrange,
Harold N Eyster, Dmitry Bogdanov, Roberto Díaz Sibaja, Manabu Sakamoto,
Mo Hassan, Chuanixn Yu, Robert Bruce Horsfall, vectorized by Zimices,
Melissa Broussard, Sharon Wegner-Larsen, Alan Manson (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Benjamin
Monod-Broca, Sergio A. Muñoz-Gómez, Taenadoman, James I. Kirkland, Luis
Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Jonathan Wells, Fcb981
(vectorized by T. Michael Keesey), Michael B. H. (vectorized by T.
Michael Keesey), Christine Axon, Ghedoghedo (vectorized by T. Michael
Keesey), Alexandre Vong, Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, Iain Reid, Anilocra (vectorization by Yan
Wong), Lukas Panzarin, Pete Buchholz, Shyamal, S.Martini, Erika
Schumacher, Mette Aumala, Brad McFeeters (vectorized by T. Michael
Keesey), Cesar Julian, Crystal Maier, Walter Vladimir, Anthony
Caravaggi, Tyler Greenfield, Matt Hayes, Katie S. Collins, I. Sáček,
Sr. (vectorized by T. Michael Keesey), Neil Kelley, Yusan Yang,
Caroline Harding, MAF (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Hans De Blauwe, Vijay Cavale (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Daniel Jaron,
Joseph Wolf, 1863 (vectorization by Dinah Challen), Farelli (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Daniel
Stadtmauer, Felix Vaux, Alex Slavenko, Skye McDavid, Joanna Wolfe,
Christoph Schomburg, Hans Hillewaert (vectorized by T. Michael Keesey),
Tyler McCraney, T. Michael Keesey (vectorization) and Larry Loos
(photography), Tony Ayling, Karina Garcia, Noah Schlottman, photo by
Casey Dunn, Charles R. Knight (vectorized by T. Michael Keesey), Kent
Sorgon, Danny Cicchetti (vectorized by T. Michael Keesey), T. Michael
Keesey (after Heinrich Harder), E. R. Waite & H. M. Hale (vectorized by
T. Michael Keesey), Aviceda (vectorized by T. Michael Keesey), FunkMonk,
Matthew E. Clapham, Henry Fairfield Osborn, vectorized by Zimices,
Michael P. Taylor, Emil Schmidt (vectorized by Maxime Dahirel), Mathilde
Cordellier, David Orr, Mali’o Kodis, photograph by Cordell Expeditions
at Cal Academy, Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Jay Matternes (vectorized by
T. Michael Keesey), Yan Wong from drawing in The Century Dictionary
(1911), Juan Carlos Jerí, Y. de Hoev. (vectorized by T. Michael Keesey),
Geoff Shaw, Abraão Leite, FunkMonk \[Michael B.H.\] (modified by T.
Michael Keesey), Elisabeth Östman, Pranav Iyer (grey ideas), T.
Tischler, Chloé Schmidt, Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü,
Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael
Keesey, T. Michael Keesey (after James & al.), Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Michele M Tobias, Darren Naish (vectorized by T. Michael
Keesey), Steven Coombs (vectorized by T. Michael Keesey), U.S. National
Park Service (vectorized by William Gearty), Kai R. Caspar, Emma Hughes,
Craig Dylke, wsnaccad, Maxime Dahirel, Mihai Dragos (vectorized by T.
Michael Keesey), Henry Lydecker, Michael Scroggie, Ben Liebeskind,
Acrocynus (vectorized by T. Michael Keesey), Gustav Mützel, Dmitry
Bogdanov and FunkMonk (vectorized by T. Michael Keesey), Robbie N. Cada
(modified by T. Michael Keesey), Allison Pease, Michelle Site, T.
Michael Keesey (after Walker & al.), Young and Zhao (1972:figure 4),
modified by Michael P. Taylor, Josefine Bohr Brask, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    735.926080 |     95.304495 | Andrew A. Farke                                                                                                                                                       |
|   2 |    581.333767 |    596.212149 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
|   3 |    798.396904 |    606.827170 | Jaime Headden                                                                                                                                                         |
|   4 |    111.208400 |    168.115497 | T. Michael Keesey                                                                                                                                                     |
|   5 |    230.237789 |    462.340971 | T. Michael Keesey                                                                                                                                                     |
|   6 |    835.411343 |    251.026013 | L. Shyamal                                                                                                                                                            |
|   7 |    136.675046 |    555.526752 | Steven Traver                                                                                                                                                         |
|   8 |    328.181914 |    379.355426 | NA                                                                                                                                                                    |
|   9 |    434.066723 |    636.744499 | Ferran Sayol                                                                                                                                                          |
|  10 |    915.865235 |    639.472777 | Ewald Rübsamen                                                                                                                                                        |
|  11 |    303.795378 |    752.694377 | Zimices                                                                                                                                                               |
|  12 |    368.192143 |    510.483253 | Maija Karala                                                                                                                                                          |
|  13 |    448.273029 |    344.641015 | Zimices                                                                                                                                                               |
|  14 |    159.785371 |    251.512818 | Tauana J. Cunha                                                                                                                                                       |
|  15 |    898.371031 |    702.991847 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
|  16 |    571.790379 |     91.747411 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
|  17 |    222.092752 |    384.470020 | Zimices                                                                                                                                                               |
|  18 |    670.038496 |    459.182815 | Jagged Fang Designs                                                                                                                                                   |
|  19 |    638.022435 |    321.993744 | Matt Crook                                                                                                                                                            |
|  20 |    908.504011 |    118.078795 | Margot Michaud                                                                                                                                                        |
|  21 |    493.557006 |    470.822515 | Gareth Monger                                                                                                                                                         |
|  22 |    402.873695 |    274.716728 | Beth Reinke                                                                                                                                                           |
|  23 |    151.363641 |     89.038993 | Sarah Werning                                                                                                                                                         |
|  24 |    262.166083 |    140.063068 | NA                                                                                                                                                                    |
|  25 |    757.079153 |    734.188131 | Carlos Cano-Barbacil                                                                                                                                                  |
|  26 |    101.637499 |    423.273688 | Josep Marti Solans                                                                                                                                                    |
|  27 |    774.257520 |     25.055761 | Tasman Dixon                                                                                                                                                          |
|  28 |    794.376176 |    331.306427 | Gareth Monger                                                                                                                                                         |
|  29 |    474.504929 |    127.430287 | Birgit Lang                                                                                                                                                           |
|  30 |    961.401683 |    421.311718 | Margot Michaud                                                                                                                                                        |
|  31 |    301.950569 |    597.194215 | Margot Michaud                                                                                                                                                        |
|  32 |    387.177514 |    209.287402 | Sarah Werning                                                                                                                                                         |
|  33 |    931.650497 |    180.677925 | david maas / dave hone                                                                                                                                                |
|  34 |    787.617999 |    503.977220 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
|  35 |    762.976634 |    431.689640 | Scott Hartman                                                                                                                                                         |
|  36 |    429.019265 |     58.141738 | Margot Michaud                                                                                                                                                        |
|  37 |    171.618993 |    732.703367 | Matt Crook                                                                                                                                                            |
|  38 |    272.228789 |    232.396047 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  39 |    414.539272 |     98.149528 | Matt Crook                                                                                                                                                            |
|  40 |    421.921752 |    749.994797 | Kamil S. Jaron                                                                                                                                                        |
|  41 |    657.350616 |    653.942404 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
|  42 |    959.322376 |    535.713969 | Steven Traver                                                                                                                                                         |
|  43 |    600.939888 |    191.576690 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  44 |    408.179422 |    414.151733 | Emma Kissling                                                                                                                                                         |
|  45 |    119.234325 |     22.489197 | Jagged Fang Designs                                                                                                                                                   |
|  46 |    629.574293 |    685.320696 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
|  47 |    547.295548 |    757.900997 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  48 |    322.503730 |    122.825097 | Mason McNair                                                                                                                                                          |
|  49 |    116.188703 |    644.942425 | Chris huh                                                                                                                                                             |
|  50 |    300.012190 |    691.383506 | Ingo Braasch                                                                                                                                                          |
|  51 |    150.757965 |    330.227439 | Lisa Byrne                                                                                                                                                            |
|  52 |     70.612135 |    294.615502 | Smokeybjb                                                                                                                                                             |
|  53 |    566.401664 |     32.115284 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  54 |    272.388443 |     36.806665 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
|  55 |    982.322872 |    273.937435 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
|  56 |    891.830579 |    387.319299 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
|  57 |     71.686341 |    722.141210 | Zimices                                                                                                                                                               |
|  58 |    868.516458 |     44.436669 | Nobu Tamura                                                                                                                                                           |
|  59 |    610.562604 |    417.736058 | Ferran Sayol                                                                                                                                                          |
|  60 |    677.791252 |    549.905956 | NA                                                                                                                                                                    |
|  61 |    852.734105 |    457.574111 | Jagged Fang Designs                                                                                                                                                   |
|  62 |     33.624487 |    207.058528 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  63 |    954.528216 |    762.052228 | Jagged Fang Designs                                                                                                                                                   |
|  64 |    709.455994 |    226.664914 | Scott Hartman                                                                                                                                                         |
|  65 |    292.354728 |    313.242952 | T. K. Robinson                                                                                                                                                        |
|  66 |    790.766092 |    669.721331 | Chris huh                                                                                                                                                             |
|  67 |    262.581020 |    537.770030 | NA                                                                                                                                                                    |
|  68 |     33.006995 |    581.941330 | NASA                                                                                                                                                                  |
|  69 |     95.405841 |    679.837563 | C. Camilo Julián-Caballero                                                                                                                                            |
|  70 |    536.467090 |    295.791814 | NA                                                                                                                                                                    |
|  71 |    479.436043 |    517.090766 | Tracy A. Heath                                                                                                                                                        |
|  72 |    285.529541 |    288.328753 | Gareth Monger                                                                                                                                                         |
|  73 |    263.413971 |    344.226076 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  74 |     23.081668 |    442.742974 | Armin Reindl                                                                                                                                                          |
|  75 |    974.954496 |     42.053293 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  76 |    802.198643 |    412.045966 | Gareth Monger                                                                                                                                                         |
|  77 |    330.191469 |    441.420888 | Smokeybjb                                                                                                                                                             |
|  78 |    563.514376 |    163.438013 | Matt Crook                                                                                                                                                            |
|  79 |    927.376398 |    227.776494 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
|  80 |    539.979901 |    148.459595 | Collin Gross                                                                                                                                                          |
|  81 |    137.862526 |    507.488213 | Ignacio Contreras                                                                                                                                                     |
|  82 |     56.975787 |     90.575629 | Andy Wilson                                                                                                                                                           |
|  83 |    673.996710 |     32.398101 | Jagged Fang Designs                                                                                                                                                   |
|  84 |    542.562891 |    680.871798 | T. Michael Keesey                                                                                                                                                     |
|  85 |    985.750034 |    699.385812 | T. Michael Keesey                                                                                                                                                     |
|  86 |    733.051028 |    382.716350 | Andy Wilson                                                                                                                                                           |
|  87 |    654.590976 |    156.563759 | CNZdenek                                                                                                                                                              |
|  88 |    311.744304 |    657.239805 | Markus A. Grohme                                                                                                                                                      |
|  89 |    662.248666 |    743.833418 | CNZdenek                                                                                                                                                              |
|  90 |     72.988565 |    230.496576 | Zimices                                                                                                                                                               |
|  91 |    991.087062 |    193.787000 | Matt Crook                                                                                                                                                            |
|  92 |    202.395677 |    167.686849 | Gareth Monger                                                                                                                                                         |
|  93 |    414.439542 |    549.683934 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
|  94 |    227.842094 |    620.456909 | Matt Crook                                                                                                                                                            |
|  95 |    690.829367 |    786.386647 | Markus A. Grohme                                                                                                                                                      |
|  96 |    578.652426 |    471.186251 | Mathew Wedel                                                                                                                                                          |
|  97 |     32.817064 |    501.519033 | xgirouxb                                                                                                                                                              |
|  98 |     36.446833 |     44.972504 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  99 |    149.082396 |    613.239052 | Julia B McHugh                                                                                                                                                        |
| 100 |    359.449576 |    336.307599 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 101 |    915.974208 |     14.217574 | Matt Martyniuk                                                                                                                                                        |
| 102 |    700.228782 |    199.150826 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 103 |    242.228429 |     62.212705 | Jagged Fang Designs                                                                                                                                                   |
| 104 |    440.882677 |    220.871860 | Matt Crook                                                                                                                                                            |
| 105 |    244.821041 |    645.000301 | Kamil S. Jaron                                                                                                                                                        |
| 106 |    405.914025 |    642.397754 | Jimmy Bernot                                                                                                                                                          |
| 107 |    578.670162 |    323.384387 | Margot Michaud                                                                                                                                                        |
| 108 |     42.749498 |    344.739630 | NA                                                                                                                                                                    |
| 109 |    491.851215 |    728.153931 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 110 |    849.140073 |    509.827256 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 111 |    476.820382 |    299.199704 | Zimices                                                                                                                                                               |
| 112 |    879.043422 |    352.981429 | Gareth Monger                                                                                                                                                         |
| 113 |    634.529655 |    568.107761 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 114 |    160.399582 |     40.654407 | Dave Angelini                                                                                                                                                         |
| 115 |    999.278084 |    742.804075 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 116 |     45.358488 |     73.844750 | Ignacio Contreras                                                                                                                                                     |
| 117 |    352.056426 |     11.751758 | Scott Reid                                                                                                                                                            |
| 118 |    493.800417 |     62.061215 | Scott Hartman                                                                                                                                                         |
| 119 |    153.165690 |    196.917855 | Jagged Fang Designs                                                                                                                                                   |
| 120 |    196.314395 |     55.950068 | Maija Karala                                                                                                                                                          |
| 121 |    191.975041 |    660.783423 | Dean Schnabel                                                                                                                                                         |
| 122 |   1006.019849 |    222.422436 | Steven Coombs                                                                                                                                                         |
| 123 |    461.506035 |     79.990363 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 124 |    782.320667 |    776.557077 | Steven Traver                                                                                                                                                         |
| 125 |    598.723256 |    212.906572 | FJDegrange                                                                                                                                                            |
| 126 |    169.824014 |    122.309170 | Andy Wilson                                                                                                                                                           |
| 127 |    488.648188 |    421.630832 | Chris huh                                                                                                                                                             |
| 128 |    249.019796 |    363.401064 | Gareth Monger                                                                                                                                                         |
| 129 |     74.879523 |    428.147688 | Harold N Eyster                                                                                                                                                       |
| 130 |    358.808847 |    457.542333 | Gareth Monger                                                                                                                                                         |
| 131 |    371.256677 |    354.179607 | Dmitry Bogdanov                                                                                                                                                       |
| 132 |    789.295329 |    463.274156 | Andy Wilson                                                                                                                                                           |
| 133 |    401.488204 |    158.791291 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 134 |     59.862875 |    769.945083 | Roberto Díaz Sibaja                                                                                                                                                   |
| 135 |    894.970386 |    493.559639 | Manabu Sakamoto                                                                                                                                                       |
| 136 |   1007.921550 |    288.174277 | Mo Hassan                                                                                                                                                             |
| 137 |    384.077258 |    674.194627 | Chuanixn Yu                                                                                                                                                           |
| 138 |    700.411535 |    253.810331 | xgirouxb                                                                                                                                                              |
| 139 |    637.535979 |    284.370523 | Zimices                                                                                                                                                               |
| 140 |    283.449581 |     55.750350 | Jagged Fang Designs                                                                                                                                                   |
| 141 |    742.589830 |    248.648446 | Matt Crook                                                                                                                                                            |
| 142 |     82.492515 |    610.608575 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 143 |    739.983746 |    777.985228 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 144 |    414.327778 |    704.616483 | Melissa Broussard                                                                                                                                                     |
| 145 |     12.919134 |    663.833847 | T. Michael Keesey                                                                                                                                                     |
| 146 |    663.048145 |    119.859842 | Steven Coombs                                                                                                                                                         |
| 147 |    606.164344 |    365.054667 | Sharon Wegner-Larsen                                                                                                                                                  |
| 148 |    833.206331 |    773.395992 | T. Michael Keesey                                                                                                                                                     |
| 149 |     39.506342 |     84.766117 | Lisa Byrne                                                                                                                                                            |
| 150 |    740.718393 |    571.083218 | Jagged Fang Designs                                                                                                                                                   |
| 151 |    372.323951 |    177.121530 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 152 |    195.133348 |    775.789843 | NA                                                                                                                                                                    |
| 153 |    997.515388 |     15.133970 | Markus A. Grohme                                                                                                                                                      |
| 154 |    671.874185 |     10.375412 | Dean Schnabel                                                                                                                                                         |
| 155 |    480.860114 |    499.932122 | Margot Michaud                                                                                                                                                        |
| 156 |    791.331929 |    316.845679 | Ferran Sayol                                                                                                                                                          |
| 157 |    491.556838 |    549.165825 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 158 |    295.920560 |    192.049677 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 159 |    249.107572 |    793.556063 | Benjamin Monod-Broca                                                                                                                                                  |
| 160 |   1010.877466 |     80.636489 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 161 |    158.217544 |    469.163050 | Margot Michaud                                                                                                                                                        |
| 162 |    285.406494 |    488.333505 | Taenadoman                                                                                                                                                            |
| 163 |    196.669590 |    215.626177 | Zimices                                                                                                                                                               |
| 164 |    798.707695 |    156.643599 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 165 |    200.520653 |    114.887883 | Jonathan Wells                                                                                                                                                        |
| 166 |    483.555402 |    396.417834 | Ferran Sayol                                                                                                                                                          |
| 167 |    502.428573 |    231.292578 | Andy Wilson                                                                                                                                                           |
| 168 |    889.396969 |    739.642387 | T. Michael Keesey                                                                                                                                                     |
| 169 |    751.397859 |    163.883750 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 170 |    628.325253 |     38.618942 | Ferran Sayol                                                                                                                                                          |
| 171 |    686.477874 |    394.194525 | Gareth Monger                                                                                                                                                         |
| 172 |     31.980156 |    663.547811 | Chris huh                                                                                                                                                             |
| 173 |    395.545745 |    786.845856 | Matt Crook                                                                                                                                                            |
| 174 |    605.983977 |    488.904154 | Andy Wilson                                                                                                                                                           |
| 175 |    466.420463 |      7.558461 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 176 |    211.847761 |    205.359340 | Margot Michaud                                                                                                                                                        |
| 177 |    290.660392 |    417.860707 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 178 |     85.946496 |    354.754168 | Scott Hartman                                                                                                                                                         |
| 179 |    123.335241 |    215.532842 | Christine Axon                                                                                                                                                        |
| 180 |     65.717416 |    264.551967 | Matt Crook                                                                                                                                                            |
| 181 |    268.288201 |    728.910227 | C. Camilo Julián-Caballero                                                                                                                                            |
| 182 |    132.100103 |     53.409734 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 183 |    589.108822 |    260.260796 | Jagged Fang Designs                                                                                                                                                   |
| 184 |     23.320822 |    130.561882 | Matt Crook                                                                                                                                                            |
| 185 |    406.176058 |    449.051192 | Sarah Werning                                                                                                                                                         |
| 186 |    788.603692 |    134.673655 | Margot Michaud                                                                                                                                                        |
| 187 |    459.341926 |    391.367225 | Alexandre Vong                                                                                                                                                        |
| 188 |    873.067482 |    779.568137 | Alexandre Vong                                                                                                                                                        |
| 189 |    716.920988 |    664.669828 | NA                                                                                                                                                                    |
| 190 |    826.747808 |     64.381302 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 191 |    371.170334 |    245.005340 | NA                                                                                                                                                                    |
| 192 |    683.331106 |    361.521463 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 193 |    657.769223 |    771.455601 | Ignacio Contreras                                                                                                                                                     |
| 194 |    365.704423 |    626.434637 | Iain Reid                                                                                                                                                             |
| 195 |   1001.962820 |     61.251793 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 196 |    906.190672 |     55.470720 | Margot Michaud                                                                                                                                                        |
| 197 |    584.489615 |    715.846880 | Steven Traver                                                                                                                                                         |
| 198 |    513.997181 |     49.089267 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 199 |    426.060521 |    145.166593 | Lukas Panzarin                                                                                                                                                        |
| 200 |    916.662401 |    555.916790 | Tracy A. Heath                                                                                                                                                        |
| 201 |    434.968632 |    768.417450 | Gareth Monger                                                                                                                                                         |
| 202 |    627.436210 |    124.536984 | L. Shyamal                                                                                                                                                            |
| 203 |     24.615523 |    373.255464 | T. Michael Keesey                                                                                                                                                     |
| 204 |    222.244289 |    239.234040 | Pete Buchholz                                                                                                                                                         |
| 205 |    636.567878 |    783.613958 | Julia B McHugh                                                                                                                                                        |
| 206 |    293.781739 |    470.337029 | Shyamal                                                                                                                                                               |
| 207 |    986.887172 |    500.404155 | S.Martini                                                                                                                                                             |
| 208 |    857.780919 |     64.486310 | Tauana J. Cunha                                                                                                                                                       |
| 209 |    457.679847 |    562.606036 | Chris huh                                                                                                                                                             |
| 210 |    790.747213 |     63.624167 | Scott Hartman                                                                                                                                                         |
| 211 |   1009.634220 |    124.193236 | Beth Reinke                                                                                                                                                           |
| 212 |    233.050199 |    746.839156 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 213 |    197.291128 |    619.581535 | Erika Schumacher                                                                                                                                                      |
| 214 |    954.850062 |    198.538679 | Mette Aumala                                                                                                                                                          |
| 215 |    131.672764 |    494.674946 | Zimices                                                                                                                                                               |
| 216 |    440.762981 |    391.908551 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 217 |    903.109998 |    533.251974 | Scott Hartman                                                                                                                                                         |
| 218 |     73.900257 |     10.085018 | Cesar Julian                                                                                                                                                          |
| 219 |    478.532587 |    189.182907 | Crystal Maier                                                                                                                                                         |
| 220 |    517.952677 |    420.151334 | Walter Vladimir                                                                                                                                                       |
| 221 |    631.590012 |    156.246010 | Steven Traver                                                                                                                                                         |
| 222 |    960.655969 |      7.357541 | Scott Hartman                                                                                                                                                         |
| 223 |    660.889267 |    323.975572 | Anthony Caravaggi                                                                                                                                                     |
| 224 |    624.613770 |    774.252438 | Tauana J. Cunha                                                                                                                                                       |
| 225 |    990.302295 |    352.681215 | Ferran Sayol                                                                                                                                                          |
| 226 |    491.846988 |    266.734168 | Matt Crook                                                                                                                                                            |
| 227 |     75.720365 |    319.838345 | NA                                                                                                                                                                    |
| 228 |    296.620929 |    791.280458 | Birgit Lang                                                                                                                                                           |
| 229 |    133.286445 |    364.452687 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 230 |    524.424459 |    373.537607 | Tyler Greenfield                                                                                                                                                      |
| 231 |    131.839253 |    791.588215 | Roberto Díaz Sibaja                                                                                                                                                   |
| 232 |    386.333928 |     12.472946 | Margot Michaud                                                                                                                                                        |
| 233 |    633.823754 |    354.542927 | T. Michael Keesey                                                                                                                                                     |
| 234 |    922.550865 |    257.106743 | Zimices                                                                                                                                                               |
| 235 |    494.807811 |    785.586648 | Matt Hayes                                                                                                                                                            |
| 236 |    679.912208 |    612.680201 | Zimices                                                                                                                                                               |
| 237 |   1015.225701 |    700.913709 | Gareth Monger                                                                                                                                                         |
| 238 |     38.106662 |    767.131935 | Katie S. Collins                                                                                                                                                      |
| 239 |    412.177167 |    381.229036 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 240 |    624.828349 |    246.607970 | Matt Crook                                                                                                                                                            |
| 241 |    385.580424 |    713.075055 | Matt Crook                                                                                                                                                            |
| 242 |    522.794311 |    792.817419 | Scott Hartman                                                                                                                                                         |
| 243 |    815.098317 |    480.870444 | Harold N Eyster                                                                                                                                                       |
| 244 |    775.885371 |    254.210670 | L. Shyamal                                                                                                                                                            |
| 245 |    177.574492 |    308.310820 | Neil Kelley                                                                                                                                                           |
| 246 |    348.197981 |     61.802816 | Zimices                                                                                                                                                               |
| 247 |    602.089128 |    295.916127 | Yusan Yang                                                                                                                                                            |
| 248 |    616.136186 |    314.256391 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 249 |     90.003644 |    124.439537 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
| 250 |    835.174511 |    366.557594 | Katie S. Collins                                                                                                                                                      |
| 251 |    991.051775 |    143.697330 | Mason McNair                                                                                                                                                          |
| 252 |    701.888501 |    701.536368 | Matt Crook                                                                                                                                                            |
| 253 |    995.626166 |    463.605489 | NA                                                                                                                                                                    |
| 254 |      7.550497 |    717.046278 | Gareth Monger                                                                                                                                                         |
| 255 |   1004.424628 |    479.170890 | Jagged Fang Designs                                                                                                                                                   |
| 256 |    593.443601 |    239.079244 | Andy Wilson                                                                                                                                                           |
| 257 |    927.035875 |    286.985586 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 258 |    568.015647 |    236.668663 | Katie S. Collins                                                                                                                                                      |
| 259 |    853.721366 |    321.871276 | Matt Crook                                                                                                                                                            |
| 260 |    225.178131 |    321.746065 | Kamil S. Jaron                                                                                                                                                        |
| 261 |     17.746643 |    689.980272 | Daniel Jaron                                                                                                                                                          |
| 262 |    753.337276 |    201.265135 | Chris huh                                                                                                                                                             |
| 263 |    633.168622 |    495.159131 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 264 |    618.789889 |    520.215759 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 265 |     17.227251 |    233.040039 | Armin Reindl                                                                                                                                                          |
| 266 |    727.540320 |    695.093819 | Walter Vladimir                                                                                                                                                       |
| 267 |    898.982650 |    233.485482 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 268 |    552.340617 |    632.761875 | Ferran Sayol                                                                                                                                                          |
| 269 |    288.145062 |    566.222078 | Daniel Stadtmauer                                                                                                                                                     |
| 270 |    498.856616 |     94.364330 | NA                                                                                                                                                                    |
| 271 |    890.791750 |    517.837709 | Felix Vaux                                                                                                                                                            |
| 272 |    786.510069 |    302.138310 | Alex Slavenko                                                                                                                                                         |
| 273 |    733.420052 |    559.747600 | Zimices                                                                                                                                                               |
| 274 |    747.311250 |      8.282285 | NA                                                                                                                                                                    |
| 275 |     60.945644 |    374.964888 | Margot Michaud                                                                                                                                                        |
| 276 |    684.656339 |    428.936504 | Skye McDavid                                                                                                                                                          |
| 277 |    535.923677 |    169.226199 | Joanna Wolfe                                                                                                                                                          |
| 278 |    409.685760 |    506.298343 | Christoph Schomburg                                                                                                                                                   |
| 279 |    114.133683 |    663.711540 | Scott Hartman                                                                                                                                                         |
| 280 |    939.727580 |    600.213193 | Carlos Cano-Barbacil                                                                                                                                                  |
| 281 |    193.480700 |    413.356235 | Katie S. Collins                                                                                                                                                      |
| 282 |    824.133050 |    334.619085 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 283 |    177.398824 |    177.282591 | Tyler McCraney                                                                                                                                                        |
| 284 |    430.382978 |    784.366455 | NA                                                                                                                                                                    |
| 285 |   1000.482266 |    770.752837 | Matt Crook                                                                                                                                                            |
| 286 |    700.384050 |    177.417059 | Zimices                                                                                                                                                               |
| 287 |    341.298518 |    258.428490 | NA                                                                                                                                                                    |
| 288 |    155.833443 |    453.904549 | Margot Michaud                                                                                                                                                        |
| 289 |    350.399211 |    695.898311 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 290 |    419.178751 |    174.918136 | Kamil S. Jaron                                                                                                                                                        |
| 291 |    582.250864 |    384.821544 | Erika Schumacher                                                                                                                                                      |
| 292 |    330.104217 |    635.147555 | Andy Wilson                                                                                                                                                           |
| 293 |    559.089775 |    344.189408 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 294 |    698.419420 |    290.329634 | Ignacio Contreras                                                                                                                                                     |
| 295 |    138.916146 |    124.300036 | Ferran Sayol                                                                                                                                                          |
| 296 |    211.894177 |    561.355514 | Tony Ayling                                                                                                                                                           |
| 297 |    534.214690 |    557.421947 | Steven Coombs                                                                                                                                                         |
| 298 |    225.431925 |     99.146441 | Jonathan Wells                                                                                                                                                        |
| 299 |    648.721157 |    260.322437 | Karina Garcia                                                                                                                                                         |
| 300 |     29.764926 |    401.719251 | Collin Gross                                                                                                                                                          |
| 301 |     96.124904 |    140.047130 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 302 |    603.589990 |    111.516709 | Scott Reid                                                                                                                                                            |
| 303 |    663.549911 |    730.036758 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 304 |    891.213224 |    580.205915 | Jagged Fang Designs                                                                                                                                                   |
| 305 |    384.025013 |    574.248738 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 306 |    631.365340 |    218.874025 | Cesar Julian                                                                                                                                                          |
| 307 |    842.112537 |    174.572781 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 308 |     81.689551 |    764.811751 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 309 |    777.177420 |    292.368443 | Kent Sorgon                                                                                                                                                           |
| 310 |    158.010871 |    437.588857 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 311 |    371.279527 |    374.028918 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 312 |    725.192882 |    147.124847 | Chris huh                                                                                                                                                             |
| 313 |    734.876182 |    323.651122 | Andy Wilson                                                                                                                                                           |
| 314 |    843.309284 |    551.373242 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 315 |    616.407199 |     59.601074 | Steven Traver                                                                                                                                                         |
| 316 |    347.632323 |    189.440690 | Markus A. Grohme                                                                                                                                                      |
| 317 |     78.979738 |    248.680806 | Scott Hartman                                                                                                                                                         |
| 318 |    205.359354 |     31.960953 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 319 |    301.178432 |    331.730530 | FunkMonk                                                                                                                                                              |
| 320 |    243.082580 |     11.836711 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 321 |    833.554835 |     87.764324 | Gareth Monger                                                                                                                                                         |
| 322 |    401.049784 |    359.298216 | Matt Crook                                                                                                                                                            |
| 323 |   1004.023570 |    654.769919 | NA                                                                                                                                                                    |
| 324 |    452.980579 |    101.973287 | Matthew E. Clapham                                                                                                                                                    |
| 325 |      7.231615 |    107.232762 | Dean Schnabel                                                                                                                                                         |
| 326 |    787.570353 |    693.339306 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 327 |     96.545801 |    781.136586 | Ferran Sayol                                                                                                                                                          |
| 328 |    818.973996 |    395.405380 | Gareth Monger                                                                                                                                                         |
| 329 |    357.214067 |     44.589893 | Michael P. Taylor                                                                                                                                                     |
| 330 |    840.545405 |    493.561098 | Gareth Monger                                                                                                                                                         |
| 331 |    169.412687 |    205.825046 | Dean Schnabel                                                                                                                                                         |
| 332 |    299.138114 |     17.441734 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 333 |    160.867998 |    679.415620 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 334 |    971.221443 |    774.282635 | Mathilde Cordellier                                                                                                                                                   |
| 335 |    964.134655 |    347.747476 | Steven Traver                                                                                                                                                         |
| 336 |    953.113158 |    733.117016 | David Orr                                                                                                                                                             |
| 337 |    989.052760 |    263.267834 | Matt Crook                                                                                                                                                            |
| 338 |    864.195267 |    172.213876 | Ferran Sayol                                                                                                                                                          |
| 339 |    111.439486 |    381.475854 | Matt Crook                                                                                                                                                            |
| 340 |    901.292041 |    347.685822 | Alexandre Vong                                                                                                                                                        |
| 341 |    127.170226 |    302.573651 | Jagged Fang Designs                                                                                                                                                   |
| 342 |    997.588321 |    606.527994 | Margot Michaud                                                                                                                                                        |
| 343 |    547.939389 |    591.121447 | NA                                                                                                                                                                    |
| 344 |    435.961878 |    795.541125 | Markus A. Grohme                                                                                                                                                      |
| 345 |    140.601538 |    168.123775 | NA                                                                                                                                                                    |
| 346 |    693.115275 |     44.405428 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 347 |    179.857627 |     64.802254 | Tasman Dixon                                                                                                                                                          |
| 348 |    177.110281 |    147.748209 | Tracy A. Heath                                                                                                                                                        |
| 349 |     88.917577 |    501.223193 | Jagged Fang Designs                                                                                                                                                   |
| 350 |    249.350301 |    408.164489 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 351 |    827.063369 |    443.298816 | Gareth Monger                                                                                                                                                         |
| 352 |    819.451778 |    290.532569 | Jaime Headden                                                                                                                                                         |
| 353 |    665.608677 |    626.610763 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 354 |     58.245333 |    789.961224 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 355 |    888.937189 |     32.116059 | Markus A. Grohme                                                                                                                                                      |
| 356 |    323.748229 |    555.944448 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 357 |     13.079100 |     73.577659 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 358 |    786.167404 |    445.122523 | Juan Carlos Jerí                                                                                                                                                      |
| 359 |    517.869150 |    657.384861 | NA                                                                                                                                                                    |
| 360 |    457.583164 |    490.355081 | FunkMonk                                                                                                                                                              |
| 361 |    517.121965 |      8.336820 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 362 |    365.919172 |    116.692356 | CNZdenek                                                                                                                                                              |
| 363 |     88.273442 |    450.748234 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 364 |    638.701311 |     18.590475 | Roberto Díaz Sibaja                                                                                                                                                   |
| 365 |    433.425943 |      5.226312 | Jagged Fang Designs                                                                                                                                                   |
| 366 |    352.467119 |    305.709033 | Birgit Lang                                                                                                                                                           |
| 367 |     12.856368 |    334.858184 | Gareth Monger                                                                                                                                                         |
| 368 |    706.937587 |    474.708991 | Steven Traver                                                                                                                                                         |
| 369 |    327.659959 |    456.392393 | Chris huh                                                                                                                                                             |
| 370 |    351.967172 |    767.890245 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 371 |    884.319468 |    318.843546 | Margot Michaud                                                                                                                                                        |
| 372 |   1010.929550 |    428.892972 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 373 |    193.195285 |    496.190816 | Geoff Shaw                                                                                                                                                            |
| 374 |    221.488210 |    785.898104 | Matt Crook                                                                                                                                                            |
| 375 |    459.751075 |    548.656679 | Gareth Monger                                                                                                                                                         |
| 376 |     75.561623 |    336.560413 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 377 |    220.465428 |    409.343328 | Abraão Leite                                                                                                                                                          |
| 378 |    886.184838 |    506.974058 | Chris huh                                                                                                                                                             |
| 379 |     61.022731 |    528.403560 | T. Michael Keesey                                                                                                                                                     |
| 380 |     99.818938 |    349.756875 | Jagged Fang Designs                                                                                                                                                   |
| 381 |    380.517178 |    436.160809 | Steven Coombs                                                                                                                                                         |
| 382 |    419.655231 |    484.921868 | Felix Vaux                                                                                                                                                            |
| 383 |    234.387777 |    589.076920 | Markus A. Grohme                                                                                                                                                      |
| 384 |    335.053119 |    507.448462 | Gareth Monger                                                                                                                                                         |
| 385 |    573.680355 |    297.098757 | Margot Michaud                                                                                                                                                        |
| 386 |    538.640253 |    438.553393 | Kamil S. Jaron                                                                                                                                                        |
| 387 |    531.292365 |    215.408624 | Steven Traver                                                                                                                                                         |
| 388 |    318.493132 |    474.653995 | Tracy A. Heath                                                                                                                                                        |
| 389 |    851.181186 |     17.501955 | Roberto Díaz Sibaja                                                                                                                                                   |
| 390 |    841.935620 |    415.240267 | L. Shyamal                                                                                                                                                            |
| 391 |    348.336799 |    792.379066 | Chris huh                                                                                                                                                             |
| 392 |     53.817156 |    487.780166 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 393 |    740.991431 |    666.712194 | Iain Reid                                                                                                                                                             |
| 394 |     56.685448 |    657.760971 | Elisabeth Östman                                                                                                                                                      |
| 395 |    607.483809 |      6.297430 | Ignacio Contreras                                                                                                                                                     |
| 396 |    474.343337 |    221.188038 | Gareth Monger                                                                                                                                                         |
| 397 |    959.769748 |    680.448168 | Smokeybjb                                                                                                                                                             |
| 398 |    702.526945 |    604.984610 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 399 |    202.693876 |    370.152664 | T. Tischler                                                                                                                                                           |
| 400 |    628.607365 |    754.816740 | Armin Reindl                                                                                                                                                          |
| 401 |    596.285940 |    441.333693 | Gareth Monger                                                                                                                                                         |
| 402 |     73.280169 |     50.127825 | Felix Vaux                                                                                                                                                            |
| 403 |    172.527654 |    361.386219 | Gareth Monger                                                                                                                                                         |
| 404 |    894.793582 |    596.800318 | Jagged Fang Designs                                                                                                                                                   |
| 405 |    108.249453 |    102.460098 | S.Martini                                                                                                                                                             |
| 406 |    334.202573 |    672.540151 | Shyamal                                                                                                                                                               |
| 407 |    575.517042 |    452.598897 | Chris huh                                                                                                                                                             |
| 408 |    442.652372 |    698.429537 | Chloé Schmidt                                                                                                                                                         |
| 409 |    392.170939 |    696.656636 | Jagged Fang Designs                                                                                                                                                   |
| 410 |    136.826890 |    140.648623 | Steven Coombs                                                                                                                                                         |
| 411 |    826.805352 |    708.042885 | Steven Traver                                                                                                                                                         |
| 412 |    858.744098 |    477.505600 | Juan Carlos Jerí                                                                                                                                                      |
| 413 |    545.341725 |    548.546194 | Jagged Fang Designs                                                                                                                                                   |
| 414 |    926.419481 |    789.899614 | Zimices                                                                                                                                                               |
| 415 |    271.318914 |     84.009458 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 416 |    347.565785 |    755.335938 | Gareth Monger                                                                                                                                                         |
| 417 |    682.671536 |    357.032768 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 418 |    636.291560 |    330.225579 | Ferran Sayol                                                                                                                                                          |
| 419 |    359.981558 |    164.934325 | Scott Hartman                                                                                                                                                         |
| 420 |    748.422608 |    233.746380 | Birgit Lang                                                                                                                                                           |
| 421 |    566.774699 |      7.030186 | Juan Carlos Jerí                                                                                                                                                      |
| 422 |    587.016451 |    180.383260 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 423 |    245.880849 |    711.506963 | NA                                                                                                                                                                    |
| 424 |    816.476217 |    435.830134 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 425 |    965.319467 |    141.479821 | Matt Crook                                                                                                                                                            |
| 426 |    893.047498 |    452.453323 | Markus A. Grohme                                                                                                                                                      |
| 427 |    317.540197 |    428.194828 | Jagged Fang Designs                                                                                                                                                   |
| 428 |    704.413940 |    158.392844 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 429 |    841.006950 |    739.702240 | Matt Martyniuk                                                                                                                                                        |
| 430 |    725.811547 |    173.896620 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 431 |    870.006625 |    585.904185 | Michele M Tobias                                                                                                                                                      |
| 432 |    370.923265 |    319.579526 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 433 |    787.689639 |    791.058284 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 434 |    384.520774 |    555.517861 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 435 |    362.351339 |    579.022584 | Scott Hartman                                                                                                                                                         |
| 436 |     66.142596 |    629.326423 | FunkMonk                                                                                                                                                              |
| 437 |    729.395545 |    345.159091 | Gareth Monger                                                                                                                                                         |
| 438 |    369.782919 |    445.752853 | Chris huh                                                                                                                                                             |
| 439 |    842.148331 |    471.719751 | NA                                                                                                                                                                    |
| 440 |    191.513498 |    609.350808 | Collin Gross                                                                                                                                                          |
| 441 |    779.800972 |    115.424517 | Tasman Dixon                                                                                                                                                          |
| 442 |    633.670958 |    385.535552 | Zimices                                                                                                                                                               |
| 443 |    964.207674 |    710.435799 | Felix Vaux                                                                                                                                                            |
| 444 |    455.939370 |    185.465494 | Beth Reinke                                                                                                                                                           |
| 445 |      5.205484 |    199.333017 | Gareth Monger                                                                                                                                                         |
| 446 |    525.610154 |    409.579678 | NA                                                                                                                                                                    |
| 447 |    773.671000 |    270.482587 | Kai R. Caspar                                                                                                                                                         |
| 448 |    711.451284 |    587.520398 | Emma Hughes                                                                                                                                                           |
| 449 |    369.643346 |    327.719077 | Craig Dylke                                                                                                                                                           |
| 450 |    725.974219 |    638.041413 | wsnaccad                                                                                                                                                              |
| 451 |     12.338531 |     17.462639 | Zimices                                                                                                                                                               |
| 452 |     65.967387 |    571.411631 | Maxime Dahirel                                                                                                                                                        |
| 453 |    203.292749 |      7.547480 | Andy Wilson                                                                                                                                                           |
| 454 |    490.726440 |    243.670817 | Margot Michaud                                                                                                                                                        |
| 455 |    179.489942 |    397.057170 | Chris huh                                                                                                                                                             |
| 456 |    386.748110 |    152.067640 | Felix Vaux                                                                                                                                                            |
| 457 |    510.385432 |    771.934111 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 458 |    794.337315 |    146.102406 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 459 |    998.599920 |    304.795935 | Gareth Monger                                                                                                                                                         |
| 460 |    791.093365 |    281.034693 | Henry Lydecker                                                                                                                                                        |
| 461 |    708.700532 |    767.593229 | Michael Scroggie                                                                                                                                                      |
| 462 |    629.695462 |    471.058902 | NA                                                                                                                                                                    |
| 463 |     53.671909 |    752.871670 | Tracy A. Heath                                                                                                                                                        |
| 464 |    922.296285 |    737.021735 | Birgit Lang                                                                                                                                                           |
| 465 |    490.135277 |    708.835261 | Chris huh                                                                                                                                                             |
| 466 |    507.748470 |    429.862169 | Jagged Fang Designs                                                                                                                                                   |
| 467 |    805.111077 |    710.558790 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 468 |    110.063884 |    729.143652 | Ignacio Contreras                                                                                                                                                     |
| 469 |    262.820318 |    507.720107 | Jagged Fang Designs                                                                                                                                                   |
| 470 |    169.061523 |    181.734416 | Jagged Fang Designs                                                                                                                                                   |
| 471 |     25.243874 |    644.709890 | Shyamal                                                                                                                                                               |
| 472 |    564.103321 |    708.490619 | Scott Hartman                                                                                                                                                         |
| 473 |    545.127006 |     49.188719 | Gareth Monger                                                                                                                                                         |
| 474 |     54.013562 |    608.886973 | Gareth Monger                                                                                                                                                         |
| 475 |    927.984636 |    475.800513 | Matt Crook                                                                                                                                                            |
| 476 |    112.367391 |    312.938143 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 477 |     11.657095 |    174.774482 | Ferran Sayol                                                                                                                                                          |
| 478 |    585.486262 |    376.717020 | Jaime Headden                                                                                                                                                         |
| 479 |     11.105123 |    589.018694 | NA                                                                                                                                                                    |
| 480 |    744.562709 |     45.323416 | L. Shyamal                                                                                                                                                            |
| 481 |     27.680479 |    788.924988 | Jagged Fang Designs                                                                                                                                                   |
| 482 |    911.839019 |    154.593924 | C. Camilo Julián-Caballero                                                                                                                                            |
| 483 |    726.978111 |    307.045731 | Beth Reinke                                                                                                                                                           |
| 484 |    629.132365 |    544.718371 | Zimices                                                                                                                                                               |
| 485 |    767.454242 |    406.202240 | Ben Liebeskind                                                                                                                                                        |
| 486 |    302.525346 |    719.200257 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 487 |    217.091753 |    125.845028 | Jagged Fang Designs                                                                                                                                                   |
| 488 |    514.290595 |    371.382850 | Felix Vaux                                                                                                                                                            |
| 489 |    496.254282 |    315.927074 | Steven Coombs                                                                                                                                                         |
| 490 |    522.277848 |    688.954624 | Jagged Fang Designs                                                                                                                                                   |
| 491 |     15.961403 |    383.224441 | Jaime Headden                                                                                                                                                         |
| 492 |    421.284244 |     68.203936 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 493 |    218.296699 |    362.484988 | Gustav Mützel                                                                                                                                                         |
| 494 |    402.749409 |    654.278891 | Sarah Werning                                                                                                                                                         |
| 495 |   1006.879976 |    709.664648 | Kamil S. Jaron                                                                                                                                                        |
| 496 |    780.228495 |    435.311839 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                        |
| 497 |    180.672941 |    485.637047 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 498 |    874.002531 |    667.601073 | Andrew A. Farke                                                                                                                                                       |
| 499 |    846.066893 |    628.372903 | Gareth Monger                                                                                                                                                         |
| 500 |    827.482595 |    643.547812 | Jagged Fang Designs                                                                                                                                                   |
| 501 |    239.377406 |    722.469747 | Jagged Fang Designs                                                                                                                                                   |
| 502 |    882.964417 |      7.228753 | xgirouxb                                                                                                                                                              |
| 503 |    285.051481 |    360.332963 | Andy Wilson                                                                                                                                                           |
| 504 |     84.085176 |    277.067334 | Allison Pease                                                                                                                                                         |
| 505 |    605.952837 |    706.945372 | Birgit Lang                                                                                                                                                           |
| 506 |    708.999271 |     14.995961 | Chris huh                                                                                                                                                             |
| 507 |    865.043240 |    304.122069 | Nobu Tamura                                                                                                                                                           |
| 508 |     94.533152 |    219.225638 | Zimices                                                                                                                                                               |
| 509 |    383.443896 |    611.125825 | NA                                                                                                                                                                    |
| 510 |    714.730536 |    401.010391 | Jagged Fang Designs                                                                                                                                                   |
| 511 |    358.809596 |    654.918844 | Ferran Sayol                                                                                                                                                          |
| 512 |    542.041671 |     16.659169 | Steven Coombs                                                                                                                                                         |
| 513 |    593.497666 |    317.424008 | Scott Hartman                                                                                                                                                         |
| 514 |    656.711908 |      4.772755 | Jagged Fang Designs                                                                                                                                                   |
| 515 |    651.313702 |    132.457714 | Scott Hartman                                                                                                                                                         |
| 516 |    125.556695 |    625.304859 | Michelle Site                                                                                                                                                         |
| 517 |    170.432978 |    629.847575 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 518 |    580.819626 |     44.559691 | Margot Michaud                                                                                                                                                        |
| 519 |    933.057350 |     40.369379 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 520 |    919.739436 |    577.916892 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 521 |    608.467132 |    456.672737 | Markus A. Grohme                                                                                                                                                      |
| 522 |    779.235158 |    550.252196 | Beth Reinke                                                                                                                                                           |
| 523 |    121.361718 |    230.811599 | Markus A. Grohme                                                                                                                                                      |
| 524 |    409.948856 |    215.160526 | Emma Hughes                                                                                                                                                           |
| 525 |    623.411439 |    210.208724 | Ignacio Contreras                                                                                                                                                     |
| 526 |    684.965204 |    438.767370 | T. Michael Keesey                                                                                                                                                     |
| 527 |    347.025975 |    227.947293 | NA                                                                                                                                                                    |
| 528 |    371.520831 |    107.944600 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 529 |    902.440425 |    776.545047 | Gareth Monger                                                                                                                                                         |
| 530 |    662.404929 |    368.342137 | Jagged Fang Designs                                                                                                                                                   |
| 531 |    434.486765 |    135.754726 | Jagged Fang Designs                                                                                                                                                   |
| 532 |    853.060684 |    191.445979 | Andrew A. Farke                                                                                                                                                       |
| 533 |    327.024183 |    580.920308 | Margot Michaud                                                                                                                                                        |
| 534 |    413.522148 |    513.552467 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 535 |    207.778433 |    426.804633 | Markus A. Grohme                                                                                                                                                      |
| 536 |    978.405494 |    794.356722 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 537 |    132.496744 |    177.416804 | Markus A. Grohme                                                                                                                                                      |
| 538 |     96.056487 |     86.859967 | Josefine Bohr Brask                                                                                                                                                   |
| 539 |   1016.827696 |    357.382262 | Beth Reinke                                                                                                                                                           |
| 540 |    791.663350 |    394.680769 | Tasman Dixon                                                                                                                                                          |
| 541 |    651.807407 |    487.596275 | Zimices                                                                                                                                                               |
| 542 |    646.972924 |     63.453560 | NA                                                                                                                                                                    |
| 543 |    497.917895 |    194.848989 | Beth Reinke                                                                                                                                                           |
| 544 |    226.141266 |    254.668020 | Iain Reid                                                                                                                                                             |
| 545 |    469.526442 |    280.879418 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 546 |    417.793548 |    466.145420 | Chris huh                                                                                                                                                             |
| 547 |    786.945508 |    544.801931 | Jaime Headden                                                                                                                                                         |

    #> Your tweet has been posted!
