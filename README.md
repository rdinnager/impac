
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

Auckland Museum and T. Michael Keesey, Mariana Ruiz Villarreal (modified
by T. Michael Keesey), Armin Reindl, Margot Michaud, Maija Karala, Oscar
Sanisidro, Dmitry Bogdanov (vectorized by T. Michael Keesey), Thibaut
Brunet, Chuanixn Yu, Gareth Monger, T. Michael Keesey (photo by Bc999
\[Black crow\]), Darren Naish (vectorize by T. Michael Keesey), Gabriela
Palomo-Munoz, Roule Jammes (vectorized by T. Michael Keesey), Dein
Freund der Baum (vectorized by T. Michael Keesey), Ferran Sayol, Harold
N Eyster, J Levin W (illustration) and T. Michael Keesey
(vectorization), Wayne Decatur, Lisa Byrne, Chris huh, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Markus A. Grohme, Abraão Leite, Sherman F. Denton via
rawpixel.com (illustration) and Timothy J. Bartley (silhouette), Skye M,
Cesar Julian, Michelle Site, Brad McFeeters (vectorized by T. Michael
Keesey), Jagged Fang Designs, Ville-Veikko Sinkkonen, T. Tischler, M
Kolmann, Michael Scroggie, Matt Crook, Tasman Dixon, Steven Traver, T.
Michael Keesey, Nobu Tamura (modified by T. Michael Keesey), Carlos
Cano-Barbacil, Jack Mayer Wood, Benjamin Monod-Broca, Alexandra van der
Geer, Sharon Wegner-Larsen, Nobu Tamura (vectorized by T. Michael
Keesey), Zimices, Jerry Oldenettel (vectorized by T. Michael Keesey),
Andrew A. Farke, Nobu Tamura, Steven Coombs, Felix Vaux, Caleb M. Brown,
Mike Hanson, Christina N. Hodson, Kamil S. Jaron, Matus Valach, Yan
Wong, Andy Wilson, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Jaime Headden,
Shyamal, I. Sáček, Sr. (vectorized by T. Michael Keesey), Scott Hartman,
Plukenet, Andrew A. Farke, modified from original by Robert Bruce
Horsfall, from Scott 1912, Michael Ströck (vectorized by T. Michael
Keesey), B. Duygu Özpolat, Lip Kee Yap (vectorized by T. Michael
Keesey), Jimmy Bernot, Mathieu Pélissié, Thea Boodhoo (photograph) and
T. Michael Keesey (vectorization), Kanako Bessho-Uehara, Milton Tan, T.
Michael Keesey (after Ponomarenko), Mo Hassan, Steven Blackwood,
Marmelad, Katie S. Collins, Matt Martyniuk (vectorized by T. Michael
Keesey), Ignacio Contreras, Giant Blue Anteater (vectorized by T.
Michael Keesey), Lindberg (vectorized by T. Michael Keesey), Jiekun He,
Tyler McCraney, Renata F. Martins, L. Shyamal, Rebecca Groom, Julio
Garza, AnAgnosticGod (vectorized by T. Michael Keesey), Tony Ayling
(vectorized by T. Michael Keesey), SauropodomorphMonarch, Lauren
Sumner-Rooney, Iain Reid, Tracy A. Heath, Meliponicultor Itaymbere, Neil
Kelley, V. Deepak, T. K. Robinson, Michael Scroggie, from original
photograph by John Bettaso, USFWS (original photograph in public
domain)., Manabu Bessho-Uehara, Cristopher Silva, RS, Ghedo and T.
Michael Keesey, James R. Spotila and Ray Chatterji, Christoph Schomburg,
terngirl, Erika Schumacher, Dmitry Bogdanov, vectorized by Zimices,
Lauren Anderson, ДиБгд (vectorized by T. Michael Keesey), Ghedoghedo,
Hugo Gruson, Scott Reid, T. Michael Keesey (after A. Y. Ivantsov), Mark
Witton, Jakovche, Dean Schnabel, Nobu Tamura, modified by Andrew A.
Farke, Charles R. Knight, vectorized by Zimices, Leann Biancani, photo
by Kenneth Clifton, Henry Lydecker, Alex Slavenko, Kai R. Caspar,
Melissa Broussard, Mathew Wedel, FunkMonk, Terpsichores, Joe Schneid
(vectorized by T. Michael Keesey), Ingo Braasch, Birgit Lang, based on a
photo by D. Sikes, Stanton F. Fink, vectorized by Zimices,
Archaeodontosaurus (vectorized by T. Michael Keesey), Sergio A.
Muñoz-Gómez, Stuart Humphries, DW Bapst (Modified from photograph
taken by Charles Mitchell), Kent Elson Sorgon, David Orr, E. Lear, 1819
(vectorization by Yan Wong), Ben Moon, Tauana J. Cunha, Aviceda
(vectorized by T. Michael Keesey), Matt Wilkins (photo by Patrick
Kavanagh), Ville Koistinen and T. Michael Keesey, James Neenan,
Apokryltaros (vectorized by T. Michael Keesey), Jaime Headden, modified
by T. Michael Keesey, Jaime Headden (vectorized by T. Michael Keesey),
Zsoldos Márton (vectorized by T. Michael Keesey), Mathilde Cordellier,
Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts,
Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Obsidian Soul
(vectorized by T. Michael Keesey), Haplochromis (vectorized by T.
Michael Keesey), Pete Buchholz, Xavier Giroux-Bougard, Abraão B. Leite,
Tony Ayling, Chloé Schmidt, Lankester Edwin Ray (vectorized by T.
Michael Keesey), Taenadoman, Birgit Lang, Chase Brownstein, Nobu Tamura,
vectorized by Zimices, Pranav Iyer (grey ideas), New York Zoological
Society, Mason McNair, xgirouxb, CNZdenek, E. D. Cope (modified by T.
Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Conty (vectorized
by T. Michael Keesey), Tomas Willems (vectorized by T. Michael Keesey),
T. Michael Keesey (after Mivart), Didier Descouens (vectorized by T.
Michael Keesey), Robbie N. Cada (modified by T. Michael Keesey),
Christopher Watson (photo) and T. Michael Keesey (vectorization), Sarah
Werning, Peter Coxhead, Fernando Campos De Domenico, Matt Dempsey,
Martin R. Smith, Alexandre Vong, Michael P. Taylor, Tyler Greenfield,
Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Smokeybjb, Manabu Sakamoto, Alexander Schmidt-Lebuhn,
Henry Fairfield Osborn, vectorized by Zimices, Roberto Díaz Sibaja,
Mattia Menchetti, Christine Axon, Collin Gross, Mette Aumala, Darius
Nau, Robert Bruce Horsfall, vectorized by Zimices, George Edward Lodge
(vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    680.745316 |    419.767056 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
|   2 |    343.498081 |     63.842373 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
|   3 |    782.546406 |    237.304794 | Armin Reindl                                                                                                                                                          |
|   4 |    923.217500 |    350.267762 | Margot Michaud                                                                                                                                                        |
|   5 |    610.930490 |    732.940203 | Maija Karala                                                                                                                                                          |
|   6 |    833.630818 |    543.944156 | Oscar Sanisidro                                                                                                                                                       |
|   7 |    761.358037 |    713.658156 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|   8 |    377.204859 |    651.523418 | Thibaut Brunet                                                                                                                                                        |
|   9 |    243.409391 |    451.146298 | Chuanixn Yu                                                                                                                                                           |
|  10 |    769.312049 |     70.661907 | Gareth Monger                                                                                                                                                         |
|  11 |    332.014765 |    340.033667 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
|  12 |    453.649784 |    188.714225 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
|  13 |    603.454908 |     90.135190 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  14 |    393.809610 |    573.007438 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
|  15 |     99.144880 |    475.512315 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
|  16 |    725.343928 |    168.189870 | Ferran Sayol                                                                                                                                                          |
|  17 |    199.984484 |    645.009925 | Harold N Eyster                                                                                                                                                       |
|  18 |    668.179123 |    601.879861 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
|  19 |     81.326631 |    718.700181 | Wayne Decatur                                                                                                                                                         |
|  20 |    443.160451 |    727.590035 | Ferran Sayol                                                                                                                                                          |
|  21 |    304.386133 |    143.359253 | Lisa Byrne                                                                                                                                                            |
|  22 |    204.620745 |    232.354147 | Chris huh                                                                                                                                                             |
|  23 |     93.043243 |    317.304196 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  24 |    876.466434 |     48.007455 | Markus A. Grohme                                                                                                                                                      |
|  25 |    352.039582 |    725.598470 | Abraão Leite                                                                                                                                                          |
|  26 |    797.163500 |    588.837545 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
|  27 |    363.911902 |    474.112179 | Skye M                                                                                                                                                                |
|  28 |    913.725652 |    290.823247 | Cesar Julian                                                                                                                                                          |
|  29 |     69.290078 |    625.514185 | Michelle Site                                                                                                                                                         |
|  30 |    452.010969 |    338.287607 | Ferran Sayol                                                                                                                                                          |
|  31 |    954.048730 |    698.595520 | Gareth Monger                                                                                                                                                         |
|  32 |    494.035975 |     99.258455 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  33 |    220.778027 |    708.757436 | Jagged Fang Designs                                                                                                                                                   |
|  34 |    578.967628 |    253.184612 | Ville-Veikko Sinkkonen                                                                                                                                                |
|  35 |    541.205385 |    783.601498 | T. Tischler                                                                                                                                                           |
|  36 |    891.188997 |    467.691397 | M Kolmann                                                                                                                                                             |
|  37 |    515.004421 |    590.851206 | Michael Scroggie                                                                                                                                                      |
|  38 |     71.247787 |    168.463411 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  39 |    378.008441 |    265.996724 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  40 |    930.690571 |    151.712998 | Matt Crook                                                                                                                                                            |
|  41 |    191.673741 |    104.264711 | Jagged Fang Designs                                                                                                                                                   |
|  42 |     86.408944 |     79.746829 | Tasman Dixon                                                                                                                                                          |
|  43 |    264.146063 |    560.148633 | Steven Traver                                                                                                                                                         |
|  44 |    993.029964 |    468.711390 | NA                                                                                                                                                                    |
|  45 |    222.964970 |    327.213626 | T. Michael Keesey                                                                                                                                                     |
|  46 |    512.075190 |    512.795118 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  47 |    486.112844 |     27.188898 | Chris huh                                                                                                                                                             |
|  48 |    782.510209 |    753.277901 | Carlos Cano-Barbacil                                                                                                                                                  |
|  49 |    781.463394 |    491.038991 | Cesar Julian                                                                                                                                                          |
|  50 |    830.071244 |    657.266607 | Jack Mayer Wood                                                                                                                                                       |
|  51 |    351.420072 |    208.788222 | Benjamin Monod-Broca                                                                                                                                                  |
|  52 |    784.449956 |    451.113978 | NA                                                                                                                                                                    |
|  53 |     61.152851 |     28.689986 | Alexandra van der Geer                                                                                                                                                |
|  54 |    959.219093 |    212.444851 | Sharon Wegner-Larsen                                                                                                                                                  |
|  55 |    581.540654 |    656.980370 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  56 |    407.726420 |     15.890946 | Zimices                                                                                                                                                               |
|  57 |    572.497322 |    183.685471 | Chris huh                                                                                                                                                             |
|  58 |    947.974498 |    589.615806 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
|  59 |    835.963671 |    189.830523 | Andrew A. Farke                                                                                                                                                       |
|  60 |    704.614999 |    279.638493 | Steven Traver                                                                                                                                                         |
|  61 |    633.386342 |    696.207669 | Nobu Tamura                                                                                                                                                           |
|  62 |    184.385730 |    753.099818 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
|  63 |     66.815611 |    234.145531 | Steven Coombs                                                                                                                                                         |
|  64 |    668.261462 |    777.334216 | Jagged Fang Designs                                                                                                                                                   |
|  65 |    891.355191 |    728.352910 | Felix Vaux                                                                                                                                                            |
|  66 |    262.636664 |    679.082296 | Gareth Monger                                                                                                                                                         |
|  67 |    721.169883 |    505.232226 | T. Michael Keesey                                                                                                                                                     |
|  68 |    426.678401 |     57.461126 | Jagged Fang Designs                                                                                                                                                   |
|  69 |    401.780664 |    411.192944 | Caleb M. Brown                                                                                                                                                        |
|  70 |    802.709919 |    318.094595 | Chris huh                                                                                                                                                             |
|  71 |     70.572318 |    777.254337 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  72 |    358.510939 |      6.418043 | Mike Hanson                                                                                                                                                           |
|  73 |    507.068324 |    234.355468 | Christina N. Hodson                                                                                                                                                   |
|  74 |    298.547939 |    775.832160 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  75 |    281.413897 |    492.923418 | Kamil S. Jaron                                                                                                                                                        |
|  76 |    251.026744 |     21.880554 | Matus Valach                                                                                                                                                          |
|  77 |    880.575090 |    124.739176 | Steven Traver                                                                                                                                                         |
|  78 |    136.350347 |    595.801389 | Chuanixn Yu                                                                                                                                                           |
|  79 |    611.319713 |    557.257857 | Gareth Monger                                                                                                                                                         |
|  80 |    254.650305 |     88.504831 | Yan Wong                                                                                                                                                              |
|  81 |    973.711883 |     62.561792 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  82 |    217.928319 |    579.137829 | Gareth Monger                                                                                                                                                         |
|  83 |    858.508012 |    617.881877 | Andy Wilson                                                                                                                                                           |
|  84 |    409.120670 |    122.772614 | Zimices                                                                                                                                                               |
|  85 |    527.012695 |    695.345745 | Zimices                                                                                                                                                               |
|  86 |    451.551477 |    275.591748 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  87 |    460.083173 |    451.098294 | Yan Wong                                                                                                                                                              |
|  88 |    545.403284 |    299.894472 | Jaime Headden                                                                                                                                                         |
|  89 |    374.898110 |    682.688658 | Shyamal                                                                                                                                                               |
|  90 |    797.492580 |     89.024129 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
|  91 |    565.789829 |    437.208808 | Scott Hartman                                                                                                                                                         |
|  92 |    245.414277 |    165.318996 | Zimices                                                                                                                                                               |
|  93 |    740.679305 |    791.166089 | Scott Hartman                                                                                                                                                         |
|  94 |    398.565564 |    314.014700 | Plukenet                                                                                                                                                              |
|  95 |    941.142418 |    511.702911 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
|  96 |    961.111959 |     18.582575 | Jagged Fang Designs                                                                                                                                                   |
|  97 |    733.142058 |    671.862907 | T. Michael Keesey                                                                                                                                                     |
|  98 |    737.764718 |    550.251498 | T. Michael Keesey                                                                                                                                                     |
|  99 |     50.147861 |    666.104729 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 100 |    963.627926 |    392.696156 | B. Duygu Özpolat                                                                                                                                                      |
| 101 |    207.102954 |    417.523376 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 102 |    188.478174 |    299.241514 | Felix Vaux                                                                                                                                                            |
| 103 |    811.536999 |    151.087800 | T. Michael Keesey                                                                                                                                                     |
| 104 |    805.191225 |    347.439895 | Jimmy Bernot                                                                                                                                                          |
| 105 |    535.060137 |    128.594499 | Mathieu Pélissié                                                                                                                                                      |
| 106 |    607.733327 |    211.495805 | Lisa Byrne                                                                                                                                                            |
| 107 |    997.089972 |     29.922877 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 108 |    667.746305 |     42.009316 | Michael Scroggie                                                                                                                                                      |
| 109 |    167.787216 |    315.383329 | Gareth Monger                                                                                                                                                         |
| 110 |    910.222533 |    100.712802 | Kanako Bessho-Uehara                                                                                                                                                  |
| 111 |    820.871192 |    786.527012 | Milton Tan                                                                                                                                                            |
| 112 |    226.682944 |    784.030834 | Gareth Monger                                                                                                                                                         |
| 113 |    201.611799 |     24.295969 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 114 |    871.338272 |    364.363378 | Gareth Monger                                                                                                                                                         |
| 115 |    848.424108 |     18.996482 | Matt Crook                                                                                                                                                            |
| 116 |    996.644016 |    757.693086 | Zimices                                                                                                                                                               |
| 117 |    326.130421 |    519.441600 | Margot Michaud                                                                                                                                                        |
| 118 |    422.711228 |    777.968150 | Zimices                                                                                                                                                               |
| 119 |    855.241038 |    698.280389 | Mo Hassan                                                                                                                                                             |
| 120 |    788.292791 |     16.112431 | Steven Blackwood                                                                                                                                                      |
| 121 |    692.900365 |    787.816817 | Matt Crook                                                                                                                                                            |
| 122 |    860.951155 |    265.735035 | NA                                                                                                                                                                    |
| 123 |     38.217005 |    292.745675 | Margot Michaud                                                                                                                                                        |
| 124 |     16.524350 |    512.173211 | Marmelad                                                                                                                                                              |
| 125 |    438.349754 |    381.797437 | Katie S. Collins                                                                                                                                                      |
| 126 |    202.437452 |    500.608839 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 127 |    884.052571 |    217.263674 | Ignacio Contreras                                                                                                                                                     |
| 128 |    701.429989 |    761.990022 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 129 |    857.613877 |    497.625150 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 130 |     41.256017 |     21.980563 | Jiekun He                                                                                                                                                             |
| 131 |    499.535926 |    737.991603 | Tyler McCraney                                                                                                                                                        |
| 132 |     37.395280 |    340.508816 | Gareth Monger                                                                                                                                                         |
| 133 |    160.704177 |    210.914470 | Renata F. Martins                                                                                                                                                     |
| 134 |    684.686315 |    460.495828 | L. Shyamal                                                                                                                                                            |
| 135 |    601.258901 |    424.882393 | L. Shyamal                                                                                                                                                            |
| 136 |    231.072507 |     29.579710 | NA                                                                                                                                                                    |
| 137 |    276.723857 |    108.011338 | Rebecca Groom                                                                                                                                                         |
| 138 |    114.606291 |     63.451112 | Steven Traver                                                                                                                                                         |
| 139 |    277.795988 |    337.727680 | T. Michael Keesey                                                                                                                                                     |
| 140 |    522.128618 |    469.763559 | Scott Hartman                                                                                                                                                         |
| 141 |    967.959901 |    263.139804 | Matt Crook                                                                                                                                                            |
| 142 |    539.370320 |     49.957388 | Julio Garza                                                                                                                                                           |
| 143 |    170.447810 |    180.256870 | NA                                                                                                                                                                    |
| 144 |    330.153626 |    645.029662 | Jagged Fang Designs                                                                                                                                                   |
| 145 |    946.816228 |    485.942107 | Margot Michaud                                                                                                                                                        |
| 146 |    737.993970 |    344.933531 | Steven Traver                                                                                                                                                         |
| 147 |    832.677326 |    460.123882 | Matt Crook                                                                                                                                                            |
| 148 |    298.022264 |     26.440787 | Scott Hartman                                                                                                                                                         |
| 149 |    726.733093 |    473.463836 | Sharon Wegner-Larsen                                                                                                                                                  |
| 150 |    754.476335 |    626.601324 | Gareth Monger                                                                                                                                                         |
| 151 |     15.231988 |    100.463342 | Maija Karala                                                                                                                                                          |
| 152 |    319.265153 |    607.230545 | Steven Traver                                                                                                                                                         |
| 153 |    479.247894 |     52.563893 | Markus A. Grohme                                                                                                                                                      |
| 154 |    848.080940 |    673.582877 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 155 |    283.547598 |    629.171267 | Tasman Dixon                                                                                                                                                          |
| 156 |    784.919588 |    781.297787 | Jack Mayer Wood                                                                                                                                                       |
| 157 |    691.339822 |     19.976017 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 158 |    315.968686 |    108.258164 | Scott Hartman                                                                                                                                                         |
| 159 |    685.545999 |     10.391239 | SauropodomorphMonarch                                                                                                                                                 |
| 160 |    805.330796 |    629.248737 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 161 |    983.612411 |      6.286983 | Tyler McCraney                                                                                                                                                        |
| 162 |    654.014692 |    179.601648 | NA                                                                                                                                                                    |
| 163 |    160.034839 |     28.987903 | Lauren Sumner-Rooney                                                                                                                                                  |
| 164 |    350.281236 |    171.791470 | NA                                                                                                                                                                    |
| 165 |    808.094649 |     27.106701 | Ferran Sayol                                                                                                                                                          |
| 166 |     86.076410 |    789.542135 | Iain Reid                                                                                                                                                             |
| 167 |    946.262853 |    441.484931 | Tracy A. Heath                                                                                                                                                        |
| 168 |    238.047222 |    192.004764 | Steven Traver                                                                                                                                                         |
| 169 |    349.122500 |    304.373094 | Markus A. Grohme                                                                                                                                                      |
| 170 |    725.797551 |    107.629565 | T. Michael Keesey                                                                                                                                                     |
| 171 |     60.004441 |    271.831173 | Meliponicultor Itaymbere                                                                                                                                              |
| 172 |    702.162760 |    135.629464 | Steven Coombs                                                                                                                                                         |
| 173 |    249.610645 |    768.538421 | Zimices                                                                                                                                                               |
| 174 |    159.312616 |     39.372741 | NA                                                                                                                                                                    |
| 175 |    153.253720 |    277.818784 | Zimices                                                                                                                                                               |
| 176 |     22.844139 |    684.687035 | Neil Kelley                                                                                                                                                           |
| 177 |    329.871150 |    427.149181 | Margot Michaud                                                                                                                                                        |
| 178 |    299.227965 |    737.393464 | NA                                                                                                                                                                    |
| 179 |    892.492527 |    149.390999 | Felix Vaux                                                                                                                                                            |
| 180 |    557.906647 |    535.753863 | V. Deepak                                                                                                                                                             |
| 181 |    997.922838 |    568.664454 | T. K. Robinson                                                                                                                                                        |
| 182 |    498.166497 |    654.776535 | Zimices                                                                                                                                                               |
| 183 |    320.539107 |    231.128107 | Jack Mayer Wood                                                                                                                                                       |
| 184 |     59.877487 |    371.515087 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 185 |   1002.942004 |    375.967712 | Caleb M. Brown                                                                                                                                                        |
| 186 |    176.120745 |    790.462878 | Cesar Julian                                                                                                                                                          |
| 187 |    269.106242 |    618.640363 | Caleb M. Brown                                                                                                                                                        |
| 188 |    192.539501 |    360.011569 | Manabu Bessho-Uehara                                                                                                                                                  |
| 189 |    410.971541 |     98.042564 | Cristopher Silva                                                                                                                                                      |
| 190 |    516.762312 |    666.754347 | RS                                                                                                                                                                    |
| 191 |    860.773736 |    255.756204 | Gareth Monger                                                                                                                                                         |
| 192 |    887.706486 |     14.363438 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
| 193 |   1003.814265 |    581.454957 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 194 |     40.905429 |    471.652932 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 195 |    144.915805 |    699.116642 | T. Michael Keesey                                                                                                                                                     |
| 196 |    595.806077 |    289.586146 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 197 |    424.878923 |    495.350923 | Christoph Schomburg                                                                                                                                                   |
| 198 |    831.336666 |    283.380784 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 199 |    630.283056 |     16.479645 | terngirl                                                                                                                                                              |
| 200 |    191.402407 |    687.609888 | Erika Schumacher                                                                                                                                                      |
| 201 |    441.675359 |    317.851285 | Nobu Tamura                                                                                                                                                           |
| 202 |    984.299644 |    546.325084 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 203 |    183.913144 |     45.864115 | Scott Hartman                                                                                                                                                         |
| 204 |    995.558313 |    330.150927 | Lauren Anderson                                                                                                                                                       |
| 205 |    763.429339 |    363.272329 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 206 |    304.906233 |    278.610391 | Chris huh                                                                                                                                                             |
| 207 |    486.443552 |    284.248290 | Ghedoghedo                                                                                                                                                            |
| 208 |    527.657893 |    755.480410 | NA                                                                                                                                                                    |
| 209 |   1015.474362 |    338.577897 | Hugo Gruson                                                                                                                                                           |
| 210 |    517.762631 |    283.249445 | Andy Wilson                                                                                                                                                           |
| 211 |     56.037251 |    587.179022 | Scott Reid                                                                                                                                                            |
| 212 |    826.547574 |    733.464638 | Chris huh                                                                                                                                                             |
| 213 |    465.213789 |    783.428425 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 214 |    803.042027 |    684.430626 | Scott Hartman                                                                                                                                                         |
| 215 |     22.880507 |    270.085384 | Mark Witton                                                                                                                                                           |
| 216 |    256.523840 |     53.735682 | Gareth Monger                                                                                                                                                         |
| 217 |    556.023753 |    754.415051 | Jakovche                                                                                                                                                              |
| 218 |    435.759353 |    670.173320 | Zimices                                                                                                                                                               |
| 219 |    242.598128 |    735.631381 | Steven Coombs                                                                                                                                                         |
| 220 |    323.141762 |     10.137891 | Dean Schnabel                                                                                                                                                         |
| 221 |    397.886188 |    235.162786 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 222 |    267.798759 |    275.014116 | L. Shyamal                                                                                                                                                            |
| 223 |    673.865753 |    668.728190 | Zimices                                                                                                                                                               |
| 224 |     29.841128 |     48.340507 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 225 |    868.559311 |    783.785569 | Dean Schnabel                                                                                                                                                         |
| 226 |    103.463573 |    277.186378 | Matt Crook                                                                                                                                                            |
| 227 |   1008.075414 |    295.336205 | Matt Crook                                                                                                                                                            |
| 228 |    367.712923 |    761.572425 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 229 |    677.666729 |    518.651911 | Henry Lydecker                                                                                                                                                        |
| 230 |    453.179505 |    538.965065 | Scott Hartman                                                                                                                                                         |
| 231 |    278.057188 |    195.620280 | Matt Crook                                                                                                                                                            |
| 232 |   1000.882850 |     82.703612 | Andrew A. Farke                                                                                                                                                       |
| 233 |    908.644936 |    240.923275 | Chuanixn Yu                                                                                                                                                           |
| 234 |    728.336695 |    736.859320 | Alex Slavenko                                                                                                                                                         |
| 235 |    390.466537 |    173.233844 | Kai R. Caspar                                                                                                                                                         |
| 236 |    769.839993 |    680.868810 | Gareth Monger                                                                                                                                                         |
| 237 |   1001.239344 |     48.836295 | Markus A. Grohme                                                                                                                                                      |
| 238 |    695.888228 |    732.450936 | Matt Crook                                                                                                                                                            |
| 239 |    484.485231 |    159.086820 | Michelle Site                                                                                                                                                         |
| 240 |    302.394835 |    437.114640 | Melissa Broussard                                                                                                                                                     |
| 241 |   1008.009195 |    721.718822 | Andy Wilson                                                                                                                                                           |
| 242 |    930.791239 |    385.599838 | Matt Crook                                                                                                                                                            |
| 243 |    132.626136 |     78.010012 | Margot Michaud                                                                                                                                                        |
| 244 |    855.340364 |    335.981439 | Mathew Wedel                                                                                                                                                          |
| 245 |    868.540760 |    145.548205 | Iain Reid                                                                                                                                                             |
| 246 |     68.501980 |    392.551185 | FunkMonk                                                                                                                                                              |
| 247 |    478.132773 |    645.581105 | Terpsichores                                                                                                                                                          |
| 248 |    857.074745 |    348.712902 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 249 |    625.373560 |    677.582054 | Jagged Fang Designs                                                                                                                                                   |
| 250 |    557.465827 |    218.283603 | Tasman Dixon                                                                                                                                                          |
| 251 |    787.724395 |    127.278031 | Zimices                                                                                                                                                               |
| 252 |    583.533509 |    472.617019 | Steven Traver                                                                                                                                                         |
| 253 |    126.358475 |    124.359250 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 254 |    632.798235 |    795.928576 | Ingo Braasch                                                                                                                                                          |
| 255 |    761.882742 |     83.584063 | Scott Hartman                                                                                                                                                         |
| 256 |    650.582014 |     67.771785 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 257 |    279.261839 |    642.054419 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 258 |    551.684366 |     19.058863 | Melissa Broussard                                                                                                                                                     |
| 259 |     10.461814 |    313.530214 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 260 |   1010.275314 |    111.879480 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 261 |     12.887436 |    363.653806 | Stuart Humphries                                                                                                                                                      |
| 262 |    480.148535 |    449.152002 | Scott Hartman                                                                                                                                                         |
| 263 |    139.248205 |     41.399762 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 264 |    370.897398 |    126.062173 | Kent Elson Sorgon                                                                                                                                                     |
| 265 |    198.277471 |    396.402235 | T. Michael Keesey                                                                                                                                                     |
| 266 |    918.586078 |    778.513387 | Alex Slavenko                                                                                                                                                         |
| 267 |    147.697470 |     17.438271 | Scott Hartman                                                                                                                                                         |
| 268 |    337.586478 |    690.394744 | Chris huh                                                                                                                                                             |
| 269 |     40.892071 |    109.759739 | Tracy A. Heath                                                                                                                                                        |
| 270 |    160.028171 |    683.835312 | NA                                                                                                                                                                    |
| 271 |    346.170392 |    102.205765 | Julio Garza                                                                                                                                                           |
| 272 |    122.250670 |     30.357112 | T. Michael Keesey                                                                                                                                                     |
| 273 |    725.451794 |     68.811871 | Matt Crook                                                                                                                                                            |
| 274 |     92.927921 |    669.117375 | T. Michael Keesey                                                                                                                                                     |
| 275 |    297.155188 |    696.409424 | Zimices                                                                                                                                                               |
| 276 |    246.144479 |    482.836866 | NA                                                                                                                                                                    |
| 277 |    912.360924 |     23.684129 | Zimices                                                                                                                                                               |
| 278 |    223.358416 |    393.957602 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 279 |    110.869814 |    369.539139 | David Orr                                                                                                                                                             |
| 280 |    394.125000 |    730.668618 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 281 |    316.528262 |    407.056541 | Lauren Sumner-Rooney                                                                                                                                                  |
| 282 |     27.151914 |    211.464941 | Christoph Schomburg                                                                                                                                                   |
| 283 |    757.237531 |    442.094888 | Abraão Leite                                                                                                                                                          |
| 284 |    337.333152 |    764.959039 | Ben Moon                                                                                                                                                              |
| 285 |    454.652342 |    141.006919 | Ferran Sayol                                                                                                                                                          |
| 286 |    697.846427 |    238.242913 | Chris huh                                                                                                                                                             |
| 287 |    761.790935 |    213.682147 | Gareth Monger                                                                                                                                                         |
| 288 |    933.628989 |    254.344182 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 289 |    996.674399 |    783.045915 | Tauana J. Cunha                                                                                                                                                       |
| 290 |    793.100991 |    113.664678 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 291 |    688.125632 |    537.288962 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 292 |    780.771677 |    631.563594 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 293 |    678.837052 |    783.064520 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 294 |    788.451243 |    159.019943 | Matt Crook                                                                                                                                                            |
| 295 |    279.424394 |    373.680612 | Ingo Braasch                                                                                                                                                          |
| 296 |    393.843864 |    704.462634 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 297 |    351.737930 |    376.927705 | Steven Traver                                                                                                                                                         |
| 298 |    598.308876 |    617.160451 | Matt Crook                                                                                                                                                            |
| 299 |    649.074197 |    497.006942 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 300 |    242.742757 |    790.786863 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 301 |    131.806816 |    378.542969 | Chris huh                                                                                                                                                             |
| 302 |    617.641652 |    303.552290 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 303 |    369.353114 |    148.932022 | Christoph Schomburg                                                                                                                                                   |
| 304 |    576.058863 |    494.164049 | James Neenan                                                                                                                                                          |
| 305 |    585.427915 |    161.243389 | Chris huh                                                                                                                                                             |
| 306 |    750.510598 |    251.740161 | Andy Wilson                                                                                                                                                           |
| 307 |    561.616787 |    710.645721 | Zimices                                                                                                                                                               |
| 308 |    626.113301 |    157.063408 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 309 |    481.933987 |    383.019962 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 310 |    631.620540 |     36.735698 | Tasman Dixon                                                                                                                                                          |
| 311 |    715.445728 |    312.474990 | Cesar Julian                                                                                                                                                          |
| 312 |    585.567983 |     11.104109 | Zimices                                                                                                                                                               |
| 313 |    908.234977 |    548.549830 | Markus A. Grohme                                                                                                                                                      |
| 314 |    659.705244 |    749.502483 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 315 |    175.977223 |    458.419706 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 316 |    298.874289 |    363.424221 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 317 |    552.645328 |    205.423442 | Tasman Dixon                                                                                                                                                          |
| 318 |    660.315922 |    147.725800 | Ferran Sayol                                                                                                                                                          |
| 319 |    501.182918 |     68.141916 | Chuanixn Yu                                                                                                                                                           |
| 320 |    276.624844 |    664.376953 | Margot Michaud                                                                                                                                                        |
| 321 |    300.082467 |    759.072328 | Shyamal                                                                                                                                                               |
| 322 |    335.266096 |    417.944175 | Margot Michaud                                                                                                                                                        |
| 323 |    987.863085 |    599.557502 | Scott Hartman                                                                                                                                                         |
| 324 |    313.706065 |    585.842968 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 325 |    759.964371 |     63.485281 | Steven Traver                                                                                                                                                         |
| 326 |    734.898344 |     20.501156 | Sharon Wegner-Larsen                                                                                                                                                  |
| 327 |    190.610411 |    781.825914 | Ingo Braasch                                                                                                                                                          |
| 328 |    762.335265 |     98.902085 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 329 |    910.972466 |    418.504626 | Mathilde Cordellier                                                                                                                                                   |
| 330 |    656.982229 |     11.943590 | M Kolmann                                                                                                                                                             |
| 331 |    607.081440 |    634.506558 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 332 |    757.333604 |    571.939995 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 333 |    749.941413 |    427.685571 | T. Michael Keesey                                                                                                                                                     |
| 334 |    697.313133 |    751.413662 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 335 |     59.825786 |     57.974039 | Pete Buchholz                                                                                                                                                         |
| 336 |    610.073708 |    131.314488 | Meliponicultor Itaymbere                                                                                                                                              |
| 337 |    524.094657 |    317.161845 | Tasman Dixon                                                                                                                                                          |
| 338 |    103.660499 |    228.343379 | Jack Mayer Wood                                                                                                                                                       |
| 339 |    712.383375 |      5.529851 | NA                                                                                                                                                                    |
| 340 |    380.091141 |    635.316163 | Matt Crook                                                                                                                                                            |
| 341 |    610.344675 |     49.862235 | T. Michael Keesey                                                                                                                                                     |
| 342 |    660.526602 |    529.075619 | Xavier Giroux-Bougard                                                                                                                                                 |
| 343 |    113.800475 |    645.395126 | Tracy A. Heath                                                                                                                                                        |
| 344 |    175.148972 |    199.398973 | Markus A. Grohme                                                                                                                                                      |
| 345 |    358.105082 |    319.694636 | Abraão B. Leite                                                                                                                                                       |
| 346 |    736.490684 |    650.052749 | Tony Ayling                                                                                                                                                           |
| 347 |    143.997507 |    178.536439 | Chloé Schmidt                                                                                                                                                         |
| 348 |    176.438250 |    718.374828 | Jaime Headden                                                                                                                                                         |
| 349 |    151.926474 |      7.974570 | Tasman Dixon                                                                                                                                                          |
| 350 |    714.802950 |    564.728898 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 351 |     89.664816 |    113.911791 | Alex Slavenko                                                                                                                                                         |
| 352 |   1003.689340 |    144.072330 | Zimices                                                                                                                                                               |
| 353 |     12.414463 |    421.469544 | T. Michael Keesey                                                                                                                                                     |
| 354 |    261.519379 |    311.385883 | Taenadoman                                                                                                                                                            |
| 355 |    654.823078 |    236.978576 | Andy Wilson                                                                                                                                                           |
| 356 |    269.746733 |     61.005133 | Birgit Lang                                                                                                                                                           |
| 357 |    829.318344 |    698.480527 | Felix Vaux                                                                                                                                                            |
| 358 |     81.157110 |    202.998703 | Scott Hartman                                                                                                                                                         |
| 359 |    339.558837 |     34.023697 | NA                                                                                                                                                                    |
| 360 |    581.199198 |    313.099112 | Chase Brownstein                                                                                                                                                      |
| 361 |    418.401314 |    187.726773 | Gareth Monger                                                                                                                                                         |
| 362 |    145.947949 |    649.202404 | Jagged Fang Designs                                                                                                                                                   |
| 363 |    530.873858 |     12.933965 | Scott Hartman                                                                                                                                                         |
| 364 |    853.822573 |    757.179411 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 365 |    314.253745 |    536.313975 | Scott Hartman                                                                                                                                                         |
| 366 |    842.210933 |    361.153260 | Maija Karala                                                                                                                                                          |
| 367 |     33.293814 |    590.556979 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 368 |    881.657783 |    655.317339 | Zimices                                                                                                                                                               |
| 369 |    305.927209 |    176.219328 | Zimices                                                                                                                                                               |
| 370 |    325.356873 |    719.069698 | Matt Crook                                                                                                                                                            |
| 371 |    891.696617 |    570.478042 | New York Zoological Society                                                                                                                                           |
| 372 |    140.585538 |    367.330847 | Chris huh                                                                                                                                                             |
| 373 |    580.317218 |    675.614656 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 374 |    148.796848 |    125.192000 | Mason McNair                                                                                                                                                          |
| 375 |    892.065022 |    591.675716 | xgirouxb                                                                                                                                                              |
| 376 |    346.986414 |    112.433346 | CNZdenek                                                                                                                                                              |
| 377 |    770.107596 |    338.909492 | Matt Crook                                                                                                                                                            |
| 378 |    235.798007 |    593.784417 | Ignacio Contreras                                                                                                                                                     |
| 379 |    323.366809 |    554.930588 | CNZdenek                                                                                                                                                              |
| 380 |    923.437290 |    539.233388 | Pete Buchholz                                                                                                                                                         |
| 381 |    295.424679 |    655.700782 | M Kolmann                                                                                                                                                             |
| 382 |    857.469368 |    777.445193 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 383 |    218.014784 |    770.503561 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 384 |    942.387435 |      8.809168 | Nobu Tamura                                                                                                                                                           |
| 385 |    881.545749 |    242.168389 | NA                                                                                                                                                                    |
| 386 |    754.150068 |    735.059593 | Margot Michaud                                                                                                                                                        |
| 387 |    117.998790 |    665.593788 | Jack Mayer Wood                                                                                                                                                       |
| 388 |    529.058148 |     93.252365 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 389 |    455.798362 |    399.151133 | Chris huh                                                                                                                                                             |
| 390 |    257.962649 |    303.112979 | Margot Michaud                                                                                                                                                        |
| 391 |    615.992507 |    108.629688 | Erika Schumacher                                                                                                                                                      |
| 392 |    227.794675 |     66.184398 | T. Michael Keesey (after Mivart)                                                                                                                                      |
| 393 |    558.561128 |    461.874820 | Steven Traver                                                                                                                                                         |
| 394 |    591.879885 |    594.610169 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 395 |    764.549263 |    430.028970 | Birgit Lang                                                                                                                                                           |
| 396 |    195.917562 |    561.150452 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 397 |    902.445617 |    393.233151 | NA                                                                                                                                                                    |
| 398 |     25.313898 |    750.667976 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 399 |    620.978928 |    780.541445 | Scott Hartman                                                                                                                                                         |
| 400 |    283.829514 |    749.425786 | Iain Reid                                                                                                                                                             |
| 401 |    739.591356 |     98.286166 | Gareth Monger                                                                                                                                                         |
| 402 |   1000.835081 |    313.480238 | Chris huh                                                                                                                                                             |
| 403 |    826.784604 |    262.296824 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 404 |    865.770599 |    108.352066 | Scott Hartman                                                                                                                                                         |
| 405 |    534.825207 |    761.574748 | NA                                                                                                                                                                    |
| 406 |    795.705613 |    558.100692 | FunkMonk                                                                                                                                                              |
| 407 |    739.021859 |    127.253009 | Sarah Werning                                                                                                                                                         |
| 408 |    488.304136 |    148.386912 | Scott Hartman                                                                                                                                                         |
| 409 |    659.116164 |    462.961440 | Kamil S. Jaron                                                                                                                                                        |
| 410 |    215.380119 |    548.663072 | Peter Coxhead                                                                                                                                                         |
| 411 |     15.132784 |    788.452369 | Margot Michaud                                                                                                                                                        |
| 412 |    855.550985 |    432.962018 | Milton Tan                                                                                                                                                            |
| 413 |    490.638924 |    468.519400 | Yan Wong                                                                                                                                                              |
| 414 |    865.343194 |    416.822022 | Skye M                                                                                                                                                                |
| 415 |    619.482721 |    287.460860 | Fernando Campos De Domenico                                                                                                                                           |
| 416 |     90.104354 |    191.553262 | Gareth Monger                                                                                                                                                         |
| 417 |    206.732231 |    262.457848 | Matt Dempsey                                                                                                                                                          |
| 418 |    612.081972 |    512.498272 | Martin R. Smith                                                                                                                                                       |
| 419 |    575.995945 |    134.310129 | Alexandre Vong                                                                                                                                                        |
| 420 |    425.492906 |    700.928360 | Michael P. Taylor                                                                                                                                                     |
| 421 |    445.496523 |    503.947346 | Christoph Schomburg                                                                                                                                                   |
| 422 |     15.934448 |    468.448858 | Matt Crook                                                                                                                                                            |
| 423 |    636.867333 |    524.276475 | Markus A. Grohme                                                                                                                                                      |
| 424 |    241.473017 |    413.735267 | Ingo Braasch                                                                                                                                                          |
| 425 |    913.633391 |    793.427494 | Pete Buchholz                                                                                                                                                         |
| 426 |    161.786678 |    262.716390 | Tasman Dixon                                                                                                                                                          |
| 427 |    472.421844 |    241.958438 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 428 |     78.725674 |    653.010243 | Jagged Fang Designs                                                                                                                                                   |
| 429 |     42.589182 |    360.235850 | Jagged Fang Designs                                                                                                                                                   |
| 430 |    676.085747 |     32.566627 | Markus A. Grohme                                                                                                                                                      |
| 431 |    428.005676 |    447.277578 | Ferran Sayol                                                                                                                                                          |
| 432 |    390.723710 |    349.715529 | Markus A. Grohme                                                                                                                                                      |
| 433 |    371.350784 |    101.040461 | Scott Hartman                                                                                                                                                         |
| 434 |    914.024756 |    202.084060 | Gareth Monger                                                                                                                                                         |
| 435 |    101.901505 |    591.183200 | Tyler Greenfield                                                                                                                                                      |
| 436 |    312.931459 |    501.776497 | Jagged Fang Designs                                                                                                                                                   |
| 437 |    701.282060 |    120.002770 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 438 |    544.170578 |    641.945358 | Markus A. Grohme                                                                                                                                                      |
| 439 |    197.499767 |    765.770648 | Zimices                                                                                                                                                               |
| 440 |    708.422346 |    203.788241 | Margot Michaud                                                                                                                                                        |
| 441 |    590.529906 |    777.644351 | Zimices                                                                                                                                                               |
| 442 |    729.550345 |    457.449626 | Jagged Fang Designs                                                                                                                                                   |
| 443 |    392.832087 |    669.952617 | Chris huh                                                                                                                                                             |
| 444 |   1007.263721 |     62.345616 | Michael P. Taylor                                                                                                                                                     |
| 445 |    773.164689 |    657.689679 | Jagged Fang Designs                                                                                                                                                   |
| 446 |    238.279002 |    576.605114 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 447 |     27.688924 |    498.921923 | Gareth Monger                                                                                                                                                         |
| 448 |    422.138264 |    225.615147 | Chris huh                                                                                                                                                             |
| 449 |    914.065879 |    528.978244 | Iain Reid                                                                                                                                                             |
| 450 |    284.788657 |    465.384382 | Smokeybjb                                                                                                                                                             |
| 451 |    284.530078 |    396.914439 | Scott Hartman                                                                                                                                                         |
| 452 |   1008.797634 |    538.411785 | FunkMonk                                                                                                                                                              |
| 453 |    638.303732 |    545.829484 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 454 |    176.343857 |    697.151343 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 455 |    835.090511 |    298.927909 | Michael Scroggie                                                                                                                                                      |
| 456 |    342.940547 |    675.952480 | Manabu Sakamoto                                                                                                                                                       |
| 457 |    996.606009 |    397.200456 | Tracy A. Heath                                                                                                                                                        |
| 458 |    812.828790 |    235.144948 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 459 |    660.027976 |    257.815290 | FunkMonk                                                                                                                                                              |
| 460 |    427.087483 |    389.619214 | Jagged Fang Designs                                                                                                                                                   |
| 461 |    509.867401 |    138.375331 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 462 |    247.803686 |    109.181342 | Iain Reid                                                                                                                                                             |
| 463 |    438.131239 |    364.535082 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 464 |    176.693305 |    580.768070 | Ferran Sayol                                                                                                                                                          |
| 465 |    414.650447 |    336.277427 | NA                                                                                                                                                                    |
| 466 |    872.259793 |    164.262812 | Scott Hartman                                                                                                                                                         |
| 467 |    378.080736 |    435.351413 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 468 |    324.538848 |    630.500568 | Roberto Díaz Sibaja                                                                                                                                                   |
| 469 |    986.718849 |    563.177187 | Jagged Fang Designs                                                                                                                                                   |
| 470 |    136.407882 |    777.955699 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 471 |      8.060323 |    571.133593 | Mathilde Cordellier                                                                                                                                                   |
| 472 |    518.208858 |    172.934352 | Zimices                                                                                                                                                               |
| 473 |    618.011838 |    197.777892 | Chris huh                                                                                                                                                             |
| 474 |    497.363192 |    704.784801 | Jagged Fang Designs                                                                                                                                                   |
| 475 |    271.430076 |    527.128119 | Mattia Menchetti                                                                                                                                                      |
| 476 |    885.968019 |     76.781064 | Jack Mayer Wood                                                                                                                                                       |
| 477 |    873.871711 |    795.053531 | Christine Axon                                                                                                                                                        |
| 478 |    839.132027 |    123.524813 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 479 |    707.240335 |    693.282342 | Chris huh                                                                                                                                                             |
| 480 |    539.061938 |    166.138966 | Tasman Dixon                                                                                                                                                          |
| 481 |    356.754966 |    787.747276 | Markus A. Grohme                                                                                                                                                      |
| 482 |    443.743591 |    118.788434 | Collin Gross                                                                                                                                                          |
| 483 |    130.859283 |    675.602397 | Markus A. Grohme                                                                                                                                                      |
| 484 |    976.345973 |    311.474713 | Scott Hartman                                                                                                                                                         |
| 485 |    292.023644 |    254.388160 | Ignacio Contreras                                                                                                                                                     |
| 486 |    800.295988 |    696.283620 | Jagged Fang Designs                                                                                                                                                   |
| 487 |    565.466021 |    291.418826 | Mette Aumala                                                                                                                                                          |
| 488 |    898.812998 |    107.398150 | Jagged Fang Designs                                                                                                                                                   |
| 489 |    323.401477 |    206.819668 | Margot Michaud                                                                                                                                                        |
| 490 |    731.678553 |    236.679951 | Nobu Tamura                                                                                                                                                           |
| 491 |    459.775036 |    361.779697 | Gareth Monger                                                                                                                                                         |
| 492 |    174.878672 |    664.404090 | Margot Michaud                                                                                                                                                        |
| 493 |     90.767815 |    797.722694 | Jagged Fang Designs                                                                                                                                                   |
| 494 |    257.596554 |    756.692648 | Chloé Schmidt                                                                                                                                                         |
| 495 |    448.824364 |    153.456020 | Darius Nau                                                                                                                                                            |
| 496 |    241.577248 |    207.209515 | xgirouxb                                                                                                                                                              |
| 497 |   1005.783812 |    620.895186 | NA                                                                                                                                                                    |
| 498 |    688.373042 |    708.326187 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 499 |    449.438432 |    644.373637 | David Orr                                                                                                                                                             |
| 500 |      5.705420 |    661.229845 | NA                                                                                                                                                                    |
| 501 |    166.898084 |    480.618528 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 502 |    916.817621 |    141.742982 | Markus A. Grohme                                                                                                                                                      |
| 503 |    482.629859 |    264.234609 | Jagged Fang Designs                                                                                                                                                   |
| 504 |    810.275743 |    214.620056 | T. Michael Keesey                                                                                                                                                     |
| 505 |    880.253934 |     27.526277 | Markus A. Grohme                                                                                                                                                      |
| 506 |    736.063399 |    574.715736 | NA                                                                                                                                                                    |
| 507 |   1015.719357 |    218.847725 | Gareth Monger                                                                                                                                                         |
| 508 |    388.577057 |    357.504089 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 509 |    858.382938 |    721.638184 | Gareth Monger                                                                                                                                                         |
| 510 |    974.076671 |     27.527025 | Chris huh                                                                                                                                                             |
| 511 |    799.278368 |      5.961896 | T. Michael Keesey                                                                                                                                                     |
| 512 |    340.017032 |    438.405787 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 513 |    180.210903 |     25.973020 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |

    #> Your tweet has been posted!
