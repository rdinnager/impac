
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

Karla Martinez, Ghedoghedo (vectorized by T. Michael Keesey), Zimices,
Leann Biancani, photo by Kenneth Clifton, Matt Crook, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Dean Schnabel, Michelle Site, Kai R.
Caspar, Melissa Broussard, Espen Horn (model; vectorized by T. Michael
Keesey from a photo by H. Zell), Smokeybjb, T. Michael Keesey, Tess
Linden, Katie S. Collins, Steven Traver, Neil Kelley, Tauana J. Cunha,
Chris huh, Bennet McComish, photo by Avenue, Alexandre Vong, Mattia
Menchetti, Scott Hartman, Tasman Dixon, Emily Willoughby, Michael
Scroggie, Matt Martyniuk, Joanna Wolfe, Chuanixn Yu, Gareth Monger,
Collin Gross, Ian Burt (original) and T. Michael Keesey (vectorization),
Gabriela Palomo-Munoz, Lindberg (vectorized by T. Michael Keesey),
Obsidian Soul (vectorized by T. Michael Keesey), Jaime Headden, Armin
Reindl, Christoph Schomburg, Lauren Sumner-Rooney, Smokeybjb (vectorized
by T. Michael Keesey), Ingo Braasch, Jagged Fang Designs, Roberto Díaz
Sibaja, Lankester Edwin Ray (vectorized by T. Michael Keesey), Roberto
Diaz Sibaja, based on Domser, Alex Slavenko, Sarah Werning, Ieuan Jones,
Noah Schlottman, nicubunu, Sharon Wegner-Larsen, Tyler McCraney, Tony
Ayling (vectorized by T. Michael Keesey), Melissa Ingala, Markus A.
Grohme, Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Mathew Callaghan, Matt Dempsey, Mali’o Kodis, image
from the Smithsonian Institution, Oscar Sanisidro, Brian Swartz
(vectorized by T. Michael Keesey), Josefine Bohr Brask, Young and Zhao
(1972:figure 4), modified by Michael P. Taylor, Yan Wong from drawing by
T. F. Zimmermann, Jessica Anne Miller, Felix Vaux, Margot Michaud,
Ignacio Contreras, xgirouxb, Jack Mayer Wood, Mason McNair,
Dantheman9758 (vectorized by T. Michael Keesey), Shyamal,
Archaeodontosaurus (vectorized by T. Michael Keesey), Renata F. Martins,
Andrés Sánchez, Birgit Lang, Renato Santos, Antonov (vectorized by T.
Michael Keesey), L. Shyamal, DW Bapst (modified from Bates et al.,
2005), Becky Barnes, M. Garfield & K. Anderson (modified by T. Michael
Keesey), Mali’o Kodis, image from the “Proceedings of the Zoological
Society of London”, Sean McCann, Caio Bernardes, vectorized by Zimices,
Ferran Sayol, Tony Ayling, Sarah Alewijnse, Nobu Tamura (vectorized by
T. Michael Keesey), Matt Martyniuk (vectorized by T. Michael Keesey),
Rebecca Groom, B. Duygu Özpolat, Mali’o Kodis, photograph from Jersabek
et al, 2003, C. Camilo Julián-Caballero, Mario Quevedo, Yan Wong from
photo by Gyik Toma, Martin R. Smith, Peileppe, Julio Garza, Tracy A.
Heath, Noah Schlottman, photo by Reinhard Jahn, Tomas Willems
(vectorized by T. Michael Keesey), T. Tischler, Chloé Schmidt, Jimmy
Bernot, Robert Gay, Lily Hughes, Hanyong Pu, Yoshitsugu Kobayashi,
Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia &
T. Michael Keesey, Mali’o Kodis, photograph by Derek Keats
(<http://www.flickr.com/photos/dkeats/>), Andrew A. Farke, Jose Carlos
Arenas-Monroy, Fernando Carezzano, kreidefossilien.de, Kamil S. Jaron,
Andreas Trepte (vectorized by T. Michael Keesey), Rainer Schoch,
Terpsichores, Robert Bruce Horsfall, vectorized by Zimices, FunkMonk,
Carlos Cano-Barbacil, Manabu Sakamoto, NOAA Great Lakes Environmental
Research Laboratory (illustration) and Timothy J. Bartley (silhouette),
Scott Reid, Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong),
Zimices / Julián Bayona, M Kolmann, David Tana, Sergio A. Muñoz-Gómez,
Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T.
Michael Keesey (vectorization), Courtney Rockenbach, Crystal Maier,
Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Oren Peles / vectorized by Yan Wong, Tambja (vectorized by T. Michael
Keesey), Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Sam Droege (photography) and T. Michael Keesey (vectorization), Noah
Schlottman, photo by Antonio Guillén, Konsta Happonen, from a CC-BY-NC
image by pelhonen on iNaturalist, Francisco Manuel Blanco (vectorized by
T. Michael Keesey), C. W. Nash (illustration) and Timothy J. Bartley
(silhouette), Nobu Tamura, vectorized by Zimices, Mihai Dragos
(vectorized by T. Michael Keesey), Verisimilus, Moussa Direct
Ltd. (photography) and T. Michael Keesey (vectorization), Stuart
Humphries, David Orr, Brian Gratwicke (photo) and T. Michael Keesey
(vectorization), Milton Tan, Sibi (vectorized by T. Michael Keesey),
Mathew Wedel, Beth Reinke, Maxime Dahirel, S.Martini, Inessa Voet, James
R. Spotila and Ray Chatterji, Xavier Giroux-Bougard, Daniel Stadtmauer,
Mykle Hoban, Steven Coombs, Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, Geoff Shaw, Steven Coombs (vectorized by T.
Michael Keesey), James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Harold N Eyster, Philip Chalmers (vectorized by T. Michael
Keesey), Lauren Anderson, Duane Raver/USFWS, Steven Haddock
• Jellywatch.org, Yan Wong, Lisa Byrne, Gustav Mützel, Vanessa
Guerra, Birgit Lang, based on a photo by D. Sikes, Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Dmitry Bogdanov (modified by T. Michael Keesey), Rene Martin,
FunkMonk (Michael B.H.; vectorized by T. Michael Keesey), Nobu Tamura,
modified by Andrew A. Farke, Iain Reid, Scarlet23 (vectorized by T.
Michael Keesey), Charles R. Knight (vectorized by T. Michael Keesey),
Haplochromis (vectorized by T. Michael Keesey), T. Michael Keesey (after
Masteraah), T. Michael Keesey (after MPF), Cristina Guijarro, Arthur S.
Brum, Kimberly Haddrell, Maija Karala, Trond R. Oskars, Mathieu Basille,
www.studiospectre.com, T. Michael Keesey (after Walker & al.), T.
Michael Keesey (after Heinrich Harder), Lukasiniho, Lukas Panzarin, Nobu
Tamura, SauropodomorphMonarch, Dianne Bray / Museum Victoria (vectorized
by T. Michael Keesey), Giant Blue Anteater (vectorized by T. Michael
Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    540.599673 |    469.769970 | Karla Martinez                                                                                                                                                                  |
|   2 |    323.276989 |    715.633448 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
|   3 |    467.523481 |    738.339538 | Zimices                                                                                                                                                                         |
|   4 |    939.713378 |    277.487803 | Leann Biancani, photo by Kenneth Clifton                                                                                                                                        |
|   5 |    389.617006 |    489.167208 | Matt Crook                                                                                                                                                                      |
|   6 |    481.515635 |    609.331745 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|   7 |    721.372461 |    238.995653 | Dean Schnabel                                                                                                                                                                   |
|   8 |    846.641535 |    103.326846 | Michelle Site                                                                                                                                                                   |
|   9 |    669.590914 |    585.683166 | Kai R. Caspar                                                                                                                                                                   |
|  10 |    140.806311 |    663.698905 | Melissa Broussard                                                                                                                                                               |
|  11 |    731.803719 |    397.264087 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                     |
|  12 |    207.282944 |    380.424722 | Smokeybjb                                                                                                                                                                       |
|  13 |    969.028956 |    508.838216 | T. Michael Keesey                                                                                                                                                               |
|  14 |    260.973090 |    186.744336 | Tess Linden                                                                                                                                                                     |
|  15 |    914.984691 |    164.861728 | Katie S. Collins                                                                                                                                                                |
|  16 |    544.175054 |    108.137356 | Steven Traver                                                                                                                                                                   |
|  17 |    175.502925 |    268.399213 | Neil Kelley                                                                                                                                                                     |
|  18 |    282.358641 |    588.152208 | Tauana J. Cunha                                                                                                                                                                 |
|  19 |    934.583846 |    758.241892 | Chris huh                                                                                                                                                                       |
|  20 |    169.958242 |    478.423374 | Kai R. Caspar                                                                                                                                                                   |
|  21 |    848.727252 |    697.605955 | Bennet McComish, photo by Avenue                                                                                                                                                |
|  22 |    944.249310 |    669.714013 | Alexandre Vong                                                                                                                                                                  |
|  23 |     80.396815 |    728.042388 | Mattia Menchetti                                                                                                                                                                |
|  24 |    422.749583 |    299.014100 | Scott Hartman                                                                                                                                                                   |
|  25 |    544.925198 |    239.667945 | NA                                                                                                                                                                              |
|  26 |    340.197006 |     83.301148 | Matt Crook                                                                                                                                                                      |
|  27 |    722.290301 |    638.351236 | Tasman Dixon                                                                                                                                                                    |
|  28 |    713.452028 |     63.529536 | Zimices                                                                                                                                                                         |
|  29 |    439.076403 |    188.207203 | Emily Willoughby                                                                                                                                                                |
|  30 |     75.572065 |     55.643143 | Michael Scroggie                                                                                                                                                                |
|  31 |    908.846372 |    397.757157 | Zimices                                                                                                                                                                         |
|  32 |    743.014186 |    760.029094 | Matt Martyniuk                                                                                                                                                                  |
|  33 |    385.474736 |    660.373721 | Joanna Wolfe                                                                                                                                                                    |
|  34 |    357.075827 |    357.423522 | Chuanixn Yu                                                                                                                                                                     |
|  35 |    781.417099 |    492.244762 | Gareth Monger                                                                                                                                                                   |
|  36 |    235.043966 |    116.085498 | Collin Gross                                                                                                                                                                    |
|  37 |    358.182196 |    259.189167 | Zimices                                                                                                                                                                         |
|  38 |    718.370921 |    142.048132 | Chris huh                                                                                                                                                                       |
|  39 |    582.443271 |    597.110063 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                       |
|  40 |    218.284758 |    731.334834 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  41 |     65.191711 |    163.083576 | Matt Crook                                                                                                                                                                      |
|  42 |    232.977680 |     48.724651 | Tasman Dixon                                                                                                                                                                    |
|  43 |    446.440139 |    558.042265 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                      |
|  44 |    120.283701 |    205.731241 | Gareth Monger                                                                                                                                                                   |
|  45 |     71.479083 |    592.522932 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
|  46 |    641.363298 |    490.013048 | Jaime Headden                                                                                                                                                                   |
|  47 |    583.961356 |     23.195015 | Armin Reindl                                                                                                                                                                    |
|  48 |    369.113920 |    455.424321 | Matt Crook                                                                                                                                                                      |
|  49 |    496.363748 |    338.523609 | Zimices                                                                                                                                                                         |
|  50 |     74.293681 |    404.483421 | Christoph Schomburg                                                                                                                                                             |
|  51 |    624.117701 |    750.394186 | Lauren Sumner-Rooney                                                                                                                                                            |
|  52 |    228.177679 |    420.011084 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
|  53 |    788.491986 |    573.075718 | Ingo Braasch                                                                                                                                                                    |
|  54 |    677.566177 |    355.546401 | Jagged Fang Designs                                                                                                                                                             |
|  55 |     72.798806 |    287.204708 | Gareth Monger                                                                                                                                                                   |
|  56 |    341.687077 |    767.763165 | Roberto Díaz Sibaja                                                                                                                                                             |
|  57 |    181.724141 |    326.757864 | Christoph Schomburg                                                                                                                                                             |
|  58 |    665.934467 |    688.209178 | T. Michael Keesey                                                                                                                                                               |
|  59 |    807.554241 |    317.564773 | Matt Crook                                                                                                                                                                      |
|  60 |     29.541950 |    503.035954 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                           |
|  61 |    996.833174 |    216.095878 | Gareth Monger                                                                                                                                                                   |
|  62 |    462.492929 |     39.884411 | Roberto Diaz Sibaja, based on Domser                                                                                                                                            |
|  63 |    160.771570 |    157.876401 | Alex Slavenko                                                                                                                                                                   |
|  64 |    155.234655 |    600.609131 | Chris huh                                                                                                                                                                       |
|  65 |    239.887167 |    263.558054 | Jagged Fang Designs                                                                                                                                                             |
|  66 |    837.852938 |    744.878965 | Sarah Werning                                                                                                                                                                   |
|  67 |    962.034529 |     86.670179 | Ieuan Jones                                                                                                                                                                     |
|  68 |    830.843194 |    640.715311 | Noah Schlottman                                                                                                                                                                 |
|  69 |    844.941756 |     38.754642 | nicubunu                                                                                                                                                                        |
|  70 |    884.947788 |    526.843306 | Sharon Wegner-Larsen                                                                                                                                                            |
|  71 |     85.694429 |    356.099565 | Tyler McCraney                                                                                                                                                                  |
|  72 |    539.931559 |    282.605880 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
|  73 |    504.052157 |    666.056063 | Melissa Ingala                                                                                                                                                                  |
|  74 |    183.002974 |    525.840405 | Gareth Monger                                                                                                                                                                   |
|  75 |    550.847475 |    789.774041 | Dean Schnabel                                                                                                                                                                   |
|  76 |    601.964444 |     58.429678 | Markus A. Grohme                                                                                                                                                                |
|  77 |    843.345226 |    213.512331 | Emily Willoughby                                                                                                                                                                |
|  78 |    593.654686 |    160.289118 | NA                                                                                                                                                                              |
|  79 |    603.546352 |    379.437671 | NA                                                                                                                                                                              |
|  80 |    632.625121 |    105.330734 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                                  |
|  81 |    374.245707 |    579.169479 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
|  82 |    691.515317 |    545.997996 | Zimices                                                                                                                                                                         |
|  83 |    996.994072 |    327.321031 | Mathew Callaghan                                                                                                                                                                |
|  84 |    570.969663 |    729.927881 | Chris huh                                                                                                                                                                       |
|  85 |    327.319339 |    428.125973 | Jagged Fang Designs                                                                                                                                                             |
|  86 |    900.199156 |    461.593422 | Scott Hartman                                                                                                                                                                   |
|  87 |    627.682220 |     10.826508 | Matt Dempsey                                                                                                                                                                    |
|  88 |    337.812017 |    174.552018 | NA                                                                                                                                                                              |
|  89 |    755.119371 |    110.238420 | Tasman Dixon                                                                                                                                                                    |
|  90 |    263.754737 |    452.809178 | Steven Traver                                                                                                                                                                   |
|  91 |    906.977911 |    687.356952 | Jagged Fang Designs                                                                                                                                                             |
|  92 |    772.830484 |    687.671869 | Chris huh                                                                                                                                                                       |
|  93 |    277.307550 |    321.052946 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                            |
|  94 |    276.174868 |    530.962980 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  95 |    822.836775 |    395.596919 | Oscar Sanisidro                                                                                                                                                                 |
|  96 |   1010.883612 |    390.298687 | Dean Schnabel                                                                                                                                                                   |
|  97 |    413.784504 |     21.047208 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                                  |
|  98 |    972.159777 |     37.204232 | Dean Schnabel                                                                                                                                                                   |
|  99 |    984.016495 |    124.265756 | Kai R. Caspar                                                                                                                                                                   |
| 100 |    556.322143 |    295.420620 | Matt Martyniuk                                                                                                                                                                  |
| 101 |    379.017649 |    158.641970 | Josefine Bohr Brask                                                                                                                                                             |
| 102 |    221.587873 |     14.343878 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                   |
| 103 |    696.228146 |    584.255831 | Chris huh                                                                                                                                                                       |
| 104 |     52.490027 |    574.693228 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                                       |
| 105 |    462.305512 |    416.013155 | Armin Reindl                                                                                                                                                                    |
| 106 |    460.846469 |    266.726751 | Steven Traver                                                                                                                                                                   |
| 107 |    976.674295 |    621.954504 | Scott Hartman                                                                                                                                                                   |
| 108 |    556.114893 |    699.461603 | Dean Schnabel                                                                                                                                                                   |
| 109 |    448.274332 |    683.808910 | T. Michael Keesey                                                                                                                                                               |
| 110 |    277.968030 |    365.733604 | Scott Hartman                                                                                                                                                                   |
| 111 |    856.191458 |    608.058211 | Jessica Anne Miller                                                                                                                                                             |
| 112 |    810.030640 |    199.594525 | Sarah Werning                                                                                                                                                                   |
| 113 |    911.663753 |    615.881952 | Tasman Dixon                                                                                                                                                                    |
| 114 |    302.292414 |    155.426221 | Matt Crook                                                                                                                                                                      |
| 115 |    125.117579 |    764.183107 | Felix Vaux                                                                                                                                                                      |
| 116 |     16.079560 |    278.919640 | Margot Michaud                                                                                                                                                                  |
| 117 |    462.843354 |    630.115456 | Melissa Broussard                                                                                                                                                               |
| 118 |    128.473035 |    427.278934 | Steven Traver                                                                                                                                                                   |
| 119 |    408.070520 |     91.162205 | Scott Hartman                                                                                                                                                                   |
| 120 |    307.865526 |    390.269291 | Ignacio Contreras                                                                                                                                                               |
| 121 |    832.477624 |    781.093602 | Matt Crook                                                                                                                                                                      |
| 122 |     64.169316 |    787.658824 | xgirouxb                                                                                                                                                                        |
| 123 |    200.250228 |     82.394673 | NA                                                                                                                                                                              |
| 124 |    944.588690 |    353.430776 | Jack Mayer Wood                                                                                                                                                                 |
| 125 |    497.187128 |    362.495740 | Christoph Schomburg                                                                                                                                                             |
| 126 |     32.465094 |    768.537259 | Zimices                                                                                                                                                                         |
| 127 |    630.207450 |    779.460048 | Mason McNair                                                                                                                                                                    |
| 128 |    477.062776 |     73.978521 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                                 |
| 129 |     10.617995 |    379.088666 | Emily Willoughby                                                                                                                                                                |
| 130 |     52.589019 |    459.143041 | Shyamal                                                                                                                                                                         |
| 131 |    683.824689 |     69.983058 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                            |
| 132 |    991.690897 |    643.165445 | Margot Michaud                                                                                                                                                                  |
| 133 |    467.552515 |     10.908897 | Margot Michaud                                                                                                                                                                  |
| 134 |    917.912062 |     35.373350 | Renata F. Martins                                                                                                                                                               |
| 135 |    104.551866 |    113.429928 | Andrés Sánchez                                                                                                                                                                  |
| 136 |     69.217111 |    428.765703 | Birgit Lang                                                                                                                                                                     |
| 137 |     13.228199 |    451.719597 | Kai R. Caspar                                                                                                                                                                   |
| 138 |    470.090887 |    487.468423 | Renato Santos                                                                                                                                                                   |
| 139 |    667.977494 |    728.215556 | Scott Hartman                                                                                                                                                                   |
| 140 |    970.591535 |    704.018807 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                       |
| 141 |    147.135991 |    170.530301 | L. Shyamal                                                                                                                                                                      |
| 142 |    326.259252 |    378.140471 | DW Bapst (modified from Bates et al., 2005)                                                                                                                                     |
| 143 |    713.627041 |    512.092156 | Becky Barnes                                                                                                                                                                    |
| 144 |    303.722642 |    667.624757 | Margot Michaud                                                                                                                                                                  |
| 145 |    287.702639 |    470.996185 | NA                                                                                                                                                                              |
| 146 |    763.950041 |    170.568748 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                       |
| 147 |    963.746623 |    232.568230 | Markus A. Grohme                                                                                                                                                                |
| 148 |    659.212256 |    425.115795 | Tasman Dixon                                                                                                                                                                    |
| 149 |    762.976967 |    371.453084 | Birgit Lang                                                                                                                                                                     |
| 150 |    877.180519 |    756.124744 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                  |
| 151 |    111.820244 |    581.854072 | Zimices                                                                                                                                                                         |
| 152 |    468.815574 |    369.702471 | NA                                                                                                                                                                              |
| 153 |    993.772865 |    737.784966 | Chris huh                                                                                                                                                                       |
| 154 |    952.663999 |    638.615090 | Felix Vaux                                                                                                                                                                      |
| 155 |    546.787768 |    186.868489 | Gareth Monger                                                                                                                                                                   |
| 156 |    907.223073 |    350.053672 | Sean McCann                                                                                                                                                                     |
| 157 |    704.915500 |    472.839930 | Alexandre Vong                                                                                                                                                                  |
| 158 |    312.579805 |     20.169992 | Zimices                                                                                                                                                                         |
| 159 |    355.086101 |    503.600380 | Caio Bernardes, vectorized by Zimices                                                                                                                                           |
| 160 |    618.944447 |    438.093686 | Ferran Sayol                                                                                                                                                                    |
| 161 |    149.193142 |    119.059481 | Matt Crook                                                                                                                                                                      |
| 162 |    652.524389 |    786.088045 | Matt Crook                                                                                                                                                                      |
| 163 |    180.438917 |    219.260873 | Gareth Monger                                                                                                                                                                   |
| 164 |    432.723202 |    112.867316 | Tony Ayling                                                                                                                                                                     |
| 165 |    766.505862 |    779.282399 | Zimices                                                                                                                                                                         |
| 166 |    838.655270 |    141.239636 | Tauana J. Cunha                                                                                                                                                                 |
| 167 |    801.686184 |    137.983387 | Sarah Alewijnse                                                                                                                                                                 |
| 168 |     58.472123 |    494.485957 | Scott Hartman                                                                                                                                                                   |
| 169 |    368.207882 |    204.610845 | Emily Willoughby                                                                                                                                                                |
| 170 |     29.714785 |    115.600067 | Gareth Monger                                                                                                                                                                   |
| 171 |    980.618219 |    153.199522 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 172 |    836.742621 |    443.486834 | Mason McNair                                                                                                                                                                    |
| 173 |    250.895428 |    772.911460 | Matt Crook                                                                                                                                                                      |
| 174 |    404.750282 |    608.447620 | T. Michael Keesey                                                                                                                                                               |
| 175 |    271.640800 |    643.784566 | Matt Crook                                                                                                                                                                      |
| 176 |    984.856014 |     68.369006 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                |
| 177 |    890.289418 |    330.752249 | Steven Traver                                                                                                                                                                   |
| 178 |    972.294513 |    790.549492 | Rebecca Groom                                                                                                                                                                   |
| 179 |    860.489590 |    366.296934 | Tasman Dixon                                                                                                                                                                    |
| 180 |    297.617075 |    688.656180 | T. Michael Keesey                                                                                                                                                               |
| 181 |     30.317411 |    236.409855 | NA                                                                                                                                                                              |
| 182 |    276.407301 |    240.884328 | NA                                                                                                                                                                              |
| 183 |    151.797086 |    773.668579 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 184 |    619.763391 |    635.648538 | B. Duygu Özpolat                                                                                                                                                                |
| 185 |    200.496878 |    243.678865 | T. Michael Keesey                                                                                                                                                               |
| 186 |    938.590535 |     58.959697 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                              |
| 187 |    866.553512 |    665.219593 | Steven Traver                                                                                                                                                                   |
| 188 |    432.809378 |     93.623179 | Scott Hartman                                                                                                                                                                   |
| 189 |    516.076700 |    761.764201 | L. Shyamal                                                                                                                                                                      |
| 190 |    729.509338 |    725.748435 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 191 |    167.002788 |     93.729117 | Ferran Sayol                                                                                                                                                                    |
| 192 |    257.757527 |    678.965753 | Mario Quevedo                                                                                                                                                                   |
| 193 |    424.764768 |    789.720959 | Jagged Fang Designs                                                                                                                                                             |
| 194 |    854.195253 |    791.676954 | Chris huh                                                                                                                                                                       |
| 195 |    594.445716 |    329.355617 | Steven Traver                                                                                                                                                                   |
| 196 |    261.607237 |    701.057195 | Margot Michaud                                                                                                                                                                  |
| 197 |    397.585895 |    711.696134 | Yan Wong from photo by Gyik Toma                                                                                                                                                |
| 198 |    724.264456 |    682.461827 | Martin R. Smith                                                                                                                                                                 |
| 199 |    788.362721 |    167.770628 | Peileppe                                                                                                                                                                        |
| 200 |    720.602257 |    605.880679 | Julio Garza                                                                                                                                                                     |
| 201 |    680.166478 |    122.016208 | Ferran Sayol                                                                                                                                                                    |
| 202 |    877.291349 |    588.586830 | Tracy A. Heath                                                                                                                                                                  |
| 203 |    176.045696 |     76.456106 | Margot Michaud                                                                                                                                                                  |
| 204 |    434.668965 |    247.468427 | Margot Michaud                                                                                                                                                                  |
| 205 |    345.310484 |    214.807433 | Margot Michaud                                                                                                                                                                  |
| 206 |    885.924962 |    258.092463 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                                       |
| 207 |    442.261085 |    506.867322 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                         |
| 208 |    512.401630 |    201.870963 | Steven Traver                                                                                                                                                                   |
| 209 |    728.025262 |    325.038902 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 210 |    725.030186 |    369.345669 | Zimices                                                                                                                                                                         |
| 211 |    665.672055 |    468.753940 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 212 |    209.921620 |    562.781340 | xgirouxb                                                                                                                                                                        |
| 213 |    559.131748 |    356.377040 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                                 |
| 214 |     22.838722 |      8.709383 | T. Tischler                                                                                                                                                                     |
| 215 |     35.828952 |    719.719082 | Matt Crook                                                                                                                                                                      |
| 216 |     93.702337 |    544.322906 | Matt Crook                                                                                                                                                                      |
| 217 |    882.307025 |    238.103040 | Chloé Schmidt                                                                                                                                                                   |
| 218 |    631.270935 |    396.262352 | Jimmy Bernot                                                                                                                                                                    |
| 219 |    154.175604 |     47.109732 | Robert Gay                                                                                                                                                                      |
| 220 |    476.045915 |    208.741818 | Tasman Dixon                                                                                                                                                                    |
| 221 |    129.203000 |    794.222896 | Markus A. Grohme                                                                                                                                                                |
| 222 |    719.334462 |     94.109410 | T. Michael Keesey                                                                                                                                                               |
| 223 |    493.790299 |    256.072275 | Lily Hughes                                                                                                                                                                     |
| 224 |    859.895962 |    541.463088 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                                     |
| 225 |    471.416129 |     95.457393 | Birgit Lang                                                                                                                                                                     |
| 226 |    416.366528 |    214.780184 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                                |
| 227 |    582.725257 |    202.533247 | Margot Michaud                                                                                                                                                                  |
| 228 |    700.506114 |     12.896195 | Andrew A. Farke                                                                                                                                                                 |
| 229 |    507.099234 |     61.030864 | Melissa Broussard                                                                                                                                                               |
| 230 |    766.254001 |    717.553853 | Steven Traver                                                                                                                                                                   |
| 231 |    526.169598 |    624.393499 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 232 |    162.749769 |    556.748940 | Fernando Carezzano                                                                                                                                                              |
| 233 |    480.242368 |    418.400963 | kreidefossilien.de                                                                                                                                                              |
| 234 |    590.075853 |    682.106706 | Scott Hartman                                                                                                                                                                   |
| 235 |    830.027736 |    565.108976 | Gareth Monger                                                                                                                                                                   |
| 236 |    381.750267 |    553.417896 | Zimices                                                                                                                                                                         |
| 237 |    784.094015 |    119.179649 | Tasman Dixon                                                                                                                                                                    |
| 238 |    172.046710 |    315.377854 | Kamil S. Jaron                                                                                                                                                                  |
| 239 |    159.408764 |    415.534024 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                |
| 240 |    782.077592 |    408.614015 | Birgit Lang                                                                                                                                                                     |
| 241 |    285.208834 |    224.521583 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 242 |    549.125688 |    755.174510 | Rainer Schoch                                                                                                                                                                   |
| 243 |    586.826954 |    183.608494 | Andrew A. Farke                                                                                                                                                                 |
| 244 |    599.748274 |    487.315157 | Terpsichores                                                                                                                                                                    |
| 245 |    136.081438 |     95.187637 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 246 |    973.085122 |    337.286595 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 247 |    627.959565 |    551.709358 | Gareth Monger                                                                                                                                                                   |
| 248 |    204.254178 |    357.847275 | Jagged Fang Designs                                                                                                                                                             |
| 249 |    820.248290 |     76.523720 | Ferran Sayol                                                                                                                                                                    |
| 250 |    391.238723 |    135.344111 | FunkMonk                                                                                                                                                                        |
| 251 |     33.679083 |    684.746071 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 252 |    796.651244 |    599.051070 | Tasman Dixon                                                                                                                                                                    |
| 253 |    384.900135 |    610.928777 | Matt Crook                                                                                                                                                                      |
| 254 |    649.852533 |    313.127000 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 255 |    933.360760 |     13.648821 | Carlos Cano-Barbacil                                                                                                                                                            |
| 256 |     77.186667 |    377.006668 | Jagged Fang Designs                                                                                                                                                             |
| 257 |     88.534387 |    497.566244 | Manabu Sakamoto                                                                                                                                                                 |
| 258 |    623.626655 |    589.726312 | Mario Quevedo                                                                                                                                                                   |
| 259 |    553.953455 |    312.573526 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 260 |    234.124034 |    233.077374 | Scott Reid                                                                                                                                                                      |
| 261 |    958.045258 |    399.780681 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 262 |    527.401624 |    148.452987 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                                        |
| 263 |    166.952085 |    353.318584 | Zimices / Julián Bayona                                                                                                                                                         |
| 264 |    242.512577 |    277.428914 | M Kolmann                                                                                                                                                                       |
| 265 |    989.317982 |    396.642936 | Ferran Sayol                                                                                                                                                                    |
| 266 |    220.874203 |    537.256954 | David Tana                                                                                                                                                                      |
| 267 |    438.120252 |    387.083365 | Andrés Sánchez                                                                                                                                                                  |
| 268 |    332.735213 |    671.277238 | Jagged Fang Designs                                                                                                                                                             |
| 269 |    684.118713 |    493.572384 | Tasman Dixon                                                                                                                                                                    |
| 270 |    479.910219 |    498.169018 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 271 |    424.265008 |    342.671875 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                              |
| 272 |    108.809917 |    784.252487 | Scott Hartman                                                                                                                                                                   |
| 273 |    196.660865 |    197.954952 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 274 |    692.882931 |    428.378627 | Courtney Rockenbach                                                                                                                                                             |
| 275 |    248.145960 |    306.873346 | Crystal Maier                                                                                                                                                                   |
| 276 |     76.250130 |    528.554965 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                                     |
| 277 |    487.284792 |     15.288959 | Oren Peles / vectorized by Yan Wong                                                                                                                                             |
| 278 |      5.717212 |     89.347852 | T. Michael Keesey                                                                                                                                                               |
| 279 |    116.161216 |    229.915859 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                        |
| 280 |    592.644937 |    707.333466 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 281 |    230.182910 |    513.937495 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 282 |    274.241520 |     35.473247 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                           |
| 283 |    223.053334 |    156.387000 | Becky Barnes                                                                                                                                                                    |
| 284 |    805.704848 |    223.849750 | Margot Michaud                                                                                                                                                                  |
| 285 |    811.037627 |    778.275493 | Zimices                                                                                                                                                                         |
| 286 |    636.695953 |    376.727032 | Ieuan Jones                                                                                                                                                                     |
| 287 |    437.959394 |     72.072641 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 288 |   1014.188320 |     30.235246 | Gareth Monger                                                                                                                                                                   |
| 289 |    606.721188 |    691.249402 | Jagged Fang Designs                                                                                                                                                             |
| 290 |    336.712685 |    520.325683 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 291 |    945.056156 |    422.877925 | Rebecca Groom                                                                                                                                                                   |
| 292 |    346.495269 |    293.584563 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 293 |    107.015258 |    522.675042 | FunkMonk                                                                                                                                                                        |
| 294 |    980.577412 |      5.522595 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                       |
| 295 |   1014.918101 |    645.468928 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                               |
| 296 |    220.438409 |    444.336479 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 297 |    630.788483 |    651.168985 | Sarah Werning                                                                                                                                                                   |
| 298 |    449.838117 |    466.562272 | Dean Schnabel                                                                                                                                                                   |
| 299 |     11.435874 |    410.147878 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                                       |
| 300 |    428.026332 |    267.616590 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                   |
| 301 |    243.255372 |    471.453183 | T. Michael Keesey                                                                                                                                                               |
| 302 |    687.431678 |    632.854694 | Scott Hartman                                                                                                                                                                   |
| 303 |    779.837410 |     13.176436 | Margot Michaud                                                                                                                                                                  |
| 304 |    339.646877 |    267.208278 | NA                                                                                                                                                                              |
| 305 |    484.245896 |    217.961530 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 306 |     51.788086 |    129.328282 | Chris huh                                                                                                                                                                       |
| 307 |    738.254454 |    435.547455 | Michelle Site                                                                                                                                                                   |
| 308 |    538.981110 |    683.316524 | Birgit Lang                                                                                                                                                                     |
| 309 |    204.648995 |    784.716671 | Melissa Broussard                                                                                                                                                               |
| 310 |    385.564211 |    408.541259 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                  |
| 311 |    969.976671 |    218.613128 | Gareth Monger                                                                                                                                                                   |
| 312 |    357.459724 |      5.762208 | Verisimilus                                                                                                                                                                     |
| 313 |    870.689341 |    560.838231 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                          |
| 314 |    880.407033 |     68.341468 | Stuart Humphries                                                                                                                                                                |
| 315 |    855.004999 |    719.516241 | Zimices                                                                                                                                                                         |
| 316 |    468.652521 |    781.183206 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 317 |    162.205161 |    265.083884 | David Orr                                                                                                                                                                       |
| 318 |    745.327607 |     18.669598 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                   |
| 319 |    258.861485 |    395.926225 | Zimices                                                                                                                                                                         |
| 320 |    846.056595 |    268.206019 | Jagged Fang Designs                                                                                                                                                             |
| 321 |    422.059374 |    136.543931 | Milton Tan                                                                                                                                                                      |
| 322 |    807.203395 |    163.599320 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                         |
| 323 |    978.702952 |    585.989719 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                          |
| 324 |    662.940076 |     90.383148 | Matt Crook                                                                                                                                                                      |
| 325 |    250.695979 |    359.158727 | Jagged Fang Designs                                                                                                                                                             |
| 326 |    328.052004 |    452.184486 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 327 |    410.649726 |    124.499103 | Mathew Wedel                                                                                                                                                                    |
| 328 |    308.168852 |    197.424480 | Julio Garza                                                                                                                                                                     |
| 329 |    286.747356 |    497.490778 | Terpsichores                                                                                                                                                                    |
| 330 |   1003.270559 |    724.545071 | Christoph Schomburg                                                                                                                                                             |
| 331 |    620.487916 |    459.311694 | Beth Reinke                                                                                                                                                                     |
| 332 |    595.627940 |    102.279654 | Zimices                                                                                                                                                                         |
| 333 |    906.769837 |    664.580162 | Jaime Headden                                                                                                                                                                   |
| 334 |    358.100282 |    633.761969 | Jagged Fang Designs                                                                                                                                                             |
| 335 |    934.517022 |    109.653276 | Armin Reindl                                                                                                                                                                    |
| 336 |    712.208606 |    563.248427 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 337 |     12.916574 |    312.182020 | Maxime Dahirel                                                                                                                                                                  |
| 338 |     87.553096 |    131.262591 | Rebecca Groom                                                                                                                                                                   |
| 339 |    229.406949 |    548.028616 | Kai R. Caspar                                                                                                                                                                   |
| 340 |    189.950885 |    139.653121 | S.Martini                                                                                                                                                                       |
| 341 |    226.278447 |    617.139738 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 342 |    946.300741 |    726.638634 | Christoph Schomburg                                                                                                                                                             |
| 343 |    713.052531 |    315.279080 | Matt Crook                                                                                                                                                                      |
| 344 |    907.490879 |    440.966315 | Scott Hartman                                                                                                                                                                   |
| 345 |    915.297791 |    786.456424 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 346 |    351.017008 |    142.838168 | Zimices                                                                                                                                                                         |
| 347 |    862.613363 |    297.479289 | Steven Traver                                                                                                                                                                   |
| 348 |    490.129580 |    123.713851 | Michael Scroggie                                                                                                                                                                |
| 349 |    564.588259 |     79.054230 | Gareth Monger                                                                                                                                                                   |
| 350 |    996.784763 |    784.067495 | Joanna Wolfe                                                                                                                                                                    |
| 351 |     23.484278 |    139.618752 | Smokeybjb                                                                                                                                                                       |
| 352 |    608.545630 |    418.368992 | Inessa Voet                                                                                                                                                                     |
| 353 |    919.555020 |    720.510963 | Melissa Broussard                                                                                                                                                               |
| 354 |    635.377755 |    419.959125 | Smokeybjb                                                                                                                                                                       |
| 355 |    855.863630 |    763.095995 | Matt Crook                                                                                                                                                                      |
| 356 |    114.432816 |    184.319128 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 357 |    931.049398 |    551.416430 | Christoph Schomburg                                                                                                                                                             |
| 358 |    471.953500 |    684.410543 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 359 |    250.370627 |    630.255541 | Dean Schnabel                                                                                                                                                                   |
| 360 |    284.098693 |    736.055043 | Scott Hartman                                                                                                                                                                   |
| 361 |    536.492366 |    779.371971 | Xavier Giroux-Bougard                                                                                                                                                           |
| 362 |    358.189691 |    416.856031 | NA                                                                                                                                                                              |
| 363 |     14.983266 |    563.331435 | Gareth Monger                                                                                                                                                                   |
| 364 |     74.451173 |    692.251530 | Roberto Díaz Sibaja                                                                                                                                                             |
| 365 |    462.541303 |    699.957888 | Daniel Stadtmauer                                                                                                                                                               |
| 366 |    578.368908 |    143.898202 | Gareth Monger                                                                                                                                                                   |
| 367 |    854.099290 |     82.267162 | Zimices                                                                                                                                                                         |
| 368 |    411.903190 |     10.983636 | Scott Hartman                                                                                                                                                                   |
| 369 |    187.400737 |    792.394984 | T. Tischler                                                                                                                                                                     |
| 370 |    924.692470 |    692.193445 | Carlos Cano-Barbacil                                                                                                                                                            |
| 371 |    824.633069 |    209.182381 | T. Michael Keesey                                                                                                                                                               |
| 372 |    284.926119 |    673.075838 | Chris huh                                                                                                                                                                       |
| 373 |    182.549820 |      6.359266 | Mykle Hoban                                                                                                                                                                     |
| 374 |    158.730313 |     63.627753 | Steven Coombs                                                                                                                                                                   |
| 375 |    393.304814 |    210.263970 | NA                                                                                                                                                                              |
| 376 |    544.169769 |    594.077310 | Matt Martyniuk                                                                                                                                                                  |
| 377 |    779.949241 |    734.701332 | Jaime Headden                                                                                                                                                                   |
| 378 |    682.714200 |      6.186730 | Scott Hartman                                                                                                                                                                   |
| 379 |    509.780881 |    148.209768 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                            |
| 380 |    847.906818 |    462.712696 | B. Duygu Özpolat                                                                                                                                                                |
| 381 |    378.792845 |    323.711146 | Geoff Shaw                                                                                                                                                                      |
| 382 |    146.247952 |    715.954584 | Matt Crook                                                                                                                                                                      |
| 383 |    521.026197 |    645.788967 | Jagged Fang Designs                                                                                                                                                             |
| 384 |    292.109226 |    649.849938 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                                 |
| 385 |    931.226341 |    337.247122 | Tasman Dixon                                                                                                                                                                    |
| 386 |    362.746932 |    178.151948 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 387 |     65.719709 |    719.435947 | Scott Hartman                                                                                                                                                                   |
| 388 |    672.044546 |    141.731001 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 389 |    442.872281 |    322.193052 | Jagged Fang Designs                                                                                                                                                             |
| 390 |    123.659399 |    622.877604 | Harold N Eyster                                                                                                                                                                 |
| 391 |     73.859074 |    766.370676 | Gareth Monger                                                                                                                                                                   |
| 392 |     13.941896 |    228.241104 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                               |
| 393 |    344.088362 |     17.816946 | T. Michael Keesey                                                                                                                                                               |
| 394 |    645.985966 |    504.689151 | Jaime Headden                                                                                                                                                                   |
| 395 |    535.052140 |    719.319161 | Matt Crook                                                                                                                                                                      |
| 396 |    517.463671 |    180.681500 | Jagged Fang Designs                                                                                                                                                             |
| 397 |    306.897450 |    607.560733 | Scott Reid                                                                                                                                                                      |
| 398 |    937.807729 |    490.387361 | Markus A. Grohme                                                                                                                                                                |
| 399 |    619.006367 |    610.507742 | Gareth Monger                                                                                                                                                                   |
| 400 |    296.616235 |     42.545146 | Lauren Anderson                                                                                                                                                                 |
| 401 |    234.299915 |     28.861145 | Scott Hartman                                                                                                                                                                   |
| 402 |    244.295036 |    283.341992 | Margot Michaud                                                                                                                                                                  |
| 403 |    547.740603 |    584.415940 | Jagged Fang Designs                                                                                                                                                             |
| 404 |    788.008384 |     76.619726 | Steven Traver                                                                                                                                                                   |
| 405 |    110.817171 |    634.928955 | NA                                                                                                                                                                              |
| 406 |    309.379966 |    351.358348 | Jagged Fang Designs                                                                                                                                                             |
| 407 |    671.309845 |    652.059369 | Carlos Cano-Barbacil                                                                                                                                                            |
| 408 |    864.895653 |    353.538469 | Duane Raver/USFWS                                                                                                                                                               |
| 409 |    575.071457 |    345.226959 | Zimices                                                                                                                                                                         |
| 410 |    169.741986 |    753.052499 | Jagged Fang Designs                                                                                                                                                             |
| 411 |    977.799942 |     53.604207 | Markus A. Grohme                                                                                                                                                                |
| 412 |    579.408053 |    671.360750 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 413 |    760.126658 |    673.248867 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 414 |     20.074284 |    666.024118 | Yan Wong                                                                                                                                                                        |
| 415 |    384.725146 |    113.342891 | Birgit Lang                                                                                                                                                                     |
| 416 |     64.638000 |    752.601783 | Tasman Dixon                                                                                                                                                                    |
| 417 |    719.242511 |    790.427496 | Lisa Byrne                                                                                                                                                                      |
| 418 |    881.870659 |    163.555614 | Gustav Mützel                                                                                                                                                                   |
| 419 |    255.300995 |    347.562169 | FunkMonk                                                                                                                                                                        |
| 420 |    235.494677 |    133.719664 | Scott Hartman                                                                                                                                                                   |
| 421 |    821.820478 |    371.820801 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 422 |    267.367470 |    787.831185 | Vanessa Guerra                                                                                                                                                                  |
| 423 |   1010.614677 |    757.148692 | Oscar Sanisidro                                                                                                                                                                 |
| 424 |    982.903139 |    283.510425 | Birgit Lang, based on a photo by D. Sikes                                                                                                                                       |
| 425 |    837.238524 |    255.880636 | Jagged Fang Designs                                                                                                                                                             |
| 426 |    664.669747 |    521.235517 | Gareth Monger                                                                                                                                                                   |
| 427 |    689.735026 |    472.675500 | Birgit Lang                                                                                                                                                                     |
| 428 |    715.959030 |    525.655467 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                          |
| 429 |     54.951991 |    528.876507 | Michelle Site                                                                                                                                                                   |
| 430 |    651.600603 |    411.531584 | Ignacio Contreras                                                                                                                                                               |
| 431 |     37.605545 |    375.279994 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                                 |
| 432 |    643.346158 |    158.175177 | Rene Martin                                                                                                                                                                     |
| 433 |    934.057344 |    529.014357 | Chris huh                                                                                                                                                                       |
| 434 |    390.591665 |    196.579891 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                        |
| 435 |    761.690714 |    420.204296 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                        |
| 436 |    741.843522 |    704.302672 | Tyler McCraney                                                                                                                                                                  |
| 437 |     54.213346 |    695.792240 | Iain Reid                                                                                                                                                                       |
| 438 |    711.626583 |    596.926522 | Scott Hartman                                                                                                                                                                   |
| 439 |    328.170936 |    687.196952 | Chris huh                                                                                                                                                                       |
| 440 |    720.695667 |     18.370562 | Smokeybjb                                                                                                                                                                       |
| 441 |    792.058459 |    715.666215 | Steven Traver                                                                                                                                                                   |
| 442 |    385.172242 |    741.100681 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                     |
| 443 |    336.005625 |    559.390229 | Steven Traver                                                                                                                                                                   |
| 444 |    376.774359 |    481.255864 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                             |
| 445 |    304.752383 |    402.568600 | L. Shyamal                                                                                                                                                                      |
| 446 |    551.244212 |    642.329404 | Tasman Dixon                                                                                                                                                                    |
| 447 |    174.714715 |    103.534483 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                  |
| 448 |    529.177831 |    612.102603 | Ignacio Contreras                                                                                                                                                               |
| 449 |    531.166041 |    299.731416 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 450 |    482.347677 |    465.039713 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 451 |    608.162452 |    194.909572 | Steven Coombs                                                                                                                                                                   |
| 452 |    864.315612 |    646.052328 | Jagged Fang Designs                                                                                                                                                             |
| 453 |    218.903798 |    396.723418 | T. Michael Keesey (after Masteraah)                                                                                                                                             |
| 454 |    776.123738 |     32.943194 | Ignacio Contreras                                                                                                                                                               |
| 455 |     63.810787 |    640.612828 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 456 |    297.585621 |    317.022944 | Gareth Monger                                                                                                                                                                   |
| 457 |    975.357334 |    178.642975 | T. Michael Keesey (after MPF)                                                                                                                                                   |
| 458 |    887.705519 |    174.641141 | Zimices                                                                                                                                                                         |
| 459 |    525.023824 |    738.092929 | Chris huh                                                                                                                                                                       |
| 460 |     88.338903 |     13.898672 | Gareth Monger                                                                                                                                                                   |
| 461 |    520.776152 |    577.204794 | Cristina Guijarro                                                                                                                                                               |
| 462 |    654.297396 |    493.749011 | Roberto Díaz Sibaja                                                                                                                                                             |
| 463 |   1015.056580 |    699.606739 | T. Michael Keesey                                                                                                                                                               |
| 464 |    383.286791 |    401.626654 | Arthur S. Brum                                                                                                                                                                  |
| 465 |    534.608124 |     52.801127 | Felix Vaux                                                                                                                                                                      |
| 466 |    378.243062 |    690.810759 | Zimices                                                                                                                                                                         |
| 467 |    802.088934 |    701.453734 | Gareth Monger                                                                                                                                                                   |
| 468 |    864.371772 |    130.712588 | T. Michael Keesey                                                                                                                                                               |
| 469 |    802.225315 |    428.832448 | Zimices                                                                                                                                                                         |
| 470 |    469.655864 |    240.346263 | Gareth Monger                                                                                                                                                                   |
| 471 |     43.611965 |     13.079347 | Carlos Cano-Barbacil                                                                                                                                                            |
| 472 |    915.041400 |    604.839034 | Jagged Fang Designs                                                                                                                                                             |
| 473 |    974.289955 |    371.920443 | Kimberly Haddrell                                                                                                                                                               |
| 474 |    162.060678 |     22.084052 | Chris huh                                                                                                                                                                       |
| 475 |    936.816050 |    794.578392 | Jagged Fang Designs                                                                                                                                                             |
| 476 |    592.741697 |    777.664851 | Carlos Cano-Barbacil                                                                                                                                                            |
| 477 |    747.516228 |    353.027170 | Margot Michaud                                                                                                                                                                  |
| 478 |    410.287878 |    696.535005 | Margot Michaud                                                                                                                                                                  |
| 479 |    876.273120 |    789.495250 | Sean McCann                                                                                                                                                                     |
| 480 |     49.622785 |    118.864242 | Ferran Sayol                                                                                                                                                                    |
| 481 |    845.881488 |    371.188446 | Gareth Monger                                                                                                                                                                   |
| 482 |    939.193458 |    450.305566 | Mathew Wedel                                                                                                                                                                    |
| 483 |    914.769052 |    702.858381 | Maija Karala                                                                                                                                                                    |
| 484 |    277.023157 |     13.075972 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 485 |    237.305022 |    635.810148 | Emily Willoughby                                                                                                                                                                |
| 486 |   1012.864128 |    206.543924 | Trond R. Oskars                                                                                                                                                                 |
| 487 |    771.061935 |    603.417706 | Mathieu Basille                                                                                                                                                                 |
| 488 |    153.705347 |     32.790252 | Jagged Fang Designs                                                                                                                                                             |
| 489 |    814.447573 |     15.417734 | Noah Schlottman                                                                                                                                                                 |
| 490 |    533.625794 |     80.114036 | NA                                                                                                                                                                              |
| 491 |    695.123702 |    720.368225 | Chuanixn Yu                                                                                                                                                                     |
| 492 |    236.579334 |    214.993000 | Armin Reindl                                                                                                                                                                    |
| 493 |     99.186879 |    242.359491 | NA                                                                                                                                                                              |
| 494 |    491.431649 |    635.978328 | Tasman Dixon                                                                                                                                                                    |
| 495 |    280.101874 |    659.313879 | Armin Reindl                                                                                                                                                                    |
| 496 |   1001.483996 |    107.429975 | Felix Vaux                                                                                                                                                                      |
| 497 |    776.356500 |    190.329954 | Scott Hartman                                                                                                                                                                   |
| 498 |    697.414904 |    166.460126 | www.studiospectre.com                                                                                                                                                           |
| 499 |    329.491631 |    648.154623 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 500 |     60.642716 |    504.728598 | Tasman Dixon                                                                                                                                                                    |
| 501 |    789.219061 |    363.855583 | David Orr                                                                                                                                                                       |
| 502 |    427.593071 |    688.234207 | T. Michael Keesey (after Walker & al.)                                                                                                                                          |
| 503 |     36.969395 |    426.578196 | Katie S. Collins                                                                                                                                                                |
| 504 |    231.191161 |    689.013617 | Markus A. Grohme                                                                                                                                                                |
| 505 |    128.081280 |    693.382758 | Jaime Headden                                                                                                                                                                   |
| 506 |    196.051935 |     56.156492 | Zimices                                                                                                                                                                         |
| 507 |    338.078103 |    695.948767 | T. Michael Keesey (after Heinrich Harder)                                                                                                                                       |
| 508 |     16.153750 |    342.701017 | Lukasiniho                                                                                                                                                                      |
| 509 |    560.087292 |     41.171544 | Tony Ayling                                                                                                                                                                     |
| 510 |    648.173945 |     20.842330 | Chris huh                                                                                                                                                                       |
| 511 |    193.820932 |    582.031166 | Xavier Giroux-Bougard                                                                                                                                                           |
| 512 |    328.989213 |    510.902095 | Chris huh                                                                                                                                                                       |
| 513 |     81.518282 |    100.638963 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                       |
| 514 |    903.836229 |     73.629552 | Collin Gross                                                                                                                                                                    |
| 515 |    483.442012 |    391.589625 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 516 |    974.086289 |    609.995896 | Lukas Panzarin                                                                                                                                                                  |
| 517 |    981.583499 |    208.207392 | Collin Gross                                                                                                                                                                    |
| 518 |    432.788061 |    154.396290 | Nobu Tamura                                                                                                                                                                     |
| 519 |    846.228535 |    554.207262 | Harold N Eyster                                                                                                                                                                 |
| 520 |    879.360402 |    617.336271 | Tasman Dixon                                                                                                                                                                    |
| 521 |    265.603378 |    470.430596 | SauropodomorphMonarch                                                                                                                                                           |
| 522 |     23.598798 |    131.333891 | Matt Dempsey                                                                                                                                                                    |
| 523 |    891.294839 |    599.026987 | Ferran Sayol                                                                                                                                                                    |
| 524 |    376.604227 |    227.910012 | Markus A. Grohme                                                                                                                                                                |
| 525 |    849.280493 |     68.684215 | Mathew Wedel                                                                                                                                                                    |
| 526 |    707.635046 |    338.259496 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                                 |
| 527 |    822.004756 |      5.688831 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                           |

    #> Your tweet has been posted!
