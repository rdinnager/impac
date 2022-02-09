
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

T. Michael Keesey, Matt Crook, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Gareth Monger, Scott Hartman, Apokryltaros (vectorized by T.
Michael Keesey), Collin Gross, Sarah Werning, Margot Michaud, Steven
Traver, Andrew A. Farke, Sean McCann, Gabriela Palomo-Munoz, Chase
Brownstein, Markus A. Grohme, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Rene Martin,
Pete Buchholz, Yan Wong, Lukasiniho, Tyler Greenfield, Mathew Stewart,
Joanna Wolfe, Lee Harding (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Zimices, Christoph Schomburg, CNZdenek,
Rebecca Groom, Jose Carlos Arenas-Monroy, Ferran Sayol, Falconaumanni
and T. Michael Keesey, Michael Ströck (vectorized by T. Michael Keesey),
Tasman Dixon, Scott Hartman, modified by T. Michael Keesey, Scott Reid,
Emily Willoughby, Jaime Headden, Zachary Quigley, Ignacio Contreras,
Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Jagged
Fang Designs, Smokeybjb, Scott Hartman (modified by T. Michael Keesey),
Servien (vectorized by T. Michael Keesey), FunkMonk, Kai R. Caspar, Jon
Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Nobu
Tamura (vectorized by T. Michael Keesey), Birgit Lang, Conty (vectorized
by T. Michael Keesey), Mathieu Basille, Ingo Braasch, Lafage, Xavier
Giroux-Bougard, Robert Bruce Horsfall, vectorized by Zimices, Katie S.
Collins, Martien Brand (original photo), Renato Santos (vector
silhouette), M Kolmann, Chris huh, C. Camilo Julián-Caballero, Jaime
Headden (vectorized by T. Michael Keesey), Felix Vaux, FJDegrange,
Darren Naish (vectorize by T. Michael Keesey), Iain Reid, T. Michael
Keesey (after Masteraah), Michelle Site, Eduard Solà (vectorized by T.
Michael Keesey), L. Shyamal, Yan Wong from drawing by T. F. Zimmermann,
Shyamal, Chloé Schmidt, Chuanixn Yu, Matt Dempsey, Mathilde Cordellier,
Michele Tobias, Mathieu Pélissié, Maija Karala, Sharon Wegner-Larsen,
Rebecca Groom (Based on Photo by Andreas Trepte), Alexander
Schmidt-Lebuhn, Sergio A. Muñoz-Gómez, Martin R. Smith, Christine Axon,
Anthony Caravaggi, Raven Amos, Hans Hillewaert (vectorized by T. Michael
Keesey), Caleb M. Gordon, T. Michael Keesey (photo by Sean Mack),
Richard Ruggiero, vectorized by Zimices, david maas / dave hone, Lukas
Panzarin, T. Michael Keesey, from a photograph by Thea Boodhoo, Mark
Hofstetter (vectorized by T. Michael Keesey), H. F. O. March (modified
by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Mali’o
Kodis, photograph by P. Funch and R.M. Kristensen, , Dean Schnabel,
Didier Descouens (vectorized by T. Michael Keesey), M Hutchinson,
Alexandre Vong, Ghedoghedo (vectorized by T. Michael Keesey), Melissa
Broussard, Matt Martyniuk, Cesar Julian, Jay Matternes (modified by T.
Michael Keesey), Ekaterina Kopeykina (vectorized by T. Michael Keesey),
Mali’o Kodis, photograph by John Slapcinsky, Michael B. H. (vectorized
by T. Michael Keesey), Christopher Laumer (vectorized by T. Michael
Keesey), Tyler McCraney, FunkMonk (Michael B.H.; vectorized by T.
Michael Keesey), J. J. Harrison (photo) & T. Michael Keesey, Kanchi
Nanjo, T. Michael Keesey (after Walker & al.), Kamil S. Jaron, Agnello
Picorelli, I. Sácek, Sr. (vectorized by T. Michael Keesey), Pranav Iyer
(grey ideas), xgirouxb, Steven Coombs, Carlos Cano-Barbacil, Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Henry Fairfield Osborn,
vectorized by Zimices, Roberto Díaz Sibaja, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Jimmy Bernot,
Benjamint444, Tyler Greenfield and Scott Hartman, Ville Koistinen
(vectorized by T. Michael Keesey), Karla Martinez, Marcos Pérez-Losada,
Jens T. Høeg & Keith A. Crandall, Walter Vladimir, Luc Viatour (source
photo) and Andreas Plank, Terpsichores, Charles R. Knight, vectorized by
Zimices, Tony Ayling (vectorized by T. Michael Keesey), Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), T. Michael Keesey (after Mauricio Antón), Scarlet23 (vectorized
by T. Michael Keesey), Noah Schlottman, photo from Moorea Biocode, DW
Bapst (modified from Bates et al., 2005), DW Bapst, modified from Figure
1 of Belanger (2011, PALAIOS)., Beth Reinke, Matt Martyniuk (vectorized
by T. Michael Keesey), Sibi (vectorized by T. Michael Keesey), Campbell
Fleming, Maxime Dahirel, Armin Reindl, Nobu Tamura, modified by Andrew
A. Farke, Ricardo N. Martinez & Oscar A. Alcober, Nobu Tamura, Noah
Schlottman, photo by Reinhard Jahn, Tracy A. Heath, Kimberly Haddrell,
Dmitry Bogdanov, Jack Mayer Wood, Joseph J. W. Sertich, Mark A. Loewen,
Kanako Bessho-Uehara, Mathew Wedel, Jake Warner, Giant Blue Anteater
(vectorized by T. Michael Keesey), Nobu Tamura, vectorized by Zimices,
Todd Marshall, vectorized by Zimices, Philip Chalmers (vectorized by T.
Michael Keesey), Milton Tan, Michael Scroggie, Gopal Murali, Ieuan
Jones, SecretJellyMan

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                      |
| --: | ------------: | ------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    689.625668 |    236.569803 | T. Michael Keesey                                                                                                                                           |
|   2 |    512.346752 |    659.058252 | Matt Crook                                                                                                                                                  |
|   3 |    206.736356 |    538.441444 | NA                                                                                                                                                          |
|   4 |    362.646313 |    357.262349 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
|   5 |    129.635550 |    145.012033 | Gareth Monger                                                                                                                                               |
|   6 |    510.474238 |    160.015159 | Scott Hartman                                                                                                                                               |
|   7 |    769.537243 |    404.804335 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                              |
|   8 |    398.714228 |    633.947122 | Collin Gross                                                                                                                                                |
|   9 |    642.054115 |    580.352978 | Sarah Werning                                                                                                                                               |
|  10 |    160.142595 |    232.552455 | NA                                                                                                                                                          |
|  11 |    937.537493 |    305.852626 | Margot Michaud                                                                                                                                              |
|  12 |    851.384053 |    648.318628 | Matt Crook                                                                                                                                                  |
|  13 |    987.857618 |    169.322694 | Gareth Monger                                                                                                                                               |
|  14 |    185.440593 |    351.325847 | Steven Traver                                                                                                                                               |
|  15 |    862.750825 |    124.125621 | Gareth Monger                                                                                                                                               |
|  16 |    643.492747 |    303.473141 | Margot Michaud                                                                                                                                              |
|  17 |    785.550596 |     41.678292 | NA                                                                                                                                                          |
|  18 |    930.211032 |    671.693194 | Gareth Monger                                                                                                                                               |
|  19 |     77.107704 |    694.793250 | Andrew A. Farke                                                                                                                                             |
|  20 |    488.425042 |    427.341431 | Collin Gross                                                                                                                                                |
|  21 |    746.562167 |    336.389247 | Sean McCann                                                                                                                                                 |
|  22 |    267.363052 |    118.299809 | Steven Traver                                                                                                                                               |
|  23 |    499.979892 |    312.970013 | Gabriela Palomo-Munoz                                                                                                                                       |
|  24 |    870.355699 |    562.338631 | Gabriela Palomo-Munoz                                                                                                                                       |
|  25 |    208.603871 |    439.188617 | Chase Brownstein                                                                                                                                            |
|  26 |    634.108944 |    182.400163 | Markus A. Grohme                                                                                                                                            |
|  27 |    618.165318 |     79.880994 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
|  28 |    386.265750 |    468.252981 | Rene Martin                                                                                                                                                 |
|  29 |    951.173684 |    446.070815 | Pete Buchholz                                                                                                                                               |
|  30 |    530.193307 |     98.303232 | Yan Wong                                                                                                                                                    |
|  31 |    783.981132 |    483.530528 | Lukasiniho                                                                                                                                                  |
|  32 |    130.317661 |    420.239923 | T. Michael Keesey                                                                                                                                           |
|  33 |    108.822562 |     47.010911 | Andrew A. Farke                                                                                                                                             |
|  34 |    612.851060 |    715.096445 | Tyler Greenfield                                                                                                                                            |
|  35 |    352.138385 |    743.460500 | Mathew Stewart                                                                                                                                              |
|  36 |    748.070597 |    764.635798 | Joanna Wolfe                                                                                                                                                |
|  37 |    933.891219 |    750.470365 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  38 |    207.804023 |    648.715488 | Zimices                                                                                                                                                     |
|  39 |    725.429284 |    674.065398 | Matt Crook                                                                                                                                                  |
|  40 |    754.218499 |    200.430873 | Steven Traver                                                                                                                                               |
|  41 |    879.453287 |    226.223856 | Christoph Schomburg                                                                                                                                         |
|  42 |    960.130509 |     31.103890 | CNZdenek                                                                                                                                                    |
|  43 |    229.451794 |    755.406935 | Rebecca Groom                                                                                                                                               |
|  44 |     60.662403 |    335.868609 | NA                                                                                                                                                          |
|  45 |     94.409112 |    590.452841 | Jose Carlos Arenas-Monroy                                                                                                                                   |
|  46 |    266.303494 |    255.627177 | Ferran Sayol                                                                                                                                                |
|  47 |    572.061663 |    467.353350 | Falconaumanni and T. Michael Keesey                                                                                                                         |
|  48 |    363.000179 |    408.133583 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                            |
|  49 |    397.650000 |    176.874667 | Tasman Dixon                                                                                                                                                |
|  50 |    894.066317 |    373.657544 | Scott Hartman                                                                                                                                               |
|  51 |    400.973229 |     77.560666 | Scott Hartman, modified by T. Michael Keesey                                                                                                                |
|  52 |    857.612666 |     44.421731 | Scott Reid                                                                                                                                                  |
|  53 |    945.921500 |    497.343563 | NA                                                                                                                                                          |
|  54 |     87.859870 |    113.094228 | Markus A. Grohme                                                                                                                                            |
|  55 |    297.571801 |    592.189704 | Emily Willoughby                                                                                                                                            |
|  56 |    503.822047 |    537.421349 | Scott Hartman                                                                                                                                               |
|  57 |    682.946624 |    397.301376 | Jaime Headden                                                                                                                                               |
|  58 |     68.144697 |    757.836763 | Gabriela Palomo-Munoz                                                                                                                                       |
|  59 |    677.673156 |     70.615626 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
|  60 |    501.069944 |    761.241482 | Zachary Quigley                                                                                                                                             |
|  61 |    665.829507 |    485.636944 | Gabriela Palomo-Munoz                                                                                                                                       |
|  62 |    392.020882 |    671.511519 | Margot Michaud                                                                                                                                              |
|  63 |    358.742710 |    295.810696 | Ignacio Contreras                                                                                                                                           |
|  64 |    844.506403 |    737.806673 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                            |
|  65 |    946.945719 |     91.199596 | Jagged Fang Designs                                                                                                                                         |
|  66 |    261.845004 |     39.249909 | Smokeybjb                                                                                                                                                   |
|  67 |    513.529091 |     30.366533 | Scott Hartman (modified by T. Michael Keesey)                                                                                                               |
|  68 |     99.448408 |    168.360442 | Andrew A. Farke                                                                                                                                             |
|  69 |    391.378764 |    544.256734 | Ferran Sayol                                                                                                                                                |
|  70 |    770.751014 |    122.326348 | NA                                                                                                                                                          |
|  71 |     84.925139 |    492.768762 | Servien (vectorized by T. Michael Keesey)                                                                                                                   |
|  72 |    792.223644 |    606.598813 | Sarah Werning                                                                                                                                               |
|  73 |    894.406836 |    418.112399 | Smokeybjb                                                                                                                                                   |
|  74 |    950.928418 |    554.459803 | FunkMonk                                                                                                                                                    |
|  75 |    368.725493 |     24.587975 | Margot Michaud                                                                                                                                              |
|  76 |     53.469865 |    421.304979 | Matt Crook                                                                                                                                                  |
|  77 |    643.610649 |    258.069784 | T. Michael Keesey                                                                                                                                           |
|  78 |    961.410086 |    602.711972 | Matt Crook                                                                                                                                                  |
|  79 |    284.074783 |    418.006250 | Ferran Sayol                                                                                                                                                |
|  80 |    248.763450 |    508.758672 | Kai R. Caspar                                                                                                                                               |
|  81 |    180.599472 |    103.535297 | Matt Crook                                                                                                                                                  |
|  82 |    722.371708 |    451.821537 | Scott Reid                                                                                                                                                  |
|  83 |    816.874229 |    264.781123 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                              |
|  84 |     76.251651 |    787.761791 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  85 |    621.695044 |    788.463024 | Birgit Lang                                                                                                                                                 |
|  86 |    216.392633 |    587.600358 | Christoph Schomburg                                                                                                                                         |
|  87 |    369.527486 |    225.210473 | Steven Traver                                                                                                                                               |
|  88 |    723.922402 |    145.244765 | Conty (vectorized by T. Michael Keesey)                                                                                                                     |
|  89 |    228.520865 |    316.065957 | Mathieu Basille                                                                                                                                             |
|  90 |     45.309639 |    230.745529 | Sarah Werning                                                                                                                                               |
|  91 |    537.442007 |    148.411471 | Ingo Braasch                                                                                                                                                |
|  92 |     85.468707 |    639.414863 | Matt Crook                                                                                                                                                  |
|  93 |    938.449669 |    397.817051 | Lafage                                                                                                                                                      |
|  94 |    765.646772 |    541.981910 | T. Michael Keesey                                                                                                                                           |
|  95 |    541.469189 |    244.006386 | Xavier Giroux-Bougard                                                                                                                                       |
|  96 |    516.117598 |    725.139337 | Margot Michaud                                                                                                                                              |
|  97 |    355.583457 |    131.398244 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                |
|  98 |    864.929937 |    337.083179 | Katie S. Collins                                                                                                                                            |
|  99 |    277.118481 |    363.713098 | Zimices                                                                                                                                                     |
| 100 |    771.507039 |    270.463779 | CNZdenek                                                                                                                                                    |
| 101 |    846.330444 |    463.866525 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                           |
| 102 |    732.945342 |    605.663587 | Jagged Fang Designs                                                                                                                                         |
| 103 |    152.460696 |     90.387289 | M Kolmann                                                                                                                                                   |
| 104 |    374.865751 |    335.754138 | Ferran Sayol                                                                                                                                                |
| 105 |    120.116243 |    722.504854 | Zimices                                                                                                                                                     |
| 106 |    786.376154 |    717.331637 | Chris huh                                                                                                                                                   |
| 107 |    760.873448 |    591.519080 | C. Camilo Julián-Caballero                                                                                                                                  |
| 108 |    616.630903 |    644.612634 | Matt Crook                                                                                                                                                  |
| 109 |    255.352054 |    708.826222 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                             |
| 110 |    996.230745 |    378.848767 | Felix Vaux                                                                                                                                                  |
| 111 |    439.248529 |    777.567611 | Zimices                                                                                                                                                     |
| 112 |    393.847055 |    274.166722 | Jagged Fang Designs                                                                                                                                         |
| 113 |    134.162072 |    761.481469 | FJDegrange                                                                                                                                                  |
| 114 |    290.205907 |    503.901862 | Lukasiniho                                                                                                                                                  |
| 115 |   1004.499890 |    586.824262 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                               |
| 116 |    926.900538 |    222.879153 | NA                                                                                                                                                          |
| 117 |     98.018176 |    525.389212 | Iain Reid                                                                                                                                                   |
| 118 |    546.093949 |    561.030978 | T. Michael Keesey (after Masteraah)                                                                                                                         |
| 119 |    469.137669 |    574.838683 | Michelle Site                                                                                                                                               |
| 120 |    265.382267 |    183.017235 | Emily Willoughby                                                                                                                                            |
| 121 |     61.286036 |     11.233430 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                               |
| 122 |    326.325424 |    321.765944 | Markus A. Grohme                                                                                                                                            |
| 123 |   1007.727872 |    207.743692 | L. Shyamal                                                                                                                                                  |
| 124 |    336.581730 |     54.000241 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                   |
| 125 |     18.358352 |     22.248922 | Ferran Sayol                                                                                                                                                |
| 126 |    665.856570 |    206.264128 | T. Michael Keesey                                                                                                                                           |
| 127 |    981.147053 |    335.084593 | L. Shyamal                                                                                                                                                  |
| 128 |    616.824004 |    160.180501 | NA                                                                                                                                                          |
| 129 |    618.779674 |    362.520913 | Zimices                                                                                                                                                     |
| 130 |    248.846928 |    382.121492 | Gareth Monger                                                                                                                                               |
| 131 |    151.831207 |    744.465108 | Shyamal                                                                                                                                                     |
| 132 |    505.690003 |    608.452836 | Chloé Schmidt                                                                                                                                               |
| 133 |    468.420855 |    620.272162 | Margot Michaud                                                                                                                                              |
| 134 |    801.452060 |    331.406861 | Zimices                                                                                                                                                     |
| 135 |    270.465115 |     24.802607 | Markus A. Grohme                                                                                                                                            |
| 136 |    845.101385 |    766.820538 | Chuanixn Yu                                                                                                                                                 |
| 137 |    458.079788 |    500.939862 | Matt Dempsey                                                                                                                                                |
| 138 |    788.247147 |    151.406279 | Margot Michaud                                                                                                                                              |
| 139 |    262.650819 |    491.244597 | Margot Michaud                                                                                                                                              |
| 140 |     88.338242 |    279.995155 | Rebecca Groom                                                                                                                                               |
| 141 |    421.203496 |     27.442655 | Mathilde Cordellier                                                                                                                                         |
| 142 |    595.699063 |    534.371757 | Ferran Sayol                                                                                                                                                |
| 143 |    633.740109 |    213.472792 | NA                                                                                                                                                          |
| 144 |    188.437928 |    485.945807 | Michele Tobias                                                                                                                                              |
| 145 |    197.258812 |    322.969447 | Jagged Fang Designs                                                                                                                                         |
| 146 |    630.456493 |    624.681076 | T. Michael Keesey                                                                                                                                           |
| 147 |    514.517600 |    473.871637 | Matt Crook                                                                                                                                                  |
| 148 |    145.972734 |    650.718378 | Matt Crook                                                                                                                                                  |
| 149 |     19.929050 |    158.162738 | NA                                                                                                                                                          |
| 150 |    921.163831 |    167.219749 | Margot Michaud                                                                                                                                              |
| 151 |    291.646908 |     12.271071 | Zimices                                                                                                                                                     |
| 152 |    161.964110 |    290.586748 | Steven Traver                                                                                                                                               |
| 153 |    953.646826 |    212.495678 | Mathieu Pélissié                                                                                                                                            |
| 154 |    301.877971 |    532.693080 | Zimices                                                                                                                                                     |
| 155 |    645.686246 |    346.609642 | Maija Karala                                                                                                                                                |
| 156 |    177.205114 |    568.242404 | Steven Traver                                                                                                                                               |
| 157 |     60.864170 |    666.087013 | Matt Crook                                                                                                                                                  |
| 158 |     19.859245 |    663.264752 | Smokeybjb                                                                                                                                                   |
| 159 |    983.228088 |    106.628358 | Felix Vaux                                                                                                                                                  |
| 160 |    107.677014 |    337.009794 | T. Michael Keesey                                                                                                                                           |
| 161 |    634.061774 |    597.989718 | Ferran Sayol                                                                                                                                                |
| 162 |    650.343234 |    376.857138 | Matt Dempsey                                                                                                                                                |
| 163 |    160.655269 |    176.696476 | Chris huh                                                                                                                                                   |
| 164 |    528.371271 |    587.583927 | Zimices                                                                                                                                                     |
| 165 |     48.774973 |    516.684557 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 166 |    943.927733 |    107.374537 | Sharon Wegner-Larsen                                                                                                                                        |
| 167 |    558.652639 |    669.348500 | NA                                                                                                                                                          |
| 168 |    674.707865 |    443.729514 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                            |
| 169 |   1016.450341 |    412.723328 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 170 |    982.536332 |    244.303672 | NA                                                                                                                                                          |
| 171 |    689.717753 |    192.011577 | Tasman Dixon                                                                                                                                                |
| 172 |    816.476136 |    211.061812 | Sergio A. Muñoz-Gómez                                                                                                                                       |
| 173 |    287.229747 |    679.228580 | Margot Michaud                                                                                                                                              |
| 174 |    590.576416 |    223.950837 | Martin R. Smith                                                                                                                                             |
| 175 |    222.720779 |    187.402356 | Jagged Fang Designs                                                                                                                                         |
| 176 |    438.970148 |     51.123676 | Margot Michaud                                                                                                                                              |
| 177 |     25.827250 |    391.819013 | Matt Crook                                                                                                                                                  |
| 178 |    987.224948 |    292.646450 | Andrew A. Farke                                                                                                                                             |
| 179 |    752.541239 |     79.789021 | Christine Axon                                                                                                                                              |
| 180 |    420.548949 |    130.987470 | Birgit Lang                                                                                                                                                 |
| 181 |    687.894542 |     22.574604 | Markus A. Grohme                                                                                                                                            |
| 182 |     58.245501 |     93.411638 | Anthony Caravaggi                                                                                                                                           |
| 183 |    205.445533 |    258.655913 | Ferran Sayol                                                                                                                                                |
| 184 |    946.735237 |     70.322051 | Shyamal                                                                                                                                                     |
| 185 |     85.941691 |    199.996941 | Margot Michaud                                                                                                                                              |
| 186 |    182.605462 |    711.037547 | Gabriela Palomo-Munoz                                                                                                                                       |
| 187 |    497.048836 |     59.612395 | Raven Amos                                                                                                                                                  |
| 188 |    498.311811 |    372.887080 | Emily Willoughby                                                                                                                                            |
| 189 |    585.707817 |    158.153287 | C. Camilo Julián-Caballero                                                                                                                                  |
| 190 |    915.268607 |    528.938599 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                           |
| 191 |    404.244606 |    252.913581 | Caleb M. Gordon                                                                                                                                             |
| 192 |     31.477170 |    251.127163 | Scott Hartman                                                                                                                                               |
| 193 |    707.872219 |      2.307328 | Gareth Monger                                                                                                                                               |
| 194 |    968.581526 |    730.273741 | Zimices                                                                                                                                                     |
| 195 |    998.566579 |    551.364272 | T. Michael Keesey (photo by Sean Mack)                                                                                                                      |
| 196 |    422.177325 |    342.958689 | Emily Willoughby                                                                                                                                            |
| 197 |    719.282216 |    307.058205 | Matt Crook                                                                                                                                                  |
| 198 |    794.700948 |    560.802285 | Sergio A. Muñoz-Gómez                                                                                                                                       |
| 199 |    913.366790 |    708.945563 | NA                                                                                                                                                          |
| 200 |    871.271394 |    785.478918 | Richard Ruggiero, vectorized by Zimices                                                                                                                     |
| 201 |    608.213494 |    513.857149 | Steven Traver                                                                                                                                               |
| 202 |    435.313752 |     83.738437 | david maas / dave hone                                                                                                                                      |
| 203 |   1000.170177 |    739.798674 | T. Michael Keesey                                                                                                                                           |
| 204 |    975.906997 |    789.069017 | T. Michael Keesey                                                                                                                                           |
| 205 |    613.419115 |    233.712881 | Lukas Panzarin                                                                                                                                              |
| 206 |    855.124668 |    691.943604 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                        |
| 207 |    398.093046 |    381.882242 | Lukasiniho                                                                                                                                                  |
| 208 |     91.634982 |    428.170558 | Collin Gross                                                                                                                                                |
| 209 |     42.866783 |    538.918751 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                           |
| 210 |    982.335217 |    534.651817 | Zimices                                                                                                                                                     |
| 211 |    446.409883 |    547.582065 | NA                                                                                                                                                          |
| 212 |    438.809021 |    442.055485 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                        |
| 213 |   1007.162466 |    617.275103 | Gabriela Palomo-Munoz                                                                                                                                       |
| 214 |    659.669346 |    610.231842 | Michele Tobias                                                                                                                                              |
| 215 |    465.033716 |     32.717444 | Matt Crook                                                                                                                                                  |
| 216 |    741.913021 |    279.655168 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                    |
| 217 |    552.340781 |     57.780017 | Matt Crook                                                                                                                                                  |
| 218 |    891.247344 |    513.318833 |                                                                                                                                                             |
| 219 |    837.319089 |    223.015388 | Steven Traver                                                                                                                                               |
| 220 |    131.867002 |    784.292705 | Dean Schnabel                                                                                                                                               |
| 221 |    342.609099 |    560.568782 | Matt Crook                                                                                                                                                  |
| 222 |    820.142490 |     32.404286 | Steven Traver                                                                                                                                               |
| 223 |     42.319985 |    463.836962 | NA                                                                                                                                                          |
| 224 |    594.984190 |    380.607182 | NA                                                                                                                                                          |
| 225 |    877.136451 |    463.644705 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
| 226 |    841.075301 |    155.324237 | Michelle Site                                                                                                                                               |
| 227 |    561.254719 |    781.545222 | M Hutchinson                                                                                                                                                |
| 228 |    826.572452 |    439.207637 | NA                                                                                                                                                          |
| 229 |    349.233242 |    100.683262 | Alexandre Vong                                                                                                                                              |
| 230 |    168.289325 |    539.440682 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 231 |     19.085370 |    674.721646 | Matt Crook                                                                                                                                                  |
| 232 |    678.127022 |    109.187336 | Melissa Broussard                                                                                                                                           |
| 233 |    771.418160 |    737.935837 | Maija Karala                                                                                                                                                |
| 234 |    562.867242 |    734.453041 | Ferran Sayol                                                                                                                                                |
| 235 |    389.858159 |    138.274887 | Steven Traver                                                                                                                                               |
| 236 |    253.495886 |    472.061693 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 237 |    678.157424 |    723.128066 | Matt Martyniuk                                                                                                                                              |
| 238 |    171.116580 |     67.064428 | Cesar Julian                                                                                                                                                |
| 239 |     62.846134 |    554.259372 | Jay Matternes (modified by T. Michael Keesey)                                                                                                               |
| 240 |      9.289805 |    321.766484 | NA                                                                                                                                                          |
| 241 |    167.940107 |    667.152409 | T. Michael Keesey                                                                                                                                           |
| 242 |    112.783429 |    664.452392 | Zimices                                                                                                                                                     |
| 243 |    378.495338 |     45.680901 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                       |
| 244 |    494.526327 |    508.750775 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                 |
| 245 |    242.672407 |    236.088123 | Matt Crook                                                                                                                                                  |
| 246 |    664.598367 |    636.957806 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                             |
| 247 |    821.440769 |     49.225727 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                        |
| 248 |    263.734539 |    213.975922 | Tyler McCraney                                                                                                                                              |
| 249 |    628.056915 |    429.072772 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                    |
| 250 |    976.439545 |    359.206426 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 251 |    515.067636 |    363.923877 | Kai R. Caspar                                                                                                                                               |
| 252 |    945.157680 |    788.488924 | Zimices                                                                                                                                                     |
| 253 |    562.650152 |    217.903008 | Gareth Monger                                                                                                                                               |
| 254 |    114.051476 |    291.426840 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                  |
| 255 |    422.181294 |    322.458837 | Kanchi Nanjo                                                                                                                                                |
| 256 |    132.568111 |    350.945306 | Gareth Monger                                                                                                                                               |
| 257 |    186.146840 |    556.534143 | Ferran Sayol                                                                                                                                                |
| 258 |    198.203500 |    691.956262 | Matt Crook                                                                                                                                                  |
| 259 |    839.298408 |    311.545510 | T. Michael Keesey (after Walker & al.)                                                                                                                      |
| 260 |    813.777267 |    521.574017 | Yan Wong                                                                                                                                                    |
| 261 |    650.449459 |      9.545997 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 262 |     36.893388 |    547.182117 | Jagged Fang Designs                                                                                                                                         |
| 263 |    614.609161 |    342.080107 | Margot Michaud                                                                                                                                              |
| 264 |     30.144801 |     92.040040 | Chris huh                                                                                                                                                   |
| 265 |    682.088730 |    770.564364 | T. Michael Keesey                                                                                                                                           |
| 266 |    932.896951 |    194.408141 | Kamil S. Jaron                                                                                                                                              |
| 267 |    653.896057 |    671.200156 | NA                                                                                                                                                          |
| 268 |    782.651303 |    695.118561 | Matt Crook                                                                                                                                                  |
| 269 |     30.468548 |    791.068079 | Scott Hartman                                                                                                                                               |
| 270 |    136.008791 |     11.060577 | Jagged Fang Designs                                                                                                                                         |
| 271 |    835.904673 |    144.079548 | Margot Michaud                                                                                                                                              |
| 272 |    188.362657 |    303.941921 | Steven Traver                                                                                                                                               |
| 273 |    584.212364 |    344.661266 | Zimices                                                                                                                                                     |
| 274 |   1004.102790 |    782.856621 | Agnello Picorelli                                                                                                                                           |
| 275 |    468.195740 |    605.671544 | Shyamal                                                                                                                                                     |
| 276 |    652.010734 |    459.677219 | NA                                                                                                                                                          |
| 277 |    450.022139 |     93.932731 | Scott Hartman                                                                                                                                               |
| 278 |    585.688997 |    642.355971 | Chris huh                                                                                                                                                   |
| 279 |     23.022723 |    593.618457 | Matt Crook                                                                                                                                                  |
| 280 |    657.467870 |    716.276127 | Collin Gross                                                                                                                                                |
| 281 |    298.223933 |    331.074570 | Jagged Fang Designs                                                                                                                                         |
| 282 |    832.105900 |    283.786789 | Matt Crook                                                                                                                                                  |
| 283 |    457.830584 |    169.365053 | CNZdenek                                                                                                                                                    |
| 284 |    704.257054 |     92.433102 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                             |
| 285 |    212.976559 |     17.248998 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 286 |    142.409085 |     73.009173 | Pranav Iyer (grey ideas)                                                                                                                                    |
| 287 |    787.760845 |    100.382603 | Zimices                                                                                                                                                     |
| 288 |    679.823102 |    648.289321 | Chris huh                                                                                                                                                   |
| 289 |    680.834524 |    153.793435 | xgirouxb                                                                                                                                                    |
| 290 |    766.509774 |    441.275459 | Gareth Monger                                                                                                                                               |
| 291 |    408.087254 |    448.244994 | Zimices                                                                                                                                                     |
| 292 |    150.728202 |    585.929447 | NA                                                                                                                                                          |
| 293 |    650.210824 |    142.534609 | Steven Coombs                                                                                                                                               |
| 294 |    161.759314 |    768.587382 | Sergio A. Muñoz-Gómez                                                                                                                                       |
| 295 |    200.643566 |    219.817846 | Matt Crook                                                                                                                                                  |
| 296 |    319.056600 |    278.658174 | FunkMonk                                                                                                                                                    |
| 297 |    561.607499 |    709.587416 | Zimices                                                                                                                                                     |
| 298 |    927.628097 |    144.105316 | NA                                                                                                                                                          |
| 299 |    646.541920 |    647.977203 | Margot Michaud                                                                                                                                              |
| 300 |    168.106492 |    263.179216 | Rebecca Groom                                                                                                                                               |
| 301 |    816.004599 |    186.620921 | Carlos Cano-Barbacil                                                                                                                                        |
| 302 |     29.554529 |    717.896382 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                    |
| 303 |    879.190500 |    281.367184 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                               |
| 304 |    916.379477 |    617.109684 | Gareth Monger                                                                                                                                               |
| 305 |   1002.475701 |    694.076130 | Matt Crook                                                                                                                                                  |
| 306 |    128.587693 |    181.191803 | Lukasiniho                                                                                                                                                  |
| 307 |    430.762815 |    595.951987 | Jagged Fang Designs                                                                                                                                         |
| 308 |    984.696105 |    412.337048 | Ferran Sayol                                                                                                                                                |
| 309 |    837.522603 |    598.237545 | Roberto Díaz Sibaja                                                                                                                                         |
| 310 |    253.215298 |    607.276266 | Anthony Caravaggi                                                                                                                                           |
| 311 |    217.105340 |    484.997820 | Zimices                                                                                                                                                     |
| 312 |    606.819455 |    437.468033 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 313 |    644.016299 |     25.366479 | Markus A. Grohme                                                                                                                                            |
| 314 |    307.716289 |    762.582261 | T. Michael Keesey                                                                                                                                           |
| 315 |    598.213353 |    140.912597 | Markus A. Grohme                                                                                                                                            |
| 316 |    986.318068 |     59.201755 | Scott Hartman                                                                                                                                               |
| 317 |    273.939668 |    460.269885 | Ingo Braasch                                                                                                                                                |
| 318 |    872.547142 |    151.101638 | Chris huh                                                                                                                                                   |
| 319 |    507.567848 |    571.093667 | Ferran Sayol                                                                                                                                                |
| 320 |    815.992998 |    170.038739 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                    |
| 321 |    845.253371 |    118.348178 | Jagged Fang Designs                                                                                                                                         |
| 322 |    995.558403 |    312.237369 | Gareth Monger                                                                                                                                               |
| 323 |    706.035148 |    270.196825 | Jimmy Bernot                                                                                                                                                |
| 324 |    665.715975 |    326.792298 | Benjamint444                                                                                                                                                |
| 325 |    893.416944 |     17.535043 | Jagged Fang Designs                                                                                                                                         |
| 326 |    281.346732 |    482.979986 | Tyler Greenfield and Scott Hartman                                                                                                                          |
| 327 |    652.948118 |    443.808341 | Tasman Dixon                                                                                                                                                |
| 328 |    707.762863 |    178.919021 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                           |
| 329 |    797.162712 |    527.427258 | Ferran Sayol                                                                                                                                                |
| 330 |    179.117775 |    602.922595 | Jagged Fang Designs                                                                                                                                         |
| 331 |    625.278750 |    415.369779 | Gareth Monger                                                                                                                                               |
| 332 |    868.760172 |    507.417490 | Karla Martinez                                                                                                                                              |
| 333 |    335.497101 |    242.768199 | Chris huh                                                                                                                                                   |
| 334 |    859.096722 |    302.179860 | Ferran Sayol                                                                                                                                                |
| 335 |    191.680760 |    120.578489 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                       |
| 336 |     13.617683 |    364.076029 | NA                                                                                                                                                          |
| 337 |    581.849603 |    258.588370 | Rebecca Groom                                                                                                                                               |
| 338 |     38.118191 |    129.453498 | Walter Vladimir                                                                                                                                             |
| 339 |    185.288566 |    286.139293 | NA                                                                                                                                                          |
| 340 |    446.714626 |    418.962426 | Zimices                                                                                                                                                     |
| 341 |    107.961066 |    401.777100 | L. Shyamal                                                                                                                                                  |
| 342 |    797.060640 |    439.112643 | NA                                                                                                                                                          |
| 343 |    472.333836 |    640.770914 | Michelle Site                                                                                                                                               |
| 344 |    447.382070 |    198.951087 | Matt Crook                                                                                                                                                  |
| 345 |    257.316873 |    192.760101 | Jagged Fang Designs                                                                                                                                         |
| 346 |    939.291941 |    529.671735 | Luc Viatour (source photo) and Andreas Plank                                                                                                                |
| 347 |    826.339715 |    319.737765 | Mathilde Cordellier                                                                                                                                         |
| 348 |    556.735495 |    687.582388 | T. Michael Keesey                                                                                                                                           |
| 349 |    691.253959 |    318.196464 | Terpsichores                                                                                                                                                |
| 350 |    541.360298 |      4.597764 | Scott Reid                                                                                                                                                  |
| 351 |    664.224150 |    362.965750 | Charles R. Knight, vectorized by Zimices                                                                                                                    |
| 352 |    429.799565 |    526.784493 | Steven Traver                                                                                                                                               |
| 353 |    817.209895 |    784.078896 | Ferran Sayol                                                                                                                                                |
| 354 |    501.693801 |    452.351346 | Ferran Sayol                                                                                                                                                |
| 355 |    238.286863 |    404.027243 | Kai R. Caspar                                                                                                                                               |
| 356 |     25.771157 |    623.491720 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                               |
| 357 |    553.922663 |    233.609607 | Tasman Dixon                                                                                                                                                |
| 358 |    132.926965 |    512.506372 | Gareth Monger                                                                                                                                               |
| 359 |    863.204654 |    403.383827 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                      |
| 360 |    678.862771 |    795.762563 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 361 |    174.154251 |    611.301521 | Scott Hartman                                                                                                                                               |
| 362 |    139.276337 |    284.150263 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 363 |    941.089404 |    710.993883 | Chris huh                                                                                                                                                   |
| 364 |    253.649696 |    448.215323 | Margot Michaud                                                                                                                                              |
| 365 |     30.516696 |    198.426035 | Chris huh                                                                                                                                                   |
| 366 |    805.507856 |    646.014681 | T. Michael Keesey (after Mauricio Antón)                                                                                                                    |
| 367 |    603.305166 |    278.787437 | Gabriela Palomo-Munoz                                                                                                                                       |
| 368 |    350.131191 |    445.303556 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                 |
| 369 |     81.622985 |    453.886888 | Matt Crook                                                                                                                                                  |
| 370 |    763.734997 |    380.707785 | Jagged Fang Designs                                                                                                                                         |
| 371 |    283.541160 |    621.427257 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 372 |    143.936778 |    707.244510 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 373 |    537.765589 |    574.962699 | Markus A. Grohme                                                                                                                                            |
| 374 |    312.554952 |    191.557383 | Steven Traver                                                                                                                                               |
| 375 |    373.803016 |    773.988342 | M Kolmann                                                                                                                                                   |
| 376 |    963.947452 |    185.806488 | Matt Crook                                                                                                                                                  |
| 377 |    481.621242 |    395.534421 | Gareth Monger                                                                                                                                               |
| 378 |    213.859092 |     51.659369 | Margot Michaud                                                                                                                                              |
| 379 |    664.224901 |    743.156649 | Margot Michaud                                                                                                                                              |
| 380 |    619.016096 |     51.857141 | Steven Traver                                                                                                                                               |
| 381 |   1004.183965 |    641.188898 | FunkMonk                                                                                                                                                    |
| 382 |   1010.023777 |    277.060918 | Sarah Werning                                                                                                                                               |
| 383 |    605.803810 |     13.839482 | Lafage                                                                                                                                                      |
| 384 |    413.545028 |    771.866340 | T. Michael Keesey                                                                                                                                           |
| 385 |    285.233557 |    311.818255 | Jagged Fang Designs                                                                                                                                         |
| 386 |    873.278959 |    436.832593 | Jagged Fang Designs                                                                                                                                         |
| 387 |     15.245698 |    508.595671 | NA                                                                                                                                                          |
| 388 |     20.143157 |     75.290349 | Scott Hartman                                                                                                                                               |
| 389 |    194.850416 |    277.976777 | M Kolmann                                                                                                                                                   |
| 390 |     17.287518 |    477.100126 | Ferran Sayol                                                                                                                                                |
| 391 |    746.017505 |    371.328101 | Scott Hartman                                                                                                                                               |
| 392 |    281.832014 |    634.808041 | CNZdenek                                                                                                                                                    |
| 393 |    327.846315 |     29.617040 | Zimices                                                                                                                                                     |
| 394 |    524.920635 |    504.473701 | Ferran Sayol                                                                                                                                                |
| 395 |    329.086442 |    530.341792 | Noah Schlottman, photo from Moorea Biocode                                                                                                                  |
| 396 |   1007.986567 |     68.970427 | Chris huh                                                                                                                                                   |
| 397 |    578.660802 |    659.641933 | DW Bapst (modified from Bates et al., 2005)                                                                                                                 |
| 398 |     23.098012 |    537.679507 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                               |
| 399 |    366.706327 |    260.494219 | Beth Reinke                                                                                                                                                 |
| 400 |    833.465362 |    176.940959 | Tyler McCraney                                                                                                                                              |
| 401 |    502.018159 |    134.008809 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                            |
| 402 |    533.498760 |    543.755024 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                  |
| 403 |    734.469095 |    540.964101 | Sarah Werning                                                                                                                                               |
| 404 |    976.800205 |    712.787432 | Matt Martyniuk                                                                                                                                              |
| 405 |    386.748215 |    312.239092 | Sibi (vectorized by T. Michael Keesey)                                                                                                                      |
| 406 |    823.076323 |    363.757847 | Scott Reid                                                                                                                                                  |
| 407 |    909.590392 |    778.935008 | C. Camilo Julián-Caballero                                                                                                                                  |
| 408 |    154.627357 |    682.249109 | Campbell Fleming                                                                                                                                            |
| 409 |    540.764848 |    457.549531 | T. Michael Keesey                                                                                                                                           |
| 410 |    475.160209 |     74.235715 | Pranav Iyer (grey ideas)                                                                                                                                    |
| 411 |    137.040219 |    259.864435 | Gabriela Palomo-Munoz                                                                                                                                       |
| 412 |    335.763801 |    437.900756 | Sarah Werning                                                                                                                                               |
| 413 |    513.761719 |    394.185093 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                           |
| 414 |     40.719716 |    182.822101 | Gabriela Palomo-Munoz                                                                                                                                       |
| 415 |    463.359225 |    786.048319 | Steven Traver                                                                                                                                               |
| 416 |     90.961941 |    247.563671 | NA                                                                                                                                                          |
| 417 |    737.826063 |    498.095876 | Iain Reid                                                                                                                                                   |
| 418 |    469.683656 |    110.865238 | Rebecca Groom                                                                                                                                               |
| 419 |    959.966455 |     33.625192 | Smokeybjb                                                                                                                                                   |
| 420 |    504.510024 |    777.056468 | Gareth Monger                                                                                                                                               |
| 421 |    829.085155 |    467.610533 | Kanchi Nanjo                                                                                                                                                |
| 422 |    998.542476 |    466.518529 | Joanna Wolfe                                                                                                                                                |
| 423 |    659.072604 |    271.397881 | Xavier Giroux-Bougard                                                                                                                                       |
| 424 |    340.412606 |     85.162700 | Chris huh                                                                                                                                                   |
| 425 |    303.295617 |    405.096889 | Kai R. Caspar                                                                                                                                               |
| 426 |    988.378472 |    759.242519 | Maxime Dahirel                                                                                                                                              |
| 427 |    404.570578 |    511.603018 | Zimices                                                                                                                                                     |
| 428 |    222.480869 |    711.841990 | Ferran Sayol                                                                                                                                                |
| 429 |   1004.227784 |    352.028787 | Armin Reindl                                                                                                                                                |
| 430 |    337.517702 |    700.235055 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                    |
| 431 |    625.058532 |    580.221518 | Chris huh                                                                                                                                                   |
| 432 |   1009.330260 |    508.769633 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                           |
| 433 |    394.863138 |      8.562663 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                      |
| 434 |    196.184245 |     28.575134 | Scott Hartman                                                                                                                                               |
| 435 |    946.170353 |    718.991808 | Markus A. Grohme                                                                                                                                            |
| 436 |    834.400448 |    613.793893 | Scott Hartman                                                                                                                                               |
| 437 |     68.369500 |    532.423893 | Nobu Tamura                                                                                                                                                 |
| 438 |    924.894464 |    125.917327 | Jimmy Bernot                                                                                                                                                |
| 439 |    737.644656 |    518.947393 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                     |
| 440 |     99.281612 |    458.394380 | Jagged Fang Designs                                                                                                                                         |
| 441 |     36.619662 |    653.382242 | Scott Hartman                                                                                                                                               |
| 442 |    556.596402 |     28.561311 | NA                                                                                                                                                          |
| 443 |    194.920092 |    394.215960 | Matt Crook                                                                                                                                                  |
| 444 |    246.015831 |     17.686936 | Matt Crook                                                                                                                                                  |
| 445 |    579.907426 |    135.550488 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 446 |    872.647416 |    708.965783 | Tracy A. Heath                                                                                                                                              |
| 447 |    162.882852 |    379.043826 | Kimberly Haddrell                                                                                                                                           |
| 448 |    496.048353 |    791.449955 | Dmitry Bogdanov                                                                                                                                             |
| 449 |    729.214860 |     10.568349 | Jack Mayer Wood                                                                                                                                             |
| 450 |    597.778395 |    417.349658 | Jagged Fang Designs                                                                                                                                         |
| 451 |    592.521589 |    402.617240 | NA                                                                                                                                                          |
| 452 |   1009.087899 |    371.788086 | Kai R. Caspar                                                                                                                                               |
| 453 |    417.514786 |     55.855900 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                        |
| 454 |    111.428523 |     84.948452 | Jaime Headden                                                                                                                                               |
| 455 |    244.620572 |    780.486573 | Kanako Bessho-Uehara                                                                                                                                        |
| 456 |    315.530826 |    498.907563 | Mathew Wedel                                                                                                                                                |
| 457 |    315.145135 |    424.175239 | CNZdenek                                                                                                                                                    |
| 458 |    410.161609 |    210.032040 | Tasman Dixon                                                                                                                                                |
| 459 |    989.049322 |    683.126117 | Beth Reinke                                                                                                                                                 |
| 460 |    561.985924 |    260.746759 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 461 |    418.309972 |     80.165856 | Jake Warner                                                                                                                                                 |
| 462 |    483.108512 |    244.121497 | Gareth Monger                                                                                                                                               |
| 463 |    716.287635 |     23.006982 | Tasman Dixon                                                                                                                                                |
| 464 |    704.546707 |     79.161340 | Tasman Dixon                                                                                                                                                |
| 465 |    815.695749 |    577.127869 | NA                                                                                                                                                          |
| 466 |    140.412038 |    325.263704 | Zimices                                                                                                                                                     |
| 467 |    207.640943 |    550.394387 | Scott Hartman                                                                                                                                               |
| 468 |    956.138950 |    377.422593 | Matt Dempsey                                                                                                                                                |
| 469 |    772.873010 |    580.934511 | Joanna Wolfe                                                                                                                                                |
| 470 |    959.503444 |    236.549243 | Scott Reid                                                                                                                                                  |
| 471 |    410.478993 |    581.956006 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                       |
| 472 |     60.786172 |    270.633774 | Ingo Braasch                                                                                                                                                |
| 473 |    347.503018 |    384.813446 | Chris huh                                                                                                                                                   |
| 474 |    685.218484 |    787.763605 | Markus A. Grohme                                                                                                                                            |
| 475 |    976.225494 |     76.089332 | Steven Traver                                                                                                                                               |
| 476 |    711.866017 |    536.515226 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 477 |    788.818754 |    646.273766 | Birgit Lang                                                                                                                                                 |
| 478 |    597.475039 |    245.345070 | Margot Michaud                                                                                                                                              |
| 479 |    324.355876 |    493.327470 | NA                                                                                                                                                          |
| 480 |    159.533246 |      7.577666 | Tyler Greenfield                                                                                                                                            |
| 481 |   1002.352161 |    332.992036 | Gareth Monger                                                                                                                                               |
| 482 |     38.176163 |    730.255144 | Chris huh                                                                                                                                                   |
| 483 |    615.349721 |    197.071889 | Tasman Dixon                                                                                                                                                |
| 484 |    626.472086 |    794.286092 | Ingo Braasch                                                                                                                                                |
| 485 |    321.211437 |    261.214149 | Matt Crook                                                                                                                                                  |
| 486 |    914.818721 |     50.258554 | Gareth Monger                                                                                                                                               |
| 487 |     85.707162 |     93.024172 | Gareth Monger                                                                                                                                               |
| 488 |    149.112192 |     20.679812 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 489 |    557.967017 |    177.303213 | Chuanixn Yu                                                                                                                                                 |
| 490 |    637.934829 |    537.950314 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 491 |    622.419064 |    265.516696 | T. Michael Keesey                                                                                                                                           |
| 492 |    680.587432 |    169.617810 | Scott Hartman                                                                                                                                               |
| 493 |     17.657278 |    279.546081 | Todd Marshall, vectorized by Zimices                                                                                                                        |
| 494 |    693.198010 |    417.271428 | Markus A. Grohme                                                                                                                                            |
| 495 |    705.796959 |    618.626346 | Ferran Sayol                                                                                                                                                |
| 496 |    297.397452 |    655.453202 | Gareth Monger                                                                                                                                               |
| 497 |    823.349655 |    638.749725 | M Kolmann                                                                                                                                                   |
| 498 |    179.130898 |    240.554034 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                           |
| 499 |     12.976073 |    409.386878 | NA                                                                                                                                                          |
| 500 |    198.279792 |    180.880427 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 501 |    839.121119 |     76.046666 | Scott Hartman                                                                                                                                               |
| 502 |    783.310703 |     11.338876 | Christoph Schomburg                                                                                                                                         |
| 503 |   1006.003053 |    699.023891 | Matt Crook                                                                                                                                                  |
| 504 |    925.382735 |    240.784242 | Margot Michaud                                                                                                                                              |
| 505 |    883.616003 |    301.228300 | Milton Tan                                                                                                                                                  |
| 506 |    655.089938 |    194.468219 | Scott Hartman                                                                                                                                               |
| 507 |    494.078287 |    493.175521 | Jagged Fang Designs                                                                                                                                         |
| 508 |    879.664624 |    396.207904 | Scott Hartman                                                                                                                                               |
| 509 |    508.070063 |    351.811165 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 510 |    176.797095 |    203.453663 | Markus A. Grohme                                                                                                                                            |
| 511 |    683.034414 |    655.530249 | Ignacio Contreras                                                                                                                                           |
| 512 |    667.135394 |    777.428611 | Michael Scroggie                                                                                                                                            |
| 513 |    488.608998 |    261.329467 | Scott Hartman                                                                                                                                               |
| 514 |    204.127652 |    149.157769 | Gopal Murali                                                                                                                                                |
| 515 |     16.903186 |    300.821842 | Scott Hartman                                                                                                                                               |
| 516 |    134.543493 |     82.886145 | Scott Hartman                                                                                                                                               |
| 517 |    663.394293 |    516.815392 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 518 |    315.391357 |    551.180180 | Margot Michaud                                                                                                                                              |
| 519 |    189.380837 |    194.111292 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 520 |    653.755970 |    761.685331 | Ieuan Jones                                                                                                                                                 |
| 521 |    936.931585 |     60.352206 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 522 |    477.593846 |    444.607368 | Xavier Giroux-Bougard                                                                                                                                       |
| 523 |   1008.218934 |    484.998379 | Gareth Monger                                                                                                                                               |
| 524 |    604.315680 |    335.882863 | Christoph Schomburg                                                                                                                                         |
| 525 |      9.060745 |    196.423606 | SecretJellyMan                                                                                                                                              |
| 526 |    180.373145 |    790.501811 | Scott Hartman                                                                                                                                               |
| 527 |    919.191834 |    379.083454 | Jimmy Bernot                                                                                                                                                |
| 528 |    722.148969 |    271.042056 | T. Michael Keesey                                                                                                                                           |

    #> Your tweet has been posted!
