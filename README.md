
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

Margot Michaud, Jagged Fang Designs, Alexander Schmidt-Lebuhn, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Ferran Sayol, Geoff Shaw, Chris huh, Rebecca Groom,
Joanna Wolfe, Dmitry Bogdanov, Felix Vaux, Emil Schmidt (vectorized by
Maxime Dahirel), T. Michael Keesey, Renata F. Martins, Zimices, Beth
Reinke, Xavier Giroux-Bougard, Katie S. Collins, Mareike C. Janiak,
Tasman Dixon, M Kolmann, Andy Wilson, Nobu Tamura (vectorized by T.
Michael Keesey), Joseph J. W. Sertich, Mark A. Loewen, Markus A. Grohme,
Smokeybjb, Emily Willoughby, Scott Hartman, Erika Schumacher, Matt
Dempsey, Tyler Greenfield, Roberto Díaz Sibaja, Mateus Zica (modified by
T. Michael Keesey), Campbell Fleming, Jose Carlos Arenas-Monroy, Joe
Schneid (vectorized by T. Michael Keesey), Dmitry Bogdanov (vectorized
by T. Michael Keesey), Jaime Headden, Didier Descouens (vectorized by T.
Michael Keesey), E. D. Cope (modified by T. Michael Keesey, Michael P.
Taylor & Matthew J. Wedel), Iain Reid, E. R. Waite & H. M. Hale
(vectorized by T. Michael Keesey), Apokryltaros (vectorized by T.
Michael Keesey), Steven Blackwood, Steven Traver, Nobu Tamura, Ville
Koistinen and T. Michael Keesey, Smokeybjb (vectorized by T. Michael
Keesey), Bruno Maggia, Carlos Cano-Barbacil, C. Camilo Julián-Caballero,
T. Michael Keesey (after James & al.), Francesco “Architetto” Rollandin,
Kamil S. Jaron, Robbie N. Cada (modified by T. Michael Keesey), Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Caleb Brown, Chloé Schmidt,
John Curtis (vectorized by T. Michael Keesey), Gareth Monger, Crystal
Maier, Matt Crook, Duane Raver (vectorized by T. Michael Keesey), Harold
N Eyster, Tracy A. Heath, Ghedoghedo (vectorized by T. Michael Keesey),
T. Michael Keesey (after MPF), L. Shyamal, David Orr, Andrew A. Farke,
Brad McFeeters (vectorized by T. Michael Keesey), Shyamal, François
Michonneau, Noah Schlottman, photo from National Science Foundation -
Turbellarian Taxonomic Database, Ignacio Contreras, Birgit Lang, Ingo
Braasch, Christoph Schomburg, FunkMonk, M. Antonio Todaro, Tobias
Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael
Keesey), Tom Tarrant (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Yan Wong from drawing by Joseph Smit,
Armin Reindl, Maxime Dahirel, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Zachary
Quigley, Nobu Tamura, vectorized by Zimices, Smokeybjb (modified by T.
Michael Keesey), James R. Spotila and Ray Chatterji, Mathieu Pélissié,
Michael Scroggie, Kai R. Caspar, Farelli (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Ghedo and T. Michael
Keesey, Eduard Solà Vázquez, vectorised by Yan Wong, L.M. Davalos,
Mathew Wedel, Dann Pigdon, Michelle Site, Manabu Bessho-Uehara, Mike
Hanson, Dean Schnabel, Yan Wong, Haplochromis (vectorized by T. Michael
Keesey), Tyler McCraney, Noah Schlottman, photo by Casey Dunn, Stephen
O’Connor (vectorized by T. Michael Keesey), Gopal Murali, Moussa
Direct Ltd. (photography) and T. Michael Keesey (vectorization),
Riccardo Percudani, Hans Hillewaert, Jim Bendon (photography) and T.
Michael Keesey (vectorization), Julio Garza, Jonathan Lawley,
SecretJellyMan - from Mason McNair, Jennifer Trimble, Jonathan Wells,
Rene Martin, Mykle Hoban, Scott Hartman (vectorized by T. Michael
Keesey), Nicholas J. Czaplewski, vectorized by Zimices, Lisa M. “Pixxl”
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Tony Ayling, Theodore W. Pietsch (photography) and T. Michael
Keesey (vectorization), Martien Brand (original photo), Renato Santos
(vector silhouette), Neil Kelley, Ellen Edmonson (illustration) and
Timothy J. Bartley (silhouette), Emily Jane McTavish, Tauana J. Cunha,
H. F. O. March (vectorized by T. Michael Keesey), DW Bapst (modified
from Bates et al., 2005), Arthur Weasley (vectorized by T. Michael
Keesey), Sarah Werning, Maija Karala, Almandine (vectorized by T.
Michael Keesey), Anthony Caravaggi, Zimices / Julián Bayona, Chuanixn
Yu, NOAA Great Lakes Environmental Research Laboratory (illustration)
and Timothy J. Bartley (silhouette), Alex Slavenko, Tony Ayling
(vectorized by T. Michael Keesey), Jake Warner, Melissa Ingala, Noah
Schlottman, photo from Moorea Biocode, Noah Schlottman, Javier Luque &
Sarah Gerken, Jaime Headden (vectorized by T. Michael Keesey), Zimices,
based in Mauricio Antón skeletal, Cristina Guijarro, Jimmy Bernot,
JCGiron, Jerry Oldenettel (vectorized by T. Michael Keesey), Ieuan
Jones, Lip Kee Yap (vectorized by T. Michael Keesey), Becky Barnes, Juan
Carlos Jerí, Dmitry Bogdanov (modified by T. Michael Keesey), Pollyanna
von Knorring and T. Michael Keesey, Gabriela Palomo-Munoz, Lily Hughes,
Gabriele Midolo, Steven Coombs, Matt Martyniuk, Myriam\_Ramirez, Collin
Gross, CNZdenek, Chris A. Hamilton, Brian Swartz (vectorized by T.
Michael Keesey), Scott Hartman, modified by T. Michael Keesey, Oscar
Sanisidro, Lisa Byrne, Milton Tan, Gustav Mützel, Dave Angelini,
Courtney Rockenbach, Pete Buchholz, Agnello Picorelli, Smokeybjb,
vectorized by Zimices, Mathieu Basille, Jordan Mallon (vectorized by T.
Michael Keesey), Ernst Haeckel (vectorized by T. Michael Keesey),
Maxwell Lefroy (vectorized by T. Michael Keesey), Lankester Edwin Ray
(vectorized by T. Michael Keesey), ДиБгд (vectorized by T. Michael
Keesey), Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz
Sibaja, SauropodomorphMonarch, Alexandre Vong, Scott Reid, Mark Witton

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                          |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    858.699854 |    396.207420 | Margot Michaud                                                                                                                                                  |
|   2 |    601.516068 |    607.151774 | Jagged Fang Designs                                                                                                                                             |
|   3 |     40.570435 |    270.591537 | Alexander Schmidt-Lebuhn                                                                                                                                        |
|   4 |    414.121781 |    307.555291 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                          |
|   5 |    230.660162 |    491.634342 | Ferran Sayol                                                                                                                                                    |
|   6 |    527.052701 |    380.265118 | Geoff Shaw                                                                                                                                                      |
|   7 |    370.527839 |     57.227384 | Chris huh                                                                                                                                                       |
|   8 |    504.078219 |    132.339227 | Rebecca Groom                                                                                                                                                   |
|   9 |    719.800407 |    604.492896 | Joanna Wolfe                                                                                                                                                    |
|  10 |    106.168864 |    693.597849 | Dmitry Bogdanov                                                                                                                                                 |
|  11 |    913.086446 |    664.651977 | Felix Vaux                                                                                                                                                      |
|  12 |    251.361561 |    331.454429 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                     |
|  13 |    261.041630 |    156.333830 | T. Michael Keesey                                                                                                                                               |
|  14 |    860.135815 |    128.085636 | Renata F. Martins                                                                                                                                               |
|  15 |    627.702471 |    302.531901 | Margot Michaud                                                                                                                                                  |
|  16 |    180.860271 |    231.370897 | Zimices                                                                                                                                                         |
|  17 |    354.105818 |    462.345730 | Beth Reinke                                                                                                                                                     |
|  18 |    729.451722 |    253.279713 | Xavier Giroux-Bougard                                                                                                                                           |
|  19 |    704.841580 |    702.512218 | Katie S. Collins                                                                                                                                                |
|  20 |    943.369591 |    331.345867 | NA                                                                                                                                                              |
|  21 |    672.618876 |    119.630872 | Mareike C. Janiak                                                                                                                                               |
|  22 |    663.300064 |    435.713429 | Tasman Dixon                                                                                                                                                    |
|  23 |    429.630034 |    687.449716 | M Kolmann                                                                                                                                                       |
|  24 |    560.192398 |    218.446680 | T. Michael Keesey                                                                                                                                               |
|  25 |    702.136135 |    522.552662 | Andy Wilson                                                                                                                                                     |
|  26 |    242.089921 |    709.463976 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  27 |    904.618424 |    519.599729 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                            |
|  28 |    234.305164 |     90.912006 | Markus A. Grohme                                                                                                                                                |
|  29 |    505.877978 |    494.091637 | Smokeybjb                                                                                                                                                       |
|  30 |    403.096086 |    619.569685 | Emily Willoughby                                                                                                                                                |
|  31 |    849.638747 |     51.139771 | Scott Hartman                                                                                                                                                   |
|  32 |    118.549127 |    323.466770 | Erika Schumacher                                                                                                                                                |
|  33 |    304.582743 |    753.599138 | Matt Dempsey                                                                                                                                                    |
|  34 |     62.934967 |    517.956056 | Tyler Greenfield                                                                                                                                                |
|  35 |    351.725844 |    411.104736 | Roberto Díaz Sibaja                                                                                                                                             |
|  36 |    210.642805 |    584.667079 | Andy Wilson                                                                                                                                                     |
|  37 |    487.088861 |    603.481380 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                     |
|  38 |    638.135259 |     49.928218 | Jagged Fang Designs                                                                                                                                             |
|  39 |    858.424897 |    603.250076 | Jagged Fang Designs                                                                                                                                             |
|  40 |   1002.270725 |    394.267680 | NA                                                                                                                                                              |
|  41 |    820.913107 |    315.665463 | Tasman Dixon                                                                                                                                                    |
|  42 |    867.815463 |    746.971685 | Joanna Wolfe                                                                                                                                                    |
|  43 |    368.064908 |    707.850544 | Campbell Fleming                                                                                                                                                |
|  44 |    391.767508 |    133.590902 | Beth Reinke                                                                                                                                                     |
|  45 |     88.154090 |    111.587769 | Jose Carlos Arenas-Monroy                                                                                                                                       |
|  46 |    497.657480 |    698.012760 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                   |
|  47 |    892.165909 |    208.412031 | Ferran Sayol                                                                                                                                                    |
|  48 |    259.085277 |     46.325863 | M Kolmann                                                                                                                                                       |
|  49 |    151.045840 |    433.871681 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
|  50 |    584.341099 |    679.055936 | Jaime Headden                                                                                                                                                   |
|  51 |    385.709112 |    204.970958 | Tasman Dixon                                                                                                                                                    |
|  52 |    226.806742 |    775.816506 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                              |
|  53 |    616.134287 |      7.067688 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                |
|  54 |    354.342588 |    382.897913 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  55 |    769.179129 |    449.144315 | Tasman Dixon                                                                                                                                                    |
|  56 |    586.723594 |    526.821746 | T. Michael Keesey                                                                                                                                               |
|  57 |    697.168096 |    374.312981 | Margot Michaud                                                                                                                                                  |
|  58 |    846.440604 |    555.279146 | Iain Reid                                                                                                                                                       |
|  59 |    575.179480 |    765.515260 | Tasman Dixon                                                                                                                                                    |
|  60 |    436.706438 |    511.020751 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                      |
|  61 |    493.251154 |     47.541301 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                  |
|  62 |    443.416934 |    250.106608 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  63 |     69.409329 |     55.182230 | Steven Blackwood                                                                                                                                                |
|  64 |    716.965774 |     17.837748 | Steven Traver                                                                                                                                                   |
|  65 |    121.778347 |    167.382727 | Nobu Tamura                                                                                                                                                     |
|  66 |    953.945737 |    460.813294 | Ville Koistinen and T. Michael Keesey                                                                                                                           |
|  67 |    674.185121 |    180.786804 | Zimices                                                                                                                                                         |
|  68 |    473.373638 |    419.580553 | Jagged Fang Designs                                                                                                                                             |
|  69 |    317.387955 |    248.151778 | T. Michael Keesey                                                                                                                                               |
|  70 |     90.478869 |    757.794292 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                     |
|  71 |    306.665041 |    550.775515 | Emily Willoughby                                                                                                                                                |
|  72 |    103.273185 |    390.672327 | Bruno Maggia                                                                                                                                                    |
|  73 |    963.479290 |     21.815628 | Carlos Cano-Barbacil                                                                                                                                            |
|  74 |    731.326570 |    775.161200 | T. Michael Keesey                                                                                                                                               |
|  75 |    915.009296 |    778.273431 | C. Camilo Julián-Caballero                                                                                                                                      |
|  76 |    784.686660 |     36.789856 | Iain Reid                                                                                                                                                       |
|  77 |    147.842774 |     33.105147 | T. Michael Keesey (after James & al.)                                                                                                                           |
|  78 |    816.363129 |    640.169266 | Scott Hartman                                                                                                                                                   |
|  79 |    786.498121 |    712.304979 | Emily Willoughby                                                                                                                                                |
|  80 |    435.107194 |    771.644850 | Emily Willoughby                                                                                                                                                |
|  81 |    150.364168 |    489.231765 | Francesco “Architetto” Rollandin                                                                                                                                |
|  82 |    451.040824 |     21.813515 | Markus A. Grohme                                                                                                                                                |
|  83 |    537.395844 |    302.065866 | Steven Traver                                                                                                                                                   |
|  84 |    658.051337 |    552.606345 | Zimices                                                                                                                                                         |
|  85 |    902.452055 |    267.783505 | Emily Willoughby                                                                                                                                                |
|  86 |     95.373115 |      9.747706 | Emily Willoughby                                                                                                                                                |
|  87 |    339.664546 |    781.326896 | Scott Hartman                                                                                                                                                   |
|  88 |    554.619806 |    464.657764 | NA                                                                                                                                                              |
|  89 |    626.483571 |    452.422175 | T. Michael Keesey                                                                                                                                               |
|  90 |    828.780613 |    257.220806 | Zimices                                                                                                                                                         |
|  91 |    477.970592 |    217.715533 | NA                                                                                                                                                              |
|  92 |   1011.857509 |    185.126851 | NA                                                                                                                                                              |
|  93 |    988.045716 |     65.841545 | Kamil S. Jaron                                                                                                                                                  |
|  94 |    935.590887 |    391.386283 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                  |
|  95 |    529.985118 |     92.382744 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                        |
|  96 |    993.070475 |    559.803444 | Ferran Sayol                                                                                                                                                    |
|  97 |    100.303631 |     71.058590 | Caleb Brown                                                                                                                                                     |
|  98 |    966.804153 |    728.859820 | Steven Traver                                                                                                                                                   |
|  99 |     30.151913 |     23.199105 | Jagged Fang Designs                                                                                                                                             |
| 100 |    415.629266 |    279.728972 | Steven Traver                                                                                                                                                   |
| 101 |     45.715993 |    613.025539 | Chloé Schmidt                                                                                                                                                   |
| 102 |    143.618337 |    666.767754 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                   |
| 103 |    743.203865 |    102.104808 | Gareth Monger                                                                                                                                                   |
| 104 |    606.756903 |    353.385406 | T. Michael Keesey                                                                                                                                               |
| 105 |    726.494367 |    313.164599 | Crystal Maier                                                                                                                                                   |
| 106 |    499.149591 |    538.697063 | Matt Crook                                                                                                                                                      |
| 107 |    292.714339 |    209.274043 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                   |
| 108 |    420.715080 |    698.998799 | Chris huh                                                                                                                                                       |
| 109 |    313.448504 |    305.936347 | Matt Crook                                                                                                                                                      |
| 110 |    488.545148 |    304.171456 | Harold N Eyster                                                                                                                                                 |
| 111 |    799.692535 |     65.976725 | Scott Hartman                                                                                                                                                   |
| 112 |    264.278170 |    652.863676 | Zimices                                                                                                                                                         |
| 113 |    416.215834 |     99.217073 | Tracy A. Heath                                                                                                                                                  |
| 114 |    757.863954 |    408.122982 | Matt Crook                                                                                                                                                      |
| 115 |    210.622071 |    184.477124 | Zimices                                                                                                                                                         |
| 116 |    432.591807 |    719.945760 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 117 |    475.232984 |    194.861922 | Scott Hartman                                                                                                                                                   |
| 118 |    574.704978 |     86.196684 | Zimices                                                                                                                                                         |
| 119 |    908.535432 |    421.165178 | T. Michael Keesey (after MPF)                                                                                                                                   |
| 120 |     21.934766 |    431.747448 | L. Shyamal                                                                                                                                                      |
| 121 |    967.291235 |    620.845613 | Zimices                                                                                                                                                         |
| 122 |     93.990556 |    579.264750 | David Orr                                                                                                                                                       |
| 123 |    173.394572 |    129.138230 | Ferran Sayol                                                                                                                                                    |
| 124 |    985.603720 |    236.655595 | Emily Willoughby                                                                                                                                                |
| 125 |    658.096608 |    473.960399 | Andrew A. Farke                                                                                                                                                 |
| 126 |      7.100560 |    389.376828 | T. Michael Keesey                                                                                                                                               |
| 127 |    345.274400 |    565.216506 | NA                                                                                                                                                              |
| 128 |    777.969976 |    512.054015 | T. Michael Keesey                                                                                                                                               |
| 129 |    482.418519 |    468.910701 | Matt Crook                                                                                                                                                      |
| 130 |     22.309671 |    114.752298 | Tasman Dixon                                                                                                                                                    |
| 131 |    558.757742 |    149.292373 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                |
| 132 |    828.545408 |    287.259340 | Shyamal                                                                                                                                                         |
| 133 |    117.631560 |    592.078939 | Erika Schumacher                                                                                                                                                |
| 134 |    377.504535 |    526.524621 | François Michonneau                                                                                                                                             |
| 135 |    471.228587 |    374.248300 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                       |
| 136 |     95.349577 |    210.761529 | Ignacio Contreras                                                                                                                                               |
| 137 |     17.570708 |    661.433095 | Birgit Lang                                                                                                                                                     |
| 138 |    191.538094 |    653.734854 | Ingo Braasch                                                                                                                                                    |
| 139 |    353.419928 |    599.173171 | Christoph Schomburg                                                                                                                                             |
| 140 |    522.072734 |    528.595805 | FunkMonk                                                                                                                                                        |
| 141 |    597.411624 |    753.240370 | Harold N Eyster                                                                                                                                                 |
| 142 |    758.853610 |    226.403975 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                        |
| 143 |     29.525359 |    407.116814 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 144 |     99.324194 |    240.284570 | Margot Michaud                                                                                                                                                  |
| 145 |    401.696758 |    790.078098 | Tasman Dixon                                                                                                                                                    |
| 146 |    460.093864 |    456.850704 | Scott Hartman                                                                                                                                                   |
| 147 |    961.154961 |    148.969636 | Yan Wong from drawing by Joseph Smit                                                                                                                            |
| 148 |    923.813213 |    558.543774 | Zimices                                                                                                                                                         |
| 149 |    969.385181 |    603.874135 | Armin Reindl                                                                                                                                                    |
| 150 |    639.122591 |     33.890306 | Maxime Dahirel                                                                                                                                                  |
| 151 |    494.384321 |    280.349220 | Steven Traver                                                                                                                                                   |
| 152 |    650.690094 |    587.282202 | T. Michael Keesey                                                                                                                                               |
| 153 |    887.896425 |    613.614692 | Scott Hartman                                                                                                                                                   |
| 154 |    857.179937 |    179.672400 | Steven Traver                                                                                                                                                   |
| 155 |     98.332860 |    261.813048 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                             |
| 156 |    299.462799 |     13.032564 | Zachary Quigley                                                                                                                                                 |
| 157 |    967.792438 |    378.708334 | Jagged Fang Designs                                                                                                                                             |
| 158 |    334.090580 |    354.154351 | Zimices                                                                                                                                                         |
| 159 |    812.514490 |    404.563107 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 160 |    851.293695 |    478.765381 | Margot Michaud                                                                                                                                                  |
| 161 |    653.536056 |    653.645047 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                     |
| 162 |    254.851103 |     12.736928 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                       |
| 163 |    156.303564 |    184.877234 | Zimices                                                                                                                                                         |
| 164 |    278.659978 |    679.345451 | Jaime Headden                                                                                                                                                   |
| 165 |    658.230180 |    515.978951 | Ferran Sayol                                                                                                                                                    |
| 166 |    550.948044 |    530.430084 | T. Michael Keesey                                                                                                                                               |
| 167 |    880.955801 |    203.835383 | Margot Michaud                                                                                                                                                  |
| 168 |    481.654597 |    182.543483 | Chris huh                                                                                                                                                       |
| 169 |    282.543016 |    475.291217 | Beth Reinke                                                                                                                                                     |
| 170 |    527.598296 |    556.280286 | Matt Crook                                                                                                                                                      |
| 171 |    633.585737 |    613.185329 | NA                                                                                                                                                              |
| 172 |    574.787579 |    331.323441 | Birgit Lang                                                                                                                                                     |
| 173 |    493.572926 |    231.805872 | Scott Hartman                                                                                                                                                   |
| 174 |     19.399635 |    183.720242 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 175 |    404.087135 |    221.672629 | Matt Crook                                                                                                                                                      |
| 176 |    646.177645 |    678.578250 | Kamil S. Jaron                                                                                                                                                  |
| 177 |     68.691651 |    446.107016 | James R. Spotila and Ray Chatterji                                                                                                                              |
| 178 |    187.876479 |    394.265121 | Mathieu Pélissié                                                                                                                                                |
| 179 |    165.402094 |    287.006324 | Jagged Fang Designs                                                                                                                                             |
| 180 |    989.836527 |    509.509777 | Tracy A. Heath                                                                                                                                                  |
| 181 |    510.195449 |    768.829742 | NA                                                                                                                                                              |
| 182 |    151.164863 |     56.169810 | NA                                                                                                                                                              |
| 183 |    416.971868 |    659.969424 | Zimices                                                                                                                                                         |
| 184 |    553.585025 |    704.094746 | Michael Scroggie                                                                                                                                                |
| 185 |     68.841474 |     21.573046 | Kai R. Caspar                                                                                                                                                   |
| 186 |     17.414812 |    526.690188 | Emily Willoughby                                                                                                                                                |
| 187 |     24.537260 |    345.126953 | Christoph Schomburg                                                                                                                                             |
| 188 |    261.274083 |    426.040979 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 189 |    807.250407 |    209.739667 | NA                                                                                                                                                              |
| 190 |    988.379647 |    274.101716 | Zimices                                                                                                                                                         |
| 191 |    671.580310 |    256.297365 | Ghedo and T. Michael Keesey                                                                                                                                     |
| 192 |     59.493490 |    419.879871 | Scott Hartman                                                                                                                                                   |
| 193 |    574.392570 |    120.108929 | Tracy A. Heath                                                                                                                                                  |
| 194 |    447.019707 |    750.358428 | Ferran Sayol                                                                                                                                                    |
| 195 |    448.017577 |    647.823396 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                     |
| 196 |    989.313052 |    172.821839 | L.M. Davalos                                                                                                                                                    |
| 197 |    480.077702 |    441.566434 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 198 |     20.192682 |    314.264589 | Matt Crook                                                                                                                                                      |
| 199 |    336.962137 |    525.556289 | Markus A. Grohme                                                                                                                                                |
| 200 |    237.111234 |    671.540743 | Mathieu Pélissié                                                                                                                                                |
| 201 |    965.156209 |    405.516913 | Matt Crook                                                                                                                                                      |
| 202 |   1011.552639 |    728.423126 | Armin Reindl                                                                                                                                                    |
| 203 |    348.631594 |     98.852497 | T. Michael Keesey                                                                                                                                               |
| 204 |    654.805308 |    208.383745 | Ignacio Contreras                                                                                                                                               |
| 205 |    476.118433 |    708.313907 | Mathew Wedel                                                                                                                                                    |
| 206 |    132.581412 |    411.261442 | Scott Hartman                                                                                                                                                   |
| 207 |    752.468562 |    519.466785 | Zimices                                                                                                                                                         |
| 208 |     87.200711 |    613.359684 | NA                                                                                                                                                              |
| 209 |    906.507267 |    439.856661 | Dann Pigdon                                                                                                                                                     |
| 210 |    594.550789 |     25.874165 | Steven Traver                                                                                                                                                   |
| 211 |    988.029658 |    791.965516 | Margot Michaud                                                                                                                                                  |
| 212 |    923.257170 |    583.623515 | Emily Willoughby                                                                                                                                                |
| 213 |    353.758723 |     22.768503 | C. Camilo Julián-Caballero                                                                                                                                      |
| 214 |     10.667289 |    638.354155 | Michelle Site                                                                                                                                                   |
| 215 |    347.420875 |    504.752235 | Zimices                                                                                                                                                         |
| 216 |    881.061119 |     64.060363 | Margot Michaud                                                                                                                                                  |
| 217 |    642.158666 |    780.960879 | Manabu Bessho-Uehara                                                                                                                                            |
| 218 |    182.077295 |    347.369757 | Mike Hanson                                                                                                                                                     |
| 219 |    949.450113 |    786.918211 | Dean Schnabel                                                                                                                                                   |
| 220 |    640.883664 |    442.397263 | Zimices                                                                                                                                                         |
| 221 |    511.255616 |    397.837041 | Yan Wong                                                                                                                                                        |
| 222 |    614.751999 |    503.975431 | Scott Hartman                                                                                                                                                   |
| 223 |     18.298711 |    749.522731 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                  |
| 224 |    391.173022 |    539.946891 | Tyler McCraney                                                                                                                                                  |
| 225 |    458.973242 |    671.398091 | Margot Michaud                                                                                                                                                  |
| 226 |     17.554515 |    714.844297 | Noah Schlottman, photo by Casey Dunn                                                                                                                            |
| 227 |    185.007333 |    667.111135 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                              |
| 228 |    407.918755 |    349.539288 | NA                                                                                                                                                              |
| 229 |    504.486252 |    634.859328 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                      |
| 230 |    791.570741 |    372.130113 | Gopal Murali                                                                                                                                                    |
| 231 |    754.966510 |    309.729513 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                          |
| 232 |    780.107579 |     76.869892 | Riccardo Percudani                                                                                                                                              |
| 233 |    616.316393 |    424.698326 | Hans Hillewaert                                                                                                                                                 |
| 234 |    342.094685 |    296.993035 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                  |
| 235 |    841.905439 |    522.668773 | NA                                                                                                                                                              |
| 236 |    641.342965 |    358.501217 | Birgit Lang                                                                                                                                                     |
| 237 |     20.430971 |    473.913873 | T. Michael Keesey                                                                                                                                               |
| 238 |    526.418919 |    451.861288 | Jagged Fang Designs                                                                                                                                             |
| 239 |    200.078263 |    310.905493 | Zimices                                                                                                                                                         |
| 240 |    271.745697 |    452.352270 | Julio Garza                                                                                                                                                     |
| 241 |    194.852421 |    448.588060 | Jonathan Lawley                                                                                                                                                 |
| 242 |    361.457717 |    267.522910 | Christoph Schomburg                                                                                                                                             |
| 243 |    523.240698 |    793.268058 | Jagged Fang Designs                                                                                                                                             |
| 244 |    194.897886 |    279.408395 | NA                                                                                                                                                              |
| 245 |    590.762814 |    284.191210 | SecretJellyMan - from Mason McNair                                                                                                                              |
| 246 |    357.642536 |    339.678608 | Jennifer Trimble                                                                                                                                                |
| 247 |    625.738141 |    257.615896 | Beth Reinke                                                                                                                                                     |
| 248 |    961.767028 |    764.003676 | Markus A. Grohme                                                                                                                                                |
| 249 |    209.427159 |    677.533877 | Chris huh                                                                                                                                                       |
| 250 |    703.669644 |     41.886537 | Jonathan Wells                                                                                                                                                  |
| 251 |   1007.888031 |    134.890224 | Matt Crook                                                                                                                                                      |
| 252 |    304.491701 |    657.234944 | Ferran Sayol                                                                                                                                                    |
| 253 |    205.736776 |     11.811939 | Rene Martin                                                                                                                                                     |
| 254 |    563.330349 |    441.984841 | Mykle Hoban                                                                                                                                                     |
| 255 |    279.695107 |     33.747220 | Jaime Headden                                                                                                                                                   |
| 256 |    697.122844 |    303.218757 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                 |
| 257 |     60.145418 |    791.543544 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                   |
| 258 |   1003.684783 |    597.997500 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 259 |    460.782731 |    560.133900 | Tony Ayling                                                                                                                                                     |
| 260 |    897.558601 |    363.461704 | Margot Michaud                                                                                                                                                  |
| 261 |     26.805214 |    142.161710 | Matt Crook                                                                                                                                                      |
| 262 |   1004.416117 |    296.260728 | Margot Michaud                                                                                                                                                  |
| 263 |    387.315240 |    293.791088 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                         |
| 264 |    454.244358 |    523.933120 | Beth Reinke                                                                                                                                                     |
| 265 |    740.080246 |    648.831439 | Ferran Sayol                                                                                                                                                    |
| 266 |     26.359593 |    104.297352 | Geoff Shaw                                                                                                                                                      |
| 267 |    816.289372 |    230.107022 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                               |
| 268 |    512.636326 |    457.178010 | Neil Kelley                                                                                                                                                     |
| 269 |    647.318452 |    238.157669 | Katie S. Collins                                                                                                                                                |
| 270 |     92.192613 |    421.108622 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 271 |    474.894996 |    160.579093 | Julio Garza                                                                                                                                                     |
| 272 |    324.894586 |    335.738337 | Jaime Headden                                                                                                                                                   |
| 273 |    953.100701 |    586.585565 | Matt Crook                                                                                                                                                      |
| 274 |    155.999736 |     14.249519 | Matt Crook                                                                                                                                                      |
| 275 |    776.823324 |    308.912855 | NA                                                                                                                                                              |
| 276 |    855.113825 |    700.555962 | Margot Michaud                                                                                                                                                  |
| 277 |     13.942070 |    781.456294 | Emily Jane McTavish                                                                                                                                             |
| 278 |     38.193800 |    578.565685 | Kamil S. Jaron                                                                                                                                                  |
| 279 |    671.684912 |     40.132952 | Smokeybjb                                                                                                                                                       |
| 280 |    747.919339 |    204.940721 | Tauana J. Cunha                                                                                                                                                 |
| 281 |    896.925774 |    758.741230 | C. Camilo Julián-Caballero                                                                                                                                      |
| 282 |    743.824245 |    343.808043 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                |
| 283 |    971.943187 |    106.210273 | Ferran Sayol                                                                                                                                                    |
| 284 |    173.097904 |    522.911254 | NA                                                                                                                                                              |
| 285 |    525.190702 |    435.262857 | Steven Traver                                                                                                                                                   |
| 286 |    445.442178 |     96.930738 | Carlos Cano-Barbacil                                                                                                                                            |
| 287 |    694.227137 |    323.262158 | NA                                                                                                                                                              |
| 288 |    262.327953 |    797.024286 | Ignacio Contreras                                                                                                                                               |
| 289 |      5.920626 |    467.430254 | DW Bapst (modified from Bates et al., 2005)                                                                                                                     |
| 290 |    971.438547 |    207.079871 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                |
| 291 |    250.319174 |    559.170101 | NA                                                                                                                                                              |
| 292 |    178.208531 |    143.442751 | Xavier Giroux-Bougard                                                                                                                                           |
| 293 |    337.502802 |    646.803367 | Sarah Werning                                                                                                                                                   |
| 294 |    339.049439 |    222.063785 | Tasman Dixon                                                                                                                                                    |
| 295 |    700.716529 |    577.847436 | Sarah Werning                                                                                                                                                   |
| 296 |    622.869547 |    525.927917 | Margot Michaud                                                                                                                                                  |
| 297 |    252.640536 |    193.272835 | Chris huh                                                                                                                                                       |
| 298 |    943.445964 |    410.611944 | C. Camilo Julián-Caballero                                                                                                                                      |
| 299 |    514.720686 |    336.940112 | NA                                                                                                                                                              |
| 300 |    128.695895 |    578.514541 | Ferran Sayol                                                                                                                                                    |
| 301 |    949.992623 |    639.201358 | T. Michael Keesey                                                                                                                                               |
| 302 |    977.702819 |    687.276985 | Maija Karala                                                                                                                                                    |
| 303 |    762.873406 |    377.139781 | Gareth Monger                                                                                                                                                   |
| 304 |    707.861376 |    634.276735 | Almandine (vectorized by T. Michael Keesey)                                                                                                                     |
| 305 |    950.841474 |    744.763936 | Matt Crook                                                                                                                                                      |
| 306 |    293.357578 |     58.603003 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 307 |    828.945566 |    707.995008 | Anthony Caravaggi                                                                                                                                               |
| 308 |    109.132719 |    790.467198 | NA                                                                                                                                                              |
| 309 |    825.317518 |    785.156166 | Zimices                                                                                                                                                         |
| 310 |     73.018063 |     82.125020 | Steven Traver                                                                                                                                                   |
| 311 |    422.727750 |    440.114778 | Kamil S. Jaron                                                                                                                                                  |
| 312 |    468.555659 |    141.963913 | Ferran Sayol                                                                                                                                                    |
| 313 |    682.296266 |    211.748155 | Tasman Dixon                                                                                                                                                    |
| 314 |   1003.509307 |    254.454234 | Steven Traver                                                                                                                                                   |
| 315 |    798.450013 |    611.753933 | T. Michael Keesey                                                                                                                                               |
| 316 |    744.859694 |    152.442857 | Zimices / Julián Bayona                                                                                                                                         |
| 317 |    449.394953 |    547.048940 | Chuanixn Yu                                                                                                                                                     |
| 318 |    766.864531 |     58.200694 | Andrew A. Farke                                                                                                                                                 |
| 319 |    644.313715 |    485.740759 | T. Michael Keesey (after James & al.)                                                                                                                           |
| 320 |    783.041662 |     11.131387 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                           |
| 321 |    671.307219 |    637.595100 | Alex Slavenko                                                                                                                                                   |
| 322 |    602.416938 |    146.995349 | Matt Crook                                                                                                                                                      |
| 323 |    996.890683 |      6.268034 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                   |
| 324 |    947.251345 |    248.088655 | NA                                                                                                                                                              |
| 325 |    811.916155 |    356.910807 | Margot Michaud                                                                                                                                                  |
| 326 |    315.056330 |    707.644074 | Margot Michaud                                                                                                                                                  |
| 327 |     17.106096 |    288.847436 | Birgit Lang                                                                                                                                                     |
| 328 |    736.010419 |    637.517502 | Jake Warner                                                                                                                                                     |
| 329 |    221.485304 |    737.196620 | Zimices                                                                                                                                                         |
| 330 |    622.308371 |    274.539595 | Melissa Ingala                                                                                                                                                  |
| 331 |    351.511610 |    117.463265 | Andy Wilson                                                                                                                                                     |
| 332 |    760.418997 |    543.497158 | Noah Schlottman, photo from Moorea Biocode                                                                                                                      |
| 333 |    170.629073 |     24.841319 | Noah Schlottman                                                                                                                                                 |
| 334 |    429.820369 |    482.978009 | Felix Vaux                                                                                                                                                      |
| 335 |     59.241667 |    144.762381 | Zimices                                                                                                                                                         |
| 336 |    590.854517 |    455.538178 | T. Michael Keesey                                                                                                                                               |
| 337 |    717.205592 |    459.853095 | Andrew A. Farke                                                                                                                                                 |
| 338 |    386.098507 |    361.841713 | Javier Luque & Sarah Gerken                                                                                                                                     |
| 339 |    392.736410 |    700.828837 | Matt Crook                                                                                                                                                      |
| 340 |    767.131716 |    755.217799 | Tracy A. Heath                                                                                                                                                  |
| 341 |   1001.622560 |    100.878177 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                 |
| 342 |     60.147484 |    782.576601 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                   |
| 343 |    882.892342 |    454.190560 | Markus A. Grohme                                                                                                                                                |
| 344 |    196.085653 |    154.218782 | Scott Hartman                                                                                                                                                   |
| 345 |    975.949157 |    430.855926 | Zimices, based in Mauricio Antón skeletal                                                                                                                       |
| 346 |    469.926439 |     91.187458 | Dmitry Bogdanov                                                                                                                                                 |
| 347 |     20.174670 |    369.492746 | Steven Traver                                                                                                                                                   |
| 348 |   1003.948450 |    488.657125 | Cristina Guijarro                                                                                                                                               |
| 349 |    155.339216 |    784.690163 | Christoph Schomburg                                                                                                                                             |
| 350 |    443.294720 |    387.578897 | Gareth Monger                                                                                                                                                   |
| 351 |    535.637904 |    733.535193 | NA                                                                                                                                                              |
| 352 |    317.067201 |    793.272454 | Iain Reid                                                                                                                                                       |
| 353 |    174.250438 |    747.165346 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 354 |    368.718070 |     79.824883 | Dmitry Bogdanov                                                                                                                                                 |
| 355 |    327.884868 |     71.009783 | Markus A. Grohme                                                                                                                                                |
| 356 |    752.899594 |    615.977102 | Alex Slavenko                                                                                                                                                   |
| 357 |    862.154308 |    163.252897 | Mathew Wedel                                                                                                                                                    |
| 358 |     63.589881 |    122.500261 | Jimmy Bernot                                                                                                                                                    |
| 359 |    428.034931 |     62.181062 | Jagged Fang Designs                                                                                                                                             |
| 360 |     67.877909 |    269.829271 | JCGiron                                                                                                                                                         |
| 361 |    417.194972 |    372.697169 | Andy Wilson                                                                                                                                                     |
| 362 |    791.424280 |    582.676453 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                              |
| 363 |    147.303984 |    699.086929 | Steven Traver                                                                                                                                                   |
| 364 |    365.023049 |    230.889717 | NA                                                                                                                                                              |
| 365 |    207.253338 |    344.246899 | Steven Traver                                                                                                                                                   |
| 366 |    855.684649 |     20.314227 | Steven Traver                                                                                                                                                   |
| 367 |    952.348237 |    161.706212 | Ieuan Jones                                                                                                                                                     |
| 368 |    491.667007 |    482.302786 | Yan Wong                                                                                                                                                        |
| 369 |    925.633498 |    573.386465 | Noah Schlottman, photo by Casey Dunn                                                                                                                            |
| 370 |    342.032165 |    765.849257 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                   |
| 371 |    493.173838 |    793.623730 | Jagged Fang Designs                                                                                                                                             |
| 372 |    464.259542 |    793.098587 | Jagged Fang Designs                                                                                                                                             |
| 373 |     57.950499 |      9.965901 | Becky Barnes                                                                                                                                                    |
| 374 |    761.906835 |    330.845414 | M Kolmann                                                                                                                                                       |
| 375 |    960.428176 |    501.078874 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 376 |    111.258834 |    544.051051 | Noah Schlottman                                                                                                                                                 |
| 377 |    196.512312 |    426.289795 | Juan Carlos Jerí                                                                                                                                                |
| 378 |    777.699164 |    792.249697 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                 |
| 379 |    811.163970 |    520.974502 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                    |
| 380 |   1006.883822 |    764.786528 | Gabriela Palomo-Munoz                                                                                                                                           |
| 381 |    297.291951 |    329.751020 | Anthony Caravaggi                                                                                                                                               |
| 382 |    180.403544 |    503.194996 | Lily Hughes                                                                                                                                                     |
| 383 |    818.175589 |      8.182757 | Scott Hartman                                                                                                                                                   |
| 384 |     17.480228 |     82.810857 | Michael Scroggie                                                                                                                                                |
| 385 |    273.579455 |    493.963545 | NA                                                                                                                                                              |
| 386 |    612.579455 |    480.563855 | Gabriele Midolo                                                                                                                                                 |
| 387 |    744.606195 |    488.053901 | Katie S. Collins                                                                                                                                                |
| 388 |    888.019677 |     10.274701 | Alex Slavenko                                                                                                                                                   |
| 389 |    258.248133 |     61.841913 | Margot Michaud                                                                                                                                                  |
| 390 |    636.046456 |    215.470774 | Iain Reid                                                                                                                                                       |
| 391 |    733.667433 |    417.202829 | Birgit Lang                                                                                                                                                     |
| 392 |    686.743415 |     76.538629 | Steven Coombs                                                                                                                                                   |
| 393 |    212.727085 |    164.716627 | Anthony Caravaggi                                                                                                                                               |
| 394 |    335.372931 |      7.266903 | Matt Martyniuk                                                                                                                                                  |
| 395 |    206.126967 |    469.579551 | Myriam\_Ramirez                                                                                                                                                 |
| 396 |    753.179906 |    356.836494 | Scott Hartman                                                                                                                                                   |
| 397 |    820.332710 |    461.446269 | Gareth Monger                                                                                                                                                   |
| 398 |    435.374086 |    216.496227 | NA                                                                                                                                                              |
| 399 |    604.873001 |    338.313685 | Chris huh                                                                                                                                                       |
| 400 |    883.839949 |    568.353339 | Margot Michaud                                                                                                                                                  |
| 401 |    325.434710 |    131.905041 | T. Michael Keesey                                                                                                                                               |
| 402 |    924.594405 |    700.473479 | Collin Gross                                                                                                                                                    |
| 403 |    103.063971 |    187.319402 | CNZdenek                                                                                                                                                        |
| 404 |    657.930017 |    763.116604 | Ignacio Contreras                                                                                                                                               |
| 405 |    163.594259 |    449.294911 | NA                                                                                                                                                              |
| 406 |    366.420094 |    574.559514 | Margot Michaud                                                                                                                                                  |
| 407 |    619.736459 |    585.525730 | Chris A. Hamilton                                                                                                                                               |
| 408 |    720.921447 |    795.569342 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                  |
| 409 |    121.501612 |    738.839223 | Tracy A. Heath                                                                                                                                                  |
| 410 |    476.984434 |    400.076219 | Scott Hartman, modified by T. Michael Keesey                                                                                                                    |
| 411 |    576.355107 |    175.229882 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 412 |     25.516674 |    125.745344 | Mike Hanson                                                                                                                                                     |
| 413 |    878.758357 |    714.114823 | Chris huh                                                                                                                                                       |
| 414 |    531.208161 |    413.537669 | Christoph Schomburg                                                                                                                                             |
| 415 |    247.192995 |    539.107220 | Gareth Monger                                                                                                                                                   |
| 416 |    569.030251 |    291.203437 | Jagged Fang Designs                                                                                                                                             |
| 417 |    486.237910 |    325.046926 | Markus A. Grohme                                                                                                                                                |
| 418 |    410.548379 |     71.675486 | Jonathan Wells                                                                                                                                                  |
| 419 |    224.243132 |    553.795097 | Gareth Monger                                                                                                                                                   |
| 420 |    162.201935 |    716.894402 | Jennifer Trimble                                                                                                                                                |
| 421 |    355.556210 |    751.062217 | Katie S. Collins                                                                                                                                                |
| 422 |    565.233238 |    348.733455 | Oscar Sanisidro                                                                                                                                                 |
| 423 |    972.933315 |    129.932867 | Margot Michaud                                                                                                                                                  |
| 424 |    742.878573 |    167.713817 | Lisa Byrne                                                                                                                                                      |
| 425 |    443.943452 |     38.328779 | Jagged Fang Designs                                                                                                                                             |
| 426 |    750.515983 |    665.827332 | M Kolmann                                                                                                                                                       |
| 427 |    610.917716 |    758.849685 | Markus A. Grohme                                                                                                                                                |
| 428 |    998.412466 |    112.898389 | Milton Tan                                                                                                                                                      |
| 429 |    506.716643 |    506.983948 | Scott Hartman                                                                                                                                                   |
| 430 |    743.058594 |    507.701394 | François Michonneau                                                                                                                                             |
| 431 |    850.121872 |    449.928078 | Mathew Wedel                                                                                                                                                    |
| 432 |    356.283313 |    787.099463 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 433 |    187.997408 |    374.687666 | NA                                                                                                                                                              |
| 434 |     44.715330 |    159.779232 | Ignacio Contreras                                                                                                                                               |
| 435 |    932.010881 |    262.150265 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 436 |    859.139075 |    767.860529 | Beth Reinke                                                                                                                                                     |
| 437 |    348.908039 |    612.882597 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                  |
| 438 |    395.352351 |    329.280809 | Gustav Mützel                                                                                                                                                   |
| 439 |     46.726252 |    645.714969 | Chris huh                                                                                                                                                       |
| 440 |    560.387693 |    272.926907 | M Kolmann                                                                                                                                                       |
| 441 |    240.286259 |     23.341294 | Ferran Sayol                                                                                                                                                    |
| 442 |    909.161639 |    493.088137 | Dave Angelini                                                                                                                                                   |
| 443 |    103.157195 |    143.967791 | Courtney Rockenbach                                                                                                                                             |
| 444 |    995.722455 |    632.705440 | Pete Buchholz                                                                                                                                                   |
| 445 |    462.057630 |    294.319424 | T. Michael Keesey                                                                                                                                               |
| 446 |    624.369824 |     80.710836 | Chris huh                                                                                                                                                       |
| 447 |    426.255123 |    527.061622 | Steven Traver                                                                                                                                                   |
| 448 |    494.130548 |    559.390174 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 449 |    545.180370 |    432.801693 | Agnello Picorelli                                                                                                                                               |
| 450 |     45.068313 |    433.073589 | Smokeybjb, vectorized by Zimices                                                                                                                                |
| 451 |    550.068885 |     72.935143 | T. Michael Keesey                                                                                                                                               |
| 452 |    905.721609 |    768.369256 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 453 |    117.579336 |    227.540704 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                |
| 454 |    570.859816 |    249.331788 | Matt Crook                                                                                                                                                      |
| 455 |    667.417527 |    788.251599 | Jagged Fang Designs                                                                                                                                             |
| 456 |    996.003403 |    700.355646 | Mathieu Basille                                                                                                                                                 |
| 457 |    871.153431 |    334.394528 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                 |
| 458 |    384.255024 |    778.406232 | Jagged Fang Designs                                                                                                                                             |
| 459 |    237.420294 |    165.228978 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                 |
| 460 |    472.607637 |    280.416187 | Yan Wong                                                                                                                                                        |
| 461 |    155.477977 |    639.326743 | Scott Hartman                                                                                                                                                   |
| 462 |    510.962182 |    471.692712 | NA                                                                                                                                                              |
| 463 |    536.699537 |     55.671337 | Birgit Lang                                                                                                                                                     |
| 464 |    413.916361 |    555.326550 | Scott Hartman                                                                                                                                                   |
| 465 |    938.804932 |    138.951203 | Matt Crook                                                                                                                                                      |
| 466 |    385.054667 |    183.638994 | Margot Michaud                                                                                                                                                  |
| 467 |    606.482966 |    651.531450 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                |
| 468 |    894.658643 |     30.866427 | Markus A. Grohme                                                                                                                                                |
| 469 |      6.517152 |    142.448297 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                           |
| 470 |    389.267527 |    261.279559 | CNZdenek                                                                                                                                                        |
| 471 |    389.406953 |    428.466059 | Emily Willoughby                                                                                                                                                |
| 472 |    956.099456 |    568.930680 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                         |
| 473 |    288.330316 |    726.877991 | Jagged Fang Designs                                                                                                                                             |
| 474 |    613.252198 |    283.009120 | Scott Hartman                                                                                                                                                   |
| 475 |    562.096168 |     29.374549 | Tasman Dixon                                                                                                                                                    |
| 476 |     30.020350 |    451.155349 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                          |
| 477 |     18.847488 |    558.515857 | SauropodomorphMonarch                                                                                                                                           |
| 478 |    903.753556 |    249.588256 | Markus A. Grohme                                                                                                                                                |
| 479 |    103.615516 |    774.168393 | Jaime Headden                                                                                                                                                   |
| 480 |    334.244040 |    661.879211 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 481 |    215.980131 |     27.349175 | Zimices                                                                                                                                                         |
| 482 |    287.503458 |     21.866748 | NA                                                                                                                                                              |
| 483 |    650.680871 |    347.829908 | Manabu Bessho-Uehara                                                                                                                                            |
| 484 |    817.307825 |    297.216732 | Birgit Lang                                                                                                                                                     |
| 485 |    403.822315 |    482.727416 | NA                                                                                                                                                              |
| 486 |    747.197565 |    761.373846 | Tony Ayling                                                                                                                                                     |
| 487 |     18.634327 |    758.258006 | Sarah Werning                                                                                                                                                   |
| 488 |    329.287561 |    323.951678 | Ingo Braasch                                                                                                                                                    |
| 489 |    195.447078 |     61.741477 | Steven Traver                                                                                                                                                   |
| 490 |    695.897537 |    450.598122 | Alexandre Vong                                                                                                                                                  |
| 491 |    525.156016 |    764.599713 | Sarah Werning                                                                                                                                                   |
| 492 |    669.612429 |    589.024289 | NA                                                                                                                                                              |
| 493 |    764.735598 |    694.078947 | Gareth Monger                                                                                                                                                   |
| 494 |    671.305478 |    221.609027 | NA                                                                                                                                                              |
| 495 |   1015.505449 |    278.777191 | Scott Hartman                                                                                                                                                   |
| 496 |    838.574556 |    643.443616 | M Kolmann                                                                                                                                                       |
| 497 |    549.556837 |    594.467213 | Matt Crook                                                                                                                                                      |
| 498 |    491.610654 |    769.707064 | Collin Gross                                                                                                                                                    |
| 499 |    302.087086 |     30.933196 | Scott Reid                                                                                                                                                      |
| 500 |    463.787192 |    502.882577 | Jagged Fang Designs                                                                                                                                             |
| 501 |    727.909505 |     83.929014 | Gareth Monger                                                                                                                                                   |
| 502 |    100.242543 |    604.084969 | T. Michael Keesey                                                                                                                                               |
| 503 |   1014.680364 |    680.281668 | Chloé Schmidt                                                                                                                                                   |
| 504 |     28.917426 |    644.599727 | Zimices                                                                                                                                                         |
| 505 |    642.563441 |    424.601818 | Collin Gross                                                                                                                                                    |
| 506 |    516.080721 |     67.692898 | Felix Vaux                                                                                                                                                      |
| 507 |    623.360187 |    187.064266 | Birgit Lang                                                                                                                                                     |
| 508 |    633.034438 |    656.922061 | Scott Hartman                                                                                                                                                   |
| 509 |    771.288260 |    565.667632 | Mark Witton                                                                                                                                                     |

    #> Your tweet has been posted!
