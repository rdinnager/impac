
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

Markus A. Grohme, Tyler Greenfield, Zimices, Margot Michaud, T. Michael
Keesey, Francesca Belem Lopes Palmeira, Ingo Braasch, Chris huh, Matt
Crook, Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Andrew A. Farke, modified from original by H. Milne
Edwards, Ferran Sayol, Nobu Tamura and T. Michael Keesey,
Myriam\_Ramirez, Filip em, Matt Martyniuk, Steven Traver, Gareth Monger,
Tasman Dixon, Scott Hartman, Jose Carlos Arenas-Monroy, Mali’o Kodis,
photograph by Melissa Frey, Gabriela Palomo-Munoz, Mathilde Cordellier,
Emily Willoughby, Doug Backlund (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Christoph Schomburg, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Mason McNair, Jaime Headden, Chuanixn
Yu, Nobu Tamura (vectorized by T. Michael Keesey), Iain Reid, Dean
Schnabel, Juan Carlos Jerí, Dianne Bray / Museum Victoria (vectorized by
T. Michael Keesey), Beth Reinke, Caleb M. Brown, Lauren Anderson, Duane
Raver/USFWS, Mark Miller, Michelle Site, Obsidian Soul (vectorized by T.
Michael Keesey), Brad McFeeters (vectorized by T. Michael Keesey),
Smokeybjb, Florian Pfaff, Darren Naish (vectorized by T. Michael
Keesey), Jagged Fang Designs, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Nobu
Tamura (vectorized by A. Verrière), Sarah Werning, David Orr, Kenneth
Lacovara (vectorized by T. Michael Keesey), Rene Martin, Roberto Díaz
Sibaja, Andreas Hejnol, M Kolmann, Philippe Janvier (vectorized by T.
Michael Keesey), A. H. Baldwin (vectorized by T. Michael Keesey),
Francesco “Architetto” Rollandin, Robert Gay, modified from FunkMonk
(Michael B.H.) and T. Michael Keesey., \[unknown\], Roule Jammes
(vectorized by T. Michael Keesey), Dmitry Bogdanov, C. Camilo
Julián-Caballero, Matt Celeskey, Tony Ayling, Collin Gross, Michael P.
Taylor, JCGiron, Becky Barnes, Melissa Broussard, Tracy A. Heath,
Christine Axon, David Tana, Nina Skinner, Andy Wilson, Esme Ashe-Jepson,
Ville-Veikko Sinkkonen, FunkMonk, Michele M Tobias from an image By
Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Mattia
Menchetti, Erika Schumacher, André Karwath (vectorized by T. Michael
Keesey), Catherine Yasuda, Arthur S. Brum, Apokryltaros (vectorized by
T. Michael Keesey), Conty (vectorized by T. Michael Keesey), Joanna
Wolfe, Joseph Smit (modified by T. Michael Keesey), Kai R. Caspar,
Mathieu Pélissié, Robert Hering, Sam Droege (photo) and T. Michael
Keesey (vectorization), Michael Scroggie, T. Michael Keesey and
Tanetahi, Carlos Cano-Barbacil, Jack Mayer Wood, Emily Jane McTavish,
Cagri Cevrim, Cesar Julian, Verisimilus, Matt Dempsey, Jon M Laurent, T.
Michael Keesey (after Masteraah), Harold N Eyster, Christopher Laumer
(vectorized by T. Michael Keesey), T. Michael Keesey (from a photograph
by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Inessa
Voet, Rebecca Groom (Based on Photo by Andreas Trepte), Martin R. Smith,
Yan Wong, Armin Reindl, Owen Jones (derived from a CC-BY 2.0 photograph
by Paulo B. Chaves), Wayne Decatur, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Ville
Koistinen and T. Michael Keesey, Alexander Schmidt-Lebuhn, Konsta
Happonen, Matthias Buschmann (vectorized by T. Michael Keesey), Sarah
Alewijnse, Smith609 and T. Michael Keesey, Steven Coombs, Maija Karala,
T. Michael Keesey (after A. Y. Ivantsov), Katie S. Collins, Birgit Lang,
John Conway, Andrew A. Farke, Felix Vaux, Madeleine Price Ball, Maha
Ghazal, Lukasiniho, Rebecca Groom, Neil Kelley, Jonathan Wells, Ignacio
Contreras, Kamil S. Jaron, Mette Aumala, Martin Kevil, Matus Valach,
Stuart Humphries, Gustav Mützel, Bennet McComish, photo by Hans
Hillewaert, Pollyanna von Knorring and T. Michael Keesey, Chase
Brownstein, Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Nobu Tamura, modified by Andrew A.
Farke, Trond R. Oskars, FJDegrange, Chris A. Hamilton, Manabu Sakamoto,
Scarlet23 (vectorized by T. Michael Keesey), Noah Schlottman, photo from
National Science Foundation - Turbellarian Taxonomic Database, Evan
Swigart (photography) and T. Michael Keesey (vectorization), Ewald
Rübsamen, Noah Schlottman, photo by Hans De Blauwe, T. Michael Keesey
(after C. De Muizon), T. Michael Keesey (vectorization) and Nadiatalent
(photography), Hans Hillewaert (vectorized by T. Michael Keesey),
xgirouxb, Xavier Giroux-Bougard, Matt Wilkins, Alex Slavenko, Mathieu
Basille, Noah Schlottman, photo by Carol Cummings, Michele M Tobias,
Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong), Tyler
McCraney, Nobu Tamura, vectorized by Zimices, Lily Hughes, Ellen
Edmonson (illustration) and Timothy J. Bartley (silhouette), Jaime
Chirinos (vectorized by T. Michael Keesey), Pedro de Siracusa, Crystal
Maier, Nobu Tamura, James R. Spotila and Ray Chatterji, Natasha Vitek,
Jiekun He, Roger Witter, vectorized by Zimices, Вальдимар (vectorized by
T. Michael Keesey), Alexandre Vong, Birgit Lang; original image by
virmisco.org, Mark Witton, Chloé Schmidt, Joris van der Ham (vectorized
by T. Michael Keesey), Anthony Caravaggi, MPF (vectorized by T. Michael
Keesey), Jakovche, Leann Biancani, photo by Kenneth Clifton, Nobu Tamura
(modified by T. Michael Keesey), Noah Schlottman, photo from Casey Dunn,
Eduard Solà (vectorized by T. Michael Keesey), Noah Schlottman, photo by
Casey Dunn, Alexandra van der Geer, Pete Buchholz, Marie-Aimée Allard,
Cathy, Sharon Wegner-Larsen, Caleb Brown, Mali’o Kodis, photograph from
Jersabek et al, 2003, Matt Martyniuk (modified by T. Michael Keesey),
(after McCulloch 1908), Andrew R. Gehrke, Shyamal, Ghedoghedo
(vectorized by T. Michael Keesey), Didier Descouens (vectorized by T.
Michael Keesey), DW Bapst (Modified from Bulman, 1964), Sibi (vectorized
by T. Michael Keesey), Jake Warner, Cristopher Silva, S.Martini,
Jennifer Trimble, Mr E? (vectorized by T. Michael Keesey), Rainer
Schoch, Maxwell Lefroy (vectorized by T. Michael Keesey), Fernando
Campos De Domenico, L. Shyamal, Julio Garza, Smokeybjb, vectorized by
Zimices, Verdilak, Noah Schlottman, photo by Martin V. Sørensen, Ray
Simpson (vectorized by T. Michael Keesey), Chris Jennings (Risiatto),
Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist, Lip
Kee Yap (vectorized by T. Michael Keesey), Scott Hartman (vectorized by
T. Michael Keesey), DFoidl (vectorized by T. Michael Keesey), Noah
Schlottman, photo by Antonio Guillén, Bryan Carstens, Rachel Shoop,
Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja,
Meliponicultor Itaymbere, Scott Hartman (modified by T. Michael Keesey),
Kosta Mumcuoglu (vectorized by T. Michael Keesey), Lani Mohan, Margret
Flinsch, vectorized by Zimices, nicubunu, Darius Nau, Frederick William
Frohawk (vectorized by T. Michael Keesey), Armelle Ansart (photograph),
Maxime Dahirel (digitisation), B. Duygu Özpolat, Zimices / Julián
Bayona, Arthur Weasley (vectorized by T. Michael Keesey), Charles R.
Knight, vectorized by Zimices, Zachary Quigley, Tony Ayling (vectorized
by T. Michael Keesey), Duane Raver (vectorized by T. Michael Keesey),
George Edward Lodge, T. Michael Keesey (vectorization); Yves Bousquet
(photography), Jaime Headden, modified by T. Michael Keesey, Patrick
Strutzenberger, Emma Kissling, Kailah Thorn & Ben King, Lukas Panzarin
(vectorized by T. Michael Keesey), NASA, Martin R. Smith, after Skovsted
et al 2015

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    651.323062 |    581.761485 | Markus A. Grohme                                                                                                                                                      |
|   2 |    330.435813 |    644.342310 | Tyler Greenfield                                                                                                                                                      |
|   3 |    184.570192 |    450.153165 | Zimices                                                                                                                                                               |
|   4 |     54.568561 |    184.288166 | Margot Michaud                                                                                                                                                        |
|   5 |    355.099909 |    746.808153 | T. Michael Keesey                                                                                                                                                     |
|   6 |    338.657264 |    167.853015 | Francesca Belem Lopes Palmeira                                                                                                                                        |
|   7 |    668.514021 |    186.165063 | Markus A. Grohme                                                                                                                                                      |
|   8 |    139.969275 |    213.771441 | Ingo Braasch                                                                                                                                                          |
|   9 |    945.329618 |    319.263734 | NA                                                                                                                                                                    |
|  10 |    220.875181 |    491.154918 | Chris huh                                                                                                                                                             |
|  11 |    827.436270 |     90.535338 | NA                                                                                                                                                                    |
|  12 |    416.321604 |    358.944719 | Matt Crook                                                                                                                                                            |
|  13 |    105.457150 |    748.964412 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
|  14 |    531.692678 |    180.825425 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
|  15 |    274.208138 |    322.754063 | Ferran Sayol                                                                                                                                                          |
|  16 |    475.002526 |    509.664351 | Margot Michaud                                                                                                                                                        |
|  17 |     84.945218 |    664.084360 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
|  18 |     99.010722 |    548.621650 | Myriam\_Ramirez                                                                                                                                                       |
|  19 |    347.965287 |     72.224158 | Margot Michaud                                                                                                                                                        |
|  20 |    653.469645 |     59.373464 | Chris huh                                                                                                                                                             |
|  21 |    479.766531 |    412.568506 | Filip em                                                                                                                                                              |
|  22 |    634.859247 |    105.256122 | Zimices                                                                                                                                                               |
|  23 |    621.224666 |    747.568518 | Matt Martyniuk                                                                                                                                                        |
|  24 |    408.596817 |    254.587251 | Matt Crook                                                                                                                                                            |
|  25 |    878.655222 |    450.519179 | Steven Traver                                                                                                                                                         |
|  26 |    149.556124 |    321.052018 | Gareth Monger                                                                                                                                                         |
|  27 |    908.415530 |    691.804429 | Tasman Dixon                                                                                                                                                          |
|  28 |    609.743786 |    665.055536 | Scott Hartman                                                                                                                                                         |
|  29 |    684.945064 |    338.356007 | NA                                                                                                                                                                    |
|  30 |    915.146441 |    172.870664 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  31 |    393.414188 |    561.115857 | T. Michael Keesey                                                                                                                                                     |
|  32 |    254.445548 |    598.211119 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                              |
|  33 |    908.466727 |    556.423181 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  34 |    957.219787 |    406.077234 | Gareth Monger                                                                                                                                                         |
|  35 |    478.297999 |    720.700491 | Gareth Monger                                                                                                                                                         |
|  36 |    549.639911 |    296.327707 | Mathilde Cordellier                                                                                                                                                   |
|  37 |    822.681563 |    693.466424 | Emily Willoughby                                                                                                                                                      |
|  38 |    242.258784 |    229.031085 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
|  39 |    801.744356 |    225.410609 | Christoph Schomburg                                                                                                                                                   |
|  40 |    438.640801 |    439.256987 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  41 |    242.053262 |    715.573628 | Ferran Sayol                                                                                                                                                          |
|  42 |    196.796804 |    582.541348 | Mason McNair                                                                                                                                                          |
|  43 |    456.475364 |     61.314582 | NA                                                                                                                                                                    |
|  44 |    216.411127 |     61.585804 | Jaime Headden                                                                                                                                                         |
|  45 |    767.319663 |    133.324264 | Ferran Sayol                                                                                                                                                          |
|  46 |    953.107335 |    257.402923 | Chuanixn Yu                                                                                                                                                           |
|  47 |    644.595559 |    497.136999 | NA                                                                                                                                                                    |
|  48 |    565.374695 |     42.913827 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  49 |    322.330352 |    452.792135 | Iain Reid                                                                                                                                                             |
|  50 |    822.796157 |    302.999747 | Matt Crook                                                                                                                                                            |
|  51 |    182.261761 |    401.092727 | Dean Schnabel                                                                                                                                                         |
|  52 |     78.540603 |    435.195567 | Juan Carlos Jerí                                                                                                                                                      |
|  53 |    674.344684 |    165.068056 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
|  54 |    941.883027 |     60.797399 | Beth Reinke                                                                                                                                                           |
|  55 |    376.744984 |    506.031550 | Matt Crook                                                                                                                                                            |
|  56 |    323.523499 |    226.263517 | Scott Hartman                                                                                                                                                         |
|  57 |    795.178013 |    707.679537 | Scott Hartman                                                                                                                                                         |
|  58 |    807.669438 |    660.330429 | Caleb M. Brown                                                                                                                                                        |
|  59 |    791.041770 |    399.265308 | Lauren Anderson                                                                                                                                                       |
|  60 |    684.064705 |    453.368666 | Duane Raver/USFWS                                                                                                                                                     |
|  61 |    405.221860 |    635.131582 | Mark Miller                                                                                                                                                           |
|  62 |    502.525151 |    376.782688 | Tyler Greenfield                                                                                                                                                      |
|  63 |     41.646470 |     97.886935 | Michelle Site                                                                                                                                                         |
|  64 |    573.837840 |    452.891964 | Lauren Anderson                                                                                                                                                       |
|  65 |    921.383304 |    640.320431 | Markus A. Grohme                                                                                                                                                      |
|  66 |    212.829926 |    785.954025 | NA                                                                                                                                                                    |
|  67 |    571.714715 |    727.144091 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  68 |    953.414348 |    755.170981 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  69 |    129.133579 |    133.833800 | Smokeybjb                                                                                                                                                             |
|  70 |    767.072608 |    514.987556 | Caleb M. Brown                                                                                                                                                        |
|  71 |    347.840013 |    367.327303 | Florian Pfaff                                                                                                                                                         |
|  72 |    325.954928 |    123.869812 | Gareth Monger                                                                                                                                                         |
|  73 |    168.217756 |    494.636317 | Scott Hartman                                                                                                                                                         |
|  74 |    148.977428 |    717.163478 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
|  75 |    739.383534 |     28.729433 | Jagged Fang Designs                                                                                                                                                   |
|  76 |    978.206623 |    479.576758 | Jagged Fang Designs                                                                                                                                                   |
|  77 |    994.963884 |    194.686288 | Zimices                                                                                                                                                               |
|  78 |    811.324022 |    502.998776 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  79 |     46.060091 |    338.143705 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
|  80 |    966.196700 |    611.693386 | Sarah Werning                                                                                                                                                         |
|  81 |    579.941513 |    637.165067 | Gareth Monger                                                                                                                                                         |
|  82 |    219.090318 |    558.804770 | David Orr                                                                                                                                                             |
|  83 |     42.582954 |    565.035701 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
|  84 |     39.299688 |    477.325269 | Rene Martin                                                                                                                                                           |
|  85 |    505.732715 |    288.705451 | Margot Michaud                                                                                                                                                        |
|  86 |    841.884571 |     24.005568 | Roberto Díaz Sibaja                                                                                                                                                   |
|  87 |    514.670755 |    106.964299 | Dean Schnabel                                                                                                                                                         |
|  88 |     32.728421 |    310.626609 | Zimices                                                                                                                                                               |
|  89 |    909.805182 |    266.868002 | Andreas Hejnol                                                                                                                                                        |
|  90 |    140.465632 |    244.056779 | Ferran Sayol                                                                                                                                                          |
|  91 |    439.890827 |    150.093837 | M Kolmann                                                                                                                                                             |
|  92 |     33.474734 |    405.532856 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
|  93 |    830.462154 |    749.546195 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
|  94 |    890.926181 |    727.906514 | Steven Traver                                                                                                                                                         |
|  95 |    106.085821 |     94.526429 | NA                                                                                                                                                                    |
|  96 |    297.226881 |    420.239115 | Francesco “Architetto” Rollandin                                                                                                                                      |
|  97 |    297.628958 |    720.516484 | NA                                                                                                                                                                    |
|  98 |    352.897633 |     98.114727 | Margot Michaud                                                                                                                                                        |
|  99 |    943.462303 |    340.555129 | Markus A. Grohme                                                                                                                                                      |
| 100 |    695.225053 |    200.095114 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 101 |    279.536971 |    385.296371 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 102 |     35.849187 |    496.885527 | \[unknown\]                                                                                                                                                           |
| 103 |    516.851741 |     27.278495 | Chris huh                                                                                                                                                             |
| 104 |     61.366391 |    359.251713 | Matt Crook                                                                                                                                                            |
| 105 |    562.993910 |     89.378842 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
| 106 |     25.119478 |    366.346983 | Dmitry Bogdanov                                                                                                                                                       |
| 107 |    669.026959 |    207.183271 | Zimices                                                                                                                                                               |
| 108 |    759.543557 |    791.659235 | C. Camilo Julián-Caballero                                                                                                                                            |
| 109 |    115.964776 |    329.168673 | Matt Celeskey                                                                                                                                                         |
| 110 |    502.679863 |    448.013905 | Tony Ayling                                                                                                                                                           |
| 111 |    547.751214 |    704.091146 | Collin Gross                                                                                                                                                          |
| 112 |    891.990521 |    621.205309 | Michael P. Taylor                                                                                                                                                     |
| 113 |    388.733583 |    211.892345 | Steven Traver                                                                                                                                                         |
| 114 |    836.263927 |    706.083653 | JCGiron                                                                                                                                                               |
| 115 |    936.599921 |    474.044440 | Becky Barnes                                                                                                                                                          |
| 116 |    171.506926 |    153.879209 | Roberto Díaz Sibaja                                                                                                                                                   |
| 117 |    368.502280 |    596.882855 | Melissa Broussard                                                                                                                                                     |
| 118 |    191.565460 |    698.089570 | NA                                                                                                                                                                    |
| 119 |    910.396448 |    379.293934 | Chris huh                                                                                                                                                             |
| 120 |    115.635623 |    195.601045 | Tracy A. Heath                                                                                                                                                        |
| 121 |    190.395817 |    677.962668 | Gareth Monger                                                                                                                                                         |
| 122 |    177.350354 |    183.288270 | Tasman Dixon                                                                                                                                                          |
| 123 |    210.502463 |    426.561098 | Christine Axon                                                                                                                                                        |
| 124 |    967.282987 |    549.994859 | David Tana                                                                                                                                                            |
| 125 |    423.168705 |    769.578743 | Nina Skinner                                                                                                                                                          |
| 126 |    336.359116 |    774.087029 | Andy Wilson                                                                                                                                                           |
| 127 |     64.378627 |    273.621611 | Esme Ashe-Jepson                                                                                                                                                      |
| 128 |    555.722556 |    629.098225 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 129 |    640.760292 |     16.832712 | Jagged Fang Designs                                                                                                                                                   |
| 130 |    585.049285 |    785.718462 | FunkMonk                                                                                                                                                              |
| 131 |    605.544934 |     60.283276 | NA                                                                                                                                                                    |
| 132 |    996.341558 |    511.763201 | Gareth Monger                                                                                                                                                         |
| 133 |     38.983008 |    679.114476 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 134 |     78.325692 |    715.734758 | Scott Hartman                                                                                                                                                         |
| 135 |     51.915662 |     28.256633 | Mattia Menchetti                                                                                                                                                      |
| 136 |    288.766998 |    251.722543 | Erika Schumacher                                                                                                                                                      |
| 137 |    987.196714 |    347.112551 | Margot Michaud                                                                                                                                                        |
| 138 |    270.811199 |    476.644514 | Zimices                                                                                                                                                               |
| 139 |    961.475095 |      9.898430 | NA                                                                                                                                                                    |
| 140 |    521.669113 |    684.002001 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                       |
| 141 |    485.591797 |    790.864382 | NA                                                                                                                                                                    |
| 142 |   1011.997097 |    307.440395 | Zimices                                                                                                                                                               |
| 143 |     72.973701 |    783.342670 | Catherine Yasuda                                                                                                                                                      |
| 144 |    673.026877 |    470.674340 | Arthur S. Brum                                                                                                                                                        |
| 145 |     20.461697 |    158.117054 | Tasman Dixon                                                                                                                                                          |
| 146 |    843.508773 |    381.294236 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 147 |    484.247906 |    664.972723 | Ferran Sayol                                                                                                                                                          |
| 148 |    886.350737 |     74.946400 | Margot Michaud                                                                                                                                                        |
| 149 |    958.781534 |    734.320442 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 150 |    353.834295 |     16.814276 | NA                                                                                                                                                                    |
| 151 |     17.503268 |    440.783635 | Joanna Wolfe                                                                                                                                                          |
| 152 |    296.919534 |    410.588848 | Tyler Greenfield                                                                                                                                                      |
| 153 |    617.334354 |    626.215747 | Gareth Monger                                                                                                                                                         |
| 154 |    605.874266 |    691.071282 | Tasman Dixon                                                                                                                                                          |
| 155 |     82.554722 |    104.998343 | Steven Traver                                                                                                                                                         |
| 156 |    658.655811 |    669.663680 | Ingo Braasch                                                                                                                                                          |
| 157 |    174.977315 |    686.497989 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                           |
| 158 |    586.381968 |    316.170451 | Kai R. Caspar                                                                                                                                                         |
| 159 |    841.011191 |    363.314444 | Mathieu Pélissié                                                                                                                                                      |
| 160 |    197.545048 |    320.354141 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 161 |     11.922111 |    397.435654 | Robert Hering                                                                                                                                                         |
| 162 |     46.407394 |     12.220219 | NA                                                                                                                                                                    |
| 163 |    310.099846 |    557.581101 | Gareth Monger                                                                                                                                                         |
| 164 |    784.272034 |    279.945671 | T. Michael Keesey                                                                                                                                                     |
| 165 |    679.626229 |    146.442830 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                              |
| 166 |    554.694772 |    134.803983 | Matt Crook                                                                                                                                                            |
| 167 |    373.646179 |    295.353669 | Michael Scroggie                                                                                                                                                      |
| 168 |    358.927685 |    242.255582 | David Tana                                                                                                                                                            |
| 169 |    998.481537 |    494.749748 | Jagged Fang Designs                                                                                                                                                   |
| 170 |    994.513020 |    762.670276 | Christoph Schomburg                                                                                                                                                   |
| 171 |    749.703572 |    298.176067 | T. Michael Keesey and Tanetahi                                                                                                                                        |
| 172 |    359.500754 |     20.169013 | Margot Michaud                                                                                                                                                        |
| 173 |    204.021341 |    308.530346 | Carlos Cano-Barbacil                                                                                                                                                  |
| 174 |    461.370290 |    792.701420 | Jack Mayer Wood                                                                                                                                                       |
| 175 |    999.704256 |    572.573962 | Matt Crook                                                                                                                                                            |
| 176 |    989.262817 |    586.031490 | Gareth Monger                                                                                                                                                         |
| 177 |    264.365741 |    465.278738 | Emily Jane McTavish                                                                                                                                                   |
| 178 |    580.890903 |    376.689157 | Cagri Cevrim                                                                                                                                                          |
| 179 |    140.046204 |    594.887360 | Margot Michaud                                                                                                                                                        |
| 180 |    202.389217 |    359.148235 | Sarah Werning                                                                                                                                                         |
| 181 |    981.826032 |    747.868630 | Gareth Monger                                                                                                                                                         |
| 182 |    899.296716 |    792.584648 | Sarah Werning                                                                                                                                                         |
| 183 |    257.065132 |    137.046043 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 184 |    767.831237 |    302.082110 | Cesar Julian                                                                                                                                                          |
| 185 |    549.745748 |    511.100080 | Verisimilus                                                                                                                                                           |
| 186 |    505.298614 |     53.979907 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 187 |   1000.817421 |    775.579504 | Zimices                                                                                                                                                               |
| 188 |    807.881724 |    790.874902 | Matt Dempsey                                                                                                                                                          |
| 189 |    626.779542 |    780.776788 | Scott Hartman                                                                                                                                                         |
| 190 |   1002.828993 |     68.827693 | Margot Michaud                                                                                                                                                        |
| 191 |     40.770486 |    762.794768 | T. Michael Keesey                                                                                                                                                     |
| 192 |    418.486158 |    140.960211 | Ferran Sayol                                                                                                                                                          |
| 193 |    911.483386 |    659.234259 | Catherine Yasuda                                                                                                                                                      |
| 194 |    608.502172 |    256.812432 | Jon M Laurent                                                                                                                                                         |
| 195 |    730.314115 |    301.850686 | Zimices                                                                                                                                                               |
| 196 |    689.919766 |    153.669399 | Smokeybjb                                                                                                                                                             |
| 197 |     19.972034 |    628.129939 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 198 |     36.946291 |    330.762714 | Scott Hartman                                                                                                                                                         |
| 199 |    847.238116 |    589.010597 | Arthur S. Brum                                                                                                                                                        |
| 200 |     32.231617 |    246.097331 | Kai R. Caspar                                                                                                                                                         |
| 201 |    465.929586 |    183.209698 | Harold N Eyster                                                                                                                                                       |
| 202 |    281.330291 |     33.179392 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 203 |    132.085221 |     24.161772 | Jagged Fang Designs                                                                                                                                                   |
| 204 |    865.457243 |    693.576574 | Michael Scroggie                                                                                                                                                      |
| 205 |    781.598051 |      6.460916 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 206 |    597.887028 |    274.599190 | Zimices                                                                                                                                                               |
| 207 |    152.990221 |    747.599819 | Collin Gross                                                                                                                                                          |
| 208 |    124.616389 |    270.389393 | Inessa Voet                                                                                                                                                           |
| 209 |    834.394784 |    457.570332 | Tasman Dixon                                                                                                                                                          |
| 210 |    461.571467 |    390.095980 | Steven Traver                                                                                                                                                         |
| 211 |    285.827085 |    523.802068 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 212 |    759.963769 |    466.939701 | Ingo Braasch                                                                                                                                                          |
| 213 |    728.573770 |     49.590858 | Caleb M. Brown                                                                                                                                                        |
| 214 |    867.860958 |    751.086234 | Ferran Sayol                                                                                                                                                          |
| 215 |     30.725683 |    549.531043 | Scott Hartman                                                                                                                                                         |
| 216 |    877.473554 |    303.631299 | Becky Barnes                                                                                                                                                          |
| 217 |    515.272868 |    336.095902 | Martin R. Smith                                                                                                                                                       |
| 218 |    976.455108 |    693.285204 | Ferran Sayol                                                                                                                                                          |
| 219 |    999.740453 |    537.888278 | Tracy A. Heath                                                                                                                                                        |
| 220 |    275.356695 |    542.773848 | Roberto Díaz Sibaja                                                                                                                                                   |
| 221 |    387.492123 |    111.457726 | Yan Wong                                                                                                                                                              |
| 222 |    156.182949 |    261.646072 | Melissa Broussard                                                                                                                                                     |
| 223 |    730.359709 |    200.768030 | Matt Crook                                                                                                                                                            |
| 224 |    153.496703 |     21.758773 | Armin Reindl                                                                                                                                                          |
| 225 |    219.605987 |    146.316574 | T. Michael Keesey                                                                                                                                                     |
| 226 |     40.119769 |    707.278241 | T. Michael Keesey                                                                                                                                                     |
| 227 |    763.881915 |     78.907201 | Scott Hartman                                                                                                                                                         |
| 228 |    818.477365 |     20.523224 | Gareth Monger                                                                                                                                                         |
| 229 |     71.473350 |    617.025411 | Sarah Werning                                                                                                                                                         |
| 230 |    756.998195 |    475.718108 | NA                                                                                                                                                                    |
| 231 |    871.480733 |    366.107104 | Zimices                                                                                                                                                               |
| 232 |    894.653453 |    591.965795 | Matt Crook                                                                                                                                                            |
| 233 |    168.374787 |    742.214631 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 234 |    580.664259 |    247.579580 | Steven Traver                                                                                                                                                         |
| 235 |    341.393756 |    373.570016 | Sarah Werning                                                                                                                                                         |
| 236 |    440.578564 |    661.718454 | Wayne Decatur                                                                                                                                                         |
| 237 |    991.112862 |    370.409776 | Gareth Monger                                                                                                                                                         |
| 238 |    246.559278 |    234.290262 | Andy Wilson                                                                                                                                                           |
| 239 |    818.320136 |    480.306383 | Scott Hartman                                                                                                                                                         |
| 240 |    615.039638 |    445.644582 | Matt Crook                                                                                                                                                            |
| 241 |    849.360189 |    239.664050 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 242 |    710.040218 |    642.860468 | Matt Crook                                                                                                                                                            |
| 243 |     18.041515 |    348.179849 | C. Camilo Julián-Caballero                                                                                                                                            |
| 244 |    401.004468 |     16.460832 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 245 |    733.013517 |    795.214258 | Zimices                                                                                                                                                               |
| 246 |    486.390341 |    219.926412 | NA                                                                                                                                                                    |
| 247 |    330.831863 |    413.974934 | Matt Crook                                                                                                                                                            |
| 248 |    762.187829 |    283.828469 | Matt Crook                                                                                                                                                            |
| 249 |     98.685698 |    349.471499 | Harold N Eyster                                                                                                                                                       |
| 250 |    320.879893 |    789.974771 | Zimices                                                                                                                                                               |
| 251 |    623.608289 |    287.571691 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 252 |    139.582459 |    290.069665 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 253 |    879.217125 |    250.971195 | Scott Hartman                                                                                                                                                         |
| 254 |    123.528231 |      9.030376 | Jaime Headden                                                                                                                                                         |
| 255 |    552.469894 |    363.701646 | Steven Traver                                                                                                                                                         |
| 256 |    394.934111 |    708.970107 | Matt Crook                                                                                                                                                            |
| 257 |    103.896280 |    240.693713 | Konsta Happonen                                                                                                                                                       |
| 258 |    294.173799 |    514.503843 | NA                                                                                                                                                                    |
| 259 |    214.408497 |    325.505404 | Kai R. Caspar                                                                                                                                                         |
| 260 |    409.211129 |    135.186513 | Becky Barnes                                                                                                                                                          |
| 261 |    718.637856 |    695.466794 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
| 262 |    336.184899 |     31.163023 | Mathieu Pélissié                                                                                                                                                      |
| 263 |    825.996363 |     93.355211 | T. Michael Keesey                                                                                                                                                     |
| 264 |    966.609019 |     21.788775 | FunkMonk                                                                                                                                                              |
| 265 |    303.248003 |    539.237948 | Matt Crook                                                                                                                                                            |
| 266 |    237.297145 |    516.064642 | Sarah Alewijnse                                                                                                                                                       |
| 267 |   1012.127451 |    649.777837 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 268 |   1004.515301 |    157.561749 | Sarah Werning                                                                                                                                                         |
| 269 |    896.224814 |    104.583432 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 270 |    183.423910 |    231.723996 | Steven Coombs                                                                                                                                                         |
| 271 |    897.317740 |    120.817549 | JCGiron                                                                                                                                                               |
| 272 |    279.994360 |    678.450512 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 273 |    194.596292 |     15.470700 | Maija Karala                                                                                                                                                          |
| 274 |    720.488045 |    434.447484 | Markus A. Grohme                                                                                                                                                      |
| 275 |    698.955841 |    773.579242 | Steven Traver                                                                                                                                                         |
| 276 |    266.653274 |    180.714256 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 277 |    812.917524 |    770.934395 | Katie S. Collins                                                                                                                                                      |
| 278 |   1008.300700 |    232.727731 | Markus A. Grohme                                                                                                                                                      |
| 279 |    625.360887 |     50.771386 | Margot Michaud                                                                                                                                                        |
| 280 |    373.148897 |     33.195981 | Margot Michaud                                                                                                                                                        |
| 281 |    595.258777 |    292.542831 | Gareth Monger                                                                                                                                                         |
| 282 |     61.386324 |    730.675701 | Birgit Lang                                                                                                                                                           |
| 283 |     34.742006 |    293.834755 | Tracy A. Heath                                                                                                                                                        |
| 284 |     40.257019 |    539.195369 | Margot Michaud                                                                                                                                                        |
| 285 |    756.273251 |    437.655484 | T. Michael Keesey                                                                                                                                                     |
| 286 |    631.156392 |    770.722752 | Birgit Lang                                                                                                                                                           |
| 287 |    757.539988 |    771.750341 | John Conway                                                                                                                                                           |
| 288 |    134.600388 |    783.412103 | Katie S. Collins                                                                                                                                                      |
| 289 |    383.755581 |    642.750116 | Margot Michaud                                                                                                                                                        |
| 290 |    878.517411 |    216.440220 | Steven Traver                                                                                                                                                         |
| 291 |    418.137377 |    170.661721 | T. Michael Keesey                                                                                                                                                     |
| 292 |    129.196650 |    585.430831 | Scott Hartman                                                                                                                                                         |
| 293 |    785.734298 |    291.933497 | Andrew A. Farke                                                                                                                                                       |
| 294 |    222.033794 |    364.394386 | Felix Vaux                                                                                                                                                            |
| 295 |    864.302586 |    789.455256 | Steven Traver                                                                                                                                                         |
| 296 |    927.757513 |    130.904524 | Beth Reinke                                                                                                                                                           |
| 297 |   1001.686513 |    101.866850 | Madeleine Price Ball                                                                                                                                                  |
| 298 |    726.800511 |    531.850421 | Zimices                                                                                                                                                               |
| 299 |    543.596699 |    768.616551 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 300 |    258.989167 |    532.898250 | Zimices                                                                                                                                                               |
| 301 |    563.476743 |    673.730503 | NA                                                                                                                                                                    |
| 302 |    721.980476 |    773.659168 | Joanna Wolfe                                                                                                                                                          |
| 303 |    584.096374 |    144.169602 | Matt Crook                                                                                                                                                            |
| 304 |    781.337787 |    103.505735 | Maha Ghazal                                                                                                                                                           |
| 305 |    381.249436 |    585.047387 | Lukasiniho                                                                                                                                                            |
| 306 |    832.114500 |    767.135532 | Rebecca Groom                                                                                                                                                         |
| 307 |    641.892687 |    425.212839 | Steven Traver                                                                                                                                                         |
| 308 |    735.973623 |    232.363962 | Neil Kelley                                                                                                                                                           |
| 309 |     38.999350 |    439.979458 | Gareth Monger                                                                                                                                                         |
| 310 |    817.809942 |    445.338856 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 311 |    416.749410 |    211.517373 | Matt Crook                                                                                                                                                            |
| 312 |    789.065385 |    125.661287 | Gareth Monger                                                                                                                                                         |
| 313 |    371.885620 |    467.320732 | Zimices                                                                                                                                                               |
| 314 |    403.833730 |    311.134831 | Jon M Laurent                                                                                                                                                         |
| 315 |    611.887370 |    519.413256 | NA                                                                                                                                                                    |
| 316 |    699.127337 |    793.110198 | Jonathan Wells                                                                                                                                                        |
| 317 |    811.533446 |     79.953709 | Ignacio Contreras                                                                                                                                                     |
| 318 |    875.337605 |    695.987879 | Kamil S. Jaron                                                                                                                                                        |
| 319 |    662.842437 |    127.357219 | Mette Aumala                                                                                                                                                          |
| 320 |    487.292443 |    657.895166 | Ignacio Contreras                                                                                                                                                     |
| 321 |   1002.680704 |    325.844417 | Martin Kevil                                                                                                                                                          |
| 322 |    814.922001 |    155.585746 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 323 |    991.815641 |    652.005844 | Margot Michaud                                                                                                                                                        |
| 324 |    981.917623 |    102.572859 | Matus Valach                                                                                                                                                          |
| 325 |    761.823226 |    110.737247 | Tasman Dixon                                                                                                                                                          |
| 326 |    503.131540 |    794.032972 | Chuanixn Yu                                                                                                                                                           |
| 327 |    926.131227 |    569.708245 | Stuart Humphries                                                                                                                                                      |
| 328 |    736.974443 |    494.689571 | Matt Crook                                                                                                                                                            |
| 329 |     84.124461 |    343.641190 | Kamil S. Jaron                                                                                                                                                        |
| 330 |    933.709431 |    257.252208 | Matt Crook                                                                                                                                                            |
| 331 |    631.262797 |     32.548831 | Margot Michaud                                                                                                                                                        |
| 332 |    563.317455 |    702.331125 | Gustav Mützel                                                                                                                                                         |
| 333 |   1009.521595 |    380.129773 | Jagged Fang Designs                                                                                                                                                   |
| 334 |    758.277837 |    671.809281 | Steven Traver                                                                                                                                                         |
| 335 |    229.292271 |    524.572283 | Margot Michaud                                                                                                                                                        |
| 336 |    531.969108 |     17.737076 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 337 |    892.951475 |    783.430177 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 338 |    168.435881 |    120.832266 | Gareth Monger                                                                                                                                                         |
| 339 |    168.831340 |    244.174360 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 340 |    150.711801 |    553.575382 | Maija Karala                                                                                                                                                          |
| 341 |    704.947128 |    519.248144 | NA                                                                                                                                                                    |
| 342 |    906.014672 |    140.943462 | Matt Crook                                                                                                                                                            |
| 343 |    698.507617 |    243.999015 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 344 |    473.996104 |    652.542001 | Tasman Dixon                                                                                                                                                          |
| 345 |    889.096792 |    478.748061 | Dean Schnabel                                                                                                                                                         |
| 346 |    878.129825 |    768.172712 | Markus A. Grohme                                                                                                                                                      |
| 347 |    749.757726 |      5.776973 | Christoph Schomburg                                                                                                                                                   |
| 348 |    382.194693 |    251.715201 | Markus A. Grohme                                                                                                                                                      |
| 349 |    131.979311 |     36.224172 | Ignacio Contreras                                                                                                                                                     |
| 350 |    495.940894 |     19.143447 | NA                                                                                                                                                                    |
| 351 |    540.414364 |    527.916050 | Chase Brownstein                                                                                                                                                      |
| 352 |    188.915524 |    668.076032 | Zimices                                                                                                                                                               |
| 353 |    856.020490 |    781.446248 | Zimices                                                                                                                                                               |
| 354 |    909.044880 |     69.203524 | C. Camilo Julián-Caballero                                                                                                                                            |
| 355 |    597.505817 |    172.726287 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 356 |   1002.322886 |    467.919202 | Markus A. Grohme                                                                                                                                                      |
| 357 |    519.043178 |     78.774246 | Matt Crook                                                                                                                                                            |
| 358 |     77.402686 |    271.591142 | Jaime Headden                                                                                                                                                         |
| 359 |    618.977329 |    470.755119 | Matt Martyniuk                                                                                                                                                        |
| 360 |    256.862725 |      4.842302 | Scott Hartman                                                                                                                                                         |
| 361 |    750.602440 |    409.818041 | Tracy A. Heath                                                                                                                                                        |
| 362 |    771.187180 |    358.624209 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 363 |    244.717158 |    210.833174 | Andy Wilson                                                                                                                                                           |
| 364 |    393.090600 |    533.795291 | Matt Crook                                                                                                                                                            |
| 365 |    892.583408 |    695.658291 | Trond R. Oskars                                                                                                                                                       |
| 366 |    554.903302 |    530.691612 | Joanna Wolfe                                                                                                                                                          |
| 367 |     91.341977 |     51.734704 | FJDegrange                                                                                                                                                            |
| 368 |    580.332163 |    394.849665 | Jagged Fang Designs                                                                                                                                                   |
| 369 |    711.421855 |    412.261838 | Chris A. Hamilton                                                                                                                                                     |
| 370 |    626.810748 |    303.700193 | Scott Hartman                                                                                                                                                         |
| 371 |    413.697055 |    717.241831 | Manabu Sakamoto                                                                                                                                                       |
| 372 |    687.897258 |     35.884092 | Erika Schumacher                                                                                                                                                      |
| 373 |    831.066935 |    126.998986 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 374 |    278.398285 |    731.100137 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                             |
| 375 |    290.841329 |    469.608869 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 376 |    242.220202 |    532.337132 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
| 377 |    720.258084 |    738.242002 | Ewald Rübsamen                                                                                                                                                        |
| 378 |    258.830918 |    756.756957 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
| 379 |    448.159504 |    197.806735 | Margot Michaud                                                                                                                                                        |
| 380 |    985.484411 |    463.340003 | Michael Scroggie                                                                                                                                                      |
| 381 |    774.680567 |    275.306255 | Yan Wong                                                                                                                                                              |
| 382 |     58.266236 |    282.390365 | Scott Hartman                                                                                                                                                         |
| 383 |    606.986858 |    382.526685 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 384 |    894.252953 |    516.354180 | Gareth Monger                                                                                                                                                         |
| 385 |     54.512471 |    540.471237 | Scott Hartman                                                                                                                                                         |
| 386 |    703.793828 |    470.086189 | Chris huh                                                                                                                                                             |
| 387 |     27.256363 |    690.757838 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 388 |     77.860649 |    606.359276 | Matt Crook                                                                                                                                                            |
| 389 |    869.130522 |     34.300400 | Gareth Monger                                                                                                                                                         |
| 390 |    332.593653 |    258.390035 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 391 |    903.155293 |     37.731918 | Steven Traver                                                                                                                                                         |
| 392 |    683.650520 |    714.296639 | Ferran Sayol                                                                                                                                                          |
| 393 |     28.994247 |     22.389346 | Margot Michaud                                                                                                                                                        |
| 394 |    239.031615 |    131.095834 | Birgit Lang                                                                                                                                                           |
| 395 |    139.307186 |    455.084297 | Markus A. Grohme                                                                                                                                                      |
| 396 |     22.121686 |    675.149650 | Zimices                                                                                                                                                               |
| 397 |    878.507909 |    235.214287 | Matt Crook                                                                                                                                                            |
| 398 |     95.273589 |    288.005041 | Tasman Dixon                                                                                                                                                          |
| 399 |    350.563459 |    313.113189 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 400 |    310.777930 |    526.129857 | Steven Traver                                                                                                                                                         |
| 401 |     18.723105 |    493.777668 | Felix Vaux                                                                                                                                                            |
| 402 |     70.395696 |    513.887641 | xgirouxb                                                                                                                                                              |
| 403 |    908.877851 |    404.050189 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 404 |    610.181161 |    219.782169 | Jagged Fang Designs                                                                                                                                                   |
| 405 |    120.595006 |    227.647975 | Margot Michaud                                                                                                                                                        |
| 406 |    217.149943 |    765.405789 | Beth Reinke                                                                                                                                                           |
| 407 |    842.097014 |    323.071535 | Gareth Monger                                                                                                                                                         |
| 408 |    872.648922 |    609.882506 | Christoph Schomburg                                                                                                                                                   |
| 409 |    593.737036 |     11.670218 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 410 |    845.367528 |    573.913281 | Steven Traver                                                                                                                                                         |
| 411 |    779.317704 |    464.949235 | Zimices                                                                                                                                                               |
| 412 |    289.684852 |    763.135632 | Xavier Giroux-Bougard                                                                                                                                                 |
| 413 |    534.782338 |    357.843876 | Margot Michaud                                                                                                                                                        |
| 414 |     90.415561 |    592.087199 | Gareth Monger                                                                                                                                                         |
| 415 |    452.658632 |    639.011520 | Jagged Fang Designs                                                                                                                                                   |
| 416 |    457.341312 |    668.555060 | Beth Reinke                                                                                                                                                           |
| 417 |    446.800690 |    580.590586 | NA                                                                                                                                                                    |
| 418 |    205.834084 |    214.466745 | Gareth Monger                                                                                                                                                         |
| 419 |     41.896101 |    577.215608 | Ignacio Contreras                                                                                                                                                     |
| 420 |     31.656150 |    346.246889 | Maija Karala                                                                                                                                                          |
| 421 |    808.988706 |     30.654616 | NA                                                                                                                                                                    |
| 422 |    939.514003 |    490.893226 | T. Michael Keesey                                                                                                                                                     |
| 423 |    769.180837 |    700.998721 | Sarah Werning                                                                                                                                                         |
| 424 |    267.469131 |     94.511646 | Jack Mayer Wood                                                                                                                                                       |
| 425 |    485.733147 |    119.704868 | Ferran Sayol                                                                                                                                                          |
| 426 |    387.388811 |     92.549941 | Chuanixn Yu                                                                                                                                                           |
| 427 |     42.557737 |    276.125714 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 428 |    643.924278 |    648.141336 | Matt Wilkins                                                                                                                                                          |
| 429 |    498.035127 |    339.852751 | Tasman Dixon                                                                                                                                                          |
| 430 |    681.963963 |    677.679197 | Matus Valach                                                                                                                                                          |
| 431 |    588.079903 |    341.659607 | Alex Slavenko                                                                                                                                                         |
| 432 |    863.195961 |    342.260772 | Birgit Lang                                                                                                                                                           |
| 433 |     35.312993 |    625.975513 | Margot Michaud                                                                                                                                                        |
| 434 |    677.605673 |    644.985936 | Scott Hartman                                                                                                                                                         |
| 435 |      9.500984 |    715.293069 | Steven Traver                                                                                                                                                         |
| 436 |    811.797675 |    270.365000 | Scott Hartman                                                                                                                                                         |
| 437 |    100.851172 |    787.088488 | Steven Traver                                                                                                                                                         |
| 438 |    146.503456 |    579.198621 | Mathieu Basille                                                                                                                                                       |
| 439 |    229.174876 |    547.283712 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 440 |    313.327184 |    261.194166 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 441 |    750.706643 |     54.143987 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 442 |   1017.220729 |    226.179980 | Gareth Monger                                                                                                                                                         |
| 443 |    481.558792 |    797.010901 | Markus A. Grohme                                                                                                                                                      |
| 444 |   1014.075128 |    749.565278 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 445 |    165.181534 |    267.342895 | Beth Reinke                                                                                                                                                           |
| 446 |    826.517289 |    467.544113 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 447 |     39.213797 |    790.960361 | Scott Hartman                                                                                                                                                         |
| 448 |     65.318751 |    521.285357 | Markus A. Grohme                                                                                                                                                      |
| 449 |    952.075097 |    496.348850 | Jagged Fang Designs                                                                                                                                                   |
| 450 |    294.194721 |    550.905645 | Michele M Tobias                                                                                                                                                      |
| 451 |    503.252024 |    121.752917 | NA                                                                                                                                                                    |
| 452 |    279.772623 |     10.311656 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 453 |    350.084322 |    210.959921 | FunkMonk                                                                                                                                                              |
| 454 |    990.481994 |    134.000828 | Steven Traver                                                                                                                                                         |
| 455 |    416.086484 |    731.144803 | Gareth Monger                                                                                                                                                         |
| 456 |    980.534990 |    499.376888 | Birgit Lang                                                                                                                                                           |
| 457 |     49.814207 |    625.000802 | Margot Michaud                                                                                                                                                        |
| 458 |    786.253548 |    701.567010 | Juan Carlos Jerí                                                                                                                                                      |
| 459 |    288.082871 |    697.364028 | Tyler McCraney                                                                                                                                                        |
| 460 |    107.700823 |    733.589482 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 461 |    723.775950 |    221.253065 | Yan Wong                                                                                                                                                              |
| 462 |    471.562038 |    306.108696 | T. Michael Keesey                                                                                                                                                     |
| 463 |    998.150433 |    167.361883 | Ferran Sayol                                                                                                                                                          |
| 464 |    389.341905 |    727.418689 | Christoph Schomburg                                                                                                                                                   |
| 465 |    776.610815 |     23.031912 | Lily Hughes                                                                                                                                                           |
| 466 |    433.714417 |    742.606583 | Zimices                                                                                                                                                               |
| 467 |    888.183428 |    145.465445 | NA                                                                                                                                                                    |
| 468 |    417.281811 |    691.721842 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 469 |    410.111048 |    124.586821 | Maija Karala                                                                                                                                                          |
| 470 |    217.651521 |    108.458808 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
| 471 |     84.431526 |     79.639476 | Jagged Fang Designs                                                                                                                                                   |
| 472 |    652.434572 |    137.957695 | Yan Wong                                                                                                                                                              |
| 473 |    866.023726 |      2.830503 | Jagged Fang Designs                                                                                                                                                   |
| 474 |    634.836604 |    787.289326 | Matt Crook                                                                                                                                                            |
| 475 |    207.939581 |    751.308249 | Pedro de Siracusa                                                                                                                                                     |
| 476 |    761.207012 |    487.094264 | Jagged Fang Designs                                                                                                                                                   |
| 477 |    337.024906 |    181.746443 | Matt Crook                                                                                                                                                            |
| 478 |    925.579167 |    296.540289 | Tasman Dixon                                                                                                                                                          |
| 479 |    996.637125 |     21.923042 | Crystal Maier                                                                                                                                                         |
| 480 |    901.976972 |    310.028490 | Nobu Tamura                                                                                                                                                           |
| 481 |    677.779378 |      7.795617 | Chris huh                                                                                                                                                             |
| 482 |     90.005708 |    314.890479 | Matt Martyniuk                                                                                                                                                        |
| 483 |    525.989643 |    259.193694 | NA                                                                                                                                                                    |
| 484 |    817.117611 |    133.368646 | Zimices                                                                                                                                                               |
| 485 |    710.947824 |    145.786484 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 486 |   1007.766561 |    117.730541 | Birgit Lang                                                                                                                                                           |
| 487 |    598.113879 |     82.738775 | Zimices                                                                                                                                                               |
| 488 |     90.603286 |    486.282784 | Jagged Fang Designs                                                                                                                                                   |
| 489 |    427.047347 |    198.877037 | Christoph Schomburg                                                                                                                                                   |
| 490 |    314.091541 |    143.177098 | Zimices                                                                                                                                                               |
| 491 |     56.844966 |    153.635836 | T. Michael Keesey                                                                                                                                                     |
| 492 |     46.437828 |    523.377418 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 493 |    907.726885 |    577.140136 | Natasha Vitek                                                                                                                                                         |
| 494 |    888.249758 |     41.215868 | Steven Traver                                                                                                                                                         |
| 495 |    150.546511 |    646.554540 | Jiekun He                                                                                                                                                             |
| 496 |    535.000958 |    145.315840 | Zimices                                                                                                                                                               |
| 497 |   1008.090989 |     38.682572 | Jiekun He                                                                                                                                                             |
| 498 |    157.692894 |    664.077271 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 499 |    346.343337 |    387.984830 | Zimices                                                                                                                                                               |
| 500 |    395.808569 |    790.983492 | Zimices                                                                                                                                                               |
| 501 |    148.274522 |     47.293498 | Matt Crook                                                                                                                                                            |
| 502 |    707.283218 |    759.071859 | Matt Crook                                                                                                                                                            |
| 503 |    357.599854 |     35.764315 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 504 |    654.435962 |    786.533723 | T. Michael Keesey                                                                                                                                                     |
| 505 |     16.565150 |    330.600456 | Birgit Lang                                                                                                                                                           |
| 506 |    714.714696 |    212.534113 | Scott Hartman                                                                                                                                                         |
| 507 |    220.016798 |    468.107796 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 508 |     16.618006 |     50.031188 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 509 |    896.145905 |    572.079857 | Mathilde Cordellier                                                                                                                                                   |
| 510 |     27.005858 |    527.711843 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 511 |    980.038125 |    429.448608 | Alexandre Vong                                                                                                                                                        |
| 512 |    604.461728 |    625.753094 | Ferran Sayol                                                                                                                                                          |
| 513 |     72.965582 |    534.382017 | Dean Schnabel                                                                                                                                                         |
| 514 |    124.283978 |    279.768280 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 515 |   1010.199920 |    141.852372 | Steven Traver                                                                                                                                                         |
| 516 |    525.636540 |    713.210501 | Matt Crook                                                                                                                                                            |
| 517 |    663.785763 |    693.196055 | Erika Schumacher                                                                                                                                                      |
| 518 |    559.739742 |    204.628632 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 519 |    544.439864 |    654.662994 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 520 |    461.227575 |    779.553712 | FunkMonk                                                                                                                                                              |
| 521 |    308.431243 |    731.897612 | Ferran Sayol                                                                                                                                                          |
| 522 |    823.059518 |    111.862353 | Mark Witton                                                                                                                                                           |
| 523 |    790.757023 |    485.278386 | Katie S. Collins                                                                                                                                                      |
| 524 |    614.536160 |    207.635049 | Sarah Werning                                                                                                                                                         |
| 525 |    756.714174 |    187.292798 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 526 |    542.374372 |    399.399250 | Margot Michaud                                                                                                                                                        |
| 527 |    867.483480 |    245.571453 | Tasman Dixon                                                                                                                                                          |
| 528 |    519.951120 |    791.534963 | Tyler Greenfield                                                                                                                                                      |
| 529 |    533.815622 |    485.165140 | Ferran Sayol                                                                                                                                                          |
| 530 |    313.839585 |    202.483033 | David Orr                                                                                                                                                             |
| 531 |    489.976197 |    326.484166 | Carlos Cano-Barbacil                                                                                                                                                  |
| 532 |    178.149633 |    343.398423 | T. Michael Keesey                                                                                                                                                     |
| 533 |     67.602993 |    291.027370 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 534 |    467.404088 |    131.806725 | Chloé Schmidt                                                                                                                                                         |
| 535 |    227.144151 |    720.164206 | Chris huh                                                                                                                                                             |
| 536 |    545.666130 |    498.897700 | Steven Traver                                                                                                                                                         |
| 537 |      8.679198 |    377.741338 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 538 |    334.314153 |    496.849160 | Becky Barnes                                                                                                                                                          |
| 539 |    983.421997 |    168.282834 | Steven Traver                                                                                                                                                         |
| 540 |    721.033064 |     69.736813 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 541 |    642.034985 |    208.827138 | Margot Michaud                                                                                                                                                        |
| 542 |    890.008265 |     19.348690 | Ferran Sayol                                                                                                                                                          |
| 543 |    229.829830 |    725.554911 | Chris huh                                                                                                                                                             |
| 544 |    999.428099 |    389.152178 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 545 |    225.454721 |     24.394613 | Jagged Fang Designs                                                                                                                                                   |
| 546 |    563.126617 |    126.307040 | Scott Hartman                                                                                                                                                         |
| 547 |    854.340349 |    674.447112 | Birgit Lang                                                                                                                                                           |
| 548 |    620.413600 |    131.641196 | Steven Traver                                                                                                                                                         |
| 549 |    806.833994 |    640.021369 | Margot Michaud                                                                                                                                                        |
| 550 |    899.805632 |    349.857347 | NA                                                                                                                                                                    |
| 551 |    377.288027 |    623.241333 | Michelle Site                                                                                                                                                         |
| 552 |    509.328462 |    149.433704 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 553 |    223.653990 |    166.586961 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 554 |    161.095713 |    537.136135 | Anthony Caravaggi                                                                                                                                                     |
| 555 |    564.213985 |    756.467098 | Ferran Sayol                                                                                                                                                          |
| 556 |    726.908998 |    644.019913 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 557 |    536.315002 |    122.841361 | Scott Hartman                                                                                                                                                         |
| 558 |    382.670304 |    774.284772 | NA                                                                                                                                                                    |
| 559 |    841.664591 |    349.054798 | Sarah Werning                                                                                                                                                         |
| 560 |    339.953648 |    267.014931 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 561 |    200.659360 |    369.270616 | Jakovche                                                                                                                                                              |
| 562 |    712.234369 |    488.878053 | Jonathan Wells                                                                                                                                                        |
| 563 |    878.674246 |    754.225999 | Steven Traver                                                                                                                                                         |
| 564 |    249.100292 |    105.300554 | Ferran Sayol                                                                                                                                                          |
| 565 |    907.000865 |    397.525313 | Scott Hartman                                                                                                                                                         |
| 566 |    487.571170 |    779.460794 | Matt Martyniuk                                                                                                                                                        |
| 567 |    987.561393 |    407.295244 | NA                                                                                                                                                                    |
| 568 |    671.058693 |      3.719853 | Iain Reid                                                                                                                                                             |
| 569 |     14.794690 |    473.494459 | Michelle Site                                                                                                                                                         |
| 570 |    823.912151 |    334.997864 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 571 |    570.175684 |    363.476631 | FJDegrange                                                                                                                                                            |
| 572 |    534.156674 |    517.572783 | Jagged Fang Designs                                                                                                                                                   |
| 573 |    637.849259 |    221.495292 | NA                                                                                                                                                                    |
| 574 |    395.381821 |    624.316349 | Matt Crook                                                                                                                                                            |
| 575 |    203.934653 |    140.463147 | T. Michael Keesey                                                                                                                                                     |
| 576 |    827.479944 |    784.507163 | Collin Gross                                                                                                                                                          |
| 577 |    355.064081 |     27.967297 | Caleb M. Brown                                                                                                                                                        |
| 578 |    289.751732 |    758.514986 | Stuart Humphries                                                                                                                                                      |
| 579 |    383.901076 |    447.750345 | Felix Vaux                                                                                                                                                            |
| 580 |    538.368930 |    201.518586 | Matt Crook                                                                                                                                                            |
| 581 |    778.109299 |    115.301423 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 582 |    999.393718 |    667.397876 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 583 |     10.675033 |      5.283836 | Jagged Fang Designs                                                                                                                                                   |
| 584 |    147.339220 |    618.818451 | Ferran Sayol                                                                                                                                                          |
| 585 |    412.663242 |     71.064728 | Joanna Wolfe                                                                                                                                                          |
| 586 |    598.847730 |    244.048942 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 587 |    782.311866 |    535.414207 | Matt Crook                                                                                                                                                            |
| 588 |    127.893321 |    185.638979 | Anthony Caravaggi                                                                                                                                                     |
| 589 |     27.228784 |    384.689563 | Tasman Dixon                                                                                                                                                          |
| 590 |    825.975167 |    569.154986 | Margot Michaud                                                                                                                                                        |
| 591 |    388.986653 |     76.638464 | NA                                                                                                                                                                    |
| 592 |    182.988845 |    480.186071 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 593 |    122.969418 |    795.424930 | Chris huh                                                                                                                                                             |
| 594 |    417.708697 |    105.831349 | Melissa Broussard                                                                                                                                                     |
| 595 |    302.333956 |    499.936560 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 596 |    176.216970 |     22.019873 | Collin Gross                                                                                                                                                          |
| 597 |    538.944175 |    211.094191 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 598 |   1013.052847 |    594.156812 | T. Michael Keesey                                                                                                                                                     |
| 599 |    482.340442 |    298.173608 | Roberto Díaz Sibaja                                                                                                                                                   |
| 600 |     50.243502 |    167.775395 | Anthony Caravaggi                                                                                                                                                     |
| 601 |    497.476168 |    115.712711 | Gareth Monger                                                                                                                                                         |
| 602 |    603.702424 |    470.188207 | NA                                                                                                                                                                    |
| 603 |    651.661680 |    730.899079 | Martin R. Smith                                                                                                                                                       |
| 604 |    434.933385 |    179.053176 | Alexandra van der Geer                                                                                                                                                |
| 605 |    698.855867 |    129.822102 | Pete Buchholz                                                                                                                                                         |
| 606 |    216.761290 |    377.823327 | Maija Karala                                                                                                                                                          |
| 607 |   1006.888519 |    445.975593 | Marie-Aimée Allard                                                                                                                                                    |
| 608 |    362.541180 |    215.413615 | Cathy                                                                                                                                                                 |
| 609 |    417.623642 |     22.392081 | NA                                                                                                                                                                    |
| 610 |    850.445202 |    359.646132 | Tasman Dixon                                                                                                                                                          |
| 611 |    587.442518 |    127.481029 | Matt Crook                                                                                                                                                            |
| 612 |    913.869602 |    334.202775 | Jagged Fang Designs                                                                                                                                                   |
| 613 |    267.141890 |    417.190269 | Sarah Werning                                                                                                                                                         |
| 614 |    581.617156 |    305.104792 | Margot Michaud                                                                                                                                                        |
| 615 |    496.982251 |    246.466209 | T. Michael Keesey                                                                                                                                                     |
| 616 |    604.347271 |    147.847617 | Andy Wilson                                                                                                                                                           |
| 617 |    186.278950 |    751.389510 | T. Michael Keesey                                                                                                                                                     |
| 618 |    902.857629 |    367.906807 | Ferran Sayol                                                                                                                                                          |
| 619 |    696.934915 |    112.435751 | Matt Crook                                                                                                                                                            |
| 620 |    967.655494 |    178.655399 | Matt Crook                                                                                                                                                            |
| 621 |    107.823729 |    436.140469 | Dean Schnabel                                                                                                                                                         |
| 622 |    458.555838 |    399.059063 | Alex Slavenko                                                                                                                                                         |
| 623 |    171.617567 |    360.943079 | Ingo Braasch                                                                                                                                                          |
| 624 |    244.314207 |    664.023253 | Tracy A. Heath                                                                                                                                                        |
| 625 |    640.623144 |    704.348486 | Andy Wilson                                                                                                                                                           |
| 626 |    333.372749 |    144.302725 | Ignacio Contreras                                                                                                                                                     |
| 627 |    237.702549 |    362.987609 | NA                                                                                                                                                                    |
| 628 |    904.643061 |    718.449039 | NA                                                                                                                                                                    |
| 629 |    239.540086 |    107.487682 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 630 |    854.574516 |    517.056362 | Matt Crook                                                                                                                                                            |
| 631 |    558.900059 |    145.289277 | Jagged Fang Designs                                                                                                                                                   |
| 632 |    425.068496 |    163.635867 | Margot Michaud                                                                                                                                                        |
| 633 |     50.747451 |    307.465066 | Jagged Fang Designs                                                                                                                                                   |
| 634 |    861.002049 |    729.944234 | Zimices                                                                                                                                                               |
| 635 |    278.191369 |    744.706305 | Kamil S. Jaron                                                                                                                                                        |
| 636 |    256.915034 |     19.001528 | Chuanixn Yu                                                                                                                                                           |
| 637 |    267.058443 |    671.090132 | Chris huh                                                                                                                                                             |
| 638 |    689.808702 |    629.302372 | Chris huh                                                                                                                                                             |
| 639 |    173.027624 |    299.820715 | Scott Hartman                                                                                                                                                         |
| 640 |     18.998473 |    463.377115 | Sharon Wegner-Larsen                                                                                                                                                  |
| 641 |    928.723887 |    603.934654 | Caleb Brown                                                                                                                                                           |
| 642 |     11.531014 |    793.299049 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 643 |    967.060739 |    206.902386 | NA                                                                                                                                                                    |
| 644 |    833.553090 |    639.390042 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
| 645 |    407.533438 |    153.391268 | Andrew A. Farke                                                                                                                                                       |
| 646 |    790.006640 |    471.355402 | T. Michael Keesey                                                                                                                                                     |
| 647 |    286.891581 |    780.960703 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 648 |    765.800355 |     55.791193 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 649 |    526.513153 |    529.841469 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 650 |    223.013693 |    753.922878 | Gareth Monger                                                                                                                                                         |
| 651 |    520.610145 |    646.621842 | Matt Crook                                                                                                                                                            |
| 652 |    699.790617 |    222.730514 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 653 |    625.448278 |    401.205385 | Ferran Sayol                                                                                                                                                          |
| 654 |    167.512694 |    576.457760 | Lily Hughes                                                                                                                                                           |
| 655 |    991.042562 |    429.584961 | (after McCulloch 1908)                                                                                                                                                |
| 656 |    591.855457 |    322.414549 | Kamil S. Jaron                                                                                                                                                        |
| 657 |    639.847086 |    304.171505 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 658 |    931.251726 |    409.319647 | Tasman Dixon                                                                                                                                                          |
| 659 |    277.653529 |     99.015164 | Chris huh                                                                                                                                                             |
| 660 |      6.776107 |    544.543909 | NA                                                                                                                                                                    |
| 661 |    347.852627 |    790.151192 | Andrew R. Gehrke                                                                                                                                                      |
| 662 |    427.842872 |    711.365736 | Roberto Díaz Sibaja                                                                                                                                                   |
| 663 |    612.964572 |    408.723278 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 664 |    349.588555 |    485.250904 | Shyamal                                                                                                                                                               |
| 665 |    156.175496 |    587.158396 | Armin Reindl                                                                                                                                                          |
| 666 |    314.120027 |    413.833653 | Gareth Monger                                                                                                                                                         |
| 667 |     28.838361 |    730.708120 | Margot Michaud                                                                                                                                                        |
| 668 |    370.902314 |    234.893493 | Zimices                                                                                                                                                               |
| 669 |    982.558969 |    563.708994 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 670 |    152.024901 |    769.231771 | Carlos Cano-Barbacil                                                                                                                                                  |
| 671 |     17.151310 |    752.486736 | Zimices                                                                                                                                                               |
| 672 |    663.728879 |    631.030367 | Sharon Wegner-Larsen                                                                                                                                                  |
| 673 |    378.420765 |    708.341661 | Maija Karala                                                                                                                                                          |
| 674 |    932.559909 |    422.584427 | Gareth Monger                                                                                                                                                         |
| 675 |    157.303865 |    178.435954 | Zimices                                                                                                                                                               |
| 676 |    563.163775 |    783.228815 | Ferran Sayol                                                                                                                                                          |
| 677 |    245.939083 |    162.565711 | FunkMonk                                                                                                                                                              |
| 678 |     10.080412 |    432.752074 | NA                                                                                                                                                                    |
| 679 |    592.305748 |    745.114822 | Jagged Fang Designs                                                                                                                                                   |
| 680 |    433.838330 |    398.777398 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 681 |    809.684842 |     17.335047 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 682 |    562.901237 |    345.624643 | Gareth Monger                                                                                                                                                         |
| 683 |    316.988954 |    425.669022 | Anthony Caravaggi                                                                                                                                                     |
| 684 |    140.078495 |    565.567755 | Zimices                                                                                                                                                               |
| 685 |      5.467695 |     82.175428 | T. Michael Keesey                                                                                                                                                     |
| 686 |    708.057898 |    789.128302 | Ferran Sayol                                                                                                                                                          |
| 687 |     51.025311 |    255.365246 | C. Camilo Julián-Caballero                                                                                                                                            |
| 688 |    407.531949 |    531.739906 | Andy Wilson                                                                                                                                                           |
| 689 |    452.478634 |    424.201318 | Markus A. Grohme                                                                                                                                                      |
| 690 |    986.138360 |    215.745064 | David Orr                                                                                                                                                             |
| 691 |    636.943731 |    731.014963 | Andreas Hejnol                                                                                                                                                        |
| 692 |    351.175881 |    111.407474 | Tasman Dixon                                                                                                                                                          |
| 693 |     69.474157 |    339.356649 | Dean Schnabel                                                                                                                                                         |
| 694 |    876.665768 |    315.710881 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 695 |    506.784146 |    262.188898 | Jake Warner                                                                                                                                                           |
| 696 |    474.387113 |    117.237087 | Matt Crook                                                                                                                                                            |
| 697 |    610.919717 |      5.806206 | Emily Willoughby                                                                                                                                                      |
| 698 |    126.819846 |    614.847814 | Zimices                                                                                                                                                               |
| 699 |    816.996681 |    425.735647 | Matt Celeskey                                                                                                                                                         |
| 700 |    726.359299 |    426.397104 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 701 |    260.406604 |    119.005219 | NA                                                                                                                                                                    |
| 702 |    993.606809 |    311.399199 | Cristopher Silva                                                                                                                                                      |
| 703 |    426.697184 |    183.228988 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 704 |     79.899083 |    362.968301 | Sarah Werning                                                                                                                                                         |
| 705 |   1011.886895 |      9.065271 | Scott Hartman                                                                                                                                                         |
| 706 |    542.090291 |    720.799137 | T. Michael Keesey                                                                                                                                                     |
| 707 |     30.521789 |    255.358853 | Ferran Sayol                                                                                                                                                          |
| 708 |    583.116681 |    704.915081 | Steven Traver                                                                                                                                                         |
| 709 |    602.756765 |    757.044641 | Matt Crook                                                                                                                                                            |
| 710 |    163.610586 |    570.974488 | Margot Michaud                                                                                                                                                        |
| 711 |    157.086250 |    685.231878 | S.Martini                                                                                                                                                             |
| 712 |    129.952717 |    257.225305 | Jagged Fang Designs                                                                                                                                                   |
| 713 |    115.459293 |    342.251049 | Jennifer Trimble                                                                                                                                                      |
| 714 |    950.872019 |    661.994408 | Chris A. Hamilton                                                                                                                                                     |
| 715 |    388.643858 |    185.996165 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 716 |    113.920295 |    320.003935 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 717 |    111.201089 |    601.222821 | Chris huh                                                                                                                                                             |
| 718 |    288.981882 |    356.163895 | Rebecca Groom                                                                                                                                                         |
| 719 |    234.766917 |    470.907942 | Zimices                                                                                                                                                               |
| 720 |    830.573940 |    484.085634 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 721 |    255.198866 |    443.248478 | Rainer Schoch                                                                                                                                                         |
| 722 |    277.270336 |    135.954871 | Andy Wilson                                                                                                                                                           |
| 723 |     20.304946 |    592.082195 | NA                                                                                                                                                                    |
| 724 |    672.005879 |    660.796616 | Matt Crook                                                                                                                                                            |
| 725 |    671.031137 |    790.931265 | Andreas Hejnol                                                                                                                                                        |
| 726 |    219.126430 |    349.483333 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 727 |    316.851778 |    489.086063 | Andy Wilson                                                                                                                                                           |
| 728 |    821.952928 |    562.262090 | Carlos Cano-Barbacil                                                                                                                                                  |
| 729 |    169.923170 |    278.126398 | Gareth Monger                                                                                                                                                         |
| 730 |    374.550480 |     23.962499 | Michelle Site                                                                                                                                                         |
| 731 |    643.384684 |    678.725367 | Zimices                                                                                                                                                               |
| 732 |    179.445425 |    764.588473 | Tasman Dixon                                                                                                                                                          |
| 733 |    984.455201 |    754.620154 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 734 |    278.833780 |    228.799915 | Armin Reindl                                                                                                                                                          |
| 735 |    612.610887 |    300.160321 | Carlos Cano-Barbacil                                                                                                                                                  |
| 736 |    954.579957 |    118.069083 | Zimices                                                                                                                                                               |
| 737 |    889.199798 |    359.460080 | Markus A. Grohme                                                                                                                                                      |
| 738 |     46.308419 |     37.830860 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 739 |    519.101537 |    133.059425 | Birgit Lang                                                                                                                                                           |
| 740 |    168.136843 |    613.344360 | Scott Hartman                                                                                                                                                         |
| 741 |    114.708966 |    396.541067 | Fernando Campos De Domenico                                                                                                                                           |
| 742 |     92.045942 |      9.897798 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 743 |    642.071914 |    630.175763 | Kamil S. Jaron                                                                                                                                                        |
| 744 |     38.645848 |    596.172252 | Andy Wilson                                                                                                                                                           |
| 745 |    968.826702 |    593.375004 | Birgit Lang                                                                                                                                                           |
| 746 |     60.988729 |    387.337515 | Carlos Cano-Barbacil                                                                                                                                                  |
| 747 |    742.288892 |    533.114616 | L. Shyamal                                                                                                                                                            |
| 748 |   1012.772259 |    661.255174 | Manabu Sakamoto                                                                                                                                                       |
| 749 |    439.439470 |    724.541383 | Joanna Wolfe                                                                                                                                                          |
| 750 |    113.807368 |    577.716218 | Julio Garza                                                                                                                                                           |
| 751 |    749.243226 |     67.956885 | Tasman Dixon                                                                                                                                                          |
| 752 |    181.449632 |    635.746226 | Matus Valach                                                                                                                                                          |
| 753 |     61.006439 |    302.320257 | Juan Carlos Jerí                                                                                                                                                      |
| 754 |    471.213195 |    212.116071 | Ferran Sayol                                                                                                                                                          |
| 755 |   1006.712986 |    336.972265 | Matt Crook                                                                                                                                                            |
| 756 |    655.444719 |    414.122420 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 757 |    661.441539 |    652.302346 | Pete Buchholz                                                                                                                                                         |
| 758 |    831.337137 |    511.016500 | Matt Crook                                                                                                                                                            |
| 759 |    701.818188 |    705.157747 | Steven Traver                                                                                                                                                         |
| 760 |    364.793981 |    702.325529 | Lauren Anderson                                                                                                                                                       |
| 761 |    977.398692 |    226.225509 | Verdilak                                                                                                                                                              |
| 762 |    913.475665 |    785.574488 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 763 |      4.598460 |    172.543688 | Ferran Sayol                                                                                                                                                          |
| 764 |    388.334505 |    142.740126 | Margot Michaud                                                                                                                                                        |
| 765 |    109.074774 |    561.822245 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 766 |   1017.899606 |    608.386956 | T. Michael Keesey                                                                                                                                                     |
| 767 |    351.644543 |    774.263751 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 768 |     22.656991 |    615.804690 | Steven Traver                                                                                                                                                         |
| 769 |    707.849407 |    678.406933 | Steven Traver                                                                                                                                                         |
| 770 |    570.738501 |    524.704429 | Lukasiniho                                                                                                                                                            |
| 771 |    448.231380 |    652.286805 | Ignacio Contreras                                                                                                                                                     |
| 772 |    979.552464 |    722.517665 | Jagged Fang Designs                                                                                                                                                   |
| 773 |     10.863385 |     67.827150 | Iain Reid                                                                                                                                                             |
| 774 |    702.603917 |    427.421276 | Chris Jennings (Risiatto)                                                                                                                                             |
| 775 |    770.581470 |    458.261909 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 776 |    394.387547 |    739.847282 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 777 |    398.521853 |     34.081144 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 778 |    195.819503 |    126.115392 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 779 |    963.781894 |      3.207869 | Jagged Fang Designs                                                                                                                                                   |
| 780 |    983.067056 |    118.441929 | Steven Traver                                                                                                                                                         |
| 781 |    840.456714 |    183.634011 | T. Michael Keesey                                                                                                                                                     |
| 782 |    304.142054 |    401.090542 | Joanna Wolfe                                                                                                                                                          |
| 783 |    476.594376 |    635.626232 | Nobu Tamura                                                                                                                                                           |
| 784 |     70.440619 |    706.618986 | Matt Crook                                                                                                                                                            |
| 785 |    302.416130 |    450.582502 | Margot Michaud                                                                                                                                                        |
| 786 |    172.968288 |    644.778141 | Margot Michaud                                                                                                                                                        |
| 787 |     32.690931 |    265.000176 | Jagged Fang Designs                                                                                                                                                   |
| 788 |    541.243981 |    685.357208 | Anthony Caravaggi                                                                                                                                                     |
| 789 |    382.611489 |    700.317080 | Jagged Fang Designs                                                                                                                                                   |
| 790 |    235.379112 |     10.936030 | Jagged Fang Designs                                                                                                                                                   |
| 791 |     57.693817 |    715.766320 | Zimices                                                                                                                                                               |
| 792 |    887.671462 |    294.432110 | Alex Slavenko                                                                                                                                                         |
| 793 |    842.524251 |    165.708022 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
| 794 |    619.396861 |    431.229338 | Matt Crook                                                                                                                                                            |
| 795 |    433.905732 |    791.820797 | Matt Crook                                                                                                                                                            |
| 796 |    887.157467 |    244.509701 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 797 |    555.648303 |    118.044470 | C. Camilo Julián-Caballero                                                                                                                                            |
| 798 |    542.182831 |     88.613634 | Bryan Carstens                                                                                                                                                        |
| 799 |    905.796909 |    590.282684 | Rachel Shoop                                                                                                                                                          |
| 800 |    934.036992 |    278.150286 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 801 |     65.334655 |    497.337742 | Meliponicultor Itaymbere                                                                                                                                              |
| 802 |    684.969753 |    233.859668 | Martin R. Smith                                                                                                                                                       |
| 803 |    196.365526 |    245.777856 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 804 |    104.616507 |    380.668087 | Zimices                                                                                                                                                               |
| 805 |    994.411380 |    710.904228 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 806 |    904.313670 |     83.344035 | Matt Crook                                                                                                                                                            |
| 807 |    968.047165 |    579.447582 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 808 |    997.362143 |    605.635789 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 809 |    489.761905 |    312.251381 | Jagged Fang Designs                                                                                                                                                   |
| 810 |    186.661729 |    378.572322 | Madeleine Price Ball                                                                                                                                                  |
| 811 |    745.587096 |    466.061156 | Gareth Monger                                                                                                                                                         |
| 812 |    750.839299 |     38.278142 | Lani Mohan                                                                                                                                                            |
| 813 |     31.894514 |    588.184197 | Michelle Site                                                                                                                                                         |
| 814 |    123.138663 |    555.489939 | Maija Karala                                                                                                                                                          |
| 815 |    316.206615 |    253.827902 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 816 |    801.606876 |    141.920284 | nicubunu                                                                                                                                                              |
| 817 |    313.389685 |    283.834463 | Darius Nau                                                                                                                                                            |
| 818 |    387.733726 |     45.834564 | Ferran Sayol                                                                                                                                                          |
| 819 |    562.029336 |    399.245689 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 820 |    278.006149 |    786.158683 | Jagged Fang Designs                                                                                                                                                   |
| 821 |    306.651916 |    571.863976 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 822 |     60.311334 |    558.573328 | Jagged Fang Designs                                                                                                                                                   |
| 823 |    403.024322 |     78.792100 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                            |
| 824 |    615.153846 |    168.519835 | Zimices                                                                                                                                                               |
| 825 |    267.652306 |    147.445733 | B. Duygu Özpolat                                                                                                                                                      |
| 826 |    771.208431 |     89.110474 | Lukasiniho                                                                                                                                                            |
| 827 |    621.355673 |    460.019770 | Zimices / Julián Bayona                                                                                                                                               |
| 828 |    276.183242 |    360.545724 | Rebecca Groom                                                                                                                                                         |
| 829 |    846.556976 |    641.515951 | Ferran Sayol                                                                                                                                                          |
| 830 |    382.647151 |    330.888293 | Kamil S. Jaron                                                                                                                                                        |
| 831 |    739.041140 |    292.700229 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 832 |    958.422629 |    483.086334 | Zimices                                                                                                                                                               |
| 833 |    469.418836 |    795.825461 | FunkMonk                                                                                                                                                              |
| 834 |    716.349943 |    135.631159 | Margot Michaud                                                                                                                                                        |
| 835 |    699.212969 |    136.727983 | Zimices                                                                                                                                                               |
| 836 |    773.924305 |    493.103302 | Becky Barnes                                                                                                                                                          |
| 837 |    557.451429 |    424.835958 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 838 |    150.955175 |    138.423252 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 839 |    198.952894 |    647.058224 | Zachary Quigley                                                                                                                                                       |
| 840 |    223.504048 |    794.378476 | Scott Hartman                                                                                                                                                         |
| 841 |    873.642184 |    717.747298 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 842 |    541.076931 |    225.217546 | Matt Crook                                                                                                                                                            |
| 843 |    647.431868 |    225.090135 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 844 |    787.681358 |    769.335027 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 845 |     19.387855 |    514.782466 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 846 |    887.321067 |    369.088047 | George Edward Lodge                                                                                                                                                   |
| 847 |    983.986820 |     17.844401 | Andy Wilson                                                                                                                                                           |
| 848 |    126.564513 |    387.064321 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 849 |    530.934459 |    463.805491 | Michael Scroggie                                                                                                                                                      |
| 850 |    325.724200 |    583.947911 | NA                                                                                                                                                                    |
| 851 |    934.021038 |    658.448680 | Alexandre Vong                                                                                                                                                        |
| 852 |    805.585470 |    471.066536 | Matt Crook                                                                                                                                                            |
| 853 |    712.185589 |     79.124935 | Ferran Sayol                                                                                                                                                          |
| 854 |     50.602809 |    262.826770 | Zimices                                                                                                                                                               |
| 855 |    969.871949 |    764.743913 | NA                                                                                                                                                                    |
| 856 |   1017.695124 |     24.197823 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 857 |    115.423113 |    371.361529 | T. Michael Keesey                                                                                                                                                     |
| 858 |    812.714364 |    719.137880 | NA                                                                                                                                                                    |
| 859 |    981.246059 |    513.087934 | Matt Crook                                                                                                                                                            |
| 860 |    528.779591 |    665.812582 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 861 |    108.713865 |    308.966429 | Jagged Fang Designs                                                                                                                                                   |
| 862 |    891.264530 |    490.487581 | Jagged Fang Designs                                                                                                                                                   |
| 863 |    351.104808 |    501.087152 | T. Michael Keesey                                                                                                                                                     |
| 864 |    283.607709 |    689.606175 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 865 |      8.458585 |    566.086983 | C. Camilo Julián-Caballero                                                                                                                                            |
| 866 |    720.472143 |    174.083242 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 867 |    505.378936 |    652.897255 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 868 |    241.297687 |    375.845609 | Patrick Strutzenberger                                                                                                                                                |
| 869 |   1006.818508 |     54.368642 | Zimices                                                                                                                                                               |
| 870 |     15.818449 |    177.938267 | Myriam\_Ramirez                                                                                                                                                       |
| 871 |    236.261033 |    248.477610 | S.Martini                                                                                                                                                             |
| 872 |    279.541587 |    428.011496 | Maha Ghazal                                                                                                                                                           |
| 873 |    619.063819 |    270.415715 | Tasman Dixon                                                                                                                                                          |
| 874 |    261.504653 |    169.174463 | Mattia Menchetti                                                                                                                                                      |
| 875 |    621.408119 |    637.942895 | Steven Traver                                                                                                                                                         |
| 876 |    149.659146 |    517.715714 | Gareth Monger                                                                                                                                                         |
| 877 |    552.927803 |    391.163320 | Andy Wilson                                                                                                                                                           |
| 878 |    996.450616 |    630.982493 | Jagged Fang Designs                                                                                                                                                   |
| 879 |    836.516414 |    667.209439 | Matt Martyniuk                                                                                                                                                        |
| 880 |    801.763308 |    283.267988 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 881 |    732.636480 |    724.628754 | Matt Crook                                                                                                                                                            |
| 882 |     15.098797 |    253.170188 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 883 |    156.572031 |    606.918825 | Zimices                                                                                                                                                               |
| 884 |    683.410415 |    509.738366 | Steven Traver                                                                                                                                                         |
| 885 |    167.868287 |    623.119135 | xgirouxb                                                                                                                                                              |
| 886 |    942.425763 |    607.535890 | Erika Schumacher                                                                                                                                                      |
| 887 |    893.415004 |    260.715903 | NA                                                                                                                                                                    |
| 888 |     41.785832 |    173.802073 | NA                                                                                                                                                                    |
| 889 |    263.101618 |    522.142385 | Emma Kissling                                                                                                                                                         |
| 890 |    236.851628 |    776.975949 | Christoph Schomburg                                                                                                                                                   |
| 891 |    282.334832 |    590.999597 | Matt Crook                                                                                                                                                            |
| 892 |    806.388030 |    561.595832 | Zimices                                                                                                                                                               |
| 893 |      8.549596 |    655.950967 | Kailah Thorn & Ben King                                                                                                                                               |
| 894 |    175.828435 |    367.949088 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 895 |    739.918603 |    751.949047 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 896 |    984.899785 |    574.119892 | Matt Crook                                                                                                                                                            |
| 897 |    652.869829 |     82.410322 | Matt Martyniuk                                                                                                                                                        |
| 898 |     22.931034 |     38.444295 | Zimices                                                                                                                                                               |
| 899 |   1013.971477 |    394.774850 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 900 |    742.719061 |    740.301832 | Chuanixn Yu                                                                                                                                                           |
| 901 |    497.180748 |    641.423869 | Chris huh                                                                                                                                                             |
| 902 |    101.814670 |    476.222567 | Sharon Wegner-Larsen                                                                                                                                                  |
| 903 |    460.045802 |    267.606930 | Cesar Julian                                                                                                                                                          |
| 904 |    921.150799 |    398.853705 | NA                                                                                                                                                                    |
| 905 |    136.267561 |    194.679395 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 906 |    762.341501 |    639.925609 | Beth Reinke                                                                                                                                                           |
| 907 |    182.551428 |    732.525163 | Yan Wong                                                                                                                                                              |
| 908 |     17.768848 |    417.881060 | Felix Vaux                                                                                                                                                            |
| 909 |    219.120582 |    737.118855 | NASA                                                                                                                                                                  |
| 910 |    738.107451 |    483.279206 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 911 |     46.714894 |    784.284772 | Gareth Monger                                                                                                                                                         |
| 912 |    404.400974 |     94.330274 | Kamil S. Jaron                                                                                                                                                        |
| 913 |     30.329149 |    377.722271 | Margot Michaud                                                                                                                                                        |
| 914 |    409.328051 |    294.425209 | Matt Crook                                                                                                                                                            |
| 915 |    862.979873 |    708.603981 | Scott Hartman                                                                                                                                                         |
| 916 |    343.332237 |    288.362517 | Jagged Fang Designs                                                                                                                                                   |
| 917 |    344.917746 |    136.007971 | Michelle Site                                                                                                                                                         |
| 918 |    673.371164 |    424.720448 | Birgit Lang                                                                                                                                                           |
| 919 |    654.248955 |    233.711857 | Chris huh                                                                                                                                                             |

    #> Your tweet has been posted!
