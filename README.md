
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

Margot Michaud, Steven Traver, Javiera Constanzo, Matthew Hooge
(vectorized by T. Michael Keesey), Owen Jones, Pranav Iyer (grey ideas),
Jagged Fang Designs, Erika Schumacher, Matt Crook, T. Michael Keesey,
Smokeybjb, Noah Schlottman, photo by Carlos Sánchez-Ortiz, Fcb981
(vectorized by T. Michael Keesey), Katie S. Collins, Michelle Site,
Alexandre Vong, Gabriela Palomo-Munoz, Ferran Sayol, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Dmitry Bogdanov (modified by T. Michael Keesey), Andy
Wilson, Roule Jammes (vectorized by T. Michael Keesey), Abraão Leite,
Scott Hartman, Henry Lydecker, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Gareth Monger, DW Bapst (modified from Bates et al., 2005),
Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Mathilde
Cordellier, Julie Blommaert based on photo by Sofdrakou, Kai R. Caspar,
Jiekun He, Maija Karala, Nobu Tamura (vectorized by T. Michael Keesey),
FunkMonk, Birgit Lang, Noah Schlottman, photo by Martin V. Sørensen,
Chris huh, Nobu Tamura, Jaime Headden, Cesar Julian, Frank Förster,
Kenneth Lacovara (vectorized by T. Michael Keesey), Scott Reid, Felix
Vaux, Ignacio Contreras, Kamil S. Jaron, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Collin Gross, Tyler Greenfield, Zimices, Caleb M. Brown, Chris A.
Hamilton, Kanchi Nanjo, Emily Willoughby, Martin R. Smith, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Dean
Schnabel, Tasman Dixon, Sergio A. Muñoz-Gómez, Tyler McCraney, Matt
Martyniuk, Steven Coombs, C. Camilo Julián-Caballero, Obsidian Soul
(vectorized by T. Michael Keesey), Smokeybjb, vectorized by Zimices,
Mali’o Kodis, photograph from Jersabek et al, 2003, Ben Moon, Rebecca
Groom (Based on Photo by Andreas Trepte), Hans Hillewaert (vectorized by
T. Michael Keesey), Anthony Caravaggi, James R. Spotila and Ray
Chatterji, Markus A. Grohme, L. Shyamal, Scarlet23 (vectorized by T.
Michael Keesey), Espen Horn (model; vectorized by T. Michael Keesey from
a photo by H. Zell), Joe Schneid (vectorized by T. Michael Keesey),
Chase Brownstein, Matthew E. Clapham, E. R. Waite & H. M. Hale
(vectorized by T. Michael Keesey), Andrew A. Farke, Evan Swigart
(photography) and T. Michael Keesey (vectorization), Nobu Tamura
(vectorized by A. Verrière), Yan Wong, Christoph Schomburg, Jose Carlos
Arenas-Monroy, Joanna Wolfe, NOAA (vectorized by T. Michael Keesey),
Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Rebecca Groom, Sarah Werning, John Conway, Jack Mayer
Wood, Beth Reinke, Y. de Hoev. (vectorized by T. Michael Keesey),
Meliponicultor Itaymbere, Becky Barnes, Steven Blackwood, Robert Bruce
Horsfall (vectorized by William Gearty), DW Bapst (Modified from
photograph taken by Charles Mitchell), Ghedoghedo (vectorized by T.
Michael Keesey), Gregor Bucher, Max Farnworth, xgirouxb, Margret
Flinsch, vectorized by Zimices, S.Martini, Darren Naish (vectorized by
T. Michael Keesey), Sarah Alewijnse, Xavier Giroux-Bougard, Scott
Hartman, modified by T. Michael Keesey, Joseph Wolf, 1863 (vectorization
by Dinah Challen), T. Michael Keesey (vectorization) and Nadiatalent
(photography), Matt Celeskey, Lukasiniho, Bennet McComish, photo by
Avenue, Dave Angelini, James I. Kirkland, Luis Alcalá, Mark A. Loewen,
Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T.
Michael Keesey), Harold N Eyster, Mathew Wedel, U.S. Fish and Wildlife
Service (illustration) and Timothy J. Bartley (silhouette), Sibi
(vectorized by T. Michael Keesey), Mattia Menchetti / Yan Wong, Mali’o
Kodis, traced image from the National Science Foundation’s Turbellarian
Taxonomic Database, Mark Miller, Michael Scroggie, Tony Ayling, Ingo
Braasch, T. Michael Keesey (after James & al.), Iain Reid, Hans
Hillewaert, Griensteidl and T. Michael Keesey, CNZdenek, Andrés Sánchez,
, Jimmy Bernot, Peter Coxhead, Noah Schlottman, photo from Casey Dunn,
Noah Schlottman, photo by Carol Cummings, Nicholas J. Czaplewski,
vectorized by Zimices, Leann Biancani, photo by Kenneth Clifton,
Kimberly Haddrell, Mateus Zica (modified by T. Michael Keesey), Noah
Schlottman, Smokeybjb (vectorized by T. Michael Keesey), Amanda Katzer,
FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey), Melissa
Ingala, Zachary Quigley, Carlos Cano-Barbacil, Christine Axon, Unknown
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Agnello Picorelli,
FunkMonk (Michael B.H.; vectorized by T. Michael Keesey), Anna
Willoughby, Lip Kee Yap (vectorized by T. Michael Keesey), Tracy A.
Heath, Sean McCann, Thibaut Brunet, Steven Haddock • Jellywatch.org,
Benjamint444, Walter Vladimir, Ricardo N. Martinez & Oscar A. Alcober,
Stemonitis (photography) and T. Michael Keesey (vectorization),
Alexander Schmidt-Lebuhn, Danny Cicchetti (vectorized by T. Michael
Keesey), SauropodomorphMonarch, Ralf Janssen, Nikola-Michael Prpic & Wim
G. M. Damen (vectorized by T. Michael Keesey), Jaime Headden, modified
by T. Michael Keesey, Cristopher Silva, Lily Hughes

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    605.026587 |     69.005949 | Margot Michaud                                                                                                                                                        |
|   2 |    153.812852 |    634.203100 | Margot Michaud                                                                                                                                                        |
|   3 |    636.659384 |    335.345582 | Steven Traver                                                                                                                                                         |
|   4 |    842.729258 |    617.844609 | Javiera Constanzo                                                                                                                                                     |
|   5 |    666.943150 |    207.093044 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
|   6 |    316.401093 |    395.983004 | Owen Jones                                                                                                                                                            |
|   7 |     82.210699 |    110.975091 | NA                                                                                                                                                                    |
|   8 |    483.092921 |    413.264169 | NA                                                                                                                                                                    |
|   9 |    441.007497 |    715.042824 | Pranav Iyer (grey ideas)                                                                                                                                              |
|  10 |    237.548835 |    724.719849 | Jagged Fang Designs                                                                                                                                                   |
|  11 |    879.531378 |    538.508122 | Erika Schumacher                                                                                                                                                      |
|  12 |    455.254241 |    175.894831 | Matt Crook                                                                                                                                                            |
|  13 |    585.329423 |    554.931192 | T. Michael Keesey                                                                                                                                                     |
|  14 |    297.833653 |    216.916714 | Smokeybjb                                                                                                                                                             |
|  15 |    108.140002 |    445.150709 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
|  16 |    620.838549 |    457.633766 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
|  17 |    863.721061 |     86.134884 | Katie S. Collins                                                                                                                                                      |
|  18 |    971.217092 |    657.136776 | Michelle Site                                                                                                                                                         |
|  19 |    826.361815 |    696.433050 | Alexandre Vong                                                                                                                                                        |
|  20 |    929.789885 |    434.693434 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  21 |    579.611509 |    151.196061 | Jagged Fang Designs                                                                                                                                                   |
|  22 |    603.745608 |    729.251141 | NA                                                                                                                                                                    |
|  23 |    252.197117 |    141.063535 | Ferran Sayol                                                                                                                                                          |
|  24 |    808.957716 |    351.431834 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  25 |     73.961660 |    321.801068 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
|  26 |    769.603066 |    206.144988 | Andy Wilson                                                                                                                                                           |
|  27 |    210.683585 |    297.330034 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
|  28 |    741.502759 |    440.674893 | Abraão Leite                                                                                                                                                          |
|  29 |    420.977323 |    630.933783 | Scott Hartman                                                                                                                                                         |
|  30 |    780.087091 |    778.837573 | Henry Lydecker                                                                                                                                                        |
|  31 |     84.352223 |    222.206885 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  32 |    715.405738 |    608.447412 | Gareth Monger                                                                                                                                                         |
|  33 |    451.357074 |    530.884350 | Margot Michaud                                                                                                                                                        |
|  34 |    882.397844 |    341.838086 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
|  35 |     71.009024 |    401.482427 | Ferran Sayol                                                                                                                                                          |
|  36 |    994.367002 |    221.696412 | Steven Traver                                                                                                                                                         |
|  37 |    947.138779 |    316.306322 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
|  38 |     69.467816 |    652.801046 | Gareth Monger                                                                                                                                                         |
|  39 |    954.893777 |    132.507009 | Mathilde Cordellier                                                                                                                                                   |
|  40 |    897.675835 |    216.796568 | Matt Crook                                                                                                                                                            |
|  41 |    284.768955 |    593.289131 | Margot Michaud                                                                                                                                                        |
|  42 |    156.176875 |    559.860072 | Andy Wilson                                                                                                                                                           |
|  43 |    768.041457 |     53.268217 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
|  44 |    325.590980 |     52.478841 | Kai R. Caspar                                                                                                                                                         |
|  45 |    468.133642 |     60.648429 | Margot Michaud                                                                                                                                                        |
|  46 |    491.567403 |    581.964087 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  47 |    390.672097 |    313.335491 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  48 |    699.472078 |    128.990278 | Jiekun He                                                                                                                                                             |
|  49 |    178.196603 |    185.991253 | Steven Traver                                                                                                                                                         |
|  50 |    960.290370 |     50.170329 | Erika Schumacher                                                                                                                                                      |
|  51 |    218.141934 |    684.741507 | Scott Hartman                                                                                                                                                         |
|  52 |     75.604816 |    774.661345 | Margot Michaud                                                                                                                                                        |
|  53 |     42.191668 |    655.515037 | Maija Karala                                                                                                                                                          |
|  54 |    821.289903 |    489.794903 | NA                                                                                                                                                                    |
|  55 |    373.381077 |    760.817108 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  56 |    201.441262 |     79.686150 | Jagged Fang Designs                                                                                                                                                   |
|  57 |    542.829211 |    631.536202 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  58 |    243.098120 |    452.498089 | FunkMonk                                                                                                                                                              |
|  59 |    760.920464 |    711.045923 | Birgit Lang                                                                                                                                                           |
|  60 |    445.628793 |     27.471574 | Jagged Fang Designs                                                                                                                                                   |
|  61 |    135.669989 |    431.690817 | T. Michael Keesey                                                                                                                                                     |
|  62 |    502.343631 |    295.921698 | Ferran Sayol                                                                                                                                                          |
|  63 |    350.019717 |    263.736139 | Smokeybjb                                                                                                                                                             |
|  64 |     88.899521 |    568.990688 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
|  65 |    727.610351 |    521.348597 | Chris huh                                                                                                                                                             |
|  66 |    842.236846 |    156.337102 | Nobu Tamura                                                                                                                                                           |
|  67 |    371.352291 |    496.572368 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  68 |    339.532774 |    671.513031 | Jaime Headden                                                                                                                                                         |
|  69 |    928.761492 |    732.775797 | Cesar Julian                                                                                                                                                          |
|  70 |    603.567297 |    237.908697 | Frank Förster                                                                                                                                                         |
|  71 |    189.280046 |     32.941772 | Gareth Monger                                                                                                                                                         |
|  72 |     60.780608 |    728.721129 | T. Michael Keesey                                                                                                                                                     |
|  73 |    961.145734 |    779.503152 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
|  74 |    572.806880 |     23.023898 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  75 |    879.749035 |    666.676516 | Scott Reid                                                                                                                                                            |
|  76 |    988.874520 |    371.826999 | Felix Vaux                                                                                                                                                            |
|  77 |    536.376716 |    758.709963 | Matt Crook                                                                                                                                                            |
|  78 |     45.533987 |    168.790598 | Matt Crook                                                                                                                                                            |
|  79 |    530.504457 |    793.796800 | Ignacio Contreras                                                                                                                                                     |
|  80 |    608.790559 |    615.151833 | Kamil S. Jaron                                                                                                                                                        |
|  81 |     13.751453 |    104.196223 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  82 |    111.437346 |    416.627890 | Gareth Monger                                                                                                                                                         |
|  83 |   1002.068172 |    487.179569 | Steven Traver                                                                                                                                                         |
|  84 |    397.055583 |     68.545080 | T. Michael Keesey                                                                                                                                                     |
|  85 |    531.812710 |    666.616412 | Collin Gross                                                                                                                                                          |
|  86 |    721.963232 |    405.008732 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  87 |    660.775819 |    724.706050 | Tyler Greenfield                                                                                                                                                      |
|  88 |    349.478892 |    535.265190 | Matt Crook                                                                                                                                                            |
|  89 |    281.276399 |    165.520325 | Andy Wilson                                                                                                                                                           |
|  90 |    695.104549 |     30.167982 | Zimices                                                                                                                                                               |
|  91 |    380.797338 |    282.384025 | Caleb M. Brown                                                                                                                                                        |
|  92 |    230.827055 |     55.284292 | Chris huh                                                                                                                                                             |
|  93 |    225.564672 |    538.808716 | Chris A. Hamilton                                                                                                                                                     |
|  94 |    279.083116 |    521.681670 | Kanchi Nanjo                                                                                                                                                          |
|  95 |    917.784034 |    336.502847 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  96 |   1007.082588 |    172.424648 | Emily Willoughby                                                                                                                                                      |
|  97 |   1003.701252 |    539.029796 | Martin R. Smith                                                                                                                                                       |
|  98 |    293.915451 |    286.684988 | Margot Michaud                                                                                                                                                        |
|  99 |    828.928311 |    395.399479 | Maija Karala                                                                                                                                                          |
| 100 |    345.851689 |    467.164852 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 101 |    563.454303 |    498.975619 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 102 |    839.868732 |    444.809739 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 103 |    639.775353 |    636.925497 | Gareth Monger                                                                                                                                                         |
| 104 |    204.538484 |    634.972131 | Collin Gross                                                                                                                                                          |
| 105 |    512.000907 |    476.254014 | Emily Willoughby                                                                                                                                                      |
| 106 |    209.892278 |    766.168674 | Dean Schnabel                                                                                                                                                         |
| 107 |    678.733137 |    502.916352 | Matt Crook                                                                                                                                                            |
| 108 |    354.602559 |    645.380659 | NA                                                                                                                                                                    |
| 109 |    616.055268 |    269.861219 | Tasman Dixon                                                                                                                                                          |
| 110 |    358.238695 |    599.730384 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 111 |    814.098356 |    186.354652 | Tyler McCraney                                                                                                                                                        |
| 112 |    223.462583 |    388.366156 | Chris huh                                                                                                                                                             |
| 113 |     22.027624 |     23.115919 | Matt Martyniuk                                                                                                                                                        |
| 114 |    815.194075 |      8.071168 | NA                                                                                                                                                                    |
| 115 |    808.143341 |    594.668707 | T. Michael Keesey                                                                                                                                                     |
| 116 |    165.677474 |    111.048504 | Steven Coombs                                                                                                                                                         |
| 117 |    870.831516 |    766.017045 | C. Camilo Julián-Caballero                                                                                                                                            |
| 118 |    394.285340 |    215.912404 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 119 |    306.350008 |    335.756187 | Martin R. Smith                                                                                                                                                       |
| 120 |     54.815400 |    510.188772 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 121 |    906.051967 |    478.925065 | NA                                                                                                                                                                    |
| 122 |    662.678645 |    237.417545 | Kamil S. Jaron                                                                                                                                                        |
| 123 |    151.702713 |    259.968547 | Katie S. Collins                                                                                                                                                      |
| 124 |    335.525056 |    115.464165 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 125 |    855.531337 |     15.019858 | Andy Wilson                                                                                                                                                           |
| 126 |    185.563961 |    604.686367 | Collin Gross                                                                                                                                                          |
| 127 |    784.663676 |    171.233629 | Jagged Fang Designs                                                                                                                                                   |
| 128 |    959.338899 |    407.326457 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
| 129 |     82.920461 |    263.297608 | Ben Moon                                                                                                                                                              |
| 130 |    611.691612 |    114.611082 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 131 |    507.616534 |    733.711055 | Ignacio Contreras                                                                                                                                                     |
| 132 |    380.342002 |    433.570671 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 133 |     19.888947 |    330.918085 | Ferran Sayol                                                                                                                                                          |
| 134 |    476.912951 |    761.950776 | Zimices                                                                                                                                                               |
| 135 |    864.860437 |    330.608157 | Michelle Site                                                                                                                                                         |
| 136 |     53.987451 |    432.639623 | Matt Crook                                                                                                                                                            |
| 137 |     21.508534 |    542.337678 | Anthony Caravaggi                                                                                                                                                     |
| 138 |    858.324784 |    304.635245 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 139 |     20.157972 |    282.822942 | Markus A. Grohme                                                                                                                                                      |
| 140 |    154.329038 |    728.318752 | L. Shyamal                                                                                                                                                            |
| 141 |    472.668588 |    639.115745 | Smokeybjb                                                                                                                                                             |
| 142 |    769.368509 |    138.889618 | Collin Gross                                                                                                                                                          |
| 143 |     96.720598 |    453.858459 | Maija Karala                                                                                                                                                          |
| 144 |    763.420798 |    547.380978 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 145 |    662.156163 |      9.363789 | T. Michael Keesey                                                                                                                                                     |
| 146 |    950.170516 |    764.963570 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 147 |    476.378645 |    465.250512 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 148 |    412.313776 |    366.958639 | Chase Brownstein                                                                                                                                                      |
| 149 |    789.840241 |    113.353085 | Matthew E. Clapham                                                                                                                                                    |
| 150 |    491.732535 |    718.812282 | NA                                                                                                                                                                    |
| 151 |     91.528881 |    680.438303 | T. Michael Keesey                                                                                                                                                     |
| 152 |    473.514525 |     26.518474 | Gareth Monger                                                                                                                                                         |
| 153 |    930.352228 |    376.881287 | Matt Crook                                                                                                                                                            |
| 154 |    123.239792 |    120.879053 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 155 |    785.718324 |    765.836721 | Zimices                                                                                                                                                               |
| 156 |    406.043474 |    584.858440 | Tasman Dixon                                                                                                                                                          |
| 157 |    672.732205 |    100.327917 | Kamil S. Jaron                                                                                                                                                        |
| 158 |    766.081235 |    275.963480 | Markus A. Grohme                                                                                                                                                      |
| 159 |     19.676613 |    621.654889 | NA                                                                                                                                                                    |
| 160 |     90.771481 |    598.050087 | T. Michael Keesey                                                                                                                                                     |
| 161 |    301.912093 |    649.435691 | Maija Karala                                                                                                                                                          |
| 162 |    499.592759 |    559.883141 | NA                                                                                                                                                                    |
| 163 |    577.527103 |    202.592016 | Andrew A. Farke                                                                                                                                                       |
| 164 |    856.611996 |    582.155361 | Zimices                                                                                                                                                               |
| 165 |    336.069733 |    172.749954 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
| 166 |    928.953297 |    604.101992 | Markus A. Grohme                                                                                                                                                      |
| 167 |    740.206244 |    341.606500 | Jaime Headden                                                                                                                                                         |
| 168 |    497.784153 |     82.769181 | T. Michael Keesey                                                                                                                                                     |
| 169 |    522.979143 |    644.868927 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 170 |    969.447183 |    492.525803 | Matt Crook                                                                                                                                                            |
| 171 |    405.321184 |    473.337306 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 172 |    215.617202 |    346.382675 | Margot Michaud                                                                                                                                                        |
| 173 |    149.283798 |    239.478543 | Tasman Dixon                                                                                                                                                          |
| 174 |    608.395797 |    403.999596 | Andrew A. Farke                                                                                                                                                       |
| 175 |    407.769136 |    124.770077 | Yan Wong                                                                                                                                                              |
| 176 |    637.916589 |    575.513697 | Christoph Schomburg                                                                                                                                                   |
| 177 |    165.876381 |    362.545518 | Jagged Fang Designs                                                                                                                                                   |
| 178 |    402.518405 |    603.499215 | Steven Traver                                                                                                                                                         |
| 179 |    266.526626 |    431.510668 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 180 |    355.050662 |    571.023431 | Zimices                                                                                                                                                               |
| 181 |     46.193336 |    269.094275 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 182 |    331.462993 |     22.283545 | Joanna Wolfe                                                                                                                                                          |
| 183 |    515.590948 |    112.122437 | Matt Crook                                                                                                                                                            |
| 184 |    143.864242 |    668.645156 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 185 |    112.520225 |    144.059453 | NA                                                                                                                                                                    |
| 186 |    732.761418 |    269.469485 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 187 |    665.018546 |    152.440750 | Rebecca Groom                                                                                                                                                         |
| 188 |    299.012387 |    241.694200 | Steven Traver                                                                                                                                                         |
| 189 |    128.323378 |    298.208697 | Sarah Werning                                                                                                                                                         |
| 190 |    441.810007 |    672.056122 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 191 |    659.287491 |    373.534128 | John Conway                                                                                                                                                           |
| 192 |    995.452513 |    744.227057 | Matt Crook                                                                                                                                                            |
| 193 |    415.493237 |    438.546892 | Andy Wilson                                                                                                                                                           |
| 194 |    375.235457 |    237.660900 | Ferran Sayol                                                                                                                                                          |
| 195 |    651.864170 |    402.634617 | Jack Mayer Wood                                                                                                                                                       |
| 196 |    966.408510 |    587.013468 | Markus A. Grohme                                                                                                                                                      |
| 197 |    409.950338 |    743.368155 | Beth Reinke                                                                                                                                                           |
| 198 |     18.834545 |    368.932519 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 199 |     12.564775 |    573.428073 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 200 |    653.948432 |    553.361904 | Steven Traver                                                                                                                                                         |
| 201 |    137.256355 |    604.421494 | NA                                                                                                                                                                    |
| 202 |    662.167503 |    412.261117 | Matt Crook                                                                                                                                                            |
| 203 |    742.381683 |    365.473911 | Steven Traver                                                                                                                                                         |
| 204 |     31.779511 |    107.090496 | T. Michael Keesey                                                                                                                                                     |
| 205 |    546.497870 |    688.706819 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 206 |    110.028679 |    261.584767 | Mathilde Cordellier                                                                                                                                                   |
| 207 |    130.412608 |    743.069323 | Meliponicultor Itaymbere                                                                                                                                              |
| 208 |    286.706011 |    350.652875 | Tasman Dixon                                                                                                                                                          |
| 209 |    883.006236 |    779.971791 | Markus A. Grohme                                                                                                                                                      |
| 210 |    206.776206 |    135.218194 | Maija Karala                                                                                                                                                          |
| 211 |    694.265603 |    268.097195 | Becky Barnes                                                                                                                                                          |
| 212 |    669.544414 |    665.630101 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 213 |    960.676250 |    534.673872 | Steven Traver                                                                                                                                                         |
| 214 |    727.004033 |     78.633093 | Matt Crook                                                                                                                                                            |
| 215 |    757.426582 |     14.727053 | Steven Blackwood                                                                                                                                                      |
| 216 |    809.545428 |    579.018524 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 217 |    896.255449 |    630.533762 | NA                                                                                                                                                                    |
| 218 |    503.645104 |    599.796084 | Gareth Monger                                                                                                                                                         |
| 219 |    123.885670 |    690.865988 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 220 |    653.543177 |    772.863186 | Jagged Fang Designs                                                                                                                                                   |
| 221 |    542.673858 |    461.608853 | Gareth Monger                                                                                                                                                         |
| 222 |    804.123349 |    289.707825 | Christoph Schomburg                                                                                                                                                   |
| 223 |    889.610488 |     29.780462 | Matt Crook                                                                                                                                                            |
| 224 |     23.983180 |    251.257397 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 225 |    841.690585 |    282.449993 | Emily Willoughby                                                                                                                                                      |
| 226 |    277.381016 |    453.111536 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 227 |    629.489949 |    203.777922 | Margot Michaud                                                                                                                                                        |
| 228 |    254.531657 |    653.873046 | Chris huh                                                                                                                                                             |
| 229 |    253.629570 |    611.787891 | Beth Reinke                                                                                                                                                           |
| 230 |    278.265862 |    743.294348 | Birgit Lang                                                                                                                                                           |
| 231 |      6.819688 |    767.628590 | Gareth Monger                                                                                                                                                         |
| 232 |    459.944657 |    657.087095 | Rebecca Groom                                                                                                                                                         |
| 233 |    218.245624 |    498.374184 | Gregor Bucher, Max Farnworth                                                                                                                                          |
| 234 |    662.047833 |    790.080149 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 235 |    861.056048 |    728.619930 | Zimices                                                                                                                                                               |
| 236 |   1011.448630 |    607.281187 | xgirouxb                                                                                                                                                              |
| 237 |    155.949583 |    523.366180 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 238 |    893.363443 |    305.546351 | S.Martini                                                                                                                                                             |
| 239 |     30.794386 |    208.593060 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 240 |    287.036568 |    766.489226 | Margot Michaud                                                                                                                                                        |
| 241 |    118.564849 |    522.914526 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 242 |    462.162549 |    685.253504 | Sarah Alewijnse                                                                                                                                                       |
| 243 |    963.618185 |     18.283426 | Zimices                                                                                                                                                               |
| 244 |    303.176854 |    706.159475 | Xavier Giroux-Bougard                                                                                                                                                 |
| 245 |    365.238082 |     10.251259 | Chris huh                                                                                                                                                             |
| 246 |     18.106449 |     50.828056 | Steven Traver                                                                                                                                                         |
| 247 |    496.670600 |    233.013990 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 248 |    309.205892 |    164.656977 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 249 |    932.794139 |    467.225517 | Rebecca Groom                                                                                                                                                         |
| 250 |    245.100100 |    359.168809 | Tasman Dixon                                                                                                                                                          |
| 251 |    991.633442 |    101.299884 | T. Michael Keesey                                                                                                                                                     |
| 252 |    828.503289 |    251.539468 | NA                                                                                                                                                                    |
| 253 |    694.720784 |    166.602465 | Gareth Monger                                                                                                                                                         |
| 254 |    766.428317 |    288.065343 | NA                                                                                                                                                                    |
| 255 |    118.131747 |    567.626077 | Anthony Caravaggi                                                                                                                                                     |
| 256 |    389.375018 |    791.950900 | Sarah Werning                                                                                                                                                         |
| 257 |    357.362714 |    725.276959 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 258 |    143.772165 |    278.734033 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 259 |    322.336137 |    273.389998 | Margot Michaud                                                                                                                                                        |
| 260 |    763.140908 |    562.788992 | Matt Celeskey                                                                                                                                                         |
| 261 |    433.672717 |    289.300932 | Christoph Schomburg                                                                                                                                                   |
| 262 |    288.098255 |    332.773162 | Margot Michaud                                                                                                                                                        |
| 263 |    793.631949 |    681.728331 | Birgit Lang                                                                                                                                                           |
| 264 |    185.952285 |    585.523264 | Markus A. Grohme                                                                                                                                                      |
| 265 |    325.879796 |    608.169618 | Lukasiniho                                                                                                                                                            |
| 266 |    832.952726 |    212.716387 | Erika Schumacher                                                                                                                                                      |
| 267 |    831.516336 |    471.730141 | Bennet McComish, photo by Avenue                                                                                                                                      |
| 268 |    754.999866 |     80.358400 | T. Michael Keesey                                                                                                                                                     |
| 269 |     93.077002 |    718.288387 | Chris huh                                                                                                                                                             |
| 270 |    500.376192 |    149.551379 | Matt Crook                                                                                                                                                            |
| 271 |     17.985159 |    348.699102 | Dave Angelini                                                                                                                                                         |
| 272 |    265.312178 |    411.171597 | NA                                                                                                                                                                    |
| 273 |    927.532672 |     11.904887 | NA                                                                                                                                                                    |
| 274 |    174.842385 |    656.789298 | Ferran Sayol                                                                                                                                                          |
| 275 |    183.371710 |    531.442207 | Dean Schnabel                                                                                                                                                         |
| 276 |     43.760728 |    111.719337 | T. Michael Keesey                                                                                                                                                     |
| 277 |    997.898955 |    765.092864 | Chris huh                                                                                                                                                             |
| 278 |    293.747470 |    128.373453 | Steven Traver                                                                                                                                                         |
| 279 |    794.738444 |     38.525722 | Jack Mayer Wood                                                                                                                                                       |
| 280 |    765.899382 |    388.500145 | Birgit Lang                                                                                                                                                           |
| 281 |    323.623432 |    330.528520 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 282 |     81.477507 |    514.245559 | Jagged Fang Designs                                                                                                                                                   |
| 283 |    633.851781 |    363.514711 | Matt Martyniuk                                                                                                                                                        |
| 284 |    326.147632 |    351.368913 | T. Michael Keesey                                                                                                                                                     |
| 285 |    187.393631 |    364.780397 | Harold N Eyster                                                                                                                                                       |
| 286 |    637.678036 |    380.278988 | Jagged Fang Designs                                                                                                                                                   |
| 287 |    301.263511 |     15.676586 | Lukasiniho                                                                                                                                                            |
| 288 |    715.660155 |     59.291245 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 289 |    353.926397 |    246.723485 | Joanna Wolfe                                                                                                                                                          |
| 290 |    813.471193 |    316.306124 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 291 |    371.614079 |    175.189524 | Felix Vaux                                                                                                                                                            |
| 292 |    648.713300 |    130.975064 | Collin Gross                                                                                                                                                          |
| 293 |    167.349634 |    135.357131 | Matt Crook                                                                                                                                                            |
| 294 |    802.645702 |     21.739363 | Ignacio Contreras                                                                                                                                                     |
| 295 |    884.079911 |    580.968905 | Ferran Sayol                                                                                                                                                          |
| 296 |    620.881680 |    663.838124 | Mathew Wedel                                                                                                                                                          |
| 297 |    496.113785 |    254.841300 | NA                                                                                                                                                                    |
| 298 |    444.818025 |    612.415535 | Tasman Dixon                                                                                                                                                          |
| 299 |    137.185879 |    338.454670 | Zimices                                                                                                                                                               |
| 300 |    531.378054 |    732.442418 | Jagged Fang Designs                                                                                                                                                   |
| 301 |    816.800276 |    135.030535 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 302 |    841.857391 |     35.351470 | Jagged Fang Designs                                                                                                                                                   |
| 303 |    514.013080 |    687.924480 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 304 |    119.516403 |    242.683546 | NA                                                                                                                                                                    |
| 305 |     88.417954 |    554.436233 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 306 |    858.585359 |    416.912057 | NA                                                                                                                                                                    |
| 307 |    665.953632 |    252.335442 | Scott Hartman                                                                                                                                                         |
| 308 |     64.922108 |    742.895491 | Ignacio Contreras                                                                                                                                                     |
| 309 |    519.070258 |    746.245111 | Jagged Fang Designs                                                                                                                                                   |
| 310 |    163.899167 |    563.065008 | Scott Hartman                                                                                                                                                         |
| 311 |    108.020727 |    477.482554 | Jiekun He                                                                                                                                                             |
| 312 |    906.716220 |    281.010701 | Steven Traver                                                                                                                                                         |
| 313 |    265.856489 |     21.115294 | Zimices                                                                                                                                                               |
| 314 |    230.118769 |    100.176885 | Beth Reinke                                                                                                                                                           |
| 315 |     95.471884 |    651.467021 | Gareth Monger                                                                                                                                                         |
| 316 |    304.753573 |    453.406316 | T. Michael Keesey                                                                                                                                                     |
| 317 |    778.689369 |    637.771238 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 318 |     38.654360 |    315.618269 | Scott Hartman                                                                                                                                                         |
| 319 |    681.321870 |    761.024248 | Margot Michaud                                                                                                                                                        |
| 320 |    532.444590 |    508.023858 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 321 |   1009.978549 |    106.254086 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 322 |    211.359360 |    361.957810 | Chris huh                                                                                                                                                             |
| 323 |    159.852703 |    487.095722 | Mark Miller                                                                                                                                                           |
| 324 |    257.962515 |    239.800010 | Michael Scroggie                                                                                                                                                      |
| 325 |    627.464039 |    591.247357 | Tasman Dixon                                                                                                                                                          |
| 326 |   1004.468592 |    778.614925 | Tony Ayling                                                                                                                                                           |
| 327 |    916.217739 |    789.967079 | S.Martini                                                                                                                                                             |
| 328 |    381.216811 |    461.253125 | Rebecca Groom                                                                                                                                                         |
| 329 |    783.220329 |    157.720296 | Birgit Lang                                                                                                                                                           |
| 330 |    299.464089 |    192.234398 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 331 |    707.354100 |    748.276455 | NA                                                                                                                                                                    |
| 332 |     78.181877 |    465.141017 | Ingo Braasch                                                                                                                                                          |
| 333 |    973.257713 |    517.201691 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 334 |    838.005612 |    227.939740 | Iain Reid                                                                                                                                                             |
| 335 |    293.453924 |    786.886256 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 336 |    162.442047 |      9.672371 | Zimices                                                                                                                                                               |
| 337 |    822.160778 |    780.320754 | Hans Hillewaert                                                                                                                                                       |
| 338 |    300.998034 |     89.419422 | Ferran Sayol                                                                                                                                                          |
| 339 |    453.083482 |    470.523333 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 340 |    576.010884 |    781.258104 | C. Camilo Julián-Caballero                                                                                                                                            |
| 341 |    171.029457 |    618.429049 | Steven Traver                                                                                                                                                         |
| 342 |    958.511239 |    490.548857 | Chris huh                                                                                                                                                             |
| 343 |    808.517724 |     32.413294 | CNZdenek                                                                                                                                                              |
| 344 |    995.938742 |    302.309641 | Jagged Fang Designs                                                                                                                                                   |
| 345 |    678.791440 |     69.573952 | Ingo Braasch                                                                                                                                                          |
| 346 |    447.456172 |    782.228204 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 347 |    248.218237 |      3.760071 | Christoph Schomburg                                                                                                                                                   |
| 348 |    359.013553 |    104.009958 | Tasman Dixon                                                                                                                                                          |
| 349 |    416.090378 |     83.243116 | Tasman Dixon                                                                                                                                                          |
| 350 |     17.602216 |    670.820942 | Andrés Sánchez                                                                                                                                                        |
| 351 |    567.268756 |    113.520522 | Jagged Fang Designs                                                                                                                                                   |
| 352 |    315.546615 |    514.648186 |                                                                                                                                                                       |
| 353 |     42.301595 |    487.462105 | Matt Crook                                                                                                                                                            |
| 354 |    416.903551 |    409.534004 | Jimmy Bernot                                                                                                                                                          |
| 355 |    698.079514 |    716.417675 | Peter Coxhead                                                                                                                                                         |
| 356 |     27.594568 |    748.907874 | Matt Crook                                                                                                                                                            |
| 357 |    741.343548 |    328.793630 | NA                                                                                                                                                                    |
| 358 |    641.848005 |     32.770875 | Steven Traver                                                                                                                                                         |
| 359 |    775.788510 |     20.002129 | Markus A. Grohme                                                                                                                                                      |
| 360 |     24.452978 |    794.020113 | FunkMonk                                                                                                                                                              |
| 361 |    851.393020 |    756.835340 | Jagged Fang Designs                                                                                                                                                   |
| 362 |    158.488725 |    206.145522 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 363 |    576.130361 |    354.352103 | FunkMonk                                                                                                                                                              |
| 364 |    999.965251 |    436.513137 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 365 |   1003.143177 |     77.120263 | Scott Hartman                                                                                                                                                         |
| 366 |     76.679429 |    533.602854 | Markus A. Grohme                                                                                                                                                      |
| 367 |    329.932351 |      8.840040 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 368 |    264.008810 |     52.256250 | Ferran Sayol                                                                                                                                                          |
| 369 |    154.158372 |     89.556082 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 370 |    694.755562 |     88.496775 | Jagged Fang Designs                                                                                                                                                   |
| 371 |     29.976548 |    139.295943 | Tasman Dixon                                                                                                                                                          |
| 372 |     42.626472 |     85.611612 | NA                                                                                                                                                                    |
| 373 |    313.025546 |    759.389595 | Beth Reinke                                                                                                                                                           |
| 374 |    985.226261 |    150.636808 | Andy Wilson                                                                                                                                                           |
| 375 |    850.473981 |    292.079080 | S.Martini                                                                                                                                                             |
| 376 |    986.831460 |    292.055330 | Scott Hartman                                                                                                                                                         |
| 377 |    852.880203 |    665.594583 | T. Michael Keesey                                                                                                                                                     |
| 378 |    721.200037 |    539.324441 | Zimices                                                                                                                                                               |
| 379 |    382.408922 |    393.377618 | Kimberly Haddrell                                                                                                                                                     |
| 380 |    878.693782 |    600.319660 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 381 |    177.530686 |    462.273808 | Zimices                                                                                                                                                               |
| 382 |    109.081889 |    593.637180 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 383 |    142.503708 |    775.825711 | Noah Schlottman                                                                                                                                                       |
| 384 |    665.362205 |    229.068375 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 385 |    478.834809 |    794.940400 | Scott Hartman                                                                                                                                                         |
| 386 |    943.648400 |    461.804440 | Amanda Katzer                                                                                                                                                         |
| 387 |    543.745267 |     48.361944 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 388 |    114.197710 |    181.214293 | Steven Traver                                                                                                                                                         |
| 389 |    629.955361 |    107.939638 | Melissa Ingala                                                                                                                                                        |
| 390 |   1016.141683 |    289.537869 | T. Michael Keesey                                                                                                                                                     |
| 391 |    262.138482 |    551.339615 | Jagged Fang Designs                                                                                                                                                   |
| 392 |    973.774403 |      4.923060 | Tasman Dixon                                                                                                                                                          |
| 393 |    887.875194 |    482.709167 | Ferran Sayol                                                                                                                                                          |
| 394 |    219.654122 |    585.826082 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 395 |    107.450713 |    378.431333 | Michelle Site                                                                                                                                                         |
| 396 |    235.799455 |    153.787112 | Scott Hartman                                                                                                                                                         |
| 397 |    809.046642 |    396.322435 | Andy Wilson                                                                                                                                                           |
| 398 |    871.365515 |    169.478715 | Markus A. Grohme                                                                                                                                                      |
| 399 |    924.365200 |    157.390701 | Scott Hartman                                                                                                                                                         |
| 400 |    325.940877 |    308.898454 | Scott Hartman                                                                                                                                                         |
| 401 |    134.282512 |     27.143428 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 402 |    885.418717 |     51.064818 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 403 |    652.248786 |    213.509429 | Zachary Quigley                                                                                                                                                       |
| 404 |    212.251408 |    565.473094 | Matt Crook                                                                                                                                                            |
| 405 |    470.543171 |    292.179818 | Matt Crook                                                                                                                                                            |
| 406 |    916.000923 |    353.843094 | Margot Michaud                                                                                                                                                        |
| 407 |    251.222264 |    688.929466 | Carlos Cano-Barbacil                                                                                                                                                  |
| 408 |    551.708427 |    596.156858 | Scott Hartman                                                                                                                                                         |
| 409 |    289.282899 |    635.012953 | Christine Axon                                                                                                                                                        |
| 410 |    777.358163 |    503.289091 | Maija Karala                                                                                                                                                          |
| 411 |    668.557128 |    686.666214 | NA                                                                                                                                                                    |
| 412 |    752.799658 |    493.624839 | NA                                                                                                                                                                    |
| 413 |    935.489923 |    406.482876 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 414 |    457.559175 |    357.971949 | Mathew Wedel                                                                                                                                                          |
| 415 |    728.863955 |    247.357223 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 416 |    659.294846 |     19.502004 | Carlos Cano-Barbacil                                                                                                                                                  |
| 417 |     17.124910 |    258.238520 | Emily Willoughby                                                                                                                                                      |
| 418 |    933.996413 |    393.834708 | Ignacio Contreras                                                                                                                                                     |
| 419 |    897.752554 |    709.278015 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 420 |    264.496096 |    420.218840 | Gareth Monger                                                                                                                                                         |
| 421 |   1014.187716 |    436.124566 | Agnello Picorelli                                                                                                                                                     |
| 422 |     20.005520 |    457.114187 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 423 |    151.139457 |    354.018382 | Hans Hillewaert                                                                                                                                                       |
| 424 |     73.420448 |    475.598191 | Anna Willoughby                                                                                                                                                       |
| 425 |   1008.916620 |    714.778160 | Tyler Greenfield                                                                                                                                                      |
| 426 |    672.561301 |     51.669107 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 427 |     28.287009 |    784.252432 | NA                                                                                                                                                                    |
| 428 |    130.296089 |    534.496880 | Jagged Fang Designs                                                                                                                                                   |
| 429 |    245.142552 |    625.430108 | Scott Hartman                                                                                                                                                         |
| 430 |    579.149810 |    789.297184 | Gareth Monger                                                                                                                                                         |
| 431 |    327.633870 |    451.885189 | NA                                                                                                                                                                    |
| 432 |    473.612953 |    147.313225 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 433 |    418.542015 |    227.449016 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 434 |    283.876823 |    303.818965 | Zimices                                                                                                                                                               |
| 435 |    560.558305 |    524.984225 | Ferran Sayol                                                                                                                                                          |
| 436 |    905.502494 |    390.835200 | Tracy A. Heath                                                                                                                                                        |
| 437 |    820.234978 |    291.127304 | Ferran Sayol                                                                                                                                                          |
| 438 |    870.636162 |      6.561688 | Jagged Fang Designs                                                                                                                                                   |
| 439 |    398.521821 |     14.736851 | Beth Reinke                                                                                                                                                           |
| 440 |    154.504716 |    581.726118 | Sean McCann                                                                                                                                                           |
| 441 |    987.786694 |    543.454010 | Kanchi Nanjo                                                                                                                                                          |
| 442 |    196.398657 |    513.161337 | Gareth Monger                                                                                                                                                         |
| 443 |    573.300462 |    271.813979 | Markus A. Grohme                                                                                                                                                      |
| 444 |    590.808712 |    183.571749 | Erika Schumacher                                                                                                                                                      |
| 445 |    737.161459 |    386.686650 | Beth Reinke                                                                                                                                                           |
| 446 |    684.468447 |    474.846557 | Jack Mayer Wood                                                                                                                                                       |
| 447 |    523.908438 |    445.776691 | Zimices                                                                                                                                                               |
| 448 |    818.152817 |    764.535673 | NA                                                                                                                                                                    |
| 449 |    102.788041 |    168.618654 | Sarah Werning                                                                                                                                                         |
| 450 |     71.316491 |    201.445168 | Sarah Werning                                                                                                                                                         |
| 451 |    959.720352 |    752.907234 | Gareth Monger                                                                                                                                                         |
| 452 |     90.183323 |      6.803026 | Chris huh                                                                                                                                                             |
| 453 |    302.202848 |    540.817753 | T. Michael Keesey                                                                                                                                                     |
| 454 |     17.919418 |    522.276502 | Kanchi Nanjo                                                                                                                                                          |
| 455 |    249.623199 |    509.699924 | Sarah Werning                                                                                                                                                         |
| 456 |    679.964642 |    543.497736 | NA                                                                                                                                                                    |
| 457 |    825.515292 |    161.446824 | Thibaut Brunet                                                                                                                                                        |
| 458 |    591.317507 |    604.684055 | Tyler McCraney                                                                                                                                                        |
| 459 |   1006.462362 |    650.553150 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 460 |    380.979561 |    343.264604 | T. Michael Keesey                                                                                                                                                     |
| 461 |    587.056766 |    392.648737 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 462 |    713.347942 |    176.184358 | Benjamint444                                                                                                                                                          |
| 463 |    453.549198 |    280.959579 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 464 |    305.148379 |    695.086354 | Gareth Monger                                                                                                                                                         |
| 465 |    723.071699 |    488.437641 | Margot Michaud                                                                                                                                                        |
| 466 |    990.470254 |    719.592016 | Walter Vladimir                                                                                                                                                       |
| 467 |    433.086951 |    593.252618 | Chris huh                                                                                                                                                             |
| 468 |    304.359217 |    729.099041 | Ferran Sayol                                                                                                                                                          |
| 469 |    760.351542 |    116.487207 | Michael Scroggie                                                                                                                                                      |
| 470 |    458.020962 |    311.483126 | Zimices                                                                                                                                                               |
| 471 |    164.579823 |    692.779046 | Yan Wong                                                                                                                                                              |
| 472 |    635.376330 |    146.062253 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 473 |    110.245371 |    696.944765 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 474 |    350.534005 |    230.296184 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 475 |     15.980625 |    703.933493 | Chris huh                                                                                                                                                             |
| 476 |    911.437776 |    625.690485 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 477 |    423.126683 |    575.162018 | Collin Gross                                                                                                                                                          |
| 478 |    591.365209 |    672.594510 | Jagged Fang Designs                                                                                                                                                   |
| 479 |    111.344610 |    126.827674 | Jagged Fang Designs                                                                                                                                                   |
| 480 |   1001.133719 |    592.644134 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 481 |    232.937793 |    665.267814 | Gareth Monger                                                                                                                                                         |
| 482 |    160.358960 |    448.137811 | Jagged Fang Designs                                                                                                                                                   |
| 483 |    449.580507 |    599.541159 | Chris huh                                                                                                                                                             |
| 484 |    858.501061 |    715.447213 | Carlos Cano-Barbacil                                                                                                                                                  |
| 485 |    854.835759 |    195.888555 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 486 |    405.249585 |    675.752480 | Matt Crook                                                                                                                                                            |
| 487 |    743.807424 |    476.667892 | Scott Hartman                                                                                                                                                         |
| 488 |    769.590755 |    748.166158 | Chris huh                                                                                                                                                             |
| 489 |    339.535776 |    194.041109 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 490 |    544.104440 |    355.679722 | Margot Michaud                                                                                                                                                        |
| 491 |    109.082196 |    283.162906 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 492 |    567.301670 |    177.782940 | Jagged Fang Designs                                                                                                                                                   |
| 493 |    924.105712 |    312.800206 | Gareth Monger                                                                                                                                                         |
| 494 |    868.026758 |    198.639341 | Zimices                                                                                                                                                               |
| 495 |    488.457852 |    653.717656 | SauropodomorphMonarch                                                                                                                                                 |
| 496 |    926.815197 |    139.635887 | Jagged Fang Designs                                                                                                                                                   |
| 497 |    798.126505 |    469.915727 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 498 |    997.577069 |    577.492683 | Scott Hartman                                                                                                                                                         |
| 499 |    209.068060 |    234.150641 | Chris huh                                                                                                                                                             |
| 500 |    209.705697 |    118.360406 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 501 |    411.989795 |      4.961865 | Chris huh                                                                                                                                                             |
| 502 |    965.170200 |    248.400131 | Cristopher Silva                                                                                                                                                      |
| 503 |    972.171580 |    460.619307 | FunkMonk                                                                                                                                                              |
| 504 |    712.502694 |      7.832288 | Markus A. Grohme                                                                                                                                                      |
| 505 |    249.623967 |    702.243857 | Scott Reid                                                                                                                                                            |
| 506 |    581.053103 |    662.667118 | Lily Hughes                                                                                                                                                           |

    #> Your tweet has been posted!
