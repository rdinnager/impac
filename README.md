
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

Matt Dempsey, Tyler McCraney, Andy Wilson, Chris huh, Margot Michaud,
Walter Vladimir, Amanda Katzer, T. Michael Keesey, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Nobu Tamura,
Timothy Knepp (vectorized by T. Michael Keesey), Yan Wong, Chuanixn Yu,
Scott Hartman, Felix Vaux, Beth Reinke, Alexander Schmidt-Lebuhn, Dean
Schnabel, Markus A. Grohme, Gareth Monger, Owen Jones, James R. Spotila
and Ray Chatterji, Matt Crook, L. Shyamal, \[unknown\], Steven Traver,
David Orr, Carlos Cano-Barbacil, Pete Buchholz, Julio Garza, C. Camilo
Julián-Caballero, Zimices, terngirl, Tasman Dixon, Kanchi Nanjo, Skye
McDavid, Maxime Dahirel, Lee Harding (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Birgit Lang, Rebecca Groom,
Kenneth Lacovara (vectorized by T. Michael Keesey), Erika Schumacher,
Inessa Voet, Lani Mohan, Scott Reid, Noah Schlottman, photo by Casey
Dunn, Steven Coombs, T. Tischler, Andrew A. Farke, Jaime Headden, Emily
Willoughby, Joanna Wolfe, Zachary Quigley, Ferran Sayol, Jagged Fang
Designs, Christoph Schomburg, T. Michael Keesey (after Walker & al.),
Caleb M. Brown, Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Heinrich Harder (vectorized by T. Michael Keesey), Skye
M, Shyamal, Nobu Tamura (modified by T. Michael Keesey), Dmitry Bogdanov
(vectorized by T. Michael Keesey), Chris Jennings (Risiatto), Michelle
Site, Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Collin Gross, Armin Reindl, Falconaumanni
and T. Michael Keesey, Mathew Wedel, Matt Hayes, Noah Schlottman,
Berivan Temiz, Tauana J. Cunha, Meyers Konversations-Lexikon 1897
(vectorized: Yan Wong), Ghedoghedo (vectorized by T. Michael Keesey),
Jack Mayer Wood, Tony Ayling (vectorized by T. Michael Keesey), Renato
Santos, Iain Reid, Jay Matternes (modified by T. Michael Keesey),
xgirouxb, Dexter R. Mardis, B. Duygu Özpolat, Dmitry Bogdanov, Katie S.
Collins, Nobu Tamura (vectorized by T. Michael Keesey), Mali’o Kodis,
photograph by Hans Hillewaert, Matthew E. Clapham, Gabriela
Palomo-Munoz, Didier Descouens (vectorized by T. Michael Keesey), Milton
Tan, Chloé Schmidt, Gopal Murali, Mason McNair, Kamil S. Jaron, Kent
Elson Sorgon, H. F. O. March (modified by T. Michael Keesey, Michael P.
Taylor & Matthew J. Wedel), Christine Axon, Mali’o Kodis, photograph by
Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>),
Mali’o Kodis, image from the Smithsonian Institution, Renata F.
Martins, Juan Carlos Jerí, Roberto Díaz Sibaja, Duane Raver (vectorized
by T. Michael Keesey), Robbie N. Cada (vectorized by T. Michael Keesey),
Matt Martyniuk, CNZdenek, Hugo Gruson, George Edward Lodge (vectorized
by T. Michael Keesey), www.studiospectre.com, Crystal Maier, Robert Gay,
T. Michael Keesey (after C. De Muizon), Thea Boodhoo (photograph) and T.
Michael Keesey (vectorization), Caio Bernardes, vectorized by Zimices,
FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey), Ignacio
Contreras, Aviceda (vectorized by T. Michael Keesey), Nobu Tamura,
vectorized by Zimices, Sarah Werning, Ghedoghedo, vectorized by Zimices,
Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Mattia Menchetti, NOAA (vectorized by T. Michael Keesey), Jaime Headden
(vectorized by T. Michael Keesey), Frank Förster (based on a picture by
Hans Hillewaert), Benjamint444, Evan Swigart (photography) and T.
Michael Keesey (vectorization), Javiera Constanzo, Smokeybjb, Harold N
Eyster, Alexandre Vong, Jaime A. Headden (vectorized by T. Michael
Keesey), Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Francesco Veronesi
(vectorized by T. Michael Keesey), Trond R. Oskars, Lafage, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Joseph J. W.
Sertich, Mark A. Loewen, , John Gould (vectorized by T. Michael Keesey),
Lip Kee Yap (vectorized by T. Michael Keesey), Abraão Leite, Riccardo
Percudani, Christina N. Hodson, Gabriele Midolo, H. F. O. March
(vectorized by T. Michael Keesey), Antonov (vectorized by T. Michael
Keesey), Jose Carlos Arenas-Monroy, JJ Harrison (vectorized by T.
Michael Keesey), Florian Pfaff, E. D. Cope (modified by T. Michael
Keesey, Michael P. Taylor & Matthew J. Wedel), Rafael Maia, Danny
Cicchetti (vectorized by T. Michael Keesey), Scott Hartman (vectorized
by William Gearty), Ingo Braasch, Emma Kissling, Bruno Maggia, Maija
Karala, Josefine Bohr Brask, Martin Kevil, John Conway, Martin R. Smith,
Arthur S. Brum, Anthony Caravaggi, Giant Blue Anteater (vectorized by T.
Michael Keesey), Mike Hanson, Michael P. Taylor, Tracy A. Heath, Darius
Nau, Mo Hassan, T. Michael Keesey (after Heinrich Harder), Melissa
Broussard, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), Young and Zhao (1972:figure
4), modified by Michael P. Taylor, Ricardo N. Martinez & Oscar A.
Alcober, SauropodomorphMonarch, FunkMonk, Nicholas J. Czaplewski,
vectorized by Zimices, M Kolmann, Abraão B. Leite, Alan Manson (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey), Andrés
Sánchez, Вальдимар (vectorized by T. Michael Keesey), Maxwell Lefroy
(vectorized by T. Michael Keesey), Original drawing by Antonov,
vectorized by Roberto Díaz Sibaja, Rene Martin

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     360.21198 |    128.309561 | Matt Dempsey                                                                                                                                                          |
|   2 |     755.13916 |    426.193185 | Tyler McCraney                                                                                                                                                        |
|   3 |     592.98261 |    189.864883 | Andy Wilson                                                                                                                                                           |
|   4 |     695.69060 |    457.583983 | Chris huh                                                                                                                                                             |
|   5 |     223.07346 |    306.500175 | Margot Michaud                                                                                                                                                        |
|   6 |     170.32928 |    248.562674 | Walter Vladimir                                                                                                                                                       |
|   7 |     717.24580 |     61.546037 | Amanda Katzer                                                                                                                                                         |
|   8 |     280.68301 |    633.603022 | T. Michael Keesey                                                                                                                                                     |
|   9 |     448.32584 |    590.554939 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
|  10 |     633.98225 |    604.179046 | Nobu Tamura                                                                                                                                                           |
|  11 |     840.35402 |     64.432626 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
|  12 |     188.67413 |     95.890952 | Yan Wong                                                                                                                                                              |
|  13 |     440.30875 |    268.593600 | Chuanixn Yu                                                                                                                                                           |
|  14 |     915.91727 |    305.272835 | Scott Hartman                                                                                                                                                         |
|  15 |     136.71475 |    421.948424 | Felix Vaux                                                                                                                                                            |
|  16 |      77.01268 |    776.720481 | Beth Reinke                                                                                                                                                           |
|  17 |     791.79474 |    588.585394 | NA                                                                                                                                                                    |
|  18 |     939.38885 |    603.935445 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  19 |     555.54410 |    341.486602 | Dean Schnabel                                                                                                                                                         |
|  20 |     626.81207 |    506.561536 | Markus A. Grohme                                                                                                                                                      |
|  21 |     505.43984 |    397.930306 | Walter Vladimir                                                                                                                                                       |
|  22 |      82.95938 |    677.396371 | Gareth Monger                                                                                                                                                         |
|  23 |     973.60070 |    733.584963 | Gareth Monger                                                                                                                                                         |
|  24 |     316.19562 |    461.116060 | Owen Jones                                                                                                                                                            |
|  25 |     870.43436 |    215.250847 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  26 |      63.20882 |    361.302407 | Matt Crook                                                                                                                                                            |
|  27 |     787.51569 |    278.252901 | L. Shyamal                                                                                                                                                            |
|  28 |     860.07002 |    414.178686 | NA                                                                                                                                                                    |
|  29 |     699.88217 |    731.519199 | \[unknown\]                                                                                                                                                           |
|  30 |     154.33549 |    174.268175 | Steven Traver                                                                                                                                                         |
|  31 |     109.84895 |     29.648509 | Yan Wong                                                                                                                                                              |
|  32 |     430.43975 |    690.221019 | David Orr                                                                                                                                                             |
|  33 |     391.95244 |    216.857779 | Carlos Cano-Barbacil                                                                                                                                                  |
|  34 |     551.39311 |    144.472292 | Pete Buchholz                                                                                                                                                         |
|  35 |     745.77191 |    151.697565 | Gareth Monger                                                                                                                                                         |
|  36 |     586.62158 |    697.488941 | Julio Garza                                                                                                                                                           |
|  37 |     886.50549 |    113.612739 | C. Camilo Julián-Caballero                                                                                                                                            |
|  38 |     513.90257 |    507.565643 | Zimices                                                                                                                                                               |
|  39 |     346.26774 |    366.782270 | terngirl                                                                                                                                                              |
|  40 |      72.47239 |    523.681739 | Chris huh                                                                                                                                                             |
|  41 |     177.97813 |    487.157174 | Tasman Dixon                                                                                                                                                          |
|  42 |     658.94925 |    172.231038 | Kanchi Nanjo                                                                                                                                                          |
|  43 |     318.92913 |    310.868333 | Matt Crook                                                                                                                                                            |
|  44 |     680.37999 |    254.660280 | Skye McDavid                                                                                                                                                          |
|  45 |      46.85890 |    153.369897 | T. Michael Keesey                                                                                                                                                     |
|  46 |     251.49872 |    186.590868 | Maxime Dahirel                                                                                                                                                        |
|  47 |     136.71179 |    553.958612 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  48 |     437.96931 |     53.679339 | Tasman Dixon                                                                                                                                                          |
|  49 |     854.00292 |    330.147578 | Birgit Lang                                                                                                                                                           |
|  50 |     884.47509 |    684.605679 | Rebecca Groom                                                                                                                                                         |
|  51 |     444.86592 |    180.226260 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
|  52 |     321.79319 |     41.117729 | Erika Schumacher                                                                                                                                                      |
|  53 |     762.52528 |    520.340850 | NA                                                                                                                                                                    |
|  54 |     111.94655 |    592.550857 | Inessa Voet                                                                                                                                                           |
|  55 |     234.50082 |    394.734687 | Steven Traver                                                                                                                                                         |
|  56 |     554.86640 |     56.176561 | Steven Traver                                                                                                                                                         |
|  57 |     541.77314 |    612.763653 | Lani Mohan                                                                                                                                                            |
|  58 |     761.83357 |    681.111546 | Gareth Monger                                                                                                                                                         |
|  59 |     561.63883 |    767.117424 | Scott Reid                                                                                                                                                            |
|  60 |     484.19251 |    473.893787 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  61 |     797.34039 |     28.998025 | Steven Coombs                                                                                                                                                         |
|  62 |     922.41359 |    487.810462 | T. Tischler                                                                                                                                                           |
|  63 |      41.07469 |    608.715646 | Yan Wong                                                                                                                                                              |
|  64 |     394.10155 |    529.891074 | Andrew A. Farke                                                                                                                                                       |
|  65 |     642.68518 |    553.620020 | Jaime Headden                                                                                                                                                         |
|  66 |     996.44296 |    190.843354 | Emily Willoughby                                                                                                                                                      |
|  67 |     151.63290 |    724.755235 | Joanna Wolfe                                                                                                                                                          |
|  68 |     962.66034 |     48.954325 | Zachary Quigley                                                                                                                                                       |
|  69 |     242.09694 |    758.611684 | Ferran Sayol                                                                                                                                                          |
|  70 |     842.30762 |    780.205666 | Chris huh                                                                                                                                                             |
|  71 |     953.55281 |    531.662214 | C. Camilo Julián-Caballero                                                                                                                                            |
|  72 |     746.41778 |    363.089487 | Gareth Monger                                                                                                                                                         |
|  73 |     878.82557 |    507.142724 | T. Michael Keesey                                                                                                                                                     |
|  74 |     366.76815 |    757.146458 | Jagged Fang Designs                                                                                                                                                   |
|  75 |      63.47243 |    462.485844 | T. Michael Keesey                                                                                                                                                     |
|  76 |     966.02076 |    382.918832 | Gareth Monger                                                                                                                                                         |
|  77 |     890.27005 |    162.434653 | Christoph Schomburg                                                                                                                                                   |
|  78 |     411.62532 |    407.929778 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
|  79 |      60.45117 |    254.943462 | Caleb M. Brown                                                                                                                                                        |
|  80 |     296.26716 |     79.475385 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
|  81 |     150.79575 |    670.109243 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
|  82 |     611.50711 |    303.556463 | NA                                                                                                                                                                    |
|  83 |     521.86613 |    350.331379 | Matt Crook                                                                                                                                                            |
|  84 |     692.45557 |     17.783070 | Skye M                                                                                                                                                                |
|  85 |     449.85321 |     97.358922 | Margot Michaud                                                                                                                                                        |
|  86 |     968.64520 |    251.343524 | Steven Traver                                                                                                                                                         |
|  87 |     745.40801 |    319.988097 | Julio Garza                                                                                                                                                           |
|  88 |      31.02936 |    686.423284 | Shyamal                                                                                                                                                               |
|  89 |     966.23258 |    117.310039 | Yan Wong                                                                                                                                                              |
|  90 |     267.69517 |    259.171027 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  91 |      45.06434 |    720.037989 | Markus A. Grohme                                                                                                                                                      |
|  92 |     296.75822 |    322.344253 | NA                                                                                                                                                                    |
|  93 |     485.99166 |    290.890011 | Erika Schumacher                                                                                                                                                      |
|  94 |      89.41469 |     66.775832 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  95 |     487.83978 |    110.322265 | Andy Wilson                                                                                                                                                           |
|  96 |      79.67362 |    289.938414 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  97 |     138.59046 |    615.011212 | NA                                                                                                                                                                    |
|  98 |     952.39513 |    460.743008 | Jagged Fang Designs                                                                                                                                                   |
|  99 |     319.74078 |    182.829211 | Chris Jennings (Risiatto)                                                                                                                                             |
| 100 |     500.19273 |    695.180255 | Michelle Site                                                                                                                                                         |
| 101 |     301.41674 |    522.371186 | Jagged Fang Designs                                                                                                                                                   |
| 102 |     684.82786 |    657.668091 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 103 |     483.55922 |    202.337606 | Gareth Monger                                                                                                                                                         |
| 104 |     432.76827 |    784.146069 | Gareth Monger                                                                                                                                                         |
| 105 |     209.36416 |    440.546045 | Collin Gross                                                                                                                                                          |
| 106 |     419.91166 |    141.847322 | Yan Wong                                                                                                                                                              |
| 107 |     521.90929 |    256.435044 | Ferran Sayol                                                                                                                                                          |
| 108 |     985.71540 |    103.611052 | Jagged Fang Designs                                                                                                                                                   |
| 109 |     183.82563 |    523.112393 | Armin Reindl                                                                                                                                                          |
| 110 |    1008.95687 |    667.384926 | Zimices                                                                                                                                                               |
| 111 |     318.59174 |    223.346972 | Gareth Monger                                                                                                                                                         |
| 112 |    1012.30361 |    125.123358 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 113 |     383.75168 |    145.760208 | Mathew Wedel                                                                                                                                                          |
| 114 |     928.02888 |    735.604672 | Matt Hayes                                                                                                                                                            |
| 115 |     635.09146 |     71.208855 | Gareth Monger                                                                                                                                                         |
| 116 |     436.17879 |     46.036673 | Gareth Monger                                                                                                                                                         |
| 117 |     286.94299 |     18.051976 | Zimices                                                                                                                                                               |
| 118 |     672.41832 |    340.867140 | Noah Schlottman                                                                                                                                                       |
| 119 |     522.06513 |    776.205789 | Margot Michaud                                                                                                                                                        |
| 120 |     783.44662 |    130.608617 | Berivan Temiz                                                                                                                                                         |
| 121 |     694.25352 |    320.243327 | Zimices                                                                                                                                                               |
| 122 |     238.54192 |     13.057862 | Joanna Wolfe                                                                                                                                                          |
| 123 |     964.71679 |    151.918442 | Tauana J. Cunha                                                                                                                                                       |
| 124 |     230.02600 |    498.876085 | Matt Crook                                                                                                                                                            |
| 125 |      24.82775 |    303.716730 | Zimices                                                                                                                                                               |
| 126 |     944.14921 |    196.870028 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 127 |     623.95512 |    448.035099 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 128 |     838.90088 |    467.625506 | Markus A. Grohme                                                                                                                                                      |
| 129 |     785.46145 |    209.527694 | Matt Crook                                                                                                                                                            |
| 130 |     207.15485 |    767.784150 | Jack Mayer Wood                                                                                                                                                       |
| 131 |     403.48092 |    477.942695 | NA                                                                                                                                                                    |
| 132 |     200.12791 |    153.738022 | Zimices                                                                                                                                                               |
| 133 |     401.10846 |    739.126492 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 134 |     432.08015 |    637.126880 | Tauana J. Cunha                                                                                                                                                       |
| 135 |     788.96196 |     76.645151 | Steven Traver                                                                                                                                                         |
| 136 |     540.53792 |    659.565875 | Matt Crook                                                                                                                                                            |
| 137 |     785.02763 |    756.069862 | Renato Santos                                                                                                                                                         |
| 138 |     546.36424 |    427.080141 | Iain Reid                                                                                                                                                             |
| 139 |    1005.23921 |    572.213413 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                         |
| 140 |     829.43004 |    737.037939 | Matt Crook                                                                                                                                                            |
| 141 |     340.47425 |    252.630566 | xgirouxb                                                                                                                                                              |
| 142 |     928.52183 |    398.206133 | Markus A. Grohme                                                                                                                                                      |
| 143 |     153.39234 |    341.524213 | Dexter R. Mardis                                                                                                                                                      |
| 144 |     250.34778 |    510.176181 | Steven Traver                                                                                                                                                         |
| 145 |     662.81296 |    744.943092 | NA                                                                                                                                                                    |
| 146 |    1006.90362 |    415.475099 | Joanna Wolfe                                                                                                                                                          |
| 147 |     234.05463 |    360.828616 | Beth Reinke                                                                                                                                                           |
| 148 |     911.29697 |     88.174219 | B. Duygu Özpolat                                                                                                                                                      |
| 149 |     364.98851 |    178.523027 | Ferran Sayol                                                                                                                                                          |
| 150 |     402.30498 |    497.404296 | Dmitry Bogdanov                                                                                                                                                       |
| 151 |     477.90855 |    470.736773 | T. Michael Keesey                                                                                                                                                     |
| 152 |     476.60415 |    165.347827 | Zimices                                                                                                                                                               |
| 153 |     305.31747 |    293.345975 | Katie S. Collins                                                                                                                                                      |
| 154 |     685.00064 |     93.496321 | Amanda Katzer                                                                                                                                                         |
| 155 |     889.06672 |     35.607000 | Zimices                                                                                                                                                               |
| 156 |     955.51835 |    660.671380 | NA                                                                                                                                                                    |
| 157 |     487.68601 |    652.439693 | Kanchi Nanjo                                                                                                                                                          |
| 158 |     676.04339 |    533.850416 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 159 |     304.29908 |    137.025091 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 160 |     991.75874 |    438.540409 | Zimices                                                                                                                                                               |
| 161 |      61.02321 |    611.851182 | Zimices                                                                                                                                                               |
| 162 |     589.15182 |    630.420395 | Skye McDavid                                                                                                                                                          |
| 163 |     228.97885 |    564.707767 | Matthew E. Clapham                                                                                                                                                    |
| 164 |     364.45133 |    564.028559 | Margot Michaud                                                                                                                                                        |
| 165 |     135.15669 |    454.797262 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 166 |     179.93837 |    233.895476 | NA                                                                                                                                                                    |
| 167 |     718.07463 |    394.601580 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 168 |     171.23683 |    410.387986 | Milton Tan                                                                                                                                                            |
| 169 |     498.96017 |    155.960934 | Chloé Schmidt                                                                                                                                                         |
| 170 |     711.83493 |    151.601154 | Andy Wilson                                                                                                                                                           |
| 171 |     198.01612 |     36.841831 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 172 |     384.07303 |    717.061429 | Dean Schnabel                                                                                                                                                         |
| 173 |     551.06469 |    549.025080 | Matt Crook                                                                                                                                                            |
| 174 |     895.17247 |    789.467923 | Margot Michaud                                                                                                                                                        |
| 175 |     568.88172 |    383.200538 | Gopal Murali                                                                                                                                                          |
| 176 |     437.44532 |    354.080970 | Erika Schumacher                                                                                                                                                      |
| 177 |     536.91504 |    202.759290 | Matt Crook                                                                                                                                                            |
| 178 |      14.00408 |    217.720135 | Mason McNair                                                                                                                                                          |
| 179 |     913.27522 |      8.974053 | Markus A. Grohme                                                                                                                                                      |
| 180 |     712.54922 |    573.081774 | Kamil S. Jaron                                                                                                                                                        |
| 181 |     634.24291 |    688.518500 | Yan Wong                                                                                                                                                              |
| 182 |     643.39052 |    428.279303 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 183 |     688.38401 |    396.980558 | Steven Traver                                                                                                                                                         |
| 184 |     662.68202 |    308.948354 | Markus A. Grohme                                                                                                                                                      |
| 185 |     100.60728 |    114.982953 | NA                                                                                                                                                                    |
| 186 |     832.84371 |    229.052453 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 187 |     734.16094 |    746.846396 | Birgit Lang                                                                                                                                                           |
| 188 |     998.44461 |    617.093212 | Ferran Sayol                                                                                                                                                          |
| 189 |     579.36017 |    360.294836 | Gopal Murali                                                                                                                                                          |
| 190 |     469.01758 |    770.715896 | NA                                                                                                                                                                    |
| 191 |     469.30413 |    665.058357 | Dean Schnabel                                                                                                                                                         |
| 192 |     945.96169 |    660.139901 | Jagged Fang Designs                                                                                                                                                   |
| 193 |     516.92020 |    108.198382 | Joanna Wolfe                                                                                                                                                          |
| 194 |     263.66460 |    102.000959 | Kent Elson Sorgon                                                                                                                                                     |
| 195 |      15.19091 |    184.214482 | T. Michael Keesey                                                                                                                                                     |
| 196 |     933.42573 |    143.196488 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 197 |      40.42633 |    228.784417 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 198 |     565.59898 |    443.493085 | Margot Michaud                                                                                                                                                        |
| 199 |      45.71358 |    318.637213 | Margot Michaud                                                                                                                                                        |
| 200 |     118.87365 |    284.714329 | Gareth Monger                                                                                                                                                         |
| 201 |     137.42730 |    641.144781 | Dmitry Bogdanov                                                                                                                                                       |
| 202 |     861.69705 |    607.825397 | Rebecca Groom                                                                                                                                                         |
| 203 |      21.34368 |    420.701399 | Margot Michaud                                                                                                                                                        |
| 204 |     498.32077 |    278.320608 | Christine Axon                                                                                                                                                        |
| 205 |     320.32322 |    544.100522 | Felix Vaux                                                                                                                                                            |
| 206 |     130.23063 |    482.782823 | Shyamal                                                                                                                                                               |
| 207 |     304.26148 |    497.855200 | NA                                                                                                                                                                    |
| 208 |     377.09694 |    257.363092 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 209 |     990.85578 |    504.889992 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 210 |     156.30502 |    597.982205 | Renata F. Martins                                                                                                                                                     |
| 211 |    1006.95565 |    556.460737 | Steven Traver                                                                                                                                                         |
| 212 |     468.61945 |     13.538162 | Juan Carlos Jerí                                                                                                                                                      |
| 213 |     438.04503 |    163.191291 | Rebecca Groom                                                                                                                                                         |
| 214 |     829.20092 |    141.537174 | Ferran Sayol                                                                                                                                                          |
| 215 |     806.49255 |    662.528176 | Zimices                                                                                                                                                               |
| 216 |     361.29416 |     74.825017 | Roberto Díaz Sibaja                                                                                                                                                   |
| 217 |     863.25280 |     90.082761 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 218 |      24.29643 |     18.953512 | Tasman Dixon                                                                                                                                                          |
| 219 |     327.27584 |     10.882188 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 220 |     902.09262 |    666.501309 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 221 |     209.73262 |    245.067466 | Tasman Dixon                                                                                                                                                          |
| 222 |      31.58602 |    749.945535 | Gopal Murali                                                                                                                                                          |
| 223 |     881.10136 |    590.199914 | Margot Michaud                                                                                                                                                        |
| 224 |     363.65182 |    686.650455 | NA                                                                                                                                                                    |
| 225 |     161.03511 |    748.563007 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 226 |     739.35948 |     84.107652 | Matt Martyniuk                                                                                                                                                        |
| 227 |     648.40051 |    635.392877 | CNZdenek                                                                                                                                                              |
| 228 |    1004.86609 |    365.109849 | Hugo Gruson                                                                                                                                                           |
| 229 |     750.42899 |    280.945515 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 230 |     620.93118 |    421.076755 | Steven Traver                                                                                                                                                         |
| 231 |     810.03370 |    479.150989 | www.studiospectre.com                                                                                                                                                 |
| 232 |     188.36553 |     14.085537 | Gareth Monger                                                                                                                                                         |
| 233 |     843.65562 |    556.840036 | Matt Crook                                                                                                                                                            |
| 234 |     300.36292 |    368.859894 | Michelle Site                                                                                                                                                         |
| 235 |     227.49442 |    543.535776 | Skye M                                                                                                                                                                |
| 236 |      46.80790 |     70.227926 | Crystal Maier                                                                                                                                                         |
| 237 |      72.95980 |    541.596826 | Robert Gay                                                                                                                                                            |
| 238 |     630.45473 |    737.679400 | Matt Crook                                                                                                                                                            |
| 239 |     213.98938 |     52.110572 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 240 |     870.74250 |    625.205034 | Scott Hartman                                                                                                                                                         |
| 241 |     894.81344 |    274.886096 | Chris huh                                                                                                                                                             |
| 242 |     146.79491 |    524.193090 | Michelle Site                                                                                                                                                         |
| 243 |      35.62524 |    341.520395 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 244 |      21.97451 |    241.413991 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 245 |     626.97051 |    778.743612 | Felix Vaux                                                                                                                                                            |
| 246 |     629.58791 |    721.183109 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 247 |    1003.91490 |    469.612924 | Kamil S. Jaron                                                                                                                                                        |
| 248 |     340.06377 |    161.974572 | Matt Crook                                                                                                                                                            |
| 249 |     386.46317 |    459.826215 | Ignacio Contreras                                                                                                                                                     |
| 250 |     530.87485 |    231.553275 | Margot Michaud                                                                                                                                                        |
| 251 |     436.49925 |    334.488294 | Crystal Maier                                                                                                                                                         |
| 252 |     891.44358 |    459.378727 | NA                                                                                                                                                                    |
| 253 |     461.32245 |    305.299949 | Matt Crook                                                                                                                                                            |
| 254 |     929.35025 |     73.699335 | Chris huh                                                                                                                                                             |
| 255 |      20.71536 |    437.053072 | Dmitry Bogdanov                                                                                                                                                       |
| 256 |     642.68948 |     14.979698 | Margot Michaud                                                                                                                                                        |
| 257 |    1014.45510 |    691.008517 | Mason McNair                                                                                                                                                          |
| 258 |     612.62972 |     75.716291 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 259 |     299.79469 |    225.101425 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 260 |     675.57341 |    113.747782 | Sarah Werning                                                                                                                                                         |
| 261 |     185.22067 |    173.921047 | NA                                                                                                                                                                    |
| 262 |     502.76064 |     18.644793 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 263 |      19.48438 |    276.373238 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 264 |     827.80016 |    688.456666 | Caleb M. Brown                                                                                                                                                        |
| 265 |     202.28369 |    362.919765 | Zimices                                                                                                                                                               |
| 266 |     692.89127 |    665.453521 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 267 |     583.96889 |    729.676609 | Ferran Sayol                                                                                                                                                          |
| 268 |     711.00507 |     93.380479 | Scott Reid                                                                                                                                                            |
| 269 |     753.55235 |    759.459470 | Scott Hartman                                                                                                                                                         |
| 270 |     484.51038 |    570.443439 | Mattia Menchetti                                                                                                                                                      |
| 271 |     707.52199 |    536.930560 | Matt Crook                                                                                                                                                            |
| 272 |     411.18840 |    336.167308 | NA                                                                                                                                                                    |
| 273 |    1005.74973 |     77.737449 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 274 |     603.29455 |    576.043135 | Crystal Maier                                                                                                                                                         |
| 275 |     584.42947 |    664.652300 | Steven Traver                                                                                                                                                         |
| 276 |     134.92389 |    360.196385 | Jagged Fang Designs                                                                                                                                                   |
| 277 |     397.17828 |     12.022944 | Zimices                                                                                                                                                               |
| 278 |     215.85895 |    150.283513 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 279 |    1000.35983 |     22.598818 | Kanchi Nanjo                                                                                                                                                          |
| 280 |     561.15036 |    268.033852 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 281 |     820.98373 |    214.010480 | Gareth Monger                                                                                                                                                         |
| 282 |     760.87475 |    442.783754 | Scott Hartman                                                                                                                                                         |
| 283 |      69.82379 |    204.638638 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 284 |     187.94945 |    773.382254 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 285 |     966.02616 |    187.719964 | NA                                                                                                                                                                    |
| 286 |      94.79910 |    419.961709 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 287 |     917.92491 |    261.751147 | Birgit Lang                                                                                                                                                           |
| 288 |     937.02992 |    367.440561 | Benjamint444                                                                                                                                                          |
| 289 |      19.90004 |     31.880389 | Gareth Monger                                                                                                                                                         |
| 290 |     109.54122 |    669.543406 | Zimices                                                                                                                                                               |
| 291 |     841.93075 |    255.593692 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 292 |     689.07197 |    208.649960 | Gareth Monger                                                                                                                                                         |
| 293 |     864.51809 |    275.292825 | Jagged Fang Designs                                                                                                                                                   |
| 294 |     950.57106 |    434.048917 | T. Michael Keesey                                                                                                                                                     |
| 295 |     159.07425 |    296.413435 | Emily Willoughby                                                                                                                                                      |
| 296 |     958.35768 |    279.787725 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 297 |     908.88588 |    586.730658 | Gareth Monger                                                                                                                                                         |
| 298 |     914.58897 |    772.430367 | Birgit Lang                                                                                                                                                           |
| 299 |     759.94293 |    399.711327 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
| 300 |     167.28431 |     56.142641 | Tasman Dixon                                                                                                                                                          |
| 301 |     621.73857 |    760.606220 | Javiera Constanzo                                                                                                                                                     |
| 302 |     827.60542 |     95.066803 | Roberto Díaz Sibaja                                                                                                                                                   |
| 303 |     944.83356 |     85.872575 | Chris huh                                                                                                                                                             |
| 304 |     777.56830 |    187.391740 | Smokeybjb                                                                                                                                                             |
| 305 |     395.51171 |    622.352660 | C. Camilo Julián-Caballero                                                                                                                                            |
| 306 |     500.71871 |    625.982465 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 307 |     368.66064 |    581.494201 | Rebecca Groom                                                                                                                                                         |
| 308 |     801.97296 |    121.808733 | Caleb M. Brown                                                                                                                                                        |
| 309 |     731.23885 |    595.002225 | Sarah Werning                                                                                                                                                         |
| 310 |     453.88782 |    415.977599 | Harold N Eyster                                                                                                                                                       |
| 311 |     790.18656 |    446.953339 | Alexandre Vong                                                                                                                                                        |
| 312 |     158.67892 |    166.686962 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 313 |     893.47868 |    713.986936 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 314 |     675.59606 |    375.073812 | Margot Michaud                                                                                                                                                        |
| 315 |     170.61938 |     29.639436 | Gareth Monger                                                                                                                                                         |
| 316 |     639.26516 |    530.009950 | C. Camilo Julián-Caballero                                                                                                                                            |
| 317 |     904.84127 |    324.927116 | Collin Gross                                                                                                                                                          |
| 318 |     438.72035 |    399.672829 | Matt Crook                                                                                                                                                            |
| 319 |     549.30918 |    181.193474 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 320 |     522.86393 |    185.420725 | Ferran Sayol                                                                                                                                                          |
| 321 |     536.13504 |    638.689833 | Zimices                                                                                                                                                               |
| 322 |    1006.83165 |    394.378567 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 323 |     168.21574 |    363.606655 | Trond R. Oskars                                                                                                                                                       |
| 324 |     658.56884 |    353.449908 | Lafage                                                                                                                                                                |
| 325 |     328.37528 |    513.438950 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 326 |     110.98700 |    690.434492 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 327 |     417.14255 |    197.028051 | Chris huh                                                                                                                                                             |
| 328 |     472.90762 |    214.873377 |                                                                                                                                                                       |
| 329 |     583.44879 |    790.083552 | Tasman Dixon                                                                                                                                                          |
| 330 |     384.42599 |    695.027547 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 331 |     423.16531 |    234.992386 | Chris huh                                                                                                                                                             |
| 332 |     744.15101 |    728.166485 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 333 |     721.48627 |    180.962808 | Matt Crook                                                                                                                                                            |
| 334 |     770.80890 |    783.563163 | Kanchi Nanjo                                                                                                                                                          |
| 335 |     595.52052 |    434.793963 | Chloé Schmidt                                                                                                                                                         |
| 336 |     551.19568 |    764.999394 | Zimices                                                                                                                                                               |
| 337 |     120.40993 |     88.024288 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 338 |     542.52399 |      6.377234 | T. Michael Keesey                                                                                                                                                     |
| 339 |     978.82632 |    559.775287 | T. Michael Keesey                                                                                                                                                     |
| 340 |     492.89479 |    756.147695 | Emily Willoughby                                                                                                                                                      |
| 341 |     552.84963 |    528.629418 | Scott Hartman                                                                                                                                                         |
| 342 |     966.48485 |     23.577358 | Joanna Wolfe                                                                                                                                                          |
| 343 |     563.57522 |    635.981156 | Abraão Leite                                                                                                                                                          |
| 344 |     572.29396 |    105.077037 | Scott Hartman                                                                                                                                                         |
| 345 |     627.03925 |    318.392679 | T. Michael Keesey                                                                                                                                                     |
| 346 |     375.86340 |    425.529937 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 347 |     682.85793 |    577.031866 | Riccardo Percudani                                                                                                                                                    |
| 348 |     198.97014 |    556.732368 | Zimices                                                                                                                                                               |
| 349 |     402.44691 |    100.709256 | Christoph Schomburg                                                                                                                                                   |
| 350 |     860.88705 |    577.601934 | Chris huh                                                                                                                                                             |
| 351 |     585.44271 |    590.718113 | Christina N. Hodson                                                                                                                                                   |
| 352 |     954.54478 |    213.968780 | Gabriele Midolo                                                                                                                                                       |
| 353 |     956.81489 |    680.254175 | Sarah Werning                                                                                                                                                         |
| 354 |     477.67562 |    619.517263 | Matt Crook                                                                                                                                                            |
| 355 |     907.75187 |    551.207197 | Erika Schumacher                                                                                                                                                      |
| 356 |     593.09819 |    261.550677 | Gareth Monger                                                                                                                                                         |
| 357 |     620.83382 |     29.135285 | Tasman Dixon                                                                                                                                                          |
| 358 |     492.70297 |    729.058684 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 359 |     260.44095 |    461.527303 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 360 |     840.43306 |    703.103545 | T. Michael Keesey                                                                                                                                                     |
| 361 |      19.37188 |     57.836790 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 362 |     870.81388 |    755.498672 | Caleb M. Brown                                                                                                                                                        |
| 363 |     826.84987 |    532.168614 | Matt Crook                                                                                                                                                            |
| 364 |     512.93449 |    747.806788 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 365 |      63.41143 |    742.502764 | Jagged Fang Designs                                                                                                                                                   |
| 366 |    1005.49850 |    649.322507 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 367 |     625.82597 |    571.758215 | Scott Hartman                                                                                                                                                         |
| 368 |     176.96112 |    738.450074 | Margot Michaud                                                                                                                                                        |
| 369 |     459.11900 |    128.102909 | Jagged Fang Designs                                                                                                                                                   |
| 370 |     360.43539 |    292.732098 | Birgit Lang                                                                                                                                                           |
| 371 |     168.34632 |    651.657118 | CNZdenek                                                                                                                                                              |
| 372 |     825.77983 |    354.703640 | Zimices                                                                                                                                                               |
| 373 |     119.32808 |    390.984375 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                         |
| 374 |     921.38014 |    420.184896 | L. Shyamal                                                                                                                                                            |
| 375 |     430.76218 |    430.614701 | Florian Pfaff                                                                                                                                                         |
| 376 |     975.45431 |    629.311623 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 377 |     195.74647 |    583.159239 | Margot Michaud                                                                                                                                                        |
| 378 |     543.40768 |    387.889685 | Matt Crook                                                                                                                                                            |
| 379 |     625.86380 |    121.353050 | Rafael Maia                                                                                                                                                           |
| 380 |     331.63491 |     62.578003 | Dmitry Bogdanov                                                                                                                                                       |
| 381 |     822.38161 |    107.835796 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 382 |     471.86178 |    463.724727 | NA                                                                                                                                                                    |
| 383 |     382.55615 |    489.556735 | Matt Crook                                                                                                                                                            |
| 384 |      15.75780 |    507.975716 | Matt Crook                                                                                                                                                            |
| 385 |     353.54606 |    781.780227 | Zimices                                                                                                                                                               |
| 386 |     186.89464 |    687.488842 | Scott Hartman (vectorized by William Gearty)                                                                                                                          |
| 387 |     192.37655 |    665.460792 | Zimices                                                                                                                                                               |
| 388 |     739.57685 |      8.051246 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 389 |     569.42342 |    246.892519 | Ingo Braasch                                                                                                                                                          |
| 390 |     362.35391 |     13.593996 | Jaime Headden                                                                                                                                                         |
| 391 |     694.34142 |    134.350226 | Zimices                                                                                                                                                               |
| 392 |     603.80666 |    478.682509 | Jagged Fang Designs                                                                                                                                                   |
| 393 |     493.79357 |    555.702684 | Emma Kissling                                                                                                                                                         |
| 394 |      28.31462 |    794.275795 | Jagged Fang Designs                                                                                                                                                   |
| 395 |     936.19556 |    618.569858 | NA                                                                                                                                                                    |
| 396 |     343.70193 |    237.485246 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 397 |      66.96751 |    564.063161 | Gareth Monger                                                                                                                                                         |
| 398 |     298.18244 |     93.837498 | Margot Michaud                                                                                                                                                        |
| 399 |     888.72441 |     22.194611 | Ingo Braasch                                                                                                                                                          |
| 400 |     477.36560 |    362.811879 | Bruno Maggia                                                                                                                                                          |
| 401 |     791.96053 |    403.218051 | Matt Crook                                                                                                                                                            |
| 402 |     818.53408 |    716.425101 | Steven Traver                                                                                                                                                         |
| 403 |     222.78704 |    788.921765 | Chris huh                                                                                                                                                             |
| 404 |     597.84751 |    743.987399 | Maija Karala                                                                                                                                                          |
| 405 |     365.03119 |     94.463088 | Josefine Bohr Brask                                                                                                                                                   |
| 406 |     441.20774 |      8.982064 | Zimices                                                                                                                                                               |
| 407 |     860.46268 |    565.101725 | Martin Kevil                                                                                                                                                          |
| 408 |     691.72970 |    231.381531 | John Conway                                                                                                                                                           |
| 409 |     408.07446 |    123.565461 | Scott Hartman                                                                                                                                                         |
| 410 |     429.75946 |    772.910437 | Tasman Dixon                                                                                                                                                          |
| 411 |     479.65867 |     77.650287 | Milton Tan                                                                                                                                                            |
| 412 |      88.84577 |     93.802425 | T. Michael Keesey                                                                                                                                                     |
| 413 |     979.58759 |     37.310455 | NA                                                                                                                                                                    |
| 414 |     151.30300 |    775.694743 | Matt Crook                                                                                                                                                            |
| 415 |     985.66637 |    410.571510 | Martin R. Smith                                                                                                                                                       |
| 416 |     881.55916 |    549.264963 | Arthur S. Brum                                                                                                                                                        |
| 417 |     781.68119 |    313.632779 | Anthony Caravaggi                                                                                                                                                     |
| 418 |     785.64295 |    471.124562 | Scott Hartman                                                                                                                                                         |
| 419 |     894.37359 |    736.247325 | L. Shyamal                                                                                                                                                            |
| 420 |     896.57846 |    365.578941 | Collin Gross                                                                                                                                                          |
| 421 |     966.64797 |    318.953341 | Iain Reid                                                                                                                                                             |
| 422 |     705.66681 |    603.532019 | Sarah Werning                                                                                                                                                         |
| 423 |     322.81651 |    785.678446 | Margot Michaud                                                                                                                                                        |
| 424 |     819.69751 |    129.142332 | Sarah Werning                                                                                                                                                         |
| 425 |      33.42122 |    544.114200 | Zimices                                                                                                                                                               |
| 426 |     341.66490 |    200.296347 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 427 |     210.58197 |     25.455552 | Mike Hanson                                                                                                                                                           |
| 428 |     169.13115 |    639.847973 | Jagged Fang Designs                                                                                                                                                   |
| 429 |     197.14552 |    470.412079 | Robert Gay                                                                                                                                                            |
| 430 |      19.91446 |    646.748168 | Chris huh                                                                                                                                                             |
| 431 |     392.24501 |    311.441755 | Michael P. Taylor                                                                                                                                                     |
| 432 |     905.38646 |    761.992915 | Tracy A. Heath                                                                                                                                                        |
| 433 |      88.43365 |    496.764057 | Zimices                                                                                                                                                               |
| 434 |      94.07454 |    551.480247 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 435 |     846.35991 |    475.742957 | Emma Kissling                                                                                                                                                         |
| 436 |     102.07788 |    432.094094 | Darius Nau                                                                                                                                                            |
| 437 |     720.40705 |    200.501315 | Scott Hartman                                                                                                                                                         |
| 438 |     842.62732 |    620.859173 | Scott Hartman                                                                                                                                                         |
| 439 |      19.57228 |     91.482650 | Chris huh                                                                                                                                                             |
| 440 |     998.10917 |    277.429416 | Smokeybjb                                                                                                                                                             |
| 441 |     612.06750 |     49.976454 | John Conway                                                                                                                                                           |
| 442 |     383.36880 |    778.320493 | Tracy A. Heath                                                                                                                                                        |
| 443 |     401.95847 |    437.070249 | T. Michael Keesey                                                                                                                                                     |
| 444 |     439.28903 |    552.206137 | Mo Hassan                                                                                                                                                             |
| 445 |      21.55482 |    663.272304 | Jagged Fang Designs                                                                                                                                                   |
| 446 |     698.50118 |    614.536091 | Jagged Fang Designs                                                                                                                                                   |
| 447 |     447.73018 |    108.921143 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 448 |     860.70744 |    737.492559 | Jagged Fang Designs                                                                                                                                                   |
| 449 |     651.87387 |    705.426404 | Maija Karala                                                                                                                                                          |
| 450 |     295.18781 |      6.382636 | Erika Schumacher                                                                                                                                                      |
| 451 |     142.20278 |    320.423820 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 452 |     124.35694 |    783.216283 | Matt Crook                                                                                                                                                            |
| 453 |     792.50569 |    181.959034 | Birgit Lang                                                                                                                                                           |
| 454 |      92.46697 |    205.067893 | NA                                                                                                                                                                    |
| 455 |     918.83066 |     20.894912 | Ignacio Contreras                                                                                                                                                     |
| 456 |     684.44941 |    566.971425 | Chris huh                                                                                                                                                             |
| 457 |     142.91259 |    150.030977 | Pete Buchholz                                                                                                                                                         |
| 458 |     981.81310 |    786.353737 | Scott Hartman                                                                                                                                                         |
| 459 |     734.03019 |    445.883762 | Markus A. Grohme                                                                                                                                                      |
| 460 |     299.30675 |    208.179938 | Emily Willoughby                                                                                                                                                      |
| 461 |     395.78546 |    562.032329 | Roberto Díaz Sibaja                                                                                                                                                   |
| 462 |     699.64802 |    792.880958 | Tasman Dixon                                                                                                                                                          |
| 463 |     342.99604 |    550.718277 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 464 |     651.18174 |    292.829411 | Matt Crook                                                                                                                                                            |
| 465 |     791.89506 |    220.615020 | NA                                                                                                                                                                    |
| 466 |     525.71826 |    282.755308 | C. Camilo Julián-Caballero                                                                                                                                            |
| 467 |     641.24327 |    757.997348 | Caleb M. Brown                                                                                                                                                        |
| 468 |     438.98228 |    377.275469 | Dean Schnabel                                                                                                                                                         |
| 469 |     839.03292 |    794.118311 | Chris huh                                                                                                                                                             |
| 470 |     444.05185 |    752.013527 | Zimices                                                                                                                                                               |
| 471 |     734.22959 |    382.599614 | Iain Reid                                                                                                                                                             |
| 472 |     794.07916 |    682.927254 | Melissa Broussard                                                                                                                                                     |
| 473 |     910.03421 |    541.314631 | Jagged Fang Designs                                                                                                                                                   |
| 474 |      77.61765 |    310.978350 | Tasman Dixon                                                                                                                                                          |
| 475 |     332.76487 |    740.762735 | Noah Schlottman                                                                                                                                                       |
| 476 |     617.73604 |    258.390450 | C. Camilo Julián-Caballero                                                                                                                                            |
| 477 |     942.56398 |    329.175276 | Gareth Monger                                                                                                                                                         |
| 478 |     743.58358 |    705.275555 | Noah Schlottman                                                                                                                                                       |
| 479 |     442.06589 |    294.524110 | Matt Crook                                                                                                                                                            |
| 480 |     225.35300 |    747.251128 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 481 |     126.22833 |    106.980027 | Shyamal                                                                                                                                                               |
| 482 |     698.86547 |    344.773182 | Beth Reinke                                                                                                                                                           |
| 483 |     928.88182 |    788.981761 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 484 |     638.18291 |    108.362443 | Scott Hartman                                                                                                                                                         |
| 485 |     320.34283 |    102.854084 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 486 |     913.54439 |    384.247814 | Scott Hartman                                                                                                                                                         |
| 487 |     766.65754 |     95.393821 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 488 |     902.01729 |    333.830159 | NA                                                                                                                                                                    |
| 489 |     352.92028 |    399.257765 | Matt Crook                                                                                                                                                            |
| 490 |     830.78148 |    752.298942 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 491 |     149.18833 |      5.662771 | SauropodomorphMonarch                                                                                                                                                 |
| 492 |     596.37154 |    110.309820 | NA                                                                                                                                                                    |
| 493 |      16.65328 |    589.854019 | NA                                                                                                                                                                    |
| 494 |     738.19106 |    687.222693 | Caleb M. Brown                                                                                                                                                        |
| 495 |      88.00396 |    231.710073 | FunkMonk                                                                                                                                                              |
| 496 |     140.24455 |    218.781510 | Margot Michaud                                                                                                                                                        |
| 497 |    1007.37476 |    285.619996 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 498 |      12.71477 |    626.080593 | Kamil S. Jaron                                                                                                                                                        |
| 499 |     666.25033 |    426.285649 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 500 |     584.57648 |    152.325410 | Ignacio Contreras                                                                                                                                                     |
| 501 |     180.69924 |    544.062623 | FunkMonk                                                                                                                                                              |
| 502 |     256.40944 |    419.619970 | Zachary Quigley                                                                                                                                                       |
| 503 |     659.27431 |    404.585426 | NA                                                                                                                                                                    |
| 504 |     488.03536 |    781.480037 | M Kolmann                                                                                                                                                             |
| 505 |     941.72319 |    669.846206 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 506 |     309.83589 |    375.566047 | Markus A. Grohme                                                                                                                                                      |
| 507 |     585.89762 |      9.681132 | NA                                                                                                                                                                    |
| 508 |      46.26435 |    699.379601 | Abraão B. Leite                                                                                                                                                       |
| 509 |     656.32492 |     32.781658 | Matt Dempsey                                                                                                                                                          |
| 510 |     249.50339 |     63.174145 | Erika Schumacher                                                                                                                                                      |
| 511 |     249.01603 |    528.019779 | Sarah Werning                                                                                                                                                         |
| 512 |     561.20849 |    469.276508 | Emily Willoughby                                                                                                                                                      |
| 513 |     677.90532 |     41.786812 | Matt Dempsey                                                                                                                                                          |
| 514 |     732.72334 |    629.709005 | Margot Michaud                                                                                                                                                        |
| 515 |     975.72868 |     74.439867 | Gareth Monger                                                                                                                                                         |
| 516 |     531.39538 |    737.698411 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 517 |     193.27572 |    760.744551 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 518 |     805.68278 |    346.419264 | Zimices                                                                                                                                                               |
| 519 |     980.46037 |    452.340536 | Caleb M. Brown                                                                                                                                                        |
| 520 |     562.80472 |    676.943005 | Armin Reindl                                                                                                                                                          |
| 521 |     522.42903 |    578.255876 | Armin Reindl                                                                                                                                                          |
| 522 |     398.90331 |    399.424756 | Andrés Sánchez                                                                                                                                                        |
| 523 |      25.04717 |    616.866757 | NA                                                                                                                                                                    |
| 524 |     512.74967 |    385.061735 | Jack Mayer Wood                                                                                                                                                       |
| 525 |     168.91227 |    792.867072 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 526 |     583.28219 |    346.871091 | Gareth Monger                                                                                                                                                         |
| 527 |     696.75196 |    491.025920 | SauropodomorphMonarch                                                                                                                                                 |
| 528 |     412.52073 |    321.839111 | CNZdenek                                                                                                                                                              |
| 529 |     923.39457 |    185.339033 | Mathew Wedel                                                                                                                                                          |
| 530 |     454.48988 |     35.508088 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 531 |     236.46158 |    332.787366 | Zimices                                                                                                                                                               |
| 532 |     553.46489 |    320.187342 | Margot Michaud                                                                                                                                                        |
| 533 |     134.91539 |    471.877753 | NA                                                                                                                                                                    |
| 534 |     389.65543 |    469.142888 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 535 |     512.26864 |    465.989996 | Jagged Fang Designs                                                                                                                                                   |
| 536 |     400.38246 |     66.022597 | Collin Gross                                                                                                                                                          |
| 537 |     980.67815 |      7.632879 | Jagged Fang Designs                                                                                                                                                   |
| 538 |     335.20749 |    353.304663 | Zachary Quigley                                                                                                                                                       |
| 539 |      19.99771 |    731.063268 | Markus A. Grohme                                                                                                                                                      |
| 540 |     307.34578 |     64.023495 | Margot Michaud                                                                                                                                                        |
| 541 |     733.95942 |    300.564134 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 542 |     669.65002 |    331.303482 | Gareth Monger                                                                                                                                                         |
| 543 |     475.61161 |    543.340381 | Chris huh                                                                                                                                                             |
| 544 |     163.41761 |    397.785520 | Rene Martin                                                                                                                                                           |
| 545 |    1001.26642 |    338.713292 | Scott Hartman                                                                                                                                                         |

    #> Your tweet has been posted!
