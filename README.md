
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

Zimices, Scott Hartman, Kamil S. Jaron, Steven Traver, Chris huh, Sharon
Wegner-Larsen, Caleb M. Brown, Jaime Headden, modified by T. Michael
Keesey, Darren Naish (vectorize by T. Michael Keesey), Stanton F. Fink
(vectorized by T. Michael Keesey), Birgit Lang, Collin Gross, Matt
Crook, Gabriela Palomo-Munoz, Dave Angelini, Iain Reid, Margot Michaud,
Chloé Schmidt, Mike Hanson, Nobu Tamura, vectorized by Zimices, Becky
Barnes, Tomas Willems (vectorized by T. Michael Keesey), T. Michael
Keesey, Smokeybjb, Noah Schlottman, photo from Casey Dunn, Andrew A.
Farke, Maxwell Lefroy (vectorized by T. Michael Keesey), Andrew R.
Gehrke, Conty (vectorized by T. Michael Keesey), Ferran Sayol, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Kristina Gagalova, Christine
Axon, Mason McNair, Mathieu Basille, Gopal Murali, Robert Bruce
Horsfall, vectorized by Zimices, Roberto Díaz Sibaja, Mali’o Kodis,
photograph by G. Giribet, Steven Haddock • Jellywatch.org, Hugo Gruson,
Beth Reinke, Andy Wilson, Keith Murdock (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, T. Michael Keesey (after
James & al.), M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and
Ulf Jondelius (vectorized by T. Michael Keesey), T. Tischler, Michael
Scroggie, Smokeybjb, vectorized by Zimices, Jagged Fang Designs, Gregor
Bucher, Max Farnworth, Scott Hartman (modified by T. Michael Keesey),
www.studiospectre.com, C. Camilo Julián-Caballero, Tarique Sani (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Yan
Wong, Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, \[unknown\], Diego Fontaneto, Elisabeth
A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Cristopher Silva, Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by
Iñaki Ruiz-Trillo), TaraTaylorDesign, Saguaro Pictures (source photo)
and T. Michael Keesey, Crystal Maier, Ghedoghedo (vectorized by T.
Michael Keesey), Oliver Griffith, Sarah Werning, Alexandre Vong, Carlos
Cano-Barbacil, Dean Schnabel, Ignacio Contreras, Mark Miller, Yan Wong
from drawing in The Century Dictionary (1911), Steve Hillebrand/U. S.
Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Erika Schumacher, Zachary Quigley, Lauren Anderson,
Robert Gay, Rebecca Groom, T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Gareth Monger, Jack
Mayer Wood, Lafage, Jessica Anne Miller, Ingo Braasch, Liftarn, Andreas
Trepte (vectorized by T. Michael Keesey), Nobu Tamura (vectorized by T.
Michael Keesey), Alexander Schmidt-Lebuhn, Matt Martyniuk, Markus A.
Grohme, Matt Dempsey, David Tana, Jaime A. Headden (vectorized by T.
Michael Keesey), AnAgnosticGod (vectorized by T. Michael Keesey), Bruno
Maggia, Tyler Greenfield, Martin Kevil, Scott Reid, Xavier
Giroux-Bougard, Mathilde Cordellier, (after Spotila 2004), Matthew E.
Clapham, Ville Koistinen (vectorized by T. Michael Keesey), Katie S.
Collins, Oscar Sanisidro, Robbie N. Cada (vectorized by T. Michael
Keesey), Fernando Carezzano, Ellen Edmonson (illustration) and Timothy
J. Bartley (silhouette), Tony Ayling (vectorized by T. Michael Keesey),
Harold N Eyster, Lindberg (vectorized by T. Michael Keesey), Owen Jones
(derived from a CC-BY 2.0 photograph by Paulo B. Chaves),
SecretJellyMan, Jaime Headden, Sergio A. Muñoz-Gómez, Juan Carlos Jerí,
Michael P. Taylor, H. F. O. March (vectorized by T. Michael Keesey),
Meliponicultor Itaymbere, Alex Slavenko, Chuanixn Yu, Maky
(vectorization), Gabriella Skollar (photography), Rebecca Lewis
(editing), Ieuan Jones, Kosta Mumcuoglu (vectorized by T. Michael
Keesey), Michelle Site, Michele M Tobias, Felix Vaux, Julia B McHugh, T.
Michael Keesey (after MPF), Isaure Scavezzoni, Mo Hassan, Emily
Willoughby, Tasman Dixon, Mathieu Pélissié, Terpsichores, FunkMonk,
CNZdenek, Jose Carlos Arenas-Monroy, Nancy Wyman (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Smokeybjb
(modified by Mike Keesey), Darren Naish (vectorized by T. Michael
Keesey), Melissa Broussard, David Sim (photograph) and T. Michael Keesey
(vectorization), Nobu Tamura, Matt Celeskey, Lukasiniho, Sam Droege
(photography) and T. Michael Keesey (vectorization), T. Michael Keesey
(vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), Jessica Rick, Maija Karala, Lauren
Sumner-Rooney, Hans Hillewaert (vectorized by T. Michael Keesey),
Jakovche, Francisco Gascó (modified by Michael P. Taylor), Manabu
Bessho-Uehara, Danny Cicchetti (vectorized by T. Michael Keesey), Lukas
Panzarin, Jesús Gómez, vectorized by Zimices, Noah Schlottman, photo by
Casey Dunn, Sean McCann, xgirouxb, Cesar Julian, Steven Coombs, Riccardo
Percudani, Lip Kee Yap (vectorized by T. Michael Keesey), M Kolmann,
James R. Spotila and Ray Chatterji, JJ Harrison (vectorized by T.
Michael Keesey), Christoph Schomburg, Pranav Iyer (grey ideas),
Plukenet, Chris A. Hamilton, Kai R. Caspar, Daniel Jaron, Caleb M.
Gordon, Jake Warner, Mette Aumala, Tauana J. Cunha, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Tony Ayling, NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), Robert Gay, modified from FunkMonk (Michael
B.H.) and T. Michael Keesey., Shyamal, T. Michael Keesey (after A. Y.
Ivantsov), Robert Bruce Horsfall (vectorized by T. Michael Keesey),
Mathew Wedel, Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Henry Lydecker, Stuart Humphries, Johan Lindgren,
Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Nicholas J. Czaplewski, vectorized by Zimices, Didier
Descouens (vectorized by T. Michael Keesey), Kailah Thorn & Mark
Hutchinson, Andrés Sánchez, James I. Kirkland, Luis Alcalá, Mark A.
Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized
by T. Michael Keesey), Mihai Dragos (vectorized by T. Michael Keesey),
Caleb Brown, Caio Bernardes, vectorized by Zimices, Julio Garza, Tracy
A. Heath, Eduard Solà (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     162.15865 |    647.491536 | Zimices                                                                                                                                                                              |
|   2 |     385.02376 |    337.560731 | Scott Hartman                                                                                                                                                                        |
|   3 |     626.09395 |    533.327849 | NA                                                                                                                                                                                   |
|   4 |     662.97066 |    212.340011 | Scott Hartman                                                                                                                                                                        |
|   5 |     409.55021 |    636.702321 | Kamil S. Jaron                                                                                                                                                                       |
|   6 |     867.49943 |    560.608478 | Steven Traver                                                                                                                                                                        |
|   7 |     794.84208 |    763.980797 | Chris huh                                                                                                                                                                            |
|   8 |     230.96404 |    737.525462 | NA                                                                                                                                                                                   |
|   9 |     538.62667 |    761.536215 | Chris huh                                                                                                                                                                            |
|  10 |     210.17842 |    386.095687 | Sharon Wegner-Larsen                                                                                                                                                                 |
|  11 |     801.44022 |    280.772377 | Caleb M. Brown                                                                                                                                                                       |
|  12 |     409.79299 |    394.977524 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
|  13 |     539.57981 |    232.048740 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
|  14 |     201.60661 |    296.780992 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
|  15 |     205.32896 |    503.396100 | Birgit Lang                                                                                                                                                                          |
|  16 |     192.85625 |     47.309089 | Collin Gross                                                                                                                                                                         |
|  17 |     455.54258 |    444.708491 | NA                                                                                                                                                                                   |
|  18 |     611.52959 |    310.858024 | Matt Crook                                                                                                                                                                           |
|  19 |     364.36190 |     36.928895 | NA                                                                                                                                                                                   |
|  20 |     393.61027 |    204.209981 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  21 |     563.85828 |    143.374331 | Dave Angelini                                                                                                                                                                        |
|  22 |     831.51009 |    221.889354 | Zimices                                                                                                                                                                              |
|  23 |     496.60982 |    615.176662 | Iain Reid                                                                                                                                                                            |
|  24 |     105.20530 |    574.932226 | Margot Michaud                                                                                                                                                                       |
|  25 |     875.63621 |    102.433230 | Chloé Schmidt                                                                                                                                                                        |
|  26 |     814.18579 |    322.999054 | Mike Hanson                                                                                                                                                                          |
|  27 |     887.23087 |    367.482717 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  28 |     916.18392 |    444.355825 | Becky Barnes                                                                                                                                                                         |
|  29 |     505.29145 |    341.433895 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                                      |
|  30 |     710.55525 |     89.666757 | T. Michael Keesey                                                                                                                                                                    |
|  31 |     112.67247 |    142.760255 | Smokeybjb                                                                                                                                                                            |
|  32 |     815.91359 |    643.993711 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
|  33 |     454.70884 |    291.886826 | Andrew A. Farke                                                                                                                                                                      |
|  34 |     575.63978 |     35.790332 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                     |
|  35 |     978.08293 |    714.025480 | Andrew R. Gehrke                                                                                                                                                                     |
|  36 |     732.09145 |    406.913808 | Zimices                                                                                                                                                                              |
|  37 |     272.49363 |    125.506793 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
|  38 |     296.15308 |    608.212146 | Ferran Sayol                                                                                                                                                                         |
|  39 |     389.60203 |    123.458438 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  40 |      63.57881 |     76.633373 | Andrew A. Farke                                                                                                                                                                      |
|  41 |      55.39527 |    325.448060 | Kristina Gagalova                                                                                                                                                                    |
|  42 |     709.80462 |    531.514148 | Christine Axon                                                                                                                                                                       |
|  43 |     341.08361 |    463.357802 | Mason McNair                                                                                                                                                                         |
|  44 |      81.46252 |    201.418478 | Mathieu Basille                                                                                                                                                                      |
|  45 |     358.41862 |    767.211678 | Zimices                                                                                                                                                                              |
|  46 |      58.84482 |    472.112590 | Gopal Murali                                                                                                                                                                         |
|  47 |     849.52061 |    695.843883 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
|  48 |     675.01101 |    741.511675 | Collin Gross                                                                                                                                                                         |
|  49 |     940.49710 |     27.659556 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  50 |     829.12742 |    458.885191 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
|  51 |     590.08632 |    442.923886 | Margot Michaud                                                                                                                                                                       |
|  52 |     932.19665 |    223.056394 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  53 |     647.44092 |    650.501272 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
|  54 |     949.72818 |    691.011966 | Hugo Gruson                                                                                                                                                                          |
|  55 |     311.85492 |    236.820466 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  56 |     377.15212 |    156.885578 | Margot Michaud                                                                                                                                                                       |
|  57 |     229.73015 |    193.928399 | Zimices                                                                                                                                                                              |
|  58 |     490.84605 |    679.714243 | Beth Reinke                                                                                                                                                                          |
|  59 |     881.48744 |      8.080646 | NA                                                                                                                                                                                   |
|  60 |     995.43881 |    449.177746 | NA                                                                                                                                                                                   |
|  61 |     122.68542 |    272.278533 | Andy Wilson                                                                                                                                                                          |
|  62 |     935.76008 |    757.082467 | Scott Hartman                                                                                                                                                                        |
|  63 |      52.12426 |    721.011182 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
|  64 |     165.26614 |     72.976479 | T. Michael Keesey (after James & al.)                                                                                                                                                |
|  65 |     691.94327 |    568.527290 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  66 |     529.73131 |    447.476421 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
|  67 |     590.50957 |     96.285603 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                             |
|  68 |     439.47610 |     73.170945 | Ferran Sayol                                                                                                                                                                         |
|  69 |     765.91197 |     45.838653 | T. Michael Keesey (after James & al.)                                                                                                                                                |
|  70 |     436.04253 |    244.618627 | T. Tischler                                                                                                                                                                          |
|  71 |     127.88327 |    417.404251 | Michael Scroggie                                                                                                                                                                     |
|  72 |     733.90020 |    174.765008 | Margot Michaud                                                                                                                                                                       |
|  73 |     702.83227 |    473.227096 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
|  74 |     102.17194 |     26.406815 | Jagged Fang Designs                                                                                                                                                                  |
|  75 |     301.71947 |    349.099106 | Gregor Bucher, Max Farnworth                                                                                                                                                         |
|  76 |     968.21207 |    365.527188 | T. Michael Keesey                                                                                                                                                                    |
|  77 |     496.89114 |    543.366217 | Jagged Fang Designs                                                                                                                                                                  |
|  78 |     287.69316 |     81.561475 | Chris huh                                                                                                                                                                            |
|  79 |     303.86914 |    535.694671 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                        |
|  80 |     345.16306 |    265.816965 | NA                                                                                                                                                                                   |
|  81 |     369.39002 |    423.201925 | Margot Michaud                                                                                                                                                                       |
|  82 |     487.77503 |    118.361463 | www.studiospectre.com                                                                                                                                                                |
|  83 |     901.05007 |    286.725195 | NA                                                                                                                                                                                   |
|  84 |     729.44893 |     12.444568 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  85 |     147.25334 |    464.076756 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
|  86 |     974.37985 |    293.432302 | Yan Wong                                                                                                                                                                             |
|  87 |     978.83988 |    147.872517 | Ferran Sayol                                                                                                                                                                         |
|  88 |     260.08308 |    151.727219 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
|  89 |     960.27341 |    536.661747 | \[unknown\]                                                                                                                                                                          |
|  90 |     377.70633 |    301.541724 | Chris huh                                                                                                                                                                            |
|  91 |     158.43622 |    121.570007 | Gopal Murali                                                                                                                                                                         |
|  92 |      22.35565 |    615.413097 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
|  93 |     137.06054 |    772.607829 | Steven Traver                                                                                                                                                                        |
|  94 |     503.45795 |    733.156748 | T. Michael Keesey                                                                                                                                                                    |
|  95 |     573.40681 |    644.542273 | Margot Michaud                                                                                                                                                                       |
|  96 |     535.29581 |    567.119817 | Cristopher Silva                                                                                                                                                                     |
|  97 |     469.06380 |    582.321170 | Scott Hartman                                                                                                                                                                        |
|  98 |     134.53075 |    377.522449 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                                              |
|  99 |     217.76500 |    579.450114 | TaraTaylorDesign                                                                                                                                                                     |
| 100 |     946.53375 |    478.660037 | Zimices                                                                                                                                                                              |
| 101 |     161.66950 |    580.481846 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                                |
| 102 |     689.13336 |    287.225053 | Crystal Maier                                                                                                                                                                        |
| 103 |     249.12446 |    765.964853 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 104 |     899.06046 |    772.215385 | Oliver Griffith                                                                                                                                                                      |
| 105 |     386.10190 |     74.462682 | Sarah Werning                                                                                                                                                                        |
| 106 |     505.67641 |     84.551508 | Alexandre Vong                                                                                                                                                                       |
| 107 |     903.74983 |    655.291093 | NA                                                                                                                                                                                   |
| 108 |      99.71465 |    675.065657 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 109 |     338.87156 |    365.814334 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 110 |     904.19547 |    496.467521 | Zimices                                                                                                                                                                              |
| 111 |     867.62161 |    421.991223 | Dean Schnabel                                                                                                                                                                        |
| 112 |     724.90747 |    296.272703 | Ignacio Contreras                                                                                                                                                                    |
| 113 |     456.10830 |    191.219390 | Mark Miller                                                                                                                                                                          |
| 114 |     963.18990 |     65.343052 | Zimices                                                                                                                                                                              |
| 115 |      29.32876 |    241.977487 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                               |
| 116 |     696.98421 |    600.742781 | Matt Crook                                                                                                                                                                           |
| 117 |     317.15215 |    174.320091 | T. Michael Keesey                                                                                                                                                                    |
| 118 |     585.43951 |    269.866908 | Ferran Sayol                                                                                                                                                                         |
| 119 |      22.49898 |    261.608501 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 120 |     187.34801 |    360.046056 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                   |
| 121 |     720.79935 |    354.974255 | Erika Schumacher                                                                                                                                                                     |
| 122 |     590.29599 |    309.503425 | Zachary Quigley                                                                                                                                                                      |
| 123 |     912.28418 |    144.083135 | Lauren Anderson                                                                                                                                                                      |
| 124 |     159.11038 |     98.264361 | Robert Gay                                                                                                                                                                           |
| 125 |     266.92843 |    404.786041 | Rebecca Groom                                                                                                                                                                        |
| 126 |      68.30977 |    643.972662 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                                    |
| 127 |     534.13135 |    541.750216 | Gareth Monger                                                                                                                                                                        |
| 128 |     255.80612 |    467.534535 | Ignacio Contreras                                                                                                                                                                    |
| 129 |     329.18434 |    677.789890 | Andy Wilson                                                                                                                                                                          |
| 130 |    1000.17483 |    778.655940 | Jack Mayer Wood                                                                                                                                                                      |
| 131 |     177.05861 |    536.962930 | Collin Gross                                                                                                                                                                         |
| 132 |     636.73132 |    515.328160 | Gareth Monger                                                                                                                                                                        |
| 133 |     942.13249 |    104.778568 | NA                                                                                                                                                                                   |
| 134 |     398.27904 |    361.503325 | Lafage                                                                                                                                                                               |
| 135 |     768.30534 |    230.462745 | Jessica Anne Miller                                                                                                                                                                  |
| 136 |     499.74150 |    389.922840 | Ingo Braasch                                                                                                                                                                         |
| 137 |     307.46174 |    727.399879 | Margot Michaud                                                                                                                                                                       |
| 138 |     750.42021 |    259.299976 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 139 |     681.89782 |    770.186984 | Margot Michaud                                                                                                                                                                       |
| 140 |     689.83779 |    660.988469 | Crystal Maier                                                                                                                                                                        |
| 141 |     988.85890 |    620.495946 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 142 |      15.57815 |     19.402566 | Matt Crook                                                                                                                                                                           |
| 143 |     852.42786 |    475.086044 | Liftarn                                                                                                                                                                              |
| 144 |     335.40860 |    569.478512 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                     |
| 145 |     648.11115 |    384.832699 | Scott Hartman                                                                                                                                                                        |
| 146 |     841.91887 |     25.293107 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 147 |      33.27116 |    206.233035 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 148 |     303.29238 |    201.738433 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 149 |     189.07092 |    596.168597 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 150 |     218.79494 |    136.419419 | Matt Martyniuk                                                                                                                                                                       |
| 151 |     411.66713 |    337.660427 | NA                                                                                                                                                                                   |
| 152 |     589.04597 |    508.500338 | Markus A. Grohme                                                                                                                                                                     |
| 153 |     423.10901 |    543.019909 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 154 |     453.71201 |    319.277648 | Matt Dempsey                                                                                                                                                                         |
| 155 |     831.00648 |    340.534969 | Zimices                                                                                                                                                                              |
| 156 |     172.68384 |    237.541873 | Gareth Monger                                                                                                                                                                        |
| 157 |     750.58253 |    108.833165 | Gareth Monger                                                                                                                                                                        |
| 158 |     827.18320 |    176.602179 | David Tana                                                                                                                                                                           |
| 159 |     785.01469 |    109.520102 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 160 |      43.66954 |    217.516121 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                                   |
| 161 |     668.78632 |    427.446621 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                                      |
| 162 |     198.35849 |    787.991666 | Bruno Maggia                                                                                                                                                                         |
| 163 |     481.84093 |    158.897199 | NA                                                                                                                                                                                   |
| 164 |     405.52893 |    509.081132 | Tyler Greenfield                                                                                                                                                                     |
| 165 |     589.75259 |    601.311782 | Martin Kevil                                                                                                                                                                         |
| 166 |     789.62903 |    225.885927 | Scott Reid                                                                                                                                                                           |
| 167 |     240.63024 |    660.940971 | Becky Barnes                                                                                                                                                                         |
| 168 |     654.97174 |    784.964968 | Xavier Giroux-Bougard                                                                                                                                                                |
| 169 |     286.60098 |     25.863899 | Jagged Fang Designs                                                                                                                                                                  |
| 170 |     800.40015 |    162.956243 | Scott Hartman                                                                                                                                                                        |
| 171 |      83.21162 |    713.512220 | Birgit Lang                                                                                                                                                                          |
| 172 |     687.14152 |    332.819305 | NA                                                                                                                                                                                   |
| 173 |     844.64937 |    615.874592 | Zimices                                                                                                                                                                              |
| 174 |     440.75931 |    751.035554 | Jagged Fang Designs                                                                                                                                                                  |
| 175 |     802.58347 |     13.129906 | Matt Crook                                                                                                                                                                           |
| 176 |     258.51140 |    712.665005 | Margot Michaud                                                                                                                                                                       |
| 177 |     878.41367 |     38.521748 | Gareth Monger                                                                                                                                                                        |
| 178 |     771.67069 |    582.753811 | Chloé Schmidt                                                                                                                                                                        |
| 179 |     774.47896 |    658.765326 | Mathilde Cordellier                                                                                                                                                                  |
| 180 |     466.75650 |    728.073114 | Matt Crook                                                                                                                                                                           |
| 181 |     743.76780 |    717.294518 | NA                                                                                                                                                                                   |
| 182 |     576.76491 |    330.431506 | (after Spotila 2004)                                                                                                                                                                 |
| 183 |    1008.70455 |    714.339746 | Matthew E. Clapham                                                                                                                                                                   |
| 184 |     780.49984 |    494.775081 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                                    |
| 185 |     372.52609 |    563.736723 | Katie S. Collins                                                                                                                                                                     |
| 186 |     721.51119 |    697.141708 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 187 |     551.91260 |     54.370789 | Steven Traver                                                                                                                                                                        |
| 188 |     975.11816 |    587.881166 | Oscar Sanisidro                                                                                                                                                                      |
| 189 |     341.35902 |    296.477787 | NA                                                                                                                                                                                   |
| 190 |     525.83152 |    291.112469 | Andy Wilson                                                                                                                                                                          |
| 191 |     817.59321 |    379.953245 | Jagged Fang Designs                                                                                                                                                                  |
| 192 |     335.74641 |    217.073023 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 193 |     867.02449 |    656.887729 | Scott Hartman                                                                                                                                                                        |
| 194 |     218.80886 |    227.180561 | Fernando Carezzano                                                                                                                                                                   |
| 195 |     735.10197 |    332.206377 | Matt Crook                                                                                                                                                                           |
| 196 |     738.28755 |    523.586742 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 197 |     894.43384 |    348.764647 | Smokeybjb                                                                                                                                                                            |
| 198 |     193.82996 |    119.106966 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 199 |     103.31636 |    739.153797 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 200 |     510.77474 |      8.396641 | Harold N Eyster                                                                                                                                                                      |
| 201 |     137.82081 |    733.240994 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                           |
| 202 |      33.15624 |    752.650139 | Kamil S. Jaron                                                                                                                                                                       |
| 203 |     851.53765 |    411.617826 | Markus A. Grohme                                                                                                                                                                     |
| 204 |     925.99631 |    424.382809 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                                  |
| 205 |     439.34409 |     23.314131 | SecretJellyMan                                                                                                                                                                       |
| 206 |     283.33302 |     56.444828 | Erika Schumacher                                                                                                                                                                     |
| 207 |     488.43544 |     19.421867 | Jaime Headden                                                                                                                                                                        |
| 208 |     589.64778 |    699.486220 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 209 |      51.90657 |    626.131346 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 210 |     396.79288 |    129.865054 | Gareth Monger                                                                                                                                                                        |
| 211 |      14.47992 |    400.633391 | Juan Carlos Jerí                                                                                                                                                                     |
| 212 |     159.23997 |    287.200175 | Ferran Sayol                                                                                                                                                                         |
| 213 |     280.23887 |    676.584475 | Michael P. Taylor                                                                                                                                                                    |
| 214 |     453.59565 |    793.882662 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 215 |     763.07770 |    142.912930 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
| 216 |     895.05902 |    702.780966 | NA                                                                                                                                                                                   |
| 217 |      23.54178 |    530.938481 | Meliponicultor Itaymbere                                                                                                                                                             |
| 218 |      97.31372 |    465.344013 | Jaime Headden                                                                                                                                                                        |
| 219 |     636.27806 |     34.739602 | Matt Crook                                                                                                                                                                           |
| 220 |     285.94496 |    477.056772 | Alex Slavenko                                                                                                                                                                        |
| 221 |     127.16300 |    512.843537 | Zimices                                                                                                                                                                              |
| 222 |     189.79540 |    768.276052 | Chuanixn Yu                                                                                                                                                                          |
| 223 |     358.96074 |    719.477698 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                       |
| 224 |     424.23262 |    402.447879 | Ieuan Jones                                                                                                                                                                          |
| 225 |     854.23642 |     50.829217 | Lafage                                                                                                                                                                               |
| 226 |     736.85413 |    210.757813 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                                    |
| 227 |      49.52245 |    546.444587 | Michelle Site                                                                                                                                                                        |
| 228 |      72.30167 |    244.478358 | Zimices                                                                                                                                                                              |
| 229 |     158.11439 |    679.548657 | Michele M Tobias                                                                                                                                                                     |
| 230 |     140.08257 |    164.133431 | NA                                                                                                                                                                                   |
| 231 |     178.37376 |    728.603619 | Felix Vaux                                                                                                                                                                           |
| 232 |     157.26072 |    156.237670 | Iain Reid                                                                                                                                                                            |
| 233 |     343.52009 |    503.052542 | NA                                                                                                                                                                                   |
| 234 |     161.89598 |    256.822627 | Rebecca Groom                                                                                                                                                                        |
| 235 |     770.93300 |    294.003154 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 236 |     773.09878 |    722.594082 | Margot Michaud                                                                                                                                                                       |
| 237 |     995.67650 |    262.464257 | Matt Crook                                                                                                                                                                           |
| 238 |     335.03722 |    705.570343 | Jaime Headden                                                                                                                                                                        |
| 239 |     629.95268 |    782.260102 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 240 |     258.02406 |    723.733500 | Julia B McHugh                                                                                                                                                                       |
| 241 |     686.79927 |     44.321068 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 242 |     663.06520 |    152.604736 | Isaure Scavezzoni                                                                                                                                                                    |
| 243 |      77.66486 |    518.546381 | Mo Hassan                                                                                                                                                                            |
| 244 |     836.42108 |    742.480658 | Emily Willoughby                                                                                                                                                                     |
| 245 |    1009.04462 |    160.673658 | NA                                                                                                                                                                                   |
| 246 |     279.18123 |    418.814881 | Margot Michaud                                                                                                                                                                       |
| 247 |     757.48370 |    712.999468 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                                |
| 248 |     368.91891 |    221.114380 | Tasman Dixon                                                                                                                                                                         |
| 249 |     761.63584 |    678.665798 | Zimices                                                                                                                                                                              |
| 250 |      26.79527 |    774.335483 | Zimices                                                                                                                                                                              |
| 251 |     316.35991 |    565.456591 | Tyler Greenfield                                                                                                                                                                     |
| 252 |     756.67208 |    744.017811 | NA                                                                                                                                                                                   |
| 253 |     440.08604 |    364.794466 | Chris huh                                                                                                                                                                            |
| 254 |     131.52310 |    708.071498 | T. Michael Keesey                                                                                                                                                                    |
| 255 |    1002.43511 |    193.602771 | T. Michael Keesey                                                                                                                                                                    |
| 256 |     617.99334 |    172.863399 | Scott Hartman                                                                                                                                                                        |
| 257 |     347.25369 |    535.625117 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 258 |     996.73027 |    567.199946 | Felix Vaux                                                                                                                                                                           |
| 259 |     785.52054 |    359.234744 | Zimices                                                                                                                                                                              |
| 260 |     511.04767 |    176.839180 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 261 |    1008.74306 |     53.432922 | Chris huh                                                                                                                                                                            |
| 262 |     635.51931 |    142.611171 | Mathieu Pélissié                                                                                                                                                                     |
| 263 |     453.50496 |    129.602601 | Terpsichores                                                                                                                                                                         |
| 264 |     188.44143 |      9.311598 | NA                                                                                                                                                                                   |
| 265 |      19.41773 |    162.192036 | NA                                                                                                                                                                                   |
| 266 |     219.23797 |    688.011525 | Zimices                                                                                                                                                                              |
| 267 |     475.22838 |    401.731376 | Ferran Sayol                                                                                                                                                                         |
| 268 |     945.65352 |    312.031181 | Michael Scroggie                                                                                                                                                                     |
| 269 |    1002.11515 |     90.885370 | FunkMonk                                                                                                                                                                             |
| 270 |     408.90464 |     45.800865 | Zimices                                                                                                                                                                              |
| 271 |     443.05509 |    775.521765 | CNZdenek                                                                                                                                                                             |
| 272 |     577.46315 |    730.458284 | Markus A. Grohme                                                                                                                                                                     |
| 273 |      81.01161 |    270.532088 | Matt Crook                                                                                                                                                                           |
| 274 |     872.17385 |    745.367275 | Matt Crook                                                                                                                                                                           |
| 275 |     617.94044 |    563.986067 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 276 |     619.62675 |     10.580235 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 277 |      60.31636 |    163.140674 | Alex Slavenko                                                                                                                                                                        |
| 278 |     872.52595 |    602.670595 | Ferran Sayol                                                                                                                                                                         |
| 279 |     924.33959 |    595.427789 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 280 |     203.47342 |    453.385712 | Zimices                                                                                                                                                                              |
| 281 |     318.68330 |    756.149974 | NA                                                                                                                                                                                   |
| 282 |     963.88395 |    416.267946 | T. Michael Keesey                                                                                                                                                                    |
| 283 |     793.75462 |    788.972663 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
| 284 |     836.86167 |    431.164173 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 285 |     905.94728 |    334.904831 | Margot Michaud                                                                                                                                                                       |
| 286 |     838.23854 |    391.537165 | Mathieu Basille                                                                                                                                                                      |
| 287 |     861.21929 |    393.680836 | NA                                                                                                                                                                                   |
| 288 |     138.06814 |     80.873866 | Zimices                                                                                                                                                                              |
| 289 |     869.04626 |    776.433147 | Xavier Giroux-Bougard                                                                                                                                                                |
| 290 |     165.53742 |    516.657874 | Sarah Werning                                                                                                                                                                        |
| 291 |     100.68671 |    768.432253 | Meliponicultor Itaymbere                                                                                                                                                             |
| 292 |     113.81567 |    485.289408 | Matt Crook                                                                                                                                                                           |
| 293 |     692.66503 |    699.826466 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 294 |      45.48028 |     24.806051 | NA                                                                                                                                                                                   |
| 295 |     891.33947 |    164.556689 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 296 |     453.98078 |    760.259065 | Dean Schnabel                                                                                                                                                                        |
| 297 |     998.95396 |    514.006621 | Chris huh                                                                                                                                                                            |
| 298 |     243.66321 |    440.683511 | Melissa Broussard                                                                                                                                                                    |
| 299 |     888.55874 |    321.238298 | Markus A. Grohme                                                                                                                                                                     |
| 300 |     631.44207 |    537.163429 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                         |
| 301 |     641.46672 |    478.363008 | Nobu Tamura                                                                                                                                                                          |
| 302 |     815.81076 |     61.992621 | Emily Willoughby                                                                                                                                                                     |
| 303 |     424.38653 |    481.959072 | Matt Celeskey                                                                                                                                                                        |
| 304 |     619.61877 |    648.971517 | Ferran Sayol                                                                                                                                                                         |
| 305 |     536.62031 |    780.101458 | Chris huh                                                                                                                                                                            |
| 306 |     919.10464 |    406.562895 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 307 |     720.98649 |    282.909013 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 308 |     997.83502 |     68.674606 | Lukasiniho                                                                                                                                                                           |
| 309 |    1001.82179 |    653.565094 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 310 |     875.34261 |     63.061222 | Jaime Headden                                                                                                                                                                        |
| 311 |     381.20013 |    374.805448 | Zimices                                                                                                                                                                              |
| 312 |      44.73906 |    405.470493 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 313 |     459.18790 |    497.920924 | Jessica Rick                                                                                                                                                                         |
| 314 |     575.73809 |     10.381711 | Zimices                                                                                                                                                                              |
| 315 |     716.30760 |    229.281321 | Alex Slavenko                                                                                                                                                                        |
| 316 |     559.31481 |    616.265986 | Jaime Headden                                                                                                                                                                        |
| 317 |     282.12710 |    496.931775 | T. Michael Keesey                                                                                                                                                                    |
| 318 |      89.51294 |    657.025489 | Maija Karala                                                                                                                                                                         |
| 319 |     805.97094 |    136.169440 | Gareth Monger                                                                                                                                                                        |
| 320 |     548.16743 |    626.250768 | Lauren Sumner-Rooney                                                                                                                                                                 |
| 321 |     467.55343 |    631.729359 | Emily Willoughby                                                                                                                                                                     |
| 322 |     369.94629 |    129.384430 | Ferran Sayol                                                                                                                                                                         |
| 323 |     772.67660 |     33.302117 | Chris huh                                                                                                                                                                            |
| 324 |     995.21894 |    240.327056 | NA                                                                                                                                                                                   |
| 325 |    1003.48495 |    592.514821 | Jagged Fang Designs                                                                                                                                                                  |
| 326 |     909.31835 |    416.879308 | Jagged Fang Designs                                                                                                                                                                  |
| 327 |    1008.78020 |    291.770726 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 328 |     617.26768 |    257.150569 | Jakovche                                                                                                                                                                             |
| 329 |      13.10313 |    730.372441 | NA                                                                                                                                                                                   |
| 330 |     530.36074 |    192.217116 | T. Michael Keesey                                                                                                                                                                    |
| 331 |     263.54928 |    210.344778 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 332 |     780.83488 |     10.145147 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                                      |
| 333 |     669.40650 |    630.037469 | Oliver Griffith                                                                                                                                                                      |
| 334 |     756.84765 |    510.011974 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 335 |     825.47025 |    303.826354 | NA                                                                                                                                                                                   |
| 336 |     552.79608 |    671.739469 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                                    |
| 337 |     820.04245 |    601.750377 | Collin Gross                                                                                                                                                                         |
| 338 |      16.00315 |    506.031403 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 339 |     940.95714 |    153.715505 | Andy Wilson                                                                                                                                                                          |
| 340 |     420.58728 |    178.932901 | Jagged Fang Designs                                                                                                                                                                  |
| 341 |     816.06392 |    368.845010 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 342 |     888.17065 |    476.943719 | Gareth Monger                                                                                                                                                                        |
| 343 |      94.74222 |    161.693597 | NA                                                                                                                                                                                   |
| 344 |     531.99517 |    521.112771 | Markus A. Grohme                                                                                                                                                                     |
| 345 |     959.39842 |     42.811951 | Margot Michaud                                                                                                                                                                       |
| 346 |      58.93069 |    254.604272 | Iain Reid                                                                                                                                                                            |
| 347 |     113.46848 |     52.787503 | Zimices                                                                                                                                                                              |
| 348 |     197.86006 |    437.226936 | Ferran Sayol                                                                                                                                                                         |
| 349 |     721.84683 |    507.171519 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 350 |     496.81143 |    240.877199 | Lukas Panzarin                                                                                                                                                                       |
| 351 |     441.16864 |    419.015246 | Becky Barnes                                                                                                                                                                         |
| 352 |     587.00650 |    787.293985 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 353 |     493.14243 |    593.845818 | Birgit Lang                                                                                                                                                                          |
| 354 |     697.37488 |    635.307990 | Iain Reid                                                                                                                                                                            |
| 355 |     984.93167 |     20.157472 | Scott Hartman                                                                                                                                                                        |
| 356 |     835.62263 |    453.247759 | T. Michael Keesey                                                                                                                                                                    |
| 357 |     527.53465 |    789.189274 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 358 |     902.84942 |    305.390151 | Jagged Fang Designs                                                                                                                                                                  |
| 359 |     906.31895 |    251.751829 | Gareth Monger                                                                                                                                                                        |
| 360 |     378.40870 |    588.062182 | Jaime Headden                                                                                                                                                                        |
| 361 |    1008.33006 |    630.837039 | Markus A. Grohme                                                                                                                                                                     |
| 362 |     713.39119 |    248.449379 | Rebecca Groom                                                                                                                                                                        |
| 363 |     851.36881 |    176.893322 | Sean McCann                                                                                                                                                                          |
| 364 |     280.30951 |    456.111815 | Markus A. Grohme                                                                                                                                                                     |
| 365 |     587.00308 |     63.274542 | Ignacio Contreras                                                                                                                                                                    |
| 366 |     262.84992 |    741.766781 | xgirouxb                                                                                                                                                                             |
| 367 |     478.33120 |    219.415446 | Markus A. Grohme                                                                                                                                                                     |
| 368 |     202.79729 |    665.450921 | Tasman Dixon                                                                                                                                                                         |
| 369 |     330.71920 |     66.710487 | Cesar Julian                                                                                                                                                                         |
| 370 |     559.42590 |    511.135564 | Steven Coombs                                                                                                                                                                        |
| 371 |      47.32002 |    149.148475 | Andy Wilson                                                                                                                                                                          |
| 372 |     661.56669 |    162.758065 | Riccardo Percudani                                                                                                                                                                   |
| 373 |     749.13341 |    696.202351 | Matt Dempsey                                                                                                                                                                         |
| 374 |     251.69582 |    674.766242 | NA                                                                                                                                                                                   |
| 375 |     984.13887 |      8.173317 | NA                                                                                                                                                                                   |
| 376 |     950.42754 |    275.988063 | Gareth Monger                                                                                                                                                                        |
| 377 |     408.11859 |    440.838665 | CNZdenek                                                                                                                                                                             |
| 378 |      42.40224 |    492.137691 | T. Michael Keesey                                                                                                                                                                    |
| 379 |     660.93160 |      7.661335 | Ingo Braasch                                                                                                                                                                         |
| 380 |     113.99751 |    327.018029 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                                        |
| 381 |     304.07249 |    501.417311 | M Kolmann                                                                                                                                                                            |
| 382 |      15.30503 |    131.148881 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 383 |     939.70022 |    619.859017 | Margot Michaud                                                                                                                                                                       |
| 384 |      60.21416 |    115.510856 | Scott Hartman                                                                                                                                                                        |
| 385 |     515.65239 |    469.552065 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                                        |
| 386 |     982.19168 |    107.556265 | Ingo Braasch                                                                                                                                                                         |
| 387 |     368.58573 |    693.609928 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 388 |     129.92013 |    690.962214 | Christoph Schomburg                                                                                                                                                                  |
| 389 |      96.82707 |    449.239866 | Gareth Monger                                                                                                                                                                        |
| 390 |     803.40461 |    241.242371 | Jagged Fang Designs                                                                                                                                                                  |
| 391 |     861.71272 |    292.031192 | Andrew A. Farke                                                                                                                                                                      |
| 392 |     789.21160 |     92.055651 | Markus A. Grohme                                                                                                                                                                     |
| 393 |     576.08201 |    201.816121 | Jagged Fang Designs                                                                                                                                                                  |
| 394 |     563.16997 |    682.189642 | Zimices                                                                                                                                                                              |
| 395 |     896.65254 |    392.232278 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 396 |    1005.48804 |    759.728474 | Plukenet                                                                                                                                                                             |
| 397 |     137.20925 |    120.380043 | Steven Traver                                                                                                                                                                        |
| 398 |    1010.01858 |    357.257443 | Mathilde Cordellier                                                                                                                                                                  |
| 399 |     267.84884 |    785.575029 | Gareth Monger                                                                                                                                                                        |
| 400 |     359.38147 |    597.430043 | Scott Hartman                                                                                                                                                                        |
| 401 |     651.63566 |    549.732902 | Chris A. Hamilton                                                                                                                                                                    |
| 402 |     302.75460 |    153.024372 | Kai R. Caspar                                                                                                                                                                        |
| 403 |     510.43992 |    254.841494 | Daniel Jaron                                                                                                                                                                         |
| 404 |     426.57918 |    561.747372 | Sarah Werning                                                                                                                                                                        |
| 405 |     948.03555 |    331.502062 | NA                                                                                                                                                                                   |
| 406 |     164.84105 |    752.192549 | NA                                                                                                                                                                                   |
| 407 |     524.49343 |    391.146546 | Christoph Schomburg                                                                                                                                                                  |
| 408 |     799.79600 |    255.833955 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 409 |    1009.35116 |    546.626732 | Margot Michaud                                                                                                                                                                       |
| 410 |     614.44904 |    618.062910 | Andrew A. Farke                                                                                                                                                                      |
| 411 |     234.85050 |    624.293833 | Caleb M. Gordon                                                                                                                                                                      |
| 412 |     931.10764 |    274.282806 | Zimices                                                                                                                                                                              |
| 413 |      38.83930 |    527.269640 | NA                                                                                                                                                                                   |
| 414 |     198.09381 |    409.758467 | Chris huh                                                                                                                                                                            |
| 415 |     707.62906 |    322.720685 | Gareth Monger                                                                                                                                                                        |
| 416 |     162.29277 |    432.123926 | Jake Warner                                                                                                                                                                          |
| 417 |     865.61576 |     80.823891 | Chris huh                                                                                                                                                                            |
| 418 |     836.62364 |    723.815370 | Margot Michaud                                                                                                                                                                       |
| 419 |     363.93982 |    648.185924 | NA                                                                                                                                                                                   |
| 420 |     244.98800 |    792.933045 | Emily Willoughby                                                                                                                                                                     |
| 421 |      19.59471 |    424.743471 | Matt Crook                                                                                                                                                                           |
| 422 |     302.44195 |    212.846726 | Mette Aumala                                                                                                                                                                         |
| 423 |     343.65182 |    170.389925 | Zimices                                                                                                                                                                              |
| 424 |     541.24690 |     13.470245 | FunkMonk                                                                                                                                                                             |
| 425 |     685.66661 |    504.405856 | Chris huh                                                                                                                                                                            |
| 426 |     114.46915 |     11.864624 | Ferran Sayol                                                                                                                                                                         |
| 427 |     350.35870 |    399.843113 | NA                                                                                                                                                                                   |
| 428 |     387.24597 |    732.201766 | Tauana J. Cunha                                                                                                                                                                      |
| 429 |     794.34542 |    511.536947 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 430 |     669.46536 |     23.063279 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 431 |     764.55687 |    247.394550 | Gareth Monger                                                                                                                                                                        |
| 432 |     536.78268 |    154.311726 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 433 |      97.97708 |    312.924418 | Jessica Anne Miller                                                                                                                                                                  |
| 434 |      12.41521 |    212.879629 | Beth Reinke                                                                                                                                                                          |
| 435 |     464.43420 |      6.144450 | T. Michael Keesey                                                                                                                                                                    |
| 436 |      46.26059 |    130.548826 | Caleb M. Brown                                                                                                                                                                       |
| 437 |     116.65772 |    794.777969 | Chris huh                                                                                                                                                                            |
| 438 |     359.46635 |    546.659267 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                                              |
| 439 |     831.63392 |    791.014754 | NA                                                                                                                                                                                   |
| 440 |     391.89524 |     50.256706 | Scott Hartman                                                                                                                                                                        |
| 441 |      16.94032 |    790.166405 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 442 |     450.13953 |    721.627728 | Caleb M. Brown                                                                                                                                                                       |
| 443 |     435.81407 |    504.734973 | Ingo Braasch                                                                                                                                                                         |
| 444 |     278.36823 |    514.638803 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                                    |
| 445 |     445.81194 |    214.651499 | Steven Traver                                                                                                                                                                        |
| 446 |     154.70658 |    216.952353 | T. Michael Keesey                                                                                                                                                                    |
| 447 |     755.03645 |    532.980428 | Margot Michaud                                                                                                                                                                       |
| 448 |     649.64801 |    764.688053 | Scott Hartman                                                                                                                                                                        |
| 449 |     537.03738 |    587.237784 | Ingo Braasch                                                                                                                                                                         |
| 450 |     266.42701 |    373.166785 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 451 |     267.15843 |    700.773245 | Tony Ayling                                                                                                                                                                          |
| 452 |     645.98758 |    170.521887 | Jagged Fang Designs                                                                                                                                                                  |
| 453 |     761.30062 |    364.060586 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 454 |     613.85466 |    779.946560 | T. Michael Keesey                                                                                                                                                                    |
| 455 |     130.65388 |    344.668764 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
| 456 |     115.19599 |    171.835575 | Margot Michaud                                                                                                                                                                       |
| 457 |     345.33579 |    434.510852 | Steven Traver                                                                                                                                                                        |
| 458 |     911.07619 |    234.373914 | Lukas Panzarin                                                                                                                                                                       |
| 459 |     249.10389 |    538.273103 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 460 |     239.20367 |    647.435827 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 461 |     570.22376 |    186.671511 | Tasman Dixon                                                                                                                                                                         |
| 462 |     710.52455 |    418.929888 | Zimices                                                                                                                                                                              |
| 463 |     550.47568 |    374.889839 | Chris huh                                                                                                                                                                            |
| 464 |     947.54425 |    401.937644 | Shyamal                                                                                                                                                                              |
| 465 |     583.35226 |    299.782500 | Jagged Fang Designs                                                                                                                                                                  |
| 466 |     371.41848 |     10.814953 | CNZdenek                                                                                                                                                                             |
| 467 |     153.85867 |    205.221606 | Ingo Braasch                                                                                                                                                                         |
| 468 |     486.03533 |    138.359338 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                             |
| 469 |     736.90162 |    135.283923 | Gareth Monger                                                                                                                                                                        |
| 470 |     130.87302 |     95.157986 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                                              |
| 471 |     785.17916 |    448.565679 | Margot Michaud                                                                                                                                                                       |
| 472 |     849.61275 |    494.144784 | Mathew Wedel                                                                                                                                                                         |
| 473 |     531.90193 |    648.126041 | Andy Wilson                                                                                                                                                                          |
| 474 |     381.89987 |    181.871740 | Scott Hartman                                                                                                                                                                        |
| 475 |     616.33270 |    367.417698 | Jagged Fang Designs                                                                                                                                                                  |
| 476 |     501.44099 |     54.265597 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 477 |      19.12720 |    704.515428 | Tasman Dixon                                                                                                                                                                         |
| 478 |    1007.64646 |     17.138931 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                                      |
| 479 |     773.14226 |    460.206256 | Steven Traver                                                                                                                                                                        |
| 480 |     492.79883 |    232.332882 | Chris huh                                                                                                                                                                            |
| 481 |     716.94714 |    543.958653 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 482 |     236.64235 |     83.518699 | Henry Lydecker                                                                                                                                                                       |
| 483 |     737.18664 |    602.201061 | Stuart Humphries                                                                                                                                                                     |
| 484 |     500.20950 |    159.109010 | Michael Scroggie                                                                                                                                                                     |
| 485 |     827.83686 |    483.139684 | Ingo Braasch                                                                                                                                                                         |
| 486 |     460.87729 |    179.108293 | NA                                                                                                                                                                                   |
| 487 |     892.07883 |    795.378676 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                                 |
| 488 |     177.49600 |    602.142708 | Jaime Headden                                                                                                                                                                        |
| 489 |     483.75025 |    260.253672 | Chris huh                                                                                                                                                                            |
| 490 |     752.86559 |    479.235114 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 491 |     746.61488 |    762.535133 | Tasman Dixon                                                                                                                                                                         |
| 492 |     364.35351 |    504.205397 | Ferran Sayol                                                                                                                                                                         |
| 493 |     807.73424 |    103.404877 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                        |
| 494 |     820.27122 |    155.598250 | Andy Wilson                                                                                                                                                                          |
| 495 |      79.05812 |     51.752515 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 496 |    1015.95212 |    384.502250 | Lauren Anderson                                                                                                                                                                      |
| 497 |     407.36959 |    314.095166 | Sarah Werning                                                                                                                                                                        |
| 498 |     934.98923 |    506.851674 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
| 499 |     441.26145 |    593.506648 | Felix Vaux                                                                                                                                                                           |
| 500 |     556.17051 |     70.830829 | FunkMonk                                                                                                                                                                             |
| 501 |    1005.73011 |    214.391575 | Chris huh                                                                                                                                                                            |
| 502 |     474.38501 |    773.634871 | Andrés Sánchez                                                                                                                                                                       |
| 503 |     708.65747 |    780.126262 | Chris huh                                                                                                                                                                            |
| 504 |     659.31502 |    356.705008 | Scott Hartman                                                                                                                                                                        |
| 505 |     178.17727 |    560.580965 | Gopal Murali                                                                                                                                                                         |
| 506 |     454.75335 |    105.274974 | Jagged Fang Designs                                                                                                                                                                  |
| 507 |     613.22179 |    193.417057 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 508 |     565.14106 |    384.543946 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                       |
| 509 |     459.70998 |     26.002840 | Kamil S. Jaron                                                                                                                                                                       |
| 510 |     384.33973 |    527.567156 | NA                                                                                                                                                                                   |
| 511 |     959.94537 |     12.205753 | Andy Wilson                                                                                                                                                                          |
| 512 |     165.23319 |    494.366471 | Scott Hartman                                                                                                                                                                        |
| 513 |     637.53383 |     72.221453 | Markus A. Grohme                                                                                                                                                                     |
| 514 |     566.55488 |    736.722473 | Cesar Julian                                                                                                                                                                         |
| 515 |     344.60668 |      4.108864 | Jagged Fang Designs                                                                                                                                                                  |
| 516 |     273.28650 |      4.148272 | Maija Karala                                                                                                                                                                         |
| 517 |     343.06396 |    412.891367 | Caleb Brown                                                                                                                                                                          |
| 518 |      77.92487 |    789.678534 | Gareth Monger                                                                                                                                                                        |
| 519 |     914.50982 |     46.035229 | Birgit Lang                                                                                                                                                                          |
| 520 |    1007.94443 |    222.766184 | Chris huh                                                                                                                                                                            |
| 521 |     602.12733 |    206.674971 | Caio Bernardes, vectorized by Zimices                                                                                                                                                |
| 522 |     742.46415 |    555.517694 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 523 |    1005.59867 |    521.471569 | Michael P. Taylor                                                                                                                                                                    |
| 524 |     581.76135 |    433.663111 | Gareth Monger                                                                                                                                                                        |
| 525 |     303.29635 |    757.301544 | T. Michael Keesey                                                                                                                                                                    |
| 526 |     308.10925 |    566.166146 | Gareth Monger                                                                                                                                                                        |
| 527 |     251.68311 |    496.561670 | Ignacio Contreras                                                                                                                                                                    |
| 528 |     236.51702 |    239.677991 | Collin Gross                                                                                                                                                                         |
| 529 |     499.91300 |    288.583907 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 530 |     927.00380 |    670.757446 | NA                                                                                                                                                                                   |
| 531 |     185.40469 |    248.537687 | Chris huh                                                                                                                                                                            |
| 532 |     154.75755 |    506.298045 | Julio Garza                                                                                                                                                                          |
| 533 |     141.00336 |    225.518963 | Tracy A. Heath                                                                                                                                                                       |
| 534 |     392.77928 |    251.417270 | Markus A. Grohme                                                                                                                                                                     |
| 535 |     962.01991 |    511.880871 | Gareth Monger                                                                                                                                                                        |
| 536 |     591.06388 |    670.882321 | Shyamal                                                                                                                                                                              |
| 537 |     712.78697 |    790.399923 | Chris huh                                                                                                                                                                            |
| 538 |     115.91952 |    500.901610 | Jaime Headden                                                                                                                                                                        |
| 539 |     183.48315 |    425.761883 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
| 540 |     986.75353 |    794.587461 | Margot Michaud                                                                                                                                                                       |
| 541 |      20.73567 |    497.213809 | Zimices                                                                                                                                                                              |
| 542 |     349.09829 |    182.503052 | C. Camilo Julián-Caballero                                                                                                                                                           |

    #> Your tweet has been posted!
