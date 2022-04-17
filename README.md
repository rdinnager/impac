
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

Jerry Oldenettel (vectorized by T. Michael Keesey), Mattia Menchetti,
FunkMonk, T. Michael Keesey, Dmitry Bogdanov, Steven Traver, Birgit
Lang, Ignacio Contreras, Roberto Díaz Sibaja, Margot Michaud, Joanna
Wolfe, Caroline Harding, MAF (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Carol Cummings, Zimices, Tony Ayling (vectorized by
T. Michael Keesey), Jiekun He, xgirouxb, Katie S. Collins, Gareth
Monger, Jose Carlos Arenas-Monroy, Jagged Fang Designs, Ludwik
Gasiorowski, Maxime Dahirel, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Scott Hartman, C. Camilo Julián-Caballero, Lafage, Nobu Tamura
(vectorized by T. Michael Keesey), Derek Bakken (photograph) and T.
Michael Keesey (vectorization), S.Martini, Tauana J. Cunha, Amanda
Katzer, CNZdenek, Charles Doolittle Walcott (vectorized by T. Michael
Keesey), Lukasiniho, Unknown (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Maija Karala, Jack Mayer Wood, M
Kolmann, Ferran Sayol, Chris huh, Jaime Headden, Andy Wilson, Danny
Cicchetti (vectorized by T. Michael Keesey), Alexandra van der Geer,
Agnello Picorelli, Brian Swartz (vectorized by T. Michael Keesey),
Gustav Mützel, Zachary Quigley, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Mathilde Cordellier, Christian A. Masnaghetti, Matt Martyniuk
(vectorized by T. Michael Keesey), Michelle Site, Dean Schnabel, Darren
Naish (vectorize by T. Michael Keesey), Arthur S. Brum, Meliponicultor
Itaymbere, Kamil S. Jaron, Matt Celeskey, Haplochromis (vectorized by T.
Michael Keesey), Tasman Dixon, Collin Gross, Darren Naish (vectorized by
T. Michael Keesey), Milton Tan, Xavier Giroux-Bougard, Robert Hering, DW
Bapst, modified from Ishitani et al. 2016, Joseph Wolf, 1863
(vectorization by Dinah Challen), Dmitry Bogdanov (modified by T.
Michael Keesey), Nobu Tamura, Robert Gay, Felix Vaux, Ieuan Jones, T.
Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia
Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika
Timm, and David W. Wrase (photography), Courtney Rockenbach, Matt Crook,
T. Michael Keesey (after MPF), Cesar Julian, Gabriela Palomo-Munoz, Pete
Buchholz, Rebecca Groom, Ron Holmes/U. S. Fish and Wildlife Service
(source photo), T. Michael Keesey (vectorization), Emily Willoughby,
Hans Hillewaert (vectorized by T. Michael Keesey), Cathy, Tracy A.
Heath, Mike Keesey (vectorization) and Vaibhavcho (photography), Noah
Schlottman, photo from Moorea Biocode, Scott Hartman (modified by T.
Michael Keesey), Matthew E. Clapham, Marcos Pérez-Losada, Jens T. Høeg &
Keith A. Crandall, Geoff Shaw, Mali’o Kodis, image by Rebecca Ritger,
Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Michael Wolf (photo), Hans Hillewaert (editing), T.
Michael Keesey (vectorization), Jay Matternes (modified by T. Michael
Keesey), Michael Scroggie, T. Tischler, Erika Schumacher,
SecretJellyMan, T. Michael Keesey (after Colin M. L. Burnett), Chloé
Schmidt, Eric Moody, David Orr, Mali’o Kodis, photograph by “Wildcat
Dunny” (<http://www.flickr.com/people/wildcat_dunny/>), Alexandre Vong,
Noah Schlottman, photo by Casey Dunn, Daniel Stadtmauer, Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Mathieu Pélissié, Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by
Iñaki Ruiz-Trillo), Smokeybjb (vectorized by T. Michael Keesey),
Mariana Ruiz Villarreal (modified by T. Michael Keesey), Markus A.
Grohme, Matt Martyniuk, Andrew A. Farke, Lauren Sumner-Rooney, Yan Wong,
Darius Nau, M. A. Broussard, Diego Fontaneto, Elisabeth A. Herniou,
Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and
Timothy G. Barraclough (vectorized by T. Michael Keesey), Alex Slavenko,
Arthur Weasley (vectorized by T. Michael Keesey), Lukas Panzarin
(vectorized by T. Michael Keesey), Steve Hillebrand/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Francis de Laporte de Castelnau (vectorized by T. Michael Keesey),
Jakovche, Beth Reinke, Mali’o Kodis, photograph by John Slapcinsky,
Apokryltaros (vectorized by T. Michael Keesey), Nobu Tamura, vectorized
by Zimices, Smith609 and T. Michael Keesey, Tyler Greenfield, Maxwell
Lefroy (vectorized by T. Michael Keesey), John Curtis (vectorized by T.
Michael Keesey), Scarlet23 (vectorized by T. Michael Keesey), Kai R.
Caspar, Shyamal, Karla Martinez, Scott Hartman (vectorized by T. Michael
Keesey), Ingo Braasch, Tommaso Cancellario, Mathieu Basille, Matt Hayes,
Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Fernando Campos De Domenico, Peter Coxhead, Javier Luque &
Sarah Gerken, Duane Raver (vectorized by T. Michael Keesey), Sergio A.
Muñoz-Gómez, TaraTaylorDesign, New York Zoological Society, RS, Robert
Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the
Western Hemisphere”, T. Michael Keesey (vectorization) and Larry Loos
(photography), Yan Wong from photo by Denes Emoke, Armin Reindl,
Ghedoghedo (vectorized by T. Michael Keesey), Manabu Bessho-Uehara,
Julio Garza, Iain Reid, Sarah Werning, Rene Martin, Becky Barnes, Arthur
Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Evan-Amos (vectorized by T. Michael Keesey), Christina
N. Hodson, Carlos Cano-Barbacil, B. Duygu Özpolat, Martin R. Smith,
after Skovsted et al 2015, SauropodomorphMonarch, Mo Hassan, Melissa
Ingala, Mateus Zica (modified by T. Michael Keesey), Smokeybjb, Rachel
Shoop, Christoph Schomburg, Harold N Eyster, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, FunkMonk \[Michael B.H.\]
(modified by T. Michael Keesey), M Hutchinson, Kailah Thorn & Mark
Hutchinson, Martin R. Smith

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     888.77680 |    581.752919 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
|   2 |     455.56660 |    468.224600 | Mattia Menchetti                                                                                                                                                                     |
|   3 |     560.85945 |    144.949706 | FunkMonk                                                                                                                                                                             |
|   4 |     726.07128 |    723.375022 | T. Michael Keesey                                                                                                                                                                    |
|   5 |     245.23786 |    213.957779 | Dmitry Bogdanov                                                                                                                                                                      |
|   6 |      68.77295 |    522.868432 | Steven Traver                                                                                                                                                                        |
|   7 |      58.60682 |    178.234380 | Birgit Lang                                                                                                                                                                          |
|   8 |     154.21621 |     93.008202 | Ignacio Contreras                                                                                                                                                                    |
|   9 |     731.22140 |    560.686281 | Birgit Lang                                                                                                                                                                          |
|  10 |     374.96911 |    606.832366 | T. Michael Keesey                                                                                                                                                                    |
|  11 |     601.27398 |    668.210785 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  12 |     667.19892 |    452.091123 | T. Michael Keesey                                                                                                                                                                    |
|  13 |     264.02304 |    628.150631 | Margot Michaud                                                                                                                                                                       |
|  14 |     560.14015 |    599.228704 | Joanna Wolfe                                                                                                                                                                         |
|  15 |     578.71751 |    397.401703 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
|  16 |     751.90989 |    101.285117 | Noah Schlottman, photo by Carol Cummings                                                                                                                                             |
|  17 |     859.52008 |    295.451566 | Zimices                                                                                                                                                                              |
|  18 |     301.88103 |    724.133469 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
|  19 |     978.55410 |    125.225508 | Jiekun He                                                                                                                                                                            |
|  20 |     396.28915 |    261.787729 | xgirouxb                                                                                                                                                                             |
|  21 |     570.18672 |    313.916317 | Katie S. Collins                                                                                                                                                                     |
|  22 |     410.69552 |    373.586430 | Gareth Monger                                                                                                                                                                        |
|  23 |     921.82192 |    746.335658 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
|  24 |     706.93218 |    227.354713 | Margot Michaud                                                                                                                                                                       |
|  25 |      69.48682 |     25.445422 | Jagged Fang Designs                                                                                                                                                                  |
|  26 |     717.28703 |    349.683878 | Ludwik Gasiorowski                                                                                                                                                                   |
|  27 |     866.42059 |    112.253769 | Zimices                                                                                                                                                                              |
|  28 |     182.32797 |    680.703014 | Margot Michaud                                                                                                                                                                       |
|  29 |     237.66136 |    377.620907 | Maxime Dahirel                                                                                                                                                                       |
|  30 |     299.34293 |    476.628917 | Gareth Monger                                                                                                                                                                        |
|  31 |     896.32391 |    658.334894 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  32 |     212.53806 |    549.381662 | Scott Hartman                                                                                                                                                                        |
|  33 |     362.23536 |     57.091501 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  34 |     962.71833 |    454.293400 | Margot Michaud                                                                                                                                                                       |
|  35 |     540.06470 |     51.054198 | Lafage                                                                                                                                                                               |
|  36 |     510.98690 |    767.501275 | Margot Michaud                                                                                                                                                                       |
|  37 |     367.75937 |    328.355630 | NA                                                                                                                                                                                   |
|  38 |     439.07961 |    714.718385 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  39 |     488.76667 |    169.050758 | Jagged Fang Designs                                                                                                                                                                  |
|  40 |     618.61312 |    539.047128 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
|  41 |      90.35832 |    388.505050 | S.Martini                                                                                                                                                                            |
|  42 |     938.14414 |    382.612711 | Tauana J. Cunha                                                                                                                                                                      |
|  43 |     676.35476 |     39.526589 | Amanda Katzer                                                                                                                                                                        |
|  44 |     409.52243 |    523.420517 | CNZdenek                                                                                                                                                                             |
|  45 |      51.49415 |    298.448203 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                          |
|  46 |     307.81579 |    774.820957 | Scott Hartman                                                                                                                                                                        |
|  47 |      94.21286 |    745.628408 | NA                                                                                                                                                                                   |
|  48 |     444.42381 |    601.237083 | T. Michael Keesey                                                                                                                                                                    |
|  49 |     572.38827 |    713.415452 | Lukasiniho                                                                                                                                                                           |
|  50 |     832.08308 |    181.788427 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
|  51 |     842.68439 |    228.052031 | Maija Karala                                                                                                                                                                         |
|  52 |     960.84173 |    547.598221 | Jack Mayer Wood                                                                                                                                                                      |
|  53 |     391.89472 |    686.196405 | M Kolmann                                                                                                                                                                            |
|  54 |     291.50733 |    337.520578 | NA                                                                                                                                                                                   |
|  55 |     863.87127 |    443.580453 | Gareth Monger                                                                                                                                                                        |
|  56 |      60.41839 |    616.441407 | Lukasiniho                                                                                                                                                                           |
|  57 |     590.62915 |    193.845518 | Jagged Fang Designs                                                                                                                                                                  |
|  58 |     389.26406 |    167.242698 | Ferran Sayol                                                                                                                                                                         |
|  59 |     612.97792 |    777.473318 | Chris huh                                                                                                                                                                            |
|  60 |     208.06177 |    764.133410 | Gareth Monger                                                                                                                                                                        |
|  61 |     503.41850 |    294.416120 | NA                                                                                                                                                                                   |
|  62 |     350.76096 |    436.928095 | Jaime Headden                                                                                                                                                                        |
|  63 |     773.43720 |    650.877864 | Andy Wilson                                                                                                                                                                          |
|  64 |     917.72789 |     52.797413 | NA                                                                                                                                                                                   |
|  65 |     371.66980 |     18.670302 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  66 |     659.68577 |     97.893845 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                                    |
|  67 |     681.37933 |    512.513283 | Scott Hartman                                                                                                                                                                        |
|  68 |     784.99644 |    759.499351 | Margot Michaud                                                                                                                                                                       |
|  69 |     527.94000 |    499.990368 | Alexandra van der Geer                                                                                                                                                               |
|  70 |    1003.98638 |    216.321189 | Agnello Picorelli                                                                                                                                                                    |
|  71 |     738.14006 |    150.060955 | Chris huh                                                                                                                                                                            |
|  72 |     344.01663 |    408.193565 | Chris huh                                                                                                                                                                            |
|  73 |     942.18489 |    510.494139 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                       |
|  74 |     956.59088 |    330.000661 | Gustav Mützel                                                                                                                                                                        |
|  75 |     178.43954 |     35.626435 | Gareth Monger                                                                                                                                                                        |
|  76 |     215.80584 |    508.804062 | NA                                                                                                                                                                                   |
|  77 |     171.34598 |    339.803875 | Ferran Sayol                                                                                                                                                                         |
|  78 |    1001.42443 |    757.818549 | NA                                                                                                                                                                                   |
|  79 |     181.67440 |    457.809017 | Birgit Lang                                                                                                                                                                          |
|  80 |     849.38767 |    787.045443 | Zachary Quigley                                                                                                                                                                      |
|  81 |     320.80561 |    226.201770 | Maija Karala                                                                                                                                                                         |
|  82 |      17.91433 |    725.747982 | T. Michael Keesey                                                                                                                                                                    |
|  83 |     611.54695 |    228.259190 | Birgit Lang                                                                                                                                                                          |
|  84 |     489.11147 |    670.195604 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  85 |     168.47207 |    400.280690 | Mathilde Cordellier                                                                                                                                                                  |
|  86 |     720.71505 |    187.701589 | NA                                                                                                                                                                                   |
|  87 |     715.97181 |    267.204214 | Christian A. Masnaghetti                                                                                                                                                             |
|  88 |     172.11321 |    605.696630 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
|  89 |     825.32852 |    371.893625 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  90 |     328.76819 |    523.058479 | Ferran Sayol                                                                                                                                                                         |
|  91 |      32.65055 |     71.315331 | Katie S. Collins                                                                                                                                                                     |
|  92 |     972.48734 |     35.078212 | Michelle Site                                                                                                                                                                        |
|  93 |     362.93785 |    289.761412 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
|  94 |     750.62759 |    414.818570 | Margot Michaud                                                                                                                                                                       |
|  95 |     238.21228 |    670.184795 | Dean Schnabel                                                                                                                                                                        |
|  96 |     110.92980 |    214.106484 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
|  97 |     638.03213 |    411.570851 | Arthur S. Brum                                                                                                                                                                       |
|  98 |     314.36766 |    567.646695 | Jagged Fang Designs                                                                                                                                                                  |
|  99 |     462.40632 |    119.843908 | Ignacio Contreras                                                                                                                                                                    |
| 100 |     432.43615 |    200.759582 | Meliponicultor Itaymbere                                                                                                                                                             |
| 101 |      43.17754 |    444.176671 | Kamil S. Jaron                                                                                                                                                                       |
| 102 |     932.97428 |    202.822669 | Matt Celeskey                                                                                                                                                                        |
| 103 |     496.27601 |    107.815580 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 104 |     852.44993 |    525.583616 | Ignacio Contreras                                                                                                                                                                    |
| 105 |     762.34143 |    462.554844 | Tasman Dixon                                                                                                                                                                         |
| 106 |     158.78117 |    487.725135 | Collin Gross                                                                                                                                                                         |
| 107 |     403.94784 |    763.968335 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 108 |     181.02389 |    120.119080 | Ferran Sayol                                                                                                                                                                         |
| 109 |     133.76526 |    140.544033 | Milton Tan                                                                                                                                                                           |
| 110 |      75.80017 |    663.806283 | Xavier Giroux-Bougard                                                                                                                                                                |
| 111 |     128.44936 |    451.768568 | Robert Hering                                                                                                                                                                        |
| 112 |     170.66530 |    295.914970 | Andy Wilson                                                                                                                                                                          |
| 113 |     189.05317 |    639.832105 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                                         |
| 114 |     900.37807 |    159.432402 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 115 |     237.21832 |    120.204234 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                                      |
| 116 |     958.32382 |    692.307790 | Nobu Tamura                                                                                                                                                                          |
| 117 |     796.83701 |    248.366594 | NA                                                                                                                                                                                   |
| 118 |     105.22509 |     60.389321 | Amanda Katzer                                                                                                                                                                        |
| 119 |     196.96635 |    665.349274 | Scott Hartman                                                                                                                                                                        |
| 120 |     622.00920 |    470.706788 | Dmitry Bogdanov                                                                                                                                                                      |
| 121 |     702.78833 |    211.288133 | Robert Gay                                                                                                                                                                           |
| 122 |     888.41473 |    426.093781 | Felix Vaux                                                                                                                                                                           |
| 123 |     144.26498 |    523.578582 | T. Michael Keesey                                                                                                                                                                    |
| 124 |     246.96186 |    788.966273 | Ieuan Jones                                                                                                                                                                          |
| 125 |     464.40947 |    735.522156 | Chris huh                                                                                                                                                                            |
| 126 |     349.87250 |    115.286693 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 127 |     319.70942 |    247.744094 | Scott Hartman                                                                                                                                                                        |
| 128 |     994.59038 |    244.248552 | Andy Wilson                                                                                                                                                                          |
| 129 |     508.32364 |    721.221180 | Courtney Rockenbach                                                                                                                                                                  |
| 130 |     518.57710 |    225.621948 | Matt Crook                                                                                                                                                                           |
| 131 |     318.33241 |    104.097176 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 132 |     474.33905 |    535.219215 | Cesar Julian                                                                                                                                                                         |
| 133 |     309.31914 |    609.614255 | Gareth Monger                                                                                                                                                                        |
| 134 |      51.10744 |    462.807812 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 135 |     610.04199 |    429.181865 | Pete Buchholz                                                                                                                                                                        |
| 136 |    1006.09775 |     56.211679 | Andy Wilson                                                                                                                                                                          |
| 137 |     133.86865 |    260.354713 | Rebecca Groom                                                                                                                                                                        |
| 138 |     487.74240 |    399.406823 | Matt Crook                                                                                                                                                                           |
| 139 |     778.52646 |    425.035552 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                         |
| 140 |     561.90358 |     83.853435 | Emily Willoughby                                                                                                                                                                     |
| 141 |     797.28633 |    744.223718 | Katie S. Collins                                                                                                                                                                     |
| 142 |     993.09426 |    672.778995 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 143 |     168.11487 |    730.760641 | Cathy                                                                                                                                                                                |
| 144 |     697.87654 |     52.838456 | Tracy A. Heath                                                                                                                                                                       |
| 145 |     133.06211 |    718.699496 | Scott Hartman                                                                                                                                                                        |
| 146 |     716.08040 |    539.013814 | Ferran Sayol                                                                                                                                                                         |
| 147 |     992.48983 |    720.052756 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                                             |
| 148 |     348.65292 |    590.048356 | Noah Schlottman, photo from Moorea Biocode                                                                                                                                           |
| 149 |     107.75357 |    157.950301 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
| 150 |      46.99267 |    709.587861 | Matthew E. Clapham                                                                                                                                                                   |
| 151 |     273.70403 |    687.624421 | Ignacio Contreras                                                                                                                                                                    |
| 152 |     413.88893 |    516.467925 | Andy Wilson                                                                                                                                                                          |
| 153 |     621.12145 |    172.671201 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                                |
| 154 |     564.55069 |    440.567038 | Geoff Shaw                                                                                                                                                                           |
| 155 |     579.86118 |    106.170948 | Maija Karala                                                                                                                                                                         |
| 156 |     333.74333 |    595.965590 | Lukasiniho                                                                                                                                                                           |
| 157 |     142.71199 |    307.390617 | Chris huh                                                                                                                                                                            |
| 158 |     679.78588 |    289.110630 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                                |
| 159 |     715.75799 |    646.145844 | Steven Traver                                                                                                                                                                        |
| 160 |     564.97675 |    223.666896 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 161 |      27.80959 |    662.564880 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 162 |     538.71392 |    414.692678 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 163 |     377.43131 |    464.212640 | Dean Schnabel                                                                                                                                                                        |
| 164 |     188.70573 |    786.362035 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                                        |
| 165 |     801.11075 |    222.651493 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 166 |     828.06159 |    128.680160 | Emily Willoughby                                                                                                                                                                     |
| 167 |     535.34385 |    474.202624 | Jagged Fang Designs                                                                                                                                                                  |
| 168 |     619.22819 |    744.493281 | Margot Michaud                                                                                                                                                                       |
| 169 |     480.27086 |    163.512147 | Michael Scroggie                                                                                                                                                                     |
| 170 |      17.27562 |    226.943058 | Margot Michaud                                                                                                                                                                       |
| 171 |     432.08601 |    673.055747 | T. Tischler                                                                                                                                                                          |
| 172 |     161.21939 |    157.581034 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 173 |     988.05563 |    308.047564 | Scott Hartman                                                                                                                                                                        |
| 174 |      22.19927 |     31.209734 | Scott Hartman                                                                                                                                                                        |
| 175 |     746.41151 |    736.264157 | Zimices                                                                                                                                                                              |
| 176 |     601.20939 |     24.196240 | Gareth Monger                                                                                                                                                                        |
| 177 |     752.05415 |    499.169567 | Matt Crook                                                                                                                                                                           |
| 178 |     929.44676 |    338.916082 | Erika Schumacher                                                                                                                                                                     |
| 179 |     571.39206 |    165.513726 | SecretJellyMan                                                                                                                                                                       |
| 180 |     526.74774 |     91.972218 | Emily Willoughby                                                                                                                                                                     |
| 181 |     996.00312 |    291.180808 | NA                                                                                                                                                                                   |
| 182 |     514.68951 |    552.570619 | Birgit Lang                                                                                                                                                                          |
| 183 |     478.74146 |    334.214654 | Scott Hartman                                                                                                                                                                        |
| 184 |     138.17518 |    619.738818 | Gareth Monger                                                                                                                                                                        |
| 185 |      82.97741 |     74.921496 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 186 |     119.61751 |    693.295705 | Jaime Headden                                                                                                                                                                        |
| 187 |     654.01483 |    166.666792 | Margot Michaud                                                                                                                                                                       |
| 188 |     643.15095 |    690.593042 | NA                                                                                                                                                                                   |
| 189 |     619.39211 |    622.332283 | Ludwik Gasiorowski                                                                                                                                                                   |
| 190 |     715.17366 |     72.935209 | Michelle Site                                                                                                                                                                        |
| 191 |      20.33968 |    167.345297 | Jagged Fang Designs                                                                                                                                                                  |
| 192 |     730.06298 |    282.711202 | Rebecca Groom                                                                                                                                                                        |
| 193 |     886.67866 |    487.913963 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 194 |     195.44387 |    578.246251 | Andy Wilson                                                                                                                                                                          |
| 195 |     250.48558 |    531.411250 | Margot Michaud                                                                                                                                                                       |
| 196 |     600.05339 |    263.608070 | Michael Scroggie                                                                                                                                                                     |
| 197 |     978.39110 |    214.514234 | NA                                                                                                                                                                                   |
| 198 |     842.15045 |    348.897021 | Birgit Lang                                                                                                                                                                          |
| 199 |     637.83773 |    292.186945 | Scott Hartman                                                                                                                                                                        |
| 200 |     630.17767 |    259.952632 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                                        |
| 201 |     966.47480 |    624.808439 | Chloé Schmidt                                                                                                                                                                        |
| 202 |      34.59207 |    118.265553 | Eric Moody                                                                                                                                                                           |
| 203 |     325.95363 |    365.429063 | Maija Karala                                                                                                                                                                         |
| 204 |     814.02318 |     22.125724 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 205 |     875.38470 |    156.122563 | Steven Traver                                                                                                                                                                        |
| 206 |     956.57126 |    577.806066 | David Orr                                                                                                                                                                            |
| 207 |     763.42199 |    698.359419 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                          |
| 208 |     767.52110 |    199.734627 | Matt Crook                                                                                                                                                                           |
| 209 |     492.25877 |    140.233265 | Cesar Julian                                                                                                                                                                         |
| 210 |     149.55212 |    375.980256 | Alexandre Vong                                                                                                                                                                       |
| 211 |      31.32513 |    690.722053 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 212 |     213.09755 |    693.679511 | Daniel Stadtmauer                                                                                                                                                                    |
| 213 |      49.51960 |    743.860253 | Ferran Sayol                                                                                                                                                                         |
| 214 |     617.45135 |     51.205668 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                                          |
| 215 |     833.17647 |    565.771404 | Lukasiniho                                                                                                                                                                           |
| 216 |     785.22955 |    390.464410 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 217 |     803.24183 |    349.874630 | Mathieu Pélissié                                                                                                                                                                     |
| 218 |     737.32702 |    220.558681 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 219 |     921.35819 |    557.292793 | Ignacio Contreras                                                                                                                                                                    |
| 220 |     672.91389 |    571.308364 | Gareth Monger                                                                                                                                                                        |
| 221 |      20.13717 |    200.623478 | NA                                                                                                                                                                                   |
| 222 |     427.61372 |     92.636271 | Matt Crook                                                                                                                                                                           |
| 223 |     969.12051 |     97.467245 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                                              |
| 224 |     213.78825 |    440.311668 | Margot Michaud                                                                                                                                                                       |
| 225 |      93.28806 |    705.503828 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 226 |    1006.00181 |    648.637176 | Birgit Lang                                                                                                                                                                          |
| 227 |     291.22959 |     25.687985 | Tasman Dixon                                                                                                                                                                         |
| 228 |     515.42501 |    358.907954 | Felix Vaux                                                                                                                                                                           |
| 229 |     596.48408 |    182.523800 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                                              |
| 230 |     826.07495 |    202.944220 | Markus A. Grohme                                                                                                                                                                     |
| 231 |     643.34249 |    636.195302 | Matt Martyniuk                                                                                                                                                                       |
| 232 |     374.11399 |    440.660320 | Andrew A. Farke                                                                                                                                                                      |
| 233 |     442.01714 |    410.560445 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 234 |     795.81736 |     91.684176 | Ferran Sayol                                                                                                                                                                         |
| 235 |     815.91191 |    433.726253 | Dean Schnabel                                                                                                                                                                        |
| 236 |      96.08117 |    329.337409 | Matt Crook                                                                                                                                                                           |
| 237 |     702.19006 |    686.027575 | Markus A. Grohme                                                                                                                                                                     |
| 238 |     441.93063 |    242.106304 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 239 |     736.50846 |    479.361938 | S.Martini                                                                                                                                                                            |
| 240 |     965.90519 |    265.893433 | Yan Wong                                                                                                                                                                             |
| 241 |     768.55844 |    122.534129 | Jiekun He                                                                                                                                                                            |
| 242 |     405.18723 |    567.937827 | Scott Hartman                                                                                                                                                                        |
| 243 |     142.70891 |    418.856235 | Andy Wilson                                                                                                                                                                          |
| 244 |     711.45993 |    752.482506 | Margot Michaud                                                                                                                                                                       |
| 245 |     679.92540 |     70.327050 | Darius Nau                                                                                                                                                                           |
| 246 |     329.35350 |    783.647846 | Scott Hartman                                                                                                                                                                        |
| 247 |     412.43306 |    289.791908 | M. A. Broussard                                                                                                                                                                      |
| 248 |     310.21701 |    684.047514 | NA                                                                                                                                                                                   |
| 249 |     568.73812 |    533.267453 | Chris huh                                                                                                                                                                            |
| 250 |     856.65054 |     10.659856 | NA                                                                                                                                                                                   |
| 251 |     417.47112 |    417.994622 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 252 |     248.11273 |     18.094752 | Alex Slavenko                                                                                                                                                                        |
| 253 |     945.59652 |     10.561694 | Jaime Headden                                                                                                                                                                        |
| 254 |     325.37269 |    703.335978 | Markus A. Grohme                                                                                                                                                                     |
| 255 |     469.47949 |     16.353815 | Matt Crook                                                                                                                                                                           |
| 256 |     292.38085 |    697.502126 | Chris huh                                                                                                                                                                            |
| 257 |     766.30134 |    229.711413 | Zimices                                                                                                                                                                              |
| 258 |     783.53044 |    102.792248 | Katie S. Collins                                                                                                                                                                     |
| 259 |      96.08344 |    684.579140 | Joanna Wolfe                                                                                                                                                                         |
| 260 |     572.89643 |     90.277749 | Ferran Sayol                                                                                                                                                                         |
| 261 |     287.61041 |    202.995382 | Lukasiniho                                                                                                                                                                           |
| 262 |      65.04983 |    111.603230 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                     |
| 263 |     645.72498 |    729.073671 | Margot Michaud                                                                                                                                                                       |
| 264 |     267.43561 |    307.335883 | Matt Crook                                                                                                                                                                           |
| 265 |     339.74443 |    616.566809 | Matt Crook                                                                                                                                                                           |
| 266 |     798.44280 |    126.744060 | Ignacio Contreras                                                                                                                                                                    |
| 267 |     637.70336 |    142.137215 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 268 |     600.29281 |    132.968482 | Margot Michaud                                                                                                                                                                       |
| 269 |     656.65885 |    371.286977 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                                     |
| 270 |     920.23672 |    683.084901 | NA                                                                                                                                                                                   |
| 271 |     388.54331 |    726.793603 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                   |
| 272 |     696.34038 |    674.239523 | Chloé Schmidt                                                                                                                                                                        |
| 273 |     135.82319 |    786.876927 | Scott Hartman                                                                                                                                                                        |
| 274 |     983.18632 |    558.623032 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                                    |
| 275 |     361.25168 |    237.274510 | Lukasiniho                                                                                                                                                                           |
| 276 |     664.65447 |    308.527010 | Jakovche                                                                                                                                                                             |
| 277 |      19.00469 |    340.125700 | NA                                                                                                                                                                                   |
| 278 |     746.96181 |     12.954999 | Scott Hartman                                                                                                                                                                        |
| 279 |     237.07871 |     72.904987 | Zimices                                                                                                                                                                              |
| 280 |     174.57528 |     11.534649 | Andrew A. Farke                                                                                                                                                                      |
| 281 |     273.89846 |    345.730970 | Gareth Monger                                                                                                                                                                        |
| 282 |     375.15647 |    488.133493 | Beth Reinke                                                                                                                                                                          |
| 283 |      85.86244 |    447.139940 | Matt Crook                                                                                                                                                                           |
| 284 |     162.10003 |     68.174964 | NA                                                                                                                                                                                   |
| 285 |     512.88053 |    622.029827 | Zimices                                                                                                                                                                              |
| 286 |     222.76532 |    736.881340 | Chris huh                                                                                                                                                                            |
| 287 |     474.30517 |    227.431322 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
| 288 |     135.05123 |    285.568654 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 289 |     588.75286 |    550.465240 | Gareth Monger                                                                                                                                                                        |
| 290 |     609.44115 |    118.193465 | Scott Hartman                                                                                                                                                                        |
| 291 |     961.76472 |    781.952558 | Pete Buchholz                                                                                                                                                                        |
| 292 |     874.89638 |    400.688470 | Zimices                                                                                                                                                                              |
| 293 |      24.74328 |    782.767664 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 294 |     795.11895 |      7.586775 | Margot Michaud                                                                                                                                                                       |
| 295 |     415.56481 |    362.414190 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 296 |      23.15877 |    401.127579 | Zimices                                                                                                                                                                              |
| 297 |     589.13310 |    471.788078 | Jagged Fang Designs                                                                                                                                                                  |
| 298 |     382.29579 |    377.206592 | T. Michael Keesey                                                                                                                                                                    |
| 299 |     159.67902 |    580.076209 | Zimices                                                                                                                                                                              |
| 300 |     191.84627 |    304.133938 | Andy Wilson                                                                                                                                                                          |
| 301 |     500.05564 |    250.589153 | Ferran Sayol                                                                                                                                                                         |
| 302 |     896.69472 |    619.308990 | Jagged Fang Designs                                                                                                                                                                  |
| 303 |     812.69232 |    594.037022 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 304 |     898.27216 |     14.266328 | Michelle Site                                                                                                                                                                        |
| 305 |     355.82668 |    701.546936 | Gareth Monger                                                                                                                                                                        |
| 306 |     472.60753 |    248.389197 | Smith609 and T. Michael Keesey                                                                                                                                                       |
| 307 |     267.91125 |    117.527882 | Tyler Greenfield                                                                                                                                                                     |
| 308 |     136.85317 |    114.883311 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 309 |     685.58946 |    701.527114 | Tasman Dixon                                                                                                                                                                         |
| 310 |     215.47155 |    627.025969 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
| 311 |     287.38939 |    751.350955 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 312 |     963.62135 |    670.498387 | Matt Crook                                                                                                                                                                           |
| 313 |      17.38803 |    148.536059 | Kamil S. Jaron                                                                                                                                                                       |
| 314 |     632.45544 |    496.035528 | Chris huh                                                                                                                                                                            |
| 315 |     121.68953 |    333.879011 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 316 |     180.59597 |    771.061783 | T. Michael Keesey                                                                                                                                                                    |
| 317 |     260.97735 |      8.436164 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                          |
| 318 |     890.10869 |    598.289585 | Andy Wilson                                                                                                                                                                          |
| 319 |     810.96964 |    136.719553 | Tasman Dixon                                                                                                                                                                         |
| 320 |     939.97847 |    298.378194 | NA                                                                                                                                                                                   |
| 321 |     298.41465 |    538.437523 | Kai R. Caspar                                                                                                                                                                        |
| 322 |     361.02682 |    173.552901 | Alexandre Vong                                                                                                                                                                       |
| 323 |     852.16689 |    743.135301 | Michael Scroggie                                                                                                                                                                     |
| 324 |     773.87866 |    365.525086 | T. Michael Keesey                                                                                                                                                                    |
| 325 |     688.63185 |    558.494528 | Matt Crook                                                                                                                                                                           |
| 326 |     483.59065 |     86.690438 | Scott Hartman                                                                                                                                                                        |
| 327 |     270.41577 |     94.460029 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 328 |     934.74518 |     96.973641 | Scott Hartman                                                                                                                                                                        |
| 329 |     103.69582 |    253.960072 | Chris huh                                                                                                                                                                            |
| 330 |     835.97797 |    164.082452 | Margot Michaud                                                                                                                                                                       |
| 331 |      66.66900 |    784.035094 | Shyamal                                                                                                                                                                              |
| 332 |     389.43979 |    769.239581 | Karla Martinez                                                                                                                                                                       |
| 333 |     706.33404 |    767.397977 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                                      |
| 334 |     351.93447 |    667.513100 | Michelle Site                                                                                                                                                                        |
| 335 |     752.65717 |    176.193603 | Erika Schumacher                                                                                                                                                                     |
| 336 |     730.45675 |     12.554595 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 337 |      79.89344 |    710.560633 | Shyamal                                                                                                                                                                              |
| 338 |     720.89872 |    202.743879 | Gareth Monger                                                                                                                                                                        |
| 339 |    1011.29826 |    613.269858 | NA                                                                                                                                                                                   |
| 340 |     215.12724 |    312.149541 | Matt Crook                                                                                                                                                                           |
| 341 |     359.72266 |    742.490331 | Ingo Braasch                                                                                                                                                                         |
| 342 |     654.32464 |    279.364761 | Tommaso Cancellario                                                                                                                                                                  |
| 343 |     414.24938 |    231.126987 | Steven Traver                                                                                                                                                                        |
| 344 |     432.25893 |    152.890020 | FunkMonk                                                                                                                                                                             |
| 345 |     414.95338 |    736.536119 | Mathieu Basille                                                                                                                                                                      |
| 346 |     972.28219 |    597.464684 | Margot Michaud                                                                                                                                                                       |
| 347 |     484.02359 |    645.673308 | Pete Buchholz                                                                                                                                                                        |
| 348 |     582.33363 |    750.895327 | Matt Hayes                                                                                                                                                                           |
| 349 |     532.18052 |    679.526017 | Collin Gross                                                                                                                                                                         |
| 350 |     858.63163 |     32.429616 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 351 |     113.90280 |      8.024629 | Jagged Fang Designs                                                                                                                                                                  |
| 352 |     651.73959 |    335.884827 | xgirouxb                                                                                                                                                                             |
| 353 |     668.74029 |    536.913663 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                                    |
| 354 |     533.50686 |    454.674571 | Ignacio Contreras                                                                                                                                                                    |
| 355 |    1008.25235 |    400.567677 | Fernando Campos De Domenico                                                                                                                                                          |
| 356 |     143.08673 |    763.005768 | Peter Coxhead                                                                                                                                                                        |
| 357 |     702.78276 |    784.247364 | Javier Luque & Sarah Gerken                                                                                                                                                          |
| 358 |     505.38194 |    180.355527 | Kamil S. Jaron                                                                                                                                                                       |
| 359 |     759.28778 |     25.891100 | Ieuan Jones                                                                                                                                                                          |
| 360 |     316.69767 |    275.638861 | Zimices                                                                                                                                                                              |
| 361 |     527.77944 |    115.404844 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
| 362 |     609.25215 |    689.570999 | Zimices                                                                                                                                                                              |
| 363 |     406.64811 |      4.546487 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 364 |     968.01558 |     51.607139 | Markus A. Grohme                                                                                                                                                                     |
| 365 |     489.03285 |    320.696601 | Jiekun He                                                                                                                                                                            |
| 366 |     919.59789 |    232.508335 | Maxime Dahirel                                                                                                                                                                       |
| 367 |     375.98237 |    108.030756 | Mattia Menchetti                                                                                                                                                                     |
| 368 |     731.35200 |     53.168156 | Steven Traver                                                                                                                                                                        |
| 369 |     104.22170 |    297.443129 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 370 |     186.44136 |    367.927357 | TaraTaylorDesign                                                                                                                                                                     |
| 371 |     375.59596 |    512.448526 | New York Zoological Society                                                                                                                                                          |
| 372 |     108.15745 |    793.706954 | RS                                                                                                                                                                                   |
| 373 |     877.11425 |    772.849964 | Gareth Monger                                                                                                                                                                        |
| 374 |      80.34569 |    230.820847 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                                  |
| 375 |     356.18139 |    536.100677 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                                       |
| 376 |     868.46131 |    370.939506 | Michael Scroggie                                                                                                                                                                     |
| 377 |     400.17467 |    795.745405 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 378 |      98.97392 |    672.105720 | Shyamal                                                                                                                                                                              |
| 379 |     635.47512 |    132.438371 | Chris huh                                                                                                                                                                            |
| 380 |     959.99723 |    227.494219 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 381 |     676.98455 |    753.726446 | FunkMonk                                                                                                                                                                             |
| 382 |     855.24351 |    715.661379 | Armin Reindl                                                                                                                                                                         |
| 383 |      95.25238 |    124.370856 | Markus A. Grohme                                                                                                                                                                     |
| 384 |     805.29154 |    572.297468 | Gareth Monger                                                                                                                                                                        |
| 385 |     927.21694 |    597.695710 | NA                                                                                                                                                                                   |
| 386 |     836.74214 |    353.913794 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 387 |    1007.46621 |    356.161919 | Beth Reinke                                                                                                                                                                          |
| 388 |     966.97857 |    301.474015 | Andy Wilson                                                                                                                                                                          |
| 389 |     514.98903 |    526.984631 | Jagged Fang Designs                                                                                                                                                                  |
| 390 |     672.11582 |    403.499991 | Tracy A. Heath                                                                                                                                                                       |
| 391 |     640.52604 |     69.692985 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 392 |     249.94455 |    448.369112 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 393 |     301.02538 |      3.877622 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 394 |     397.11302 |     95.777771 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 395 |     807.11529 |    389.330535 | Tasman Dixon                                                                                                                                                                         |
| 396 |     985.10887 |    576.076383 | Scott Hartman                                                                                                                                                                        |
| 397 |     102.76294 |     37.931934 | Julio Garza                                                                                                                                                                          |
| 398 |     670.03808 |    119.574636 | Iain Reid                                                                                                                                                                            |
| 399 |     481.30557 |    629.516856 | Sarah Werning                                                                                                                                                                        |
| 400 |     190.66508 |    741.372765 | Rene Martin                                                                                                                                                                          |
| 401 |      77.64697 |     54.286950 | Tauana J. Cunha                                                                                                                                                                      |
| 402 |     202.66177 |    676.358806 | Chris huh                                                                                                                                                                            |
| 403 |     527.04938 |    647.289823 | Iain Reid                                                                                                                                                                            |
| 404 |     189.24682 |    261.625421 | T. Michael Keesey                                                                                                                                                                    |
| 405 |     565.74308 |    117.588678 | Becky Barnes                                                                                                                                                                         |
| 406 |     938.84171 |    116.280701 | Chris huh                                                                                                                                                                            |
| 407 |     496.64546 |    541.352524 | T. Michael Keesey                                                                                                                                                                    |
| 408 |     347.34135 |    644.184652 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 409 |     619.06490 |    655.928283 | Markus A. Grohme                                                                                                                                                                     |
| 410 |     567.81128 |    245.477477 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                          |
| 411 |     292.88482 |    253.983390 | Ferran Sayol                                                                                                                                                                         |
| 412 |     834.58431 |    119.947806 | Markus A. Grohme                                                                                                                                                                     |
| 413 |      45.04134 |    761.088184 | CNZdenek                                                                                                                                                                             |
| 414 |     649.02502 |    750.313060 | Scott Hartman                                                                                                                                                                        |
| 415 |     756.85575 |     38.054570 | Jagged Fang Designs                                                                                                                                                                  |
| 416 |     243.18698 |    584.058481 | Scott Hartman                                                                                                                                                                        |
| 417 |     929.16641 |    666.416603 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 418 |     750.20205 |    269.019377 | Gareth Monger                                                                                                                                                                        |
| 419 |     195.19735 |    330.977225 | Scott Hartman                                                                                                                                                                        |
| 420 |     127.18327 |    179.852400 | Iain Reid                                                                                                                                                                            |
| 421 |     472.94929 |     55.588522 | T. Michael Keesey                                                                                                                                                                    |
| 422 |     539.92240 |    536.637718 | Nobu Tamura                                                                                                                                                                          |
| 423 |     201.18978 |    139.177543 | Margot Michaud                                                                                                                                                                       |
| 424 |     519.38594 |    736.038461 | Jagged Fang Designs                                                                                                                                                                  |
| 425 |     660.41753 |    541.063183 | Scott Hartman                                                                                                                                                                        |
| 426 |     625.44967 |    153.093926 | Iain Reid                                                                                                                                                                            |
| 427 |     970.41862 |    756.111472 | Christina N. Hodson                                                                                                                                                                  |
| 428 |     434.54150 |    543.094778 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 429 |     396.13866 |    673.694379 | Zimices                                                                                                                                                                              |
| 430 |      15.06862 |    362.425561 | Jack Mayer Wood                                                                                                                                                                      |
| 431 |     295.07509 |    103.763887 | Zimices                                                                                                                                                                              |
| 432 |    1003.27443 |     35.465595 | Maija Karala                                                                                                                                                                         |
| 433 |     462.80558 |    208.695759 | Zimices                                                                                                                                                                              |
| 434 |     825.48669 |    736.863563 | B. Duygu Özpolat                                                                                                                                                                     |
| 435 |     605.23223 |      7.920625 | Tracy A. Heath                                                                                                                                                                       |
| 436 |     674.54152 |    793.164331 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 437 |     746.12569 |    403.451382 | Margot Michaud                                                                                                                                                                       |
| 438 |     938.91385 |    703.695283 | Jagged Fang Designs                                                                                                                                                                  |
| 439 |     691.25842 |    660.344524 | Chris huh                                                                                                                                                                            |
| 440 |      15.25032 |    188.859777 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 441 |     714.05181 |    172.485049 | Markus A. Grohme                                                                                                                                                                     |
| 442 |     146.49735 |     14.265386 | Chloé Schmidt                                                                                                                                                                        |
| 443 |    1010.99768 |    560.198872 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                           |
| 444 |     471.77299 |    356.872351 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 445 |     865.57550 |     56.919291 | SauropodomorphMonarch                                                                                                                                                                |
| 446 |      49.04659 |    671.267193 | Steven Traver                                                                                                                                                                        |
| 447 |     678.69303 |     83.405900 | Jagged Fang Designs                                                                                                                                                                  |
| 448 |    1006.22616 |    514.317833 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 449 |     256.11157 |    107.904135 | Mo Hassan                                                                                                                                                                            |
| 450 |     440.03818 |     13.741520 | Melissa Ingala                                                                                                                                                                       |
| 451 |     639.28974 |     46.299462 | Scott Hartman                                                                                                                                                                        |
| 452 |     648.91865 |    389.249390 | Chris huh                                                                                                                                                                            |
| 453 |     935.45993 |     28.051113 | Markus A. Grohme                                                                                                                                                                     |
| 454 |     846.20062 |    247.244994 | Jaime Headden                                                                                                                                                                        |
| 455 |    1006.69672 |    380.711711 | Jagged Fang Designs                                                                                                                                                                  |
| 456 |     905.82684 |    311.968150 | Noah Schlottman, photo by Carol Cummings                                                                                                                                             |
| 457 |     916.35404 |    491.459602 | Ingo Braasch                                                                                                                                                                         |
| 458 |     407.21394 |    554.535816 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                                          |
| 459 |     487.82380 |    701.185266 | Rebecca Groom                                                                                                                                                                        |
| 460 |     629.71209 |     33.234868 | Jagged Fang Designs                                                                                                                                                                  |
| 461 |     291.84439 |     84.999438 | Chris huh                                                                                                                                                                            |
| 462 |     149.54991 |    794.216349 | Smokeybjb                                                                                                                                                                            |
| 463 |     206.67555 |    117.175896 | Jaime Headden                                                                                                                                                                        |
| 464 |     507.22770 |    290.192430 | Rachel Shoop                                                                                                                                                                         |
| 465 |     341.47075 |    377.033395 | Margot Michaud                                                                                                                                                                       |
| 466 |     322.14511 |    387.575771 | Sarah Werning                                                                                                                                                                        |
| 467 |    1014.04810 |    709.522974 | Maija Karala                                                                                                                                                                         |
| 468 |     891.68906 |    500.835198 | Christoph Schomburg                                                                                                                                                                  |
| 469 |    1000.93520 |    690.542805 | Harold N Eyster                                                                                                                                                                      |
| 470 |     360.34291 |    763.060172 | Zimices                                                                                                                                                                              |
| 471 |     776.69338 |    603.669288 | Zimices                                                                                                                                                                              |
| 472 |     670.93019 |    264.556176 | FunkMonk                                                                                                                                                                             |
| 473 |     143.76229 |    186.864127 | Chris huh                                                                                                                                                                            |
| 474 |     214.02683 |    485.598295 | NA                                                                                                                                                                                   |
| 475 |      97.15044 |    578.116284 | Zimices                                                                                                                                                                              |
| 476 |     577.26295 |    647.544380 | NA                                                                                                                                                                                   |
| 477 |     961.49182 |     66.852439 | Scott Hartman                                                                                                                                                                        |
| 478 |     232.89292 |     56.176363 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 479 |     124.63481 |    275.454543 | Smokeybjb                                                                                                                                                                            |
| 480 |     446.32292 |    277.255988 | Steven Traver                                                                                                                                                                        |
| 481 |     803.58046 |    795.040044 | M Kolmann                                                                                                                                                                            |
| 482 |     612.38310 |     99.415160 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 483 |     786.71762 |    679.678415 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 484 |     763.56208 |    793.167607 | Yan Wong                                                                                                                                                                             |
| 485 |     510.56528 |    743.845048 | Sarah Werning                                                                                                                                                                        |
| 486 |     511.94321 |    159.781687 | Tasman Dixon                                                                                                                                                                         |
| 487 |     649.01555 |      6.678070 | Markus A. Grohme                                                                                                                                                                     |
| 488 |     255.13652 |     37.082632 | Dmitry Bogdanov                                                                                                                                                                      |
| 489 |     644.91502 |    564.274340 | Matt Martyniuk                                                                                                                                                                       |
| 490 |     536.61039 |    265.919894 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 491 |     432.83086 |    791.515911 | Tasman Dixon                                                                                                                                                                         |
| 492 |     697.52205 |    491.097450 | Smokeybjb                                                                                                                                                                            |
| 493 |     109.58927 |    171.336030 | NA                                                                                                                                                                                   |
| 494 |     285.06679 |    707.444836 | Dean Schnabel                                                                                                                                                                        |
| 495 |     178.10849 |    321.264027 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                                            |
| 496 |     682.03400 |    109.200653 | Chris huh                                                                                                                                                                            |
| 497 |     374.10361 |    369.812106 | NA                                                                                                                                                                                   |
| 498 |     598.80881 |    165.053209 | Chris huh                                                                                                                                                                            |
| 499 |     449.28338 |    696.531027 | Margot Michaud                                                                                                                                                                       |
| 500 |      19.29820 |     44.108407 | M Hutchinson                                                                                                                                                                         |
| 501 |     552.33147 |    467.988377 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 502 |      72.77737 |      5.851405 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 503 |     651.79525 |    593.064385 | Zimices                                                                                                                                                                              |
| 504 |      33.13474 |    105.412688 | Zimices                                                                                                                                                                              |
| 505 |     962.73583 |    795.234690 | Gareth Monger                                                                                                                                                                        |
| 506 |     284.09885 |    268.952567 | Tasman Dixon                                                                                                                                                                         |
| 507 |     480.32681 |    370.304442 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 508 |     665.02587 |    358.636167 | Chris huh                                                                                                                                                                            |
| 509 |     861.27638 |    773.585292 | Jagged Fang Designs                                                                                                                                                                  |
| 510 |     222.64312 |    653.976549 | Scott Hartman                                                                                                                                                                        |
| 511 |     428.05628 |    109.007650 | Tasman Dixon                                                                                                                                                                         |
| 512 |     125.51254 |    164.897275 | Jagged Fang Designs                                                                                                                                                                  |
| 513 |     213.72846 |      8.472734 | Margot Michaud                                                                                                                                                                       |
| 514 |     269.71706 |    428.262089 | Matt Crook                                                                                                                                                                           |
| 515 |     641.02639 |    187.540399 | Martin R. Smith                                                                                                                                                                      |

    #> Your tweet has been posted!
