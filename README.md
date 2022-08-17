
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

Arthur Weasley (vectorized by T. Michael Keesey), Margot Michaud,
Gabriela Palomo-Munoz, Zimices, T. Michael Keesey, Rebecca Groom (Based
on Photo by Andreas Trepte), Sergio A. Muñoz-Gómez, Sherman F. Denton
via rawpixel.com (illustration) and Timothy J. Bartley (silhouette),
Joanna Wolfe, Chris huh, Tasman Dixon, Markus A. Grohme, Becky Barnes,
Kanchi Nanjo, Matt Martyniuk, Birgit Lang, Steven Traver, Oscar
Sanisidro, Gareth Monger, Jagged Fang Designs, Matt Crook, Unknown
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Tony Ayling (vectorized by T. Michael Keesey), Andy Wilson,
Scott Hartman, Melissa Broussard, Sarah Werning, Tracy A. Heath, Nobu
Tamura (vectorized by T. Michael Keesey), Harold N Eyster, Alexandra van
der Geer, Joshua Fowler, Collin Gross, Kent Elson Sorgon,
www.studiospectre.com, Stuart Humphries, Nobu Tamura, vectorized by
Zimices, Maija Karala, Jaime Headden, Tauana J. Cunha, Carlos
Cano-Barbacil, Jose Carlos Arenas-Monroy, Lisa Byrne, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Dean Schnabel, Tyler McCraney, T. Tischler, Meliponicultor
Itaymbere, John Curtis (vectorized by T. Michael Keesey), Tyler
Greenfield and Scott Hartman, T. Michael Keesey (after C. De Muizon),
Matthew E. Clapham, Caleb M. Brown, Florian Pfaff, kotik, Bryan
Carstens, C. Camilo Julián-Caballero, Charles R. Knight (vectorized by
T. Michael Keesey), ДиБгд (vectorized by T. Michael Keesey),
Apokryltaros (vectorized by T. Michael Keesey), Dmitry Bogdanov, Stanton
F. Fink (vectorized by T. Michael Keesey), Beth Reinke, Ignacio
Contreras, Juan Carlos Jerí, Mathew Wedel, Ben Liebeskind, Joseph J. W.
Sertich, Mark A. Loewen, L. Shyamal, Maxime Dahirel, Erika Schumacher,
Ferran Sayol, Javier Luque, Conty (vectorized by T. Michael Keesey),
Geoff Shaw, Michael P. Taylor, Johan Lindgren, Michael W. Caldwell,
Takuya Konishi, Luis M. Chiappe, Martin R. Smith, Ludwik Gąsiorowski,
Crystal Maier, Scott Hartman (modified by T. Michael Keesey), Mathieu
Basille, Ramona J Heim, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Walter Vladimir, Abraão Leite, Patrick Strutzenberger,
Griensteidl and T. Michael Keesey, Michelle Site, ArtFavor &
annaleeblysse, Antonov (vectorized by T. Michael Keesey), Tyler
Greenfield, Lafage, Frank Förster, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Alexander Schmidt-Lebuhn, Jessica Anne Miller, U.S. National Park
Service (vectorized by William Gearty), Steven Coombs, Henry Lydecker,
Mali’o Kodis, photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), xgirouxb, Richard
Lampitt, Jeremy Young / NHM (vectorization by Yan Wong), Sharon
Wegner-Larsen, G. M. Woodward, James R. Spotila and Ray Chatterji,
Jessica Rick, Chuanixn Yu, Michael Wolf (photo), Hans Hillewaert
(editing), T. Michael Keesey (vectorization), Ingo Braasch, Wynston
Cooper (photo) and Albertonykus (silhouette), Felix Vaux, Christoph
Schomburg, FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey),
Matt Celeskey, Obsidian Soul (vectorized by T. Michael Keesey), Chloé
Schmidt, Mali’o Kodis, image from the Smithsonian Institution, Smokeybjb
(modified by T. Michael Keesey), FunkMonk, Yan Wong, Kamil S. Jaron,
Lukas Panzarin, Duane Raver/USFWS, Milton Tan, Mali’o Kodis, photograph
from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), FJDegrange, Noah Schlottman, Jaime Headden, modified by
T. Michael Keesey, CNZdenek, S.Martini, Noah Schlottman, photo by Carol
Cummings, Jay Matternes (vectorized by T. Michael Keesey), Lani Mohan,
Mykle Hoban, Mattia Menchetti, Chris A. Hamilton, Michele M Tobias,
Stemonitis (photography) and T. Michael Keesey (vectorization), Ellen
Edmonson (illustration) and Timothy J. Bartley (silhouette), Konsta
Happonen, from a CC-BY-NC image by pelhonen on iNaturalist, Ieuan Jones,
Armin Reindl, Steven Blackwood, Kai R. Caspar, Bruno C. Vellutini,
Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey), Julio
Garza, Emily Willoughby, Pete Buchholz, James I. Kirkland, Luis Alcalá,
Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Cagri Cevrim, Karkemish (vectorized
by T. Michael Keesey), Scott Reid, T. K. Robinson, Matus Valach, Mali’o
Kodis, traced image from the National Science Foundation’s Turbellarian
Taxonomic Database, Julia B McHugh, Kailah Thorn & Mark Hutchinson, M
Kolmann, Tony Ayling, Heinrich Harder (vectorized by William Gearty),
Steven Coombs (vectorized by T. Michael Keesey), Rebecca Groom, Mathieu
Pélissié, E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey),
Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey), Renata F.
Martins, Arthur S. Brum, Matt Dempsey, Jack Mayer Wood, Brian Gratwicke
(photo) and T. Michael Keesey (vectorization), Jimmy Bernot, , Alex
Slavenko, Xavier Giroux-Bougard, Dave Angelini, NASA, Tim Bertelink
(modified by T. Michael Keesey), Francesco Veronesi (vectorized by T.
Michael Keesey), Smokeybjb (modified by Mike Keesey), Sherman Foote
Denton (illustration, 1897) and Timothy J. Bartley (silhouette), Robert
Bruce Horsfall (vectorized by William Gearty), Francesco “Architetto”
Rollandin, AnAgnosticGod (vectorized by T. Michael Keesey), Rene Martin,
Joe Schneid (vectorized by T. Michael Keesey), M. Antonio Todaro, Tobias
Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael
Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    650.533527 |    128.215898 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
|   2 |    451.564534 |    732.289451 | Margot Michaud                                                                                                                                                        |
|   3 |    645.117518 |    729.991899 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   4 |    175.530016 |     83.574276 | Zimices                                                                                                                                                               |
|   5 |    344.949408 |    540.608259 | T. Michael Keesey                                                                                                                                                     |
|   6 |    574.449349 |    452.436084 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
|   7 |    424.196195 |    252.194899 | NA                                                                                                                                                                    |
|   8 |    106.897390 |    396.368903 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|   9 |    573.204501 |    175.028357 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
|  10 |    509.135285 |    152.638763 | Joanna Wolfe                                                                                                                                                          |
|  11 |    119.415425 |     52.142357 | Chris huh                                                                                                                                                             |
|  12 |    778.940232 |    647.134357 | Tasman Dixon                                                                                                                                                          |
|  13 |    872.690061 |    697.539024 | Markus A. Grohme                                                                                                                                                      |
|  14 |    103.064893 |    507.781670 | Becky Barnes                                                                                                                                                          |
|  15 |    736.685760 |    318.884205 | Kanchi Nanjo                                                                                                                                                          |
|  16 |    580.837191 |    610.685332 | Matt Martyniuk                                                                                                                                                        |
|  17 |    876.506825 |    412.823465 | Margot Michaud                                                                                                                                                        |
|  18 |    843.761338 |    137.522560 | Birgit Lang                                                                                                                                                           |
|  19 |    142.873403 |    668.974505 | Margot Michaud                                                                                                                                                        |
|  20 |    922.720884 |     63.281915 | Margot Michaud                                                                                                                                                        |
|  21 |    677.751675 |    454.725608 | NA                                                                                                                                                                    |
|  22 |    191.070248 |    443.627404 | T. Michael Keesey                                                                                                                                                     |
|  23 |    104.329383 |    170.819745 | Margot Michaud                                                                                                                                                        |
|  24 |    840.981868 |    737.769352 | Steven Traver                                                                                                                                                         |
|  25 |    905.786141 |    236.996525 | Zimices                                                                                                                                                               |
|  26 |    721.784231 |    572.352323 | Steven Traver                                                                                                                                                         |
|  27 |    547.556978 |    273.220556 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  28 |    753.504975 |     70.507730 | Oscar Sanisidro                                                                                                                                                       |
|  29 |    858.878008 |    568.711437 | Gareth Monger                                                                                                                                                         |
|  30 |    765.447483 |    215.108275 | Jagged Fang Designs                                                                                                                                                   |
|  31 |    445.539724 |    533.660228 | Matt Crook                                                                                                                                                            |
|  32 |    601.908825 |    387.108082 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
|  33 |    579.388747 |    556.358378 | Tasman Dixon                                                                                                                                                          |
|  34 |    408.490154 |    328.457404 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  35 |    737.490766 |    435.451477 | Andy Wilson                                                                                                                                                           |
|  36 |    962.631527 |    359.902490 | Scott Hartman                                                                                                                                                         |
|  37 |    297.804131 |    220.446769 | Melissa Broussard                                                                                                                                                     |
|  38 |    864.301264 |    484.790854 | Sarah Werning                                                                                                                                                         |
|  39 |    228.444137 |    339.217070 | Tracy A. Heath                                                                                                                                                        |
|  40 |    454.583049 |    374.522577 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  41 |    239.259121 |     95.125163 | Matt Crook                                                                                                                                                            |
|  42 |    955.584206 |    628.262041 | Harold N Eyster                                                                                                                                                       |
|  43 |    174.797347 |    592.436386 | Gareth Monger                                                                                                                                                         |
|  44 |    228.596451 |    534.552062 | Alexandra van der Geer                                                                                                                                                |
|  45 |    489.296975 |     45.211223 | Matt Crook                                                                                                                                                            |
|  46 |    340.449525 |    123.341094 | Joshua Fowler                                                                                                                                                         |
|  47 |     84.464917 |    765.320211 | Tasman Dixon                                                                                                                                                          |
|  48 |    709.674636 |    507.842667 | Jagged Fang Designs                                                                                                                                                   |
|  49 |    124.200607 |    265.768283 | Margot Michaud                                                                                                                                                        |
|  50 |    459.775288 |    634.100860 | Collin Gross                                                                                                                                                          |
|  51 |    404.859768 |     31.950377 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  52 |    573.015877 |     69.781414 | Kent Elson Sorgon                                                                                                                                                     |
|  53 |    600.419084 |    687.532186 | www.studiospectre.com                                                                                                                                                 |
|  54 |    994.292791 |    193.227025 | Gareth Monger                                                                                                                                                         |
|  55 |    839.224468 |    353.371533 | Stuart Humphries                                                                                                                                                      |
|  56 |    345.079650 |    294.602114 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  57 |    266.493708 |    730.548657 | Zimices                                                                                                                                                               |
|  58 |    792.089560 |    772.553309 | Gareth Monger                                                                                                                                                         |
|  59 |    186.365819 |    781.807166 | Scott Hartman                                                                                                                                                         |
|  60 |    643.476364 |    252.412772 | Maija Karala                                                                                                                                                          |
|  61 |    188.312034 |     13.934951 | Gareth Monger                                                                                                                                                         |
|  62 |    379.156148 |    189.658316 | Jaime Headden                                                                                                                                                         |
|  63 |    706.308415 |     11.446041 | Markus A. Grohme                                                                                                                                                      |
|  64 |    458.279769 |    453.054991 | Tauana J. Cunha                                                                                                                                                       |
|  65 |     21.908979 |    531.709338 | NA                                                                                                                                                                    |
|  66 |    768.997084 |    627.414472 | Carlos Cano-Barbacil                                                                                                                                                  |
|  67 |    960.089987 |    743.045630 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  68 |    794.129389 |    174.956136 | Lisa Byrne                                                                                                                                                            |
|  69 |    271.066117 |    443.895656 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  70 |    550.327869 |    651.890951 | Chris huh                                                                                                                                                             |
|  71 |    731.310058 |    687.522547 | Scott Hartman                                                                                                                                                         |
|  72 |    480.825447 |    113.239751 | Jagged Fang Designs                                                                                                                                                   |
|  73 |    109.345750 |    324.486321 | Dean Schnabel                                                                                                                                                         |
|  74 |    927.568502 |    121.324590 | NA                                                                                                                                                                    |
|  75 |    443.620287 |    204.459692 | Tyler McCraney                                                                                                                                                        |
|  76 |    106.627897 |    746.883790 | T. Tischler                                                                                                                                                           |
|  77 |     66.576131 |    592.312456 | Meliponicultor Itaymbere                                                                                                                                              |
|  78 |    935.762221 |    518.191313 | Margot Michaud                                                                                                                                                        |
|  79 |    575.089025 |    752.544143 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
|  80 |    237.968043 |    281.126204 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
|  81 |    489.871959 |     21.248892 | NA                                                                                                                                                                    |
|  82 |    674.269124 |    616.316486 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
|  83 |    137.529930 |    122.334823 | Matthew E. Clapham                                                                                                                                                    |
|  84 |    866.272914 |    678.643615 | Caleb M. Brown                                                                                                                                                        |
|  85 |    290.541968 |    682.906905 | Gareth Monger                                                                                                                                                         |
|  86 |    840.235350 |     93.172918 | Florian Pfaff                                                                                                                                                         |
|  87 |    980.438154 |    382.480075 | kotik                                                                                                                                                                 |
|  88 |    277.301420 |    594.235865 | NA                                                                                                                                                                    |
|  89 |     36.664482 |    684.759969 | Bryan Carstens                                                                                                                                                        |
|  90 |    672.123731 |    331.865678 | NA                                                                                                                                                                    |
|  91 |    725.794356 |    148.523443 | C. Camilo Julián-Caballero                                                                                                                                            |
|  92 |    988.088012 |    434.580262 | Markus A. Grohme                                                                                                                                                      |
|  93 |    400.002007 |    767.302093 | Zimices                                                                                                                                                               |
|  94 |    675.258231 |     40.886157 | Margot Michaud                                                                                                                                                        |
|  95 |    841.970913 |     23.661449 | Jagged Fang Designs                                                                                                                                                   |
|  96 |    509.054172 |    589.448119 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
|  97 |    657.473654 |    173.500532 | Jagged Fang Designs                                                                                                                                                   |
|  98 |    539.034995 |    344.908082 | T. Michael Keesey                                                                                                                                                     |
|  99 |    149.729782 |    413.268321 | Sarah Werning                                                                                                                                                         |
| 100 |    235.240907 |    641.222351 | Steven Traver                                                                                                                                                         |
| 101 |    948.150551 |    557.662354 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 102 |     39.130138 |    427.527465 | NA                                                                                                                                                                    |
| 103 |    927.346771 |    298.943726 | Matt Crook                                                                                                                                                            |
| 104 |    534.857459 |    483.519918 | NA                                                                                                                                                                    |
| 105 |     65.144735 |    684.151747 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 106 |    939.238688 |    166.756254 | Margot Michaud                                                                                                                                                        |
| 107 |    694.550761 |    773.931505 | Dmitry Bogdanov                                                                                                                                                       |
| 108 |    703.070472 |    394.465688 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 109 |    965.339308 |    269.174013 | Jagged Fang Designs                                                                                                                                                   |
| 110 |    701.632180 |    182.386612 | Gareth Monger                                                                                                                                                         |
| 111 |    722.654969 |    230.633024 | Beth Reinke                                                                                                                                                           |
| 112 |     30.843938 |    347.821887 | Tauana J. Cunha                                                                                                                                                       |
| 113 |    859.538983 |    188.513105 | Ignacio Contreras                                                                                                                                                     |
| 114 |    526.163001 |    755.647698 | Margot Michaud                                                                                                                                                        |
| 115 |    484.588355 |    313.882922 | Juan Carlos Jerí                                                                                                                                                      |
| 116 |    228.363553 |    567.005986 | Mathew Wedel                                                                                                                                                          |
| 117 |    990.871569 |    700.262581 | Ben Liebeskind                                                                                                                                                        |
| 118 |    727.859498 |    119.119673 | Margot Michaud                                                                                                                                                        |
| 119 |     96.563317 |    346.228554 | Matt Crook                                                                                                                                                            |
| 120 |    741.704996 |    475.588146 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 121 |    571.254866 |    526.784799 | Margot Michaud                                                                                                                                                        |
| 122 |    737.236121 |    517.524642 | L. Shyamal                                                                                                                                                            |
| 123 |    539.260354 |    785.039047 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 124 |    888.643800 |    713.444084 | Sarah Werning                                                                                                                                                         |
| 125 |    429.531515 |    432.746957 | Jagged Fang Designs                                                                                                                                                   |
| 126 |   1008.439143 |    412.268776 | Zimices                                                                                                                                                               |
| 127 |     24.190916 |    649.490524 | Maxime Dahirel                                                                                                                                                        |
| 128 |    637.670743 |    211.728217 | Gareth Monger                                                                                                                                                         |
| 129 |    210.712995 |    224.583689 | Erika Schumacher                                                                                                                                                      |
| 130 |    823.454781 |    309.069000 | Dmitry Bogdanov                                                                                                                                                       |
| 131 |    510.657008 |    433.608534 | T. Michael Keesey                                                                                                                                                     |
| 132 |    534.577666 |    211.899592 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 133 |    313.613659 |    329.623992 | Gareth Monger                                                                                                                                                         |
| 134 |    792.991656 |    317.971106 | NA                                                                                                                                                                    |
| 135 |    627.240850 |    289.480882 | Ferran Sayol                                                                                                                                                          |
| 136 |    725.956452 |    716.962175 | Javier Luque                                                                                                                                                          |
| 137 |    791.981816 |    497.143522 | Zimices                                                                                                                                                               |
| 138 |    225.918727 |    669.171056 | Scott Hartman                                                                                                                                                         |
| 139 |    517.499615 |    730.280271 | Margot Michaud                                                                                                                                                        |
| 140 |    712.324509 |    252.874399 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 141 |    514.933373 |    693.534300 | NA                                                                                                                                                                    |
| 142 |    595.347018 |    786.580095 | Geoff Shaw                                                                                                                                                            |
| 143 |    884.303588 |    645.075953 | Andy Wilson                                                                                                                                                           |
| 144 |    148.148842 |    297.078879 | Gareth Monger                                                                                                                                                         |
| 145 |    969.132669 |    776.180715 | Margot Michaud                                                                                                                                                        |
| 146 |    616.583574 |    570.335967 | Matt Crook                                                                                                                                                            |
| 147 |    469.366211 |    597.434820 | Michael P. Taylor                                                                                                                                                     |
| 148 |    302.221388 |     18.495091 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 149 |    264.791030 |     36.200711 | Martin R. Smith                                                                                                                                                       |
| 150 |    702.309201 |     91.140380 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 151 |    798.325111 |    596.313351 | Andy Wilson                                                                                                                                                           |
| 152 |   1006.749608 |    495.062261 | Ludwik Gąsiorowski                                                                                                                                                    |
| 153 |    361.120605 |    786.918884 | NA                                                                                                                                                                    |
| 154 |    537.112059 |    381.914217 | Scott Hartman                                                                                                                                                         |
| 155 |    996.526295 |    465.978816 | Crystal Maier                                                                                                                                                         |
| 156 |    217.589623 |     31.451185 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 157 |    398.151011 |     84.682292 | Steven Traver                                                                                                                                                         |
| 158 |    596.763775 |    117.042074 | Mathieu Basille                                                                                                                                                       |
| 159 |    470.875261 |    669.505819 | Ramona J Heim                                                                                                                                                         |
| 160 |    776.969090 |    555.718814 | Andy Wilson                                                                                                                                                           |
| 161 |    641.848442 |    305.880399 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 162 |    909.537412 |     15.645421 | Walter Vladimir                                                                                                                                                       |
| 163 |    996.474131 |    334.155654 | Abraão Leite                                                                                                                                                          |
| 164 |    985.804649 |    569.486279 | Markus A. Grohme                                                                                                                                                      |
| 165 |    736.168423 |    736.578391 | Patrick Strutzenberger                                                                                                                                                |
| 166 |     64.520483 |    482.115053 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 167 |    873.660761 |    334.972322 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 168 |    467.966296 |    292.552033 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 169 |    999.308308 |    779.962535 | Steven Traver                                                                                                                                                         |
| 170 |    534.729367 |    449.126194 | Matt Crook                                                                                                                                                            |
| 171 |    933.890120 |    439.699918 | Zimices                                                                                                                                                               |
| 172 |    883.530518 |    780.851403 | Steven Traver                                                                                                                                                         |
| 173 |    861.062807 |    654.874931 | T. Michael Keesey                                                                                                                                                     |
| 174 |    263.276202 |    245.351348 | Tracy A. Heath                                                                                                                                                        |
| 175 |    828.825662 |    597.618985 | Zimices                                                                                                                                                               |
| 176 |    773.652054 |    285.809556 | Michelle Site                                                                                                                                                         |
| 177 |    167.180566 |    212.786060 | ArtFavor & annaleeblysse                                                                                                                                              |
| 178 |    785.494206 |    251.937790 | Ferran Sayol                                                                                                                                                          |
| 179 |    655.717874 |    378.397148 | Steven Traver                                                                                                                                                         |
| 180 |    187.082092 |    742.284593 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 181 |    768.089376 |    526.302043 | Jagged Fang Designs                                                                                                                                                   |
| 182 |     39.237492 |    302.144020 | Tyler Greenfield                                                                                                                                                      |
| 183 |    628.789582 |    485.438679 | Lafage                                                                                                                                                                |
| 184 |   1007.207025 |     45.460336 | Matt Crook                                                                                                                                                            |
| 185 |    121.606912 |    710.291208 | Frank Förster                                                                                                                                                         |
| 186 |    674.983273 |    542.175064 | Zimices                                                                                                                                                               |
| 187 |    502.931980 |    797.390422 | NA                                                                                                                                                                    |
| 188 |    629.797286 |     15.663574 | Ferran Sayol                                                                                                                                                          |
| 189 |    675.152542 |    707.874003 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 190 |    178.672800 |    558.010402 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 191 |    512.138568 |    555.171482 | Jaime Headden                                                                                                                                                         |
| 192 |    495.640305 |    618.630696 | Jagged Fang Designs                                                                                                                                                   |
| 193 |    395.999057 |    600.106842 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 194 |     63.752078 |    396.986458 | Jessica Anne Miller                                                                                                                                                   |
| 195 |    949.626416 |    457.465804 | Zimices                                                                                                                                                               |
| 196 |   1008.800151 |    100.427517 | Ferran Sayol                                                                                                                                                          |
| 197 |     97.141796 |     89.092524 | Tauana J. Cunha                                                                                                                                                       |
| 198 |     45.044538 |    465.207249 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 199 |    577.255403 |    718.387138 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 200 |    314.553811 |     65.817877 | Steven Coombs                                                                                                                                                         |
| 201 |    135.352963 |    368.895246 | Gareth Monger                                                                                                                                                         |
| 202 |    857.293415 |    302.156838 | Tracy A. Heath                                                                                                                                                        |
| 203 |    229.125974 |    195.077812 | Henry Lydecker                                                                                                                                                        |
| 204 |    196.342942 |    515.143915 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 205 |    137.436617 |    623.866628 | xgirouxb                                                                                                                                                              |
| 206 |    610.188188 |    158.225771 | Zimices                                                                                                                                                               |
| 207 |    124.780255 |    592.785730 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 208 |    216.736428 |    177.795861 | Sharon Wegner-Larsen                                                                                                                                                  |
| 209 |    236.622361 |    167.588250 | Andy Wilson                                                                                                                                                           |
| 210 |    813.714749 |    540.871127 | Matt Martyniuk                                                                                                                                                        |
| 211 |    273.324998 |    781.641388 | Birgit Lang                                                                                                                                                           |
| 212 |    664.195260 |    644.761089 | G. M. Woodward                                                                                                                                                        |
| 213 |    337.096318 |    270.102437 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 214 |    534.195605 |    198.930021 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 215 |    601.228945 |    322.069603 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 216 |    826.115236 |    271.992992 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 217 |    985.765322 |     23.372483 | Zimices                                                                                                                                                               |
| 218 |    980.207341 |    296.725538 | Zimices                                                                                                                                                               |
| 219 |    122.497582 |    437.286874 | Michelle Site                                                                                                                                                         |
| 220 |    532.349634 |    240.487141 | Chris huh                                                                                                                                                             |
| 221 |    943.411381 |    492.288082 | Harold N Eyster                                                                                                                                                       |
| 222 |    771.719221 |    386.177840 | Jessica Rick                                                                                                                                                          |
| 223 |    303.891662 |    437.271976 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 224 |    589.545057 |     31.788536 | Andy Wilson                                                                                                                                                           |
| 225 |    241.346714 |    505.814700 | Chuanixn Yu                                                                                                                                                           |
| 226 |    661.121864 |    201.169251 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
| 227 |    284.093085 |    656.871218 | Ingo Braasch                                                                                                                                                          |
| 228 |    652.186152 |    766.631339 | Andy Wilson                                                                                                                                                           |
| 229 |    934.614730 |    782.140377 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 230 |    358.029389 |    231.923775 | Felix Vaux                                                                                                                                                            |
| 231 |    820.237597 |    253.039276 | Zimices                                                                                                                                                               |
| 232 |    952.310475 |    701.801969 | Ingo Braasch                                                                                                                                                          |
| 233 |    785.040513 |    715.778977 | NA                                                                                                                                                                    |
| 234 |    338.759697 |     24.537534 | Tasman Dixon                                                                                                                                                          |
| 235 |    528.778663 |    523.969040 | C. Camilo Julián-Caballero                                                                                                                                            |
| 236 |      9.657246 |    191.573148 | NA                                                                                                                                                                    |
| 237 |    674.575278 |     84.183153 | Zimices                                                                                                                                                               |
| 238 |    927.443409 |    331.157833 | Steven Traver                                                                                                                                                         |
| 239 |    410.354152 |    139.269580 | Christoph Schomburg                                                                                                                                                   |
| 240 |     16.534737 |    754.156718 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 241 |    808.636333 |    233.540729 | Steven Traver                                                                                                                                                         |
| 242 |     19.513618 |    777.883340 | NA                                                                                                                                                                    |
| 243 |    663.805533 |     62.006417 | Margot Michaud                                                                                                                                                        |
| 244 |    821.533518 |     47.933492 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 245 |     47.059820 |      3.632343 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 246 |    467.731346 |    753.887793 | Jagged Fang Designs                                                                                                                                                   |
| 247 |    235.423613 |    791.764296 | Matt Celeskey                                                                                                                                                         |
| 248 |    168.332357 |    129.273482 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 249 |    850.637582 |    534.946341 | Zimices                                                                                                                                                               |
| 250 |    504.359917 |    386.542593 | Chloé Schmidt                                                                                                                                                         |
| 251 |    634.483108 |    507.577645 | NA                                                                                                                                                                    |
| 252 |    679.291618 |    531.677600 | Scott Hartman                                                                                                                                                         |
| 253 |    144.867733 |    595.110312 | Andy Wilson                                                                                                                                                           |
| 254 |     20.515156 |    150.788674 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 255 |    708.733954 |    749.030490 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 256 |    737.975090 |    666.299169 | Andy Wilson                                                                                                                                                           |
| 257 |    364.680229 |     63.609655 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 258 |    224.963320 |    228.640179 | Zimices                                                                                                                                                               |
| 259 |     95.408040 |    365.638489 | Matt Martyniuk                                                                                                                                                        |
| 260 |    506.002499 |    679.976610 | FunkMonk                                                                                                                                                              |
| 261 |    795.402609 |     30.734627 | Yan Wong                                                                                                                                                              |
| 262 |     62.087154 |    375.382095 | Kamil S. Jaron                                                                                                                                                        |
| 263 |    201.046694 |    258.275822 | Ignacio Contreras                                                                                                                                                     |
| 264 |    719.671964 |    644.577534 | FunkMonk                                                                                                                                                              |
| 265 |     57.534834 |    292.647104 | Lukas Panzarin                                                                                                                                                        |
| 266 |    394.203104 |    220.474845 | Margot Michaud                                                                                                                                                        |
| 267 |    621.432773 |     57.834019 | Duane Raver/USFWS                                                                                                                                                     |
| 268 |    859.712886 |     35.193601 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 269 |    845.593981 |      5.987176 | T. Michael Keesey                                                                                                                                                     |
| 270 |    513.417936 |    115.193055 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 271 |    620.991369 |    777.629750 | Carlos Cano-Barbacil                                                                                                                                                  |
| 272 |    250.703545 |    600.155169 | Ignacio Contreras                                                                                                                                                     |
| 273 |    216.544387 |    413.813035 | Michelle Site                                                                                                                                                         |
| 274 |    238.235892 |     40.883638 | Tasman Dixon                                                                                                                                                          |
| 275 |    425.173103 |    306.191330 | Milton Tan                                                                                                                                                            |
| 276 |    855.429312 |    101.823422 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 277 |     69.210717 |    716.581850 | Ferran Sayol                                                                                                                                                          |
| 278 |     28.397543 |     20.828618 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                 |
| 279 |    597.048080 |    281.065877 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 280 |    127.852717 |    638.881451 | Gareth Monger                                                                                                                                                         |
| 281 |    414.354316 |    747.245139 | Ignacio Contreras                                                                                                                                                     |
| 282 |    498.131483 |    229.498541 | NA                                                                                                                                                                    |
| 283 |    327.870136 |    757.371049 | NA                                                                                                                                                                    |
| 284 |    901.240251 |    149.978298 | FJDegrange                                                                                                                                                            |
| 285 |    336.078717 |    244.900163 | Felix Vaux                                                                                                                                                            |
| 286 |    971.309677 |    788.989975 | Chris huh                                                                                                                                                             |
| 287 |    417.941006 |    591.779254 | Zimices                                                                                                                                                               |
| 288 |    296.836544 |    272.308439 | Scott Hartman                                                                                                                                                         |
| 289 |    217.653867 |    680.361850 | Margot Michaud                                                                                                                                                        |
| 290 |    272.525235 |    635.384783 | Steven Traver                                                                                                                                                         |
| 291 |    956.628862 |    317.949589 | Matt Crook                                                                                                                                                            |
| 292 |    536.089958 |    668.867584 | Jagged Fang Designs                                                                                                                                                   |
| 293 |    647.649649 |    572.366519 | NA                                                                                                                                                                    |
| 294 |    496.135665 |     81.751971 | Carlos Cano-Barbacil                                                                                                                                                  |
| 295 |    407.507825 |    175.587168 | Noah Schlottman                                                                                                                                                       |
| 296 |    974.246718 |    466.941834 | Dean Schnabel                                                                                                                                                         |
| 297 |    534.254255 |    307.490555 | Ignacio Contreras                                                                                                                                                     |
| 298 |    983.659448 |    421.971153 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 299 |    281.326631 |    707.132719 | Margot Michaud                                                                                                                                                        |
| 300 |    608.632315 |    128.410879 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 301 |    223.933913 |     55.821750 | Zimices                                                                                                                                                               |
| 302 |    187.890452 |    170.088391 | CNZdenek                                                                                                                                                              |
| 303 |    808.921522 |    293.878420 | Joanna Wolfe                                                                                                                                                          |
| 304 |    763.789732 |    125.389283 | NA                                                                                                                                                                    |
| 305 |    484.637381 |    482.297151 | Scott Hartman                                                                                                                                                         |
| 306 |    771.916714 |    751.952681 | Collin Gross                                                                                                                                                          |
| 307 |     38.463830 |    269.699983 | T. Michael Keesey                                                                                                                                                     |
| 308 |    564.995239 |    605.944345 | S.Martini                                                                                                                                                             |
| 309 |    961.234084 |    246.520157 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 310 |    247.474754 |    685.418137 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 311 |    273.634229 |    157.895324 | Andy Wilson                                                                                                                                                           |
| 312 |    182.809896 |    294.783588 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 313 |   1006.222159 |    300.581193 | Lani Mohan                                                                                                                                                            |
| 314 |    538.536852 |    600.536620 | xgirouxb                                                                                                                                                              |
| 315 |    908.132628 |    362.534628 | Andy Wilson                                                                                                                                                           |
| 316 |    560.820590 |    223.436628 | Mykle Hoban                                                                                                                                                           |
| 317 |    469.531894 |    789.207125 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 318 |    868.376342 |    386.624170 | Mattia Menchetti                                                                                                                                                      |
| 319 |    975.315445 |    103.415971 | Zimices                                                                                                                                                               |
| 320 |    998.974703 |     79.098402 | Mathew Wedel                                                                                                                                                          |
| 321 |    817.017885 |    390.816093 | CNZdenek                                                                                                                                                              |
| 322 |    664.173706 |    404.613684 | Margot Michaud                                                                                                                                                        |
| 323 |    176.319485 |    226.039581 | Matt Crook                                                                                                                                                            |
| 324 |    810.645858 |    419.925104 | Chris A. Hamilton                                                                                                                                                     |
| 325 |    179.787655 |    533.004011 | Jagged Fang Designs                                                                                                                                                   |
| 326 |    969.762610 |    681.684507 | Birgit Lang                                                                                                                                                           |
| 327 |    596.118661 |    635.817616 | Steven Traver                                                                                                                                                         |
| 328 |    565.207639 |    106.457668 | T. Michael Keesey                                                                                                                                                     |
| 329 |    191.843240 |    235.199975 | Carlos Cano-Barbacil                                                                                                                                                  |
| 330 |    428.005769 |    220.414693 | Dmitry Bogdanov                                                                                                                                                       |
| 331 |    605.362635 |    500.375174 | Michelle Site                                                                                                                                                         |
| 332 |    353.937385 |    257.938536 | NA                                                                                                                                                                    |
| 333 |    909.096338 |    597.756757 | Matt Crook                                                                                                                                                            |
| 334 |   1006.681575 |    547.066904 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 335 |     13.343193 |    726.760706 | Michele M Tobias                                                                                                                                                      |
| 336 |    632.552253 |     70.925293 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 337 |    407.060314 |    355.199517 | Sarah Werning                                                                                                                                                         |
| 338 |    522.357904 |    704.134492 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 339 |    238.983891 |    764.278318 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 340 |   1003.751429 |    321.578987 | Chris huh                                                                                                                                                             |
| 341 |    115.560082 |    296.420820 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 342 |    963.808940 |    206.066099 | Ieuan Jones                                                                                                                                                           |
| 343 |    232.366412 |     78.490763 | Tasman Dixon                                                                                                                                                          |
| 344 |    337.088854 |     36.067290 | Kent Elson Sorgon                                                                                                                                                     |
| 345 |    287.781143 |    285.248836 | FunkMonk                                                                                                                                                              |
| 346 |    730.708402 |    792.309568 | NA                                                                                                                                                                    |
| 347 |    148.553109 |    361.106288 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 348 |    818.744994 |    791.467830 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 349 |    604.603997 |    203.801325 | Andy Wilson                                                                                                                                                           |
| 350 |    254.562135 |    156.704818 | Armin Reindl                                                                                                                                                          |
| 351 |    241.434865 |    382.682157 | NA                                                                                                                                                                    |
| 352 |    230.710545 |    432.995493 | Mathieu Basille                                                                                                                                                       |
| 353 |    851.659835 |    517.699541 | Steven Blackwood                                                                                                                                                      |
| 354 |    767.649640 |    488.170677 | Matt Crook                                                                                                                                                            |
| 355 |    813.444408 |    701.201414 | Scott Hartman                                                                                                                                                         |
| 356 |    626.606172 |    318.811667 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 357 |    572.705070 |    409.757316 | Kai R. Caspar                                                                                                                                                         |
| 358 |     20.174789 |    627.326789 | Matt Crook                                                                                                                                                            |
| 359 |    807.951724 |      9.608638 | Scott Hartman                                                                                                                                                         |
| 360 |    692.869080 |    695.286924 | Margot Michaud                                                                                                                                                        |
| 361 |    323.950905 |     54.044440 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 362 |     12.399327 |    106.861395 | Bruno C. Vellutini                                                                                                                                                    |
| 363 |    296.852212 |    627.082821 | Matt Crook                                                                                                                                                            |
| 364 |    470.157436 |    585.921804 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 365 |    581.192348 |    774.475608 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 366 |    408.691380 |     70.589722 | Julio Garza                                                                                                                                                           |
| 367 |    989.864785 |      4.946457 | Markus A. Grohme                                                                                                                                                      |
| 368 |    414.914493 |    163.176892 | Jagged Fang Designs                                                                                                                                                   |
| 369 |    816.303655 |    205.431009 | Zimices                                                                                                                                                               |
| 370 |    218.158646 |    203.000299 | Emily Willoughby                                                                                                                                                      |
| 371 |    724.929115 |     34.456857 | Ignacio Contreras                                                                                                                                                     |
| 372 |    322.558936 |    748.688831 | Scott Hartman                                                                                                                                                         |
| 373 |    755.701720 |    760.406272 | Scott Hartman                                                                                                                                                         |
| 374 |    512.519076 |    317.204086 | Ignacio Contreras                                                                                                                                                     |
| 375 |    644.256260 |    668.810766 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 376 |    492.377275 |    252.297769 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 377 |   1000.532806 |    583.904064 | Markus A. Grohme                                                                                                                                                      |
| 378 |    879.268968 |    305.262995 | Jagged Fang Designs                                                                                                                                                   |
| 379 |    942.631612 |    715.080907 | Collin Gross                                                                                                                                                          |
| 380 |    299.420015 |     33.376323 | Armin Reindl                                                                                                                                                          |
| 381 |    445.096132 |    132.030261 | Alexandra van der Geer                                                                                                                                                |
| 382 |    307.683752 |    785.138950 | Yan Wong                                                                                                                                                              |
| 383 |    221.023201 |    768.890274 | Zimices                                                                                                                                                               |
| 384 |    136.778150 |    756.421605 | Jagged Fang Designs                                                                                                                                                   |
| 385 |    757.112536 |    712.180333 | Gareth Monger                                                                                                                                                         |
| 386 |   1002.965460 |    114.075603 | Emily Willoughby                                                                                                                                                      |
| 387 |    622.812228 |    336.636823 | Scott Hartman                                                                                                                                                         |
| 388 |     82.518198 |    467.233733 | Pete Buchholz                                                                                                                                                         |
| 389 |    773.920661 |    791.759939 | Chris huh                                                                                                                                                             |
| 390 |    683.070081 |    761.485263 | Zimices                                                                                                                                                               |
| 391 |    208.914396 |    251.214360 | Steven Blackwood                                                                                                                                                      |
| 392 |    957.945153 |    580.157462 | T. Michael Keesey                                                                                                                                                     |
| 393 |     18.926732 |    255.629775 | Gareth Monger                                                                                                                                                         |
| 394 |    397.543519 |    675.756441 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 395 |    114.648587 |    249.318431 | Andy Wilson                                                                                                                                                           |
| 396 |    226.811196 |    464.390864 | Cagri Cevrim                                                                                                                                                          |
| 397 |    633.835761 |    351.983647 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 398 |    654.273620 |    590.813239 | Ferran Sayol                                                                                                                                                          |
| 399 |    558.309274 |    672.940522 | Scott Reid                                                                                                                                                            |
| 400 |    288.101622 |    546.126893 | NA                                                                                                                                                                    |
| 401 |    487.922959 |    271.502622 | Steven Coombs                                                                                                                                                         |
| 402 |    260.643987 |    263.171617 | T. K. Robinson                                                                                                                                                        |
| 403 |    519.557427 |    253.187582 | Matus Valach                                                                                                                                                          |
| 404 |     40.256755 |    570.920536 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 405 |    956.898336 |     14.411297 | Scott Hartman                                                                                                                                                         |
| 406 |    862.674965 |    716.181187 | Chris huh                                                                                                                                                             |
| 407 |    538.991297 |    771.329367 | Zimices                                                                                                                                                               |
| 408 |    498.905956 |    414.188804 | Julia B McHugh                                                                                                                                                        |
| 409 |    109.420903 |    721.512437 | Zimices                                                                                                                                                               |
| 410 |    205.399350 |    789.897929 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 411 |    820.839312 |    402.875623 | Ferran Sayol                                                                                                                                                          |
| 412 |     17.754784 |    372.907464 | M Kolmann                                                                                                                                                             |
| 413 |    604.052930 |     17.904148 | Dean Schnabel                                                                                                                                                         |
| 414 |    674.113659 |    481.869872 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 415 |    878.953153 |    138.309142 | Jagged Fang Designs                                                                                                                                                   |
| 416 |    681.405457 |    376.394032 | Yan Wong                                                                                                                                                              |
| 417 |    462.054566 |    695.164012 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 418 |    171.633986 |    447.665196 | Christoph Schomburg                                                                                                                                                   |
| 419 |    860.223703 |    601.290127 | Zimices                                                                                                                                                               |
| 420 |    951.574765 |    403.919266 | Ferran Sayol                                                                                                                                                          |
| 421 |     98.856455 |    240.487933 | Tony Ayling                                                                                                                                                           |
| 422 |    584.702133 |      8.502601 | NA                                                                                                                                                                    |
| 423 |    168.677810 |    623.153829 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 424 |    657.644290 |    740.231972 | Gareth Monger                                                                                                                                                         |
| 425 |    788.831752 |    396.537713 | Armin Reindl                                                                                                                                                          |
| 426 |    588.851903 |    747.454282 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 427 |    491.609312 |    183.580631 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 428 |    923.659306 |    681.864294 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 429 |    842.259614 |    219.723087 | Gareth Monger                                                                                                                                                         |
| 430 |    293.442780 |     96.399877 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 431 |    823.320303 |     65.087110 | Margot Michaud                                                                                                                                                        |
| 432 |   1000.169406 |    271.916669 | Matt Crook                                                                                                                                                            |
| 433 |    861.706686 |    179.545269 | Erika Schumacher                                                                                                                                                      |
| 434 |    902.754398 |    653.843999 | Kai R. Caspar                                                                                                                                                         |
| 435 |    556.680160 |    633.194083 | Rebecca Groom                                                                                                                                                         |
| 436 |    103.503869 |    658.708890 | Margot Michaud                                                                                                                                                        |
| 437 |    734.328974 |    607.686716 | Gareth Monger                                                                                                                                                         |
| 438 |     28.389087 |     40.453829 | Mathieu Pélissié                                                                                                                                                      |
| 439 |    976.952048 |    537.682636 | Gareth Monger                                                                                                                                                         |
| 440 |    531.610984 |    230.741131 | Andy Wilson                                                                                                                                                           |
| 441 |    409.954331 |    295.558230 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 442 |    654.433538 |    523.200148 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 443 |    893.790564 |    178.801476 | Renata F. Martins                                                                                                                                                     |
| 444 |    570.824333 |    314.538512 | C. Camilo Julián-Caballero                                                                                                                                            |
| 445 |    505.375675 |    672.308281 | Caleb M. Brown                                                                                                                                                        |
| 446 |    622.461639 |    751.855691 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 447 |    304.182236 |    669.068646 | Scott Hartman                                                                                                                                                         |
| 448 |    549.966555 |     42.612438 | Arthur S. Brum                                                                                                                                                        |
| 449 |    234.660802 |    405.292850 | Zimices                                                                                                                                                               |
| 450 |    961.819206 |    512.127739 | NA                                                                                                                                                                    |
| 451 |    789.847964 |    271.813744 | Matt Dempsey                                                                                                                                                          |
| 452 |    768.966110 |    735.271110 | Markus A. Grohme                                                                                                                                                      |
| 453 |    173.468006 |    156.614744 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 454 |    770.940450 |    512.656996 | Jack Mayer Wood                                                                                                                                                       |
| 455 |    513.883674 |    364.676348 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 456 |    918.690823 |    752.073844 | Milton Tan                                                                                                                                                            |
| 457 |    997.626681 |    557.709843 | Zimices                                                                                                                                                               |
| 458 |    811.186619 |    109.384818 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 459 |    892.857448 |     26.185521 | CNZdenek                                                                                                                                                              |
| 460 |    662.011322 |    564.311276 | T. Michael Keesey                                                                                                                                                     |
| 461 |    882.818453 |    322.639523 | Walter Vladimir                                                                                                                                                       |
| 462 |    404.334812 |    490.061560 | Jimmy Bernot                                                                                                                                                          |
| 463 |    547.889012 |    725.610547 |                                                                                                                                                                       |
| 464 |    517.330960 |    569.093522 | Gareth Monger                                                                                                                                                         |
| 465 |    558.219728 |     29.883879 | Alex Slavenko                                                                                                                                                         |
| 466 |    773.604468 |    724.629255 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 467 |    406.897454 |    722.371627 | Chris huh                                                                                                                                                             |
| 468 |    123.926986 |    552.994502 | Jimmy Bernot                                                                                                                                                          |
| 469 |    474.975419 |    424.340889 | Felix Vaux                                                                                                                                                            |
| 470 |    458.963349 |    220.073927 | Xavier Giroux-Bougard                                                                                                                                                 |
| 471 |    594.224679 |    562.000131 | Scott Hartman                                                                                                                                                         |
| 472 |    621.844689 |    435.738155 | T. Michael Keesey                                                                                                                                                     |
| 473 |    844.410503 |     49.730605 | Rebecca Groom                                                                                                                                                         |
| 474 |    518.591124 |    341.055959 | Birgit Lang                                                                                                                                                           |
| 475 |   1007.842004 |    531.228614 | Andy Wilson                                                                                                                                                           |
| 476 |     13.566720 |    451.654999 | Ferran Sayol                                                                                                                                                          |
| 477 |    175.682160 |    386.718276 | Melissa Broussard                                                                                                                                                     |
| 478 |    153.323618 |    243.477512 | Jagged Fang Designs                                                                                                                                                   |
| 479 |    170.194436 |    350.903894 | Dave Angelini                                                                                                                                                         |
| 480 |    754.732189 |    241.721851 | Collin Gross                                                                                                                                                          |
| 481 |    967.432786 |     83.521305 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 482 |    441.396450 |    673.457563 | NASA                                                                                                                                                                  |
| 483 |    867.568122 |    509.144233 | Chris huh                                                                                                                                                             |
| 484 |   1006.466891 |    446.307496 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 485 |    597.413887 |    267.729545 | Matt Crook                                                                                                                                                            |
| 486 |    294.933579 |    511.829209 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 487 |    338.129455 |     16.654160 | T. Michael Keesey                                                                                                                                                     |
| 488 |     74.699487 |     67.819060 | Margot Michaud                                                                                                                                                        |
| 489 |    731.417958 |    408.118930 | Tasman Dixon                                                                                                                                                          |
| 490 |    494.852180 |    217.345827 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 491 |    780.220637 |    532.865681 | Markus A. Grohme                                                                                                                                                      |
| 492 |    911.323280 |    675.825643 | Gareth Monger                                                                                                                                                         |
| 493 |     16.786662 |    268.654111 | Kamil S. Jaron                                                                                                                                                        |
| 494 |    256.575568 |    177.794207 | Martin R. Smith                                                                                                                                                       |
| 495 |    861.566536 |    759.498923 | Margot Michaud                                                                                                                                                        |
| 496 |    769.989118 |    151.822970 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 497 |    806.420729 |    552.063200 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 498 |   1005.334344 |    664.812070 | Armin Reindl                                                                                                                                                          |
| 499 |    513.879900 |    641.061563 | Armin Reindl                                                                                                                                                          |
| 500 |    705.003036 |    377.809416 | T. Michael Keesey                                                                                                                                                     |
| 501 |    514.582556 |    268.992508 | T. Michael Keesey                                                                                                                                                     |
| 502 |    408.510670 |    733.538844 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 503 |    627.602989 |    634.699014 | NA                                                                                                                                                                    |
| 504 |    888.849517 |    619.348899 | Steven Traver                                                                                                                                                         |
| 505 |    248.787339 |     27.549526 | NA                                                                                                                                                                    |
| 506 |    806.019114 |    278.992114 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 507 |     28.347356 |    386.066188 | Ferran Sayol                                                                                                                                                          |
| 508 |    735.433333 |    453.303044 | C. Camilo Julián-Caballero                                                                                                                                            |
| 509 |    672.202591 |    440.228608 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 510 |    568.631762 |    203.554930 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 511 |    386.260824 |    371.906289 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 512 |    655.815568 |    790.405132 | Rene Martin                                                                                                                                                           |
| 513 |    972.201154 |    545.684030 | Rene Martin                                                                                                                                                           |
| 514 |    514.444257 |    191.317960 | Scott Hartman                                                                                                                                                         |
| 515 |    104.780712 |    570.908151 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 516 |    158.334369 |    532.025149 | T. Michael Keesey                                                                                                                                                     |
| 517 |    644.857943 |    535.595799 | Birgit Lang                                                                                                                                                           |
| 518 |    416.981305 |    342.768998 | Jagged Fang Designs                                                                                                                                                   |
| 519 |    507.362331 |    301.719983 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 520 |    448.623149 |    289.752569 | Dmitry Bogdanov                                                                                                                                                       |
| 521 |     88.822087 |    254.883324 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |

    #> Your tweet has been posted!
