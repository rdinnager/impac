
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

Michael P. Taylor, V. Deepak, Noah Schlottman, Andy Wilson, Dean
Schnabel, Markus A. Grohme, Noah Schlottman, photo from Casey Dunn, Mark
Hofstetter (vectorized by T. Michael Keesey), Emily Willoughby, Margot
Michaud, Zimices, Matt Crook, Gareth Monger, T. Michael Keesey,
Ghedoghedo (vectorized by T. Michael Keesey), Michelle Site, Caio
Bernardes, vectorized by Zimices, Harold N Eyster, Tony Ayling
(vectorized by T. Michael Keesey), Jagged Fang Designs, Ferran Sayol,
George Edward Lodge (modified by T. Michael Keesey), Dmitry Bogdanov
(modified by T. Michael Keesey), Ludwik Gasiorowski, Juan Carlos Jerí,
Scott Hartman, Vanessa Guerra, Melissa Broussard, Matt Martyniuk
(modified by T. Michael Keesey), Smokeybjb, Felix Vaux, Brad McFeeters
(vectorized by T. Michael Keesey), Tasman Dixon, Joris van der Ham
(vectorized by T. Michael Keesey), Becky Barnes, Cesar Julian, Mali’o
Kodis, traced image from the National Science Foundation’s Turbellarian
Taxonomic Database, L. Shyamal, Noah Schlottman, photo by Antonio
Guillén, Nobu Tamura, modified by Andrew A. Farke, Chris huh,
Lukasiniho, Lukas Panzarin, Ingo Braasch, Pranav Iyer (grey ideas), Iain
Reid, Joanna Wolfe, xgirouxb, Gabriela Palomo-Munoz, Walter Vladimir,
Tomas Willems (vectorized by T. Michael Keesey), Christoph Schomburg,
Shyamal, Kailah Thorn & Mark Hutchinson, Maija Karala, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Steven Traver, Nobu Tamura
(vectorized by T. Michael Keesey), Yan Wong, Manabu Bessho-Uehara,
Ignacio Contreras, Gustav Mützel, Birgit Lang, Noah Schlottman, photo by
Martin V. Sørensen, Tauana J. Cunha, Zachary Quigley, Michele M Tobias,
Jake Warner, Collin Gross, Alexander Schmidt-Lebuhn, Mali’o Kodis,
photograph by Hans Hillewaert, Armin Reindl, Steven Coombs, Michael
Scroggie, Mathew Wedel, Michael B. H. (vectorized by T. Michael Keesey),
CNZdenek, Ben Liebeskind, Fritz Geller-Grimm (vectorized by T. Michael
Keesey), James R. Spotila and Ray Chatterji, Joseph Smit (modified by T.
Michael Keesey), B Kimmel, Carlos Cano-Barbacil, Erika Schumacher,
Manabu Sakamoto, Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric
M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Matt
Dempsey, Beth Reinke, nicubunu, Tommaso Cancellario, Pedro de Siracusa,
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Chase Brownstein, Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, Noah Schlottman, photo from National Science
Foundation - Turbellarian Taxonomic Database, Tracy A. Heath, Ryan Cupo,
T. Michael Keesey (after Heinrich Harder), Smith609 and T. Michael
Keesey, U.S. Fish and Wildlife Service (illustration) and Timothy J.
Bartley (silhouette), Kailah Thorn & Ben King, FunkMonk, Nobu Tamura
(modified by T. Michael Keesey), NASA, Xavier Giroux-Bougard, Mark
Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, C. Camilo Julián-Caballero, Tony Ayling, Mali’o Kodis,
drawing by Manvir Singh, Dmitry Bogdanov, vectorized by Zimices, Daniel
Stadtmauer, Rebecca Groom, Taenadoman, Patrick Strutzenberger, Chloé
Schmidt, Kamil S. Jaron, Noah Schlottman, photo by David J Patterson,
Benchill, Renato Santos, Dmitry Bogdanov, Ernst Haeckel (vectorized by
T. Michael Keesey), Katie S. Collins, Hugo Gruson, Roberto Díaz Sibaja,
Karla Martinez, T. Michael Keesey (after Ponomarenko), John Gould
(vectorized by T. Michael Keesey), Campbell Fleming, Arthur S. Brum,
Alex Slavenko, Nobu Tamura, vectorized by Zimices, Sean McCann, Sarah
Werning, Falconaumanni and T. Michael Keesey, Trond R. Oskars, Steven
Haddock • Jellywatch.org, S.Martini, Smokeybjb (vectorized by T. Michael
Keesey), Jack Mayer Wood, Javier Luque & Sarah Gerken, Matt Martyniuk
(modified by Serenchia), E. J. Van Nieukerken, A. Laštuvka, and Z.
Laštuvka (vectorized by T. Michael Keesey), Sergio A. Muñoz-Gómez, Jan
A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Christopher Chávez, Joseph J. W.
Sertich, Mark A. Loewen, Kai R. Caspar, Jaime Headden, T. Michael Keesey
(after Monika Betley), Filip em, Eric Moody, Agnello Picorelli, Neil
Kelley, Nick Schooler, Michael Ströck (vectorized by T. Michael Keesey),
NOAA Great Lakes Environmental Research Laboratory (illustration) and
Timothy J. Bartley (silhouette), Duane Raver (vectorized by T. Michael
Keesey), Darius Nau, Rachel Shoop, Andrés Sánchez, Kent Elson Sorgon, Mo
Hassan, C. Abraczinskas, Chuanixn Yu, Philip Chalmers (vectorized by T.
Michael Keesey), Mali’o Kodis, image by Rebecca Ritger, Robert Bruce
Horsfall (vectorized by T. Michael Keesey), Anthony Caravaggi, Matt
Martyniuk, T. Michael Keesey (after Mauricio Antón), Renata F. Martins,
Obsidian Soul (vectorized by T. Michael Keesey), Stephen O’Connor
(vectorized by T. Michael Keesey), Yan Wong from illustration by Jules
Richard (1907), Noah Schlottman, photo by Casey Dunn, J. J. Harrison
(photo) & T. Michael Keesey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    810.552264 |    381.785360 | Michael P. Taylor                                                                                                                                              |
|   2 |    219.221870 |     57.519938 | V. Deepak                                                                                                                                                      |
|   3 |    427.543704 |    158.394714 | Noah Schlottman                                                                                                                                                |
|   4 |    813.453414 |    293.359862 | NA                                                                                                                                                             |
|   5 |     66.104280 |    148.958550 | Andy Wilson                                                                                                                                                    |
|   6 |    436.926642 |    709.208673 | Dean Schnabel                                                                                                                                                  |
|   7 |    837.281082 |    450.822631 | Markus A. Grohme                                                                                                                                               |
|   8 |    592.067051 |    140.145259 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
|   9 |    220.054355 |    497.147242 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                              |
|  10 |    916.979410 |    651.308011 | Emily Willoughby                                                                                                                                               |
|  11 |    754.452104 |    659.210705 | Margot Michaud                                                                                                                                                 |
|  12 |    459.282329 |    522.771488 | Zimices                                                                                                                                                        |
|  13 |    299.901144 |    531.287711 | Matt Crook                                                                                                                                                     |
|  14 |    904.957458 |    191.442709 | Gareth Monger                                                                                                                                                  |
|  15 |    450.540326 |    602.970046 | Emily Willoughby                                                                                                                                               |
|  16 |    190.176532 |    685.109054 | T. Michael Keesey                                                                                                                                              |
|  17 |    625.166509 |    552.437438 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
|  18 |    414.429510 |    303.109547 | Michelle Site                                                                                                                                                  |
|  19 |    486.907692 |    421.488029 | Matt Crook                                                                                                                                                     |
|  20 |     61.093530 |    478.326055 | Caio Bernardes, vectorized by Zimices                                                                                                                          |
|  21 |    963.333991 |    394.993304 | Harold N Eyster                                                                                                                                                |
|  22 |     74.154171 |     49.185670 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
|  23 |    636.511638 |    332.768298 | Jagged Fang Designs                                                                                                                                            |
|  24 |    811.018875 |     51.288579 | Matt Crook                                                                                                                                                     |
|  25 |    653.024719 |    257.575445 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
|  26 |    116.913553 |    246.392109 | Margot Michaud                                                                                                                                                 |
|  27 |    913.841018 |    481.334932 | NA                                                                                                                                                             |
|  28 |    949.377128 |    122.641708 | Ferran Sayol                                                                                                                                                   |
|  29 |    326.574429 |    334.632313 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                            |
|  30 |    524.352824 |    259.374665 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                |
|  31 |    739.016572 |    113.321792 | Ludwik Gasiorowski                                                                                                                                             |
|  32 |     91.927060 |    535.425041 | Juan Carlos Jerí                                                                                                                                               |
|  33 |    161.001432 |    178.496630 | Scott Hartman                                                                                                                                                  |
|  34 |    247.349079 |    752.260563 | Vanessa Guerra                                                                                                                                                 |
|  35 |    121.064914 |    382.667219 | Melissa Broussard                                                                                                                                              |
|  36 |    467.686022 |     54.842137 | Ferran Sayol                                                                                                                                                   |
|  37 |     71.124731 |    747.246993 | Gareth Monger                                                                                                                                                  |
|  38 |    952.343772 |    724.612518 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                 |
|  39 |    943.677921 |    299.115805 | Michelle Site                                                                                                                                                  |
|  40 |    804.793022 |    223.925495 | Smokeybjb                                                                                                                                                      |
|  41 |    551.124581 |    644.806471 | Felix Vaux                                                                                                                                                     |
|  42 |    651.517993 |    628.223239 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
|  43 |    226.599530 |    608.926956 | Tasman Dixon                                                                                                                                                   |
|  44 |    320.204021 |    651.762961 | Matt Crook                                                                                                                                                     |
|  45 |    811.151318 |    555.041902 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                            |
|  46 |    582.991464 |    761.024256 | Gareth Monger                                                                                                                                                  |
|  47 |    582.622371 |    358.769419 | Ferran Sayol                                                                                                                                                   |
|  48 |    633.663015 |    443.023821 | Becky Barnes                                                                                                                                                   |
|  49 |    772.329096 |    758.584913 | Cesar Julian                                                                                                                                                   |
|  50 |    261.738378 |    231.640836 | Andy Wilson                                                                                                                                                    |
|  51 |    718.612544 |    191.941997 | Gareth Monger                                                                                                                                                  |
|  52 |    994.481217 |    535.193336 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                              |
|  53 |    615.905293 |    685.385343 | Markus A. Grohme                                                                                                                                               |
|  54 |     94.296308 |    633.575741 | L. Shyamal                                                                                                                                                     |
|  55 |    220.841504 |    320.076596 | T. Michael Keesey                                                                                                                                              |
|  56 |    879.307928 |    589.310760 | Noah Schlottman, photo by Antonio Guillén                                                                                                                      |
|  57 |    786.192857 |    525.097012 | Felix Vaux                                                                                                                                                     |
|  58 |    872.026194 |     79.153015 | Gareth Monger                                                                                                                                                  |
|  59 |    345.279620 |    413.083126 | Matt Crook                                                                                                                                                     |
|  60 |    756.651350 |    729.182145 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                       |
|  61 |    105.353648 |    206.739329 | Cesar Julian                                                                                                                                                   |
|  62 |    383.391036 |     13.977082 | NA                                                                                                                                                             |
|  63 |    564.847752 |    487.816867 | Scott Hartman                                                                                                                                                  |
|  64 |    370.400189 |    779.409877 | Jagged Fang Designs                                                                                                                                            |
|  65 |    896.419861 |    525.212339 | NA                                                                                                                                                             |
|  66 |    256.286586 |    194.381501 | Scott Hartman                                                                                                                                                  |
|  67 |    336.922126 |    109.487365 | Chris huh                                                                                                                                                      |
|  68 |    202.714792 |    139.190558 | Lukasiniho                                                                                                                                                     |
|  69 |     76.016128 |    287.735128 | NA                                                                                                                                                             |
|  70 |    370.820398 |    530.088205 | T. Michael Keesey                                                                                                                                              |
|  71 |    705.344582 |    264.555434 | T. Michael Keesey                                                                                                                                              |
|  72 |    392.200871 |    241.303623 | Lukas Panzarin                                                                                                                                                 |
|  73 |    679.485885 |    466.182346 | Ingo Braasch                                                                                                                                                   |
|  74 |    469.748821 |    342.976541 | NA                                                                                                                                                             |
|  75 |    958.897085 |     32.775786 | Markus A. Grohme                                                                                                                                               |
|  76 |    947.392663 |    238.476134 | Pranav Iyer (grey ideas)                                                                                                                                       |
|  77 |    706.003901 |     28.768369 | Emily Willoughby                                                                                                                                               |
|  78 |    824.377017 |    659.005399 | T. Michael Keesey                                                                                                                                              |
|  79 |    598.691355 |     23.382290 | Smokeybjb                                                                                                                                                      |
|  80 |    655.746592 |    121.269014 | T. Michael Keesey                                                                                                                                              |
|  81 |    501.645021 |    191.066474 | Iain Reid                                                                                                                                                      |
|  82 |     37.379944 |    437.681663 | Joanna Wolfe                                                                                                                                                   |
|  83 |    295.909749 |    133.766124 | Michael P. Taylor                                                                                                                                              |
|  84 |    891.105900 |    764.832679 | Margot Michaud                                                                                                                                                 |
|  85 |    917.278532 |    150.416731 | xgirouxb                                                                                                                                                       |
|  86 |    979.260174 |    347.620434 | Zimices                                                                                                                                                        |
|  87 |    892.764893 |    413.721895 | Gabriela Palomo-Munoz                                                                                                                                          |
|  88 |    750.565139 |    574.438938 | Walter Vladimir                                                                                                                                                |
|  89 |    677.928808 |    381.382626 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                |
|  90 |    478.017649 |    670.754879 | Christoph Schomburg                                                                                                                                            |
|  91 |    165.843234 |    745.377704 | Shyamal                                                                                                                                                        |
|  92 |    938.470767 |    688.944703 | Zimices                                                                                                                                                        |
|  93 |    333.384152 |    702.251151 | Zimices                                                                                                                                                        |
|  94 |    225.679211 |    261.920298 | Kailah Thorn & Mark Hutchinson                                                                                                                                 |
|  95 |    837.537059 |    161.108777 | Maija Karala                                                                                                                                                   |
|  96 |    953.785202 |    266.990779 | Matt Crook                                                                                                                                                     |
|  97 |    383.607617 |    659.723391 | Ferran Sayol                                                                                                                                                   |
|  98 |     95.265343 |    455.405117 | Jagged Fang Designs                                                                                                                                            |
|  99 |    321.372435 |    278.528523 | Zimices                                                                                                                                                        |
| 100 |    241.518822 |    173.400284 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 101 |    554.631022 |    523.903870 | Juan Carlos Jerí                                                                                                                                               |
| 102 |    468.566960 |    106.605131 | Steven Traver                                                                                                                                                  |
| 103 |    512.726636 |    734.398266 | Zimices                                                                                                                                                        |
| 104 |    349.944371 |    748.798971 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 105 |    168.375418 |    539.856440 | Yan Wong                                                                                                                                                       |
| 106 |    218.573820 |    292.551917 | Manabu Bessho-Uehara                                                                                                                                           |
| 107 |    150.056877 |    577.384657 | Ferran Sayol                                                                                                                                                   |
| 108 |    183.140602 |     26.065556 | Steven Traver                                                                                                                                                  |
| 109 |    880.688891 |    285.115161 | Zimices                                                                                                                                                        |
| 110 |    338.323079 |    729.849700 | Ignacio Contreras                                                                                                                                              |
| 111 |    757.496742 |    482.483267 | Chris huh                                                                                                                                                      |
| 112 |    927.140696 |    329.875805 | Gustav Mützel                                                                                                                                                  |
| 113 |   1014.104010 |    185.793995 | Gabriela Palomo-Munoz                                                                                                                                          |
| 114 |     16.572733 |    563.870338 | T. Michael Keesey                                                                                                                                              |
| 115 |    184.785111 |    503.671140 | Chris huh                                                                                                                                                      |
| 116 |    529.400551 |    554.060843 | Birgit Lang                                                                                                                                                    |
| 117 |    650.859469 |    725.324186 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                   |
| 118 |     30.555770 |    247.331052 | Harold N Eyster                                                                                                                                                |
| 119 |   1008.706788 |    728.718238 | Tauana J. Cunha                                                                                                                                                |
| 120 |    201.652946 |    100.779028 | Gareth Monger                                                                                                                                                  |
| 121 |    941.730533 |    706.760162 | Zachary Quigley                                                                                                                                                |
| 122 |    635.729691 |    381.899543 | Gareth Monger                                                                                                                                                  |
| 123 |    808.315684 |    684.694895 | Michele M Tobias                                                                                                                                               |
| 124 |    479.710817 |    635.568669 | xgirouxb                                                                                                                                                       |
| 125 |    776.964007 |    695.146090 | Matt Crook                                                                                                                                                     |
| 126 |    581.447448 |    647.283040 | Jake Warner                                                                                                                                                    |
| 127 |    575.017225 |    723.681519 | Collin Gross                                                                                                                                                   |
| 128 |    386.136195 |     66.084051 | Michael P. Taylor                                                                                                                                              |
| 129 |    289.209011 |    793.171187 | Jagged Fang Designs                                                                                                                                            |
| 130 |    195.484011 |    398.236715 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 131 |    558.220425 |    506.567718 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 132 |    661.296534 |    773.689609 | Margot Michaud                                                                                                                                                 |
| 133 |    978.224402 |    212.078426 | Matt Crook                                                                                                                                                     |
| 134 |    754.088937 |    260.683164 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                    |
| 135 |    525.423536 |     81.416332 | Matt Crook                                                                                                                                                     |
| 136 |    821.276449 |    103.223011 | Markus A. Grohme                                                                                                                                               |
| 137 |    852.373264 |    406.840403 | Armin Reindl                                                                                                                                                   |
| 138 |    749.614198 |     63.513329 | Matt Crook                                                                                                                                                     |
| 139 |    746.745772 |    312.603735 | Gareth Monger                                                                                                                                                  |
| 140 |    368.119608 |     28.652666 | Chris huh                                                                                                                                                      |
| 141 |     32.409146 |    328.020978 | Markus A. Grohme                                                                                                                                               |
| 142 |    733.915671 |     19.298069 | Steven Coombs                                                                                                                                                  |
| 143 |    723.448317 |    428.698011 | Maija Karala                                                                                                                                                   |
| 144 |    710.359444 |    516.631085 | Michael Scroggie                                                                                                                                               |
| 145 |    181.496875 |    237.919428 | Zimices                                                                                                                                                        |
| 146 |    956.711097 |    448.104891 | Chris huh                                                                                                                                                      |
| 147 |    715.730772 |    342.438616 | Ignacio Contreras                                                                                                                                              |
| 148 |    291.515446 |    455.888552 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 149 |    154.199117 |    725.739896 | Mathew Wedel                                                                                                                                                   |
| 150 |    925.564790 |    614.396041 | Scott Hartman                                                                                                                                                  |
| 151 |    397.040892 |    457.826138 | T. Michael Keesey                                                                                                                                              |
| 152 |    658.571488 |    750.526059 | Gabriela Palomo-Munoz                                                                                                                                          |
| 153 |   1005.490785 |    134.417956 | T. Michael Keesey                                                                                                                                              |
| 154 |    636.894141 |    319.203499 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
| 155 |    804.931304 |     16.527304 | CNZdenek                                                                                                                                                       |
| 156 |    855.077956 |    697.861083 | Ben Liebeskind                                                                                                                                                 |
| 157 |    528.689493 |    395.732583 | Melissa Broussard                                                                                                                                              |
| 158 |    344.598592 |     51.426966 | Ferran Sayol                                                                                                                                                   |
| 159 |     75.183337 |    100.925965 | T. Michael Keesey                                                                                                                                              |
| 160 |    513.396961 |    769.961860 | Ferran Sayol                                                                                                                                                   |
| 161 |    169.146923 |    634.954029 | Ferran Sayol                                                                                                                                                   |
| 162 |    874.240364 |    689.989123 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                           |
| 163 |   1008.680412 |    458.088119 | NA                                                                                                                                                             |
| 164 |    625.904320 |    712.224554 | Jagged Fang Designs                                                                                                                                            |
| 165 |    134.213987 |    287.471725 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 166 |    893.395624 |    342.306599 | Chris huh                                                                                                                                                      |
| 167 |     31.197888 |    379.690966 | Zimices                                                                                                                                                        |
| 168 |    303.486823 |     77.746628 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                    |
| 169 |    433.786781 |    786.427794 | B Kimmel                                                                                                                                                       |
| 170 |    796.579221 |    474.945429 | Carlos Cano-Barbacil                                                                                                                                           |
| 171 |    404.949869 |    547.309696 | Ferran Sayol                                                                                                                                                   |
| 172 |    233.082952 |     35.640744 | T. Michael Keesey                                                                                                                                              |
| 173 |    549.493408 |    301.210239 | Margot Michaud                                                                                                                                                 |
| 174 |    550.339253 |    564.571845 | Gareth Monger                                                                                                                                                  |
| 175 |    236.465181 |    659.633507 | Erika Schumacher                                                                                                                                               |
| 176 |    421.653328 |    286.238590 | Gareth Monger                                                                                                                                                  |
| 177 |    362.440875 |    315.893806 | T. Michael Keesey                                                                                                                                              |
| 178 |    699.441674 |    553.232178 | Manabu Sakamoto                                                                                                                                                |
| 179 |    499.541327 |     85.417041 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                       |
| 180 |   1014.760017 |    671.538112 | Joanna Wolfe                                                                                                                                                   |
| 181 |    835.103210 |    495.019274 | Matt Dempsey                                                                                                                                                   |
| 182 |     23.445898 |    348.881842 | Zimices                                                                                                                                                        |
| 183 |     20.985114 |    636.465996 | Matt Crook                                                                                                                                                     |
| 184 |     38.538263 |    687.545808 | L. Shyamal                                                                                                                                                     |
| 185 |    789.870441 |    183.097531 | Matt Crook                                                                                                                                                     |
| 186 |    457.580747 |    560.638031 | Margot Michaud                                                                                                                                                 |
| 187 |    266.029474 |    499.342173 | Beth Reinke                                                                                                                                                    |
| 188 |    387.757730 |     82.872905 | Steven Traver                                                                                                                                                  |
| 189 |    277.347780 |    636.697918 | Ferran Sayol                                                                                                                                                   |
| 190 |    975.103911 |    766.312946 | nicubunu                                                                                                                                                       |
| 191 |    142.282901 |    465.455213 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 192 |    743.002536 |    344.056215 | Matt Crook                                                                                                                                                     |
| 193 |    962.844204 |    603.093256 | Tommaso Cancellario                                                                                                                                            |
| 194 |    285.554722 |    479.354638 | NA                                                                                                                                                             |
| 195 |    331.053678 |    268.661398 | T. Michael Keesey                                                                                                                                              |
| 196 |    487.700163 |    706.719382 | Tasman Dixon                                                                                                                                                   |
| 197 |    673.205344 |    699.607589 | Ferran Sayol                                                                                                                                                   |
| 198 |    268.796272 |    382.507065 | Pedro de Siracusa                                                                                                                                              |
| 199 |     84.474531 |    272.724000 | Scott Hartman                                                                                                                                                  |
| 200 |    428.299482 |    348.708059 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 201 |    550.879489 |    203.891913 | Ignacio Contreras                                                                                                                                              |
| 202 |    243.695118 |    482.346438 | NA                                                                                                                                                             |
| 203 |    461.425811 |    137.771664 | Tasman Dixon                                                                                                                                                   |
| 204 |    786.993632 |    162.059571 | Markus A. Grohme                                                                                                                                               |
| 205 |    670.460548 |    328.676517 | Scott Hartman                                                                                                                                                  |
| 206 |    717.277275 |    499.977426 | Tasman Dixon                                                                                                                                                   |
| 207 |    756.026113 |    422.768574 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 208 |    544.392361 |    790.688117 | Harold N Eyster                                                                                                                                                |
| 209 |    326.698634 |    591.505128 | Chase Brownstein                                                                                                                                               |
| 210 |    481.337463 |    577.919038 | Steven Traver                                                                                                                                                  |
| 211 |    607.047824 |    256.629289 | Zimices                                                                                                                                                        |
| 212 |    217.339923 |    781.539788 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                           |
| 213 |    981.750148 |     65.950140 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                      |
| 214 |    637.906849 |     39.920807 | Tracy A. Heath                                                                                                                                                 |
| 215 |    672.759931 |    345.338054 | Ryan Cupo                                                                                                                                                      |
| 216 |     50.374299 |    376.558445 | NA                                                                                                                                                             |
| 217 |     34.837648 |    228.172462 | T. Michael Keesey                                                                                                                                              |
| 218 |     65.642307 |    346.873637 | Zimices                                                                                                                                                        |
| 219 |    911.813896 |     13.319226 | Chris huh                                                                                                                                                      |
| 220 |    997.510361 |    251.479874 | Margot Michaud                                                                                                                                                 |
| 221 |    971.574970 |    711.008699 | Chris huh                                                                                                                                                      |
| 222 |    289.201525 |    716.523405 | Becky Barnes                                                                                                                                                   |
| 223 |    240.254326 |    278.538669 | Chris huh                                                                                                                                                      |
| 224 |    762.716952 |    166.420449 | T. Michael Keesey (after Heinrich Harder)                                                                                                                      |
| 225 |    992.270845 |    181.890277 | Matt Crook                                                                                                                                                     |
| 226 |    183.776168 |     77.219772 | Ignacio Contreras                                                                                                                                              |
| 227 |     17.021831 |    312.374204 | Andy Wilson                                                                                                                                                    |
| 228 |    511.914174 |    132.438507 | Smith609 and T. Michael Keesey                                                                                                                                 |
| 229 |    869.142538 |    333.659213 | xgirouxb                                                                                                                                                       |
| 230 |    557.673992 |    449.750807 | Ferran Sayol                                                                                                                                                   |
| 231 |    655.018575 |    573.679678 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 232 |    834.042507 |    196.650095 | Becky Barnes                                                                                                                                                   |
| 233 |    877.990541 |    257.003905 | Birgit Lang                                                                                                                                                    |
| 234 |    959.377963 |     53.155393 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 235 |    449.575302 |     23.938700 | Gareth Monger                                                                                                                                                  |
| 236 |    781.131736 |    413.574474 | NA                                                                                                                                                             |
| 237 |    959.728141 |    571.093028 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 238 |    394.112793 |    704.131930 | Kailah Thorn & Ben King                                                                                                                                        |
| 239 |    993.855404 |    666.091235 | Margot Michaud                                                                                                                                                 |
| 240 |    858.048533 |    785.048353 | FunkMonk                                                                                                                                                       |
| 241 |     46.017921 |    518.979845 | Zimices                                                                                                                                                        |
| 242 |    180.517652 |    781.376172 | NA                                                                                                                                                             |
| 243 |    675.186223 |    748.034611 | Gareth Monger                                                                                                                                                  |
| 244 |    521.680770 |    459.594064 | Steven Coombs                                                                                                                                                  |
| 245 |    579.123548 |    704.383702 | Gabriela Palomo-Munoz                                                                                                                                          |
| 246 |    999.848503 |     99.962793 | Zimices                                                                                                                                                        |
| 247 |    799.345294 |    649.026253 | Melissa Broussard                                                                                                                                              |
| 248 |    243.801848 |    678.011257 | Cesar Julian                                                                                                                                                   |
| 249 |    427.375419 |    365.233264 | Gabriela Palomo-Munoz                                                                                                                                          |
| 250 |     81.141932 |    509.332811 | Gabriela Palomo-Munoz                                                                                                                                          |
| 251 |    247.931400 |    456.946505 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 252 |   1017.072677 |    555.457806 | NASA                                                                                                                                                           |
| 253 |    446.567163 |    321.739831 | Matt Crook                                                                                                                                                     |
| 254 |    928.640625 |    337.470259 | Xavier Giroux-Bougard                                                                                                                                          |
| 255 |    313.805194 |    613.217927 | Matt Crook                                                                                                                                                     |
| 256 |    807.074431 |    783.602326 | Gareth Monger                                                                                                                                                  |
| 257 |    911.118751 |    122.910957 | Tauana J. Cunha                                                                                                                                                |
| 258 |    608.785746 |    503.329767 | Collin Gross                                                                                                                                                   |
| 259 |   1007.663301 |      4.237292 | Chris huh                                                                                                                                                      |
| 260 |    484.465800 |     15.451102 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 261 |     28.844725 |     24.379498 | Michelle Site                                                                                                                                                  |
| 262 |     14.454811 |    667.636779 | Andy Wilson                                                                                                                                                    |
| 263 |    700.267671 |    626.548625 | Zimices                                                                                                                                                        |
| 264 |     71.036297 |    181.478432 | Andy Wilson                                                                                                                                                    |
| 265 |    569.193969 |    578.937844 | C. Camilo Julián-Caballero                                                                                                                                     |
| 266 |    731.719035 |    398.052857 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 267 |     99.290355 |    491.477620 | Tracy A. Heath                                                                                                                                                 |
| 268 |    602.650262 |    277.913859 | Beth Reinke                                                                                                                                                    |
| 269 |     50.877535 |    412.367475 | NA                                                                                                                                                             |
| 270 |    445.032056 |    278.126396 | Tony Ayling                                                                                                                                                    |
| 271 |     67.548983 |    318.181989 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 272 |    865.449590 |    305.510088 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                          |
| 273 |    477.678757 |    173.554904 | Gabriela Palomo-Munoz                                                                                                                                          |
| 274 |    369.367518 |     57.614961 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                         |
| 275 |    677.680718 |    484.879832 | Armin Reindl                                                                                                                                                   |
| 276 |    647.630952 |    503.200807 | Gareth Monger                                                                                                                                                  |
| 277 |    881.984553 |    394.911981 | NA                                                                                                                                                             |
| 278 |    553.782721 |     35.524258 | Daniel Stadtmauer                                                                                                                                              |
| 279 |    986.842051 |    642.771657 | Lukasiniho                                                                                                                                                     |
| 280 |     77.910144 |    687.616021 | Matt Crook                                                                                                                                                     |
| 281 |    191.615241 |    265.354850 | Rebecca Groom                                                                                                                                                  |
| 282 |    187.918169 |    551.225965 | Ferran Sayol                                                                                                                                                   |
| 283 |    629.137883 |    484.700351 | Taenadoman                                                                                                                                                     |
| 284 |    833.197843 |     73.060277 | Patrick Strutzenberger                                                                                                                                         |
| 285 |    201.228191 |    465.633088 | NA                                                                                                                                                             |
| 286 |   1002.372343 |    611.749898 | T. Michael Keesey                                                                                                                                              |
| 287 |    532.473422 |    119.464606 | Chloé Schmidt                                                                                                                                                  |
| 288 |    525.818662 |      8.072782 | Tasman Dixon                                                                                                                                                   |
| 289 |    419.339667 |    265.460958 | Jagged Fang Designs                                                                                                                                            |
| 290 |    126.514015 |     29.612906 | Kamil S. Jaron                                                                                                                                                 |
| 291 |    815.660167 |    482.197708 | Zimices                                                                                                                                                        |
| 292 |    984.984004 |    686.423826 | Markus A. Grohme                                                                                                                                               |
| 293 |    544.248810 |     59.849944 | Zimices                                                                                                                                                        |
| 294 |    961.286677 |    791.072085 | Noah Schlottman, photo by David J Patterson                                                                                                                    |
| 295 |    516.272351 |    368.211737 | Margot Michaud                                                                                                                                                 |
| 296 |    552.073472 |    714.120400 | Benchill                                                                                                                                                       |
| 297 |     60.259511 |    670.904724 | Renato Santos                                                                                                                                                  |
| 298 |    734.909216 |    229.904742 | Melissa Broussard                                                                                                                                              |
| 299 |    162.776571 |    782.451591 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                       |
| 300 |    523.075616 |    666.280715 | Birgit Lang                                                                                                                                                    |
| 301 |    414.044148 |    568.249402 | Kailah Thorn & Mark Hutchinson                                                                                                                                 |
| 302 |    620.820431 |    296.370112 | Dmitry Bogdanov                                                                                                                                                |
| 303 |    980.340838 |    461.930177 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 304 |    410.102731 |    342.475869 | Gabriela Palomo-Munoz                                                                                                                                          |
| 305 |    312.367964 |    168.336330 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                |
| 306 |    861.647602 |    349.159227 | T. Michael Keesey                                                                                                                                              |
| 307 |    479.225516 |    217.741409 | Katie S. Collins                                                                                                                                               |
| 308 |    445.278529 |    643.055195 | Hugo Gruson                                                                                                                                                    |
| 309 |     98.136409 |    116.733056 | Birgit Lang                                                                                                                                                    |
| 310 |    169.677828 |    303.643202 | Roberto Díaz Sibaja                                                                                                                                            |
| 311 |    686.341821 |    778.727216 | Andy Wilson                                                                                                                                                    |
| 312 |    571.277470 |    294.455580 | Zimices                                                                                                                                                        |
| 313 |    905.523163 |     70.447982 | Scott Hartman                                                                                                                                                  |
| 314 |    866.948782 |    736.796244 | Gabriela Palomo-Munoz                                                                                                                                          |
| 315 |    149.957115 |    654.230888 | Yan Wong                                                                                                                                                       |
| 316 |    242.166693 |    786.039553 | Matt Crook                                                                                                                                                     |
| 317 |    512.381055 |    550.889892 | Karla Martinez                                                                                                                                                 |
| 318 |    507.724361 |    586.640442 | Chris huh                                                                                                                                                      |
| 319 |    194.812334 |    198.445580 | Jagged Fang Designs                                                                                                                                            |
| 320 |    780.496677 |     32.888965 | Gareth Monger                                                                                                                                                  |
| 321 |    446.035246 |    209.849935 | Tasman Dixon                                                                                                                                                   |
| 322 |    537.458802 |    150.039937 | T. Michael Keesey (after Ponomarenko)                                                                                                                          |
| 323 |    361.760350 |    271.095179 | Christoph Schomburg                                                                                                                                            |
| 324 |    354.326493 |    413.549189 | John Gould (vectorized by T. Michael Keesey)                                                                                                                   |
| 325 |    930.189017 |    782.476738 | Erika Schumacher                                                                                                                                               |
| 326 |    325.301713 |     60.561520 | Zimices                                                                                                                                                        |
| 327 |    929.615722 |    360.170612 | Campbell Fleming                                                                                                                                               |
| 328 |    889.279129 |    167.017205 | Margot Michaud                                                                                                                                                 |
| 329 |    836.353875 |     89.430903 | Tasman Dixon                                                                                                                                                   |
| 330 |    515.820921 |    174.490727 | Markus A. Grohme                                                                                                                                               |
| 331 |    193.336939 |    660.195744 | Carlos Cano-Barbacil                                                                                                                                           |
| 332 |    857.291157 |    537.698572 | Gareth Monger                                                                                                                                                  |
| 333 |    356.296222 |    264.061960 | Steven Traver                                                                                                                                                  |
| 334 |    740.880620 |    283.316349 | Gareth Monger                                                                                                                                                  |
| 335 |    167.703948 |    285.116325 | Michelle Site                                                                                                                                                  |
| 336 |     93.355807 |    312.153977 | Maija Karala                                                                                                                                                   |
| 337 |    227.522322 |    109.702246 | Scott Hartman                                                                                                                                                  |
| 338 |    362.533675 |     70.150665 | Arthur S. Brum                                                                                                                                                 |
| 339 |    453.788517 |    198.905582 | Jagged Fang Designs                                                                                                                                            |
| 340 |    493.859484 |    746.241370 | L. Shyamal                                                                                                                                                     |
| 341 |    760.763813 |    495.810107 | Alex Slavenko                                                                                                                                                  |
| 342 |    873.020642 |    707.220432 | Mathew Wedel                                                                                                                                                   |
| 343 |    420.958526 |    724.372513 | Margot Michaud                                                                                                                                                 |
| 344 |    219.215051 |    711.049566 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 345 |    970.915904 |    468.656629 | Scott Hartman                                                                                                                                                  |
| 346 |    348.292072 |    209.509403 | Sean McCann                                                                                                                                                    |
| 347 |    280.232207 |    147.181112 | Michelle Site                                                                                                                                                  |
| 348 |    400.599242 |    746.532412 | NA                                                                                                                                                             |
| 349 |     46.700081 |    583.700236 | Margot Michaud                                                                                                                                                 |
| 350 |    963.745735 |    489.208229 | Chris huh                                                                                                                                                      |
| 351 |    468.969579 |    232.559932 | Scott Hartman                                                                                                                                                  |
| 352 |    949.903090 |    212.120329 | Margot Michaud                                                                                                                                                 |
| 353 |    914.036953 |    497.943749 | Sarah Werning                                                                                                                                                  |
| 354 |    224.316699 |    371.147008 | Margot Michaud                                                                                                                                                 |
| 355 |    662.846902 |    590.353022 | Tasman Dixon                                                                                                                                                   |
| 356 |    434.963551 |    482.180492 | Scott Hartman                                                                                                                                                  |
| 357 |    994.009799 |    782.578825 | Falconaumanni and T. Michael Keesey                                                                                                                            |
| 358 |    520.799602 |    102.491167 | NA                                                                                                                                                             |
| 359 |    917.748819 |    100.168206 | Manabu Bessho-Uehara                                                                                                                                           |
| 360 |    516.873851 |    638.911213 | Dean Schnabel                                                                                                                                                  |
| 361 |    766.820429 |    594.722674 | Trond R. Oskars                                                                                                                                                |
| 362 |    424.519121 |     99.894470 | Ferran Sayol                                                                                                                                                   |
| 363 |    137.748190 |      9.616660 | Roberto Díaz Sibaja                                                                                                                                            |
| 364 |    839.408376 |    723.183862 | Scott Hartman                                                                                                                                                  |
| 365 |    986.814305 |    147.140208 | T. Michael Keesey                                                                                                                                              |
| 366 |    685.460034 |    665.670246 | Steven Haddock • Jellywatch.org                                                                                                                                |
| 367 |    173.930799 |    709.821046 | S.Martini                                                                                                                                                      |
| 368 |    500.158529 |    478.037467 | Margot Michaud                                                                                                                                                 |
| 369 |    389.954484 |    727.373079 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                    |
| 370 |    892.883268 |    785.705933 | Jack Mayer Wood                                                                                                                                                |
| 371 |    484.162303 |    281.742717 | Tasman Dixon                                                                                                                                                   |
| 372 |    382.519276 |    214.507507 | Chris huh                                                                                                                                                      |
| 373 |    250.663305 |    654.367671 | Javier Luque & Sarah Gerken                                                                                                                                    |
| 374 |    923.049115 |    622.956101 | Gareth Monger                                                                                                                                                  |
| 375 |    968.517253 |    327.167516 | Matt Martyniuk (modified by Serenchia)                                                                                                                         |
| 376 |     38.975862 |    400.886401 | Scott Hartman                                                                                                                                                  |
| 377 |    924.035907 |    136.754853 | Chris huh                                                                                                                                                      |
| 378 |    566.902286 |    316.775447 | Zimices                                                                                                                                                        |
| 379 |    844.466820 |    739.459080 | Ferran Sayol                                                                                                                                                   |
| 380 |    543.102287 |    599.490208 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 381 |    184.624297 |    354.578135 | T. Michael Keesey                                                                                                                                              |
| 382 |    748.098996 |    794.960080 | Chris huh                                                                                                                                                      |
| 383 |    396.402167 |    790.652497 | Tony Ayling                                                                                                                                                    |
| 384 |    517.548784 |    336.288361 | Jagged Fang Designs                                                                                                                                            |
| 385 |    879.060284 |    147.455877 | Ingo Braasch                                                                                                                                                   |
| 386 |    946.419028 |    548.348167 | Felix Vaux                                                                                                                                                     |
| 387 |    666.024475 |     53.937327 | Ferran Sayol                                                                                                                                                   |
| 388 |    859.375083 |    617.338283 | Scott Hartman                                                                                                                                                  |
| 389 |    404.053623 |    616.551141 | Steven Traver                                                                                                                                                  |
| 390 |    976.292139 |    717.500161 | Markus A. Grohme                                                                                                                                               |
| 391 |    496.293222 |    791.421172 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 392 |    559.812424 |    429.418769 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                           |
| 393 |    221.332395 |    359.208488 | Chase Brownstein                                                                                                                                               |
| 394 |    164.100033 |     57.395021 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 395 |    704.580571 |    643.903394 | FunkMonk                                                                                                                                                       |
| 396 |    594.427068 |    412.892973 | Gareth Monger                                                                                                                                                  |
| 397 |    340.108820 |    482.800489 | L. Shyamal                                                                                                                                                     |
| 398 |   1004.462778 |     71.431909 | NA                                                                                                                                                             |
| 399 |     23.943566 |    301.826477 | Jagged Fang Designs                                                                                                                                            |
| 400 |   1005.189644 |    430.621060 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 401 |    264.580072 |    314.406579 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 402 |    800.477039 |    209.592434 | Christopher Chávez                                                                                                                                             |
| 403 |    734.338852 |    209.793080 | Zimices                                                                                                                                                        |
| 404 |     85.614507 |    135.444861 | Scott Hartman                                                                                                                                                  |
| 405 |    639.499126 |    414.421331 | Matt Crook                                                                                                                                                     |
| 406 |    612.396476 |    674.584975 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                           |
| 407 |    226.621296 |     13.714439 | Lukasiniho                                                                                                                                                     |
| 408 |    935.149938 |    531.742486 | Jack Mayer Wood                                                                                                                                                |
| 409 |    216.289089 |    730.571734 | Kai R. Caspar                                                                                                                                                  |
| 410 |    425.561481 |    486.713016 | Jaime Headden                                                                                                                                                  |
| 411 |    715.520474 |    170.095974 | Gustav Mützel                                                                                                                                                  |
| 412 |    532.934751 |    578.809776 | T. Michael Keesey                                                                                                                                              |
| 413 |    781.929447 |    571.730146 | Jagged Fang Designs                                                                                                                                            |
| 414 |    985.013015 |      5.180521 | Tasman Dixon                                                                                                                                                   |
| 415 |    175.083595 |    427.643486 | NA                                                                                                                                                             |
| 416 |    131.988347 |    783.891817 | T. Michael Keesey (after Monika Betley)                                                                                                                        |
| 417 |    797.808271 |    587.157376 | Felix Vaux                                                                                                                                                     |
| 418 |    953.533801 |    628.630467 | Chris huh                                                                                                                                                      |
| 419 |    840.863663 |    430.935148 | Filip em                                                                                                                                                       |
| 420 |   1011.572265 |    216.513468 | Tauana J. Cunha                                                                                                                                                |
| 421 |    701.441949 |    438.461668 | Margot Michaud                                                                                                                                                 |
| 422 |    311.927859 |    460.446445 | Tasman Dixon                                                                                                                                                   |
| 423 |    484.558637 |    264.663160 | Eric Moody                                                                                                                                                     |
| 424 |     45.413238 |     98.687361 | Melissa Broussard                                                                                                                                              |
| 425 |    573.596779 |    660.118822 | T. Michael Keesey                                                                                                                                              |
| 426 |    926.628483 |    195.450967 | Tasman Dixon                                                                                                                                                   |
| 427 |    540.151367 |    777.045025 | Agnello Picorelli                                                                                                                                              |
| 428 |    239.552811 |    495.011603 | Neil Kelley                                                                                                                                                    |
| 429 |    762.638725 |    785.066465 | Carlos Cano-Barbacil                                                                                                                                           |
| 430 |    552.515104 |    469.789466 | Nick Schooler                                                                                                                                                  |
| 431 |    319.387015 |    122.996326 | Christopher Chávez                                                                                                                                             |
| 432 |   1004.740324 |    760.883794 | Ignacio Contreras                                                                                                                                              |
| 433 |    704.769465 |    769.291464 | Carlos Cano-Barbacil                                                                                                                                           |
| 434 |    960.311750 |    239.753478 | Margot Michaud                                                                                                                                                 |
| 435 |    195.438693 |    483.981358 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 436 |    614.193020 |    403.541795 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                               |
| 437 |   1010.315863 |    781.899695 | Andy Wilson                                                                                                                                                    |
| 438 |     11.266890 |    253.619078 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 439 |    330.306748 |    577.778094 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 440 |    413.615317 |     30.395579 | Steven Traver                                                                                                                                                  |
| 441 |    548.750734 |    285.644304 | T. Michael Keesey                                                                                                                                              |
| 442 |     15.025118 |     95.408800 | Steven Traver                                                                                                                                                  |
| 443 |    846.358203 |    765.280771 | Matt Crook                                                                                                                                                     |
| 444 |    258.545669 |    712.564526 | NA                                                                                                                                                             |
| 445 |    377.243507 |    601.274131 | NA                                                                                                                                                             |
| 446 |    422.204998 |    709.927374 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                  |
| 447 |    370.487235 |    412.049804 | Melissa Broussard                                                                                                                                              |
| 448 |    524.485685 |    415.328238 | Darius Nau                                                                                                                                                     |
| 449 |    803.936964 |     80.938547 | Rachel Shoop                                                                                                                                                   |
| 450 |    266.996447 |    784.340651 | Andrés Sánchez                                                                                                                                                 |
| 451 |    997.159738 |     49.769528 | Jagged Fang Designs                                                                                                                                            |
| 452 |    420.361751 |    404.037825 | Lukasiniho                                                                                                                                                     |
| 453 |    698.098682 |      5.180933 | Jagged Fang Designs                                                                                                                                            |
| 454 |     60.278421 |    224.332502 | Gabriela Palomo-Munoz                                                                                                                                          |
| 455 |    510.827255 |    209.016288 | Kent Elson Sorgon                                                                                                                                              |
| 456 |    138.479138 |    704.108120 | Markus A. Grohme                                                                                                                                               |
| 457 |    524.017843 |    443.336504 | Mo Hassan                                                                                                                                                      |
| 458 |    690.964004 |    167.117608 | Gareth Monger                                                                                                                                                  |
| 459 |    882.915087 |    377.472255 | Jaime Headden                                                                                                                                                  |
| 460 |    771.752202 |      3.229303 | NA                                                                                                                                                             |
| 461 |    520.930476 |    693.502791 | T. Michael Keesey                                                                                                                                              |
| 462 |    136.731445 |    646.595524 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 463 |    593.917056 |    654.795428 | C. Camilo Julián-Caballero                                                                                                                                     |
| 464 |     23.258345 |    213.883616 | Sarah Werning                                                                                                                                                  |
| 465 |    749.525705 |    363.513488 | Andy Wilson                                                                                                                                                    |
| 466 |    412.502405 |    211.541929 | Chris huh                                                                                                                                                      |
| 467 |    615.138243 |    699.238176 | Markus A. Grohme                                                                                                                                               |
| 468 |    918.154681 |     56.884936 | C. Abraczinskas                                                                                                                                                |
| 469 |    144.556513 |    512.635495 | T. Michael Keesey                                                                                                                                              |
| 470 |     89.518424 |     90.054556 | Chris huh                                                                                                                                                      |
| 471 |    355.575431 |    679.700396 | CNZdenek                                                                                                                                                       |
| 472 |    779.579695 |    617.825155 | Juan Carlos Jerí                                                                                                                                               |
| 473 |    215.316580 |    343.682454 | Chuanixn Yu                                                                                                                                                    |
| 474 |      9.478471 |     32.695882 | Collin Gross                                                                                                                                                   |
| 475 |    891.892133 |     33.226218 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                              |
| 476 |    720.555083 |    595.050877 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                          |
| 477 |    467.734012 |    793.986557 | Rebecca Groom                                                                                                                                                  |
| 478 |    871.151215 |    714.937647 | Markus A. Grohme                                                                                                                                               |
| 479 |    131.277707 |    269.017517 | Lukas Panzarin                                                                                                                                                 |
| 480 |    394.620901 |    437.086219 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 481 |    745.067785 |    638.075163 | Jagged Fang Designs                                                                                                                                            |
| 482 |    916.681197 |    266.521823 | Melissa Broussard                                                                                                                                              |
| 483 |    188.503389 |    515.948723 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 484 |    610.692612 |      8.454292 | Emily Willoughby                                                                                                                                               |
| 485 |    701.559749 |    746.911054 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 486 |    190.635633 |    216.048414 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                        |
| 487 |    277.593094 |    159.214399 | NA                                                                                                                                                             |
| 488 |    931.975461 |    793.092665 | Xavier Giroux-Bougard                                                                                                                                          |
| 489 |    399.029832 |    275.594781 | Anthony Caravaggi                                                                                                                                              |
| 490 |    804.694040 |    142.670553 | Xavier Giroux-Bougard                                                                                                                                          |
| 491 |    937.604629 |    170.486898 | Zimices                                                                                                                                                        |
| 492 |    116.659385 |    123.668195 | Ignacio Contreras                                                                                                                                              |
| 493 |    664.401216 |    723.821711 | Matt Martyniuk                                                                                                                                                 |
| 494 |    517.378433 |    307.444164 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 495 |    862.683828 |    230.560105 | Tracy A. Heath                                                                                                                                                 |
| 496 |   1001.010888 |    114.335542 | Jagged Fang Designs                                                                                                                                            |
| 497 |    891.295973 |    355.972825 | Kailah Thorn & Mark Hutchinson                                                                                                                                 |
| 498 |    315.322648 |    225.115913 | Tracy A. Heath                                                                                                                                                 |
| 499 |    677.290343 |    719.432719 | Mathew Wedel                                                                                                                                                   |
| 500 |    808.514540 |    422.286956 | Michelle Site                                                                                                                                                  |
| 501 |    261.353618 |    341.879763 | Scott Hartman                                                                                                                                                  |
| 502 |     17.578188 |    174.502243 | Ignacio Contreras                                                                                                                                              |
| 503 |    106.379111 |    794.044602 | Scott Hartman                                                                                                                                                  |
| 504 |    147.029953 |    796.059294 | T. Michael Keesey                                                                                                                                              |
| 505 |    835.088827 |     57.052845 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 506 |    942.463681 |    424.840226 | T. Michael Keesey (after Mauricio Antón)                                                                                                                       |
| 507 |    597.518410 |    570.382116 | Scott Hartman                                                                                                                                                  |
| 508 |    150.393498 |     83.432434 | Margot Michaud                                                                                                                                                 |
| 509 |    103.173698 |    106.539519 | Renata F. Martins                                                                                                                                              |
| 510 |   1017.205278 |    704.697757 | T. Michael Keesey                                                                                                                                              |
| 511 |    481.102747 |    774.316352 | C. Camilo Julián-Caballero                                                                                                                                     |
| 512 |    855.760487 |    128.620937 | Gareth Monger                                                                                                                                                  |
| 513 |    198.458356 |    623.942534 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 514 |    498.855617 |    164.095357 | Tasman Dixon                                                                                                                                                   |
| 515 |    674.509260 |    210.259307 | Gareth Monger                                                                                                                                                  |
| 516 |    580.240762 |    639.288824 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 517 |   1008.360021 |    299.567711 | Kai R. Caspar                                                                                                                                                  |
| 518 |   1000.175625 |    702.863361 | Margot Michaud                                                                                                                                                 |
| 519 |    960.039521 |    645.142646 | Matt Crook                                                                                                                                                     |
| 520 |    515.037543 |     20.851766 | Markus A. Grohme                                                                                                                                               |
| 521 |    949.936884 |      3.777954 | Scott Hartman                                                                                                                                                  |
| 522 |     15.540072 |    784.734291 | Gareth Monger                                                                                                                                                  |
| 523 |    421.285057 |    276.245442 | Iain Reid                                                                                                                                                      |
| 524 |    126.816828 |    568.732138 | Andy Wilson                                                                                                                                                    |
| 525 |    273.100633 |    108.687144 | Birgit Lang                                                                                                                                                    |
| 526 |    630.955101 |    288.266164 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                             |
| 527 |    511.865334 |    788.321750 | Chris huh                                                                                                                                                      |
| 528 |    814.843953 |      8.061834 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                    |
| 529 |    200.572973 |    641.197552 | Yan Wong from illustration by Jules Richard (1907)                                                                                                             |
| 530 |    156.466938 |    764.804675 | Chris huh                                                                                                                                                      |
| 531 |    194.401433 |    531.611020 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 532 |     15.533505 |    508.067857 | Chris huh                                                                                                                                                      |
| 533 |    371.145646 |    332.043000 | T. Michael Keesey                                                                                                                                              |
| 534 |    293.479330 |    607.075637 | Gareth Monger                                                                                                                                                  |
| 535 |    124.337822 |    130.055632 | FunkMonk                                                                                                                                                       |
| 536 |   1012.728018 |    328.969492 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                     |
| 537 |    213.261779 |     56.679618 | Matt Crook                                                                                                                                                     |
| 538 |    871.748149 |    159.499484 | Markus A. Grohme                                                                                                                                               |

    #> Your tweet has been posted!
