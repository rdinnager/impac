
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

Matt Crook, Marie Russell, Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, DW Bapst (modified from Mitchell 1990), Gareth
Monger, Andrew A. Farke, Carlos Cano-Barbacil, Bruno C. Vellutini, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Myriam\_Ramirez, Harold N Eyster, FunkMonk, Scott
Hartman, Margot Michaud, Steven Traver, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Markus A.
Grohme, Andy Wilson, T. Michael Keesey, Zimices, Michelle Site, Jagged
Fang Designs, Maija Karala, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Gabriela Palomo-Munoz, Christoph Schomburg, Tyler McCraney,
Sarah Werning, Pearson Scott Foresman (vectorized by T. Michael Keesey),
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), nicubunu, Tracy A. Heath, Ferran
Sayol, Emily Willoughby, xgirouxb, Henry Lydecker, Roberto Díaz Sibaja,
RS, Jose Carlos Arenas-Monroy, Alexandre Vong, (unknown), Geoff Shaw,
Nobu Tamura, vectorized by Zimices, Chris huh, Rene Martin, Iain Reid,
Mathieu Basille, Stuart Humphries, C. Camilo Julián-Caballero, Birgit
Lang, Anthony Caravaggi, Pete Buchholz, Erika Schumacher, Ignacio
Contreras, Collin Gross, mystica, Jerry Oldenettel (vectorized by T.
Michael Keesey), Tauana J. Cunha, David Orr, Ghedoghedo (vectorized by
T. Michael Keesey), Xavier Giroux-Bougard, T. Michael Keesey (after
Kukalová), Smokeybjb, Emma Kissling, Yan Wong, Becky Barnes, Martien
Brand (original photo), Renato Santos (vector silhouette), Crystal
Maier, Jake Warner, Juan Carlos Jerí, Andreas Preuss / marauder,
Dr. Thomas G. Barnes, USFWS, Riccardo Percudani, Richard Ruggiero,
vectorized by Zimices, John Curtis (vectorized by T. Michael Keesey),
Roberto Diaz Sibaja, based on Domser, Alexander Schmidt-Lebuhn, Allison
Pease, Stanton F. Fink (vectorized by T. Michael Keesey), Mathilde
Cordellier, Melissa Broussard, Jesús Gómez, vectorized by Zimices,
Agnello Picorelli, Eric Moody, Kamil S. Jaron, L. Shyamal,
Meliponicultor Itaymbere, Hans Hillewaert (vectorized by T. Michael
Keesey), Ingo Braasch, T. Michael Keesey (vectorization) and Larry Loos
(photography), Dori <dori@merr.info> (source photo) and Nevit Dilmen,
Jaime A. Headden (vectorized by T. Michael Keesey), Michele Tobias,
Fernando Carezzano, Frank Förster (based on a picture by Jerry Kirkhart;
modified by T. Michael Keesey), MPF (vectorized by T. Michael Keesey),
Conty (vectorized by T. Michael Keesey), Andrew A. Farke, shell lines
added by Yan Wong, Cesar Julian, Audrey Ely, Rebecca Groom, Chris Hay,
Tasman Dixon, Felix Vaux, Dean Schnabel, Manabu Bessho-Uehara, Scott
Reid, I. Sáček, Sr. (vectorized by T. Michael Keesey), Smith609 and T.
Michael Keesey, Hugo Gruson, CNZdenek, Davidson Sodré, Danielle Alba,
Daniel Stadtmauer, Ieuan Jones, Andrés Sánchez, Caleb M. Brown, Matt
Martyniuk (vectorized by T. Michael Keesey), Matthew Hooge (vectorized
by T. Michael Keesey), Stacy Spensley (Modified), Griensteidl and T.
Michael Keesey, Tony Ayling (vectorized by Milton Tan), Sam Droege
(photography) and T. Michael Keesey (vectorization), Ben Moon, Kosta
Mumcuoglu (vectorized by T. Michael Keesey), Caleb M. Gordon, Neil
Kelley, Dmitry Bogdanov, vectorized by Zimices, James Neenan,
Terpsichores, Lankester Edwin Ray (vectorized by T. Michael Keesey),
Steven Haddock • Jellywatch.org, Matus Valach, Ben Liebeskind, Caleb
Brown, Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz
Sibaja, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Dmitry Bogdanov, Nobu Tamura (vectorized by T. Michael Keesey),
Francesco Veronesi (vectorized by T. Michael Keesey), Lip Kee Yap
(vectorized by T. Michael Keesey), Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Y. de
Hoev. (vectorized by T. Michael Keesey), T. Michael Keesey (after James
& al.), Zachary Quigley, SauropodomorphMonarch, Jaime Headden
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by Bruno
Vellutini, Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), M Kolmann,
Jakovche, Beth Reinke, Mathew Wedel, Jaime Headden, Emily Jane McTavish,
Kent Elson Sorgon, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Brad
McFeeters (vectorized by T. Michael Keesey), E. R. Waite & H. M. Hale
(vectorized by T. Michael Keesey), Jack Mayer Wood, Zsoldos Márton
(vectorized by T. Michael Keesey), Mathieu Pélissié, T. Michael Keesey
(vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), Leon P. A. M. Claessens, Patrick M.
O’Connor, David M. Unwin, Obsidian Soul (vectorized by T. Michael
Keesey), Walter Vladimir, T. Tischler, Jiekun He, Lauren Anderson, Kai
R. Caspar, Cagri Cevrim, Armin Reindl, I. Geoffroy Saint-Hilaire
(vectorized by T. Michael Keesey), Lukas Panzarin, Julio Garza, Joanna
Wolfe, Young and Zhao (1972:figure 4), modified by Michael P. Taylor,
David Tana, Joseph J. W. Sertich, Mark A. Loewen, Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Matt Martyniuk

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    122.629912 |    510.221377 | Matt Crook                                                                                                                                                                           |
|   2 |    619.353656 |    477.318637 | Marie Russell                                                                                                                                                                        |
|   3 |    363.995166 |     64.436768 | NA                                                                                                                                                                                   |
|   4 |    949.337852 |    148.951604 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                                 |
|   5 |    612.455807 |    158.731109 | DW Bapst (modified from Mitchell 1990)                                                                                                                                               |
|   6 |    402.418891 |    382.420889 | Gareth Monger                                                                                                                                                                        |
|   7 |    916.924682 |    470.894060 | Andrew A. Farke                                                                                                                                                                      |
|   8 |     95.109089 |    261.918514 | Carlos Cano-Barbacil                                                                                                                                                                 |
|   9 |    772.257910 |    577.368911 | Bruno C. Vellutini                                                                                                                                                                   |
|  10 |    406.725127 |    634.728234 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                               |
|  11 |    970.259015 |    666.040562 | Myriam\_Ramirez                                                                                                                                                                      |
|  12 |    785.396806 |    182.225458 | Matt Crook                                                                                                                                                                           |
|  13 |    537.614556 |    254.769735 | Harold N Eyster                                                                                                                                                                      |
|  14 |    238.690448 |    611.460485 | FunkMonk                                                                                                                                                                             |
|  15 |    698.479299 |    537.375510 | Scott Hartman                                                                                                                                                                        |
|  16 |     92.957280 |    379.646048 | Scott Hartman                                                                                                                                                                        |
|  17 |    282.268084 |    243.751561 | Scott Hartman                                                                                                                                                                        |
|  18 |    264.082643 |     55.443535 | Margot Michaud                                                                                                                                                                       |
|  19 |    493.218945 |    740.135310 | Steven Traver                                                                                                                                                                        |
|  20 |    654.135688 |    767.185159 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
|  21 |    223.557944 |    565.203558 | Markus A. Grohme                                                                                                                                                                     |
|  22 |    728.709178 |    375.094302 | Andy Wilson                                                                                                                                                                          |
|  23 |    827.341138 |    607.186163 | NA                                                                                                                                                                                   |
|  24 |    279.529032 |    765.727601 | T. Michael Keesey                                                                                                                                                                    |
|  25 |    806.707187 |     65.328057 | Zimices                                                                                                                                                                              |
|  26 |    283.389278 |    471.945417 | Matt Crook                                                                                                                                                                           |
|  27 |    346.832397 |    234.808721 | Scott Hartman                                                                                                                                                                        |
|  28 |    170.586819 |    694.961079 | T. Michael Keesey                                                                                                                                                                    |
|  29 |    765.154589 |    704.115841 | Michelle Site                                                                                                                                                                        |
|  30 |    566.255697 |    637.785158 | Jagged Fang Designs                                                                                                                                                                  |
|  31 |    924.296394 |    532.476402 | Maija Karala                                                                                                                                                                         |
|  32 |    798.595819 |    497.368319 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  33 |    162.436489 |     84.000579 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  34 |    860.523302 |    349.417279 | Christoph Schomburg                                                                                                                                                                  |
|  35 |    436.930801 |    672.963607 | Tyler McCraney                                                                                                                                                                       |
|  36 |    223.697671 |    368.015834 | Sarah Werning                                                                                                                                                                        |
|  37 |    403.701407 |    549.299530 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
|  38 |    947.208445 |    300.540596 | Scott Hartman                                                                                                                                                                        |
|  39 |    922.577557 |    608.007139 | Sarah Werning                                                                                                                                                                        |
|  40 |    639.324919 |    337.948545 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
|  41 |    950.318385 |    391.437924 | NA                                                                                                                                                                                   |
|  42 |    663.384305 |     35.343298 | nicubunu                                                                                                                                                                             |
|  43 |     84.172052 |    193.155270 | Tracy A. Heath                                                                                                                                                                       |
|  44 |     24.031121 |    663.576730 | T. Michael Keesey                                                                                                                                                                    |
|  45 |    466.320862 |    119.035059 | Ferran Sayol                                                                                                                                                                         |
|  46 |    764.078991 |    303.698731 | Emily Willoughby                                                                                                                                                                     |
|  47 |    679.066586 |    611.434125 | Tracy A. Heath                                                                                                                                                                       |
|  48 |     68.407067 |    455.046768 | Christoph Schomburg                                                                                                                                                                  |
|  49 |    286.535003 |    152.975652 | xgirouxb                                                                                                                                                                             |
|  50 |     71.245050 |    325.669374 | Henry Lydecker                                                                                                                                                                       |
|  51 |     73.736352 |    762.663597 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  52 |    304.122477 |    682.093752 | RS                                                                                                                                                                                   |
|  53 |    880.055604 |     78.770558 | Gareth Monger                                                                                                                                                                        |
|  54 |    539.683767 |    380.507400 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
|  55 |    639.232785 |    709.231932 | Alexandre Vong                                                                                                                                                                       |
|  56 |    270.100380 |    646.289768 | (unknown)                                                                                                                                                                            |
|  57 |    570.943595 |     61.390838 | Zimices                                                                                                                                                                              |
|  58 |    101.734002 |    628.228538 | Zimices                                                                                                                                                                              |
|  59 |    947.557423 |    430.575866 | Margot Michaud                                                                                                                                                                       |
|  60 |    956.010309 |     35.746503 | Scott Hartman                                                                                                                                                                        |
|  61 |    905.805531 |    755.979539 | Zimices                                                                                                                                                                              |
|  62 |    411.908231 |    164.949648 | Geoff Shaw                                                                                                                                                                           |
|  63 |    360.409016 |    730.287863 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  64 |    797.769094 |    422.506031 | Matt Crook                                                                                                                                                                           |
|  65 |    585.534937 |    568.050944 | Scott Hartman                                                                                                                                                                        |
|  66 |    463.323566 |     19.583339 | Chris huh                                                                                                                                                                            |
|  67 |    761.066402 |    775.403259 | T. Michael Keesey                                                                                                                                                                    |
|  68 |    853.234945 |    701.984739 | Rene Martin                                                                                                                                                                          |
|  69 |    109.706075 |    298.597310 | Maija Karala                                                                                                                                                                         |
|  70 |    714.583289 |    220.442627 | Margot Michaud                                                                                                                                                                       |
|  71 |    962.534163 |    347.553916 | Andy Wilson                                                                                                                                                                          |
|  72 |    428.265652 |    268.969281 | Iain Reid                                                                                                                                                                            |
|  73 |    480.361232 |    333.683451 | Chris huh                                                                                                                                                                            |
|  74 |    463.975707 |    464.687198 | Mathieu Basille                                                                                                                                                                      |
|  75 |    264.842464 |     90.212557 | Markus A. Grohme                                                                                                                                                                     |
|  76 |    202.598300 |    542.732613 | Jagged Fang Designs                                                                                                                                                                  |
|  77 |    483.048362 |    559.073152 | Emily Willoughby                                                                                                                                                                     |
|  78 |     41.882290 |     94.059685 | NA                                                                                                                                                                                   |
|  79 |    702.525481 |    105.282342 | Scott Hartman                                                                                                                                                                        |
|  80 |    865.557275 |    261.632110 | Stuart Humphries                                                                                                                                                                     |
|  81 |     85.957060 |    102.857759 | Gareth Monger                                                                                                                                                                        |
|  82 |    977.175678 |    490.742644 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  83 |    328.645781 |    613.506964 | Zimices                                                                                                                                                                              |
|  84 |    313.876409 |    583.126848 | Margot Michaud                                                                                                                                                                       |
|  85 |    134.786107 |    432.195726 | Sarah Werning                                                                                                                                                                        |
|  86 |    470.450702 |     49.733074 | Scott Hartman                                                                                                                                                                        |
|  87 |    178.491399 |    148.081500 | Birgit Lang                                                                                                                                                                          |
|  88 |    196.584014 |    449.754129 | T. Michael Keesey                                                                                                                                                                    |
|  89 |    298.429615 |    322.697626 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  90 |    682.053232 |    324.883886 | Anthony Caravaggi                                                                                                                                                                    |
|  91 |     32.379245 |    490.948755 | Christoph Schomburg                                                                                                                                                                  |
|  92 |    783.007487 |    366.904072 | Birgit Lang                                                                                                                                                                          |
|  93 |    496.473794 |    636.811861 | Margot Michaud                                                                                                                                                                       |
|  94 |    824.407115 |    101.651218 | Pete Buchholz                                                                                                                                                                        |
|  95 |    974.025650 |    765.122664 | Steven Traver                                                                                                                                                                        |
|  96 |    637.911824 |    253.988730 | Margot Michaud                                                                                                                                                                       |
|  97 |    805.487865 |    269.497582 | Erika Schumacher                                                                                                                                                                     |
|  98 |    597.879666 |    635.818138 | Margot Michaud                                                                                                                                                                       |
|  99 |    978.605971 |    291.346429 | Margot Michaud                                                                                                                                                                       |
| 100 |    316.010713 |    355.020897 | Ignacio Contreras                                                                                                                                                                    |
| 101 |     90.444752 |    356.543427 | Michelle Site                                                                                                                                                                        |
| 102 |    366.982337 |    207.372365 | Collin Gross                                                                                                                                                                         |
| 103 |    412.479813 |    214.456664 | T. Michael Keesey                                                                                                                                                                    |
| 104 |    694.738927 |    739.147833 | Christoph Schomburg                                                                                                                                                                  |
| 105 |    424.146058 |    316.072180 | mystica                                                                                                                                                                              |
| 106 |    588.697069 |    324.333671 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 107 |    396.547313 |    754.156225 | Zimices                                                                                                                                                                              |
| 108 |    871.617176 |    425.588174 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 109 |    764.980401 |    272.415295 | Tauana J. Cunha                                                                                                                                                                      |
| 110 |     71.035507 |     19.539256 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 111 |    758.146192 |    350.371423 | Margot Michaud                                                                                                                                                                       |
| 112 |    619.842392 |    372.851659 | T. Michael Keesey                                                                                                                                                                    |
| 113 |    499.883029 |    399.380210 | David Orr                                                                                                                                                                            |
| 114 |    180.213957 |     36.705357 | NA                                                                                                                                                                                   |
| 115 |    704.650443 |    135.870298 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 116 |    818.207756 |    484.455432 | Xavier Giroux-Bougard                                                                                                                                                                |
| 117 |     54.424541 |    660.313985 | T. Michael Keesey (after Kukalová)                                                                                                                                                   |
| 118 |    248.338418 |    591.035827 | Smokeybjb                                                                                                                                                                            |
| 119 |    887.915732 |    371.622791 | Emma Kissling                                                                                                                                                                        |
| 120 |    217.082688 |     31.072739 | Matt Crook                                                                                                                                                                           |
| 121 |    989.593064 |    704.385812 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 122 |    397.383920 |    700.831829 | David Orr                                                                                                                                                                            |
| 123 |    895.038488 |    183.650463 | Yan Wong                                                                                                                                                                             |
| 124 |    730.286321 |    123.287477 | Becky Barnes                                                                                                                                                                         |
| 125 |   1005.723693 |    588.726066 | Ferran Sayol                                                                                                                                                                         |
| 126 |    340.241685 |    111.305600 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 127 |    370.141435 |    393.311891 | nicubunu                                                                                                                                                                             |
| 128 |    850.057388 |    675.265354 | Jagged Fang Designs                                                                                                                                                                  |
| 129 |    304.671989 |    384.689172 | T. Michael Keesey                                                                                                                                                                    |
| 130 |    461.522459 |    375.091020 | Crystal Maier                                                                                                                                                                        |
| 131 |    281.127694 |    711.382611 | Chris huh                                                                                                                                                                            |
| 132 |     93.750059 |    699.401040 | Ferran Sayol                                                                                                                                                                         |
| 133 |    627.504654 |    233.185670 | Jake Warner                                                                                                                                                                          |
| 134 |    193.529154 |    271.117981 | Zimices                                                                                                                                                                              |
| 135 |    763.336679 |    648.681969 | NA                                                                                                                                                                                   |
| 136 |     12.070638 |    123.093433 | T. Michael Keesey                                                                                                                                                                    |
| 137 |    984.475972 |    185.285164 | NA                                                                                                                                                                                   |
| 138 |    115.615981 |     19.486600 | Chris huh                                                                                                                                                                            |
| 139 |    753.423630 |    585.420390 | Juan Carlos Jerí                                                                                                                                                                     |
| 140 |    816.208661 |    326.067367 | Andy Wilson                                                                                                                                                                          |
| 141 |    884.348324 |    668.464601 | Andreas Preuss / marauder                                                                                                                                                            |
| 142 |    660.709769 |    403.842730 | Markus A. Grohme                                                                                                                                                                     |
| 143 |    788.054127 |    309.275244 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 144 |    993.470367 |    376.051931 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                          |
| 145 |    584.628295 |    682.094881 | Riccardo Percudani                                                                                                                                                                   |
| 146 |     59.300126 |    683.669485 | Zimices                                                                                                                                                                              |
| 147 |    795.568195 |     21.944167 | Richard Ruggiero, vectorized by Zimices                                                                                                                                              |
| 148 |    947.503082 |    623.457338 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 149 |     77.815020 |    568.702991 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 150 |    979.064189 |    456.888602 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 151 |    988.702433 |    266.899046 | Allison Pease                                                                                                                                                                        |
| 152 |     32.941751 |    400.424316 | Matt Crook                                                                                                                                                                           |
| 153 |   1002.315390 |    222.466401 | Margot Michaud                                                                                                                                                                       |
| 154 |    896.940852 |    212.845430 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 155 |    138.211726 |    326.690618 | Mathilde Cordellier                                                                                                                                                                  |
| 156 |    145.561571 |    559.417110 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 157 |    392.781211 |    790.326711 | Chris huh                                                                                                                                                                            |
| 158 |    595.590253 |     30.374626 | NA                                                                                                                                                                                   |
| 159 |    682.532017 |    503.589808 | Ferran Sayol                                                                                                                                                                         |
| 160 |    166.889346 |    782.889872 | Melissa Broussard                                                                                                                                                                    |
| 161 |    414.063953 |    724.536833 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 162 |    206.087308 |     78.047602 | NA                                                                                                                                                                                   |
| 163 |    807.529424 |    526.527913 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 164 |     20.453287 |    564.645674 | Birgit Lang                                                                                                                                                                          |
| 165 |    602.241280 |    718.414118 | Birgit Lang                                                                                                                                                                          |
| 166 |    273.398037 |     22.116381 | Agnello Picorelli                                                                                                                                                                    |
| 167 |    637.992434 |    549.439825 | Eric Moody                                                                                                                                                                           |
| 168 |   1008.687478 |    101.408601 | Crystal Maier                                                                                                                                                                        |
| 169 |    531.734282 |    542.270134 | Kamil S. Jaron                                                                                                                                                                       |
| 170 |    320.449992 |    339.721841 | Chris huh                                                                                                                                                                            |
| 171 |    945.601128 |    478.456793 | NA                                                                                                                                                                                   |
| 172 |    380.343047 |    444.041290 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 173 |    501.210029 |    192.515894 | L. Shyamal                                                                                                                                                                           |
| 174 |    300.003180 |    546.164407 | Emily Willoughby                                                                                                                                                                     |
| 175 |    699.434668 |    475.865238 | NA                                                                                                                                                                                   |
| 176 |    948.700405 |    277.921052 | Meliponicultor Itaymbere                                                                                                                                                             |
| 177 |    343.406025 |    300.175870 | Harold N Eyster                                                                                                                                                                      |
| 178 |    826.804306 |    456.665682 | Andy Wilson                                                                                                                                                                          |
| 179 |    148.111845 |    370.281094 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 180 |    804.676161 |    667.453843 | NA                                                                                                                                                                                   |
| 181 |    672.848032 |    361.708133 | Ingo Braasch                                                                                                                                                                         |
| 182 |    611.835018 |     90.174499 | Jagged Fang Designs                                                                                                                                                                  |
| 183 |    262.088855 |    321.207473 | T. Michael Keesey                                                                                                                                                                    |
| 184 |    565.319789 |     24.677039 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                                       |
| 185 |    621.118494 |    663.728369 | Margot Michaud                                                                                                                                                                       |
| 186 |    419.685780 |     42.153494 | RS                                                                                                                                                                                   |
| 187 |     22.277598 |    263.367257 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                                |
| 188 |     18.177854 |    302.012392 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                                   |
| 189 |    585.137411 |    785.740597 | Zimices                                                                                                                                                                              |
| 190 |    353.063256 |    706.723159 | Michele Tobias                                                                                                                                                                       |
| 191 |    245.475771 |    438.077456 | Gareth Monger                                                                                                                                                                        |
| 192 |    174.484823 |    307.566353 | Margot Michaud                                                                                                                                                                       |
| 193 |    322.154779 |    203.780849 | FunkMonk                                                                                                                                                                             |
| 194 |    750.660986 |     27.375634 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 195 |    373.482846 |    460.063016 | Fernando Carezzano                                                                                                                                                                   |
| 196 |    531.061612 |    101.331391 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                                  |
| 197 |    915.047654 |    672.785908 | Zimices                                                                                                                                                                              |
| 198 |    534.827749 |    135.440233 | MPF (vectorized by T. Michael Keesey)                                                                                                                                                |
| 199 |    198.757548 |    506.077644 | Ferran Sayol                                                                                                                                                                         |
| 200 |    741.645322 |    566.664401 | Chris huh                                                                                                                                                                            |
| 201 |     91.749457 |     36.099110 | Jagged Fang Designs                                                                                                                                                                  |
| 202 |    790.818837 |    343.313063 | Sarah Werning                                                                                                                                                                        |
| 203 |    166.307151 |    254.490998 | NA                                                                                                                                                                                   |
| 204 |    198.694812 |    482.370852 | Zimices                                                                                                                                                                              |
| 205 |    688.309911 |     74.375924 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 206 |    716.120357 |    147.272869 | Juan Carlos Jerí                                                                                                                                                                     |
| 207 |    841.280382 |    123.032460 | Gareth Monger                                                                                                                                                                        |
| 208 |    550.757196 |    603.718390 | Zimices                                                                                                                                                                              |
| 209 |    125.792688 |    588.312815 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 210 |    365.838579 |    345.169020 | T. Michael Keesey                                                                                                                                                                    |
| 211 |    713.469174 |    529.260523 | NA                                                                                                                                                                                   |
| 212 |    767.911969 |    106.985170 | Matt Crook                                                                                                                                                                           |
| 213 |    189.066870 |    662.581770 | Zimices                                                                                                                                                                              |
| 214 |    321.910374 |    406.898393 | Ignacio Contreras                                                                                                                                                                    |
| 215 |     36.075308 |    420.749327 | NA                                                                                                                                                                                   |
| 216 |    252.830145 |    220.060399 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 217 |    857.697116 |    168.554791 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
| 218 |    827.858927 |    725.039384 | Iain Reid                                                                                                                                                                            |
| 219 |     67.695723 |    639.600630 | Cesar Julian                                                                                                                                                                         |
| 220 |    718.554579 |    460.567887 | Audrey Ely                                                                                                                                                                           |
| 221 |     26.486663 |    540.394978 | NA                                                                                                                                                                                   |
| 222 |    629.591605 |    507.820954 | Rebecca Groom                                                                                                                                                                        |
| 223 |    111.173116 |    409.289992 | Agnello Picorelli                                                                                                                                                                    |
| 224 |    174.421485 |     11.139243 | Zimices                                                                                                                                                                              |
| 225 |    169.089784 |    217.271625 | Michelle Site                                                                                                                                                                        |
| 226 |    698.573695 |    283.888481 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 227 |    572.908583 |    205.151181 | Chris Hay                                                                                                                                                                            |
| 228 |    537.357687 |    195.869014 | Tasman Dixon                                                                                                                                                                         |
| 229 |    424.132799 |    477.921385 | Tasman Dixon                                                                                                                                                                         |
| 230 |    165.603364 |    740.536855 | Felix Vaux                                                                                                                                                                           |
| 231 |    437.033407 |    224.817930 | Margot Michaud                                                                                                                                                                       |
| 232 |    647.030842 |    635.783429 | Dean Schnabel                                                                                                                                                                        |
| 233 |    163.178681 |    184.870143 | Steven Traver                                                                                                                                                                        |
| 234 |    582.530765 |    763.281191 | Scott Hartman                                                                                                                                                                        |
| 235 |    671.129231 |    563.287995 | Zimices                                                                                                                                                                              |
| 236 |    999.269511 |     64.736290 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 237 |    836.779343 |     13.710143 | Zimices                                                                                                                                                                              |
| 238 |   1004.392246 |    450.854706 | NA                                                                                                                                                                                   |
| 239 |     39.131318 |    304.396391 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 240 |    578.143615 |    744.146359 | Birgit Lang                                                                                                                                                                          |
| 241 |    267.211023 |    577.399803 | Maija Karala                                                                                                                                                                         |
| 242 |    199.358525 |    236.316309 | Andy Wilson                                                                                                                                                                          |
| 243 |    681.386923 |    185.352743 | Scott Reid                                                                                                                                                                           |
| 244 |   1000.984789 |    472.502548 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 245 |    530.675775 |    441.749964 | Yan Wong                                                                                                                                                                             |
| 246 |    559.061042 |    116.295920 | Smith609 and T. Michael Keesey                                                                                                                                                       |
| 247 |    157.192382 |    583.643643 | Steven Traver                                                                                                                                                                        |
| 248 |    536.829363 |    399.224000 | Hugo Gruson                                                                                                                                                                          |
| 249 |    666.563018 |    147.776642 | CNZdenek                                                                                                                                                                             |
| 250 |    115.532637 |    146.032318 | Emily Willoughby                                                                                                                                                                     |
| 251 |    533.081127 |    581.127549 | Matt Crook                                                                                                                                                                           |
| 252 |    736.016963 |    736.957360 | Zimices                                                                                                                                                                              |
| 253 |    768.855629 |    387.075715 | Davidson Sodré                                                                                                                                                                       |
| 254 |    120.751182 |    732.592006 | FunkMonk                                                                                                                                                                             |
| 255 |     50.662913 |    522.697284 | Danielle Alba                                                                                                                                                                        |
| 256 |    716.205300 |    497.517349 | Andy Wilson                                                                                                                                                                          |
| 257 |    272.265523 |    236.041175 | Daniel Stadtmauer                                                                                                                                                                    |
| 258 |    682.970631 |      6.128933 | Jagged Fang Designs                                                                                                                                                                  |
| 259 |    735.213526 |    556.863957 | Ieuan Jones                                                                                                                                                                          |
| 260 |    866.489743 |    226.549517 | Scott Hartman                                                                                                                                                                        |
| 261 |    170.160806 |    406.971252 | Andrés Sánchez                                                                                                                                                                       |
| 262 |    799.102928 |    467.923631 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 263 |     69.821835 |    140.537475 | T. Michael Keesey                                                                                                                                                                    |
| 264 |    212.237269 |    276.592585 | T. Michael Keesey                                                                                                                                                                    |
| 265 |    856.844997 |    279.789591 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 266 |    672.849890 |    133.273020 | Zimices                                                                                                                                                                              |
| 267 |    829.175346 |    245.715991 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 268 |    146.635380 |    755.994461 | NA                                                                                                                                                                                   |
| 269 |    602.416693 |    226.013926 | Felix Vaux                                                                                                                                                                           |
| 270 |   1003.106694 |    734.448369 | Markus A. Grohme                                                                                                                                                                     |
| 271 |    210.754965 |    428.977137 | Steven Traver                                                                                                                                                                        |
| 272 |    909.137439 |    352.975007 | L. Shyamal                                                                                                                                                                           |
| 273 |   1012.152350 |    270.971921 | Gareth Monger                                                                                                                                                                        |
| 274 |    185.781103 |    735.384435 | Caleb M. Brown                                                                                                                                                                       |
| 275 |    235.724085 |     11.107420 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 276 |     36.513072 |    790.926902 | Scott Hartman                                                                                                                                                                        |
| 277 |    742.087913 |     69.802016 | Emily Willoughby                                                                                                                                                                     |
| 278 |    450.048383 |    416.418576 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                                      |
| 279 |    235.430704 |    582.973260 | Erika Schumacher                                                                                                                                                                     |
| 280 |    376.223359 |    473.741888 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 281 |    855.486829 |    238.429552 | Stacy Spensley (Modified)                                                                                                                                                            |
| 282 |    600.886564 |    352.725003 | Matt Crook                                                                                                                                                                           |
| 283 |    336.106620 |    553.750740 | Tasman Dixon                                                                                                                                                                         |
| 284 |    202.841384 |    685.603187 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 285 |    947.602442 |    505.233379 | Chris huh                                                                                                                                                                            |
| 286 |     64.090329 |    341.408246 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                               |
| 287 |    956.177645 |    549.524212 | Collin Gross                                                                                                                                                                         |
| 288 |     76.299093 |    421.361039 | Matt Crook                                                                                                                                                                           |
| 289 |    454.297562 |    284.039272 | Dean Schnabel                                                                                                                                                                        |
| 290 |     96.224249 |     59.286225 | NA                                                                                                                                                                                   |
| 291 |    611.730875 |    743.086650 | Jagged Fang Designs                                                                                                                                                                  |
| 292 |    918.809370 |    496.507786 | Chris huh                                                                                                                                                                            |
| 293 |    995.020215 |    791.208285 | Iain Reid                                                                                                                                                                            |
| 294 |    645.984186 |    612.864658 | T. Michael Keesey                                                                                                                                                                    |
| 295 |    853.779326 |    514.523438 | Birgit Lang                                                                                                                                                                          |
| 296 |    312.059673 |     36.779501 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 297 |    767.563303 |    407.093893 | Zimices                                                                                                                                                                              |
| 298 |    596.519404 |    181.355286 | Matt Crook                                                                                                                                                                           |
| 299 |    233.255340 |    681.924596 | Gareth Monger                                                                                                                                                                        |
| 300 |    302.136386 |      7.970736 | Rebecca Groom                                                                                                                                                                        |
| 301 |    395.492431 |    122.061610 | Ben Moon                                                                                                                                                                             |
| 302 |    695.413297 |    303.450617 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                                    |
| 303 |    572.493457 |    715.271635 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 304 |    989.994627 |    553.569050 | Melissa Broussard                                                                                                                                                                    |
| 305 |    846.109362 |    735.847177 | Caleb M. Gordon                                                                                                                                                                      |
| 306 |    573.881549 |    541.227443 | Ferran Sayol                                                                                                                                                                         |
| 307 |    281.973456 |    346.606838 | Ignacio Contreras                                                                                                                                                                    |
| 308 |   1018.944213 |    663.287691 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 309 |    336.188116 |     49.425399 | Scott Hartman                                                                                                                                                                        |
| 310 |    640.695492 |    426.193765 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 311 |    926.029262 |    336.074818 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 312 |    521.905806 |    517.205570 | Neil Kelley                                                                                                                                                                          |
| 313 |    910.062884 |    257.888643 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                               |
| 314 |     25.610511 |    372.860579 | Jagged Fang Designs                                                                                                                                                                  |
| 315 |    857.827844 |    538.608730 | Chris huh                                                                                                                                                                            |
| 316 |    134.640565 |    348.960246 | T. Michael Keesey                                                                                                                                                                    |
| 317 |     81.431855 |    721.374271 | James Neenan                                                                                                                                                                         |
| 318 |    861.552885 |    207.761149 | Terpsichores                                                                                                                                                                         |
| 319 |    580.799851 |    592.873116 | Steven Traver                                                                                                                                                                        |
| 320 |    972.194048 |    238.326570 | Christoph Schomburg                                                                                                                                                                  |
| 321 |    592.663300 |    414.623284 | Harold N Eyster                                                                                                                                                                      |
| 322 |    322.367357 |    637.871114 | Tasman Dixon                                                                                                                                                                         |
| 323 |    211.294485 |    174.582259 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 324 |    942.724606 |    787.744632 | Margot Michaud                                                                                                                                                                       |
| 325 |    997.439461 |    679.053621 | Mathieu Basille                                                                                                                                                                      |
| 326 |    832.598326 |    358.643560 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 327 |    543.298973 |    177.815296 | Ferran Sayol                                                                                                                                                                         |
| 328 |    336.087737 |    261.808087 | Andrew A. Farke                                                                                                                                                                      |
| 329 |    791.627802 |    315.760776 | Zimices                                                                                                                                                                              |
| 330 |    193.429605 |    179.311288 | Chris huh                                                                                                                                                                            |
| 331 |    225.706396 |    728.096905 | Markus A. Grohme                                                                                                                                                                     |
| 332 |    639.772858 |     66.182655 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 333 |    650.205543 |    514.599415 | Markus A. Grohme                                                                                                                                                                     |
| 334 |    979.392553 |    730.092734 | Chris huh                                                                                                                                                                            |
| 335 |    897.574048 |    682.698199 | Jagged Fang Designs                                                                                                                                                                  |
| 336 |    912.613419 |     61.473376 | Matus Valach                                                                                                                                                                         |
| 337 |    677.475431 |    657.384703 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 338 |    354.948806 |    328.201402 | Gareth Monger                                                                                                                                                                        |
| 339 |     14.638320 |     18.006785 | Gareth Monger                                                                                                                                                                        |
| 340 |    860.879716 |    651.597422 | Ben Liebeskind                                                                                                                                                                       |
| 341 |    120.696807 |    640.770197 | Caleb Brown                                                                                                                                                                          |
| 342 |    806.187733 |    351.657370 | Margot Michaud                                                                                                                                                                       |
| 343 |    211.359856 |    780.156090 | Dean Schnabel                                                                                                                                                                        |
| 344 |    408.425953 |    309.958862 | CNZdenek                                                                                                                                                                             |
| 345 |    970.922862 |     14.627961 | Ignacio Contreras                                                                                                                                                                    |
| 346 |    226.163237 |    200.085032 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 347 |    191.441857 |    643.627503 | Riccardo Percudani                                                                                                                                                                   |
| 348 |    915.222190 |    691.574292 | Maija Karala                                                                                                                                                                         |
| 349 |    418.841554 |    565.591266 | Matt Crook                                                                                                                                                                           |
| 350 |     19.405896 |    220.317222 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                               |
| 351 |    607.014334 |    123.586913 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                                          |
| 352 |    103.438693 |     79.232342 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 353 |    855.984519 |    478.397203 | Melissa Broussard                                                                                                                                                                    |
| 354 |     51.935603 |    715.952502 | T. Michael Keesey                                                                                                                                                                    |
| 355 |    725.668999 |     37.647682 | James Neenan                                                                                                                                                                         |
| 356 |    371.379458 |    404.376796 | Chris huh                                                                                                                                                                            |
| 357 |    207.777360 |    257.206222 | Jagged Fang Designs                                                                                                                                                                  |
| 358 |    482.472155 |    373.015135 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                                       |
| 359 |    759.548709 |    510.216390 | Dmitry Bogdanov                                                                                                                                                                      |
| 360 |    415.916969 |    204.706871 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 361 |    994.208479 |     89.821501 | Neil Kelley                                                                                                                                                                          |
| 362 |    599.079362 |    692.732667 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 363 |    525.347984 |    609.384001 | Zimices                                                                                                                                                                              |
| 364 |    268.501830 |    690.439349 | Caleb M. Gordon                                                                                                                                                                      |
| 365 |    238.007574 |    662.880681 | Jagged Fang Designs                                                                                                                                                                  |
| 366 |    895.033944 |    234.702895 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 367 |    423.777249 |    775.580797 | T. Michael Keesey                                                                                                                                                                    |
| 368 |    510.612886 |    470.586111 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                                 |
| 369 |    813.225761 |    790.673786 | Maija Karala                                                                                                                                                                         |
| 370 |    839.253801 |    139.533289 | Zimices                                                                                                                                                                              |
| 371 |    826.411786 |    114.513250 | Chris huh                                                                                                                                                                            |
| 372 |    613.890852 |     11.414914 | Erika Schumacher                                                                                                                                                                     |
| 373 |    746.344349 |    423.105917 | NA                                                                                                                                                                                   |
| 374 |    766.914496 |    605.622301 | Scott Hartman                                                                                                                                                                        |
| 375 |    864.708839 |    184.000850 | Zimices                                                                                                                                                                              |
| 376 |    866.879870 |    569.434839 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 377 |    616.509115 |    519.429612 | Maija Karala                                                                                                                                                                         |
| 378 |    424.932518 |    243.958575 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 379 |    998.007551 |     28.449533 | Scott Hartman                                                                                                                                                                        |
| 380 |    728.604644 |    475.745072 | Gareth Monger                                                                                                                                                                        |
| 381 |    537.219062 |     20.153125 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 382 |    993.782018 |    745.493627 | Iain Reid                                                                                                                                                                            |
| 383 |    175.749142 |     62.948812 | Ferran Sayol                                                                                                                                                                         |
| 384 |    119.197702 |    125.221949 | T. Michael Keesey                                                                                                                                                                    |
| 385 |   1007.451783 |    514.475918 | NA                                                                                                                                                                                   |
| 386 |    659.670643 |    240.326451 | Jagged Fang Designs                                                                                                                                                                  |
| 387 |    229.454919 |    703.126192 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 388 |    905.476295 |    302.689850 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                                        |
| 389 |    394.833015 |    771.060570 | Margot Michaud                                                                                                                                                                       |
| 390 |    359.302325 |    580.830671 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                                       |
| 391 |   1008.587122 |    130.352975 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                                        |
| 392 |    602.481280 |    553.743460 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                               |
| 393 |     87.785945 |    497.330583 | T. Michael Keesey (after James & al.)                                                                                                                                                |
| 394 |    849.332876 |    409.939163 | T. Michael Keesey                                                                                                                                                                    |
| 395 |    905.429024 |    408.023874 | Jagged Fang Designs                                                                                                                                                                  |
| 396 |    453.883689 |    392.174033 | Zachary Quigley                                                                                                                                                                      |
| 397 |     63.265449 |    311.550180 | Andrew A. Farke                                                                                                                                                                      |
| 398 |    230.142069 |    718.163777 | Chris huh                                                                                                                                                                            |
| 399 |    674.162061 |    345.606213 | Scott Hartman                                                                                                                                                                        |
| 400 |    395.765083 |    744.852771 | SauropodomorphMonarch                                                                                                                                                                |
| 401 |    505.183323 |     44.342733 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                                      |
| 402 |   1002.964299 |      5.495639 | Andy Wilson                                                                                                                                                                          |
| 403 |    349.211656 |    458.176272 | Crystal Maier                                                                                                                                                                        |
| 404 |    482.306808 |    215.795365 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                          |
| 405 |    339.474476 |    344.704017 | Scott Hartman                                                                                                                                                                        |
| 406 |     78.068848 |      3.005531 | Markus A. Grohme                                                                                                                                                                     |
| 407 |    148.985130 |     39.223183 | Zimices                                                                                                                                                                              |
| 408 |    255.846478 |    196.662251 | Gareth Monger                                                                                                                                                                        |
| 409 |     17.154723 |     87.707362 | Scott Hartman                                                                                                                                                                        |
| 410 |    513.200956 |     78.216433 | Emily Willoughby                                                                                                                                                                     |
| 411 |     21.848253 |    241.977033 | Margot Michaud                                                                                                                                                                       |
| 412 |    177.752163 |    342.343404 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                       |
| 413 |    679.506650 |    380.104284 | Matus Valach                                                                                                                                                                         |
| 414 |    470.061813 |     77.303404 | Steven Traver                                                                                                                                                                        |
| 415 |    197.982916 |    412.766794 | Margot Michaud                                                                                                                                                                       |
| 416 |    970.329996 |    218.862766 | Yan Wong                                                                                                                                                                             |
| 417 |     14.313856 |    427.451295 | M Kolmann                                                                                                                                                                            |
| 418 |    714.000381 |    662.674663 | Jakovche                                                                                                                                                                             |
| 419 |    463.969497 |     36.775173 | NA                                                                                                                                                                                   |
| 420 |    183.192707 |    294.560651 | Margot Michaud                                                                                                                                                                       |
| 421 |    100.403567 |    688.986435 | NA                                                                                                                                                                                   |
| 422 |    338.910339 |    385.853061 | Beth Reinke                                                                                                                                                                          |
| 423 |    757.096305 |    245.941368 | Mathew Wedel                                                                                                                                                                         |
| 424 |    788.370767 |    647.675269 | Matt Crook                                                                                                                                                                           |
| 425 |    173.443548 |    604.009211 | Andy Wilson                                                                                                                                                                          |
| 426 |    921.336687 |     11.318653 | Zimices                                                                                                                                                                              |
| 427 |    364.781030 |    187.638110 | Felix Vaux                                                                                                                                                                           |
| 428 |   1010.844499 |    190.256124 | Sarah Werning                                                                                                                                                                        |
| 429 |      9.818841 |    747.436550 | NA                                                                                                                                                                                   |
| 430 |    230.467415 |    549.622439 | Zimices                                                                                                                                                                              |
| 431 |    988.014533 |    327.815599 | Jaime Headden                                                                                                                                                                        |
| 432 |    535.470718 |    412.640250 | Emily Jane McTavish                                                                                                                                                                  |
| 433 |    266.040374 |    726.667726 | Tasman Dixon                                                                                                                                                                         |
| 434 |     49.264627 |    555.961021 | Scott Hartman                                                                                                                                                                        |
| 435 |     27.218932 |    516.464850 | Kent Elson Sorgon                                                                                                                                                                    |
| 436 |    604.755035 |    283.593443 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                                          |
| 437 |    118.770467 |    461.854631 | Zimices                                                                                                                                                                              |
| 438 |    602.190594 |    616.037755 | Scott Hartman                                                                                                                                                                        |
| 439 |    854.933888 |    792.371569 | Markus A. Grohme                                                                                                                                                                     |
| 440 |    752.215598 |    435.111794 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 441 |    986.534655 |    418.645010 | Steven Traver                                                                                                                                                                        |
| 442 |     44.704444 |    157.239412 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
| 443 |     43.035257 |    146.451122 | Margot Michaud                                                                                                                                                                       |
| 444 |     15.938087 |    281.609811 | Jack Mayer Wood                                                                                                                                                                      |
| 445 |    722.804800 |    647.746076 | Zimices                                                                                                                                                                              |
| 446 |    119.731170 |    235.785163 | Erika Schumacher                                                                                                                                                                     |
| 447 |    678.357387 |    277.073378 | Margot Michaud                                                                                                                                                                       |
| 448 |    848.704996 |     32.610030 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                     |
| 449 |    638.677117 |    741.059873 | Mathieu Pélissié                                                                                                                                                                     |
| 450 |     99.562140 |    482.566318 | Dmitry Bogdanov                                                                                                                                                                      |
| 451 |    834.246044 |    769.594656 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 452 |    213.751582 |    472.093820 | Markus A. Grohme                                                                                                                                                                     |
| 453 |    633.616009 |    532.328772 | Steven Traver                                                                                                                                                                        |
| 454 |    184.191476 |    779.792635 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                         |
| 455 |    639.222458 |    559.513995 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 456 |     20.574140 |    320.210476 | Jagged Fang Designs                                                                                                                                                                  |
| 457 |    706.605978 |    788.294425 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 458 |     52.364433 |    463.525234 | Yan Wong                                                                                                                                                                             |
| 459 |    471.188020 |    309.931018 | Walter Vladimir                                                                                                                                                                      |
| 460 |    524.984145 |    315.530423 | Gareth Monger                                                                                                                                                                        |
| 461 |    327.565291 |     80.648495 | Ferran Sayol                                                                                                                                                                         |
| 462 |     32.992331 |    291.305514 | T. Tischler                                                                                                                                                                          |
| 463 |    142.575856 |    410.126855 | Jagged Fang Designs                                                                                                                                                                  |
| 464 |    687.857668 |    415.420161 | Zimices                                                                                                                                                                              |
| 465 |    490.266139 |    357.571563 | Mathew Wedel                                                                                                                                                                         |
| 466 |    652.503876 |     82.314556 | Jiekun He                                                                                                                                                                            |
| 467 |    217.199014 |    143.941699 | NA                                                                                                                                                                                   |
| 468 |    865.333743 |    495.159080 | Zimices                                                                                                                                                                              |
| 469 |    281.997558 |    545.004351 | Lauren Anderson                                                                                                                                                                      |
| 470 |     33.409088 |    583.544433 | Kai R. Caspar                                                                                                                                                                        |
| 471 |    283.213432 |    632.387867 | Jack Mayer Wood                                                                                                                                                                      |
| 472 |   1012.453218 |    768.277622 | Gareth Monger                                                                                                                                                                        |
| 473 |    185.825978 |    725.091673 | Chris huh                                                                                                                                                                            |
| 474 |    376.009012 |    692.238790 | Ferran Sayol                                                                                                                                                                         |
| 475 |    553.196703 |    334.854997 | Cagri Cevrim                                                                                                                                                                         |
| 476 |    334.844904 |    537.260360 | Smokeybjb                                                                                                                                                                            |
| 477 |    167.016469 |    635.796555 | Armin Reindl                                                                                                                                                                         |
| 478 |    755.984238 |    326.020085 | Scott Hartman                                                                                                                                                                        |
| 479 |    469.130814 |    231.707538 | Iain Reid                                                                                                                                                                            |
| 480 |    990.775239 |     46.149538 | NA                                                                                                                                                                                   |
| 481 |    462.115230 |    602.728145 | Ignacio Contreras                                                                                                                                                                    |
| 482 |     18.988970 |    339.363029 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 483 |    413.742071 |     54.089343 | T. Michael Keesey                                                                                                                                                                    |
| 484 |    792.984928 |    687.005383 | Markus A. Grohme                                                                                                                                                                     |
| 485 |    984.937420 |    254.550574 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                          |
| 486 |    282.446499 |    595.730149 | Gareth Monger                                                                                                                                                                        |
| 487 |     44.041708 |     36.688016 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 488 |    129.261568 |    398.763937 | Markus A. Grohme                                                                                                                                                                     |
| 489 |    555.313057 |    157.112451 | Tasman Dixon                                                                                                                                                                         |
| 490 |    286.384591 |    208.978448 | Zachary Quigley                                                                                                                                                                      |
| 491 |    125.255849 |     26.714683 | Markus A. Grohme                                                                                                                                                                     |
| 492 |    672.671571 |    229.997178 | Tasman Dixon                                                                                                                                                                         |
| 493 |    605.959207 |    332.332813 | Lukas Panzarin                                                                                                                                                                       |
| 494 |     14.940064 |    194.341146 | Kai R. Caspar                                                                                                                                                                        |
| 495 |    112.154676 |    115.816298 | Birgit Lang                                                                                                                                                                          |
| 496 |    539.875461 |    218.776929 | Gareth Monger                                                                                                                                                                        |
| 497 |     26.444423 |    390.916241 | Scott Hartman                                                                                                                                                                        |
| 498 |   1014.654219 |    302.806522 | NA                                                                                                                                                                                   |
| 499 |      6.044996 |    382.373050 | Gareth Monger                                                                                                                                                                        |
| 500 |    600.396855 |    730.599806 | Julio Garza                                                                                                                                                                          |
| 501 |     62.361004 |    236.900191 | Erika Schumacher                                                                                                                                                                     |
| 502 |    877.556420 |    386.860018 | Margot Michaud                                                                                                                                                                       |
| 503 |    122.081643 |    567.594303 | Gareth Monger                                                                                                                                                                        |
| 504 |    460.140310 |    446.949018 | Jack Mayer Wood                                                                                                                                                                      |
| 505 |    768.994414 |    335.322109 | Jagged Fang Designs                                                                                                                                                                  |
| 506 |    790.799756 |    250.465364 | Joanna Wolfe                                                                                                                                                                         |
| 507 |   1006.643370 |     18.167738 | Gareth Monger                                                                                                                                                                        |
| 508 |    215.539851 |    519.941136 | Sarah Werning                                                                                                                                                                        |
| 509 |    893.154847 |      5.398669 | Jagged Fang Designs                                                                                                                                                                  |
| 510 |    393.417936 |     89.730528 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 511 |    318.333368 |    564.739135 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 512 |    988.774857 |     78.073487 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                        |
| 513 |    874.855301 |    153.900301 | David Tana                                                                                                                                                                           |
| 514 |    219.791953 |    495.694840 | Bruno C. Vellutini                                                                                                                                                                   |
| 515 |    472.311625 |    415.819931 | Emily Willoughby                                                                                                                                                                     |
| 516 |    276.063268 |    793.015599 | Sarah Werning                                                                                                                                                                        |
| 517 |    709.484275 |     82.340175 | Michelle Site                                                                                                                                                                        |
| 518 |    227.063085 |    306.037057 | NA                                                                                                                                                                                   |
| 519 |    262.257704 |    550.891646 | Mathieu Basille                                                                                                                                                                      |
| 520 |    241.600307 |    112.562476 | T. Michael Keesey                                                                                                                                                                    |
| 521 |    308.603052 |    736.321385 | Jagged Fang Designs                                                                                                                                                                  |
| 522 |    182.664252 |    793.652721 | Mathew Wedel                                                                                                                                                                         |
| 523 |    988.010306 |    598.310844 | Scott Hartman                                                                                                                                                                        |
| 524 |    107.696178 |    104.557962 | Jagged Fang Designs                                                                                                                                                                  |
| 525 |    894.930829 |    417.708069 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                                 |
| 526 |    794.750882 |    285.914881 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                                 |
| 527 |    822.009677 |    237.493885 | Zimices                                                                                                                                                                              |
| 528 |    115.875255 |    366.583240 | Matt Martyniuk                                                                                                                                                                       |
| 529 |     43.772631 |     13.414915 | Smokeybjb                                                                                                                                                                            |
| 530 |    690.139871 |    519.569986 | Yan Wong                                                                                                                                                                             |
| 531 |    245.142239 |    657.669601 | Jack Mayer Wood                                                                                                                                                                      |
| 532 |    626.162018 |    573.166197 | Tasman Dixon                                                                                                                                                                         |
| 533 |    832.470092 |    253.816904 | Xavier Giroux-Bougard                                                                                                                                                                |
| 534 |     18.299561 |    363.608938 | Chris huh                                                                                                                                                                            |

    #> Your tweet has been posted!
