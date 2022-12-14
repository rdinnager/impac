
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

Gareth Monger, Maxime Dahirel (digitisation), Kees van Achterberg et al
(doi: 10.3897/BDJ.8.e49017)(original publication), Noah Schlottman,
Scott Hartman, Noah Schlottman, photo from Casey Dunn, C. Camilo
Julián-Caballero, Dexter R. Mardis, Konsta Happonen, from a CC-BY-NC
image by pelhonen on iNaturalist, Sharon Wegner-Larsen, Ferran Sayol,
Jaime Headden, Matt Crook, Rachel Shoop, (unknown), Jake Warner, T.
Tischler, Yan Wong, T. Michael Keesey, Jiekun He, Andrew A. Farke, Jan
A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Abraão Leite, Jagged Fang Designs,
Thea Boodhoo (photograph) and T. Michael Keesey (vectorization), Birgit
Lang, Kimberly Haddrell, Tyler Greenfield, Zimices, Gabriela
Palomo-Munoz, Caleb Brown, C. W. Nash (illustration) and Timothy J.
Bartley (silhouette), Andrew R. Gehrke, Steven Traver, FJDegrange, Maija
Karala, FunkMonk, Mathew Wedel, Armin Reindl, Matt Martyniuk, Carlos
Cano-Barbacil, Nobu Tamura (vectorized by T. Michael Keesey), Chris huh,
Henry Lydecker, Robbie N. Cada (vectorized by T. Michael Keesey), Ellen
Edmonson (illustration) and Timothy J. Bartley (silhouette),
TaraTaylorDesign, Christian A. Masnaghetti, Daniel Jaron, Markus A.
Grohme, Emily Willoughby, Felix Vaux, Mette Aumala, Michelle Site, Nobu
Tamura (vectorized by A. Verrière), Cesar Julian, Margot Michaud, david
maas / dave hone, Beth Reinke, Chase Brownstein, Tony Ayling (vectorized
by T. Michael Keesey), Julio Garza, Andy Wilson, Catherine Yasuda, A. H.
Baldwin (vectorized by T. Michael Keesey), Smokeybjb, xgirouxb, Ignacio
Contreras, Yan Wong from photo by Denes Emoke, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Dmitry Bogdanov, Tasman Dixon, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Hugo Gruson,
Milton Tan, T. Michael Keesey (after James & al.), André Karwath
(vectorized by T. Michael Keesey), Dave Angelini, Steven Haddock
• Jellywatch.org, B. Duygu Özpolat, Noah Schlottman, photo by Martin
V. Sørensen, Shyamal, Taenadoman, ArtFavor & annaleeblysse, Katie S.
Collins, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), James R. Spotila and Ray Chatterji, Mali’o Kodis, image
from the Smithsonian Institution, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Servien
(vectorized by T. Michael Keesey), Mason McNair, Christoph Schomburg,
Scarlet23 (vectorized by T. Michael Keesey), Kamil S. Jaron, Iain Reid,
Stanton F. Fink (vectorized by T. Michael Keesey), CNZdenek, Robert
Bruce Horsfall, vectorized by Zimices, Neil Kelley, T. K. Robinson,
Ville Koistinen and T. Michael Keesey, Becky Barnes, Smokeybjb
(vectorized by T. Michael Keesey), Dean Schnabel, H. F. O. March
(modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
Burton Robert, USFWS, Bruno Maggia, Yusan Yang, Noah Schlottman, photo
by Casey Dunn, Juan Carlos Jerí, Mr E? (vectorized by T. Michael
Keesey), Robert Gay, Harold N Eyster, Qiang Ou, Mattia Menchetti, Alex
Slavenko, Trond R. Oskars, Sarah Werning, Conty (vectorized by T.
Michael Keesey), Myriam\_Ramirez, Owen Jones, Mary Harrsch (modified by
T. Michael Keesey), Greg Schechter (original photo), Renato Santos
(vector silhouette), Sibi (vectorized by T. Michael Keesey), Emil
Schmidt (vectorized by Maxime Dahirel), Yan Wong from illustration by
Charles Orbigny, Mike Hanson, T. Michael Keesey (after Kukalová),
Matthew Hooge (vectorized by T. Michael Keesey), T. Michael Keesey
(after A. Y. Ivantsov), Michael Scroggie, Matt Wilkins, Melissa Ingala,
Emma Hughes, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy
J. Bartley (silhouette), Haplochromis (vectorized by T. Michael Keesey),
Christine Axon, RS, Cathy, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Fernando Carezzano, Lukasiniho, Kai R. Caspar, Nobu Tamura,
vectorized by Zimices, Noah Schlottman, photo by Adam G. Clause, Darren
Naish (vectorized by T. Michael Keesey), Lukas Panzarin, T. Michael
Keesey (after MPF), Siobhon Egan, Todd Marshall, vectorized by Zimices,
Griensteidl and T. Michael Keesey, Mykle Hoban, Chloé Schmidt, Tracy A.
Heath, Nobu Tamura (modified by T. Michael Keesey), Inessa Voet, Noah
Schlottman, photo by Antonio Guillén, Walter Vladimir, Noah Schlottman,
photo by Carol Cummings, DFoidl (vectorized by T. Michael Keesey), Erika
Schumacher, Obsidian Soul (vectorized by T. Michael Keesey), Estelle
Bourdon, Pranav Iyer (grey ideas), Roberto Díaz Sibaja, Alexander
Schmidt-Lebuhn, Steven Coombs, Campbell Fleming, Caleb M. Brown, Matt
Dempsey, Julien Louys, Michael B. H. (vectorized by T. Michael Keesey),
Sergio A. Muñoz-Gómez, Thibaut Brunet, Duane Raver/USFWS, Jakovche,
David Orr, Ville-Veikko Sinkkonen, Duane Raver (vectorized by T. Michael
Keesey), Falconaumanni and T. Michael Keesey, Rebecca Groom, Jaime A.
Headden (vectorized by T. Michael Keesey), Joanna Wolfe, DW Bapst
(modified from Bulman, 1970), Tony Ayling, Jaime Headden (vectorized by
T. Michael Keesey), Nina Skinner, Jack Mayer Wood, Hans Hillewaert,
Frank Denota, Sarah Alewijnse, Daniel Stadtmauer, Ingo Braasch, Gustav
Mützel, Mateus Zica (modified by T. Michael Keesey), Mattia Menchetti /
Yan Wong, Ghedoghedo (vectorized by T. Michael Keesey), Martin Kevil, L.
Shyamal, Martin R. Smith, Johan Lindgren, Michael W. Caldwell, Takuya
Konishi, Luis M. Chiappe, Christopher Laumer (vectorized by T. Michael
Keesey), Dann Pigdon, Cagri Cevrim, Anilocra (vectorization by Yan
Wong), M Kolmann

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     521.56509 |    755.678882 | Gareth Monger                                                                                                                                                         |
|   2 |     715.56002 |    377.497486 | Gareth Monger                                                                                                                                                         |
|   3 |     970.61332 |    550.458580 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
|   4 |     325.93972 |    478.409052 | Noah Schlottman                                                                                                                                                       |
|   5 |      63.41368 |    257.515339 | Scott Hartman                                                                                                                                                         |
|   6 |      82.13045 |    495.136398 | NA                                                                                                                                                                    |
|   7 |     514.09490 |    554.594225 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
|   8 |     574.73494 |    277.202380 | C. Camilo Julián-Caballero                                                                                                                                            |
|   9 |     692.06843 |    151.263595 | Dexter R. Mardis                                                                                                                                                      |
|  10 |     633.81747 |     61.910567 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
|  11 |     273.89217 |    271.379980 | NA                                                                                                                                                                    |
|  12 |     853.71542 |    608.989393 | Sharon Wegner-Larsen                                                                                                                                                  |
|  13 |     894.84621 |     71.528907 | Ferran Sayol                                                                                                                                                          |
|  14 |     413.26159 |    189.525896 | Jaime Headden                                                                                                                                                         |
|  15 |     145.95011 |    192.112106 | Matt Crook                                                                                                                                                            |
|  16 |     405.84341 |     82.889165 | Rachel Shoop                                                                                                                                                          |
|  17 |     315.93216 |    337.709502 | (unknown)                                                                                                                                                             |
|  18 |     220.80663 |    749.868320 | Scott Hartman                                                                                                                                                         |
|  19 |     263.09705 |    245.227254 | Gareth Monger                                                                                                                                                         |
|  20 |     813.89751 |    304.630899 | Jake Warner                                                                                                                                                           |
|  21 |     784.99093 |    445.324329 | T. Tischler                                                                                                                                                           |
|  22 |     204.61575 |    371.004860 | Yan Wong                                                                                                                                                              |
|  23 |     674.42592 |    550.795403 | T. Michael Keesey                                                                                                                                                     |
|  24 |     811.54599 |     82.407741 | Jiekun He                                                                                                                                                             |
|  25 |     327.52016 |    584.169109 | Andrew A. Farke                                                                                                                                                       |
|  26 |     926.32788 |    761.174836 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  27 |     949.20953 |    174.166119 | NA                                                                                                                                                                    |
|  28 |      78.96290 |    583.730458 | Abraão Leite                                                                                                                                                          |
|  29 |     760.04023 |    701.212671 | Jagged Fang Designs                                                                                                                                                   |
|  30 |     321.31143 |    741.666411 | Jiekun He                                                                                                                                                             |
|  31 |      96.56224 |    120.676719 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
|  32 |     538.25735 |    122.036814 | Ferran Sayol                                                                                                                                                          |
|  33 |     521.50642 |    675.499462 | Birgit Lang                                                                                                                                                           |
|  34 |     462.79528 |    430.722930 | Kimberly Haddrell                                                                                                                                                     |
|  35 |     211.29478 |    448.904449 | Tyler Greenfield                                                                                                                                                      |
|  36 |     543.64829 |    485.250303 | Zimices                                                                                                                                                               |
|  37 |     154.92344 |    315.491246 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  38 |     166.47392 |     87.530218 | T. Tischler                                                                                                                                                           |
|  39 |     237.51366 |     61.125589 | NA                                                                                                                                                                    |
|  40 |     618.96692 |    444.648227 | Jagged Fang Designs                                                                                                                                                   |
|  41 |     394.14959 |    707.264359 | Caleb Brown                                                                                                                                                           |
|  42 |     932.81483 |    662.136314 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
|  43 |     926.08349 |    301.462465 | Andrew R. Gehrke                                                                                                                                                      |
|  44 |      83.51070 |    753.702923 | Zimices                                                                                                                                                               |
|  45 |     107.00055 |    435.815381 | Steven Traver                                                                                                                                                         |
|  46 |     840.69796 |    179.660799 | FJDegrange                                                                                                                                                            |
|  47 |     901.11796 |    482.326675 | Maija Karala                                                                                                                                                          |
|  48 |     688.25827 |    749.375404 | FunkMonk                                                                                                                                                              |
|  49 |     265.63393 |    150.781334 | Mathew Wedel                                                                                                                                                          |
|  50 |     985.42865 |    339.623581 | Armin Reindl                                                                                                                                                          |
|  51 |     221.99473 |    665.853562 | Steven Traver                                                                                                                                                         |
|  52 |     377.98649 |    656.979884 | Matt Martyniuk                                                                                                                                                        |
|  53 |     663.42172 |    183.109723 | Jagged Fang Designs                                                                                                                                                   |
|  54 |     273.73172 |    407.254477 | Carlos Cano-Barbacil                                                                                                                                                  |
|  55 |     338.18074 |    376.264613 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  56 |     728.87685 |    236.001014 | C. Camilo Julián-Caballero                                                                                                                                            |
|  57 |     474.41861 |     22.702453 | NA                                                                                                                                                                    |
|  58 |     733.41775 |     79.181466 | T. Michael Keesey                                                                                                                                                     |
|  59 |     782.99183 |    768.853526 | Chris huh                                                                                                                                                             |
|  60 |     412.70982 |    292.580028 | Jagged Fang Designs                                                                                                                                                   |
|  61 |      63.31141 |    671.481759 | C. Camilo Julián-Caballero                                                                                                                                            |
|  62 |     199.20826 |    537.510163 | Matt Martyniuk                                                                                                                                                        |
|  63 |     424.53334 |    445.318325 | Henry Lydecker                                                                                                                                                        |
|  64 |      94.74454 |     36.042214 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  65 |     337.00698 |     28.207059 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
|  66 |     919.52445 |    704.815342 | Chris huh                                                                                                                                                             |
|  67 |      72.44439 |    351.297433 | Jiekun He                                                                                                                                                             |
|  68 |     426.24626 |    566.863996 | TaraTaylorDesign                                                                                                                                                      |
|  69 |     188.72750 |    708.188955 | Christian A. Masnaghetti                                                                                                                                              |
|  70 |     480.32464 |    340.888145 | Daniel Jaron                                                                                                                                                          |
|  71 |     632.64216 |    680.680352 | Matt Martyniuk                                                                                                                                                        |
|  72 |     270.06515 |    206.049807 | Markus A. Grohme                                                                                                                                                      |
|  73 |     291.17011 |    299.861136 | Emily Willoughby                                                                                                                                                      |
|  74 |     693.61186 |    294.493401 | Felix Vaux                                                                                                                                                            |
|  75 |     600.33934 |    621.008206 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  76 |     861.58569 |    322.403424 | Mette Aumala                                                                                                                                                          |
|  77 |     325.97643 |     83.748364 | Ferran Sayol                                                                                                                                                          |
|  78 |     946.25265 |    213.205120 | Michelle Site                                                                                                                                                         |
|  79 |     819.96232 |    467.960548 | Gareth Monger                                                                                                                                                         |
|  80 |     162.74991 |    626.778664 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
|  81 |     214.31714 |    228.071048 | NA                                                                                                                                                                    |
|  82 |     979.66951 |     89.119324 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  83 |     783.77173 |    155.458951 | NA                                                                                                                                                                    |
|  84 |     802.42477 |    515.829320 | Cesar Julian                                                                                                                                                          |
|  85 |     420.47069 |    759.596585 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  86 |     391.38572 |    377.893343 | C. Camilo Julián-Caballero                                                                                                                                            |
|  87 |     633.04584 |    505.978885 | FunkMonk                                                                                                                                                              |
|  88 |     780.00013 |     38.202408 | Gareth Monger                                                                                                                                                         |
|  89 |     983.41200 |    263.744497 | Margot Michaud                                                                                                                                                        |
|  90 |     981.57711 |    451.784757 | Scott Hartman                                                                                                                                                         |
|  91 |     661.14026 |    223.165981 | david maas / dave hone                                                                                                                                                |
|  92 |      50.87959 |    185.880734 | Beth Reinke                                                                                                                                                           |
|  93 |     766.24384 |    196.356436 | Chase Brownstein                                                                                                                                                      |
|  94 |     972.65149 |    418.422044 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  95 |     344.69725 |    646.213304 | Julio Garza                                                                                                                                                           |
|  96 |     520.60524 |    194.391298 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
|  97 |     827.05766 |    251.103509 | Margot Michaud                                                                                                                                                        |
|  98 |     666.90905 |    119.262230 | Margot Michaud                                                                                                                                                        |
|  99 |     481.42286 |     82.452419 | Gareth Monger                                                                                                                                                         |
| 100 |     541.95053 |     52.008834 | Andy Wilson                                                                                                                                                           |
| 101 |     371.15914 |    252.406848 | Catherine Yasuda                                                                                                                                                      |
| 102 |     938.27734 |    370.618257 | Matt Crook                                                                                                                                                            |
| 103 |     743.33339 |    282.586397 | Zimices                                                                                                                                                               |
| 104 |     204.77502 |    491.635542 | Steven Traver                                                                                                                                                         |
| 105 |     446.88624 |    137.244623 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 106 |     613.53413 |    735.669876 | Smokeybjb                                                                                                                                                             |
| 107 |     809.11386 |    534.187919 | xgirouxb                                                                                                                                                              |
| 108 |     878.29918 |    138.023136 | NA                                                                                                                                                                    |
| 109 |     993.44201 |    717.941161 | Chris huh                                                                                                                                                             |
| 110 |     973.91304 |    234.132291 | Ignacio Contreras                                                                                                                                                     |
| 111 |     169.98000 |    268.504627 | Jagged Fang Designs                                                                                                                                                   |
| 112 |     714.74200 |    177.809085 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 113 |     456.02434 |    723.199232 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 114 |     459.58327 |    734.536359 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 115 |     573.63292 |    140.505731 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 116 |      77.28531 |    538.838550 | NA                                                                                                                                                                    |
| 117 |      62.94096 |    126.852595 | NA                                                                                                                                                                    |
| 118 |     461.35774 |    102.463807 | Margot Michaud                                                                                                                                                        |
| 119 |     951.83816 |      9.810041 | Dmitry Bogdanov                                                                                                                                                       |
| 120 |      59.92647 |    707.463052 | Tasman Dixon                                                                                                                                                          |
| 121 |     375.87993 |    330.883961 | Ignacio Contreras                                                                                                                                                     |
| 122 |      15.61132 |    104.084327 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 123 |     565.85340 |    771.610683 | Scott Hartman                                                                                                                                                         |
| 124 |     543.01724 |    426.348765 | Hugo Gruson                                                                                                                                                           |
| 125 |     675.60658 |     14.964601 | Zimices                                                                                                                                                               |
| 126 |      42.97701 |     19.884979 | Jagged Fang Designs                                                                                                                                                   |
| 127 |      21.87772 |    438.768680 | NA                                                                                                                                                                    |
| 128 |     523.35240 |     85.337883 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 129 |     152.69051 |    118.405315 | Jagged Fang Designs                                                                                                                                                   |
| 130 |      36.36535 |     68.977846 | Chris huh                                                                                                                                                             |
| 131 |     923.97942 |    608.873938 | Margot Michaud                                                                                                                                                        |
| 132 |     191.26495 |    148.141706 | Andy Wilson                                                                                                                                                           |
| 133 |     378.72861 |      5.692900 | Milton Tan                                                                                                                                                            |
| 134 |     369.48569 |    412.453823 | Steven Traver                                                                                                                                                         |
| 135 |     465.16985 |    649.335460 | Zimices                                                                                                                                                               |
| 136 |     831.51368 |    694.607387 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 137 |     672.89396 |     93.133972 | Markus A. Grohme                                                                                                                                                      |
| 138 |     701.05104 |     25.557949 | Scott Hartman                                                                                                                                                         |
| 139 |     162.27861 |    772.017358 | Zimices                                                                                                                                                               |
| 140 |     678.75277 |    661.769215 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 141 |     112.00605 |    367.965135 | Scott Hartman                                                                                                                                                         |
| 142 |     283.64732 |    782.248040 | Matt Crook                                                                                                                                                            |
| 143 |     160.62764 |    407.435751 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                       |
| 144 |     758.80495 |    164.881972 | Zimices                                                                                                                                                               |
| 145 |     468.06410 |    683.567185 | Scott Hartman                                                                                                                                                         |
| 146 |     998.45517 |    506.325264 | Tasman Dixon                                                                                                                                                          |
| 147 |     862.36062 |    465.448927 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 148 |     506.85428 |    787.086398 | Dave Angelini                                                                                                                                                         |
| 149 |     315.28017 |    123.460967 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 150 |     429.67639 |    734.577973 | B. Duygu Özpolat                                                                                                                                                      |
| 151 |     815.70627 |    422.828303 | Jaime Headden                                                                                                                                                         |
| 152 |     668.51165 |    323.970631 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 153 |     977.53496 |    114.669293 | Tasman Dixon                                                                                                                                                          |
| 154 |     251.76438 |    478.205348 | Emily Willoughby                                                                                                                                                      |
| 155 |     847.21547 |    301.337432 | NA                                                                                                                                                                    |
| 156 |     873.67180 |    655.035521 | Shyamal                                                                                                                                                               |
| 157 |     408.43320 |    613.522479 | Zimices                                                                                                                                                               |
| 158 |     962.37728 |    286.414127 | Taenadoman                                                                                                                                                            |
| 159 |     998.15962 |    790.124114 | Scott Hartman                                                                                                                                                         |
| 160 |     172.64311 |    242.038427 | Emily Willoughby                                                                                                                                                      |
| 161 |     317.35965 |    685.767747 | ArtFavor & annaleeblysse                                                                                                                                              |
| 162 |     469.47261 |    311.172201 | Zimices                                                                                                                                                               |
| 163 |     961.08606 |    686.535899 | Katie S. Collins                                                                                                                                                      |
| 164 |     567.62228 |    206.044247 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 165 |     274.23809 |     80.852643 | Zimices                                                                                                                                                               |
| 166 |     669.59113 |    107.314317 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 167 |     129.18117 |     62.958437 | NA                                                                                                                                                                    |
| 168 |     293.65491 |    470.925992 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 169 |      29.42369 |    712.184840 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 170 |     675.80850 |    710.145100 | Matt Crook                                                                                                                                                            |
| 171 |     844.00582 |    492.620722 | Matt Crook                                                                                                                                                            |
| 172 |     240.47286 |    317.305521 | Dmitry Bogdanov                                                                                                                                                       |
| 173 |     831.29663 |    238.575757 | Jagged Fang Designs                                                                                                                                                   |
| 174 |      70.00208 |    496.644169 | Ignacio Contreras                                                                                                                                                     |
| 175 |     586.17633 |    519.082186 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 176 |     908.79235 |    633.067620 | Smokeybjb                                                                                                                                                             |
| 177 |      24.02038 |     35.726817 | Margot Michaud                                                                                                                                                        |
| 178 |     763.88009 |    739.685445 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 179 |     840.19405 |    786.071597 | Chris huh                                                                                                                                                             |
| 180 |     418.99407 |    484.869560 | Ferran Sayol                                                                                                                                                          |
| 181 |     934.25099 |    148.158665 | Dmitry Bogdanov                                                                                                                                                       |
| 182 |    1006.36174 |    437.976798 | Matt Crook                                                                                                                                                            |
| 183 |     525.60350 |    162.209429 | Andy Wilson                                                                                                                                                           |
| 184 |    1008.66812 |    756.705224 | Felix Vaux                                                                                                                                                            |
| 185 |     292.68272 |    114.991802 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 186 |     586.28900 |    163.050762 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 187 |     953.73567 |    326.877823 | Mason McNair                                                                                                                                                          |
| 188 |     570.61420 |     30.144987 | Christoph Schomburg                                                                                                                                                   |
| 189 |     380.81947 |    474.934079 | Zimices                                                                                                                                                               |
| 190 |     420.20251 |    262.064614 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 191 |     327.75937 |    786.866988 | Kamil S. Jaron                                                                                                                                                        |
| 192 |     124.41255 |    779.583620 | T. Michael Keesey                                                                                                                                                     |
| 193 |      44.40289 |    397.931343 | T. Michael Keesey                                                                                                                                                     |
| 194 |     883.55018 |    343.062554 | Zimices                                                                                                                                                               |
| 195 |     610.97767 |    108.545832 | Ferran Sayol                                                                                                                                                          |
| 196 |     595.35691 |    690.681939 | Jagged Fang Designs                                                                                                                                                   |
| 197 |     772.46109 |     18.437061 | Andy Wilson                                                                                                                                                           |
| 198 |    1004.28464 |     65.742707 | NA                                                                                                                                                                    |
| 199 |    1001.98989 |    136.965133 | Margot Michaud                                                                                                                                                        |
| 200 |     472.84406 |    468.433433 | Zimices                                                                                                                                                               |
| 201 |     526.53794 |     94.806655 | Christoph Schomburg                                                                                                                                                   |
| 202 |     279.17573 |      8.585328 | Gareth Monger                                                                                                                                                         |
| 203 |     553.85989 |      9.918243 | Chris huh                                                                                                                                                             |
| 204 |     870.96214 |    502.865209 | Gareth Monger                                                                                                                                                         |
| 205 |     286.32121 |    540.674967 | Gareth Monger                                                                                                                                                         |
| 206 |     820.23298 |    220.692645 | Iain Reid                                                                                                                                                             |
| 207 |     423.86316 |    676.335489 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 208 |     144.15651 |    106.638104 | Scott Hartman                                                                                                                                                         |
| 209 |     872.37075 |    261.014928 | Chris huh                                                                                                                                                             |
| 210 |      41.84320 |    523.997398 | CNZdenek                                                                                                                                                              |
| 211 |     587.43650 |    711.539637 | T. Michael Keesey                                                                                                                                                     |
| 212 |     199.90755 |    406.814216 | Jiekun He                                                                                                                                                             |
| 213 |     450.29538 |    308.442151 | Emily Willoughby                                                                                                                                                      |
| 214 |     732.08258 |    309.814185 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 215 |     557.89443 |    595.896543 | Neil Kelley                                                                                                                                                           |
| 216 |     608.70732 |    782.244194 | Matt Crook                                                                                                                                                            |
| 217 |     141.10318 |    595.923911 | T. K. Robinson                                                                                                                                                        |
| 218 |     480.46428 |    587.589872 | Matt Crook                                                                                                                                                            |
| 219 |     880.07209 |    676.172589 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 220 |     481.83745 |    236.764895 | Becky Barnes                                                                                                                                                          |
| 221 |     990.51195 |    610.145797 | Maija Karala                                                                                                                                                          |
| 222 |     249.47784 |    614.220570 | Scott Hartman                                                                                                                                                         |
| 223 |     837.51585 |    510.011055 | Markus A. Grohme                                                                                                                                                      |
| 224 |     459.45404 |    333.601154 | Andy Wilson                                                                                                                                                           |
| 225 |     231.93544 |    777.189185 | Christoph Schomburg                                                                                                                                                   |
| 226 |     773.89617 |    653.468182 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 227 |     173.37904 |    472.281986 | Dean Schnabel                                                                                                                                                         |
| 228 |     566.37487 |    565.317406 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 229 |     992.65580 |    153.962265 | Ignacio Contreras                                                                                                                                                     |
| 230 |     366.26127 |    548.319338 | Ferran Sayol                                                                                                                                                          |
| 231 |     657.34613 |     60.590133 | Kamil S. Jaron                                                                                                                                                        |
| 232 |     693.07730 |    432.812009 | NA                                                                                                                                                                    |
| 233 |      43.62584 |    508.335267 | Smokeybjb                                                                                                                                                             |
| 234 |     929.64917 |    487.114930 | Gareth Monger                                                                                                                                                         |
| 235 |     480.12601 |    620.809971 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 236 |     397.27443 |    135.502599 | Burton Robert, USFWS                                                                                                                                                  |
| 237 |     189.51624 |     55.738040 | Bruno Maggia                                                                                                                                                          |
| 238 |      24.26358 |    415.590937 | Yusan Yang                                                                                                                                                            |
| 239 |     429.24340 |    638.571643 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 240 |     603.47374 |     31.415201 | Chris huh                                                                                                                                                             |
| 241 |     832.03848 |     14.924625 | Juan Carlos Jerí                                                                                                                                                      |
| 242 |     359.35577 |    132.271072 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 243 |     890.02117 |    276.659462 | Matt Crook                                                                                                                                                            |
| 244 |      16.57776 |    486.422550 | Margot Michaud                                                                                                                                                        |
| 245 |     127.10998 |    138.480480 | Matt Crook                                                                                                                                                            |
| 246 |     747.35306 |    671.914299 | Robert Gay                                                                                                                                                            |
| 247 |     786.14989 |    547.833637 | Chris huh                                                                                                                                                             |
| 248 |     148.93079 |    287.252761 | Harold N Eyster                                                                                                                                                       |
| 249 |     887.48420 |    576.756176 | Michelle Site                                                                                                                                                         |
| 250 |     620.94734 |    757.228871 | NA                                                                                                                                                                    |
| 251 |      49.89128 |     98.174429 | Christoph Schomburg                                                                                                                                                   |
| 252 |    1011.61010 |    659.643165 | Qiang Ou                                                                                                                                                              |
| 253 |     856.73734 |    717.110057 | Maija Karala                                                                                                                                                          |
| 254 |      19.94658 |    143.910043 | Ferran Sayol                                                                                                                                                          |
| 255 |     631.92135 |    463.723695 | Mattia Menchetti                                                                                                                                                      |
| 256 |     171.11296 |    218.292596 | Alex Slavenko                                                                                                                                                         |
| 257 |     175.66510 |    589.209144 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 258 |     892.39525 |    729.061098 | CNZdenek                                                                                                                                                              |
| 259 |     469.13100 |    257.091949 | Trond R. Oskars                                                                                                                                                       |
| 260 |     159.66248 |    791.439154 | Zimices                                                                                                                                                               |
| 261 |     915.48352 |    235.357678 | NA                                                                                                                                                                    |
| 262 |     192.96975 |    302.236572 | Sarah Werning                                                                                                                                                         |
| 263 |     801.65557 |    199.147037 | Yan Wong                                                                                                                                                              |
| 264 |     361.85951 |    280.055093 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 265 |     790.31026 |    475.934982 | Zimices                                                                                                                                                               |
| 266 |     613.70985 |    144.076043 | Ferran Sayol                                                                                                                                                          |
| 267 |      44.68180 |    287.341575 | Myriam\_Ramirez                                                                                                                                                       |
| 268 |     209.14422 |    716.433906 | Dave Angelini                                                                                                                                                         |
| 269 |     577.21423 |    657.496509 | Armin Reindl                                                                                                                                                          |
| 270 |     260.97019 |    139.211267 | Zimices                                                                                                                                                               |
| 271 |     187.26482 |    786.611855 | Owen Jones                                                                                                                                                            |
| 272 |     210.65625 |    277.693588 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 273 |     654.80822 |     30.524966 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                    |
| 274 |     452.60401 |    672.459433 | Matt Crook                                                                                                                                                            |
| 275 |     849.46364 |    528.698416 | Scott Hartman                                                                                                                                                         |
| 276 |      39.32631 |     57.528814 | Scott Hartman                                                                                                                                                         |
| 277 |     326.92458 |    353.391911 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 278 |     620.24376 |    648.968829 | Tasman Dixon                                                                                                                                                          |
| 279 |     219.44821 |    545.092698 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 280 |     366.62590 |    736.677541 | Ferran Sayol                                                                                                                                                          |
| 281 |     879.29001 |    300.998151 | Andy Wilson                                                                                                                                                           |
| 282 |      54.55198 |    418.235870 | Matt Crook                                                                                                                                                            |
| 283 |     323.56901 |     50.820095 | Matt Crook                                                                                                                                                            |
| 284 |     149.80480 |    233.607120 | CNZdenek                                                                                                                                                              |
| 285 |     258.27449 |    513.552320 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 286 |     496.60306 |     41.790833 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 287 |     159.36568 |    130.787846 | Mike Hanson                                                                                                                                                           |
| 288 |     836.80812 |    719.538352 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 289 |     450.06804 |    769.833116 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 290 |     430.95271 |    136.408731 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 291 |     729.87277 |    131.016249 | Michael Scroggie                                                                                                                                                      |
| 292 |     618.62903 |     72.792825 | Matt Wilkins                                                                                                                                                          |
| 293 |     551.33756 |    793.533754 | Ignacio Contreras                                                                                                                                                     |
| 294 |     136.75893 |    392.391799 | Chris huh                                                                                                                                                             |
| 295 |     638.12143 |    587.112398 | Melissa Ingala                                                                                                                                                        |
| 296 |     901.59782 |    247.036779 | Steven Traver                                                                                                                                                         |
| 297 |     251.04049 |    759.838395 | Robert Gay                                                                                                                                                            |
| 298 |     994.65852 |    633.426814 | CNZdenek                                                                                                                                                              |
| 299 |     911.67454 |    419.171119 | Katie S. Collins                                                                                                                                                      |
| 300 |     849.62164 |    642.853572 | Emma Hughes                                                                                                                                                           |
| 301 |      94.23351 |     13.944914 | T. Michael Keesey                                                                                                                                                     |
| 302 |     139.22224 |    272.914945 | Tasman Dixon                                                                                                                                                          |
| 303 |     793.87975 |    680.625527 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 304 |      49.90693 |    143.301720 | Gareth Monger                                                                                                                                                         |
| 305 |     552.12555 |     91.767062 | Matt Crook                                                                                                                                                            |
| 306 |     312.72468 |    289.699632 | C. Camilo Julián-Caballero                                                                                                                                            |
| 307 |     878.69733 |    111.593362 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 308 |     846.36910 |    767.388167 | FJDegrange                                                                                                                                                            |
| 309 |      17.98600 |    402.250632 | Christine Axon                                                                                                                                                        |
| 310 |     301.69819 |     96.276995 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 311 |     686.86754 |     57.262809 | Michael Scroggie                                                                                                                                                      |
| 312 |     473.53722 |    706.126895 | Yan Wong                                                                                                                                                              |
| 313 |     223.72443 |    177.880562 | RS                                                                                                                                                                    |
| 314 |     649.56105 |    423.410667 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 315 |     791.89651 |     63.459412 | Steven Traver                                                                                                                                                         |
| 316 |     450.42452 |    239.904636 | Cathy                                                                                                                                                                 |
| 317 |     139.89743 |    675.968272 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 318 |     615.77326 |    325.503744 | Matt Crook                                                                                                                                                            |
| 319 |    1006.34805 |    257.023447 | Scott Hartman                                                                                                                                                         |
| 320 |     107.81456 |    168.375510 | Fernando Carezzano                                                                                                                                                    |
| 321 |     419.18611 |    320.585375 | Lukasiniho                                                                                                                                                            |
| 322 |     313.83131 |    185.212561 | Kai R. Caspar                                                                                                                                                         |
| 323 |    1003.73520 |    483.653219 | Kamil S. Jaron                                                                                                                                                        |
| 324 |     729.32737 |    738.404755 | Michelle Site                                                                                                                                                         |
| 325 |     546.70056 |    465.748348 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 326 |     652.49437 |    624.459838 | C. Camilo Julián-Caballero                                                                                                                                            |
| 327 |     787.24716 |    283.139538 | Margot Michaud                                                                                                                                                        |
| 328 |     987.40579 |    200.197652 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 329 |     977.04722 |     65.987846 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 330 |     793.36554 |    788.439198 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 331 |      99.07662 |    695.083563 | Jagged Fang Designs                                                                                                                                                   |
| 332 |     332.61469 |    214.850573 | Ferran Sayol                                                                                                                                                          |
| 333 |     279.88894 |    129.934326 | Lukas Panzarin                                                                                                                                                        |
| 334 |      14.35949 |    779.126742 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 335 |     261.36160 |    635.763195 | Jagged Fang Designs                                                                                                                                                   |
| 336 |     366.47386 |    140.267937 | Matt Crook                                                                                                                                                            |
| 337 |     153.87493 |    328.886660 | Sarah Werning                                                                                                                                                         |
| 338 |      69.04796 |    213.551851 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 339 |     435.22346 |    789.738850 | NA                                                                                                                                                                    |
| 340 |     863.38135 |     20.505077 | Gareth Monger                                                                                                                                                         |
| 341 |     315.25184 |    234.137643 | Iain Reid                                                                                                                                                             |
| 342 |     289.14341 |    456.257362 | Siobhon Egan                                                                                                                                                          |
| 343 |     389.22889 |    397.677894 | Margot Michaud                                                                                                                                                        |
| 344 |     790.47391 |    586.371379 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 345 |     431.49680 |    367.553973 | Gareth Monger                                                                                                                                                         |
| 346 |     897.81967 |      8.748436 | Chris huh                                                                                                                                                             |
| 347 |     902.63236 |    310.952378 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 348 |     675.06307 |     79.041650 | Ignacio Contreras                                                                                                                                                     |
| 349 |     408.38089 |    650.780742 | Christoph Schomburg                                                                                                                                                   |
| 350 |     328.87544 |    260.641623 | Markus A. Grohme                                                                                                                                                      |
| 351 |     189.34533 |    419.720810 | Mykle Hoban                                                                                                                                                           |
| 352 |    1016.36819 |    452.343216 | NA                                                                                                                                                                    |
| 353 |      86.12421 |    642.904978 | Scott Hartman                                                                                                                                                         |
| 354 |     349.53504 |    313.752369 | Mike Hanson                                                                                                                                                           |
| 355 |      15.30030 |    285.126433 | Sarah Werning                                                                                                                                                         |
| 356 |      28.66014 |    266.267099 | Chloé Schmidt                                                                                                                                                         |
| 357 |     838.19726 |    543.828686 | NA                                                                                                                                                                    |
| 358 |     335.51749 |    534.167488 | Hugo Gruson                                                                                                                                                           |
| 359 |     565.48812 |    638.978011 | Tracy A. Heath                                                                                                                                                        |
| 360 |     183.70174 |    508.509089 | Gareth Monger                                                                                                                                                         |
| 361 |     602.21378 |     60.405734 | Jaime Headden                                                                                                                                                         |
| 362 |     239.12744 |    353.155498 | Markus A. Grohme                                                                                                                                                      |
| 363 |     570.27998 |    466.144344 | Andy Wilson                                                                                                                                                           |
| 364 |     999.73884 |    563.469390 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 365 |     218.47785 |     70.960944 | C. Camilo Julián-Caballero                                                                                                                                            |
| 366 |     530.48957 |    769.640277 | Steven Traver                                                                                                                                                         |
| 367 |     364.06466 |     93.619526 | Matt Crook                                                                                                                                                            |
| 368 |     420.61290 |    466.823158 | Margot Michaud                                                                                                                                                        |
| 369 |     572.62101 |    541.361439 | Dean Schnabel                                                                                                                                                         |
| 370 |    1009.10141 |    294.719203 | T. Michael Keesey                                                                                                                                                     |
| 371 |     952.40588 |    246.432944 | Inessa Voet                                                                                                                                                           |
| 372 |     813.40431 |    341.727342 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 373 |     725.08716 |     12.841650 | Henry Lydecker                                                                                                                                                        |
| 374 |      48.43067 |    164.513887 | Zimices                                                                                                                                                               |
| 375 |     717.39546 |    418.948259 | Chris huh                                                                                                                                                             |
| 376 |     964.00921 |    624.488702 | T. Michael Keesey                                                                                                                                                     |
| 377 |     827.54579 |    671.530893 | NA                                                                                                                                                                    |
| 378 |     599.71652 |    497.976999 | Tasman Dixon                                                                                                                                                          |
| 379 |     579.86342 |    178.933717 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 380 |     230.95336 |    505.085064 | Walter Vladimir                                                                                                                                                       |
| 381 |    1006.24968 |     29.320185 | Matt Crook                                                                                                                                                            |
| 382 |     523.66732 |    620.451864 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 383 |     151.46151 |    506.938979 | Christine Axon                                                                                                                                                        |
| 384 |     921.14109 |    589.554081 | Scott Hartman                                                                                                                                                         |
| 385 |     804.34373 |    209.378997 | T. Michael Keesey                                                                                                                                                     |
| 386 |     786.34059 |    492.845075 | Dean Schnabel                                                                                                                                                         |
| 387 |     229.72693 |    629.226661 | Scott Hartman                                                                                                                                                         |
| 388 |     807.60847 |    738.504682 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
| 389 |     861.78404 |    434.668839 | Erika Schumacher                                                                                                                                                      |
| 390 |     545.26696 |    450.980632 | Zimices                                                                                                                                                               |
| 391 |     727.47962 |    792.077568 | Maija Karala                                                                                                                                                          |
| 392 |     423.56878 |    300.410992 | NA                                                                                                                                                                    |
| 393 |     331.76924 |    417.467121 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 394 |     932.84355 |    407.439297 | T. Michael Keesey                                                                                                                                                     |
| 395 |     485.71609 |    382.720931 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 396 |      49.60292 |    621.257542 | Alex Slavenko                                                                                                                                                         |
| 397 |     858.01605 |    667.261799 | Cathy                                                                                                                                                                 |
| 398 |     999.30038 |    693.760625 | T. Tischler                                                                                                                                                           |
| 399 |     208.60491 |    589.936954 | Estelle Bourdon                                                                                                                                                       |
| 400 |      97.15386 |    704.141260 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 401 |     919.81432 |     22.586468 | Chris huh                                                                                                                                                             |
| 402 |     296.54196 |    436.371228 | Roberto Díaz Sibaja                                                                                                                                                   |
| 403 |     340.96699 |    270.596234 | Birgit Lang                                                                                                                                                           |
| 404 |     359.10315 |    321.251282 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 405 |     696.14860 |     84.935579 | Smokeybjb                                                                                                                                                             |
| 406 |     777.15052 |    629.230046 | Matt Crook                                                                                                                                                            |
| 407 |     186.46748 |     31.348592 | NA                                                                                                                                                                    |
| 408 |     645.74334 |    789.506823 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 409 |    1004.51175 |    526.252043 | Steven Coombs                                                                                                                                                         |
| 410 |     109.37069 |     96.991321 | Campbell Fleming                                                                                                                                                      |
| 411 |     998.60746 |    496.693852 | Caleb M. Brown                                                                                                                                                        |
| 412 |     966.07575 |    486.270785 | Matt Crook                                                                                                                                                            |
| 413 |     964.52571 |     34.911756 | Zimices                                                                                                                                                               |
| 414 |     196.58956 |    565.928683 | Matt Dempsey                                                                                                                                                          |
| 415 |     394.07733 |    632.340287 | Julien Louys                                                                                                                                                          |
| 416 |     195.37358 |    116.993719 | Zimices                                                                                                                                                               |
| 417 |     640.13129 |    427.393162 | Erika Schumacher                                                                                                                                                      |
| 418 |     812.98127 |    173.883601 | Ferran Sayol                                                                                                                                                          |
| 419 |     464.14312 |    377.524212 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 420 |      17.08111 |    369.784199 | Sarah Werning                                                                                                                                                         |
| 421 |     740.71540 |      8.091710 | Markus A. Grohme                                                                                                                                                      |
| 422 |      25.55164 |    545.725275 | Margot Michaud                                                                                                                                                        |
| 423 |     617.73651 |    213.154849 | Gareth Monger                                                                                                                                                         |
| 424 |     906.08371 |    211.039145 | Birgit Lang                                                                                                                                                           |
| 425 |     891.92279 |    689.126938 | Markus A. Grohme                                                                                                                                                      |
| 426 |    1006.22647 |    203.918986 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 427 |     577.46804 |    336.970501 | Thibaut Brunet                                                                                                                                                        |
| 428 |     614.25401 |    638.990611 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 429 |     803.11873 |    146.266936 | Duane Raver/USFWS                                                                                                                                                     |
| 430 |     455.19114 |    506.235671 | Jakovche                                                                                                                                                              |
| 431 |     723.72259 |    324.309212 | Margot Michaud                                                                                                                                                        |
| 432 |      78.44389 |    482.242569 | Chris huh                                                                                                                                                             |
| 433 |     522.94014 |    646.702155 | Jagged Fang Designs                                                                                                                                                   |
| 434 |     592.57047 |    754.177167 | Maija Karala                                                                                                                                                          |
| 435 |     295.82442 |    142.715434 | David Orr                                                                                                                                                             |
| 436 |     309.23762 |      6.965351 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 437 |      79.98288 |    308.711745 | Margot Michaud                                                                                                                                                        |
| 438 |     130.54018 |    251.441554 | Zimices                                                                                                                                                               |
| 439 |      88.75788 |    509.666206 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 440 |    1015.77517 |    322.149165 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 441 |     123.92382 |     14.624656 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 442 |     261.86491 |    725.796181 | T. Michael Keesey                                                                                                                                                     |
| 443 |     888.88114 |    606.041795 | Sarah Werning                                                                                                                                                         |
| 444 |     789.10903 |    261.601397 | Tasman Dixon                                                                                                                                                          |
| 445 |     790.19530 |    118.061714 | Scott Hartman                                                                                                                                                         |
| 446 |     335.94557 |    105.407820 | T. Michael Keesey                                                                                                                                                     |
| 447 |     432.78035 |    155.774874 | Zimices                                                                                                                                                               |
| 448 |     217.37080 |    436.259918 | Rebecca Groom                                                                                                                                                         |
| 449 |     839.04503 |    345.115780 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 450 |     384.99134 |    492.766045 | Gareth Monger                                                                                                                                                         |
| 451 |      96.70653 |    441.480026 | Ignacio Contreras                                                                                                                                                     |
| 452 |     611.31020 |    474.703735 | Erika Schumacher                                                                                                                                                      |
| 453 |     146.47956 |    750.360817 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 454 |     180.78394 |    290.930614 | Gareth Monger                                                                                                                                                         |
| 455 |      86.91436 |    792.711533 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 456 |     751.74086 |    473.896200 | Gareth Monger                                                                                                                                                         |
| 457 |     192.59289 |    259.811479 | Matt Crook                                                                                                                                                            |
| 458 |     681.03449 |    320.686999 | Andy Wilson                                                                                                                                                           |
| 459 |     654.30950 |    205.113998 | Joanna Wolfe                                                                                                                                                          |
| 460 |     173.68107 |    134.171754 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 461 |      28.41032 |    516.910925 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 462 |     296.64780 |    361.778680 | C. Camilo Julián-Caballero                                                                                                                                            |
| 463 |     163.64674 |    433.091158 | Cesar Julian                                                                                                                                                          |
| 464 |     971.16565 |     14.208758 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 465 |     697.00674 |    714.963516 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 466 |     306.07217 |     68.032539 | Chris huh                                                                                                                                                             |
| 467 |     560.80750 |    188.133481 | Tony Ayling                                                                                                                                                           |
| 468 |      29.58494 |    483.562780 | Steven Traver                                                                                                                                                         |
| 469 |     830.70641 |    746.193733 | Matt Crook                                                                                                                                                            |
| 470 |     805.91296 |    567.557413 | Tasman Dixon                                                                                                                                                          |
| 471 |     209.68570 |    339.974669 | Zimices                                                                                                                                                               |
| 472 |     278.98025 |     99.963988 | Gareth Monger                                                                                                                                                         |
| 473 |     643.89992 |    609.031585 | NA                                                                                                                                                                    |
| 474 |     926.28891 |    122.570157 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 475 |     110.49215 |    334.183377 | Tracy A. Heath                                                                                                                                                        |
| 476 |    1013.39716 |    600.816784 | Beth Reinke                                                                                                                                                           |
| 477 |     552.93172 |    509.465266 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 478 |     394.03842 |    783.684052 | Margot Michaud                                                                                                                                                        |
| 479 |     406.39587 |    244.198033 | Gareth Monger                                                                                                                                                         |
| 480 |      18.51894 |     81.321530 | Rebecca Groom                                                                                                                                                         |
| 481 |    1006.59213 |    345.362987 | Rebecca Groom                                                                                                                                                         |
| 482 |     890.43804 |    545.368134 | Nina Skinner                                                                                                                                                          |
| 483 |     405.62370 |     21.651904 | Scott Hartman                                                                                                                                                         |
| 484 |     708.83535 |    768.104598 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 485 |     411.53850 |    153.827167 | Jack Mayer Wood                                                                                                                                                       |
| 486 |     342.95847 |    685.108402 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 487 |     297.94669 |     43.491460 | Jagged Fang Designs                                                                                                                                                   |
| 488 |     230.44394 |    160.601288 | Steven Coombs                                                                                                                                                         |
| 489 |     285.89322 |    488.462468 | Andy Wilson                                                                                                                                                           |
| 490 |     728.28644 |    198.298231 | Hans Hillewaert                                                                                                                                                       |
| 491 |     232.19849 |     11.460221 | Frank Denota                                                                                                                                                          |
| 492 |     644.95864 |    307.546879 | Christoph Schomburg                                                                                                                                                   |
| 493 |     983.70041 |     48.479836 | Scott Hartman                                                                                                                                                         |
| 494 |     153.81993 |    346.350201 | Zimices                                                                                                                                                               |
| 495 |     175.63411 |      6.729984 | Sarah Alewijnse                                                                                                                                                       |
| 496 |     770.35220 |    139.604826 | Chloé Schmidt                                                                                                                                                         |
| 497 |     828.36729 |    324.042828 | Markus A. Grohme                                                                                                                                                      |
| 498 |     299.97954 |    255.494337 | T. Tischler                                                                                                                                                           |
| 499 |      17.61267 |    461.317432 | Zimices                                                                                                                                                               |
| 500 |     211.72374 |     82.087527 | NA                                                                                                                                                                    |
| 501 |     979.47047 |    130.225150 | Scott Hartman                                                                                                                                                         |
| 502 |      47.68530 |      6.981671 | Daniel Stadtmauer                                                                                                                                                     |
| 503 |     965.64310 |    457.927772 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 504 |      18.86760 |    744.803968 | Lukasiniho                                                                                                                                                            |
| 505 |     568.12291 |    684.676888 | Chris huh                                                                                                                                                             |
| 506 |     505.67869 |    397.355701 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 507 |     797.92243 |      6.864601 | Jagged Fang Designs                                                                                                                                                   |
| 508 |     856.76532 |      8.022851 | Mathew Wedel                                                                                                                                                          |
| 509 |     814.63797 |    555.436350 | Margot Michaud                                                                                                                                                        |
| 510 |      32.24886 |    694.302239 | Chris huh                                                                                                                                                             |
| 511 |     694.86858 |     33.280499 | Jagged Fang Designs                                                                                                                                                   |
| 512 |     389.68492 |    320.578646 | Noah Schlottman                                                                                                                                                       |
| 513 |      28.25685 |    376.152172 | Christoph Schomburg                                                                                                                                                   |
| 514 |     732.67404 |    335.788697 | Steven Traver                                                                                                                                                         |
| 515 |      77.91624 |    624.733208 | Ferran Sayol                                                                                                                                                          |
| 516 |     567.85671 |    416.122359 | Christine Axon                                                                                                                                                        |
| 517 |     247.49373 |      3.780237 | Jagged Fang Designs                                                                                                                                                   |
| 518 |     358.82146 |     51.664564 | Jack Mayer Wood                                                                                                                                                       |
| 519 |      24.15074 |    643.100687 | Mattia Menchetti                                                                                                                                                      |
| 520 |     937.53032 |     84.749624 | Chris huh                                                                                                                                                             |
| 521 |    1005.58508 |    186.367401 | T. Michael Keesey                                                                                                                                                     |
| 522 |     768.35223 |    603.778560 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 523 |     571.54883 |    784.547563 | Margot Michaud                                                                                                                                                        |
| 524 |     452.38629 |     55.401722 | Matt Crook                                                                                                                                                            |
| 525 |      24.06048 |    598.833163 | Ingo Braasch                                                                                                                                                          |
| 526 |     852.06561 |    229.532493 | Gustav Mützel                                                                                                                                                         |
| 527 |     965.51218 |    340.879497 | Michelle Site                                                                                                                                                         |
| 528 |     257.54534 |    187.426415 | Gareth Monger                                                                                                                                                         |
| 529 |     453.12928 |    485.768840 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 530 |     302.46634 |    755.813273 | Scott Hartman                                                                                                                                                         |
| 531 |     987.70677 |    430.393063 | Emma Hughes                                                                                                                                                           |
| 532 |     416.13170 |    503.019265 | Carlos Cano-Barbacil                                                                                                                                                  |
| 533 |     133.01466 |    760.121283 | Margot Michaud                                                                                                                                                        |
| 534 |     353.90530 |    350.270135 | Margot Michaud                                                                                                                                                        |
| 535 |     466.19820 |    222.313436 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 536 |      10.67061 |    252.594135 | Birgit Lang                                                                                                                                                           |
| 537 |     289.37863 |    326.332861 | Jagged Fang Designs                                                                                                                                                   |
| 538 |     712.64438 |    675.163285 | Matt Crook                                                                                                                                                            |
| 539 |     675.05353 |    661.346796 | Joanna Wolfe                                                                                                                                                          |
| 540 |     634.35025 |    337.285128 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 541 |     639.05628 |    775.250400 | Erika Schumacher                                                                                                                                                      |
| 542 |     749.58957 |    419.800898 | Margot Michaud                                                                                                                                                        |
| 543 |     272.72832 |    697.594615 | Chris huh                                                                                                                                                             |
| 544 |    1004.23749 |    219.479408 | Markus A. Grohme                                                                                                                                                      |
| 545 |      47.84902 |    154.396883 | T. Tischler                                                                                                                                                           |
| 546 |     882.92348 |    638.702963 | Mathew Wedel                                                                                                                                                          |
| 547 |     405.67612 |    732.499320 | Matt Dempsey                                                                                                                                                          |
| 548 |     861.78348 |    244.577623 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 549 |     127.67601 |    382.610402 | Mathew Wedel                                                                                                                                                          |
| 550 |     224.65008 |    471.499366 | Zimices                                                                                                                                                               |
| 551 |     175.23194 |    690.580875 | Martin Kevil                                                                                                                                                          |
| 552 |     173.68517 |    668.792842 | Mathew Wedel                                                                                                                                                          |
| 553 |     648.10896 |    759.315203 | Scott Hartman                                                                                                                                                         |
| 554 |     690.03131 |    118.780865 | xgirouxb                                                                                                                                                              |
| 555 |     992.17461 |    767.247147 | L. Shyamal                                                                                                                                                            |
| 556 |     297.98991 |    375.098415 | Jagged Fang Designs                                                                                                                                                   |
| 557 |      16.51231 |    628.981522 | FunkMonk                                                                                                                                                              |
| 558 |     655.49959 |    454.536841 | Michelle Site                                                                                                                                                         |
| 559 |     523.39441 |    635.200355 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 560 |     496.39761 |    371.327654 | NA                                                                                                                                                                    |
| 561 |     520.22442 |    218.471505 | Andy Wilson                                                                                                                                                           |
| 562 |     286.92060 |    649.696716 | Gareth Monger                                                                                                                                                         |
| 563 |     805.28977 |    659.812602 | Martin R. Smith                                                                                                                                                       |
| 564 |     572.24635 |    195.084863 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 565 |     155.57835 |    497.248460 | Gareth Monger                                                                                                                                                         |
| 566 |     642.31575 |    241.296409 | Gareth Monger                                                                                                                                                         |
| 567 |     635.00970 |    704.429280 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 568 |     390.82172 |    432.364472 | Jagged Fang Designs                                                                                                                                                   |
| 569 |     730.79390 |    456.107076 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 570 |     476.62914 |    604.584274 | Mette Aumala                                                                                                                                                          |
| 571 |     422.31453 |    388.700621 | Milton Tan                                                                                                                                                            |
| 572 |     615.21641 |    713.717641 | T. Michael Keesey                                                                                                                                                     |
| 573 |     855.46507 |    216.217493 | Dann Pigdon                                                                                                                                                           |
| 574 |    1016.92893 |    388.132992 | Cagri Cevrim                                                                                                                                                          |
| 575 |     195.23020 |    478.722399 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 576 |     531.36138 |    726.912414 | M Kolmann                                                                                                                                                             |
| 577 |     724.34017 |    164.433206 | Markus A. Grohme                                                                                                                                                      |
| 578 |     163.92561 |    341.173980 | Erika Schumacher                                                                                                                                                      |
| 579 |     848.49048 |    630.293636 | Taenadoman                                                                                                                                                            |
| 580 |     889.52015 |    592.334344 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 581 |      16.56477 |    190.215847 | FunkMonk                                                                                                                                                              |

    #> Your tweet has been posted!
