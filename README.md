
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

Pedro de Siracusa, Yusan Yang, Margot Michaud, Scott Hartman, Zimices,
SecretJellyMan, Maija Karala, Birgit Lang, Emily Willoughby, Matt Crook,
Becky Barnes, Danielle Alba, Markus A. Grohme, Pete Buchholz, Tasman
Dixon, T. Michael Keesey, Chris huh, I. Geoffroy Saint-Hilaire
(vectorized by T. Michael Keesey), Erika Schumacher, Steven Traver,
Collin Gross, Gabriela Palomo-Munoz, Roberto Díaz Sibaja, Ferran Sayol,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Felix Vaux and Steven
A. Trewick, Jagged Fang Designs, FJDegrange, Lukasiniho, Dean Schnabel,
Jake Warner, V. Deepak, Mette Aumala, Noah Schlottman, photo by Carlos
Sánchez-Ortiz, Chase Brownstein, Steven Coombs, Yan Wong, Chuanixn Yu,
Siobhon Egan, Anna Willoughby, T. Michael Keesey (vectorization) and
Larry Loos (photography), C. Camilo Julián-Caballero, Conty (vectorized
by T. Michael Keesey), Dmitry Bogdanov, Smokeybjb (modified by Mike
Keesey), Obsidian Soul (vectorized by T. Michael Keesey), Andy Wilson,
Todd Marshall, vectorized by Zimices, Sarah Werning, Rainer Schoch,
Mali’o Kodis, photograph property of National Museums of Northern
Ireland, Nobu Tamura (vectorized by A. Verrière), kreidefossilien.de,
Daniel Stadtmauer, Nobu Tamura (vectorized by T. Michael Keesey),
Falconaumanni and T. Michael Keesey, Jaime Headden, Neil Kelley, , Brad
McFeeters (vectorized by T. Michael Keesey), Robert Bruce Horsfall
(vectorized by William Gearty), Crystal Maier, Josefine Bohr Brask,
Kevin Sánchez, Matthew E. Clapham, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Alexander Schmidt-Lebuhn, Milton Tan,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Christina N. Hodson, Gareth Monger,
Walter Vladimir, Terpsichores, Lindberg (vectorized by T. Michael
Keesey), Florian Pfaff, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Roderic Page and
Lois Page, Michelle Site, Kamil S. Jaron, Dein Freund der Baum
(vectorized by T. Michael Keesey), Mathieu Pélissié, Didier Descouens
(vectorized by T. Michael Keesey), CNZdenek, Jaime Headden, modified by
T. Michael Keesey, Natalie Claunch, NOAA Great Lakes Environmental
Research Laboratory (illustration) and Timothy J. Bartley (silhouette),
Agnello Picorelli, Ignacio Contreras, Maxime Dahirel, Charles Doolittle
Walcott (vectorized by T. Michael Keesey), Michael Scroggie, from
original photograph by John Bettaso, USFWS (original photograph in
public domain)., Matt Martyniuk (modified by Serenchia), C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), Beth Reinke, Francis
de Laporte de Castelnau (vectorized by T. Michael Keesey), Benjamint444,
Matt Martyniuk, Alexandre Vong, Charles R. Knight, vectorized by
Zimices, Qiang Ou, Mathieu Basille, Tracy A. Heath, Tauana J. Cunha,
Carlos Cano-Barbacil, Matt Martyniuk (vectorized by T. Michael Keesey),
David Tana, Mali’o Kodis, image from Higgins and Kristensen, 1986,
kotik, FunkMonk, Mattia Menchetti, MPF (vectorized by T. Michael
Keesey), Nobu Tamura, vectorized by Zimices, U.S. Fish and Wildlife
Service (illustration) and Timothy J. Bartley (silhouette), Margret
Flinsch, vectorized by Zimices, Yan Wong from illustration by Jules
Richard (1907), L. Shyamal, Mathew Callaghan, Jack Mayer Wood, Nobu
Tamura, Felix Vaux, Joanna Wolfe, Amanda Katzer, Ville-Veikko Sinkkonen,
Marmelad, Christoph Schomburg, Daniel Jaron, Birgit Lang; original image
by virmisco.org, Ludwik Gąsiorowski, Joe Schneid (vectorized by T.
Michael Keesey), DW Bapst (Modified from photograph taken by Charles
Mitchell), Anthony Caravaggi, Martin Kevil, Oliver Voigt, Tyler
Greenfield and Dean Schnabel, Zachary Quigley, Scott Reid, Katie S.
Collins, Karkemish (vectorized by T. Michael Keesey), Hans Hillewaert
(vectorized by T. Michael Keesey), terngirl, J. J. Harrison (photo) & T.
Michael Keesey, Armin Reindl, S.Martini, T. Michael Keesey (after
Masteraah), Fernando Carezzano, Natasha Vitek, Curtis Clark and T.
Michael Keesey, Jimmy Bernot, Iain Reid, Andrew A. Farke, Ingo Braasch,
Scott Hartman (modified by T. Michael Keesey), Mason McNair, Cesar
Julian, Smokeybjb, Tony Ayling (vectorized by T. Michael Keesey), Julio
Garza, Abraão B. Leite, Christopher Chávez, Kai R. Caspar, Tony Ayling
(vectorized by Milton Tan), Geoff Shaw, Jose Carlos Arenas-Monroy, Espen
Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell),
T. Michael Keesey (vectorization) and HuttyMcphoo (photography), Tyler
Greenfield, Rene Martin, Matt Celeskey, Nobu Tamura (modified by T.
Michael Keesey), Robert Bruce Horsfall (vectorized by T. Michael
Keesey), Martin R. Smith, Jerry Oldenettel (vectorized by T. Michael
Keesey), H. F. O. March (vectorized by T. Michael Keesey), Robert Gay,
Servien (vectorized by T. Michael Keesey), david maas / dave hone, Emma
Hughes, Pearson Scott Foresman (vectorized by T. Michael Keesey), Andrew
A. Farke, modified from original by H. Milne Edwards, Ernst Haeckel
(vectorized by T. Michael Keesey), Jonathan Wells, Caleb M. Brown, T.
Michael Keesey (after Ponomarenko), Joseph Wolf, 1863 (vectorization by
Dinah Challen), www.studiospectre.com, Tarique Sani (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Michele M
Tobias, Xavier Giroux-Bougard, Michael Scroggie, B. Duygu Özpolat, L.M.
Davalos, Darren Naish (vectorize by T. Michael Keesey), Sean McCann,
Christian A. Masnaghetti, Alan Manson (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, T. K. Robinson, Melissa
Broussard, Steven Blackwood, David Orr, Raven Amos, Mathew Wedel, Wayne
Decatur, Noah Schlottman, photo from Casey Dunn, Robbie N. Cada
(vectorized by T. Michael Keesey), Duane Raver (vectorized by T. Michael
Keesey), Noah Schlottman, photo by Casey Dunn, Martien Brand (original
photo), Renato Santos (vector silhouette), Henry Lydecker, Campbell
Fleming, Yan Wong from photo by Denes Emoke, Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), Robbie N. Cada
(modified by T. Michael Keesey), Marie-Aimée Allard, Ellen Edmonson and
Hugh Chrisp (vectorized by T. Michael Keesey), Xvazquez (vectorized by
William Gearty), Noah Schlottman, photo by Martin V. Sørensen, Mo
Hassan, annaleeblysse, T. Michael Keesey (after C. De Muizon), mystica,
Isaure Scavezzoni, Meyers Konversations-Lexikon 1897 (vectorized: Yan
Wong), Skye McDavid, Mali’o Kodis, image from the “Proceedings of the
Zoological Society of London”, Metalhead64 (vectorized by T. Michael
Keesey), Matthew Hooge (vectorized by T. Michael Keesey), Andrew A.
Farke, shell lines added by Yan Wong, Francesco Veronesi (vectorized by
T. Michael Keesey), Saguaro Pictures (source photo) and T. Michael
Keesey, Manabu Sakamoto, Stanton F. Fink, vectorized by Zimices, Dexter
R. Mardis, Sergio A. Muñoz-Gómez, Theodore W. Pietsch (photography) and
T. Michael Keesey (vectorization), Michele M Tobias from an image By
Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Ray Simpson
(vectorized by T. Michael Keesey), Rebecca Groom, Eduard Solà
(vectorized by T. Michael Keesey), ArtFavor & annaleeblysse, A. H.
Baldwin (vectorized by T. Michael Keesey), Alexis Simon, John Conway,
Pranav Iyer (grey ideas), T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Chloé Schmidt,
Patrick Strutzenberger, Nicolas Mongiardino Koch, Karla Martinez,
Riccardo Percudani, Noah Schlottman, Kent Sorgon, Ellen Edmonson and
Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette), Mali’o
Kodis, photograph by Jim Vargo, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Mathilde
Cordellier, Maxwell Lefroy (vectorized by T. Michael Keesey), Nina
Skinner, Tony Ayling, Kanchi Nanjo, Stacy Spensley (Modified)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    493.320221 |     93.101318 | Pedro de Siracusa                                                                                                                                                     |
|   2 |    915.980175 |    537.893847 | Yusan Yang                                                                                                                                                            |
|   3 |    335.368068 |    627.218703 | Margot Michaud                                                                                                                                                        |
|   4 |    628.498846 |    154.788855 | Scott Hartman                                                                                                                                                         |
|   5 |    117.122958 |    482.181545 | Margot Michaud                                                                                                                                                        |
|   6 |    259.200378 |    705.285075 | Zimices                                                                                                                                                               |
|   7 |    596.689773 |    420.327293 | Zimices                                                                                                                                                               |
|   8 |    803.549452 |    216.290369 | Margot Michaud                                                                                                                                                        |
|   9 |     31.594313 |    222.341838 | SecretJellyMan                                                                                                                                                        |
|  10 |    150.726702 |    529.389344 | NA                                                                                                                                                                    |
|  11 |    287.919379 |    462.010450 | Maija Karala                                                                                                                                                          |
|  12 |    287.523943 |    320.365047 | Birgit Lang                                                                                                                                                           |
|  13 |    940.427458 |    337.995270 | Emily Willoughby                                                                                                                                                      |
|  14 |    557.872141 |    660.805198 | NA                                                                                                                                                                    |
|  15 |    768.954591 |    415.011596 | NA                                                                                                                                                                    |
|  16 |    413.228087 |    508.278958 | Matt Crook                                                                                                                                                            |
|  17 |    181.955137 |    146.949811 | Becky Barnes                                                                                                                                                          |
|  18 |    103.890738 |     45.782184 | Danielle Alba                                                                                                                                                         |
|  19 |    735.023197 |    596.672027 | Markus A. Grohme                                                                                                                                                      |
|  20 |    805.120666 |    643.321753 | Matt Crook                                                                                                                                                            |
|  21 |    181.510630 |    350.208775 | Pete Buchholz                                                                                                                                                         |
|  22 |    787.634966 |    304.604318 | Zimices                                                                                                                                                               |
|  23 |    436.776809 |    210.631778 | NA                                                                                                                                                                    |
|  24 |    890.555920 |     67.349060 | Tasman Dixon                                                                                                                                                          |
|  25 |    501.553332 |    342.264784 | T. Michael Keesey                                                                                                                                                     |
|  26 |    688.493285 |     50.903297 | Chris huh                                                                                                                                                             |
|  27 |    269.121916 |    559.537766 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
|  28 |    960.561743 |    205.823847 | Erika Schumacher                                                                                                                                                      |
|  29 |    673.475544 |    719.519954 | Steven Traver                                                                                                                                                         |
|  30 |    225.435606 |     44.667951 | Collin Gross                                                                                                                                                          |
|  31 |     83.234389 |    401.880654 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  32 |    284.381828 |    755.764272 | Roberto Díaz Sibaja                                                                                                                                                   |
|  33 |    718.247136 |    521.047918 | Steven Traver                                                                                                                                                         |
|  34 |    539.921893 |    570.567533 | Ferran Sayol                                                                                                                                                          |
|  35 |    228.851239 |    642.628198 | Margot Michaud                                                                                                                                                        |
|  36 |    946.091861 |    461.140885 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  37 |     79.612588 |    297.019151 | Markus A. Grohme                                                                                                                                                      |
|  38 |    356.228256 |    413.363923 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
|  39 |    181.662388 |    455.347515 | Ferran Sayol                                                                                                                                                          |
|  40 |    484.175802 |    721.450216 | Zimices                                                                                                                                                               |
|  41 |    484.618090 |    772.957831 | Jagged Fang Designs                                                                                                                                                   |
|  42 |    844.810298 |    439.546355 | FJDegrange                                                                                                                                                            |
|  43 |    687.173209 |    637.870233 | Lukasiniho                                                                                                                                                            |
|  44 |    893.184411 |    733.811210 | Dean Schnabel                                                                                                                                                         |
|  45 |    109.946270 |    675.960790 | Ferran Sayol                                                                                                                                                          |
|  46 |    355.077442 |    135.085872 | Jagged Fang Designs                                                                                                                                                   |
|  47 |    681.952327 |    773.565767 | Jake Warner                                                                                                                                                           |
|  48 |    715.631391 |    345.323357 | V. Deepak                                                                                                                                                             |
|  49 |    753.753399 |    130.217106 | Erika Schumacher                                                                                                                                                      |
|  50 |    210.726981 |    232.530312 | Zimices                                                                                                                                                               |
|  51 |    818.260406 |     28.892519 | Mette Aumala                                                                                                                                                          |
|  52 |    396.112730 |    726.338699 | NA                                                                                                                                                                    |
|  53 |    449.590163 |    612.330693 | NA                                                                                                                                                                    |
|  54 |    425.281479 |    270.706662 | Jagged Fang Designs                                                                                                                                                   |
|  55 |    582.084143 |    260.005943 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
|  56 |     50.713717 |    560.954863 | Ferran Sayol                                                                                                                                                          |
|  57 |    886.261358 |    289.895504 | Chase Brownstein                                                                                                                                                      |
|  58 |    368.513923 |     37.899873 | Steven Coombs                                                                                                                                                         |
|  59 |    402.326762 |    374.784010 | NA                                                                                                                                                                    |
|  60 |     69.697063 |    771.028493 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  61 |    931.137709 |    616.507977 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  62 |    632.387156 |    346.436214 | Yan Wong                                                                                                                                                              |
|  63 |    915.171591 |    133.985792 | Chuanixn Yu                                                                                                                                                           |
|  64 |    597.867998 |    610.915378 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  65 |    357.554825 |     99.092445 | Siobhon Egan                                                                                                                                                          |
|  66 |    495.051251 |     14.120813 | Chris huh                                                                                                                                                             |
|  67 |    145.936421 |    589.082288 | Anna Willoughby                                                                                                                                                       |
|  68 |    581.835500 |     96.539209 | Emily Willoughby                                                                                                                                                      |
|  69 |    161.385977 |     95.628891 | NA                                                                                                                                                                    |
|  70 |    133.369960 |    207.622546 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
|  71 |    249.265460 |    513.811662 | C. Camilo Julián-Caballero                                                                                                                                            |
|  72 |    175.961410 |    767.223268 | Scott Hartman                                                                                                                                                         |
|  73 |    331.220892 |    267.430310 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  74 |    872.512128 |    372.919530 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  75 |    682.596865 |    281.061112 | Matt Crook                                                                                                                                                            |
|  76 |    591.232679 |     30.477777 | Ferran Sayol                                                                                                                                                          |
|  77 |     64.550902 |    123.106814 | Dmitry Bogdanov                                                                                                                                                       |
|  78 |    561.467479 |    757.588159 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
|  79 |    704.971408 |    217.017366 | Markus A. Grohme                                                                                                                                                      |
|  80 |    921.180148 |    641.785780 | NA                                                                                                                                                                    |
|  81 |    258.725672 |     80.561256 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  82 |    987.481034 |    712.298965 | Andy Wilson                                                                                                                                                           |
|  83 |    388.234563 |    300.750440 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
|  84 |    590.242956 |    574.194543 | Sarah Werning                                                                                                                                                         |
|  85 |    964.006854 |    756.469878 | Markus A. Grohme                                                                                                                                                      |
|  86 |    736.899273 |    676.173697 | Rainer Schoch                                                                                                                                                         |
|  87 |    515.903177 |    652.447278 | Sarah Werning                                                                                                                                                         |
|  88 |    298.796421 |    190.112830 | Ferran Sayol                                                                                                                                                          |
|  89 |    603.881550 |    274.602342 | Matt Crook                                                                                                                                                            |
|  90 |    599.894145 |    698.741080 | Margot Michaud                                                                                                                                                        |
|  91 |    984.960266 |    266.174914 | Margot Michaud                                                                                                                                                        |
|  92 |     61.418422 |    743.728463 | Zimices                                                                                                                                                               |
|  93 |    504.642184 |    520.939655 | T. Michael Keesey                                                                                                                                                     |
|  94 |     64.970607 |     95.061590 | NA                                                                                                                                                                    |
|  95 |    515.086798 |    266.792353 | Scott Hartman                                                                                                                                                         |
|  96 |    454.127264 |    414.960756 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
|  97 |     45.662115 |    682.920778 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
|  98 |    361.573042 |    753.687251 | kreidefossilien.de                                                                                                                                                    |
|  99 |    445.461945 |    297.315929 | Daniel Stadtmauer                                                                                                                                                     |
| 100 |    980.235107 |    502.461157 | Scott Hartman                                                                                                                                                         |
| 101 |    822.089537 |    471.775320 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 102 |    945.038175 |     25.033127 | Margot Michaud                                                                                                                                                        |
| 103 |    865.726974 |    118.802491 | Chris huh                                                                                                                                                             |
| 104 |    158.366783 |     25.867856 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 105 |    534.093333 |    182.900558 | Jaime Headden                                                                                                                                                         |
| 106 |    921.656299 |    687.994133 | Margot Michaud                                                                                                                                                        |
| 107 |    627.642854 |    565.733802 | Neil Kelley                                                                                                                                                           |
| 108 |    853.409765 |    524.241647 | Margot Michaud                                                                                                                                                        |
| 109 |    182.085259 |    722.359935 | Emily Willoughby                                                                                                                                                      |
| 110 |    259.674979 |    163.782866 |                                                                                                                                                                       |
| 111 |    813.534841 |     97.439243 | Scott Hartman                                                                                                                                                         |
| 112 |    155.430813 |    732.054992 | Ferran Sayol                                                                                                                                                          |
| 113 |    293.791220 |    536.519483 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 114 |    867.719622 |    510.286453 | Jagged Fang Designs                                                                                                                                                   |
| 115 |    989.689769 |    419.485164 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 116 |    823.186107 |    562.303928 | Steven Coombs                                                                                                                                                         |
| 117 |    414.413116 |    578.074623 | Crystal Maier                                                                                                                                                         |
| 118 |    782.044832 |    372.743528 | NA                                                                                                                                                                    |
| 119 |    298.090237 |      3.642319 | Josefine Bohr Brask                                                                                                                                                   |
| 120 |     12.261164 |    542.194830 | Margot Michaud                                                                                                                                                        |
| 121 |    144.056058 |     10.919677 | Josefine Bohr Brask                                                                                                                                                   |
| 122 |    802.642055 |    257.783543 | Lukasiniho                                                                                                                                                            |
| 123 |    637.459361 |     15.647146 | Kevin Sánchez                                                                                                                                                         |
| 124 |    121.270308 |    740.257348 | Zimices                                                                                                                                                               |
| 125 |    189.122784 |    780.610240 | Zimices                                                                                                                                                               |
| 126 |     92.457674 |    406.933902 | Matthew E. Clapham                                                                                                                                                    |
| 127 |    324.248367 |    381.211714 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 128 |    773.605819 |    455.516253 | NA                                                                                                                                                                    |
| 129 |    813.546985 |    346.379034 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 130 |    577.012366 |    204.761878 | Milton Tan                                                                                                                                                            |
| 131 |      8.415678 |     69.914977 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 132 |    113.793358 |    226.037331 | Markus A. Grohme                                                                                                                                                      |
| 133 |    542.607353 |    471.111506 | Christina N. Hodson                                                                                                                                                   |
| 134 |    981.309221 |     41.009698 | Gareth Monger                                                                                                                                                         |
| 135 |    714.445506 |      8.678467 | Jagged Fang Designs                                                                                                                                                   |
| 136 |     18.775696 |    140.975989 | Chris huh                                                                                                                                                             |
| 137 |    638.266141 |    687.222893 | Roberto Díaz Sibaja                                                                                                                                                   |
| 138 |     10.440417 |    334.753667 | Gareth Monger                                                                                                                                                         |
| 139 |    392.843372 |    124.976356 | Chris huh                                                                                                                                                             |
| 140 |    486.314060 |    680.306736 | Walter Vladimir                                                                                                                                                       |
| 141 |    656.182954 |     88.729507 | Margot Michaud                                                                                                                                                        |
| 142 |     40.281978 |    458.084688 | Ferran Sayol                                                                                                                                                          |
| 143 |   1001.123024 |    461.259174 | Margot Michaud                                                                                                                                                        |
| 144 |    891.419511 |    172.953797 | Terpsichores                                                                                                                                                          |
| 145 |    273.174772 |    113.432654 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 146 |    320.978684 |    671.997182 | Florian Pfaff                                                                                                                                                         |
| 147 |    124.660739 |      6.625134 | NA                                                                                                                                                                    |
| 148 |    322.624867 |    505.200796 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 149 |    802.863519 |    718.937520 | Roderic Page and Lois Page                                                                                                                                            |
| 150 |    490.308904 |    281.559051 | Michelle Site                                                                                                                                                         |
| 151 |    699.084790 |    463.942205 | Yan Wong                                                                                                                                                              |
| 152 |    902.669411 |    425.845078 | Dean Schnabel                                                                                                                                                         |
| 153 |     91.825878 |    371.779614 | Kamil S. Jaron                                                                                                                                                        |
| 154 |    368.742885 |    262.368986 | Ferran Sayol                                                                                                                                                          |
| 155 |    783.890224 |     32.495741 | Sarah Werning                                                                                                                                                         |
| 156 |    435.619134 |     22.942248 | Jagged Fang Designs                                                                                                                                                   |
| 157 |    714.182549 |    312.005703 | NA                                                                                                                                                                    |
| 158 |    993.654279 |     96.871514 | Jagged Fang Designs                                                                                                                                                   |
| 159 |    780.953462 |     92.224538 | Collin Gross                                                                                                                                                          |
| 160 |    861.669107 |     34.105575 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 161 |    724.671794 |    461.926701 | Mathieu Pélissié                                                                                                                                                      |
| 162 |    151.831627 |    192.655882 | Jaime Headden                                                                                                                                                         |
| 163 |    971.671189 |    580.454080 | Steven Traver                                                                                                                                                         |
| 164 |    948.133410 |    416.178471 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 165 |    509.420631 |    160.805619 | Markus A. Grohme                                                                                                                                                      |
| 166 |    963.929927 |    484.326872 | CNZdenek                                                                                                                                                              |
| 167 |    342.554052 |    579.937961 | Ferran Sayol                                                                                                                                                          |
| 168 |    298.374942 |     27.012023 | Matt Crook                                                                                                                                                            |
| 169 |    961.457626 |    531.472738 | T. Michael Keesey                                                                                                                                                     |
| 170 |    134.051226 |    363.965541 | Scott Hartman                                                                                                                                                         |
| 171 |    927.881912 |     10.026349 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 172 |    990.420319 |    403.609344 | Natalie Claunch                                                                                                                                                       |
| 173 |    542.278959 |    483.895116 | Markus A. Grohme                                                                                                                                                      |
| 174 |    256.073365 |    129.561100 | Margot Michaud                                                                                                                                                        |
| 175 |     33.158830 |    319.823594 | Zimices                                                                                                                                                               |
| 176 |    875.745196 |    172.329335 | Chris huh                                                                                                                                                             |
| 177 |    629.233444 |    478.096796 | Margot Michaud                                                                                                                                                        |
| 178 |    299.978599 |    496.708005 | Matt Crook                                                                                                                                                            |
| 179 |    375.536457 |    451.815816 | Zimices                                                                                                                                                               |
| 180 |    438.487504 |     48.377713 | Pedro de Siracusa                                                                                                                                                     |
| 181 |    824.935411 |    156.130436 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 182 |    146.062414 |    375.659426 | Matt Crook                                                                                                                                                            |
| 183 |     98.481065 |    556.402450 | Agnello Picorelli                                                                                                                                                     |
| 184 |    243.022762 |    382.618131 | Ignacio Contreras                                                                                                                                                     |
| 185 |      8.872248 |     12.039368 | Steven Traver                                                                                                                                                         |
| 186 |    798.930994 |    634.106842 | Maxime Dahirel                                                                                                                                                        |
| 187 |    548.009082 |    651.349348 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 188 |    138.554429 |    689.010024 | Matt Crook                                                                                                                                                            |
| 189 |    813.628016 |    548.344937 | Scott Hartman                                                                                                                                                         |
| 190 |    437.815151 |    679.028444 | Matt Crook                                                                                                                                                            |
| 191 |    176.539804 |      7.576594 | NA                                                                                                                                                                    |
| 192 |    594.160867 |    519.515984 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 193 |    384.385215 |      5.825577 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
| 194 |    892.235737 |    240.696330 | Matt Crook                                                                                                                                                            |
| 195 |    156.773145 |    297.197523 | Zimices                                                                                                                                                               |
| 196 |    607.887929 |    459.130693 | Jaime Headden                                                                                                                                                         |
| 197 |     53.820665 |    604.130349 | Jaime Headden                                                                                                                                                         |
| 198 |    176.246382 |    110.873085 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 199 |   1006.264517 |    409.286675 | Margot Michaud                                                                                                                                                        |
| 200 |    812.037314 |    739.663319 | Beth Reinke                                                                                                                                                           |
| 201 |    258.635736 |    424.067582 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 202 |    839.443397 |    339.143955 | Erika Schumacher                                                                                                                                                      |
| 203 |    561.512056 |    189.955232 | NA                                                                                                                                                                    |
| 204 |    406.957826 |    483.450940 | Zimices                                                                                                                                                               |
| 205 |     53.953243 |    496.155183 | Matt Crook                                                                                                                                                            |
| 206 |    915.659433 |    252.907225 | Matt Crook                                                                                                                                                            |
| 207 |    548.696761 |    218.518817 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 208 |    377.744467 |    313.745856 | Benjamint444                                                                                                                                                          |
| 209 |    625.277343 |    654.608901 | Margot Michaud                                                                                                                                                        |
| 210 |    469.700653 |    161.999226 | Margot Michaud                                                                                                                                                        |
| 211 |    362.756815 |    343.799229 | Margot Michaud                                                                                                                                                        |
| 212 |   1021.239116 |    139.377314 | T. Michael Keesey                                                                                                                                                     |
| 213 |    357.254056 |    526.664301 | Matt Martyniuk                                                                                                                                                        |
| 214 |   1006.752749 |     83.102202 | Matt Crook                                                                                                                                                            |
| 215 |    629.169613 |     57.162994 | Ferran Sayol                                                                                                                                                          |
| 216 |    801.736555 |    497.024148 | Erika Schumacher                                                                                                                                                      |
| 217 |    719.513432 |    761.398876 | Alexandre Vong                                                                                                                                                        |
| 218 |   1011.058045 |    671.733567 | Birgit Lang                                                                                                                                                           |
| 219 |    680.865693 |      2.830174 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 220 |    135.329735 |    275.909288 | Qiang Ou                                                                                                                                                              |
| 221 |    923.104291 |    654.111799 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 222 |    285.277686 |    285.483177 | Mathieu Basille                                                                                                                                                       |
| 223 |    132.115213 |    383.973595 | kreidefossilien.de                                                                                                                                                    |
| 224 |    117.748259 |    703.743025 | Tracy A. Heath                                                                                                                                                        |
| 225 |    750.376496 |    797.287258 | Maija Karala                                                                                                                                                          |
| 226 |    535.608468 |    776.283167 | Steven Traver                                                                                                                                                         |
| 227 |     58.367586 |    714.373290 | Matt Crook                                                                                                                                                            |
| 228 |     98.927106 |    322.156343 | Zimices                                                                                                                                                               |
| 229 |     84.217151 |    627.469709 | Zimices                                                                                                                                                               |
| 230 |    985.907430 |    336.515726 | Tauana J. Cunha                                                                                                                                                       |
| 231 |    613.927290 |    688.453028 | Margot Michaud                                                                                                                                                        |
| 232 |    530.661420 |    147.721115 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 233 |    684.824077 |    675.670154 | Scott Hartman                                                                                                                                                         |
| 234 |     33.137492 |    584.825953 | Tracy A. Heath                                                                                                                                                        |
| 235 |     27.448161 |    363.567274 | Gareth Monger                                                                                                                                                         |
| 236 |    467.212048 |    391.387938 | Matt Crook                                                                                                                                                            |
| 237 |    395.930327 |    655.573974 | Carlos Cano-Barbacil                                                                                                                                                  |
| 238 |    641.475219 |    448.270446 | Jagged Fang Designs                                                                                                                                                   |
| 239 |    571.831838 |    690.550739 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 240 |    823.142217 |    628.734747 | Maxime Dahirel                                                                                                                                                        |
| 241 |    519.051195 |    479.432100 | T. Michael Keesey                                                                                                                                                     |
| 242 |    820.690523 |    267.711586 | NA                                                                                                                                                                    |
| 243 |    173.910167 |    554.583152 | Margot Michaud                                                                                                                                                        |
| 244 |    483.692520 |    751.699729 | Chris huh                                                                                                                                                             |
| 245 |    693.114707 |    179.696757 | NA                                                                                                                                                                    |
| 246 |    904.529003 |     31.872737 | Kamil S. Jaron                                                                                                                                                        |
| 247 |    586.703725 |    270.556239 | Tauana J. Cunha                                                                                                                                                       |
| 248 |     72.945722 |    257.335918 | Gareth Monger                                                                                                                                                         |
| 249 |    673.758095 |    100.702388 | Andy Wilson                                                                                                                                                           |
| 250 |    735.148419 |    734.936363 | David Tana                                                                                                                                                            |
| 251 |    664.585396 |    164.554269 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 252 |    945.030674 |     74.268580 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 253 |    818.838837 |     73.748227 | kotik                                                                                                                                                                 |
| 254 |    328.958540 |    371.127321 | NA                                                                                                                                                                    |
| 255 |    304.906053 |    723.594145 | Chris huh                                                                                                                                                             |
| 256 |    805.836891 |     49.719997 | NA                                                                                                                                                                    |
| 257 |    906.725347 |    391.791988 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 258 |    914.690286 |    492.714964 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 259 |    933.839656 |    671.772343 | Margot Michaud                                                                                                                                                        |
| 260 |    640.135269 |    529.578309 | T. Michael Keesey                                                                                                                                                     |
| 261 |    671.855812 |    738.000125 | Margot Michaud                                                                                                                                                        |
| 262 |    959.569707 |    779.028013 | T. Michael Keesey                                                                                                                                                     |
| 263 |    161.052238 |    535.272093 | Zimices                                                                                                                                                               |
| 264 |    607.577062 |    329.436524 | Matt Crook                                                                                                                                                            |
| 265 |    569.383827 |    491.029288 | Yan Wong                                                                                                                                                              |
| 266 |    245.222341 |    402.334147 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 267 |    929.973782 |    490.980761 | FunkMonk                                                                                                                                                              |
| 268 |    311.597337 |    339.275089 | Mattia Menchetti                                                                                                                                                      |
| 269 |    757.860789 |     58.585845 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 270 |   1014.267225 |    563.389230 | Tasman Dixon                                                                                                                                                          |
| 271 |    430.916129 |    148.094591 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 272 |    814.971043 |    514.223165 | Zimices                                                                                                                                                               |
| 273 |    705.666426 |    169.392660 | Steven Traver                                                                                                                                                         |
| 274 |     37.663547 |     85.038198 | NA                                                                                                                                                                    |
| 275 |    524.565384 |    690.623334 | Zimices                                                                                                                                                               |
| 276 |    286.263490 |    353.679543 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 277 |    694.601913 |    669.305343 | Dmitry Bogdanov                                                                                                                                                       |
| 278 |    175.803305 |    743.138471 | Matt Crook                                                                                                                                                            |
| 279 |    256.759658 |    781.102020 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 280 |    160.555255 |    420.974673 | T. Michael Keesey                                                                                                                                                     |
| 281 |    986.730845 |    792.147607 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 282 |     93.530368 |    166.506341 | Jagged Fang Designs                                                                                                                                                   |
| 283 |    322.958847 |    774.377665 | Margot Michaud                                                                                                                                                        |
| 284 |    672.691419 |    120.408664 | C. Camilo Julián-Caballero                                                                                                                                            |
| 285 |   1008.663718 |    270.110529 | Andy Wilson                                                                                                                                                           |
| 286 |    288.505415 |    401.850095 | L. Shyamal                                                                                                                                                            |
| 287 |    484.717654 |    404.759664 | Birgit Lang                                                                                                                                                           |
| 288 |    596.301081 |    218.613672 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 289 |    409.726811 |    789.901981 | Matt Crook                                                                                                                                                            |
| 290 |    567.947872 |    704.424152 | Tracy A. Heath                                                                                                                                                        |
| 291 |    711.094678 |    682.390011 | Zimices                                                                                                                                                               |
| 292 |    134.262479 |     21.067500 | Mathew Callaghan                                                                                                                                                      |
| 293 |    416.759236 |    764.537591 | Jack Mayer Wood                                                                                                                                                       |
| 294 |    933.537783 |    727.944444 | Nobu Tamura                                                                                                                                                           |
| 295 |    251.039220 |    181.667355 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 296 |    184.320712 |     53.546335 | Felix Vaux                                                                                                                                                            |
| 297 |    174.250750 |     19.016271 | NA                                                                                                                                                                    |
| 298 |   1011.099573 |    645.970172 | Joanna Wolfe                                                                                                                                                          |
| 299 |    668.466960 |    678.218976 | Jaime Headden                                                                                                                                                         |
| 300 |    433.184419 |    742.714927 | Matt Crook                                                                                                                                                            |
| 301 |    374.749524 |     79.923582 | Amanda Katzer                                                                                                                                                         |
| 302 |    327.157560 |    707.819489 | Chris huh                                                                                                                                                             |
| 303 |    169.614894 |    279.908393 | Scott Hartman                                                                                                                                                         |
| 304 |    328.200307 |    477.415964 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 305 |    542.071409 |    310.255486 | Marmelad                                                                                                                                                              |
| 306 |   1011.175787 |     98.479354 | Christoph Schomburg                                                                                                                                                   |
| 307 |    197.886757 |    756.784553 | Daniel Jaron                                                                                                                                                          |
| 308 |    332.673021 |    738.973446 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 309 |    535.539811 |    431.772721 | Pete Buchholz                                                                                                                                                         |
| 310 |     82.569125 |    165.958221 | Ludwik Gąsiorowski                                                                                                                                                    |
| 311 |     55.694749 |    367.431554 | Matt Crook                                                                                                                                                            |
| 312 |    210.322471 |     25.553323 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 313 |    243.210703 |    478.619483 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 314 |    258.626943 |    394.475741 | Sarah Werning                                                                                                                                                         |
| 315 |    786.732357 |    760.903862 | Emily Willoughby                                                                                                                                                      |
| 316 |    850.650522 |    255.343304 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 317 |     55.603656 |    448.391607 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 318 |    920.895437 |    623.729850 | NA                                                                                                                                                                    |
| 319 |    110.993288 |    251.028134 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 320 |    640.382522 |    508.243768 | Gareth Monger                                                                                                                                                         |
| 321 |    972.790511 |    149.497394 | Zimices                                                                                                                                                               |
| 322 |     97.442368 |    190.055229 | Zimices                                                                                                                                                               |
| 323 |    721.069881 |    234.060441 | Anthony Caravaggi                                                                                                                                                     |
| 324 |     41.505338 |    668.979990 | T. Michael Keesey                                                                                                                                                     |
| 325 |    216.247984 |    294.485917 | Scott Hartman                                                                                                                                                         |
| 326 |    393.571669 |    452.842296 | NA                                                                                                                                                                    |
| 327 |     12.389540 |    610.032698 | Zimices                                                                                                                                                               |
| 328 |    275.412278 |     10.622583 | Martin Kevil                                                                                                                                                          |
| 329 |    806.825697 |    362.903302 | Oliver Voigt                                                                                                                                                          |
| 330 |    984.553242 |    162.349600 | Scott Hartman                                                                                                                                                         |
| 331 |    405.748689 |    632.632872 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 332 |    210.111680 |    387.314607 | Matt Crook                                                                                                                                                            |
| 333 |    571.396584 |    312.610094 | Zachary Quigley                                                                                                                                                       |
| 334 |    501.872326 |    434.051112 | Birgit Lang                                                                                                                                                           |
| 335 |    959.165178 |    675.083111 | Matt Crook                                                                                                                                                            |
| 336 |    819.421056 |    327.121268 | Jagged Fang Designs                                                                                                                                                   |
| 337 |    323.863293 |    357.704101 | Scott Reid                                                                                                                                                            |
| 338 |    852.706479 |    592.348668 | Katie S. Collins                                                                                                                                                      |
| 339 |   1004.127184 |    621.627884 | Matt Crook                                                                                                                                                            |
| 340 |    559.237894 |    137.686749 | Scott Hartman                                                                                                                                                         |
| 341 |    866.679153 |    661.403218 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 342 |    617.314114 |    737.422662 | Andy Wilson                                                                                                                                                           |
| 343 |    808.554255 |    530.580146 | Matt Crook                                                                                                                                                            |
| 344 |     11.659554 |     43.522050 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 345 |    214.266076 |    752.456160 | Emily Willoughby                                                                                                                                                      |
| 346 |   1008.836004 |    375.727799 | terngirl                                                                                                                                                              |
| 347 |    780.137583 |    783.919394 | Zimices                                                                                                                                                               |
| 348 |    183.913126 |    390.682831 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 349 |    888.637344 |    351.504829 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 350 |    879.303733 |    224.603606 | Armin Reindl                                                                                                                                                          |
| 351 |    575.767121 |    792.193594 | S.Martini                                                                                                                                                             |
| 352 |    864.104911 |    163.520498 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 353 |    834.210754 |    483.787687 | Tasman Dixon                                                                                                                                                          |
| 354 |    364.653794 |    533.479745 | Ferran Sayol                                                                                                                                                          |
| 355 |    283.511162 |    598.744736 | Joanna Wolfe                                                                                                                                                          |
| 356 |    384.348332 |    789.436592 | Fernando Carezzano                                                                                                                                                    |
| 357 |    296.316297 |    370.488500 | Natasha Vitek                                                                                                                                                         |
| 358 |    995.207437 |     20.046002 | Curtis Clark and T. Michael Keesey                                                                                                                                    |
| 359 |     14.330582 |    691.404496 | Jimmy Bernot                                                                                                                                                          |
| 360 |    557.201633 |    252.429358 | Zimices                                                                                                                                                               |
| 361 |     25.173933 |    567.468032 | Emily Willoughby                                                                                                                                                      |
| 362 |    378.820651 |    653.226079 | Maija Karala                                                                                                                                                          |
| 363 |    763.598894 |    756.842455 | Becky Barnes                                                                                                                                                          |
| 364 |    336.850395 |    719.764754 | Iain Reid                                                                                                                                                             |
| 365 |    421.152228 |    116.322568 | Anthony Caravaggi                                                                                                                                                     |
| 366 |    413.380876 |    606.447883 | Matt Crook                                                                                                                                                            |
| 367 |    350.947142 |    601.307314 | Gareth Monger                                                                                                                                                         |
| 368 |   1008.465908 |    120.708520 | Jagged Fang Designs                                                                                                                                                   |
| 369 |    559.313133 |    466.069682 | Steven Traver                                                                                                                                                         |
| 370 |    246.176232 |    354.510887 | Andrew A. Farke                                                                                                                                                       |
| 371 |    457.199638 |    792.056296 | Ingo Braasch                                                                                                                                                          |
| 372 |    172.442070 |    468.989606 | Matt Crook                                                                                                                                                            |
| 373 |    267.109655 |    795.926302 | Jagged Fang Designs                                                                                                                                                   |
| 374 |     19.795932 |    489.650952 | Armin Reindl                                                                                                                                                          |
| 375 |    996.648637 |    235.093608 | T. Michael Keesey                                                                                                                                                     |
| 376 |    199.406351 |    739.603321 | NA                                                                                                                                                                    |
| 377 |    868.942579 |    261.940005 | Chris huh                                                                                                                                                             |
| 378 |    630.478402 |      8.100229 | Chris huh                                                                                                                                                             |
| 379 |    991.297073 |    565.551293 | Matt Crook                                                                                                                                                            |
| 380 |     74.530212 |    518.953479 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 381 |    643.592622 |    585.812384 | Mason McNair                                                                                                                                                          |
| 382 |    888.517840 |    155.469401 | Cesar Julian                                                                                                                                                          |
| 383 |    969.337150 |    552.679196 | Smokeybjb                                                                                                                                                             |
| 384 |    126.353461 |    710.646192 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 385 |    139.109563 |    434.153204 | Steven Traver                                                                                                                                                         |
| 386 |    832.262348 |    141.786219 | Julio Garza                                                                                                                                                           |
| 387 |    842.627293 |    547.170714 | Zimices                                                                                                                                                               |
| 388 |    398.765071 |     85.904358 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 389 |    825.333155 |    447.913056 | Zimices                                                                                                                                                               |
| 390 |    862.420333 |    236.551056 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 391 |    487.154527 |    426.025128 | Zimices                                                                                                                                                               |
| 392 |    807.505267 |    785.660297 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 393 |    827.873192 |    243.189103 | Abraão B. Leite                                                                                                                                                       |
| 394 |    160.843117 |    674.067659 | Christopher Chávez                                                                                                                                                    |
| 395 |    962.523190 |    399.733238 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 396 |    899.730463 |    627.231168 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 397 |    211.557210 |    305.617243 | Zimices                                                                                                                                                               |
| 398 |    389.058971 |     65.055930 | Kai R. Caspar                                                                                                                                                         |
| 399 |    914.044797 |    508.432738 | Andy Wilson                                                                                                                                                           |
| 400 |     87.344093 |    759.334871 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 401 |     80.425956 |    152.403134 | Zimices                                                                                                                                                               |
| 402 |    301.019619 |    417.096047 | Geoff Shaw                                                                                                                                                            |
| 403 |    115.890210 |     79.781330 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 404 |    296.444926 |    431.102979 | Jaime Headden                                                                                                                                                         |
| 405 |    281.317799 |    639.414163 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 406 |    796.366477 |    511.751427 | Tasman Dixon                                                                                                                                                          |
| 407 |    150.375505 |    186.726820 | Scott Hartman                                                                                                                                                         |
| 408 |    335.333854 |    172.788414 | Anna Willoughby                                                                                                                                                       |
| 409 |    112.086615 |    549.782732 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 410 |    648.303593 |    253.083908 | Gareth Monger                                                                                                                                                         |
| 411 |    171.748008 |    611.170788 | Tyler Greenfield                                                                                                                                                      |
| 412 |    280.989695 |    429.602584 | Margot Michaud                                                                                                                                                        |
| 413 |    891.023477 |    487.062543 | Kamil S. Jaron                                                                                                                                                        |
| 414 |    716.146610 |     27.998384 | Rene Martin                                                                                                                                                           |
| 415 |    659.222151 |     23.205890 | Collin Gross                                                                                                                                                          |
| 416 |    946.441354 |    782.217940 | Tasman Dixon                                                                                                                                                          |
| 417 |    401.998316 |    647.490186 | Jagged Fang Designs                                                                                                                                                   |
| 418 |    318.983260 |    590.739049 | Andy Wilson                                                                                                                                                           |
| 419 |    423.401829 |     72.666421 | Matt Celeskey                                                                                                                                                         |
| 420 |    834.994783 |    491.765094 | Birgit Lang                                                                                                                                                           |
| 421 |    354.912871 |      9.496356 | Matt Crook                                                                                                                                                            |
| 422 |    459.496567 |    148.221870 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 423 |    834.822483 |    664.422506 | Michelle Site                                                                                                                                                         |
| 424 |    688.427785 |     66.976083 | Zimices                                                                                                                                                               |
| 425 |    413.802821 |    352.360836 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 426 |    967.295442 |    769.912827 | Birgit Lang                                                                                                                                                           |
| 427 |    731.925962 |    196.351241 | Martin R. Smith                                                                                                                                                       |
| 428 |    559.280428 |     59.528948 | Matt Crook                                                                                                                                                            |
| 429 |    197.576228 |    605.230242 | Andy Wilson                                                                                                                                                           |
| 430 |    949.895940 |    738.614636 | Andy Wilson                                                                                                                                                           |
| 431 |    231.790762 |    139.219499 | Jagged Fang Designs                                                                                                                                                   |
| 432 |    598.099880 |    633.497835 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 433 |    291.773300 |    418.758379 | Gareth Monger                                                                                                                                                         |
| 434 |    876.086661 |    353.771206 | Michelle Site                                                                                                                                                         |
| 435 |    970.602677 |    230.117039 | Ignacio Contreras                                                                                                                                                     |
| 436 |    719.311963 |     71.136982 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 437 |   1004.108311 |    533.568091 | Michelle Site                                                                                                                                                         |
| 438 |    527.824069 |    253.435332 | NA                                                                                                                                                                    |
| 439 |    242.564466 |    371.027025 | Margot Michaud                                                                                                                                                        |
| 440 |     87.702741 |      6.001475 | T. Michael Keesey                                                                                                                                                     |
| 441 |    530.464003 |    453.136055 | Sarah Werning                                                                                                                                                         |
| 442 |     24.669531 |    435.214514 | Jagged Fang Designs                                                                                                                                                   |
| 443 |    222.055999 |    568.581110 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 444 |    178.015868 |    424.629210 | Birgit Lang                                                                                                                                                           |
| 445 |   1013.840881 |      5.844840 | Zimices                                                                                                                                                               |
| 446 |    999.416749 |    402.834671 | Robert Gay                                                                                                                                                            |
| 447 |    866.636625 |    181.475252 | Scott Hartman                                                                                                                                                         |
| 448 |     70.769347 |    640.050377 | Gareth Monger                                                                                                                                                         |
| 449 |    172.624424 |     69.645563 | T. Michael Keesey                                                                                                                                                     |
| 450 |     24.955320 |    638.203788 | Michelle Site                                                                                                                                                         |
| 451 |    573.551158 |    138.025083 | T. Michael Keesey                                                                                                                                                     |
| 452 |    841.378038 |    456.783298 | Crystal Maier                                                                                                                                                         |
| 453 |     60.178998 |    245.806816 | Dean Schnabel                                                                                                                                                         |
| 454 |    822.685529 |    549.859055 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 455 |    591.986700 |    258.318113 | david maas / dave hone                                                                                                                                                |
| 456 |    182.784370 |    681.957658 | NA                                                                                                                                                                    |
| 457 |    196.370771 |    545.266402 | NA                                                                                                                                                                    |
| 458 |    425.928844 |    664.308206 | Sarah Werning                                                                                                                                                         |
| 459 |    396.074587 |    597.443563 | Emma Hughes                                                                                                                                                           |
| 460 |    548.868734 |    696.361727 | FunkMonk                                                                                                                                                              |
| 461 |    660.948838 |     33.064163 | Margot Michaud                                                                                                                                                        |
| 462 |     45.945256 |    697.527619 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 463 |    890.554729 |    582.445739 | Collin Gross                                                                                                                                                          |
| 464 |    781.461876 |    672.430358 | Markus A. Grohme                                                                                                                                                      |
| 465 |    476.418241 |    616.111559 | Ferran Sayol                                                                                                                                                          |
| 466 |    496.871997 |    296.771947 | Michelle Site                                                                                                                                                         |
| 467 |      8.209121 |    410.789080 | Gareth Monger                                                                                                                                                         |
| 468 |    826.428671 |    767.072137 | Ferran Sayol                                                                                                                                                          |
| 469 |    582.235865 |    236.029656 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 470 |    230.232427 |    584.599070 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 471 |    788.503385 |    488.538445 | Gareth Monger                                                                                                                                                         |
| 472 |    746.580219 |    785.318731 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 473 |   1005.875633 |    444.153235 | Margot Michaud                                                                                                                                                        |
| 474 |     59.605475 |    651.281494 | Jonathan Wells                                                                                                                                                        |
| 475 |    826.819454 |    684.310992 | Chuanixn Yu                                                                                                                                                           |
| 476 |    222.369665 |    488.492717 | Andrew A. Farke                                                                                                                                                       |
| 477 |    613.517576 |    786.473549 | Matt Crook                                                                                                                                                            |
| 478 |    594.423415 |    125.383170 | Fernando Carezzano                                                                                                                                                    |
| 479 |    143.636297 |    521.990928 | FunkMonk                                                                                                                                                              |
| 480 |    304.050561 |    328.245437 | Jagged Fang Designs                                                                                                                                                   |
| 481 |    525.892872 |    205.467554 | Lukasiniho                                                                                                                                                            |
| 482 |    854.009236 |    566.983381 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 483 |    606.538379 |    196.990175 | Steven Traver                                                                                                                                                         |
| 484 |    519.711496 |    498.249091 | Caleb M. Brown                                                                                                                                                        |
| 485 |    701.810528 |    409.572434 | Matt Crook                                                                                                                                                            |
| 486 |     91.325171 |    262.903561 | Andy Wilson                                                                                                                                                           |
| 487 |    958.276239 |    561.891807 | Zimices                                                                                                                                                               |
| 488 |    385.484645 |    241.347264 | Michelle Site                                                                                                                                                         |
| 489 |    964.726291 |     51.610440 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 490 |   1011.544164 |    299.663026 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 491 |    127.408052 |    134.639087 | Gareth Monger                                                                                                                                                         |
| 492 |    999.602855 |    433.079812 | Scott Hartman                                                                                                                                                         |
| 493 |    148.439149 |    452.902154 | Matthew E. Clapham                                                                                                                                                    |
| 494 |    540.198871 |    684.413665 | Ignacio Contreras                                                                                                                                                     |
| 495 |    118.157142 |    272.126895 | Ferran Sayol                                                                                                                                                          |
| 496 |    247.160815 |    525.185605 | www.studiospectre.com                                                                                                                                                 |
| 497 |    517.717897 |    470.283796 | Markus A. Grohme                                                                                                                                                      |
| 498 |    976.286126 |    566.665339 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 499 |    371.965478 |    294.818034 | Margot Michaud                                                                                                                                                        |
| 500 |    971.392701 |     95.923387 | Jaime Headden                                                                                                                                                         |
| 501 |    364.861802 |    668.324121 | Zimices                                                                                                                                                               |
| 502 |    682.752722 |    239.972222 | Milton Tan                                                                                                                                                            |
| 503 |    981.429697 |    581.975391 | Robert Gay                                                                                                                                                            |
| 504 |    164.132779 |    704.072943 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 505 |    535.462115 |    498.388494 | Jagged Fang Designs                                                                                                                                                   |
| 506 |    322.558626 |    436.258744 | Zimices                                                                                                                                                               |
| 507 |    601.316589 |    477.014039 | Michele M Tobias                                                                                                                                                      |
| 508 |    559.386087 |    726.001480 | Xavier Giroux-Bougard                                                                                                                                                 |
| 509 |    493.982266 |    263.331032 | NA                                                                                                                                                                    |
| 510 |    549.068506 |    160.323956 | Michael Scroggie                                                                                                                                                      |
| 511 |    572.698431 |     66.786315 | L. Shyamal                                                                                                                                                            |
| 512 |     10.345934 |    462.707788 | B. Duygu Özpolat                                                                                                                                                      |
| 513 |    485.863576 |    604.176983 | L.M. Davalos                                                                                                                                                          |
| 514 |   1002.962112 |    387.618557 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 515 |    548.285865 |    146.891434 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 516 |    645.168226 |    555.433569 | Matt Crook                                                                                                                                                            |
| 517 |    248.099389 |    284.096427 | S.Martini                                                                                                                                                             |
| 518 |    493.603853 |    455.353965 | Sean McCann                                                                                                                                                           |
| 519 |    638.693363 |    738.695705 | Matt Crook                                                                                                                                                            |
| 520 |    781.510847 |    794.515442 | Scott Hartman                                                                                                                                                         |
| 521 |   1005.359434 |    582.707426 | Zimices                                                                                                                                                               |
| 522 |    114.490526 |    343.677227 | Gareth Monger                                                                                                                                                         |
| 523 |   1003.729110 |     29.483930 | Jaime Headden                                                                                                                                                         |
| 524 |    557.752090 |    645.592727 | NA                                                                                                                                                                    |
| 525 |    665.433346 |    349.616110 | NA                                                                                                                                                                    |
| 526 |    586.658363 |    185.147529 | Tasman Dixon                                                                                                                                                          |
| 527 |    657.384440 |     67.731445 | Christian A. Masnaghetti                                                                                                                                              |
| 528 |   1007.941020 |    488.241100 | T. Michael Keesey                                                                                                                                                     |
| 529 |    925.698167 |    420.628655 | Mathieu Basille                                                                                                                                                       |
| 530 |    339.236431 |     63.897780 | Markus A. Grohme                                                                                                                                                      |
| 531 |    897.762201 |    663.973716 | Zimices                                                                                                                                                               |
| 532 |    930.721864 |    249.289731 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 533 |     36.778117 |    477.108657 | Matt Crook                                                                                                                                                            |
| 534 |    165.498882 |    688.717359 | Steven Traver                                                                                                                                                         |
| 535 |    282.952434 |     96.499316 | Andrew A. Farke                                                                                                                                                       |
| 536 |    661.446300 |    176.868426 | S.Martini                                                                                                                                                             |
| 537 |    299.036195 |    218.867884 | T. K. Robinson                                                                                                                                                        |
| 538 |    410.288964 |    746.389573 | T. Michael Keesey                                                                                                                                                     |
| 539 |    344.457138 |    303.470384 | Matt Crook                                                                                                                                                            |
| 540 |    424.846229 |      4.890268 | Emily Willoughby                                                                                                                                                      |
| 541 |    741.504876 |    238.855821 | Melissa Broussard                                                                                                                                                     |
| 542 |    591.922315 |    132.997976 | Steven Coombs                                                                                                                                                         |
| 543 |    963.838435 |     66.533422 | T. Michael Keesey                                                                                                                                                     |
| 544 |    327.100896 |     76.149957 | Scott Hartman                                                                                                                                                         |
| 545 |    749.151354 |    622.354057 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 546 |     46.362530 |     51.625091 | NA                                                                                                                                                                    |
| 547 |    471.957734 |    438.193737 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 548 |    688.014684 |    358.855852 | Ferran Sayol                                                                                                                                                          |
| 549 |    798.444668 |    580.763231 | Scott Hartman                                                                                                                                                         |
| 550 |    338.674853 |    697.178646 | Jaime Headden                                                                                                                                                         |
| 551 |    634.990588 |     40.444840 | Birgit Lang                                                                                                                                                           |
| 552 |    750.620156 |    273.620157 | Jagged Fang Designs                                                                                                                                                   |
| 553 |    704.666499 |    402.676903 | Steven Blackwood                                                                                                                                                      |
| 554 |    144.616898 |    543.012653 | Neil Kelley                                                                                                                                                           |
| 555 |    882.598026 |    233.726859 | Zimices                                                                                                                                                               |
| 556 |    652.843091 |    204.313196 | David Orr                                                                                                                                                             |
| 557 |    470.209227 |    666.012278 | Armin Reindl                                                                                                                                                          |
| 558 |   1009.725518 |    728.094143 | Sarah Werning                                                                                                                                                         |
| 559 |    232.752759 |    391.783471 | Gareth Monger                                                                                                                                                         |
| 560 |    670.882623 |    584.714809 | Raven Amos                                                                                                                                                            |
| 561 |     96.321525 |    347.288208 | Ferran Sayol                                                                                                                                                          |
| 562 |    446.975669 |     94.609857 | Zimices                                                                                                                                                               |
| 563 |    791.024702 |     69.709043 | Natalie Claunch                                                                                                                                                       |
| 564 |    794.572718 |    457.453130 | Birgit Lang                                                                                                                                                           |
| 565 |    640.591849 |     75.251013 | Tasman Dixon                                                                                                                                                          |
| 566 |    653.461029 |    791.976790 | Zimices                                                                                                                                                               |
| 567 |    905.905907 |    485.231538 | Steven Traver                                                                                                                                                         |
| 568 |    345.070023 |    317.519041 | Margot Michaud                                                                                                                                                        |
| 569 |    929.925826 |    293.946204 | Tyler Greenfield                                                                                                                                                      |
| 570 |    459.997131 |    370.193820 | Mathew Wedel                                                                                                                                                          |
| 571 |    920.302337 |    427.895843 | Andrew A. Farke                                                                                                                                                       |
| 572 |    983.474486 |     15.476633 | NA                                                                                                                                                                    |
| 573 |    275.971658 |    372.106277 | FJDegrange                                                                                                                                                            |
| 574 |    582.582948 |     56.642380 | Christian A. Masnaghetti                                                                                                                                              |
| 575 |    430.094640 |    614.936104 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 576 |    102.537893 |    439.159169 | Wayne Decatur                                                                                                                                                         |
| 577 |    324.974428 |    220.505940 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 578 |    413.501147 |    134.981064 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 579 |    541.832061 |    548.848749 | Andrew A. Farke                                                                                                                                                       |
| 580 |    775.289786 |    662.814623 | Scott Hartman                                                                                                                                                         |
| 581 |    741.119637 |     72.182883 | Carlos Cano-Barbacil                                                                                                                                                  |
| 582 |    679.488099 |    147.423970 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 583 |    578.862784 |    714.263964 | Steven Traver                                                                                                                                                         |
| 584 |    288.179319 |    228.871210 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 585 |     99.656221 |    464.321674 | Andy Wilson                                                                                                                                                           |
| 586 |    801.295033 |    164.275194 | Margot Michaud                                                                                                                                                        |
| 587 |    411.050285 |    121.961123 | Katie S. Collins                                                                                                                                                      |
| 588 |    870.505191 |     31.133364 | Michael Scroggie                                                                                                                                                      |
| 589 |    665.133514 |     77.653168 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 590 |    942.876124 |    261.096098 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 591 |    321.948097 |    449.772788 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 592 |    130.536026 |    306.838157 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 593 |    547.909056 |    438.034334 | Ferran Sayol                                                                                                                                                          |
| 594 |    267.980404 |     98.488025 | Mathieu Pélissié                                                                                                                                                      |
| 595 |    278.495739 |    419.472551 | Chris huh                                                                                                                                                             |
| 596 |    997.730864 |     77.701099 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 597 |    622.279848 |    318.975948 | S.Martini                                                                                                                                                             |
| 598 |    882.426449 |    621.880847 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 599 |     52.219465 |    157.562500 | Henry Lydecker                                                                                                                                                        |
| 600 |     64.068148 |    614.183393 | Campbell Fleming                                                                                                                                                      |
| 601 |    135.841075 |    725.582663 | David Orr                                                                                                                                                             |
| 602 |    669.012645 |    608.584121 | Matt Crook                                                                                                                                                            |
| 603 |    252.753252 |     71.499117 | Scott Hartman                                                                                                                                                         |
| 604 |     36.890787 |     42.586618 | S.Martini                                                                                                                                                             |
| 605 |    538.562191 |    202.525366 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 606 |    719.512255 |    698.193609 | Gareth Monger                                                                                                                                                         |
| 607 |    991.163464 |    208.208501 | Katie S. Collins                                                                                                                                                      |
| 608 |    256.880022 |    375.110339 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 609 |    272.679740 |    382.599452 | Jagged Fang Designs                                                                                                                                                   |
| 610 |    959.880049 |    659.695145 | Yan Wong                                                                                                                                                              |
| 611 |    968.867485 |     73.690847 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 612 |    572.755562 |    736.720601 | Matt Crook                                                                                                                                                            |
| 613 |     17.929967 |    599.218157 | Caleb M. Brown                                                                                                                                                        |
| 614 |    477.903384 |     31.947574 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 615 |    557.302313 |    633.317543 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 616 |    237.571874 |    599.291024 | Steven Traver                                                                                                                                                         |
| 617 |    817.295831 |    500.523757 | Maxime Dahirel                                                                                                                                                        |
| 618 |    347.952475 |    542.513918 | NA                                                                                                                                                                    |
| 619 |    154.098234 |    396.629119 | Gareth Monger                                                                                                                                                         |
| 620 |    108.557307 |    630.778481 | Marie-Aimée Allard                                                                                                                                                    |
| 621 |   1011.552472 |    744.434542 | Julio Garza                                                                                                                                                           |
| 622 |    230.381743 |     13.769296 | Zimices                                                                                                                                                               |
| 623 |    487.940021 |    536.093328 | Sarah Werning                                                                                                                                                         |
| 624 |     15.131236 |    653.797944 | Andy Wilson                                                                                                                                                           |
| 625 |    676.252865 |    107.478185 | Scott Hartman                                                                                                                                                         |
| 626 |    654.647926 |    750.250640 | Sarah Werning                                                                                                                                                         |
| 627 |    272.339563 |    292.287897 | Tasman Dixon                                                                                                                                                          |
| 628 |    726.820669 |    617.705461 | Margot Michaud                                                                                                                                                        |
| 629 |    570.572352 |     47.814761 | Scott Hartman                                                                                                                                                         |
| 630 |    695.889640 |    348.694688 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 631 |    128.387765 |    415.542711 | Matt Crook                                                                                                                                                            |
| 632 |    327.999532 |    792.701379 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 633 |     98.539250 |    782.004418 | Zimices                                                                                                                                                               |
| 634 |    164.400332 |    316.752864 | Chris huh                                                                                                                                                             |
| 635 |    634.400485 |    664.065973 | Chris huh                                                                                                                                                             |
| 636 |    325.315455 |    583.062224 | Scott Hartman                                                                                                                                                         |
| 637 |    206.146774 |     16.782357 | Margot Michaud                                                                                                                                                        |
| 638 |    790.540170 |     41.235635 | Zimices                                                                                                                                                               |
| 639 |    760.121281 |    646.471982 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 640 |    539.729455 |    232.541585 | Christoph Schomburg                                                                                                                                                   |
| 641 |    368.872234 |    598.732046 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 642 |    971.949236 |    542.935236 | Mo Hassan                                                                                                                                                             |
| 643 |    620.212087 |    462.228338 | Gareth Monger                                                                                                                                                         |
| 644 |    744.984968 |     19.241364 | Steven Traver                                                                                                                                                         |
| 645 |    168.713620 |     84.302868 | Matt Crook                                                                                                                                                            |
| 646 |    363.898315 |    651.322956 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 647 |     95.247109 |    176.874253 | Ferran Sayol                                                                                                                                                          |
| 648 |    491.891324 |    631.069434 | NA                                                                                                                                                                    |
| 649 |    793.736320 |    530.319459 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 650 |    921.009239 |     80.371464 | Dean Schnabel                                                                                                                                                         |
| 651 |    179.304405 |    308.751144 | Jonathan Wells                                                                                                                                                        |
| 652 |    201.715966 |    791.614154 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 653 |    946.372130 |    665.137188 | Mason McNair                                                                                                                                                          |
| 654 |      7.762975 |    666.562638 | Joanna Wolfe                                                                                                                                                          |
| 655 |    604.954918 |    763.233991 | Scott Reid                                                                                                                                                            |
| 656 |    712.542413 |     19.791777 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 657 |    310.512399 |    275.521883 | L. Shyamal                                                                                                                                                            |
| 658 |    182.812674 |    513.344332 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 659 |    200.125791 |    188.118218 | Gareth Monger                                                                                                                                                         |
| 660 |    830.758425 |    575.851693 | Chris huh                                                                                                                                                             |
| 661 |    713.090077 |    375.405424 | Carlos Cano-Barbacil                                                                                                                                                  |
| 662 |    258.348089 |    592.103106 | Steven Traver                                                                                                                                                         |
| 663 |     28.223129 |    661.795189 | annaleeblysse                                                                                                                                                         |
| 664 |    872.703978 |    210.040438 | Matt Crook                                                                                                                                                            |
| 665 |   1017.328194 |    703.052895 | Ferran Sayol                                                                                                                                                          |
| 666 |    416.460025 |    629.516100 | Steven Traver                                                                                                                                                         |
| 667 |    612.424721 |    536.995672 | Katie S. Collins                                                                                                                                                      |
| 668 |    995.147546 |     70.706715 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 669 |    704.633469 |    296.994158 | Zimices                                                                                                                                                               |
| 670 |    343.853577 |    706.834266 | Andrew A. Farke                                                                                                                                                       |
| 671 |    145.816747 |    305.804585 | Mathieu Pélissié                                                                                                                                                      |
| 672 |    135.044813 |    123.878412 | Kai R. Caspar                                                                                                                                                         |
| 673 |    726.150883 |    323.942923 | Steven Traver                                                                                                                                                         |
| 674 |    309.132793 |    230.477794 | Christoph Schomburg                                                                                                                                                   |
| 675 |    983.916922 |    364.063094 | Margot Michaud                                                                                                                                                        |
| 676 |    618.516425 |    344.624993 | Matt Crook                                                                                                                                                            |
| 677 |    803.244257 |    487.825145 | Steven Traver                                                                                                                                                         |
| 678 |    717.290242 |    748.038742 | Scott Reid                                                                                                                                                            |
| 679 |    684.168450 |     16.906339 | Ferran Sayol                                                                                                                                                          |
| 680 |    891.524542 |    512.339736 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 681 |    146.126669 |    670.857413 | Chris huh                                                                                                                                                             |
| 682 |     95.336687 |     93.405247 | Zimices                                                                                                                                                               |
| 683 |    836.240037 |    693.967666 | Markus A. Grohme                                                                                                                                                      |
| 684 |    341.285293 |    329.933400 | Gareth Monger                                                                                                                                                         |
| 685 |    960.113175 |    789.217496 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 686 |    858.665573 |    191.928336 | mystica                                                                                                                                                               |
| 687 |    758.151385 |    284.652873 | Matt Crook                                                                                                                                                            |
| 688 |    190.965855 |    281.388695 | Matt Crook                                                                                                                                                            |
| 689 |    312.321107 |    789.499551 | B. Duygu Özpolat                                                                                                                                                      |
| 690 |     81.511591 |    418.896124 | Isaure Scavezzoni                                                                                                                                                     |
| 691 |    126.713108 |    167.239247 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 692 |    971.057826 |    114.611985 | Skye McDavid                                                                                                                                                          |
| 693 |    799.510389 |    763.479582 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
| 694 |    330.733121 |    495.229012 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 695 |    991.248129 |    390.523687 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 696 |     59.061542 |    148.788696 | T. Michael Keesey                                                                                                                                                     |
| 697 |    295.814113 |    768.372602 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 698 |    991.063029 |    139.746686 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 699 |    318.463864 |    488.511781 | Steven Traver                                                                                                                                                         |
| 700 |    312.514681 |    649.181761 | Anthony Caravaggi                                                                                                                                                     |
| 701 |    492.822428 |    656.252745 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 702 |    217.382434 |    497.281000 | Gareth Monger                                                                                                                                                         |
| 703 |    490.773517 |    364.345804 | Ingo Braasch                                                                                                                                                          |
| 704 |    713.216180 |    391.999678 | Carlos Cano-Barbacil                                                                                                                                                  |
| 705 |    582.959871 |    251.663989 | Scott Hartman                                                                                                                                                         |
| 706 |    524.886016 |    548.428251 | Emily Willoughby                                                                                                                                                      |
| 707 |    289.082987 |    279.024550 | Tracy A. Heath                                                                                                                                                        |
| 708 |    627.206298 |    529.549478 | T. Michael Keesey                                                                                                                                                     |
| 709 |    726.480975 |    706.147694 | Scott Hartman                                                                                                                                                         |
| 710 |     10.379894 |    586.357572 | Markus A. Grohme                                                                                                                                                      |
| 711 |    805.565541 |    589.017067 | Matt Crook                                                                                                                                                            |
| 712 |    286.362236 |    148.213819 | Jagged Fang Designs                                                                                                                                                   |
| 713 |    428.522071 |    103.457601 | Zimices                                                                                                                                                               |
| 714 |    563.814765 |    222.705079 | Matt Crook                                                                                                                                                            |
| 715 |    486.278235 |    572.993494 | NA                                                                                                                                                                    |
| 716 |    933.929038 |    366.003439 | Manabu Sakamoto                                                                                                                                                       |
| 717 |    498.518644 |    594.716803 | Margot Michaud                                                                                                                                                        |
| 718 |    345.998557 |    792.139329 | C. Camilo Julián-Caballero                                                                                                                                            |
| 719 |    882.222597 |    445.757655 | Mattia Menchetti                                                                                                                                                      |
| 720 |    401.711200 |    256.320628 | Ferran Sayol                                                                                                                                                          |
| 721 |    197.895570 |    418.126610 | Matt Crook                                                                                                                                                            |
| 722 |    312.132892 |     26.513668 | Anthony Caravaggi                                                                                                                                                     |
| 723 |    705.561575 |    433.618545 | Michael Scroggie                                                                                                                                                      |
| 724 |    285.521254 |    392.821477 | Michelle Site                                                                                                                                                         |
| 725 |    955.838093 |    256.788927 | Ferran Sayol                                                                                                                                                          |
| 726 |    265.332866 |    350.743816 | Tasman Dixon                                                                                                                                                          |
| 727 |    343.469739 |    560.902572 | Gareth Monger                                                                                                                                                         |
| 728 |     39.393323 |    650.922526 | Steven Traver                                                                                                                                                         |
| 729 |    520.115126 |    534.254768 | Mathieu Basille                                                                                                                                                       |
| 730 |    498.691312 |    642.478052 | Ferran Sayol                                                                                                                                                          |
| 731 |    355.002836 |    313.770506 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 732 |     35.098822 |    701.563902 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 733 |    697.628035 |    576.340727 | Dexter R. Mardis                                                                                                                                                      |
| 734 |    656.490306 |    453.122352 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 735 |    434.576137 |    359.796407 | Andy Wilson                                                                                                                                                           |
| 736 |    117.725503 |    427.433176 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 737 |    631.454302 |    514.517701 | Gareth Monger                                                                                                                                                         |
| 738 |    843.449163 |    145.345435 | Margot Michaud                                                                                                                                                        |
| 739 |    282.497953 |    175.084267 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 740 |    198.069349 |    106.161559 | Dean Schnabel                                                                                                                                                         |
| 741 |    307.383967 |     72.493957 | Jack Mayer Wood                                                                                                                                                       |
| 742 |     95.792426 |    754.697129 | Jagged Fang Designs                                                                                                                                                   |
| 743 |    806.473849 |    278.459281 | Matt Celeskey                                                                                                                                                         |
| 744 |    805.640484 |    683.836128 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 745 |    625.196551 |    693.963155 | Tyler Greenfield                                                                                                                                                      |
| 746 |    914.680546 |    224.934221 | Margot Michaud                                                                                                                                                        |
| 747 |    782.533570 |    519.285347 | T. Michael Keesey                                                                                                                                                     |
| 748 |    552.997818 |    175.150977 | Mathieu Pélissié                                                                                                                                                      |
| 749 |     39.682584 |     31.447101 | Scott Hartman                                                                                                                                                         |
| 750 |     98.227775 |    284.475581 | Ferran Sayol                                                                                                                                                          |
| 751 |   1015.386067 |     21.902228 | Rebecca Groom                                                                                                                                                         |
| 752 |    330.652536 |    178.775409 | Steven Traver                                                                                                                                                         |
| 753 |    768.887022 |     44.314867 | Geoff Shaw                                                                                                                                                            |
| 754 |     95.992006 |    637.701371 | T. Michael Keesey                                                                                                                                                     |
| 755 |    278.340864 |    277.307492 | Matt Crook                                                                                                                                                            |
| 756 |    743.326183 |    463.809745 | Margot Michaud                                                                                                                                                        |
| 757 |    336.093642 |    597.879050 | Chris huh                                                                                                                                                             |
| 758 |     81.915633 |    188.882086 | Matt Martyniuk                                                                                                                                                        |
| 759 |    769.912729 |    364.217225 | Kamil S. Jaron                                                                                                                                                        |
| 760 |   1008.350957 |    147.261945 | Neil Kelley                                                                                                                                                           |
| 761 |    959.397443 |    628.732684 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 762 |    858.346743 |    329.737282 | Ingo Braasch                                                                                                                                                          |
| 763 |    268.363177 |    262.315002 | Matt Crook                                                                                                                                                            |
| 764 |   1016.113312 |    207.050875 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 765 |    255.544080 |    489.851206 | Tracy A. Heath                                                                                                                                                        |
| 766 |    151.678075 |    466.622464 | Zimices                                                                                                                                                               |
| 767 |    170.920191 |    190.034369 | ArtFavor & annaleeblysse                                                                                                                                              |
| 768 |    743.570673 |    701.815900 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 769 |   1016.235644 |    600.838868 | Matt Crook                                                                                                                                                            |
| 770 |     39.291153 |     64.738040 | Matt Martyniuk                                                                                                                                                        |
| 771 |    995.109560 |    201.316141 | Gareth Monger                                                                                                                                                         |
| 772 |     33.407462 |    152.658007 | Zimices                                                                                                                                                               |
| 773 |    832.393331 |    529.102776 | Matt Crook                                                                                                                                                            |
| 774 |     13.402384 |    102.162085 | Steven Traver                                                                                                                                                         |
| 775 |    991.214359 |    158.382442 | Gareth Monger                                                                                                                                                         |
| 776 |    291.577320 |    134.621785 | Jack Mayer Wood                                                                                                                                                       |
| 777 |    936.259755 |    708.358793 | Andy Wilson                                                                                                                                                           |
| 778 |    679.547099 |    744.918675 | T. Michael Keesey                                                                                                                                                     |
| 779 |    192.699465 |    567.113748 | Margot Michaud                                                                                                                                                        |
| 780 |    895.770588 |    431.527386 | Steven Traver                                                                                                                                                         |
| 781 |    108.638015 |    446.368872 | Ignacio Contreras                                                                                                                                                     |
| 782 |    534.016181 |    540.384888 | Tasman Dixon                                                                                                                                                          |
| 783 |    221.094658 |    600.242553 | Andy Wilson                                                                                                                                                           |
| 784 |     35.321661 |    722.741539 | NA                                                                                                                                                                    |
| 785 |    603.955986 |    449.947736 | Beth Reinke                                                                                                                                                           |
| 786 |    532.448386 |    648.529212 | Matt Crook                                                                                                                                                            |
| 787 |    430.855065 |    406.841890 | Xavier Giroux-Bougard                                                                                                                                                 |
| 788 |    171.187143 |    400.579900 | Tracy A. Heath                                                                                                                                                        |
| 789 |    633.027184 |    539.360829 | Carlos Cano-Barbacil                                                                                                                                                  |
| 790 |    327.376584 |    202.886109 | Scott Hartman                                                                                                                                                         |
| 791 |     60.047519 |    171.731576 | Andy Wilson                                                                                                                                                           |
| 792 |    783.242589 |    473.639345 | Emily Willoughby                                                                                                                                                      |
| 793 |     14.034399 |    674.231178 | Alexis Simon                                                                                                                                                          |
| 794 |     14.294686 |    354.158632 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 795 |    936.912819 |    446.319859 | Tracy A. Heath                                                                                                                                                        |
| 796 |    935.624907 |    152.277793 | Zimices                                                                                                                                                               |
| 797 |    409.417087 |     14.473063 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 798 |    632.722043 |    342.631625 | Xavier Giroux-Bougard                                                                                                                                                 |
| 799 |    473.901774 |    423.881105 | Ferran Sayol                                                                                                                                                          |
| 800 |    742.329397 |    292.940540 | Beth Reinke                                                                                                                                                           |
| 801 |     10.321974 |    361.364463 | Jagged Fang Designs                                                                                                                                                   |
| 802 |      9.526229 |    275.770994 | NA                                                                                                                                                                    |
| 803 |     24.470226 |     54.780713 | Ferran Sayol                                                                                                                                                          |
| 804 |    427.707466 |    602.045537 | NA                                                                                                                                                                    |
| 805 |     86.764194 |    613.282663 | Matt Crook                                                                                                                                                            |
| 806 |    478.402358 |    552.324231 | Steven Traver                                                                                                                                                         |
| 807 |   1006.150652 |    325.019351 | John Conway                                                                                                                                                           |
| 808 |    672.826213 |    575.593531 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 809 |     23.824423 |    341.963689 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 810 |    337.409084 |    777.283713 | T. Michael Keesey                                                                                                                                                     |
| 811 |    334.872796 |    767.186768 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 812 |     38.933705 |    283.754728 | Steven Traver                                                                                                                                                         |
| 813 |    693.788487 |     24.490769 | Ferran Sayol                                                                                                                                                          |
| 814 |    956.322233 |    763.935755 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 815 |    949.346608 |    692.324693 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 816 |    918.476047 |     20.501382 | Margot Michaud                                                                                                                                                        |
| 817 |    257.340825 |    310.255622 | Chloé Schmidt                                                                                                                                                         |
| 818 |    779.521913 |    644.414579 | Andy Wilson                                                                                                                                                           |
| 819 |    860.106459 |    617.602581 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 820 |    923.951814 |    442.053258 | Patrick Strutzenberger                                                                                                                                                |
| 821 |    261.601289 |    206.529776 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 822 |    933.036428 |     96.163359 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 823 |    189.998745 |     21.667746 | Nicolas Mongiardino Koch                                                                                                                                              |
| 824 |    359.529652 |    692.724732 | NA                                                                                                                                                                    |
| 825 |    503.431336 |    178.451979 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 826 |    148.505868 |    610.339119 | Tasman Dixon                                                                                                                                                          |
| 827 |     61.700320 |    351.625714 | Dmitry Bogdanov                                                                                                                                                       |
| 828 |    800.165755 |    607.941381 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 829 |    564.680398 |    240.669455 | Zimices                                                                                                                                                               |
| 830 |   1015.550449 |    227.716904 | Matt Crook                                                                                                                                                            |
| 831 |    740.750025 |    257.009624 | Beth Reinke                                                                                                                                                           |
| 832 |    300.250325 |    168.425790 | Karla Martinez                                                                                                                                                        |
| 833 |    985.190256 |    461.088959 | Zimices                                                                                                                                                               |
| 834 |    242.495248 |    107.867564 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 835 |    929.213391 |    108.641675 | Matt Crook                                                                                                                                                            |
| 836 |    196.713908 |    407.503822 | Milton Tan                                                                                                                                                            |
| 837 |    651.373791 |    692.715480 | kreidefossilien.de                                                                                                                                                    |
| 838 |    217.377331 |    280.572579 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 839 |     96.735574 |    452.353232 | Riccardo Percudani                                                                                                                                                    |
| 840 |     78.026407 |    211.452502 | Maija Karala                                                                                                                                                          |
| 841 |     67.691825 |    179.829864 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 842 |     32.313281 |    278.681296 | Scott Hartman                                                                                                                                                         |
| 843 |    585.240515 |    221.669455 | Chris huh                                                                                                                                                             |
| 844 |    377.004914 |    333.161116 | Sarah Werning                                                                                                                                                         |
| 845 |    955.892027 |    725.925572 | Tracy A. Heath                                                                                                                                                        |
| 846 |    277.898592 |    493.702689 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 847 |    791.405994 |    335.116412 | Andy Wilson                                                                                                                                                           |
| 848 |    205.433475 |    557.998630 | Scott Hartman                                                                                                                                                         |
| 849 |    428.814384 |    126.799415 | Tyler Greenfield                                                                                                                                                      |
| 850 |    701.558899 |    343.387570 | Noah Schlottman                                                                                                                                                       |
| 851 |    398.880549 |    313.770125 | Maija Karala                                                                                                                                                          |
| 852 |    908.295675 |    398.847370 | Jagged Fang Designs                                                                                                                                                   |
| 853 |    844.863531 |    478.811147 | Kent Sorgon                                                                                                                                                           |
| 854 |    763.619464 |    465.381063 | Jagged Fang Designs                                                                                                                                                   |
| 855 |    756.364710 |    769.927051 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 856 |    542.473029 |     73.507093 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                 |
| 857 |      8.336636 |     30.105522 | Julio Garza                                                                                                                                                           |
| 858 |    306.216053 |    778.026264 | Matt Crook                                                                                                                                                            |
| 859 |    929.835270 |    403.995003 | Andy Wilson                                                                                                                                                           |
| 860 |    802.979134 |    317.382707 | Matt Crook                                                                                                                                                            |
| 861 |    916.157932 |    414.592689 | Melissa Broussard                                                                                                                                                     |
| 862 |   1005.793819 |    761.618438 | Zimices                                                                                                                                                               |
| 863 |    979.372361 |    351.986706 | Gareth Monger                                                                                                                                                         |
| 864 |    783.457237 |     23.718480 | C. Camilo Julián-Caballero                                                                                                                                            |
| 865 |    763.585146 |    781.226895 | Zimices                                                                                                                                                               |
| 866 |    983.869728 |    784.738686 | NA                                                                                                                                                                    |
| 867 |    190.396287 |    300.846113 | Anthony Caravaggi                                                                                                                                                     |
| 868 |     19.993836 |    421.919550 | Kamil S. Jaron                                                                                                                                                        |
| 869 |     32.358136 |     11.255241 | Margot Michaud                                                                                                                                                        |
| 870 |    270.713132 |    609.665389 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 871 |    200.422882 |    398.947930 | Zimices                                                                                                                                                               |
| 872 |     19.654156 |    777.711830 | Matt Crook                                                                                                                                                            |
| 873 |    968.393151 |    746.255576 | Chris huh                                                                                                                                                             |
| 874 |    854.886765 |     44.798075 | Jagged Fang Designs                                                                                                                                                   |
| 875 |    323.445043 |    156.412659 | Margot Michaud                                                                                                                                                        |
| 876 |    496.035163 |    529.783995 | Tasman Dixon                                                                                                                                                          |
| 877 |    684.630297 |     94.003119 | Margot Michaud                                                                                                                                                        |
| 878 |     34.560040 |    447.879544 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 879 |     99.937270 |    140.870019 | Ferran Sayol                                                                                                                                                          |
| 880 |    874.663535 |    191.836097 | Mathilde Cordellier                                                                                                                                                   |
| 881 |    550.524226 |    621.718212 | Steven Traver                                                                                                                                                         |
| 882 |    112.026507 |    307.809650 | NA                                                                                                                                                                    |
| 883 |   1016.479985 |     42.550997 | Zimices                                                                                                                                                               |
| 884 |    757.963497 |    638.396246 | Michael Scroggie                                                                                                                                                      |
| 885 |    299.919903 |     51.349757 | Melissa Broussard                                                                                                                                                     |
| 886 |    220.994013 |      6.862978 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 887 |    998.669691 |    497.582360 | T. Michael Keesey                                                                                                                                                     |
| 888 |    953.158743 |     46.308544 | Ferran Sayol                                                                                                                                                          |
| 889 |    199.658186 |    290.006421 | T. Michael Keesey                                                                                                                                                     |
| 890 |    406.139720 |    724.738673 | NA                                                                                                                                                                    |
| 891 |    887.579207 |    391.474839 | Nina Skinner                                                                                                                                                          |
| 892 |    667.439074 |    694.744541 | Rebecca Groom                                                                                                                                                         |
| 893 |     45.886532 |    422.846921 | Smokeybjb                                                                                                                                                             |
| 894 |     44.561135 |    591.553175 | Matt Crook                                                                                                                                                            |
| 895 |    235.250109 |    488.062151 | Tony Ayling                                                                                                                                                           |
| 896 |    831.789784 |    426.424185 | Zimices                                                                                                                                                               |
| 897 |    846.357331 |    130.190931 | Kanchi Nanjo                                                                                                                                                          |
| 898 |   1003.748520 |    129.194595 | Jagged Fang Designs                                                                                                                                                   |
| 899 |    335.528887 |    668.427175 | Melissa Broussard                                                                                                                                                     |
| 900 |    215.478395 |     65.151689 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 901 |    451.719677 |    392.399093 | Margot Michaud                                                                                                                                                        |
| 902 |    333.710630 |    655.695648 | Emily Willoughby                                                                                                                                                      |
| 903 |    330.024926 |     13.259760 | Scott Reid                                                                                                                                                            |
| 904 |    405.346582 |    755.979965 | Zimices                                                                                                                                                               |
| 905 |    920.684562 |    662.461245 | Stacy Spensley (Modified)                                                                                                                                             |
| 906 |    147.240922 |      4.074255 | Tasman Dixon                                                                                                                                                          |
| 907 |    592.631553 |    783.128264 | Zimices                                                                                                                                                               |
| 908 |    983.160921 |    762.077782 | NA                                                                                                                                                                    |

    #> Your tweet has been posted!
