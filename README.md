
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

Jagged Fang Designs, JJ Harrison (vectorized by T. Michael Keesey),
Steven Traver, Margot Michaud, T. Michael Keesey, C. Camilo
Julián-Caballero, Jerry Oldenettel (vectorized by T. Michael Keesey),
Francesca Belem Lopes Palmeira, Scott Hartman, Chris huh, Matt Crook,
Zimices, Nobu Tamura (vectorized by T. Michael Keesey), Matt Wilkins,
Markus A. Grohme, Ferran Sayol, B. Duygu Özpolat, Caleb M. Brown,
Kristina Gagalova, Juan Carlos Jerí, Yan Wong from illustration by Jules
Richard (1907), Roberto Díaz Sibaja, Noah Schlottman, Vijay Cavale
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Fernando Carezzano, David Orr, Smokeybjb, vectorized by Zimices,
Didier Descouens (vectorized by T. Michael Keesey), Katie S. Collins,
Gareth Monger, Gabriela Palomo-Munoz, Dean Schnabel, Nobu Tamura,
vectorized by Zimices, John Conway, FJDegrange, Erika Schumacher, Henry
Fairfield Osborn, vectorized by Zimices, Ingo Braasch, Tyler McCraney,
Josefine Bohr Brask, Andrew A. Farke, Ignacio Contreras, CNZdenek,
Birgit Lang, Ghedoghedo, Martin R. Smith, Pete Buchholz, Jimmy Bernot,
Becky Barnes, Nobu Tamura, Robert Gay, modified from FunkMonk (Michael
B.H.) and T. Michael Keesey., Lankester Edwin Ray (vectorized by T.
Michael Keesey), Collin Gross, Tasman Dixon, Mike Hanson, Rebecca Groom,
Chase Brownstein, Joanna Wolfe, Natalie Claunch, DW Bapst, modified from
Ishitani et al. 2016, Sarah Werning, Matt Martyniuk, Steven Coombs,
S.Martini, Stanton F. Fink (vectorized by T. Michael Keesey), Chuanixn
Yu, Chris Jennings (vectorized by A. Verrière), Smokeybjb, Noah
Schlottman, photo from National Science Foundation - Turbellarian
Taxonomic Database, Christine Axon, Mette Aumala, Stanton F. Fink,
vectorized by Zimices, Tauana J. Cunha, Christoph Schomburg, Anthony
Caravaggi, Original drawing by Antonov, vectorized by Roberto Díaz
Sibaja, Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), Henry
Lydecker, Mali’o Kodis, photograph by Cordell Expeditions at Cal
Academy, Oren Peles / vectorized by Yan Wong, Tracy A. Heath, Andy
Wilson, Bennet McComish, photo by Avenue, James R. Spotila and Ray
Chatterji, Apokryltaros (vectorized by T. Michael Keesey), Unknown
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Ghedoghedo (vectorized by T. Michael Keesey), Xavier
Giroux-Bougard, Charles R. Knight, vectorized by Zimices, Matt Dempsey,
Martin Kevil, Jack Mayer Wood, T. Michael Keesey (after Marek
Velechovský), Roderic Page and Lois Page, Harold N Eyster, Mihai Dragos
(vectorized by T. Michael Keesey), Tyler Greenfield, Steven Haddock
• Jellywatch.org, Ville Koistinen and T. Michael Keesey, Michael Day,
Jiekun He, George Edward Lodge (modified by T. Michael Keesey), Crystal
Maier, JCGiron, Amanda Katzer, Diego Fontaneto, Elisabeth A. Herniou,
Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and
Timothy G. Barraclough (vectorized by T. Michael Keesey), M Kolmann,
Young and Zhao (1972:figure 4), modified by Michael P. Taylor, Carlos
Cano-Barbacil, Nicholas J. Czaplewski, vectorized by Zimices, Jonathan
Wells, Matt Martyniuk (vectorized by T. Michael Keesey), Chloé Schmidt,
Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves),
Sean McCann, Leon P. A. M. Claessens, Patrick M. O’Connor, David M.
Unwin, wsnaccad, L. Shyamal, Jessica Anne Miller, Julio Garza, Maija
Karala, Yan Wong (vectorization) from 1873 illustration, Terpsichores,
Javier Luque & Sarah Gerken, A. R. McCulloch (vectorized by T. Michael
Keesey), Emily Willoughby, Emil Schmidt (vectorized by Maxime Dahirel),
Campbell Fleming, Catherine Yasuda, Emma Kissling, Smokeybjb (modified
by Mike Keesey), FunkMonk, Kamil S. Jaron, G. M. Woodward, Jaime
Headden, Ludwik Gąsiorowski, Jose Carlos Arenas-Monroy, Obsidian Soul
(vectorized by T. Michael Keesey), T. Michael Keesey (vector) and Stuart
Halliday (photograph), Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Cesar Julian,
Mali’o Kodis, image from the Biodiversity Heritage Library, kotik,
Martin R. Smith, after Skovsted et al 2015, Smith609 and T. Michael
Keesey, Oscar Sanisidro, Ralf Janssen, Nikola-Michael Prpic & Wim G. M.
Damen (vectorized by T. Michael Keesey), xgirouxb, Geoff Shaw, Chris A.
Hamilton, Kai R. Caspar, Felix Vaux, Tyler Greenfield and Dean Schnabel,
NASA, Jay Matternes (vectorized by T. Michael Keesey), John Curtis
(vectorized by T. Michael Keesey), Dmitry Bogdanov (vectorized by T.
Michael Keesey), Michael Scroggie, Michelle Site, (after McCulloch
1908), Lukasiniho, Todd Marshall, vectorized by Zimices, Maxime Dahirel,
Sergio A. Muñoz-Gómez, Joe Schneid (vectorized by T. Michael Keesey),
Ricardo N. Martinez & Oscar A. Alcober, Xavier A. Jenkins, Gabriel
Ugueto, Neil Kelley, Marie Russell, Siobhon Egan, Mathieu Pélissié, T.
Michael Keesey (vectorization) and HuttyMcphoo (photography), Lee
Harding (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Tony Ayling, Noah Schlottman, photo by Carlos
Sánchez-Ortiz, Shyamal, Smokeybjb (vectorized by T. Michael Keesey),
Alexander Schmidt-Lebuhn, Mathilde Cordellier, Allison Pease, Mark
Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Yan Wong, Julien Louys, E. Lear, 1819 (vectorization by
Yan Wong), Nicolas Mongiardino Koch, Derek Bakken (photograph) and T.
Michael Keesey (vectorization), Mareike C. Janiak, James I. Kirkland,
Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Dinah Challen,
Auckland Museum, Beth Reinke, Agnello Picorelli, H. F. O. March
(modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
Joschua Knüppe, Burton Robert, USFWS, Doug Backlund (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Cathy, Mali’o
Kodis, photograph by Melissa Frey, Michael P. Taylor, Armin Reindl,
Danielle Alba, Scott Reid, Ieuan Jones, Stemonitis (photography) and T.
Michael Keesey (vectorization), Gopal Murali, Pranav Iyer (grey ideas),
Robert Bruce Horsfall (vectorized by William Gearty), Michael “FunkMonk”
B. H. (vectorized by T. Michael Keesey), Paul Baker (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Tim H. Heupink,
Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey),
Roule Jammes (vectorized by T. Michael Keesey), Robert Bruce Horsfall,
from W.B. Scott’s 1912 “A History of Land Mammals in the Western
Hemisphere”, Noah Schlottman, photo by Reinhard Jahn, Kanchi Nanjo,
Kanako Bessho-Uehara, Renata F. Martins, Lauren Sumner-Rooney, Nick
Schooler, Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Skye M, Thea Boodhoo
(photograph) and T. Michael Keesey (vectorization), Sharon
Wegner-Larsen, Michele M Tobias from an image By Dcrjsr - Own work, CC
BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>,
Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Julie Blommaert based on photo by Sofdrakou, Michele
Tobias, T. Michael Keesey (after Ponomarenko), Wynston Cooper (photo)
and Albertonykus (silhouette), Melissa Broussard, Matus Valach, Michele
M Tobias, Thibaut Brunet, Mali’o Kodis, photograph by G. Giribet, M. A.
Broussard, Roger Witter, vectorized by Zimices, Liftarn, nicubunu,
Alexandre Vong, Kailah Thorn & Mark Hutchinson, Dmitry Bogdanov
(modified by T. Michael Keesey), Kosta Mumcuoglu (vectorized by T.
Michael Keesey), I. Geoffroy Saint-Hilaire (vectorized by T. Michael
Keesey), T. Michael Keesey (photo by Sean Mack), Moussa Direct
Ltd. (photography) and T. Michael Keesey (vectorization), Darren Naish
(vectorize by T. Michael Keesey), Mathieu Basille, david maas / dave
hone, Luc Viatour (source photo) and Andreas Plank, Lip Kee Yap
(vectorized by T. Michael Keesey), Matt Martyniuk (modified by T.
Michael Keesey), Mattia Menchetti, Mason McNair, Richard J. Harris,
Dmitry Bogdanov, Hugo Gruson, Yusan Yang, Verdilak, AnAgnosticGod
(vectorized by T. Michael Keesey), Johan Lindgren, Michael W. Caldwell,
Takuya Konishi, Luis M. Chiappe, Pearson Scott Foresman (vectorized by
T. Michael Keesey), Benjamin Monod-Broca

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    905.397107 |    622.194495 | Jagged Fang Designs                                                                                                                                                   |
|   2 |    440.423901 |    722.220583 | NA                                                                                                                                                                    |
|   3 |     87.660062 |    197.217887 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                         |
|   4 |    639.427508 |    288.608343 | Steven Traver                                                                                                                                                         |
|   5 |    605.211733 |    519.745541 | NA                                                                                                                                                                    |
|   6 |    767.709093 |    564.399826 | Margot Michaud                                                                                                                                                        |
|   7 |    145.317957 |    614.978861 | T. Michael Keesey                                                                                                                                                     |
|   8 |    573.390720 |    651.585251 | C. Camilo Julián-Caballero                                                                                                                                            |
|   9 |    910.484436 |    285.903196 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
|  10 |    240.107422 |    631.520139 | Francesca Belem Lopes Palmeira                                                                                                                                        |
|  11 |    881.256612 |    744.461369 | Margot Michaud                                                                                                                                                        |
|  12 |    474.237990 |    452.520726 | Margot Michaud                                                                                                                                                        |
|  13 |    960.688121 |    195.763294 | Scott Hartman                                                                                                                                                         |
|  14 |    606.917133 |    615.281516 | Chris huh                                                                                                                                                             |
|  15 |    447.576079 |    632.399171 | Chris huh                                                                                                                                                             |
|  16 |    685.037603 |    143.835371 | Matt Crook                                                                                                                                                            |
|  17 |    734.225815 |    683.050020 | Zimices                                                                                                                                                               |
|  18 |    421.829663 |    240.955291 | Zimices                                                                                                                                                               |
|  19 |    923.069595 |    532.284795 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  20 |    227.725531 |    300.984805 | Matt Wilkins                                                                                                                                                          |
|  21 |    222.089672 |     33.887948 | Markus A. Grohme                                                                                                                                                      |
|  22 |    310.929940 |    377.861378 | Ferran Sayol                                                                                                                                                          |
|  23 |     99.085265 |    457.742368 | B. Duygu Özpolat                                                                                                                                                      |
|  24 |    223.261730 |    160.325320 | Ferran Sayol                                                                                                                                                          |
|  25 |     31.036577 |    615.642881 | NA                                                                                                                                                                    |
|  26 |    422.346791 |     35.237965 | Caleb M. Brown                                                                                                                                                        |
|  27 |    975.069112 |    121.140120 | Kristina Gagalova                                                                                                                                                     |
|  28 |    425.110517 |    147.940447 | Juan Carlos Jerí                                                                                                                                                      |
|  29 |    742.836438 |    373.528636 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
|  30 |    623.580372 |    396.854719 | Roberto Díaz Sibaja                                                                                                                                                   |
|  31 |    573.376309 |     72.857958 | NA                                                                                                                                                                    |
|  32 |    919.820556 |    452.421345 | Noah Schlottman                                                                                                                                                       |
|  33 |    226.746524 |    423.429887 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
|  34 |    879.215341 |     70.729066 | Fernando Carezzano                                                                                                                                                    |
|  35 |    456.166916 |    348.782579 | Margot Michaud                                                                                                                                                        |
|  36 |    846.105379 |    180.377793 | David Orr                                                                                                                                                             |
|  37 |     93.246632 |    350.743749 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
|  38 |    299.782816 |    716.619381 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
|  39 |    324.099424 |    506.349204 | Katie S. Collins                                                                                                                                                      |
|  40 |    595.710821 |    712.330329 | Matt Crook                                                                                                                                                            |
|  41 |    931.699995 |    335.764678 | C. Camilo Julián-Caballero                                                                                                                                            |
|  42 |     78.742054 |    768.260851 | Gareth Monger                                                                                                                                                         |
|  43 |     69.491434 |    531.116818 | Gareth Monger                                                                                                                                                         |
|  44 |    450.461474 |    560.216024 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  45 |    726.673723 |     18.209988 | Dean Schnabel                                                                                                                                                         |
|  46 |    127.066488 |    286.879995 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  47 |    352.921077 |    198.071320 | John Conway                                                                                                                                                           |
|  48 |    286.510461 |    777.055746 | Zimices                                                                                                                                                               |
|  49 |     69.069016 |     78.399788 | NA                                                                                                                                                                    |
|  50 |    793.121278 |    312.708286 | FJDegrange                                                                                                                                                            |
|  51 |    580.297516 |    446.394977 | Erika Schumacher                                                                                                                                                      |
|  52 |    335.503249 |    618.237364 | Gareth Monger                                                                                                                                                         |
|  53 |    331.541547 |    301.932642 | Gareth Monger                                                                                                                                                         |
|  54 |    520.480440 |    228.706400 | Gareth Monger                                                                                                                                                         |
|  55 |    761.903910 |    184.258217 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
|  56 |    658.835435 |    777.653916 | Gareth Monger                                                                                                                                                         |
|  57 |    937.406825 |    690.445174 | Ingo Braasch                                                                                                                                                          |
|  58 |    723.607026 |    435.694338 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
|  59 |    931.126448 |    594.132349 | Tyler McCraney                                                                                                                                                        |
|  60 |    920.202195 |    786.991575 | NA                                                                                                                                                                    |
|  61 |    804.971700 |    130.978801 | Josefine Bohr Brask                                                                                                                                                   |
|  62 |    841.779429 |    673.077697 | Chris huh                                                                                                                                                             |
|  63 |     62.930022 |    420.087029 | Andrew A. Farke                                                                                                                                                       |
|  64 |    235.951159 |    558.341659 | Ignacio Contreras                                                                                                                                                     |
|  65 |    944.010056 |    386.992134 | Chris huh                                                                                                                                                             |
|  66 |    772.497966 |     69.232120 | Steven Traver                                                                                                                                                         |
|  67 |    104.922427 |    734.547287 | CNZdenek                                                                                                                                                              |
|  68 |     88.521205 |    639.211494 | Birgit Lang                                                                                                                                                           |
|  69 |    355.707651 |     89.713942 | Margot Michaud                                                                                                                                                        |
|  70 |    784.152165 |    776.849051 | Jagged Fang Designs                                                                                                                                                   |
|  71 |    950.681956 |    644.929456 | Ghedoghedo                                                                                                                                                            |
|  72 |    162.970136 |     56.130042 | Gareth Monger                                                                                                                                                         |
|  73 |    447.606488 |     65.034541 | Martin R. Smith                                                                                                                                                       |
|  74 |    864.678364 |    567.837406 | Scott Hartman                                                                                                                                                         |
|  75 |    603.230713 |    749.076412 | Matt Crook                                                                                                                                                            |
|  76 |    128.210013 |    252.079622 | Jagged Fang Designs                                                                                                                                                   |
|  77 |    726.037850 |    219.670285 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  78 |    141.051155 |    385.703678 | Jagged Fang Designs                                                                                                                                                   |
|  79 |    815.239805 |    500.363138 | Scott Hartman                                                                                                                                                         |
|  80 |    194.787160 |     79.546673 | Gareth Monger                                                                                                                                                         |
|  81 |    998.730849 |    751.161530 | Pete Buchholz                                                                                                                                                         |
|  82 |    804.898009 |    449.099251 | Margot Michaud                                                                                                                                                        |
|  83 |    681.571293 |    627.844711 | Jimmy Bernot                                                                                                                                                          |
|  84 |     63.221070 |    135.020847 | Margot Michaud                                                                                                                                                        |
|  85 |    731.712350 |    505.969176 | Becky Barnes                                                                                                                                                          |
|  86 |    193.826447 |    105.341705 | Nobu Tamura                                                                                                                                                           |
|  87 |    699.207638 |    747.987493 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
|  88 |    410.838026 |    611.790775 | Zimices                                                                                                                                                               |
|  89 |    231.554277 |    676.278648 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
|  90 |    665.857437 |    340.561802 | Matt Crook                                                                                                                                                            |
|  91 |    696.766047 |    585.057476 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  92 |    146.500755 |     23.341184 | NA                                                                                                                                                                    |
|  93 |    763.891834 |    740.141784 | Collin Gross                                                                                                                                                          |
|  94 |    188.019284 |    742.556503 | Tasman Dixon                                                                                                                                                          |
|  95 |    830.570566 |    388.949456 | Mike Hanson                                                                                                                                                           |
|  96 |    458.886450 |    258.901697 | Rebecca Groom                                                                                                                                                         |
|  97 |    171.927001 |    501.851224 | Chase Brownstein                                                                                                                                                      |
|  98 |    382.540715 |    586.889077 | Joanna Wolfe                                                                                                                                                          |
|  99 |    705.929354 |     53.753286 | Natalie Claunch                                                                                                                                                       |
| 100 |    129.568382 |    420.625199 | Gareth Monger                                                                                                                                                         |
| 101 |    611.359645 |      8.084534 | Jagged Fang Designs                                                                                                                                                   |
| 102 |   1007.238594 |      5.607320 | Margot Michaud                                                                                                                                                        |
| 103 |    516.717560 |    124.484543 | Scott Hartman                                                                                                                                                         |
| 104 |    999.149921 |     34.742063 | Gareth Monger                                                                                                                                                         |
| 105 |    836.915545 |    698.550394 | Margot Michaud                                                                                                                                                        |
| 106 |    585.283469 |    147.163887 | Steven Traver                                                                                                                                                         |
| 107 |    780.735334 |    717.618091 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 108 |    361.110495 |    121.715628 | Gareth Monger                                                                                                                                                         |
| 109 |    530.202743 |    405.400849 | Markus A. Grohme                                                                                                                                                      |
| 110 |   1005.641916 |    261.695103 | Sarah Werning                                                                                                                                                         |
| 111 |    703.545623 |    548.319649 | Matt Martyniuk                                                                                                                                                        |
| 112 |    373.894871 |    744.351748 | Steven Coombs                                                                                                                                                         |
| 113 |    378.569701 |    687.711372 | Zimices                                                                                                                                                               |
| 114 |    966.224283 |    239.384284 | S.Martini                                                                                                                                                             |
| 115 |    484.720044 |    667.637099 | S.Martini                                                                                                                                                             |
| 116 |    789.186767 |    410.867450 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 117 |    544.524282 |    670.061693 | Chuanixn Yu                                                                                                                                                           |
| 118 |    559.972612 |    377.867209 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 119 |    151.442155 |    270.577573 | Sarah Werning                                                                                                                                                         |
| 120 |    582.834818 |    638.548981 | T. Michael Keesey                                                                                                                                                     |
| 121 |    848.922014 |     38.916138 | Jagged Fang Designs                                                                                                                                                   |
| 122 |    213.732043 |    492.766054 | Smokeybjb                                                                                                                                                             |
| 123 |    947.950671 |    630.881112 | T. Michael Keesey                                                                                                                                                     |
| 124 |    978.079654 |    549.174629 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 125 |    436.321640 |    771.249544 | NA                                                                                                                                                                    |
| 126 |    995.637290 |    342.272626 | Steven Traver                                                                                                                                                         |
| 127 |    389.468963 |    483.211087 | Christine Axon                                                                                                                                                        |
| 128 |    647.461484 |    636.960843 | Ferran Sayol                                                                                                                                                          |
| 129 |    373.085210 |    304.741568 | Rebecca Groom                                                                                                                                                         |
| 130 |    179.387344 |    425.297201 | Mette Aumala                                                                                                                                                          |
| 131 |    408.699439 |    352.867182 | T. Michael Keesey                                                                                                                                                     |
| 132 |    336.625106 |    679.390817 | Markus A. Grohme                                                                                                                                                      |
| 133 |    144.852413 |    307.895344 | Scott Hartman                                                                                                                                                         |
| 134 |    510.147089 |    620.771270 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 135 |    934.324999 |    483.764174 | Tauana J. Cunha                                                                                                                                                       |
| 136 |    618.726276 |    155.323120 | Christoph Schomburg                                                                                                                                                   |
| 137 |    366.786994 |    766.517737 | Anthony Caravaggi                                                                                                                                                     |
| 138 |    586.866100 |    590.774019 | Matt Crook                                                                                                                                                            |
| 139 |    727.687406 |    417.182936 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 140 |    387.110564 |    279.421418 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 141 |    352.261756 |    433.228645 | Ingo Braasch                                                                                                                                                          |
| 142 |    808.575593 |    722.073988 | Matt Crook                                                                                                                                                            |
| 143 |     51.586332 |    393.142507 | Margot Michaud                                                                                                                                                        |
| 144 |     58.715688 |    155.944493 | Margot Michaud                                                                                                                                                        |
| 145 |    671.311719 |    190.211196 | Henry Lydecker                                                                                                                                                        |
| 146 |    306.863434 |    305.153641 | Margot Michaud                                                                                                                                                        |
| 147 |   1003.834247 |    292.451585 | Margot Michaud                                                                                                                                                        |
| 148 |    350.124949 |    140.207824 | T. Michael Keesey                                                                                                                                                     |
| 149 |    988.209736 |    781.747053 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 150 |    441.665354 |    599.006279 | Margot Michaud                                                                                                                                                        |
| 151 |    215.213767 |    475.877949 | Zimices                                                                                                                                                               |
| 152 |    665.057494 |    590.080992 | Zimices                                                                                                                                                               |
| 153 |    389.580656 |    787.331043 | Jagged Fang Designs                                                                                                                                                   |
| 154 |    134.332408 |    549.564609 | Margot Michaud                                                                                                                                                        |
| 155 |    444.171571 |    606.763117 | T. Michael Keesey                                                                                                                                                     |
| 156 |    316.928344 |    646.800030 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 157 |    736.507695 |    793.596423 | Scott Hartman                                                                                                                                                         |
| 158 |    576.123534 |    213.890746 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 159 |    507.106959 |    435.580743 | Tracy A. Heath                                                                                                                                                        |
| 160 |    597.033344 |    314.741831 | Andy Wilson                                                                                                                                                           |
| 161 |    951.322597 |    539.331450 | Bennet McComish, photo by Avenue                                                                                                                                      |
| 162 |    706.004563 |    494.287236 | Jagged Fang Designs                                                                                                                                                   |
| 163 |    533.824365 |    370.262209 | Birgit Lang                                                                                                                                                           |
| 164 |    357.574322 |    726.753518 | Markus A. Grohme                                                                                                                                                      |
| 165 |    288.175007 |    268.954787 | Andrew A. Farke                                                                                                                                                       |
| 166 |    494.346125 |    129.020909 | Ingo Braasch                                                                                                                                                          |
| 167 |    286.710489 |    221.137737 | Tauana J. Cunha                                                                                                                                                       |
| 168 |    926.866113 |    310.160875 | Steven Traver                                                                                                                                                         |
| 169 |    126.575676 |    789.625250 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 170 |    101.882165 |    656.595971 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 171 |    232.231538 |    523.864029 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 172 |    534.368076 |    729.125578 | Zimices                                                                                                                                                               |
| 173 |    840.699372 |     92.189076 | Margot Michaud                                                                                                                                                        |
| 174 |    869.901995 |     35.996789 | Jagged Fang Designs                                                                                                                                                   |
| 175 |    457.662248 |    654.363503 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 176 |    140.464268 |    112.511502 | Matt Crook                                                                                                                                                            |
| 177 |     18.868523 |    104.315819 | Erika Schumacher                                                                                                                                                      |
| 178 |    866.888241 |    367.281480 | Ferran Sayol                                                                                                                                                          |
| 179 |    805.055621 |    740.999426 | Juan Carlos Jerí                                                                                                                                                      |
| 180 |    389.631183 |    404.222180 | NA                                                                                                                                                                    |
| 181 |    114.694762 |    442.579035 | Xavier Giroux-Bougard                                                                                                                                                 |
| 182 |    147.766764 |    714.872845 | Tasman Dixon                                                                                                                                                          |
| 183 |    948.950600 |     68.072092 | Ferran Sayol                                                                                                                                                          |
| 184 |    219.404898 |     14.756741 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 185 |   1005.209562 |    554.422283 | Matt Crook                                                                                                                                                            |
| 186 |    811.505336 |    611.995013 | NA                                                                                                                                                                    |
| 187 |    591.422986 |    230.545462 | Gareth Monger                                                                                                                                                         |
| 188 |    861.853913 |    269.296296 | NA                                                                                                                                                                    |
| 189 |    250.248433 |    525.356754 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 190 |    674.785079 |    484.411099 | Matt Dempsey                                                                                                                                                          |
| 191 |    964.448276 |    426.341445 | Martin Kevil                                                                                                                                                          |
| 192 |    532.661166 |    576.088140 | Andy Wilson                                                                                                                                                           |
| 193 |    669.050535 |    539.594975 | Jack Mayer Wood                                                                                                                                                       |
| 194 |    585.497602 |    352.597307 | Andy Wilson                                                                                                                                                           |
| 195 |    813.770561 |    388.978439 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 196 |    854.222163 |    537.142676 | Jack Mayer Wood                                                                                                                                                       |
| 197 |    802.429932 |    270.269684 | Roderic Page and Lois Page                                                                                                                                            |
| 198 |    524.710933 |    146.137291 | Harold N Eyster                                                                                                                                                       |
| 199 |    982.953483 |    651.185273 | T. Michael Keesey                                                                                                                                                     |
| 200 |    974.830864 |    665.497355 | Birgit Lang                                                                                                                                                           |
| 201 |   1012.055078 |    527.470848 | T. Michael Keesey                                                                                                                                                     |
| 202 |    237.418332 |    732.029757 | Gareth Monger                                                                                                                                                         |
| 203 |     23.265134 |    454.478573 | Gareth Monger                                                                                                                                                         |
| 204 |    414.603201 |    712.353495 | Zimices                                                                                                                                                               |
| 205 |    191.580002 |    269.924756 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 206 |    655.091449 |    412.232013 | Tyler Greenfield                                                                                                                                                      |
| 207 |    123.823069 |    201.760026 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 208 |     87.298468 |    471.254170 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 209 |   1008.026250 |    303.343833 | Michael Day                                                                                                                                                           |
| 210 |    340.755829 |     60.845728 | Andy Wilson                                                                                                                                                           |
| 211 |    461.046370 |    302.740410 | Jiekun He                                                                                                                                                             |
| 212 |    460.160310 |    791.335815 | Andy Wilson                                                                                                                                                           |
| 213 |    529.889330 |    269.472780 | Margot Michaud                                                                                                                                                        |
| 214 |     80.312449 |    686.322024 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 215 |    335.273671 |    587.366546 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 216 |    774.135150 |    519.869554 | Crystal Maier                                                                                                                                                         |
| 217 |    215.360279 |    702.739061 | JCGiron                                                                                                                                                               |
| 218 |    171.526720 |    776.551863 | Ferran Sayol                                                                                                                                                          |
| 219 |     14.235667 |    330.689140 | NA                                                                                                                                                                    |
| 220 |    186.415703 |    744.698027 | Amanda Katzer                                                                                                                                                         |
| 221 |    905.387791 |    305.199575 | Jagged Fang Designs                                                                                                                                                   |
| 222 |      8.389266 |    635.521633 | Ferran Sayol                                                                                                                                                          |
| 223 |    625.021166 |    104.533472 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 224 |    699.574547 |    470.952395 | M Kolmann                                                                                                                                                             |
| 225 |    532.541705 |    175.884221 | T. Michael Keesey                                                                                                                                                     |
| 226 |    360.566244 |    213.853281 | Tasman Dixon                                                                                                                                                          |
| 227 |    860.644078 |    250.845540 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 228 |    819.465169 |     23.717972 | Sarah Werning                                                                                                                                                         |
| 229 |    312.212434 |     37.182489 | Matt Crook                                                                                                                                                            |
| 230 |   1004.288694 |    321.942270 | Carlos Cano-Barbacil                                                                                                                                                  |
| 231 |    392.443084 |    297.763727 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 232 |    460.408822 |    512.465384 | Chris huh                                                                                                                                                             |
| 233 |    941.484548 |    298.744300 | Jonathan Wells                                                                                                                                                        |
| 234 |    534.334560 |    631.592973 | NA                                                                                                                                                                    |
| 235 |    809.106699 |    415.983352 | Steven Traver                                                                                                                                                         |
| 236 |    975.598541 |    365.825248 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 237 |    461.761623 |     41.632680 | Chloé Schmidt                                                                                                                                                         |
| 238 |    118.146847 |    570.405472 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 239 |    398.405315 |    431.994712 | Jagged Fang Designs                                                                                                                                                   |
| 240 |    479.862700 |    136.304025 | NA                                                                                                                                                                    |
| 241 |    158.387897 |    358.290099 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 242 |    677.222969 |    572.105075 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 243 |    529.961040 |    781.729881 | Matt Crook                                                                                                                                                            |
| 244 |    173.103015 |    475.973608 | Matt Crook                                                                                                                                                            |
| 245 |    682.836805 |    162.315919 | Sean McCann                                                                                                                                                           |
| 246 |    603.264511 |    712.433323 | NA                                                                                                                                                                    |
| 247 |    562.340803 |    201.671102 | Birgit Lang                                                                                                                                                           |
| 248 |     42.429074 |    728.612431 | NA                                                                                                                                                                    |
| 249 |    538.792018 |    522.354939 | Matt Crook                                                                                                                                                            |
| 250 |    576.604729 |    739.435841 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 251 |    868.013706 |     16.527218 | Steven Traver                                                                                                                                                         |
| 252 |    678.321994 |    389.962106 | Birgit Lang                                                                                                                                                           |
| 253 |    572.994703 |    369.395983 | wsnaccad                                                                                                                                                              |
| 254 |     51.359415 |     16.303075 | Ferran Sayol                                                                                                                                                          |
| 255 |    746.057507 |    288.107633 | L. Shyamal                                                                                                                                                            |
| 256 |    495.305411 |    702.405809 | Jagged Fang Designs                                                                                                                                                   |
| 257 |    994.402611 |    283.409343 | Margot Michaud                                                                                                                                                        |
| 258 |    535.711252 |    315.859583 | Jessica Anne Miller                                                                                                                                                   |
| 259 |    703.280610 |    480.484898 | Steven Traver                                                                                                                                                         |
| 260 |    292.062673 |    237.449013 | NA                                                                                                                                                                    |
| 261 |    316.225641 |    562.539794 | Julio Garza                                                                                                                                                           |
| 262 |     26.236904 |    710.188485 | Maija Karala                                                                                                                                                          |
| 263 |    125.227688 |    468.522826 | Zimices                                                                                                                                                               |
| 264 |    181.868280 |    483.527458 | Matt Crook                                                                                                                                                            |
| 265 |    494.992859 |    518.988715 | Margot Michaud                                                                                                                                                        |
| 266 |     21.358863 |    509.010609 | Gareth Monger                                                                                                                                                         |
| 267 |    113.766293 |    757.952922 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 268 |    668.265573 |     74.059859 | Zimices                                                                                                                                                               |
| 269 |    788.358247 |     23.528170 | Zimices                                                                                                                                                               |
| 270 |    134.443404 |     65.571093 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 271 |    968.033791 |    734.596438 | Katie S. Collins                                                                                                                                                      |
| 272 |     45.800228 |    380.129927 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 273 |    546.272186 |    498.438399 | Dean Schnabel                                                                                                                                                         |
| 274 |    321.818166 |    334.576833 | Terpsichores                                                                                                                                                          |
| 275 |    397.466587 |    460.067391 | Margot Michaud                                                                                                                                                        |
| 276 |    499.621159 |    188.092763 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 277 |    205.062673 |    441.807493 | Steven Traver                                                                                                                                                         |
| 278 |    391.905743 |    561.464995 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                     |
| 279 |    346.544060 |     71.716242 | Emily Willoughby                                                                                                                                                      |
| 280 |    471.844424 |    586.556691 | Zimices                                                                                                                                                               |
| 281 |    918.070594 |    669.634664 | Zimices                                                                                                                                                               |
| 282 |    783.028210 |    602.662437 | Matt Crook                                                                                                                                                            |
| 283 |    131.114375 |    321.249017 | Steven Traver                                                                                                                                                         |
| 284 |    126.296113 |    558.348070 | NA                                                                                                                                                                    |
| 285 |    956.717043 |    267.053168 | Matt Crook                                                                                                                                                            |
| 286 |    687.789318 |    422.166169 | Matt Crook                                                                                                                                                            |
| 287 |    984.756285 |    576.033704 | NA                                                                                                                                                                    |
| 288 |    104.430759 |    229.549136 | NA                                                                                                                                                                    |
| 289 |    667.515404 |    419.205248 | Steven Traver                                                                                                                                                         |
| 290 |    164.816515 |    449.940234 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 291 |     92.027208 |    207.599011 | Campbell Fleming                                                                                                                                                      |
| 292 |     60.315739 |    257.730082 | Catherine Yasuda                                                                                                                                                      |
| 293 |    127.783939 |    442.418228 | Margot Michaud                                                                                                                                                        |
| 294 |    626.903566 |     69.220107 | Ferran Sayol                                                                                                                                                          |
| 295 |    975.780163 |    293.289304 | Emma Kissling                                                                                                                                                         |
| 296 |    654.184865 |    314.520727 | Matt Crook                                                                                                                                                            |
| 297 |    468.539933 |    289.723064 | Margot Michaud                                                                                                                                                        |
| 298 |    343.547671 |    453.387897 | Birgit Lang                                                                                                                                                           |
| 299 |    647.216029 |    658.747742 | Chris huh                                                                                                                                                             |
| 300 |     51.541286 |    287.673103 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 301 |    101.193222 |    180.619364 | Ferran Sayol                                                                                                                                                          |
| 302 |    492.301597 |    651.736841 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 303 |    990.570335 |    434.609704 | Steven Traver                                                                                                                                                         |
| 304 |    766.976139 |    212.262917 | NA                                                                                                                                                                    |
| 305 |   1000.011612 |    463.777890 | FunkMonk                                                                                                                                                              |
| 306 |    551.954438 |    719.367290 | Kamil S. Jaron                                                                                                                                                        |
| 307 |    179.922598 |    413.122679 | Gareth Monger                                                                                                                                                         |
| 308 |     98.404600 |     35.029078 | Sarah Werning                                                                                                                                                         |
| 309 |     46.542591 |    499.532461 | Ingo Braasch                                                                                                                                                          |
| 310 |    942.208713 |    369.670964 | Matt Crook                                                                                                                                                            |
| 311 |    308.968775 |    154.738525 | G. M. Woodward                                                                                                                                                        |
| 312 |    975.555087 |     39.125087 | Margot Michaud                                                                                                                                                        |
| 313 |    887.921166 |    124.434672 | Andy Wilson                                                                                                                                                           |
| 314 |    619.715952 |    566.444122 | Chris huh                                                                                                                                                             |
| 315 |    388.721626 |    380.350812 | NA                                                                                                                                                                    |
| 316 |    914.720033 |    363.486044 | Jagged Fang Designs                                                                                                                                                   |
| 317 |     53.871545 |    372.402347 | NA                                                                                                                                                                    |
| 318 |     93.020289 |     14.726036 | NA                                                                                                                                                                    |
| 319 |     61.205262 |    269.301477 | Jaime Headden                                                                                                                                                         |
| 320 |    354.185919 |    669.837508 | Zimices                                                                                                                                                               |
| 321 |    538.005536 |    476.479782 | Sarah Werning                                                                                                                                                         |
| 322 |    540.454778 |    355.405470 | Maija Karala                                                                                                                                                          |
| 323 |    405.100084 |    473.050800 | Ludwik Gąsiorowski                                                                                                                                                    |
| 324 |    655.199964 |    759.518843 | Chloé Schmidt                                                                                                                                                         |
| 325 |   1019.318765 |    212.012550 | NA                                                                                                                                                                    |
| 326 |    841.396490 |    262.469100 | Roberto Díaz Sibaja                                                                                                                                                   |
| 327 |    688.341116 |    341.907290 | T. Michael Keesey                                                                                                                                                     |
| 328 |    823.211405 |    193.850487 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 329 |    266.820359 |     52.691102 | NA                                                                                                                                                                    |
| 330 |    572.652332 |    189.877025 | Ferran Sayol                                                                                                                                                          |
| 331 |     57.162036 |    122.791906 | Andrew A. Farke                                                                                                                                                       |
| 332 |    979.715148 |    762.164583 | Steven Traver                                                                                                                                                         |
| 333 |    957.446280 |    663.405150 | Matt Crook                                                                                                                                                            |
| 334 |     19.442487 |    730.050134 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 335 |    410.594024 |    291.285561 | Xavier Giroux-Bougard                                                                                                                                                 |
| 336 |    833.479467 |    236.470320 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 337 |    532.144803 |    390.425079 | Sarah Werning                                                                                                                                                         |
| 338 |    493.582310 |    203.232272 | Steven Traver                                                                                                                                                         |
| 339 |    603.952574 |    638.603465 | Caleb M. Brown                                                                                                                                                        |
| 340 |     47.983562 |    549.891089 | NA                                                                                                                                                                    |
| 341 |    630.385380 |    413.433418 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 342 |   1001.605549 |    231.235898 | Maija Karala                                                                                                                                                          |
| 343 |    737.322521 |     93.466963 | NA                                                                                                                                                                    |
| 344 |    381.030147 |    135.938989 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 345 |    206.529800 |    500.413353 | NA                                                                                                                                                                    |
| 346 |    253.527968 |    754.502550 | Cesar Julian                                                                                                                                                          |
| 347 |    632.078040 |    368.805576 | NA                                                                                                                                                                    |
| 348 |    480.546150 |     88.999448 | Zimices                                                                                                                                                               |
| 349 |    783.237032 |    789.837258 | Jack Mayer Wood                                                                                                                                                       |
| 350 |    137.263981 |    238.170674 | Zimices                                                                                                                                                               |
| 351 |    222.199979 |    763.797132 | NA                                                                                                                                                                    |
| 352 |    476.791055 |    240.041935 | Anthony Caravaggi                                                                                                                                                     |
| 353 |    580.260246 |    337.762528 | Matt Crook                                                                                                                                                            |
| 354 |    854.190795 |    305.563677 | L. Shyamal                                                                                                                                                            |
| 355 |    325.987383 |     57.142103 | Margot Michaud                                                                                                                                                        |
| 356 |    499.778048 |    729.335782 | Matt Crook                                                                                                                                                            |
| 357 |    164.255467 |    790.484359 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 358 |    807.864030 |    401.615048 | Scott Hartman                                                                                                                                                         |
| 359 |    877.086256 |    244.714506 | Margot Michaud                                                                                                                                                        |
| 360 |    102.830879 |    571.563123 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 361 |    783.382696 |    667.616645 | Jagged Fang Designs                                                                                                                                                   |
| 362 |    941.009584 |    725.196246 | T. Michael Keesey                                                                                                                                                     |
| 363 |    342.247661 |    766.597512 | kotik                                                                                                                                                                 |
| 364 |    237.231059 |    714.868172 | Scott Hartman                                                                                                                                                         |
| 365 |    957.238079 |    487.812197 | Matt Crook                                                                                                                                                            |
| 366 |   1006.104930 |    355.320459 | Matt Crook                                                                                                                                                            |
| 367 |    173.863620 |    432.031200 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 368 |    709.083278 |    392.309429 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 369 |    508.341541 |    160.175471 | Margot Michaud                                                                                                                                                        |
| 370 |    996.132035 |    573.266221 | Cesar Julian                                                                                                                                                          |
| 371 |    334.311133 |    427.623976 | Tasman Dixon                                                                                                                                                          |
| 372 |    893.094812 |    675.901612 | Ingo Braasch                                                                                                                                                          |
| 373 |    674.879566 |    557.859088 | Oscar Sanisidro                                                                                                                                                       |
| 374 |    519.084197 |    103.959305 | Henry Lydecker                                                                                                                                                        |
| 375 |    113.731179 |    196.153963 | Emily Willoughby                                                                                                                                                      |
| 376 |    959.181448 |    396.808365 | Matt Crook                                                                                                                                                            |
| 377 |    101.499138 |    753.979996 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 378 |    114.895794 |    673.532236 | Chris huh                                                                                                                                                             |
| 379 |    620.425336 |    221.030928 | xgirouxb                                                                                                                                                              |
| 380 |   1006.414305 |    505.728387 | Ferran Sayol                                                                                                                                                          |
| 381 |    403.284095 |    271.904308 | T. Michael Keesey                                                                                                                                                     |
| 382 |    993.456082 |     64.753709 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 383 |    829.750333 |    156.868298 | Andy Wilson                                                                                                                                                           |
| 384 |    952.370431 |    572.974595 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 385 |    847.389801 |    287.436317 | Margot Michaud                                                                                                                                                        |
| 386 |    908.531754 |      5.314306 | Geoff Shaw                                                                                                                                                            |
| 387 |    588.088010 |    373.630132 | T. Michael Keesey                                                                                                                                                     |
| 388 |     11.854719 |    131.607911 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 389 |   1006.254626 |    725.639088 | Chris A. Hamilton                                                                                                                                                     |
| 390 |    437.633972 |    505.498781 | Chris huh                                                                                                                                                             |
| 391 |    368.581132 |    290.147918 | Ferran Sayol                                                                                                                                                          |
| 392 |    157.453639 |     96.755274 | Kai R. Caspar                                                                                                                                                         |
| 393 |    956.477357 |    557.742456 | T. Michael Keesey                                                                                                                                                     |
| 394 |    482.588858 |    152.177457 | Tauana J. Cunha                                                                                                                                                       |
| 395 |    375.706503 |    472.132673 | Felix Vaux                                                                                                                                                            |
| 396 |    787.098116 |    696.819824 | Steven Traver                                                                                                                                                         |
| 397 |    356.766992 |    719.556212 | Collin Gross                                                                                                                                                          |
| 398 |    743.147690 |    395.332866 | Julio Garza                                                                                                                                                           |
| 399 |    861.253061 |    348.710378 | Markus A. Grohme                                                                                                                                                      |
| 400 |    884.003268 |    372.910408 | Kai R. Caspar                                                                                                                                                         |
| 401 |    791.065388 |    477.056160 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 402 |    957.152394 |    730.960355 | Kamil S. Jaron                                                                                                                                                        |
| 403 |    509.236579 |    764.323971 | Gareth Monger                                                                                                                                                         |
| 404 |    923.451848 |     43.085558 | NASA                                                                                                                                                                  |
| 405 |    505.326139 |    114.014858 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 406 |    434.526448 |     89.724284 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 407 |    415.637732 |    391.194791 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 408 |    853.270506 |     27.225309 | Michael Scroggie                                                                                                                                                      |
| 409 |    303.473272 |    319.575754 | Matt Crook                                                                                                                                                            |
| 410 |    975.710319 |    709.468268 | Andrew A. Farke                                                                                                                                                       |
| 411 |    228.343626 |    503.537215 | Andrew A. Farke                                                                                                                                                       |
| 412 |    423.425144 |    485.343739 | Zimices                                                                                                                                                               |
| 413 |     66.442555 |    676.282587 | Ferran Sayol                                                                                                                                                          |
| 414 |    308.085150 |    759.419299 | Michelle Site                                                                                                                                                         |
| 415 |     29.410013 |    743.189518 | (after McCulloch 1908)                                                                                                                                                |
| 416 |    503.673679 |    696.128786 | Zimices                                                                                                                                                               |
| 417 |    986.341966 |    676.839185 | Margot Michaud                                                                                                                                                        |
| 418 |    753.345385 |    522.056302 | Margot Michaud                                                                                                                                                        |
| 419 |    928.970189 |    408.737020 | Lukasiniho                                                                                                                                                            |
| 420 |    475.906155 |    761.494151 | Zimices                                                                                                                                                               |
| 421 |    610.264746 |    343.871448 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 422 |    313.757281 |      6.382122 | Tracy A. Heath                                                                                                                                                        |
| 423 |    738.754521 |    343.500374 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 424 |    456.263065 |     91.760836 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 425 |    504.253320 |    676.548422 | Maxime Dahirel                                                                                                                                                        |
| 426 |    238.055418 |     58.782553 | Roberto Díaz Sibaja                                                                                                                                                   |
| 427 |    197.964839 |    731.310567 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 428 |    562.174363 |    586.053794 | Michelle Site                                                                                                                                                         |
| 429 |    845.627574 |    166.538910 | Ingo Braasch                                                                                                                                                          |
| 430 |    668.656624 |    518.545460 | Dean Schnabel                                                                                                                                                         |
| 431 |     93.660437 |    418.262240 | Ferran Sayol                                                                                                                                                          |
| 432 |    475.006921 |    733.371450 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 433 |    660.223142 |     33.055835 | Harold N Eyster                                                                                                                                                       |
| 434 |    621.359400 |    199.183719 | Steven Traver                                                                                                                                                         |
| 435 |    922.972123 |    105.814854 | Steven Traver                                                                                                                                                         |
| 436 |    767.154626 |    224.283412 | Gareth Monger                                                                                                                                                         |
| 437 |     33.274805 |    776.096062 | Andy Wilson                                                                                                                                                           |
| 438 |    604.801005 |    412.423107 | Becky Barnes                                                                                                                                                          |
| 439 |    492.934167 |    603.793514 | T. Michael Keesey                                                                                                                                                     |
| 440 |    309.888054 |    671.826514 | Matt Wilkins                                                                                                                                                          |
| 441 |    169.022999 |    373.231220 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 442 |    524.173846 |     17.384922 | Sarah Werning                                                                                                                                                         |
| 443 |     19.871176 |    294.203166 | Ignacio Contreras                                                                                                                                                     |
| 444 |    533.854035 |    608.758998 | Tasman Dixon                                                                                                                                                          |
| 445 |    400.775207 |    728.555723 | CNZdenek                                                                                                                                                              |
| 446 |    664.328499 |    645.757083 | Julio Garza                                                                                                                                                           |
| 447 |    237.830060 |    743.664066 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 448 |    893.168052 |    605.522788 | Scott Hartman                                                                                                                                                         |
| 449 |      9.313567 |    266.188389 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 450 |    896.338541 |     14.558837 | Neil Kelley                                                                                                                                                           |
| 451 |    427.045906 |    211.599680 | Chris huh                                                                                                                                                             |
| 452 |    876.222599 |    122.666749 | Matt Crook                                                                                                                                                            |
| 453 |     14.699182 |     19.385731 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 454 |    276.584547 |    318.241156 | NA                                                                                                                                                                    |
| 455 |    215.514013 |     90.417609 | Zimices                                                                                                                                                               |
| 456 |    257.478079 |    503.578048 | Ingo Braasch                                                                                                                                                          |
| 457 |    525.865589 |    688.312714 | David Orr                                                                                                                                                             |
| 458 |    513.289018 |    702.531854 | Scott Hartman                                                                                                                                                         |
| 459 |    868.318529 |     52.276828 | Ferran Sayol                                                                                                                                                          |
| 460 |    811.227729 |    753.224099 | Chase Brownstein                                                                                                                                                      |
| 461 |     88.968292 |    267.449603 | Margot Michaud                                                                                                                                                        |
| 462 |    345.066591 |    566.867299 | T. Michael Keesey                                                                                                                                                     |
| 463 |    862.507780 |    638.005885 | Collin Gross                                                                                                                                                          |
| 464 |    516.288250 |     63.978569 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 465 |     56.270539 |    224.201792 | Jagged Fang Designs                                                                                                                                                   |
| 466 |    107.995316 |    211.023037 | Marie Russell                                                                                                                                                         |
| 467 |    522.008189 |    582.488938 | T. Michael Keesey                                                                                                                                                     |
| 468 |    174.265110 |    132.483468 | Joanna Wolfe                                                                                                                                                          |
| 469 |    833.533099 |    547.860380 | Carlos Cano-Barbacil                                                                                                                                                  |
| 470 |    539.977995 |    597.592059 | Tracy A. Heath                                                                                                                                                        |
| 471 |    517.367248 |    177.069024 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 472 |    194.630422 |    471.912765 | C. Camilo Julián-Caballero                                                                                                                                            |
| 473 |    725.295870 |    403.646838 | Kamil S. Jaron                                                                                                                                                        |
| 474 |    363.231575 |    236.797166 | Jaime Headden                                                                                                                                                         |
| 475 |    317.732775 |    113.350928 | Ignacio Contreras                                                                                                                                                     |
| 476 |    818.064268 |    728.671043 | Siobhon Egan                                                                                                                                                          |
| 477 |    141.018815 |    404.680685 | Zimices                                                                                                                                                               |
| 478 |    441.694639 |    289.037593 | Maxime Dahirel                                                                                                                                                        |
| 479 |    532.554629 |    620.824322 | NA                                                                                                                                                                    |
| 480 |    755.344398 |    400.283481 | Tasman Dixon                                                                                                                                                          |
| 481 |    956.395611 |     93.030715 | Mathieu Pélissié                                                                                                                                                      |
| 482 |    388.530537 |    355.609379 | Zimices                                                                                                                                                               |
| 483 |    288.436910 |    449.092508 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 484 |    345.568099 |     51.260393 | Margot Michaud                                                                                                                                                        |
| 485 |    986.560412 |    498.306896 | Jack Mayer Wood                                                                                                                                                       |
| 486 |    867.807649 |    693.531024 | Zimices                                                                                                                                                               |
| 487 |      9.078424 |    593.477456 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 488 |      8.913411 |    378.165138 | Tony Ayling                                                                                                                                                           |
| 489 |   1002.906976 |    701.411772 | Margot Michaud                                                                                                                                                        |
| 490 |    647.641822 |     54.666958 | Gareth Monger                                                                                                                                                         |
| 491 |    687.212376 |    499.403197 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 492 |    920.239148 |    709.313844 | Shyamal                                                                                                                                                               |
| 493 |    363.270564 |    135.652687 | Gareth Monger                                                                                                                                                         |
| 494 |     15.616262 |    445.916801 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 495 |    830.636487 |    176.572383 | Sarah Werning                                                                                                                                                         |
| 496 |    152.928949 |    415.995961 | Ferran Sayol                                                                                                                                                          |
| 497 |    999.431263 |    414.270247 | Michael Scroggie                                                                                                                                                      |
| 498 |    955.371449 |    407.820321 | Scott Hartman                                                                                                                                                         |
| 499 |    162.845835 |    112.833991 | Matt Martyniuk                                                                                                                                                        |
| 500 |    478.642989 |    214.915976 | Jagged Fang Designs                                                                                                                                                   |
| 501 |    417.896416 |    406.280915 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 502 |    321.466528 |    348.253287 | Carlos Cano-Barbacil                                                                                                                                                  |
| 503 |    861.824848 |    383.921494 | xgirouxb                                                                                                                                                              |
| 504 |    410.199910 |    490.174722 | Felix Vaux                                                                                                                                                            |
| 505 |    337.805065 |    653.166128 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 506 |    253.782224 |    566.192479 | Matt Martyniuk                                                                                                                                                        |
| 507 |    935.735262 |     10.595056 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 508 |    937.896138 |    668.435256 | Tasman Dixon                                                                                                                                                          |
| 509 |    825.549535 |    790.672714 | Matt Crook                                                                                                                                                            |
| 510 |    599.670450 |    193.867102 | Andy Wilson                                                                                                                                                           |
| 511 |    754.675668 |    709.655382 | Erika Schumacher                                                                                                                                                      |
| 512 |    800.911691 |    356.214591 | Gareth Monger                                                                                                                                                         |
| 513 |     81.677808 |    713.188066 | Chris huh                                                                                                                                                             |
| 514 |    903.319937 |    402.752151 | Jagged Fang Designs                                                                                                                                                   |
| 515 |    330.216550 |    179.709352 | Zimices                                                                                                                                                               |
| 516 |    624.960677 |     54.466524 | Mathilde Cordellier                                                                                                                                                   |
| 517 |    678.954478 |     37.333034 | xgirouxb                                                                                                                                                              |
| 518 |     32.941172 |    245.323772 | Andy Wilson                                                                                                                                                           |
| 519 |    658.544127 |    639.084392 | Allison Pease                                                                                                                                                         |
| 520 |   1015.701972 |    779.956126 | (after McCulloch 1908)                                                                                                                                                |
| 521 |    819.696467 |    270.369887 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 522 |    351.575775 |    180.197662 | Yan Wong                                                                                                                                                              |
| 523 |    849.815769 |    316.187944 | Julien Louys                                                                                                                                                          |
| 524 |    142.858622 |    373.264242 | Jaime Headden                                                                                                                                                         |
| 525 |    187.492967 |    525.180179 | Kai R. Caspar                                                                                                                                                         |
| 526 |    755.587920 |    354.545835 | Yan Wong                                                                                                                                                              |
| 527 |    801.417256 |    637.010998 | Gareth Monger                                                                                                                                                         |
| 528 |    474.927678 |     22.816458 | NA                                                                                                                                                                    |
| 529 |    842.094119 |    621.374200 | Scott Hartman                                                                                                                                                         |
| 530 |     56.421939 |    794.495638 | Zimices                                                                                                                                                               |
| 531 |    659.413085 |     83.174589 | Zimices                                                                                                                                                               |
| 532 |    442.670542 |    302.341799 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 533 |    588.037461 |    792.266349 | Mathieu Pélissié                                                                                                                                                      |
| 534 |    504.662207 |    755.562747 | Chris huh                                                                                                                                                             |
| 535 |    564.143979 |    691.871051 | Gareth Monger                                                                                                                                                         |
| 536 |    703.580373 |    647.600247 | Jagged Fang Designs                                                                                                                                                   |
| 537 |    963.231974 |    458.956322 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 538 |     32.337041 |      4.379779 | Scott Hartman                                                                                                                                                         |
| 539 |    482.455866 |    773.184967 | Nicolas Mongiardino Koch                                                                                                                                              |
| 540 |    529.869266 |    341.162104 | Markus A. Grohme                                                                                                                                                      |
| 541 |    993.672000 |    603.615280 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 542 |    683.117924 |     65.215160 | Jimmy Bernot                                                                                                                                                          |
| 543 |     31.683730 |    359.836600 | Scott Hartman                                                                                                                                                         |
| 544 |    416.477881 |    372.932264 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 545 |    913.465334 |    120.563077 | Matt Crook                                                                                                                                                            |
| 546 |    807.774484 |    514.306606 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 547 |    993.502009 |    492.752055 | Zimices                                                                                                                                                               |
| 548 |    523.950456 |    565.042684 | Ferran Sayol                                                                                                                                                          |
| 549 |    958.137697 |     54.771718 | Matt Crook                                                                                                                                                            |
| 550 |    973.536031 |    487.782194 | Christoph Schomburg                                                                                                                                                   |
| 551 |    985.846417 |    476.353802 | Mareike C. Janiak                                                                                                                                                     |
| 552 |    145.073778 |    495.950155 | Matt Crook                                                                                                                                                            |
| 553 |     75.166866 |    577.246872 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 554 |    256.151795 |    385.397887 | Michael Scroggie                                                                                                                                                      |
| 555 |    916.416889 |    704.105686 | Andy Wilson                                                                                                                                                           |
| 556 |    665.280190 |    371.627181 | Chase Brownstein                                                                                                                                                      |
| 557 |    378.351649 |    324.019165 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 558 |    964.756318 |    769.463489 | Matt Crook                                                                                                                                                            |
| 559 |    280.084786 |    279.807238 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 560 |     96.929604 |     63.315895 | Zimices                                                                                                                                                               |
| 561 |    100.813704 |    303.810715 | Maija Karala                                                                                                                                                          |
| 562 |    613.200538 |    318.380953 | Matt Crook                                                                                                                                                            |
| 563 |    496.905072 |    220.726693 | Matt Crook                                                                                                                                                            |
| 564 |    316.230922 |    228.296827 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 565 |    834.543125 |     22.626643 | Mathilde Cordellier                                                                                                                                                   |
| 566 |    237.202865 |    242.662778 | Andy Wilson                                                                                                                                                           |
| 567 |    361.632608 |    467.152262 | Dinah Challen                                                                                                                                                         |
| 568 |     42.609679 |    155.281241 | NA                                                                                                                                                                    |
| 569 |    392.456557 |    198.569449 | Margot Michaud                                                                                                                                                        |
| 570 |    572.915986 |    609.761515 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 571 |    576.844537 |    575.711089 | Markus A. Grohme                                                                                                                                                      |
| 572 |    394.351536 |    700.235333 | T. Michael Keesey                                                                                                                                                     |
| 573 |    996.001736 |    643.188545 | NA                                                                                                                                                                    |
| 574 |    531.134834 |    287.749271 | Ludwik Gąsiorowski                                                                                                                                                    |
| 575 |    824.833400 |    588.607848 | NA                                                                                                                                                                    |
| 576 |    791.771720 |    617.852196 | Auckland Museum                                                                                                                                                       |
| 577 |     24.485009 |    465.394086 | Zimices                                                                                                                                                               |
| 578 |    106.548674 |    605.017181 | Tauana J. Cunha                                                                                                                                                       |
| 579 |    499.375297 |     87.275611 | Matt Crook                                                                                                                                                            |
| 580 |    790.597798 |    767.765645 | Geoff Shaw                                                                                                                                                            |
| 581 |    613.629217 |    583.875546 | Zimices                                                                                                                                                               |
| 582 |    145.112317 |    692.839499 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 583 |    836.844876 |    596.841435 | Beth Reinke                                                                                                                                                           |
| 584 |     17.538221 |    791.966135 | Matt Crook                                                                                                                                                            |
| 585 |    632.570880 |    423.264671 | Markus A. Grohme                                                                                                                                                      |
| 586 |     33.876320 |    388.961283 | Jagged Fang Designs                                                                                                                                                   |
| 587 |    821.286547 |    568.063549 | Sarah Werning                                                                                                                                                         |
| 588 |    634.072696 |    117.574531 | NA                                                                                                                                                                    |
| 589 |    661.777397 |    492.358565 | Matt Crook                                                                                                                                                            |
| 590 |    534.877792 |    228.137694 | Agnello Picorelli                                                                                                                                                     |
| 591 |    568.308070 |    310.145915 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 592 |    496.147655 |    150.006941 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 593 |    358.177187 |     50.396181 | Collin Gross                                                                                                                                                          |
| 594 |    662.792062 |    679.699856 | Zimices                                                                                                                                                               |
| 595 |     16.571138 |    616.946855 | T. Michael Keesey                                                                                                                                                     |
| 596 |    820.732686 |    243.472841 | Joschua Knüppe                                                                                                                                                        |
| 597 |    788.802868 |    391.668106 | Jagged Fang Designs                                                                                                                                                   |
| 598 |    385.564254 |    727.624109 | NA                                                                                                                                                                    |
| 599 |    288.656135 |     51.794313 | NA                                                                                                                                                                    |
| 600 |   1012.678331 |    608.003868 | Christoph Schomburg                                                                                                                                                   |
| 601 |    796.455559 |    730.917828 | Jagged Fang Designs                                                                                                                                                   |
| 602 |    987.230021 |    534.357654 | David Orr                                                                                                                                                             |
| 603 |    301.743281 |    675.062432 | Terpsichores                                                                                                                                                          |
| 604 |    170.426231 |    767.361736 | FunkMonk                                                                                                                                                              |
| 605 |     66.799183 |    501.504182 | Jagged Fang Designs                                                                                                                                                   |
| 606 |    869.252084 |     71.739740 | Burton Robert, USFWS                                                                                                                                                  |
| 607 |   1012.723139 |    400.942265 | NA                                                                                                                                                                    |
| 608 |    296.899880 |      8.171243 | Matt Crook                                                                                                                                                            |
| 609 |    745.285271 |    145.933239 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 610 |    572.195607 |    322.425118 | Roberto Díaz Sibaja                                                                                                                                                   |
| 611 |    509.504273 |    782.628807 | Cathy                                                                                                                                                                 |
| 612 |    974.631790 |    466.986415 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                              |
| 613 |    249.871382 |    672.089305 | Steven Traver                                                                                                                                                         |
| 614 |    273.263715 |     75.417519 | Sean McCann                                                                                                                                                           |
| 615 |    993.047983 |    207.519073 | Kai R. Caspar                                                                                                                                                         |
| 616 |    428.247506 |     41.702046 | Michael P. Taylor                                                                                                                                                     |
| 617 |    975.846392 |    621.429594 | Matt Crook                                                                                                                                                            |
| 618 |    200.073109 |    427.637756 | Armin Reindl                                                                                                                                                          |
| 619 |    725.295023 |    775.066357 | Margot Michaud                                                                                                                                                        |
| 620 |    418.834606 |    572.385380 | Danielle Alba                                                                                                                                                         |
| 621 |    728.946962 |    492.358390 | Christoph Schomburg                                                                                                                                                   |
| 622 |    524.839814 |     48.812123 | Agnello Picorelli                                                                                                                                                     |
| 623 |    831.406410 |    212.257089 | Rebecca Groom                                                                                                                                                         |
| 624 |    885.729560 |     14.316166 | Michelle Site                                                                                                                                                         |
| 625 |   1009.116240 |    222.893754 | Scott Reid                                                                                                                                                            |
| 626 |    995.132993 |     19.073889 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 627 |    537.060610 |    252.155189 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 628 |    605.143484 |    797.122703 | Chris huh                                                                                                                                                             |
| 629 |    177.365109 |    724.268364 | Matt Crook                                                                                                                                                            |
| 630 |    554.637934 |    482.682987 | T. Michael Keesey                                                                                                                                                     |
| 631 |   1000.804497 |    769.742791 | Felix Vaux                                                                                                                                                            |
| 632 |    637.925045 |    445.045526 | Markus A. Grohme                                                                                                                                                      |
| 633 |    102.493183 |     95.251813 | Ieuan Jones                                                                                                                                                           |
| 634 |    991.128037 |    655.092044 | Zimices                                                                                                                                                               |
| 635 |    445.949163 |     27.864205 | Margot Michaud                                                                                                                                                        |
| 636 |    404.184407 |    199.735998 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 637 |    459.663349 |    582.927738 | Gopal Murali                                                                                                                                                          |
| 638 |    252.499438 |    209.589137 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 639 |    651.400928 |    179.827358 | Margot Michaud                                                                                                                                                        |
| 640 |     32.027295 |    321.822796 | Matt Crook                                                                                                                                                            |
| 641 |    210.568060 |    769.336958 | Margot Michaud                                                                                                                                                        |
| 642 |    380.926397 |    602.646202 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 643 |    365.113641 |    208.174026 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 644 |    779.056521 |    644.324300 | Dean Schnabel                                                                                                                                                         |
| 645 |    980.441662 |    509.287793 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 646 |   1006.078188 |    370.318230 | Ferran Sayol                                                                                                                                                          |
| 647 |    757.313952 |    765.754294 | Jagged Fang Designs                                                                                                                                                   |
| 648 |    768.876709 |    678.224816 | Terpsichores                                                                                                                                                          |
| 649 |    489.379729 |    511.295234 | Matt Crook                                                                                                                                                            |
| 650 |   1002.456159 |    434.549066 | T. Michael Keesey                                                                                                                                                     |
| 651 |    599.784048 |    424.962546 | Michael Scroggie                                                                                                                                                      |
| 652 |    307.939313 |    576.369968 | T. Michael Keesey                                                                                                                                                     |
| 653 |     24.205411 |    757.429244 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 654 |    664.206086 |     53.849738 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 655 |    739.825924 |    539.304510 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 656 |    497.116825 |    688.730293 | Matt Crook                                                                                                                                                            |
| 657 |    485.476597 |    296.628079 | Kamil S. Jaron                                                                                                                                                        |
| 658 |    754.597411 |    536.917785 | Smokeybjb                                                                                                                                                             |
| 659 |     42.278241 |    258.819672 | Scott Hartman                                                                                                                                                         |
| 660 |    641.758893 |    584.133407 | Dinah Challen                                                                                                                                                         |
| 661 |     84.493098 |    300.074629 | Zimices                                                                                                                                                               |
| 662 |    627.597599 |    184.682782 | Chris huh                                                                                                                                                             |
| 663 |    858.906109 |    700.056774 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
| 664 |   1006.377680 |    287.955881 | Steven Traver                                                                                                                                                         |
| 665 |    674.951211 |    453.829243 | Gareth Monger                                                                                                                                                         |
| 666 |    983.447112 |    416.749919 | Anthony Caravaggi                                                                                                                                                     |
| 667 |    204.032401 |    776.466485 | Margot Michaud                                                                                                                                                        |
| 668 |    169.546992 |    320.348177 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 669 |   1007.085784 |    587.776924 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 670 |    804.772046 |    699.559648 | Collin Gross                                                                                                                                                          |
| 671 |    860.559602 |    233.734202 | NA                                                                                                                                                                    |
| 672 |    993.656022 |     26.704339 | Scott Hartman                                                                                                                                                         |
| 673 |    103.068566 |    317.061439 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 674 |    758.016597 |    606.072028 | Kanchi Nanjo                                                                                                                                                          |
| 675 |    369.026526 |    450.475602 | Margot Michaud                                                                                                                                                        |
| 676 |    433.691115 |    790.150824 | Kanako Bessho-Uehara                                                                                                                                                  |
| 677 |    464.373682 |     86.697389 | Renata F. Martins                                                                                                                                                     |
| 678 |    692.772510 |    230.023499 | Carlos Cano-Barbacil                                                                                                                                                  |
| 679 |    324.767444 |    760.881411 | Lauren Sumner-Rooney                                                                                                                                                  |
| 680 |    983.709476 |    279.997944 | T. Michael Keesey                                                                                                                                                     |
| 681 |    510.160085 |    605.183933 | Gareth Monger                                                                                                                                                         |
| 682 |     57.787183 |    215.039656 | Zimices                                                                                                                                                               |
| 683 |    739.743140 |    334.563626 | Zimices                                                                                                                                                               |
| 684 |    648.096444 |    160.659821 | Scott Hartman                                                                                                                                                         |
| 685 |    693.777396 |    522.486136 | Emily Willoughby                                                                                                                                                      |
| 686 |     55.466060 |     27.250324 | Nick Schooler                                                                                                                                                         |
| 687 |    863.015963 |    544.958497 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 688 |    206.566372 |    114.886613 | Carlos Cano-Barbacil                                                                                                                                                  |
| 689 |    926.035777 |    717.872749 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 690 |   1012.085149 |    378.511779 | Sarah Werning                                                                                                                                                         |
| 691 |    546.461949 |    754.034159 | Matt Crook                                                                                                                                                            |
| 692 |    104.719705 |    622.122031 | Skye M                                                                                                                                                                |
| 693 |    319.160971 |    215.596474 | L. Shyamal                                                                                                                                                            |
| 694 |    185.446909 |    438.991378 | Felix Vaux                                                                                                                                                            |
| 695 |    371.793199 |    380.975538 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 696 |    258.377318 |    224.941156 | Ferran Sayol                                                                                                                                                          |
| 697 |    449.931974 |    106.939597 | Maija Karala                                                                                                                                                          |
| 698 |    204.652435 |    675.733985 | Sharon Wegner-Larsen                                                                                                                                                  |
| 699 |    538.244739 |      5.178985 | Markus A. Grohme                                                                                                                                                      |
| 700 |    117.961880 |    168.865929 | NA                                                                                                                                                                    |
| 701 |    433.847845 |    658.925444 | Christoph Schomburg                                                                                                                                                   |
| 702 |    266.171602 |    458.265141 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 703 |    122.882441 |    637.727407 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 704 |    302.712351 |    226.478231 | T. Michael Keesey                                                                                                                                                     |
| 705 |     49.678311 |      6.836028 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 706 |    603.474523 |    479.612448 | Tasman Dixon                                                                                                                                                          |
| 707 |    716.480139 |     78.137136 | T. Michael Keesey                                                                                                                                                     |
| 708 |    839.296480 |    245.163834 | Crystal Maier                                                                                                                                                         |
| 709 |    664.664416 |    690.882238 | Jagged Fang Designs                                                                                                                                                   |
| 710 |    332.016602 |    161.893118 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 711 |    116.998809 |    397.429951 | Scott Hartman                                                                                                                                                         |
| 712 |    606.760803 |    214.402963 | Margot Michaud                                                                                                                                                        |
| 713 |    806.653613 |    211.315183 | Steven Traver                                                                                                                                                         |
| 714 |    572.541660 |    128.000970 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 715 |     68.836141 |    623.893987 | Katie S. Collins                                                                                                                                                      |
| 716 |    818.661003 |    355.539019 | Michele Tobias                                                                                                                                                        |
| 717 |    753.462357 |    241.957196 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 718 |    723.405482 |    483.315065 | Chris huh                                                                                                                                                             |
| 719 |    831.074549 |    295.105124 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 720 |    558.597988 |    702.677942 | T. Michael Keesey                                                                                                                                                     |
| 721 |    216.757604 |    456.701091 | xgirouxb                                                                                                                                                              |
| 722 |     18.584785 |    693.820304 | Tyler Greenfield                                                                                                                                                      |
| 723 |    690.120486 |    475.174618 | Jack Mayer Wood                                                                                                                                                       |
| 724 |    554.166013 |    152.224993 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 725 |    411.121760 |    789.257760 | Scott Hartman                                                                                                                                                         |
| 726 |    798.273396 |    650.790759 | Shyamal                                                                                                                                                               |
| 727 |    375.008545 |    190.233684 | Margot Michaud                                                                                                                                                        |
| 728 |    634.872153 |     38.930892 | NA                                                                                                                                                                    |
| 729 |    604.784841 |    338.507469 | Scott Hartman                                                                                                                                                         |
| 730 |    921.283211 |    152.870999 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 731 |    983.583671 |    733.183954 | Melissa Broussard                                                                                                                                                     |
| 732 |    993.042533 |     81.408375 | NA                                                                                                                                                                    |
| 733 |    471.886094 |    715.207182 | Matt Crook                                                                                                                                                            |
| 734 |     36.049643 |    693.999057 | Beth Reinke                                                                                                                                                           |
| 735 |    579.559245 |    173.206555 | Matus Valach                                                                                                                                                          |
| 736 |    610.641315 |    681.242755 | Michele M Tobias                                                                                                                                                      |
| 737 |    346.601639 |    359.616591 | NA                                                                                                                                                                    |
| 738 |    789.866858 |    528.597916 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 739 |    855.195758 |    527.317277 | Michelle Site                                                                                                                                                         |
| 740 |    649.275082 |     45.551696 | Margot Michaud                                                                                                                                                        |
| 741 |    538.789787 |    552.040035 | Tauana J. Cunha                                                                                                                                                       |
| 742 |    661.909411 |    384.903093 | Zimices                                                                                                                                                               |
| 743 |    508.039740 |    304.987641 | Michele M Tobias                                                                                                                                                      |
| 744 |    943.550663 |    673.268627 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 745 |    404.361783 |    257.294589 | Agnello Picorelli                                                                                                                                                     |
| 746 |    104.723819 |      4.974306 | Thibaut Brunet                                                                                                                                                        |
| 747 |    156.526682 |     29.458303 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 748 |    197.981922 |    509.130328 | Kristina Gagalova                                                                                                                                                     |
| 749 |    741.768982 |    705.725249 | Margot Michaud                                                                                                                                                        |
| 750 |    356.015273 |    258.064692 | Matt Crook                                                                                                                                                            |
| 751 |    802.652314 |    423.566821 | Jagged Fang Designs                                                                                                                                                   |
| 752 |    721.574647 |    201.181817 | M. A. Broussard                                                                                                                                                       |
| 753 |      6.780153 |    157.124716 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 754 |    739.034545 |    354.313468 | C. Camilo Julián-Caballero                                                                                                                                            |
| 755 |    361.767902 |    779.975278 | Maxime Dahirel                                                                                                                                                        |
| 756 |    390.683722 |    762.434022 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 757 |    500.027634 |    706.754877 | Markus A. Grohme                                                                                                                                                      |
| 758 |    857.192612 |    358.801695 | Tasman Dixon                                                                                                                                                          |
| 759 |    413.321669 |    284.157707 | Scott Hartman                                                                                                                                                         |
| 760 |    629.343123 |    207.207323 | Zimices                                                                                                                                                               |
| 761 |   1001.873393 |    172.356414 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 762 |    603.487204 |    171.365709 | NA                                                                                                                                                                    |
| 763 |    454.316231 |    277.485694 | Xavier Giroux-Bougard                                                                                                                                                 |
| 764 |    922.909572 |    574.386566 | Cesar Julian                                                                                                                                                          |
| 765 |     45.715943 |    254.031058 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 766 |    362.401679 |    405.668462 | Liftarn                                                                                                                                                               |
| 767 |    268.176036 |    398.454766 | Margot Michaud                                                                                                                                                        |
| 768 |    369.317964 |    480.823339 | Cathy                                                                                                                                                                 |
| 769 |    820.111762 |    627.833731 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 770 |   1004.545044 |    199.566146 | S.Martini                                                                                                                                                             |
| 771 |     28.917772 |    496.498752 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 772 |    959.379226 |    718.195682 | Kamil S. Jaron                                                                                                                                                        |
| 773 |    686.208386 |    697.721360 | T. Michael Keesey                                                                                                                                                     |
| 774 |    550.462586 |    636.698131 | Gareth Monger                                                                                                                                                         |
| 775 |    728.786580 |    389.635150 | NA                                                                                                                                                                    |
| 776 |    518.321634 |    635.394495 | Matt Crook                                                                                                                                                            |
| 777 |     38.347917 |    517.956513 | nicubunu                                                                                                                                                              |
| 778 |    185.998672 |     94.178234 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 779 |    965.376150 |    565.186289 | Sarah Werning                                                                                                                                                         |
| 780 |    177.713235 |    399.321687 | Jagged Fang Designs                                                                                                                                                   |
| 781 |     47.095025 |    346.528140 | Gareth Monger                                                                                                                                                         |
| 782 |    513.715594 |    720.863270 | Sean McCann                                                                                                                                                           |
| 783 |    723.411686 |    396.843134 | FunkMonk                                                                                                                                                              |
| 784 |    571.301390 |    710.669644 | T. Michael Keesey                                                                                                                                                     |
| 785 |    219.461735 |    356.294658 | Alexandre Vong                                                                                                                                                        |
| 786 |    995.977075 |    183.963411 | Gareth Monger                                                                                                                                                         |
| 787 |    937.815864 |    318.528348 | Steven Traver                                                                                                                                                         |
| 788 |    945.516911 |    499.605261 | FunkMonk                                                                                                                                                              |
| 789 |    386.340648 |    544.054858 | NA                                                                                                                                                                    |
| 790 |    328.838731 |    446.155394 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 791 |    969.622309 |    279.562549 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 792 |    271.765967 |      8.897932 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 793 |    878.150461 |    390.963500 | Tasman Dixon                                                                                                                                                          |
| 794 |     33.274447 |    126.514730 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 795 |    954.495786 |     31.192676 | Zimices                                                                                                                                                               |
| 796 |    823.433984 |    536.867155 | Jagged Fang Designs                                                                                                                                                   |
| 797 |    314.247846 |    663.104722 | Margot Michaud                                                                                                                                                        |
| 798 |    753.967765 |    331.235276 | Zimices                                                                                                                                                               |
| 799 |    814.276067 |    584.314106 | NA                                                                                                                                                                    |
| 800 |    385.896065 |    149.187622 | Jaime Headden                                                                                                                                                         |
| 801 |   1014.087891 |     13.094864 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 802 |    939.979623 |     78.605297 | Zimices                                                                                                                                                               |
| 803 |    569.483610 |    328.769541 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 804 |    129.578757 |    138.181486 | NA                                                                                                                                                                    |
| 805 |    186.648535 |    585.095265 | Gareth Monger                                                                                                                                                         |
| 806 |    122.755253 |    502.764856 | Steven Traver                                                                                                                                                         |
| 807 |    917.358109 |    722.764926 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 808 |    480.741812 |    701.966083 | T. Michael Keesey                                                                                                                                                     |
| 809 |    100.630923 |    690.821737 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 810 |    533.554404 |    706.003550 | Andrew A. Farke                                                                                                                                                       |
| 811 |    309.801444 |    446.396731 | Gareth Monger                                                                                                                                                         |
| 812 |     10.914906 |    669.232740 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 813 |    961.244993 |    526.105516 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 814 |    151.868684 |    235.389681 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 815 |    310.988962 |     58.097854 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 816 |    355.794176 |    226.260336 | Andrew A. Farke                                                                                                                                                       |
| 817 |    159.226267 |    144.351344 | Martin Kevil                                                                                                                                                          |
| 818 |    218.419360 |    606.009411 | Birgit Lang                                                                                                                                                           |
| 819 |     90.774855 |    134.149250 | Mathieu Basille                                                                                                                                                       |
| 820 |     39.380253 |    789.867692 | david maas / dave hone                                                                                                                                                |
| 821 |    742.253455 |    254.990220 | Maija Karala                                                                                                                                                          |
| 822 |    188.276463 |    672.008770 | Felix Vaux                                                                                                                                                            |
| 823 |    793.152126 |    248.172036 | Scott Hartman                                                                                                                                                         |
| 824 |    140.854773 |    354.069477 | Gareth Monger                                                                                                                                                         |
| 825 |      7.470327 |    530.360779 | Emily Willoughby                                                                                                                                                      |
| 826 |    239.049999 |    652.927992 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 827 |     14.303902 |    368.521968 | Chris huh                                                                                                                                                             |
| 828 |    341.359495 |    159.234683 | Lukasiniho                                                                                                                                                            |
| 829 |    843.067506 |    536.703253 | Kai R. Caspar                                                                                                                                                         |
| 830 |   1014.792237 |    568.209018 | Gareth Monger                                                                                                                                                         |
| 831 |    201.822295 |    287.069111 | NA                                                                                                                                                                    |
| 832 |    283.255200 |    203.362464 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 833 |    400.623536 |    752.689654 | NA                                                                                                                                                                    |
| 834 |    752.611127 |    589.987075 | Michelle Site                                                                                                                                                         |
| 835 |    126.876280 |    584.489447 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 836 |     82.159113 |    789.881676 | C. Camilo Julián-Caballero                                                                                                                                            |
| 837 |    718.399895 |    406.199784 | Ferran Sayol                                                                                                                                                          |
| 838 |    272.374548 |     44.365701 | FunkMonk                                                                                                                                                              |
| 839 |    398.491131 |    412.257657 | Gareth Monger                                                                                                                                                         |
| 840 |    380.254140 |    431.723911 | L. Shyamal                                                                                                                                                            |
| 841 |    848.209477 |    410.285651 | NA                                                                                                                                                                    |
| 842 |    527.096437 |    279.890674 | Margot Michaud                                                                                                                                                        |
| 843 |    699.253303 |    382.107324 | Scott Hartman                                                                                                                                                         |
| 844 |    686.322008 |    708.426707 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 845 |    102.392860 |    111.668378 | Gareth Monger                                                                                                                                                         |
| 846 |    579.343966 |    673.087740 | Jagged Fang Designs                                                                                                                                                   |
| 847 |    767.171834 |    388.351400 | Sean McCann                                                                                                                                                           |
| 848 |    690.333002 |    668.797597 | Margot Michaud                                                                                                                                                        |
| 849 |    733.845701 |    724.170144 | Zimices                                                                                                                                                               |
| 850 |    441.048990 |    515.802621 | Collin Gross                                                                                                                                                          |
| 851 |    387.450821 |    112.954954 | C. Camilo Julián-Caballero                                                                                                                                            |
| 852 |    788.222919 |    441.775714 | Mattia Menchetti                                                                                                                                                      |
| 853 |    378.098414 |    628.739491 | Gareth Monger                                                                                                                                                         |
| 854 |    494.743035 |    412.652973 | Roberto Díaz Sibaja                                                                                                                                                   |
| 855 |    772.852846 |    478.594541 | Steven Traver                                                                                                                                                         |
| 856 |    719.600080 |    148.900151 | NA                                                                                                                                                                    |
| 857 |     77.461512 |    211.506853 | NA                                                                                                                                                                    |
| 858 |    365.144479 |    417.184235 | Steven Traver                                                                                                                                                         |
| 859 |    530.304923 |    238.682575 | Becky Barnes                                                                                                                                                          |
| 860 |    280.373435 |    604.703859 | Mason McNair                                                                                                                                                          |
| 861 |     96.921691 |    172.322094 | Jack Mayer Wood                                                                                                                                                       |
| 862 |    233.246598 |    472.350307 | NA                                                                                                                                                                    |
| 863 |    991.412002 |    302.708842 | Chase Brownstein                                                                                                                                                      |
| 864 |    375.776996 |    790.896908 | David Orr                                                                                                                                                             |
| 865 |     63.982616 |     38.858223 | Richard J. Harris                                                                                                                                                     |
| 866 |    992.486987 |    547.538420 | Danielle Alba                                                                                                                                                         |
| 867 |      8.283515 |     29.257466 | Markus A. Grohme                                                                                                                                                      |
| 868 |   1009.073692 |    659.783273 | C. Camilo Julián-Caballero                                                                                                                                            |
| 869 |    759.596999 |    480.353040 | Andy Wilson                                                                                                                                                           |
| 870 |    394.556712 |    450.741182 | Dmitry Bogdanov                                                                                                                                                       |
| 871 |    411.668963 |    416.790806 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 872 |    384.619975 |    614.893638 | Jack Mayer Wood                                                                                                                                                       |
| 873 |    768.032405 |    753.007394 | Zimices                                                                                                                                                               |
| 874 |    953.525747 |    306.617076 | Gareth Monger                                                                                                                                                         |
| 875 |    565.003320 |      8.643764 | C. Camilo Julián-Caballero                                                                                                                                            |
| 876 |     50.211084 |    635.279799 | Tracy A. Heath                                                                                                                                                        |
| 877 |    277.577723 |    751.042723 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 878 |    142.688106 |    780.162040 | Hugo Gruson                                                                                                                                                           |
| 879 |    377.543219 |    363.156964 | Matt Crook                                                                                                                                                            |
| 880 |    342.780849 |    556.153461 | Jack Mayer Wood                                                                                                                                                       |
| 881 |    810.591519 |    473.270781 | Steven Traver                                                                                                                                                         |
| 882 |     67.704641 |    695.008429 | FunkMonk                                                                                                                                                              |
| 883 |    265.593408 |    327.651555 | Zimices                                                                                                                                                               |
| 884 |    462.728798 |    614.573041 | Kanako Bessho-Uehara                                                                                                                                                  |
| 885 |    900.187378 |    316.773176 | Chris A. Hamilton                                                                                                                                                     |
| 886 |    934.770410 |    111.975506 | Sarah Werning                                                                                                                                                         |
| 887 |     11.748103 |     81.520641 | Yusan Yang                                                                                                                                                            |
| 888 |    399.976828 |    506.863747 | M Kolmann                                                                                                                                                             |
| 889 |    829.823505 |    620.537745 | Matt Martyniuk                                                                                                                                                        |
| 890 |    739.380508 |    109.706823 | Verdilak                                                                                                                                                              |
| 891 |    927.057316 |    259.377304 | T. Michael Keesey                                                                                                                                                     |
| 892 |    923.923309 |    240.907207 | Mason McNair                                                                                                                                                          |
| 893 |     58.299029 |    713.767824 | Matt Crook                                                                                                                                                            |
| 894 |    379.757496 |    440.660207 | Scott Hartman                                                                                                                                                         |
| 895 |   1016.786524 |    276.229490 | Margot Michaud                                                                                                                                                        |
| 896 |    769.248997 |    699.039714 | Harold N Eyster                                                                                                                                                       |
| 897 |     25.495496 |    158.350358 | Matt Crook                                                                                                                                                            |
| 898 |    165.399895 |    411.579945 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 899 |     30.273952 |    377.686674 | Ferran Sayol                                                                                                                                                          |
| 900 |    986.837875 |    201.921659 | Andrew A. Farke                                                                                                                                                       |
| 901 |    963.294772 |     81.290290 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 902 |    689.014932 |    612.297008 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 903 |    700.654633 |    599.237395 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 904 |    363.485771 |    787.957850 | Tasman Dixon                                                                                                                                                          |
| 905 |    233.747234 |    604.943867 | Sean McCann                                                                                                                                                           |
| 906 |    846.599423 |    393.179087 | Margot Michaud                                                                                                                                                        |
| 907 |    557.653694 |    741.651282 | Margot Michaud                                                                                                                                                        |
| 908 |    627.976877 |    552.468629 | Margot Michaud                                                                                                                                                        |
| 909 |     33.615524 |    268.875412 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 910 |    657.348870 |    186.915975 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 911 |    679.386554 |    681.998713 | Benjamin Monod-Broca                                                                                                                                                  |

    #> Your tweet has been posted!
