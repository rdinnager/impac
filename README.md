
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

Zimices, Chris huh, Martin Kevil, Michael Scroggie, Steven Traver,
Cristopher Silva, Alexandre Vong, Noah Schlottman, photo from Moorea
Biocode, Daniel Jaron, Matt Crook, Andrew A. Farke, Sharon
Wegner-Larsen, Ferran Sayol, Blair Perry, Collin Gross, Enoch Joseph
Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Beth Reinke, M Kolmann, Anthony Caravaggi, Juan Carlos Jerí,
Gareth Monger, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Jose Carlos Arenas-Monroy, Ryan Cupo, David Tana, Tasman Dixon, Dean
Schnabel, Margot Michaud, david maas / dave hone, Caleb M. Brown, Scott
Hartman, Tyler Greenfield, Nina Skinner, Emily Willoughby, Christopher
Chávez, Alex Slavenko, Roberto Díaz Sibaja, Jagged Fang Designs, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Ernst Haeckel (vectorized by
T. Michael Keesey), (unknown), T. Michael Keesey, Unknown (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Alan
Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Noah Schlottman, photo from Casey Dunn, New York
Zoological Society, Haplochromis (vectorized by T. Michael Keesey),
Almandine (vectorized by T. Michael Keesey), Michelle Site, Sarah
Werning, Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Neil Kelley, Birgit Lang, E. R. Waite & H. M. Hale
(vectorized by T. Michael Keesey), Charles R. Knight (vectorized by T.
Michael Keesey), Julien Louys, RS, Christine Axon, David Orr, Tyler
McCraney, Rebecca Groom, Mali’o Kodis, traced image from the National
Science Foundation’s Turbellarian Taxonomic Database, Felix Vaux,
Christoph Schomburg, Esme Ashe-Jepson, Chris A. Hamilton, Ville
Koistinen and T. Michael Keesey, Harold N Eyster, FunkMonk, Amanda
Katzer, Tony Ayling (vectorized by T. Michael Keesey), annaleeblysse,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Maxime Dahirel, Steven Coombs, L.
Shyamal, Dmitry Bogdanov, Tracy A. Heath, Julia B McHugh, Abraão Leite,
Katie S. Collins, Arthur Weasley (vectorized by T. Michael Keesey),
Peileppe, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Mali’o Kodis,
photograph by Hans Hillewaert, Mathilde Cordellier, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Gabriela Palomo-Munoz, Smokeybjb (vectorized by T.
Michael Keesey), Steven Haddock • Jellywatch.org, Jaime Headden, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Christopher
Laumer (vectorized by T. Michael Keesey), Sean McCann, Carlos
Cano-Barbacil, Kai R. Caspar, Brian Swartz (vectorized by T. Michael
Keesey), Didier Descouens (vectorized by T. Michael Keesey), T. Michael
Keesey (photo by Bc999 \[Black crow\]), Joseph J. W. Sertich, Mark A.
Loewen, Brad McFeeters (vectorized by T. Michael Keesey), Farelli
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Scott Hartman (modified by T. Michael Keesey), Chris Hay, Mark
Hofstetter (vectorized by T. Michael Keesey), Mattia Menchetti, Danny
Cicchetti (vectorized by T. Michael Keesey), Mali’o Kodis, image from
the Smithsonian Institution, Maija Karala, Fernando Carezzano,
FJDegrange, Theodore W. Pietsch (photography) and T. Michael Keesey
(vectorization), Matt Wilkins, terngirl, L.M. Davalos, Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), Nobu Tamura (vectorized by T. Michael Keesey),
Pranav Iyer (grey ideas), Pete Buchholz, Yusan Yang, T. Michael Keesey
(after C. De Muizon), Matt Celeskey, Mathew Wedel, Iain Reid, Rainer
Schoch, CNZdenek, T. Michael Keesey (from a mount by Allis Markham),
Kamil S. Jaron, T. Michael Keesey (after James & al.), Kailah Thorn &
Mark Hutchinson, B. Duygu Özpolat, C. Camilo Julián-Caballero, Michael
P. Taylor, Estelle Bourdon, Yan Wong from photo by Denes Emoke, Martin
R. Smith, G. M. Woodward, Vanessa Guerra, Shyamal, Cagri Cevrim, Jack
Mayer Wood, Madeleine Price Ball, Alexandra van der Geer, Cesar Julian,
Trond R. Oskars, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto,
and Ulf Jondelius (vectorized by T. Michael Keesey), Lisa M. “Pixxl”
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Smokeybjb, Sarah Alewijnse, SauropodomorphMonarch, Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Nobu Tamura, vectorized by Zimices, Lauren Anderson, Richard J. Harris,
Marie Russell, Geoff Shaw, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Joe Schneid (vectorized by T. Michael
Keesey), Servien (vectorized by T. Michael Keesey), Lip Kee Yap
(vectorized by T. Michael Keesey), Nobu Tamura (modified by T. Michael
Keesey), Lankester Edwin Ray (vectorized by T. Michael Keesey), Yan
Wong, Jay Matternes (vectorized by T. Michael Keesey), Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Lafage, Xavier Giroux-Bougard, Christian A. Masnaghetti, Darius
Nau, Michael Ströck (vectorized by T. Michael Keesey), Philip Chalmers
(vectorized by T. Michael Keesey), Robert Gay, DW Bapst (Modified from
photograph taken by Charles Mitchell), Matt Dempsey, Sam Droege
(photography) and T. Michael Keesey (vectorization), Maxwell Lefroy
(vectorized by T. Michael Keesey), Julio Garza, Tim Bertelink (modified
by T. Michael Keesey), Margret Flinsch, vectorized by Zimices, V.
Deepak, Armin Reindl, Lukasiniho, Joanna Wolfe

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    282.008445 |     83.049514 | Zimices                                                                                                                                                                         |
|   2 |    316.914432 |    674.433016 | Chris huh                                                                                                                                                                       |
|   3 |    618.125077 |    216.394254 | Chris huh                                                                                                                                                                       |
|   4 |    956.617524 |    156.032008 | Martin Kevil                                                                                                                                                                    |
|   5 |    215.865461 |    736.292493 | Michael Scroggie                                                                                                                                                                |
|   6 |    301.521042 |    427.540507 | Steven Traver                                                                                                                                                                   |
|   7 |    453.204849 |    764.560234 | Cristopher Silva                                                                                                                                                                |
|   8 |     46.103203 |    389.903036 | Alexandre Vong                                                                                                                                                                  |
|   9 |    670.629663 |    729.609852 | Noah Schlottman, photo from Moorea Biocode                                                                                                                                      |
|  10 |    625.134698 |    449.312870 | Daniel Jaron                                                                                                                                                                    |
|  11 |    623.890826 |    113.425414 | Zimices                                                                                                                                                                         |
|  12 |    675.199674 |    578.282390 | Zimices                                                                                                                                                                         |
|  13 |    928.206679 |    311.785806 | Matt Crook                                                                                                                                                                      |
|  14 |    613.508509 |    328.962463 | Matt Crook                                                                                                                                                                      |
|  15 |    133.859639 |    646.659701 | Andrew A. Farke                                                                                                                                                                 |
|  16 |    391.511296 |    581.919382 | Matt Crook                                                                                                                                                                      |
|  17 |    128.740049 |    560.824230 | Sharon Wegner-Larsen                                                                                                                                                            |
|  18 |    788.587405 |    349.003503 | Ferran Sayol                                                                                                                                                                    |
|  19 |    915.830935 |    481.714608 | Zimices                                                                                                                                                                         |
|  20 |    462.896593 |    257.721386 | Steven Traver                                                                                                                                                                   |
|  21 |    812.633373 |    103.405661 | Blair Perry                                                                                                                                                                     |
|  22 |    913.288904 |    626.501409 | NA                                                                                                                                                                              |
|  23 |    761.283498 |    232.727029 | Collin Gross                                                                                                                                                                    |
|  24 |    246.697739 |    259.801793 | Ferran Sayol                                                                                                                                                                    |
|  25 |    103.248107 |    214.142283 | Ferran Sayol                                                                                                                                                                    |
|  26 |    424.590109 |    328.679679 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey              |
|  27 |    507.125688 |    610.421013 | Beth Reinke                                                                                                                                                                     |
|  28 |    498.197402 |    682.805843 | M Kolmann                                                                                                                                                                       |
|  29 |    894.274052 |    552.448632 | Anthony Caravaggi                                                                                                                                                               |
|  30 |    447.209440 |    461.525934 | Steven Traver                                                                                                                                                                   |
|  31 |    339.931085 |    261.216370 | Juan Carlos Jerí                                                                                                                                                                |
|  32 |    243.742986 |    556.745703 | Gareth Monger                                                                                                                                                                   |
|  33 |    834.086891 |    666.563208 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
|  34 |    955.817853 |    775.206600 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
|  35 |    439.983617 |    102.599298 | Matt Crook                                                                                                                                                                      |
|  36 |     60.655876 |    735.117446 | Ryan Cupo                                                                                                                                                                       |
|  37 |    367.385631 |    534.857847 | David Tana                                                                                                                                                                      |
|  38 |    963.799089 |    693.566796 | Tasman Dixon                                                                                                                                                                    |
|  39 |    132.331749 |    173.187674 | Dean Schnabel                                                                                                                                                                   |
|  40 |    435.685447 |    362.955540 | NA                                                                                                                                                                              |
|  41 |    255.344814 |    186.559906 | Margot Michaud                                                                                                                                                                  |
|  42 |    513.148971 |     35.064784 | david maas / dave hone                                                                                                                                                          |
|  43 |    148.505792 |    382.353057 | Caleb M. Brown                                                                                                                                                                  |
|  44 |     69.706040 |     73.916580 | Scott Hartman                                                                                                                                                                   |
|  45 |    838.662050 |    238.263288 | Tyler Greenfield                                                                                                                                                                |
|  46 |    312.962323 |    764.183126 | Zimices                                                                                                                                                                         |
|  47 |    722.060876 |    500.711748 | Margot Michaud                                                                                                                                                                  |
|  48 |    662.908750 |     69.996427 | Nina Skinner                                                                                                                                                                    |
|  49 |    114.969221 |    491.767565 | Tasman Dixon                                                                                                                                                                    |
|  50 |    168.426209 |    333.975779 | Emily Willoughby                                                                                                                                                                |
|  51 |    126.065232 |     28.061660 | Christopher Chávez                                                                                                                                                              |
|  52 |    457.047291 |    716.246718 | Tasman Dixon                                                                                                                                                                    |
|  53 |    548.340779 |    532.244251 | Alex Slavenko                                                                                                                                                                   |
|  54 |    776.273172 |    756.326262 | Margot Michaud                                                                                                                                                                  |
|  55 |    590.154373 |    163.193429 | Roberto Díaz Sibaja                                                                                                                                                             |
|  56 |    957.949317 |    227.185559 | NA                                                                                                                                                                              |
|  57 |    410.864888 |    651.647028 | Andrew A. Farke                                                                                                                                                                 |
|  58 |    925.765233 |     72.468511 | NA                                                                                                                                                                              |
|  59 |    763.599155 |     20.462200 | Margot Michaud                                                                                                                                                                  |
|  60 |    731.159213 |    388.125488 | Jagged Fang Designs                                                                                                                                                             |
|  61 |    286.558861 |    599.166573 | Tasman Dixon                                                                                                                                                                    |
|  62 |    154.620541 |    432.761053 | Scott Hartman                                                                                                                                                                   |
|  63 |    624.300345 |    655.977041 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  64 |    581.013707 |    746.520083 | Ferran Sayol                                                                                                                                                                    |
|  65 |    580.279763 |    407.026675 | Zimices                                                                                                                                                                         |
|  66 |    343.168326 |    141.774668 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                 |
|  67 |    885.251104 |    731.534061 | (unknown)                                                                                                                                                                       |
|  68 |    656.351155 |     30.510861 | T. Michael Keesey                                                                                                                                                               |
|  69 |    867.687292 |    430.496922 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
|  70 |    470.633357 |    172.487122 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  71 |    422.002761 |    391.633716 | Margot Michaud                                                                                                                                                                  |
|  72 |    625.843628 |    778.617490 | NA                                                                                                                                                                              |
|  73 |    108.351367 |    731.268203 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
|  74 |    947.120225 |     23.985942 | Scott Hartman                                                                                                                                                                   |
|  75 |    229.683950 |    500.095816 | Tasman Dixon                                                                                                                                                                    |
|  76 |    788.782463 |    467.500491 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
|  77 |    483.815927 |    644.787324 | Gareth Monger                                                                                                                                                                   |
|  78 |    277.822046 |    343.184467 | Tasman Dixon                                                                                                                                                                    |
|  79 |    987.438516 |    444.623789 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                 |
|  80 |     67.380407 |    479.984402 | New York Zoological Society                                                                                                                                                     |
|  81 |    791.743678 |    714.239449 | Scott Hartman                                                                                                                                                                   |
|  82 |    949.613704 |     97.011591 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                  |
|  83 |    735.013527 |    620.283189 | Jagged Fang Designs                                                                                                                                                             |
|  84 |    712.102820 |    162.071252 | Almandine (vectorized by T. Michael Keesey)                                                                                                                                     |
|  85 |    521.588034 |    130.478080 | Michelle Site                                                                                                                                                                   |
|  86 |    745.955952 |    178.436081 | T. Michael Keesey                                                                                                                                                               |
|  87 |     79.433979 |    332.878117 | Tyler Greenfield                                                                                                                                                                |
|  88 |    151.599345 |    679.509038 | Jagged Fang Designs                                                                                                                                                             |
|  89 |    385.192658 |    161.519369 | Sarah Werning                                                                                                                                                                   |
|  90 |    731.250032 |    339.517993 | Zimices                                                                                                                                                                         |
|  91 |    315.356234 |    707.480496 | Jagged Fang Designs                                                                                                                                                             |
|  92 |    895.901841 |    287.416267 | Gareth Monger                                                                                                                                                                   |
|  93 |    542.642389 |    497.858609 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                      |
|  94 |    484.139750 |    143.449689 | Zimices                                                                                                                                                                         |
|  95 |    801.886847 |    282.382749 | Chris huh                                                                                                                                                                       |
|  96 |    961.342036 |    542.340974 | Neil Kelley                                                                                                                                                                     |
|  97 |    557.276055 |     65.950267 | Birgit Lang                                                                                                                                                                     |
|  98 |    494.867522 |    417.033960 | Chris huh                                                                                                                                                                       |
|  99 |    513.036066 |    351.305737 | Birgit Lang                                                                                                                                                                     |
| 100 |     49.883284 |    129.078521 | Tasman Dixon                                                                                                                                                                    |
| 101 |    980.103370 |     46.998535 | Nina Skinner                                                                                                                                                                    |
| 102 |    594.705211 |    255.764516 | Matt Crook                                                                                                                                                                      |
| 103 |    555.251257 |    458.118220 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                      |
| 104 |     32.536766 |    104.759716 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                             |
| 105 |    503.805325 |    580.332412 | Michelle Site                                                                                                                                                                   |
| 106 |     58.660410 |    654.512722 | Birgit Lang                                                                                                                                                                     |
| 107 |    488.660847 |    195.712295 | Julien Louys                                                                                                                                                                    |
| 108 |     42.842359 |    580.044880 | RS                                                                                                                                                                              |
| 109 |    769.996626 |     39.589125 | Tasman Dixon                                                                                                                                                                    |
| 110 |    749.964071 |    430.562353 | Christine Axon                                                                                                                                                                  |
| 111 |    687.915620 |    626.152575 | Andrew A. Farke                                                                                                                                                                 |
| 112 |    263.835726 |    645.910603 | Matt Crook                                                                                                                                                                      |
| 113 |    969.945492 |    619.809120 | NA                                                                                                                                                                              |
| 114 |    311.713254 |    502.236367 | T. Michael Keesey                                                                                                                                                               |
| 115 |    286.064134 |    533.394013 | Tasman Dixon                                                                                                                                                                    |
| 116 |    652.228668 |    374.579985 | David Orr                                                                                                                                                                       |
| 117 |    412.370763 |    196.378678 | Chris huh                                                                                                                                                                       |
| 118 |    848.420803 |    491.234215 | Tyler McCraney                                                                                                                                                                  |
| 119 |    212.541515 |    457.734194 | NA                                                                                                                                                                              |
| 120 |    626.204615 |    510.851027 | Ferran Sayol                                                                                                                                                                    |
| 121 |    190.507286 |    407.711179 | Rebecca Groom                                                                                                                                                                   |
| 122 |    871.100598 |    276.351483 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                               |
| 123 |    842.742307 |    607.745662 | Rebecca Groom                                                                                                                                                                   |
| 124 |    665.702461 |    391.731051 | Felix Vaux                                                                                                                                                                      |
| 125 |    111.292476 |    126.817250 | NA                                                                                                                                                                              |
| 126 |     37.280233 |    624.875183 | Caleb M. Brown                                                                                                                                                                  |
| 127 |    809.169740 |    597.597534 | Christoph Schomburg                                                                                                                                                             |
| 128 |    607.860386 |    299.935277 | Chris huh                                                                                                                                                                       |
| 129 |    213.404993 |    612.969835 | Margot Michaud                                                                                                                                                                  |
| 130 |    666.828072 |    251.636044 | Steven Traver                                                                                                                                                                   |
| 131 |    270.587792 |    155.542602 | Steven Traver                                                                                                                                                                   |
| 132 |    541.731388 |    771.876356 | Esme Ashe-Jepson                                                                                                                                                                |
| 133 |     39.857490 |    693.249428 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 134 |    714.027974 |    115.968355 | Margot Michaud                                                                                                                                                                  |
| 135 |    377.743684 |    695.054904 | Chris A. Hamilton                                                                                                                                                               |
| 136 |    736.788978 |     94.982996 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 137 |    397.155331 |    286.654352 | Jagged Fang Designs                                                                                                                                                             |
| 138 |    874.380207 |     92.001372 | Steven Traver                                                                                                                                                                   |
| 139 |    591.442257 |    693.588826 | Chris huh                                                                                                                                                                       |
| 140 |     40.634463 |    330.864994 | Michelle Site                                                                                                                                                                   |
| 141 |    203.580402 |    650.736688 | Zimices                                                                                                                                                                         |
| 142 |     59.931707 |    457.594800 | Michelle Site                                                                                                                                                                   |
| 143 |    794.045867 |    503.915615 | Matt Crook                                                                                                                                                                      |
| 144 |     85.408046 |    671.077818 | NA                                                                                                                                                                              |
| 145 |    417.599069 |    624.432398 | Chris huh                                                                                                                                                                       |
| 146 |    867.680365 |    420.174350 | Zimices                                                                                                                                                                         |
| 147 |    864.761226 |     20.411873 | Ville Koistinen and T. Michael Keesey                                                                                                                                           |
| 148 |    679.360246 |    189.933516 | Harold N Eyster                                                                                                                                                                 |
| 149 |    755.508689 |     58.705825 | FunkMonk                                                                                                                                                                        |
| 150 |     19.725499 |    720.108763 | Christoph Schomburg                                                                                                                                                             |
| 151 |    298.382398 |    315.878182 | Amanda Katzer                                                                                                                                                                   |
| 152 |    946.226152 |    748.875870 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 153 |    167.015888 |    456.037953 | Matt Crook                                                                                                                                                                      |
| 154 |    387.293441 |    786.212413 | Margot Michaud                                                                                                                                                                  |
| 155 |    879.179501 |    347.832415 | Alex Slavenko                                                                                                                                                                   |
| 156 |    727.724096 |    676.715552 | annaleeblysse                                                                                                                                                                   |
| 157 |    670.088058 |    169.142307 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 158 |    202.449898 |    222.423341 | Maxime Dahirel                                                                                                                                                                  |
| 159 |     31.165243 |    682.850013 | Almandine (vectorized by T. Michael Keesey)                                                                                                                                     |
| 160 |    533.456657 |    721.912084 | Ferran Sayol                                                                                                                                                                    |
| 161 |    603.508810 |    286.626518 | Steven Coombs                                                                                                                                                                   |
| 162 |    756.862043 |    268.149328 | Matt Crook                                                                                                                                                                      |
| 163 |    514.652875 |    441.505743 | L. Shyamal                                                                                                                                                                      |
| 164 |    186.068385 |    159.869726 | Zimices                                                                                                                                                                         |
| 165 |    339.645791 |    369.386081 | Dmitry Bogdanov                                                                                                                                                                 |
| 166 |    430.980544 |     28.423789 | Matt Crook                                                                                                                                                                      |
| 167 |    875.813851 |    712.401290 | Tracy A. Heath                                                                                                                                                                  |
| 168 |    759.536939 |    666.822722 | Julia B McHugh                                                                                                                                                                  |
| 169 |    853.355320 |     65.500880 | Chris huh                                                                                                                                                                       |
| 170 |    712.764378 |    654.102982 | Abraão Leite                                                                                                                                                                    |
| 171 |    623.506573 |    411.177394 | Zimices                                                                                                                                                                         |
| 172 |    365.811554 |     17.996689 | Katie S. Collins                                                                                                                                                                |
| 173 |    437.221898 |     48.223152 | Chris huh                                                                                                                                                                       |
| 174 |    599.768674 |    455.745701 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                |
| 175 |    388.892976 |    730.051616 | Matt Crook                                                                                                                                                                      |
| 176 |    845.958240 |    753.604111 | Peileppe                                                                                                                                                                        |
| 177 |    227.522918 |    383.709556 | Gareth Monger                                                                                                                                                                   |
| 178 |    667.418894 |      7.342335 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 179 |    712.693003 |    746.843245 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                     |
| 180 |    182.688912 |    138.622628 | Mathilde Cordellier                                                                                                                                                             |
| 181 |    198.734866 |     18.484186 | Steven Traver                                                                                                                                                                   |
| 182 |    218.940032 |    158.388894 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 183 |    756.163614 |    571.138592 | Margot Michaud                                                                                                                                                                  |
| 184 |    724.124621 |    277.019851 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 185 |    799.838677 |    316.648289 | T. Michael Keesey                                                                                                                                                               |
| 186 |    466.975593 |    326.115041 | Zimices                                                                                                                                                                         |
| 187 |    132.916314 |    724.128454 | NA                                                                                                                                                                              |
| 188 |    542.718897 |    194.902301 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 189 |    139.017007 |    176.457411 | Peileppe                                                                                                                                                                        |
| 190 |    589.117920 |     38.566033 | Steven Traver                                                                                                                                                                   |
| 191 |    809.080011 |    736.315700 | Margot Michaud                                                                                                                                                                  |
| 192 |    236.636860 |     17.297305 | Matt Crook                                                                                                                                                                      |
| 193 |    870.338085 |    192.558645 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 194 |    116.552727 |    460.026042 | Margot Michaud                                                                                                                                                                  |
| 195 |    864.453550 |    156.726803 | Jaime Headden                                                                                                                                                                   |
| 196 |    579.353598 |    491.173907 | Gareth Monger                                                                                                                                                                   |
| 197 |    508.739973 |     74.501511 | Zimices                                                                                                                                                                         |
| 198 |    464.203302 |     15.065301 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                                |
| 199 |     33.589315 |     13.118232 | Margot Michaud                                                                                                                                                                  |
| 200 |   1004.829332 |    357.617140 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                            |
| 201 |     35.885979 |    288.158245 | Christoph Schomburg                                                                                                                                                             |
| 202 |    292.663939 |    517.414270 | Sean McCann                                                                                                                                                                     |
| 203 |    628.992762 |    639.260047 | Carlos Cano-Barbacil                                                                                                                                                            |
| 204 |     60.074173 |    539.023412 | Roberto Díaz Sibaja                                                                                                                                                             |
| 205 |    640.500343 |    273.492213 | NA                                                                                                                                                                              |
| 206 |    679.062479 |    349.176963 | Steven Traver                                                                                                                                                                   |
| 207 |    424.407240 |    722.284301 | Jagged Fang Designs                                                                                                                                                             |
| 208 |    145.239495 |    740.422633 | Michael Scroggie                                                                                                                                                                |
| 209 |    859.172468 |    304.744359 | Kai R. Caspar                                                                                                                                                                   |
| 210 |    298.626087 |    249.783112 | FunkMonk                                                                                                                                                                        |
| 211 |    375.223489 |    490.194475 | Ferran Sayol                                                                                                                                                                    |
| 212 |    937.284886 |    411.849135 | NA                                                                                                                                                                              |
| 213 |    390.268065 |    578.179087 | Matt Crook                                                                                                                                                                      |
| 214 |    975.553465 |    522.689157 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 215 |    785.378457 |    526.731011 | Sharon Wegner-Larsen                                                                                                                                                            |
| 216 |     74.111529 |     40.985836 | Gareth Monger                                                                                                                                                                   |
| 217 |    100.882201 |    335.787478 | Gareth Monger                                                                                                                                                                   |
| 218 |    236.799075 |    658.779458 | Steven Traver                                                                                                                                                                   |
| 219 |    749.614011 |    398.538999 | Christoph Schomburg                                                                                                                                                             |
| 220 |    887.047371 |    753.677657 | Matt Crook                                                                                                                                                                      |
| 221 |    688.354878 |    656.227531 | Harold N Eyster                                                                                                                                                                 |
| 222 |    291.832697 |    202.083219 | Gareth Monger                                                                                                                                                                   |
| 223 |    372.369050 |    561.941167 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                  |
| 224 |    553.546004 |    333.459283 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 225 |    568.190811 |    189.973340 | Ferran Sayol                                                                                                                                                                    |
| 226 |    719.773079 |    305.740058 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 227 |    153.764971 |     78.479775 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                               |
| 228 |    121.623034 |    291.909272 | Dean Schnabel                                                                                                                                                                   |
| 229 |    219.691796 |    584.345901 | Steven Traver                                                                                                                                                                   |
| 230 |    603.722404 |    712.996785 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                            |
| 231 |   1001.577649 |    510.119219 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 232 |    878.566910 |    123.786469 | Margot Michaud                                                                                                                                                                  |
| 233 |    925.196298 |     47.997663 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 234 |    278.190992 |    721.020278 | Zimices                                                                                                                                                                         |
| 235 |    144.761502 |     40.350520 | David Orr                                                                                                                                                                       |
| 236 |    826.391745 |    298.858514 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 237 |    870.573811 |    788.383942 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 238 |    993.144008 |    247.994271 | Chris Hay                                                                                                                                                                       |
| 239 |    281.586871 |    279.613646 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                               |
| 240 |   1000.460948 |    658.503956 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 241 |    535.192242 |     81.326381 | Ferran Sayol                                                                                                                                                                    |
| 242 |    546.638437 |    122.931963 | Mattia Menchetti                                                                                                                                                                |
| 243 |   1004.999045 |    556.929506 | Tracy A. Heath                                                                                                                                                                  |
| 244 |   1005.387662 |    612.434072 | Scott Hartman                                                                                                                                                                   |
| 245 |    980.751147 |    647.992978 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                               |
| 246 |    856.347577 |    383.908611 | Margot Michaud                                                                                                                                                                  |
| 247 |    684.870565 |    325.475435 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                            |
| 248 |    399.536519 |     47.342398 | Maija Karala                                                                                                                                                                    |
| 249 |     96.145099 |    450.164567 | Fernando Carezzano                                                                                                                                                              |
| 250 |    567.543986 |    209.232101 | Jaime Headden                                                                                                                                                                   |
| 251 |    158.160936 |    616.492684 | Emily Willoughby                                                                                                                                                                |
| 252 |    636.973582 |    687.319468 | FJDegrange                                                                                                                                                                      |
| 253 |     56.928831 |    609.318552 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 254 |    393.880823 |    614.643272 | Ferran Sayol                                                                                                                                                                    |
| 255 |    256.047101 |    742.134072 | Tyler Greenfield                                                                                                                                                                |
| 256 |    660.225100 |    195.616265 | T. Michael Keesey                                                                                                                                                               |
| 257 |    806.275840 |    174.892369 | Matt Wilkins                                                                                                                                                                    |
| 258 |    212.822556 |    303.865566 | T. Michael Keesey                                                                                                                                                               |
| 259 |    242.682803 |    623.152393 | terngirl                                                                                                                                                                        |
| 260 |    205.484019 |    541.706421 | L.M. Davalos                                                                                                                                                                    |
| 261 |    361.189726 |    361.571745 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                              |
| 262 |    166.293551 |     49.311199 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 263 |    788.377331 |    418.741146 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 264 |    634.970210 |    723.532921 | Margot Michaud                                                                                                                                                                  |
| 265 |     20.622161 |    424.416087 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 266 |    894.369630 |     34.262124 | Sarah Werning                                                                                                                                                                   |
| 267 |    391.527766 |     74.880813 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 268 |    952.397973 |     60.378205 | Maija Karala                                                                                                                                                                    |
| 269 |    480.006832 |    563.145319 | Pete Buchholz                                                                                                                                                                   |
| 270 |     16.470010 |    549.016113 | Ferran Sayol                                                                                                                                                                    |
| 271 |    641.192037 |    734.898760 | Yusan Yang                                                                                                                                                                      |
| 272 |   1010.020600 |    315.180209 | Matt Crook                                                                                                                                                                      |
| 273 |    313.171983 |    329.070061 | Gareth Monger                                                                                                                                                                   |
| 274 |    108.092660 |    525.211851 | Jaime Headden                                                                                                                                                                   |
| 275 |    616.785430 |    266.422771 | T. Michael Keesey (after C. De Muizon)                                                                                                                                          |
| 276 |    164.960624 |    774.021666 | T. Michael Keesey                                                                                                                                                               |
| 277 |    406.117635 |     18.352505 | Katie S. Collins                                                                                                                                                                |
| 278 |   1007.912405 |    342.052663 | Matt Celeskey                                                                                                                                                                   |
| 279 |    147.856096 |    703.456241 | Rebecca Groom                                                                                                                                                                   |
| 280 |    180.648919 |    239.210809 | Mathew Wedel                                                                                                                                                                    |
| 281 |    422.390981 |    503.150589 | Birgit Lang                                                                                                                                                                     |
| 282 |    834.979084 |    720.972149 | Felix Vaux                                                                                                                                                                      |
| 283 |    572.541559 |    511.163879 | Iain Reid                                                                                                                                                                       |
| 284 |    128.712951 |    771.728738 | Scott Hartman                                                                                                                                                                   |
| 285 |    753.558956 |    136.622304 | NA                                                                                                                                                                              |
| 286 |    792.889667 |     52.964960 | Rainer Schoch                                                                                                                                                                   |
| 287 |    542.198527 |    664.411024 | Margot Michaud                                                                                                                                                                  |
| 288 |    373.621087 |    435.516074 | Gareth Monger                                                                                                                                                                   |
| 289 |    106.632344 |    175.482900 | Ferran Sayol                                                                                                                                                                    |
| 290 |    454.693824 |    692.407008 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 291 |    893.383182 |    330.577415 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 292 |    656.664489 |    508.082349 | Carlos Cano-Barbacil                                                                                                                                                            |
| 293 |    515.296324 |    525.451875 | Andrew A. Farke                                                                                                                                                                 |
| 294 |    667.433032 |    757.703614 | Steven Traver                                                                                                                                                                   |
| 295 |    865.306135 |    635.063966 | Scott Hartman                                                                                                                                                                   |
| 296 |    360.581875 |    587.714556 | Margot Michaud                                                                                                                                                                  |
| 297 |    477.132372 |    378.077186 | CNZdenek                                                                                                                                                                        |
| 298 |    999.665384 |    733.627005 | Tyler Greenfield                                                                                                                                                                |
| 299 |    750.702380 |    326.138289 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 300 |    299.031720 |    643.294584 | Alex Slavenko                                                                                                                                                                   |
| 301 |    790.129267 |     30.626730 | Scott Hartman                                                                                                                                                                   |
| 302 |    334.053317 |    702.213799 | Dmitry Bogdanov                                                                                                                                                                 |
| 303 |    825.173948 |     39.047339 | Dean Schnabel                                                                                                                                                                   |
| 304 |    655.603320 |    647.286384 | Margot Michaud                                                                                                                                                                  |
| 305 |    552.811756 |    566.480256 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                               |
| 306 |    305.004615 |    692.480407 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 307 |     22.260745 |    247.987700 | Christine Axon                                                                                                                                                                  |
| 308 |    574.541480 |    793.662294 | NA                                                                                                                                                                              |
| 309 |    873.179249 |    250.260374 | Kamil S. Jaron                                                                                                                                                                  |
| 310 |    142.327530 |    116.886352 | Chris huh                                                                                                                                                                       |
| 311 |     11.070824 |    495.123428 | NA                                                                                                                                                                              |
| 312 |    723.514888 |     56.513689 | Ferran Sayol                                                                                                                                                                    |
| 313 |    866.467576 |    327.633364 | Matt Crook                                                                                                                                                                      |
| 314 |    525.908274 |    202.454018 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 315 |    319.623897 |    564.116043 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 316 |    273.492125 |    145.913533 | FunkMonk                                                                                                                                                                        |
| 317 |     36.169299 |    309.847946 | Kailah Thorn & Mark Hutchinson                                                                                                                                                  |
| 318 |    703.169517 |    188.320074 | B. Duygu Özpolat                                                                                                                                                                |
| 319 |    924.001713 |    204.399988 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 320 |   1008.091922 |    636.118255 | Michael P. Taylor                                                                                                                                                               |
| 321 |    441.726338 |    527.606264 | Roberto Díaz Sibaja                                                                                                                                                             |
| 322 |    749.256650 |    651.192737 | Alex Slavenko                                                                                                                                                                   |
| 323 |    436.625991 |    613.519421 | Estelle Bourdon                                                                                                                                                                 |
| 324 |    379.290629 |    261.655660 | Tyler McCraney                                                                                                                                                                  |
| 325 |    310.370927 |     10.151335 | Zimices                                                                                                                                                                         |
| 326 |    451.738620 |    666.974921 | Yan Wong from photo by Denes Emoke                                                                                                                                              |
| 327 |    613.052401 |    309.576269 | FunkMonk                                                                                                                                                                        |
| 328 |     83.825345 |    615.328465 | Chris huh                                                                                                                                                                       |
| 329 |    150.766981 |    297.387744 | Zimices                                                                                                                                                                         |
| 330 |    768.528501 |    597.480597 | Steven Traver                                                                                                                                                                   |
| 331 |    399.476520 |    559.152055 | Beth Reinke                                                                                                                                                                     |
| 332 |     31.230430 |    779.926044 | Martin R. Smith                                                                                                                                                                 |
| 333 |    887.376874 |    774.133434 | G. M. Woodward                                                                                                                                                                  |
| 334 |    754.114418 |    358.412339 | Rebecca Groom                                                                                                                                                                   |
| 335 |    666.564845 |    603.335943 | Matt Crook                                                                                                                                                                      |
| 336 |    310.264331 |    488.985387 | Jagged Fang Designs                                                                                                                                                             |
| 337 |    109.675584 |    399.757048 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 338 |    265.471496 |    611.968955 | Vanessa Guerra                                                                                                                                                                  |
| 339 |    371.186148 |    710.614046 | Margot Michaud                                                                                                                                                                  |
| 340 |    933.886740 |    247.877660 | Zimices                                                                                                                                                                         |
| 341 |    735.781040 |    448.281144 | Scott Hartman                                                                                                                                                                   |
| 342 |    797.501295 |    481.062967 | Jaime Headden                                                                                                                                                                   |
| 343 |    742.522657 |     89.524067 | Margot Michaud                                                                                                                                                                  |
| 344 |    428.571287 |    329.548652 | Roberto Díaz Sibaja                                                                                                                                                             |
| 345 |    166.614449 |    688.206661 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 346 |    844.842735 |     12.492570 | Margot Michaud                                                                                                                                                                  |
| 347 |    562.118296 |    245.076885 | T. Michael Keesey                                                                                                                                                               |
| 348 |    404.080544 |    683.034487 | Gareth Monger                                                                                                                                                                   |
| 349 |    988.780206 |    206.941209 | Shyamal                                                                                                                                                                         |
| 350 |    615.008183 |    795.085010 | Scott Hartman                                                                                                                                                                   |
| 351 |    885.056428 |    511.208264 | Abraão Leite                                                                                                                                                                    |
| 352 |    282.093775 |    571.895158 | NA                                                                                                                                                                              |
| 353 |    177.338265 |    119.691882 | Scott Hartman                                                                                                                                                                   |
| 354 |    308.074312 |    220.803795 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 355 |    597.047347 |    591.255084 | Cagri Cevrim                                                                                                                                                                    |
| 356 |    128.274811 |    795.354375 | Chris huh                                                                                                                                                                       |
| 357 |    515.553225 |    719.350876 | Zimices                                                                                                                                                                         |
| 358 |    732.690357 |    523.842344 | Jack Mayer Wood                                                                                                                                                                 |
| 359 |    188.445164 |    452.408587 | T. Michael Keesey                                                                                                                                                               |
| 360 |   1007.185461 |    398.007596 | T. Michael Keesey                                                                                                                                                               |
| 361 |    647.774711 |    245.300407 | Margot Michaud                                                                                                                                                                  |
| 362 |    123.704012 |    359.882800 | Carlos Cano-Barbacil                                                                                                                                                            |
| 363 |    751.067185 |    521.938664 | David Orr                                                                                                                                                                       |
| 364 |     24.427496 |    734.178613 | Rebecca Groom                                                                                                                                                                   |
| 365 |    127.207514 |    347.336388 | Margot Michaud                                                                                                                                                                  |
| 366 |    208.760932 |    664.292364 | Scott Hartman                                                                                                                                                                   |
| 367 |    742.084485 |    788.536052 | Margot Michaud                                                                                                                                                                  |
| 368 |     78.290196 |    469.354876 | Steven Traver                                                                                                                                                                   |
| 369 |     21.466710 |    638.744475 | Chris huh                                                                                                                                                                       |
| 370 |    582.871010 |    444.312637 | Madeleine Price Ball                                                                                                                                                            |
| 371 |    262.442810 |    584.228314 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 372 |    504.984230 |    503.062827 | Harold N Eyster                                                                                                                                                                 |
| 373 |    378.375446 |    475.061038 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                             |
| 374 |    130.925060 |     90.263228 | Zimices                                                                                                                                                                         |
| 375 |    994.018100 |    377.072780 | Alexandra van der Geer                                                                                                                                                          |
| 376 |    336.920261 |    499.616648 | Chris huh                                                                                                                                                                       |
| 377 |    451.961562 |    194.002072 | Matt Crook                                                                                                                                                                      |
| 378 |    302.235927 |    307.742945 | Jagged Fang Designs                                                                                                                                                             |
| 379 |    688.676408 |    250.820775 | Kai R. Caspar                                                                                                                                                                   |
| 380 |    339.682805 |    719.746718 | Harold N Eyster                                                                                                                                                                 |
| 381 |    335.531420 |    608.025549 | NA                                                                                                                                                                              |
| 382 |    674.854237 |    299.027199 | Margot Michaud                                                                                                                                                                  |
| 383 |    538.895096 |    321.747444 | Cesar Julian                                                                                                                                                                    |
| 384 |    852.566252 |    139.049300 | Trond R. Oskars                                                                                                                                                                 |
| 385 |    579.064578 |    500.549802 | Margot Michaud                                                                                                                                                                  |
| 386 |    795.590196 |    615.355831 | Ferran Sayol                                                                                                                                                                    |
| 387 |     58.635964 |    784.312529 | Margot Michaud                                                                                                                                                                  |
| 388 |    660.384201 |    266.788217 | Scott Hartman                                                                                                                                                                   |
| 389 |    279.418724 |     13.303481 | Roberto Díaz Sibaja                                                                                                                                                             |
| 390 |    350.693013 |    331.024731 | Margot Michaud                                                                                                                                                                  |
| 391 |   1008.868477 |    531.380399 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                        |
| 392 |     50.422389 |    477.545496 | Steven Traver                                                                                                                                                                   |
| 393 |      9.407637 |    524.068782 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                 |
| 394 |    929.157771 |    783.594523 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 395 |     31.179349 |    596.078440 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 396 |    609.903130 |    276.162155 | Smokeybjb                                                                                                                                                                       |
| 397 |    169.580303 |    730.006359 | Gareth Monger                                                                                                                                                                   |
| 398 |     42.292689 |     32.256511 | Gareth Monger                                                                                                                                                                   |
| 399 |    494.108371 |      5.817931 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 400 |    538.065246 |    170.235218 | T. Michael Keesey                                                                                                                                                               |
| 401 |    405.321047 |    273.534928 | Steven Traver                                                                                                                                                                   |
| 402 |    182.815805 |    301.486303 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 403 |    588.908161 |      6.345930 | NA                                                                                                                                                                              |
| 404 |    783.133656 |    435.244360 | Zimices                                                                                                                                                                         |
| 405 |    937.602474 |    600.269598 | Sarah Alewijnse                                                                                                                                                                 |
| 406 |     74.481041 |    137.220745 | Zimices                                                                                                                                                                         |
| 407 |    887.335687 |    197.981060 | Gareth Monger                                                                                                                                                                   |
| 408 |    282.159414 |    660.755136 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 409 |    998.996743 |    650.979296 | Jagged Fang Designs                                                                                                                                                             |
| 410 |    387.866244 |    127.945664 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 411 |    557.295998 |    609.655788 | SauropodomorphMonarch                                                                                                                                                           |
| 412 |    799.541096 |    448.123376 | Scott Hartman                                                                                                                                                                   |
| 413 |    994.668639 |     19.960445 | Margot Michaud                                                                                                                                                                  |
| 414 |    694.545582 |    778.512084 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
| 415 |    850.333829 |    355.842960 | M Kolmann                                                                                                                                                                       |
| 416 |     64.119455 |    361.125270 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                                     |
| 417 |    898.561419 |    322.061281 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 418 |    550.970480 |    633.712215 | Lauren Anderson                                                                                                                                                                 |
| 419 |    753.628760 |    415.417990 | Steven Traver                                                                                                                                                                   |
| 420 |    328.214309 |    191.707320 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 421 |    181.773052 |    565.986253 | Jagged Fang Designs                                                                                                                                                             |
| 422 |    851.607062 |    114.177038 | Chris huh                                                                                                                                                                       |
| 423 |     88.877037 |    499.155701 | Margot Michaud                                                                                                                                                                  |
| 424 |    407.896057 |    695.027554 | NA                                                                                                                                                                              |
| 425 |    293.382401 |    167.248704 | David Orr                                                                                                                                                                       |
| 426 |    766.654456 |    682.512601 | Richard J. Harris                                                                                                                                                               |
| 427 |    177.700266 |    101.355008 | Marie Russell                                                                                                                                                                   |
| 428 |    844.401658 |    474.507593 | Chris huh                                                                                                                                                                       |
| 429 |    561.601730 |    705.586374 | Tasman Dixon                                                                                                                                                                    |
| 430 |    459.697051 |    509.216075 | Geoff Shaw                                                                                                                                                                      |
| 431 |    213.530960 |    639.429181 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                          |
| 432 |    616.971580 |    610.735106 | Roberto Díaz Sibaja                                                                                                                                                             |
| 433 |    704.827372 |    360.440914 | Scott Hartman                                                                                                                                                                   |
| 434 |    182.577365 |    653.202122 | Gareth Monger                                                                                                                                                                   |
| 435 |    477.867732 |    619.342307 | Andrew A. Farke                                                                                                                                                                 |
| 436 |   1010.430210 |    438.788605 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                   |
| 437 |    584.432440 |     73.225520 | Chris huh                                                                                                                                                                       |
| 438 |    128.849357 |    782.840917 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 439 |    397.544311 |    149.654681 | Roberto Díaz Sibaja                                                                                                                                                             |
| 440 |    205.509646 |     31.363743 | Servien (vectorized by T. Michael Keesey)                                                                                                                                       |
| 441 |    830.914297 |    445.817204 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                                   |
| 442 |    695.981416 |    280.135868 | Zimices                                                                                                                                                                         |
| 443 |    534.687990 |    562.439309 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 444 |    647.729794 |    145.155815 | Scott Hartman                                                                                                                                                                   |
| 445 |    958.592753 |    584.420391 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 446 |    132.639452 |    192.729032 | Ferran Sayol                                                                                                                                                                    |
| 447 |    909.307606 |    667.450301 | Tasman Dixon                                                                                                                                                                    |
| 448 |    588.946408 |    348.221913 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                           |
| 449 |   1005.701099 |    748.451490 | Yan Wong                                                                                                                                                                        |
| 450 |    499.275210 |    397.706685 | NA                                                                                                                                                                              |
| 451 |    622.404376 |    702.472738 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                 |
| 452 |    365.709068 |    115.692568 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 453 |    422.793843 |    710.505700 | Lafage                                                                                                                                                                          |
| 454 |    456.589170 |    416.117884 | Kamil S. Jaron                                                                                                                                                                  |
| 455 |    137.099506 |    753.911433 | Felix Vaux                                                                                                                                                                      |
| 456 |    384.176613 |    404.649959 | Sarah Werning                                                                                                                                                                   |
| 457 |    124.578764 |      6.256428 | NA                                                                                                                                                                              |
| 458 |    416.829888 |    185.952362 | Xavier Giroux-Bougard                                                                                                                                                           |
| 459 |     24.937944 |     81.522566 | Christian A. Masnaghetti                                                                                                                                                        |
| 460 |    476.203670 |     64.082225 | Jagged Fang Designs                                                                                                                                                             |
| 461 |    931.341144 |    587.244186 | Chris huh                                                                                                                                                                       |
| 462 |    272.046175 |    785.362844 | Matt Crook                                                                                                                                                                      |
| 463 |     65.299706 |    700.024563 | T. Michael Keesey                                                                                                                                                               |
| 464 |    571.971209 |    676.433471 | NA                                                                                                                                                                              |
| 465 |    494.766454 |    553.484495 | Darius Nau                                                                                                                                                                      |
| 466 |    764.496964 |    167.773629 | Maija Karala                                                                                                                                                                    |
| 467 |    245.334002 |    149.593311 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                                |
| 468 |     76.923225 |     28.135616 | Scott Hartman                                                                                                                                                                   |
| 469 |    948.436741 |    740.232394 | NA                                                                                                                                                                              |
| 470 |    858.320982 |    171.208034 | Jagged Fang Designs                                                                                                                                                             |
| 471 |    893.992407 |    707.414191 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                               |
| 472 |     78.594274 |    457.546270 | T. Michael Keesey                                                                                                                                                               |
| 473 |    674.729696 |    518.256852 | Robert Gay                                                                                                                                                                      |
| 474 |   1000.366022 |    289.902729 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                   |
| 475 |   1008.261454 |    625.329186 | NA                                                                                                                                                                              |
| 476 |    959.526335 |    206.650119 | Matt Dempsey                                                                                                                                                                    |
| 477 |    611.261723 |    195.619116 | Jagged Fang Designs                                                                                                                                                             |
| 478 |    854.712476 |    323.312740 | Smokeybjb                                                                                                                                                                       |
| 479 |    853.638511 |    404.194020 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 480 |    419.678663 |    418.542442 | Jaime Headden                                                                                                                                                                   |
| 481 |    184.786512 |     49.861091 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 482 |    736.962498 |    714.350625 | Cesar Julian                                                                                                                                                                    |
| 483 |    714.908671 |    459.287692 | Julio Garza                                                                                                                                                                     |
| 484 |    342.979761 |    690.610848 | Jack Mayer Wood                                                                                                                                                                 |
| 485 |    171.062943 |    436.616271 | Steven Traver                                                                                                                                                                   |
| 486 |    708.014478 |    713.032104 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 487 |    482.012611 |    335.590456 | Jagged Fang Designs                                                                                                                                                             |
| 488 |     22.779354 |    231.160228 | B. Duygu Özpolat                                                                                                                                                                |
| 489 |    156.120055 |    719.547213 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                   |
| 490 |    442.401391 |    711.095680 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 491 |    532.239514 |    114.603308 | L. Shyamal                                                                                                                                                                      |
| 492 |    150.474213 |    786.774113 | Margret Flinsch, vectorized by Zimices                                                                                                                                          |
| 493 |   1014.764856 |    415.451665 | V. Deepak                                                                                                                                                                       |
| 494 |    825.893970 |    505.735375 | NA                                                                                                                                                                              |
| 495 |    357.878695 |    321.984002 | Tasman Dixon                                                                                                                                                                    |
| 496 |    720.902498 |    670.265672 | Emily Willoughby                                                                                                                                                                |
| 497 |    434.094832 |    675.161042 | Chris huh                                                                                                                                                                       |
| 498 |    429.070188 |    794.861360 | Margot Michaud                                                                                                                                                                  |
| 499 |    300.879165 |    724.631326 | Chris huh                                                                                                                                                                       |
| 500 |     29.200381 |    713.604604 | T. Michael Keesey                                                                                                                                                               |
| 501 |    533.110120 |    425.879993 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                            |
| 502 |    632.109897 |    322.103349 | Carlos Cano-Barbacil                                                                                                                                                            |
| 503 |     33.627782 |     74.397427 | Steven Traver                                                                                                                                                                   |
| 504 |    894.085812 |    790.040469 | Margot Michaud                                                                                                                                                                  |
| 505 |    245.601328 |    581.798158 | Gareth Monger                                                                                                                                                                   |
| 506 |    330.783272 |    341.001381 | Iain Reid                                                                                                                                                                       |
| 507 |    186.578580 |    221.919388 | Armin Reindl                                                                                                                                                                    |
| 508 |    750.791530 |    483.612347 | Lukasiniho                                                                                                                                                                      |
| 509 |    352.976526 |    207.935618 | Margot Michaud                                                                                                                                                                  |
| 510 |    469.733261 |    380.765097 | Margot Michaud                                                                                                                                                                  |
| 511 |    493.098167 |    423.611954 | Scott Hartman                                                                                                                                                                   |
| 512 |    788.896031 |    170.855365 | Joanna Wolfe                                                                                                                                                                    |

    #> Your tweet has been posted!
