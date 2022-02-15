
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

Ferran Sayol, Matt Crook, Renato de Carvalho Ferreira, David Tana, Caleb
M. Brown, S.Martini, Zimices, Ieuan Jones, Gabriela Palomo-Munoz, Steven
Traver, Rebecca Groom, Sharon Wegner-Larsen, Tyler Greenfield and Dean
Schnabel, I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey),
Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Mo Hassan, Nobu Tamura (vectorized by T. Michael
Keesey), Felix Vaux, Yan Wong, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Pearson Scott
Foresman (vectorized by T. Michael Keesey), Gareth Monger, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Renata F. Martins, Margot
Michaud, Scott Hartman, modified by T. Michael Keesey, Ingo Braasch, Jan
Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Scott Hartman, T. Michael Keesey (vector) and Stuart
Halliday (photograph), Conty (vectorized by T. Michael Keesey), Darren
Naish (vectorized by T. Michael Keesey), Steven Coombs, Birgit Lang,
Chris huh, T. Michael Keesey, Chase Brownstein, Leon P. A. M. Claessens,
Patrick M. O’Connor, David M. Unwin, Frederick William Frohawk
(vectorized by T. Michael Keesey), Sebastian Stabinger, Bruno Maggia,
Jagged Fang Designs, Markus A. Grohme, Matt Martyniuk, Mattia Menchetti,
Tasman Dixon, (unknown), , Beth Reinke, Campbell Fleming, Iain Reid,
Collin Gross, Jay Matternes, vectorized by Zimices, Rene Martin,
Lukasiniho, Noah Schlottman, photo by Antonio Guillén, T. Michael Keesey
(after James & al.), Henry Lydecker, Hugo Gruson, Benchill, Noah
Schlottman, Nina Skinner, FJDegrange, Emily Willoughby, Alexandre Vong,
Michelle Site, Natasha Vitek, M Kolmann, Robbie N. Cada (vectorized by
T. Michael Keesey), Sergio A. Muñoz-Gómez, xgirouxb, Smokeybjb, Anthony
Caravaggi, Carlos Cano-Barbacil, Ignacio Contreras, Ernst Haeckel
(vectorized by T. Michael Keesey), Kenneth Lacovara (vectorized by T.
Michael Keesey), Alex Slavenko, Javiera Constanzo, Katie S. Collins,
Rachel Shoop, T. Michael Keesey (after Monika Betley), Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Fernando Carezzano, Jonathan Lawley, Jonathan Wells, Jesús
Gómez, vectorized by Zimices, Kamil S. Jaron, Michael “FunkMonk” B. H.
(vectorized by T. Michael Keesey), Apokryltaros (vectorized by T.
Michael Keesey), Chloé Schmidt, Bennet McComish, photo by Hans
Hillewaert, Dean Schnabel, Trond R. Oskars, Vijay Cavale (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Jaime
Headden, Nobu Tamura, Obsidian Soul (vectorized by T. Michael Keesey),
Michael P. Taylor, Dmitry Bogdanov, Joanna Wolfe, Kevin Sánchez,
Lindberg (vectorized by T. Michael Keesey), Agnello Picorelli, Pete
Buchholz, Roberto Díaz Sibaja, Dianne Bray / Museum Victoria (vectorized
by T. Michael Keesey), Alan Manson (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Jakovche, E. D. Cope (modified by
T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Scott Reid,
Andrew A. Farke, modified from original by Robert Bruce Horsfall, from
Scott 1912, Tracy A. Heath, Milton Tan, B. Duygu Özpolat, Andrew A.
Farke, Matthew E. Clapham, Nobu Tamura (modified by T. Michael Keesey),
Jose Carlos Arenas-Monroy, David Orr, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Mason
McNair, Sean McCann, Mykle Hoban, Maija Karala, Filip em, Didier
Descouens (vectorized by T. Michael Keesey), Mathew Wedel, C.
Abraczinskas, Mark Hofstetter (vectorized by T. Michael Keesey),
SecretJellyMan, Nobu Tamura, vectorized by Zimices, Inessa Voet, Keith
Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Tess Linden, Stanton F. Fink, vectorized by Zimices,
Javier Luque, T. Michael Keesey (vectorization) and Larry Loos
(photography), Jay Matternes (modified by T. Michael Keesey), FunkMonk,
DW Bapst (Modified from photograph taken by Charles Mitchell), Dave
Souza (vectorized by T. Michael Keesey), Tauana J. Cunha, Terpsichores,
Birgit Lang, based on a photo by D. Sikes, Arthur S. Brum, Curtis Clark
and T. Michael Keesey, Robert Bruce Horsfall, vectorized by Zimices,
Christoph Schomburg, Martin Kevil, Daniel Stadtmauer, CNZdenek, Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Dmitry
Bogdanov (modified by T. Michael Keesey), Sarah Werning, Harold N
Eyster, George Edward Lodge, Brian Swartz (vectorized by T. Michael
Keesey), Kelly, Benjamin Monod-Broca, T. K. Robinson,
SauropodomorphMonarch, Eduard Solà (vectorized by T. Michael Keesey),
Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T.
Michael Keesey (vectorization), Matus Valach, Chuanixn Yu, Blanco et
al., 2014, vectorized by Zimices, Diana Pomeroy, Melissa Broussard,
Haplochromis (vectorized by T. Michael Keesey), Noah Schlottman, photo
by Casey Dunn, Karla Martinez, Ricardo N. Martinez & Oscar A. Alcober,
Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist, Yan
Wong from wikipedia drawing (PD: Pearson Scott Foresman), Duane Raver
(vectorized by T. Michael Keesey), Alexander Schmidt-Lebuhn, Nobu Tamura
(vectorized by A. Verrière), Smokeybjb, vectorized by Zimices, Xavier A.
Jenkins, Gabriel Ugueto, Mike Hanson, Tyler Greenfield, Juan Carlos Jerí

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                          |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    837.630094 |    156.332485 | Ferran Sayol                                                                                                                                                    |
|   2 |    164.557011 |    482.298626 | Ferran Sayol                                                                                                                                                    |
|   3 |    258.323275 |    726.733856 | Matt Crook                                                                                                                                                      |
|   4 |    939.160616 |    704.782422 | NA                                                                                                                                                              |
|   5 |    134.105434 |    195.477778 | Renato de Carvalho Ferreira                                                                                                                                     |
|   6 |    520.323856 |    644.426483 | David Tana                                                                                                                                                      |
|   7 |    910.552245 |    360.341501 | Caleb M. Brown                                                                                                                                                  |
|   8 |    327.842556 |    601.968068 | S.Martini                                                                                                                                                       |
|   9 |    918.692718 |    620.074286 | Zimices                                                                                                                                                         |
|  10 |    116.475959 |    596.124866 | Ieuan Jones                                                                                                                                                     |
|  11 |    260.137601 |    345.287935 | Gabriela Palomo-Munoz                                                                                                                                           |
|  12 |    556.141912 |    299.741931 | Steven Traver                                                                                                                                                   |
|  13 |    101.131277 |    306.184641 | Rebecca Groom                                                                                                                                                   |
|  14 |    693.424725 |    586.324902 | Sharon Wegner-Larsen                                                                                                                                            |
|  15 |    760.570102 |     44.541991 | Caleb M. Brown                                                                                                                                                  |
|  16 |    687.341712 |    330.183947 | Tyler Greenfield and Dean Schnabel                                                                                                                              |
|  17 |    157.132162 |    101.884491 | Zimices                                                                                                                                                         |
|  18 |    803.569920 |    220.394677 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                     |
|  19 |    345.915259 |    198.466213 | Ferran Sayol                                                                                                                                                    |
|  20 |    637.425019 |     75.770212 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  21 |    453.912466 |    175.720011 | Mo Hassan                                                                                                                                                       |
|  22 |    773.196959 |    441.858362 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  23 |    489.899228 |     94.037746 | Zimices                                                                                                                                                         |
|  24 |    924.796359 |    476.132868 | Felix Vaux                                                                                                                                                      |
|  25 |    517.842246 |    542.245875 | Zimices                                                                                                                                                         |
|  26 |    615.066433 |    138.793882 | Yan Wong                                                                                                                                                        |
|  27 |    445.494747 |    404.643062 | Ferran Sayol                                                                                                                                                    |
|  28 |    129.086557 |    692.372717 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                             |
|  29 |    450.044603 |    722.358728 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                        |
|  30 |    688.781462 |    701.038886 | Gareth Monger                                                                                                                                                   |
|  31 |    841.032522 |    380.625588 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
|  32 |    485.629342 |    246.206680 | Renata F. Martins                                                                                                                                               |
|  33 |    945.756580 |    242.745408 | Margot Michaud                                                                                                                                                  |
|  34 |    574.686317 |    418.729706 | NA                                                                                                                                                              |
|  35 |    373.208809 |    330.680449 | Scott Hartman, modified by T. Michael Keesey                                                                                                                    |
|  36 |    962.102964 |     69.762174 | Matt Crook                                                                                                                                                      |
|  37 |    818.365052 |    293.001105 | NA                                                                                                                                                              |
|  38 |    312.025197 |    480.556019 | Gareth Monger                                                                                                                                                   |
|  39 |    191.559110 |     28.485484 | Ingo Braasch                                                                                                                                                    |
|  40 |    147.957099 |    239.339182 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
|  41 |    274.059867 |     80.665050 | Scott Hartman                                                                                                                                                   |
|  42 |    760.994969 |    735.999815 | Matt Crook                                                                                                                                                      |
|  43 |    220.142387 |    189.949054 | Margot Michaud                                                                                                                                                  |
|  44 |    773.861680 |    528.222842 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                     |
|  45 |    602.047399 |    749.183354 | Gabriela Palomo-Munoz                                                                                                                                           |
|  46 |     81.500324 |    481.584082 | Conty (vectorized by T. Michael Keesey)                                                                                                                         |
|  47 |    429.499053 |     40.439157 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                  |
|  48 |     80.972828 |     79.747008 | Zimices                                                                                                                                                         |
|  49 |    670.856825 |    458.214612 | Steven Coombs                                                                                                                                                   |
|  50 |    317.113632 |     23.056161 | Margot Michaud                                                                                                                                                  |
|  51 |    224.142215 |    652.249320 | Birgit Lang                                                                                                                                                     |
|  52 |     82.855899 |    423.388863 | Chris huh                                                                                                                                                       |
|  53 |     33.466460 |    686.234563 | T. Michael Keesey                                                                                                                                               |
|  54 |    347.898407 |    767.823663 | Gareth Monger                                                                                                                                                   |
|  55 |    889.771179 |    742.986875 | Chase Brownstein                                                                                                                                                |
|  56 |    795.591877 |    107.442734 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                    |
|  57 |    149.298018 |    371.659830 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                     |
|  58 |    420.024827 |    596.466086 | Sebastian Stabinger                                                                                                                                             |
|  59 |    541.269325 |    377.106855 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  60 |    426.680103 |    296.345116 | Bruno Maggia                                                                                                                                                    |
|  61 |    475.118564 |    487.997070 | Jagged Fang Designs                                                                                                                                             |
|  62 |    527.966310 |     19.091938 | Markus A. Grohme                                                                                                                                                |
|  63 |    265.247345 |    220.498054 | Birgit Lang                                                                                                                                                     |
|  64 |    347.697381 |    738.126632 | Gareth Monger                                                                                                                                                   |
|  65 |    729.323154 |    187.433635 | Matt Martyniuk                                                                                                                                                  |
|  66 |     67.789517 |    776.645175 | Mattia Menchetti                                                                                                                                                |
|  67 |    606.541417 |    225.797968 | Tasman Dixon                                                                                                                                                    |
|  68 |    544.657751 |    480.518366 | (unknown)                                                                                                                                                       |
|  69 |    321.210258 |    411.397039 |                                                                                                                                                                 |
|  70 |    557.140610 |    339.565567 | Jagged Fang Designs                                                                                                                                             |
|  71 |    378.481891 |    111.818141 | Ferran Sayol                                                                                                                                                    |
|  72 |     49.477108 |    229.207428 | Gareth Monger                                                                                                                                                   |
|  73 |    235.011011 |    142.386396 | Scott Hartman                                                                                                                                                   |
|  74 |    940.105707 |    142.087247 | Jagged Fang Designs                                                                                                                                             |
|  75 |    869.484328 |     64.735261 | Beth Reinke                                                                                                                                                     |
|  76 |    710.058373 |    149.264101 | Gabriela Palomo-Munoz                                                                                                                                           |
|  77 |    720.678928 |     85.396381 | T. Michael Keesey                                                                                                                                               |
|  78 |    226.884316 |    588.991634 | Campbell Fleming                                                                                                                                                |
|  79 |    967.922963 |    747.627175 | NA                                                                                                                                                              |
|  80 |    543.407843 |    705.898668 | Gareth Monger                                                                                                                                                   |
|  81 |    148.019339 |    146.305662 | Iain Reid                                                                                                                                                       |
|  82 |    748.169547 |    490.912881 | T. Michael Keesey                                                                                                                                               |
|  83 |    814.625715 |    577.574254 | Zimices                                                                                                                                                         |
|  84 |    955.607540 |    559.131738 | Collin Gross                                                                                                                                                    |
|  85 |    844.008274 |    668.341871 | Tasman Dixon                                                                                                                                                    |
|  86 |    271.818818 |    547.518855 | Matt Martyniuk                                                                                                                                                  |
|  87 |    445.494694 |    460.576799 | Chris huh                                                                                                                                                       |
|  88 |    424.943909 |    523.931740 | Jay Matternes, vectorized by Zimices                                                                                                                            |
|  89 |    390.244374 |    245.524940 | Rene Martin                                                                                                                                                     |
|  90 |    917.897523 |    780.564067 | Lukasiniho                                                                                                                                                      |
|  91 |    160.099711 |    556.284044 | Noah Schlottman, photo by Antonio Guillén                                                                                                                       |
|  92 |    591.753264 |    693.222634 | Ferran Sayol                                                                                                                                                    |
|  93 |    752.849548 |    238.931774 | Tasman Dixon                                                                                                                                                    |
|  94 |    169.246705 |     59.323557 | T. Michael Keesey (after James & al.)                                                                                                                           |
|  95 |    358.964711 |    688.656929 | Henry Lydecker                                                                                                                                                  |
|  96 |    564.258671 |    615.823423 | Margot Michaud                                                                                                                                                  |
|  97 |     55.765100 |    365.441694 | Hugo Gruson                                                                                                                                                     |
|  98 |    526.476182 |     44.850870 | Benchill                                                                                                                                                        |
|  99 |    591.711690 |    583.507606 | Chris huh                                                                                                                                                       |
| 100 |    954.862543 |    320.963540 | Tasman Dixon                                                                                                                                                    |
| 101 |    853.425984 |    483.412551 | Noah Schlottman                                                                                                                                                 |
| 102 |    533.119940 |    160.290101 | Nina Skinner                                                                                                                                                    |
| 103 |    957.168958 |    498.954828 | FJDegrange                                                                                                                                                      |
| 104 |    268.327956 |    649.177775 | Emily Willoughby                                                                                                                                                |
| 105 |   1012.015492 |    243.134227 | Ferran Sayol                                                                                                                                                    |
| 106 |    430.703081 |    124.677798 | Ferran Sayol                                                                                                                                                    |
| 107 |   1008.778870 |    761.633822 | Gabriela Palomo-Munoz                                                                                                                                           |
| 108 |    866.249823 |    249.770755 | Alexandre Vong                                                                                                                                                  |
| 109 |    487.933834 |    607.710701 | Ferran Sayol                                                                                                                                                    |
| 110 |    160.121451 |    625.823886 | Zimices                                                                                                                                                         |
| 111 |    679.365693 |    760.541044 | Michelle Site                                                                                                                                                   |
| 112 |    591.722916 |     60.405594 | Matt Crook                                                                                                                                                      |
| 113 |    685.097580 |    124.401421 | Natasha Vitek                                                                                                                                                   |
| 114 |    468.295174 |    357.082650 | M Kolmann                                                                                                                                                       |
| 115 |    892.918894 |    330.066068 | Ingo Braasch                                                                                                                                                    |
| 116 |    287.154620 |    292.323660 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                |
| 117 |     27.053067 |    505.392441 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 118 |    484.128170 |    781.507129 | Steven Traver                                                                                                                                                   |
| 119 |     33.118666 |     28.498940 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 120 |    106.441701 |    236.319410 | Chris huh                                                                                                                                                       |
| 121 |   1007.598744 |    678.876168 | xgirouxb                                                                                                                                                        |
| 122 |    602.536603 |    570.149742 | Zimices                                                                                                                                                         |
| 123 |    286.864108 |    671.581585 | Smokeybjb                                                                                                                                                       |
| 124 |    469.917389 |    671.161810 | Anthony Caravaggi                                                                                                                                               |
| 125 |    676.694964 |    788.341811 | Smokeybjb                                                                                                                                                       |
| 126 |    810.721623 |     47.619694 | Carlos Cano-Barbacil                                                                                                                                            |
| 127 |     72.769705 |    128.718701 | Carlos Cano-Barbacil                                                                                                                                            |
| 128 |    733.274103 |    673.178833 | Noah Schlottman, photo by Antonio Guillén                                                                                                                       |
| 129 |    879.995339 |    677.474690 | NA                                                                                                                                                              |
| 130 |    536.111270 |    461.629068 | Ignacio Contreras                                                                                                                                               |
| 131 |    817.618042 |    197.064664 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 132 |     56.923757 |    143.218927 | NA                                                                                                                                                              |
| 133 |   1003.204932 |    191.416264 | Gareth Monger                                                                                                                                                   |
| 134 |    124.083039 |    639.278472 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                 |
| 135 |    649.163058 |     27.614332 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                              |
| 136 |    839.395507 |    187.810729 | Beth Reinke                                                                                                                                                     |
| 137 |    885.703869 |    234.939234 | Gabriela Palomo-Munoz                                                                                                                                           |
| 138 |   1007.355395 |    634.711921 | Alex Slavenko                                                                                                                                                   |
| 139 |    354.503583 |    671.766546 | Javiera Constanzo                                                                                                                                               |
| 140 |   1000.269805 |    561.102060 | Tasman Dixon                                                                                                                                                    |
| 141 |    738.551008 |    385.411320 | Matt Crook                                                                                                                                                      |
| 142 |    782.966541 |     80.763786 | Carlos Cano-Barbacil                                                                                                                                            |
| 143 |    424.462148 |    226.043305 | Katie S. Collins                                                                                                                                                |
| 144 |    384.303175 |    559.905283 | Steven Traver                                                                                                                                                   |
| 145 |    804.826167 |    638.463926 | Rachel Shoop                                                                                                                                                    |
| 146 |    876.503443 |    531.882936 | T. Michael Keesey (after Monika Betley)                                                                                                                         |
| 147 |     64.781318 |    532.437733 | NA                                                                                                                                                              |
| 148 |    189.022931 |    257.904356 | Zimices                                                                                                                                                         |
| 149 |    866.952498 |    632.674029 | Zimices                                                                                                                                                         |
| 150 |    993.141163 |    426.472224 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                          |
| 151 |    568.104999 |     93.920677 | Gareth Monger                                                                                                                                                   |
| 152 |    226.036105 |    549.986860 | Zimices                                                                                                                                                         |
| 153 |    371.392711 |    234.836062 | Jagged Fang Designs                                                                                                                                             |
| 154 |    894.839683 |    119.150737 | NA                                                                                                                                                              |
| 155 |    443.570559 |    353.570496 | Fernando Carezzano                                                                                                                                              |
| 156 |    749.864671 |    313.241346 | Jonathan Lawley                                                                                                                                                 |
| 157 |    872.712171 |    778.378669 | Margot Michaud                                                                                                                                                  |
| 158 |    670.547770 |    629.393056 | Jonathan Wells                                                                                                                                                  |
| 159 |    386.609432 |    455.306541 | Margot Michaud                                                                                                                                                  |
| 160 |    418.375176 |    643.991927 | Jesús Gómez, vectorized by Zimices                                                                                                                              |
| 161 |     83.770844 |    717.502870 | Zimices                                                                                                                                                         |
| 162 |     17.121063 |    250.730597 | Jagged Fang Designs                                                                                                                                             |
| 163 |    411.603520 |    443.296016 | Kamil S. Jaron                                                                                                                                                  |
| 164 |    571.044632 |    553.550068 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                      |
| 165 |     61.888272 |    571.617401 | Jagged Fang Designs                                                                                                                                             |
| 166 |    159.111885 |    649.665697 | Rebecca Groom                                                                                                                                                   |
| 167 |    247.820668 |    131.649265 | Iain Reid                                                                                                                                                       |
| 168 |    631.918066 |    365.744108 | Chris huh                                                                                                                                                       |
| 169 |    704.795835 |    637.914890 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                  |
| 170 |    230.282641 |     61.681127 | Zimices                                                                                                                                                         |
| 171 |    177.177963 |    777.732732 | Rebecca Groom                                                                                                                                                   |
| 172 |    257.451660 |    476.803645 | Lukasiniho                                                                                                                                                      |
| 173 |    618.946137 |    657.123447 | S.Martini                                                                                                                                                       |
| 174 |    433.550053 |     15.207598 | Margot Michaud                                                                                                                                                  |
| 175 |     18.245507 |    296.852041 | Markus A. Grohme                                                                                                                                                |
| 176 |    519.095238 |    592.375960 | NA                                                                                                                                                              |
| 177 |    345.257145 |    680.935539 | Chloé Schmidt                                                                                                                                                   |
| 178 |    566.971223 |    564.026887 | Gareth Monger                                                                                                                                                   |
| 179 |    885.686662 |    101.270801 | Margot Michaud                                                                                                                                                  |
| 180 |    375.694374 |    399.199607 | Bennet McComish, photo by Hans Hillewaert                                                                                                                       |
| 181 |    402.708766 |    342.114360 | Dean Schnabel                                                                                                                                                   |
| 182 |    909.979578 |    431.839007 | Jagged Fang Designs                                                                                                                                             |
| 183 |    348.135337 |    174.225325 | Scott Hartman                                                                                                                                                   |
| 184 |     81.198117 |     14.605007 | Trond R. Oskars                                                                                                                                                 |
| 185 |    819.804594 |    480.791376 | Jagged Fang Designs                                                                                                                                             |
| 186 |    167.588533 |    421.905648 | Gareth Monger                                                                                                                                                   |
| 187 |    442.527199 |    104.823725 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 188 |    888.272718 |     15.006896 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 189 |    140.975262 |    448.369324 | Markus A. Grohme                                                                                                                                                |
| 190 |    775.567531 |    400.425370 | Natasha Vitek                                                                                                                                                   |
| 191 |    354.688984 |    379.043858 | Jaime Headden                                                                                                                                                   |
| 192 |    505.762501 |    264.149351 | Nobu Tamura                                                                                                                                                     |
| 193 |    816.598067 |    774.521740 | Gabriela Palomo-Munoz                                                                                                                                           |
| 194 |     76.485721 |    247.324256 | Gabriela Palomo-Munoz                                                                                                                                           |
| 195 |    188.200653 |    681.133009 | Steven Traver                                                                                                                                                   |
| 196 |    352.614027 |    261.816718 | Renata F. Martins                                                                                                                                               |
| 197 |    557.242283 |    493.928290 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                 |
| 198 |    647.331043 |     15.750293 | Jagged Fang Designs                                                                                                                                             |
| 199 |     19.364139 |    278.240046 | Michael P. Taylor                                                                                                                                               |
| 200 |    346.281047 |    290.374143 | Dmitry Bogdanov                                                                                                                                                 |
| 201 |   1008.970493 |    578.541369 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 202 |    704.356977 |     79.000703 | Joanna Wolfe                                                                                                                                                    |
| 203 |    518.055405 |    783.341428 | Gareth Monger                                                                                                                                                   |
| 204 |    463.601626 |    227.961614 | NA                                                                                                                                                              |
| 205 |    637.726421 |    395.144680 | Gareth Monger                                                                                                                                                   |
| 206 |    371.294613 |    438.192139 | Kevin Sánchez                                                                                                                                                   |
| 207 |    599.655907 |    637.112798 | Jagged Fang Designs                                                                                                                                             |
| 208 |    811.677002 |    618.759238 | Birgit Lang                                                                                                                                                     |
| 209 |    991.645579 |    347.008317 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                      |
| 210 |    568.300573 |    782.864567 | Matt Crook                                                                                                                                                      |
| 211 |    717.155151 |    752.933377 | Agnello Picorelli                                                                                                                                               |
| 212 |    843.345511 |    554.371589 | Renata F. Martins                                                                                                                                               |
| 213 |    537.242281 |    192.988686 | Emily Willoughby                                                                                                                                                |
| 214 |    412.123039 |    579.086125 | Pete Buchholz                                                                                                                                                   |
| 215 |    837.188267 |    709.216877 | Smokeybjb                                                                                                                                                       |
| 216 |   1002.842503 |    364.557087 | Zimices                                                                                                                                                         |
| 217 |     71.664725 |    694.377739 | Roberto Díaz Sibaja                                                                                                                                             |
| 218 |    334.418277 |    543.555929 | Collin Gross                                                                                                                                                    |
| 219 |    101.601620 |    451.444363 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                 |
| 220 |    275.915274 |    448.660886 | Zimices                                                                                                                                                         |
| 221 |     81.471366 |    170.910614 | Jagged Fang Designs                                                                                                                                             |
| 222 |    967.909867 |    161.251919 | Ferran Sayol                                                                                                                                                    |
| 223 |    130.626130 |    730.178789 | Ferran Sayol                                                                                                                                                    |
| 224 |    558.221621 |    155.053143 | Ferran Sayol                                                                                                                                                    |
| 225 |    447.804459 |    140.613026 | Markus A. Grohme                                                                                                                                                |
| 226 |    457.897984 |    338.230297 | Tasman Dixon                                                                                                                                                    |
| 227 |    254.196793 |    297.757410 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 228 |    879.774566 |    513.378620 | Jakovche                                                                                                                                                        |
| 229 |    446.714612 |    558.941348 | Dean Schnabel                                                                                                                                                   |
| 230 |    398.342495 |     27.759861 | Joanna Wolfe                                                                                                                                                    |
| 231 |     19.167556 |    134.004536 | Chloé Schmidt                                                                                                                                                   |
| 232 |      8.711282 |    570.525106 | Anthony Caravaggi                                                                                                                                               |
| 233 |    275.674869 |    572.223798 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                |
| 234 |    137.475803 |    460.874575 | M Kolmann                                                                                                                                                       |
| 235 |    684.057280 |     64.044257 | Scott Reid                                                                                                                                                      |
| 236 |    389.532542 |    479.051023 | Carlos Cano-Barbacil                                                                                                                                            |
| 237 |    406.153474 |    417.917310 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                               |
| 238 |     72.648022 |    281.735404 | Tracy A. Heath                                                                                                                                                  |
| 239 |    946.840209 |    182.668873 | Milton Tan                                                                                                                                                      |
| 240 |     49.303555 |    395.900839 | B. Duygu Özpolat                                                                                                                                                |
| 241 |     43.284415 |    311.364282 | Zimices                                                                                                                                                         |
| 242 |    271.526799 |    766.838665 | Ieuan Jones                                                                                                                                                     |
| 243 |    180.470469 |    327.230405 | Jagged Fang Designs                                                                                                                                             |
| 244 |    165.478103 |    755.260283 | Andrew A. Farke                                                                                                                                                 |
| 245 |    904.110593 |    169.223807 | Trond R. Oskars                                                                                                                                                 |
| 246 |    607.352333 |    789.005601 | Matthew E. Clapham                                                                                                                                              |
| 247 |    497.145698 |    417.611367 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                     |
| 248 |     17.958947 |    613.772421 | Dmitry Bogdanov                                                                                                                                                 |
| 249 |    936.917490 |    398.193585 | Kamil S. Jaron                                                                                                                                                  |
| 250 |    489.073373 |    319.447736 | Jose Carlos Arenas-Monroy                                                                                                                                       |
| 251 |    365.354127 |    650.117903 | Scott Hartman                                                                                                                                                   |
| 252 |    614.437993 |    540.211889 | Gareth Monger                                                                                                                                                   |
| 253 |     41.026992 |    602.411976 | Michelle Site                                                                                                                                                   |
| 254 |    597.411574 |    525.710111 | David Orr                                                                                                                                                       |
| 255 |    287.105249 |    256.304464 | NA                                                                                                                                                              |
| 256 |    501.494114 |    459.300510 | NA                                                                                                                                                              |
| 257 |    917.406132 |    421.050804 | Chris huh                                                                                                                                                       |
| 258 |    223.813161 |    366.643845 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 259 |   1001.804792 |    599.210304 | Gareth Monger                                                                                                                                                   |
| 260 |    383.813297 |    714.699588 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                  |
| 261 |    320.215801 |    132.933650 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 262 |    583.925680 |    502.758581 | Margot Michaud                                                                                                                                                  |
| 263 |    354.724631 |    709.485292 | Steven Traver                                                                                                                                                   |
| 264 |    764.344631 |     99.690236 | Iain Reid                                                                                                                                                       |
| 265 |    842.109215 |     18.206654 | T. Michael Keesey                                                                                                                                               |
| 266 |    656.644220 |    654.417278 | Mason McNair                                                                                                                                                    |
| 267 |    762.221034 |    369.956006 | Sean McCann                                                                                                                                                     |
| 268 |    476.242844 |    652.964056 | Scott Hartman                                                                                                                                                   |
| 269 |    474.450584 |    440.624529 | Mykle Hoban                                                                                                                                                     |
| 270 |     94.253228 |    629.162807 | Maija Karala                                                                                                                                                    |
| 271 |    847.581675 |    787.773456 | Gareth Monger                                                                                                                                                   |
| 272 |    756.926477 |    713.395872 | Zimices                                                                                                                                                         |
| 273 |    183.477259 |    615.379977 | T. Michael Keesey                                                                                                                                               |
| 274 |    574.699874 |     41.276829 | Smokeybjb                                                                                                                                                       |
| 275 |    626.639665 |    345.391669 | Filip em                                                                                                                                                        |
| 276 |    820.802422 |    633.094509 | T. Michael Keesey                                                                                                                                               |
| 277 |   1007.852327 |    476.589459 | Matt Crook                                                                                                                                                      |
| 278 |    220.811152 |    297.416893 | Trond R. Oskars                                                                                                                                                 |
| 279 |    378.952938 |    180.546869 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                              |
| 280 |    226.888299 |    528.462765 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 281 |    842.158863 |    641.720103 | Zimices                                                                                                                                                         |
| 282 |    967.053773 |    781.421723 | Mathew Wedel                                                                                                                                                    |
| 283 |    700.264718 |    773.730839 | Scott Hartman                                                                                                                                                   |
| 284 |    769.363106 |    346.492506 | Steven Traver                                                                                                                                                   |
| 285 |    128.296844 |    203.207821 | C. Abraczinskas                                                                                                                                                 |
| 286 |     94.614368 |    150.860018 | Joanna Wolfe                                                                                                                                                    |
| 287 |     16.646060 |    778.715117 | Margot Michaud                                                                                                                                                  |
| 288 |    113.727757 |    555.565766 | Zimices                                                                                                                                                         |
| 289 |    239.730503 |    292.542717 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                               |
| 290 |    521.556676 |    718.002416 | Matt Crook                                                                                                                                                      |
| 291 |    752.275476 |    451.870407 | Sean McCann                                                                                                                                                     |
| 292 |    475.183129 |    741.149104 | Gareth Monger                                                                                                                                                   |
| 293 |     15.691856 |    374.928263 | Zimices                                                                                                                                                         |
| 294 |    623.599945 |    550.894603 | SecretJellyMan                                                                                                                                                  |
| 295 |    830.545638 |    655.065771 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 296 |    525.472247 |    212.915842 | Zimices                                                                                                                                                         |
| 297 |    242.199904 |    107.938331 | Tasman Dixon                                                                                                                                                    |
| 298 |    382.013281 |    503.451521 | T. Michael Keesey                                                                                                                                               |
| 299 |    882.237408 |    263.516375 | Dean Schnabel                                                                                                                                                   |
| 300 |     35.201351 |    561.671307 | Inessa Voet                                                                                                                                                     |
| 301 |     51.975635 |    576.056085 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                |
| 302 |    830.667667 |    335.168228 | Zimices                                                                                                                                                         |
| 303 |    849.321526 |    532.531480 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey   |
| 304 |    121.908936 |     40.586690 | NA                                                                                                                                                              |
| 305 |    582.882843 |    461.923171 | Tess Linden                                                                                                                                                     |
| 306 |    990.436393 |    504.792600 | Stanton F. Fink, vectorized by Zimices                                                                                                                          |
| 307 |    995.370642 |    164.701726 | Javier Luque                                                                                                                                                    |
| 308 |    449.710626 |    316.904359 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 309 |    898.371393 |    452.617184 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                  |
| 310 |   1015.167356 |    344.251425 | T. Michael Keesey                                                                                                                                               |
| 311 |    954.685549 |    305.291088 | Dmitry Bogdanov                                                                                                                                                 |
| 312 |    866.347822 |    701.796746 | Zimices                                                                                                                                                         |
| 313 |    530.676286 |    745.874903 | Tasman Dixon                                                                                                                                                    |
| 314 |    806.381309 |     65.652294 | T. Michael Keesey                                                                                                                                               |
| 315 |    135.163261 |    230.972215 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                   |
| 316 |    937.252642 |    508.756615 | FunkMonk                                                                                                                                                        |
| 317 |    261.274958 |    595.612624 | Zimices                                                                                                                                                         |
| 318 |    354.217307 |    153.875125 | Gabriela Palomo-Munoz                                                                                                                                           |
| 319 |    298.097739 |    277.680536 | Jagged Fang Designs                                                                                                                                             |
| 320 |    405.550341 |    623.614259 | NA                                                                                                                                                              |
| 321 |    639.814756 |    786.742681 | Zimices                                                                                                                                                         |
| 322 |    463.116241 |    752.098656 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                   |
| 323 |    217.861521 |    717.147365 | Steven Traver                                                                                                                                                   |
| 324 |     74.273432 |    406.668482 | Markus A. Grohme                                                                                                                                                |
| 325 |    323.632552 |     47.522190 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                    |
| 326 |     22.627121 |    161.790709 | Tauana J. Cunha                                                                                                                                                 |
| 327 |    864.833638 |    551.645169 | Birgit Lang                                                                                                                                                     |
| 328 |    485.130045 |     58.653724 | Sharon Wegner-Larsen                                                                                                                                            |
| 329 |    866.102068 |    331.708419 | Ferran Sayol                                                                                                                                                    |
| 330 |    201.816422 |    547.605520 | Terpsichores                                                                                                                                                    |
| 331 |    991.168153 |    312.542891 | Markus A. Grohme                                                                                                                                                |
| 332 |    339.634228 |    135.861253 | Scott Hartman                                                                                                                                                   |
| 333 |    275.214799 |    633.445762 | Birgit Lang, based on a photo by D. Sikes                                                                                                                       |
| 334 |     25.760113 |    539.992966 | Tracy A. Heath                                                                                                                                                  |
| 335 |    688.664103 |    638.232735 | Matt Crook                                                                                                                                                      |
| 336 |    407.117295 |      7.830521 | NA                                                                                                                                                              |
| 337 |    556.722467 |     92.439481 | Gareth Monger                                                                                                                                                   |
| 338 |   1007.630016 |    527.733787 | Dean Schnabel                                                                                                                                                   |
| 339 |    830.808018 |     95.281722 | Tasman Dixon                                                                                                                                                    |
| 340 |    644.819769 |    488.851393 | Bruno Maggia                                                                                                                                                    |
| 341 |     77.083776 |    739.166676 | Beth Reinke                                                                                                                                                     |
| 342 |    757.974878 |    281.346828 | Zimices                                                                                                                                                         |
| 343 |    554.300147 |    204.485781 | Scott Hartman                                                                                                                                                   |
| 344 |    621.831176 |    261.883658 | Matt Crook                                                                                                                                                      |
| 345 |    302.735517 |    301.671989 | Arthur S. Brum                                                                                                                                                  |
| 346 |    470.706532 |    275.972989 | Jagged Fang Designs                                                                                                                                             |
| 347 |    330.550577 |    706.005915 | NA                                                                                                                                                              |
| 348 |    662.809000 |    155.953872 | Zimices                                                                                                                                                         |
| 349 |    417.279254 |    344.326697 | Matt Crook                                                                                                                                                      |
| 350 |    265.592616 |     98.531685 | NA                                                                                                                                                              |
| 351 |    834.359469 |     72.284295 | B. Duygu Özpolat                                                                                                                                                |
| 352 |    149.474920 |    525.293881 | Joanna Wolfe                                                                                                                                                    |
| 353 |    154.107986 |    787.467254 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 354 |    233.033284 |    491.538594 | Steven Traver                                                                                                                                                   |
| 355 |    469.051100 |    133.919547 | Ignacio Contreras                                                                                                                                               |
| 356 |    355.573623 |    659.094731 | Scott Hartman                                                                                                                                                   |
| 357 |    480.814720 |    587.937789 | Curtis Clark and T. Michael Keesey                                                                                                                              |
| 358 |    576.202165 |    716.126722 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 359 |    220.310225 |    392.146333 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                    |
| 360 |    145.414743 |    759.794035 | Christoph Schomburg                                                                                                                                             |
| 361 |    493.190064 |    793.576005 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                    |
| 362 |    375.123191 |    218.510085 | Martin Kevil                                                                                                                                                    |
| 363 |    745.562013 |    130.585127 | Sharon Wegner-Larsen                                                                                                                                            |
| 364 |    389.629478 |    272.993492 | T. Michael Keesey                                                                                                                                               |
| 365 |    610.262674 |    712.616120 | Jagged Fang Designs                                                                                                                                             |
| 366 |    635.033619 |    148.250264 | Gareth Monger                                                                                                                                                   |
| 367 |    362.277133 |    368.959389 | Daniel Stadtmauer                                                                                                                                               |
| 368 |    333.930747 |     61.549870 | NA                                                                                                                                                              |
| 369 |    495.090475 |    214.273717 | Felix Vaux                                                                                                                                                      |
| 370 |    256.071248 |    690.336920 | FunkMonk                                                                                                                                                        |
| 371 |    613.881821 |    338.597477 | CNZdenek                                                                                                                                                        |
| 372 |     64.831021 |    626.788308 | Jesús Gómez, vectorized by Zimices                                                                                                                              |
| 373 |    367.735110 |    787.584426 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                          |
| 374 |    146.459194 |    214.040757 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                 |
| 375 |    283.158672 |      8.498742 | Gareth Monger                                                                                                                                                   |
| 376 |    595.154750 |    541.982878 | Gabriela Palomo-Munoz                                                                                                                                           |
| 377 |    213.923373 |    167.695221 | Zimices                                                                                                                                                         |
| 378 |   1008.209270 |    124.583337 | Sarah Werning                                                                                                                                                   |
| 379 |    827.946476 |    692.441429 | Gareth Monger                                                                                                                                                   |
| 380 |   1019.331226 |    284.202140 | T. Michael Keesey                                                                                                                                               |
| 381 |    298.237419 |    789.365504 | Lukasiniho                                                                                                                                                      |
| 382 |    605.955909 |     90.800886 | Markus A. Grohme                                                                                                                                                |
| 383 |    390.302999 |     14.227026 | Jagged Fang Designs                                                                                                                                             |
| 384 |    904.182740 |     24.855708 | Henry Lydecker                                                                                                                                                  |
| 385 |    925.790360 |    527.354600 | Tasman Dixon                                                                                                                                                    |
| 386 |    249.108001 |      7.612367 | Jagged Fang Designs                                                                                                                                             |
| 387 |    319.116698 |    113.714509 | Scott Hartman                                                                                                                                                   |
| 388 |    397.536668 |    362.573219 | Gabriela Palomo-Munoz                                                                                                                                           |
| 389 |    238.259034 |    789.405812 | Zimices                                                                                                                                                         |
| 390 |    945.505763 |    660.724271 | Harold N Eyster                                                                                                                                                 |
| 391 |    935.792303 |    283.584110 | Zimices                                                                                                                                                         |
| 392 |    846.507216 |    441.526305 | Margot Michaud                                                                                                                                                  |
| 393 |     69.846808 |    667.291968 | George Edward Lodge                                                                                                                                             |
| 394 |    966.414083 |    445.162363 | S.Martini                                                                                                                                                       |
| 395 |    203.102835 |    785.543705 | Dmitry Bogdanov                                                                                                                                                 |
| 396 |    830.577605 |    474.239541 | Markus A. Grohme                                                                                                                                                |
| 397 |    273.691960 |     38.878850 | Zimices                                                                                                                                                         |
| 398 |    399.207485 |    531.605347 | Collin Gross                                                                                                                                                    |
| 399 |   1008.433153 |    415.903245 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 400 |    544.545038 |    772.293518 | Margot Michaud                                                                                                                                                  |
| 401 |    534.908757 |     62.049612 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                  |
| 402 |    695.862468 |    216.454451 | Gareth Monger                                                                                                                                                   |
| 403 |    821.553483 |    665.644498 | Jagged Fang Designs                                                                                                                                             |
| 404 |    513.503825 |    673.257770 | Iain Reid                                                                                                                                                       |
| 405 |     31.842382 |    576.323250 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 406 |     12.937206 |    213.270047 | Kelly                                                                                                                                                           |
| 407 |    179.825424 |    313.881465 | Matt Crook                                                                                                                                                      |
| 408 |    500.413442 |    470.343949 | Jagged Fang Designs                                                                                                                                             |
| 409 |    850.702951 |    234.511197 | Chris huh                                                                                                                                                       |
| 410 |    979.291365 |    463.212343 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 411 |    618.304110 |    491.252022 | Benjamin Monod-Broca                                                                                                                                            |
| 412 |    680.319179 |     93.322569 | Steven Traver                                                                                                                                                   |
| 413 |   1002.697759 |    398.352279 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 414 |    931.666240 |    167.631706 | Zimices                                                                                                                                                         |
| 415 |    897.050133 |    313.990004 | T. K. Robinson                                                                                                                                                  |
| 416 |    810.106408 |    507.274966 | SauropodomorphMonarch                                                                                                                                           |
| 417 |    646.907180 |    412.911913 | Felix Vaux                                                                                                                                                      |
| 418 |    231.349684 |    116.754021 | Scott Hartman                                                                                                                                                   |
| 419 |    272.302157 |    606.040947 | Michelle Site                                                                                                                                                   |
| 420 |    601.644771 |     10.347408 | Tasman Dixon                                                                                                                                                    |
| 421 |    209.504221 |     66.928175 | Gareth Monger                                                                                                                                                   |
| 422 |    661.036674 |    495.642816 | Scott Hartman                                                                                                                                                   |
| 423 |    213.145037 |    579.211609 | FJDegrange                                                                                                                                                      |
| 424 |    919.445349 |    680.476045 | Jagged Fang Designs                                                                                                                                             |
| 425 |     26.981326 |    355.325268 | Felix Vaux                                                                                                                                                      |
| 426 |    767.020473 |     14.521725 | Daniel Stadtmauer                                                                                                                                               |
| 427 |     16.721202 |    171.813430 | Emily Willoughby                                                                                                                                                |
| 428 |   1007.690187 |     15.828417 | Ferran Sayol                                                                                                                                                    |
| 429 |     99.303004 |    115.434914 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                   |
| 430 |     18.551529 |    420.202655 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                              |
| 431 |    129.333257 |    779.818867 | Scott Hartman                                                                                                                                                   |
| 432 |    246.949048 |    633.042002 | Matus Valach                                                                                                                                                    |
| 433 |    841.507223 |    569.061952 | Chuanixn Yu                                                                                                                                                     |
| 434 |    273.807576 |    369.131095 | Blanco et al., 2014, vectorized by Zimices                                                                                                                      |
| 435 |    318.546140 |    389.336612 | Noah Schlottman, photo by Antonio Guillén                                                                                                                       |
| 436 |    669.203839 |    225.441266 | Diana Pomeroy                                                                                                                                                   |
| 437 |    179.835486 |    134.394012 | Scott Hartman                                                                                                                                                   |
| 438 |    267.863261 |    780.382601 | Melissa Broussard                                                                                                                                               |
| 439 |    103.372137 |    485.278881 | Tasman Dixon                                                                                                                                                    |
| 440 |     22.958307 |    444.131897 | Margot Michaud                                                                                                                                                  |
| 441 |     22.448798 |    150.179809 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                  |
| 442 |    797.472458 |      3.946514 | Chris huh                                                                                                                                                       |
| 443 |   1011.644295 |    445.641386 | xgirouxb                                                                                                                                                        |
| 444 |    128.745256 |    410.056927 | Chris huh                                                                                                                                                       |
| 445 |    842.800423 |    618.767010 | Steven Traver                                                                                                                                                   |
| 446 |    570.484135 |    670.487450 | Chris huh                                                                                                                                                       |
| 447 |    345.401112 |    354.238876 | Noah Schlottman, photo by Casey Dunn                                                                                                                            |
| 448 |    155.764437 |    511.139095 | Scott Hartman                                                                                                                                                   |
| 449 |    190.250959 |    582.024999 | Gabriela Palomo-Munoz                                                                                                                                           |
| 450 |    607.785956 |    378.934954 | Collin Gross                                                                                                                                                    |
| 451 |    188.099530 |    637.807819 | Margot Michaud                                                                                                                                                  |
| 452 |    196.453885 |    731.678050 | Karla Martinez                                                                                                                                                  |
| 453 |    500.306100 |    430.092143 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                          |
| 454 |   1019.676383 |    213.875986 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                               |
| 455 |    408.411758 |    564.102628 | Scott Hartman                                                                                                                                                   |
| 456 |    467.621495 |    448.344141 | Scott Hartman                                                                                                                                                   |
| 457 |   1003.790910 |    663.656133 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 458 |    521.100464 |    680.191570 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                |
| 459 |     65.806054 |    504.705258 | Mathew Wedel                                                                                                                                                    |
| 460 |    654.170077 |    175.306928 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                    |
| 461 |    445.577392 |    667.904900 | Zimices                                                                                                                                                         |
| 462 |   1008.462460 |    737.843059 | FunkMonk                                                                                                                                                        |
| 463 |    568.211682 |     56.139895 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                   |
| 464 |    112.184968 |     15.218444 | Ferran Sayol                                                                                                                                                    |
| 465 |    810.884879 |    757.536424 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 466 |    993.553644 |    796.984538 | Maija Karala                                                                                                                                                    |
| 467 |    804.897688 |    451.870873 | NA                                                                                                                                                              |
| 468 |    128.773853 |    276.151550 | Carlos Cano-Barbacil                                                                                                                                            |
| 469 |    355.086497 |    395.942455 | Tasman Dixon                                                                                                                                                    |
| 470 |    990.520366 |    758.285984 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 471 |    417.658166 |    791.296053 | NA                                                                                                                                                              |
| 472 |    403.177712 |    753.858159 | NA                                                                                                                                                              |
| 473 |    526.500366 |      6.712512 | Markus A. Grohme                                                                                                                                                |
| 474 |    842.158307 |     43.865072 | Markus A. Grohme                                                                                                                                                |
| 475 |     62.348939 |    298.341076 | Zimices                                                                                                                                                         |
| 476 |    789.514008 |    669.104987 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                         |
| 477 |    748.205725 |    344.636154 | T. Michael Keesey                                                                                                                                               |
| 478 |    790.174600 |    326.074174 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 479 |    333.570087 |    346.907545 | Noah Schlottman, photo by Casey Dunn                                                                                                                            |
| 480 |    734.282122 |    507.733580 | Chris huh                                                                                                                                                       |
| 481 |    750.755404 |     90.098750 | Bruno Maggia                                                                                                                                                    |
| 482 |     49.280123 |     17.089709 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                               |
| 483 |    925.674820 |     10.686571 | Zimices                                                                                                                                                         |
| 484 |     21.940973 |    392.564229 | Zimices                                                                                                                                                         |
| 485 |    773.704765 |    134.880893 | Gareth Monger                                                                                                                                                   |
| 486 |    934.631542 |    293.340913 | Smokeybjb, vectorized by Zimices                                                                                                                                |
| 487 |    573.086407 |    256.450861 | Sarah Werning                                                                                                                                                   |
| 488 |    755.648474 |    160.378719 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 489 |    142.130771 |     70.026286 | Zimices                                                                                                                                                         |
| 490 |    924.864559 |    579.693176 | Chris huh                                                                                                                                                       |
| 491 |    782.313804 |    479.763084 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                               |
| 492 |    521.208413 |    320.102995 | Caleb M. Brown                                                                                                                                                  |
| 493 |    863.259689 |    646.773436 | Matt Crook                                                                                                                                                      |
| 494 |    849.938047 |    207.760624 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 495 |    999.011627 |    549.478846 | Ignacio Contreras                                                                                                                                               |
| 496 |    883.989690 |    177.266333 | Margot Michaud                                                                                                                                                  |
| 497 |    310.656325 |    262.235320 | Mike Hanson                                                                                                                                                     |
| 498 |    674.469997 |     39.621406 | Steven Traver                                                                                                                                                   |
| 499 |    369.219113 |    639.197703 | Markus A. Grohme                                                                                                                                                |
| 500 |    992.278088 |    722.290349 | T. Michael Keesey                                                                                                                                               |
| 501 |    181.832361 |    746.871276 | T. Michael Keesey                                                                                                                                               |
| 502 |     75.487842 |     32.577726 | Tyler Greenfield                                                                                                                                                |
| 503 |    246.059848 |    267.876932 | Zimices                                                                                                                                                         |
| 504 |    625.243935 |    308.871292 | T. Michael Keesey                                                                                                                                               |
| 505 |     91.184086 |    398.071812 | NA                                                                                                                                                              |
| 506 |     17.416548 |    597.098796 | Steven Traver                                                                                                                                                   |
| 507 |    582.431342 |    360.191609 | Scott Hartman                                                                                                                                                   |
| 508 |    984.020484 |    589.424459 | Ignacio Contreras                                                                                                                                               |
| 509 |    558.311030 |    329.123765 | Tasman Dixon                                                                                                                                                    |
| 510 |     55.114805 |    453.456540 | Scott Hartman                                                                                                                                                   |
| 511 |    364.619957 |    139.940306 | Milton Tan                                                                                                                                                      |
| 512 |    960.477819 |    376.539600 | Chuanixn Yu                                                                                                                                                     |
| 513 |    287.109451 |    748.756873 | Jagged Fang Designs                                                                                                                                             |
| 514 |    210.996548 |    255.142832 | Juan Carlos Jerí                                                                                                                                                |
| 515 |    350.417479 |    124.978607 | Chris huh                                                                                                                                                       |

    #> Your tweet has been posted!
