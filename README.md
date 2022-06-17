
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

Matt Crook, Gareth Monger, Margot Michaud, Xvazquez (vectorized by
William Gearty), Darren Naish (vectorized by T. Michael Keesey), Kent
Elson Sorgon, Jagged Fang Designs, Blair Perry, Caleb M. Brown, Robbie
N. Cada (vectorized by T. Michael Keesey), Zimices, Andrew A. Farke,
Ferran Sayol, Bill Bouton (source photo) & T. Michael Keesey
(vectorization), Carlos Cano-Barbacil, Andrew A. Farke, shell lines
added by Yan Wong, Tauana J. Cunha, Matt Martyniuk, Chris huh, T.
Michael Keesey (photo by Sean Mack), Gabriela Palomo-Munoz, Steven
Haddock • Jellywatch.org, Collin Gross, Nobu Tamura (vectorized by T.
Michael Keesey), Tasman Dixon, Liftarn, Qiang Ou, Steven Traver, Pete
Buchholz, Ieuan Jones, Ignacio Contreras, T. Michael Keesey (after
Mauricio Antón), Christoph Schomburg, T. Michael Keesey, Jaime Headden,
Dinah Challen, Anthony Caravaggi, Markus A. Grohme, Michelle Site,
Kailah Thorn & Mark Hutchinson, Rebecca Groom, Scott D. Sampson, Mark A.
Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua
A. Smith, Alan L. Titus, Tambja (vectorized by T. Michael Keesey),
Alexander Schmidt-Lebuhn, Armin Reindl, Melissa Ingala, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Ingo Braasch, Sarah Werning, T. Tischler, Julio Garza, Mathew
Wedel, Mattia Menchetti / Yan Wong, \[unknown\], Katie S. Collins,
kreidefossilien.de, Bob Goldstein, Vectorization:Jake Warner, Scott
Hartman, Dmitry Bogdanov (vectorized by T. Michael Keesey), Auckland
Museum, T. Michael Keesey (vectorization) and Larry Loos (photography),
Kamil S. Jaron, Christine Axon, Sharon Wegner-Larsen, Yan Wong from
illustration by Jules Richard (1907), Tracy A. Heath, DFoidl (vectorized
by T. Michael Keesey), Crystal Maier, Robert Bruce Horsfall (vectorized
by William Gearty), Michael Day, Duane Raver/USFWS, Anna Willoughby,
Frank Förster (based on a picture by Hans Hillewaert), Warren H
(photography), T. Michael Keesey (vectorization), Emily Willoughby,
David Orr, Ville-Veikko Sinkkonen, Maija Karala, Robert Gay, modified
from FunkMonk (Michael B.H.) and T. Michael Keesey., Michael P. Taylor,
Kai R. Caspar, CNZdenek, J Levin W (illustration) and T. Michael Keesey
(vectorization), Gopal Murali, Skye McDavid, Matthew E. Clapham, Dmitry
Bogdanov, Paul O. Lewis, Natalie Claunch, Robert Gay, FunkMonk \[Michael
B.H.\] (modified by T. Michael Keesey), Renata F. Martins, Estelle
Bourdon, Matt Martyniuk (vectorized by T. Michael Keesey), Birgit Lang,
Mattia Menchetti, Pearson Scott Foresman (vectorized by T. Michael
Keesey), Francisco Gascó (modified by Michael P. Taylor), DW Bapst
(Modified from photograph taken by Charles Mitchell), Amanda Katzer, Jan
A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Harold N Eyster, Maxwell Lefroy
(vectorized by T. Michael Keesey), Caroline Harding, MAF (vectorized by
T. Michael Keesey), Benchill, Stemonitis (photography) and T. Michael
Keesey (vectorization), DW Bapst, modified from Ishitani et al. 2016,
Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Joe Schneid (vectorized by T. Michael Keesey), xgirouxb,
Darius Nau, Unknown (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Michael Scroggie, Sarah Alewijnse, Jon Hill (Photo by
Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Brian
Gratwicke (photo) and T. Michael Keesey (vectorization),
Myriam\_Ramirez, U.S. National Park Service (vectorized by William
Gearty), Catherine Yasuda, Courtney Rockenbach, Karl Ragnar Gjertsen
(vectorized by T. Michael Keesey), Cesar Julian, Dmitry Bogdanov
(modified by T. Michael Keesey), ArtFavor & annaleeblysse, Terpsichores,
T. Michael Keesey (after MPF), Noah Schlottman, photo by Casey Dunn,
Noah Schlottman, Jay Matternes (modified by T. Michael Keesey), M
Kolmann, Erika Schumacher, Andy Wilson, FJDegrange, Steven Coombs,
Stanton F. Fink (vectorized by T. Michael Keesey), Yan Wong, Aviceda
(photo) & T. Michael Keesey, Beth Reinke, Ghedo (vectorized by T.
Michael Keesey), Shyamal, Dean Schnabel, Geoff Shaw, S.Martini, Antonov
(vectorized by T. Michael Keesey), Falconaumanni and T. Michael Keesey,
Daniel Stadtmauer, Gabriel Lio, vectorized by Zimices, Agnello
Picorelli, Lafage, Melissa Broussard, John Conway, Nina Skinner,
Obsidian Soul (vectorized by T. Michael Keesey), Lauren Anderson, Mateus
Zica (modified by T. Michael Keesey), Matt Dempsey, Joanna Wolfe, L.
Shyamal, FunkMonk, T. Michael Keesey (after Mivart), B. Duygu Özpolat,
NASA, Benjamin Monod-Broca, Yusan Yang, Lukas Panzarin, Sergio A.
Muñoz-Gómez, Rafael Maia, Maxime Dahirel, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, Xavier Giroux-Bougard,
Felix Vaux, U.S. Fish and Wildlife Service (illustration) and Timothy J.
Bartley (silhouette), Becky Barnes, Young and Zhao (1972:figure 4),
modified by Michael P. Taylor, Nobu Tamura, vectorized by Zimices, Nick
Schooler, Haplochromis (vectorized by T. Michael Keesey), Ray Simpson
(vectorized by T. Michael Keesey), Eduard Solà (vectorized by T. Michael
Keesey), Fernando Campos De Domenico, Milton Tan, Lankester Edwin Ray
(vectorized by T. Michael Keesey), Chuanixn Yu, Christopher Laumer
(vectorized by T. Michael Keesey), Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), T. Michael Keesey
(after Ponomarenko), Mark Witton, Walter Vladimir, Lip Kee Yap
(vectorized by T. Michael Keesey), C. Camilo Julián-Caballero, Michael
“FunkMonk” B. H. (vectorized by T. Michael Keesey), Smokeybjb, Lee
Harding (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Alex Slavenko, Mette Aumala, Riccardo Percudani, Emma
Hughes, Nicholas J. Czaplewski, vectorized by Zimices, Roberto Díaz
Sibaja, Emma Kissling, Tony Ayling (vectorized by T. Michael Keesey),
Scott Reid, Aleksey Nagovitsyn (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    358.502029 |    527.882414 | NA                                                                                                                                                                    |
|   2 |    630.190491 |    401.622133 | Matt Crook                                                                                                                                                            |
|   3 |    104.580161 |    648.095339 | NA                                                                                                                                                                    |
|   4 |    939.882846 |    182.593440 | Gareth Monger                                                                                                                                                         |
|   5 |    320.085364 |    259.618894 | Margot Michaud                                                                                                                                                        |
|   6 |    608.316849 |    300.503684 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
|   7 |    609.975167 |    118.894146 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
|   8 |    878.195202 |    214.834479 | Kent Elson Sorgon                                                                                                                                                     |
|   9 |    632.764179 |    246.648634 | Jagged Fang Designs                                                                                                                                                   |
|  10 |    805.955207 |    714.483273 | NA                                                                                                                                                                    |
|  11 |    480.260584 |    453.195049 | Blair Perry                                                                                                                                                           |
|  12 |    848.303134 |    510.280720 | Caleb M. Brown                                                                                                                                                        |
|  13 |    612.005642 |     51.584640 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  14 |    938.631864 |    644.021675 | Zimices                                                                                                                                                               |
|  15 |    106.092803 |    316.442643 | NA                                                                                                                                                                    |
|  16 |    441.145822 |     82.316919 | Andrew A. Farke                                                                                                                                                       |
|  17 |    186.505977 |    477.994508 | Ferran Sayol                                                                                                                                                          |
|  18 |    187.838077 |    257.814510 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
|  19 |    818.885891 |    359.398277 | Carlos Cano-Barbacil                                                                                                                                                  |
|  20 |    625.414061 |    723.772762 | Zimices                                                                                                                                                               |
|  21 |    576.917950 |    583.401244 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
|  22 |    359.679148 |    381.586672 | Tauana J. Cunha                                                                                                                                                       |
|  23 |    259.530267 |    126.958133 | Matt Crook                                                                                                                                                            |
|  24 |    885.232750 |    293.406929 | Matt Martyniuk                                                                                                                                                        |
|  25 |    792.111838 |    192.379781 | Chris huh                                                                                                                                                             |
|  26 |    298.493030 |    691.456274 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
|  27 |    127.191124 |    177.818709 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  28 |    508.956356 |    246.076986 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  29 |    431.432034 |    276.378330 | NA                                                                                                                                                                    |
|  30 |    283.278465 |    778.218616 | Chris huh                                                                                                                                                             |
|  31 |    658.210604 |    439.572210 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  32 |    910.847296 |    579.699065 | Zimices                                                                                                                                                               |
|  33 |    663.203525 |    185.347498 | Matt Crook                                                                                                                                                            |
|  34 |    724.297919 |    602.450137 | Matt Crook                                                                                                                                                            |
|  35 |     73.614857 |    513.658528 | Collin Gross                                                                                                                                                          |
|  36 |    871.314018 |    436.720796 | Margot Michaud                                                                                                                                                        |
|  37 |    854.372616 |    125.192580 | Gareth Monger                                                                                                                                                         |
|  38 |    129.224647 |    753.262056 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  39 |    753.300456 |    437.336843 | Tasman Dixon                                                                                                                                                          |
|  40 |    178.463353 |     69.805572 | Liftarn                                                                                                                                                               |
|  41 |    466.634598 |    690.879146 | Gareth Monger                                                                                                                                                         |
|  42 |    735.980265 |     99.187239 | Qiang Ou                                                                                                                                                              |
|  43 |     64.948077 |     84.348308 | Steven Traver                                                                                                                                                         |
|  44 |    912.115897 |     32.658293 | Pete Buchholz                                                                                                                                                         |
|  45 |     71.447456 |     33.400248 | Ieuan Jones                                                                                                                                                           |
|  46 |    745.929667 |    281.770635 | Ignacio Contreras                                                                                                                                                     |
|  47 |    850.667726 |     70.509842 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
|  48 |    952.692863 |    746.031192 | Margot Michaud                                                                                                                                                        |
|  49 |    786.298360 |     26.841998 | Christoph Schomburg                                                                                                                                                   |
|  50 |     36.863870 |    288.524373 | T. Michael Keesey                                                                                                                                                     |
|  51 |    481.536790 |    197.302906 | Jaime Headden                                                                                                                                                         |
|  52 |    487.013966 |    338.804471 | Gareth Monger                                                                                                                                                         |
|  53 |    356.780608 |     14.640409 | Jagged Fang Designs                                                                                                                                                   |
|  54 |    247.125320 |    360.915446 | Dinah Challen                                                                                                                                                         |
|  55 |    991.834820 |    163.352233 | Anthony Caravaggi                                                                                                                                                     |
|  56 |    764.392734 |    664.576562 | Matt Crook                                                                                                                                                            |
|  57 |     60.091616 |    458.501506 | Markus A. Grohme                                                                                                                                                      |
|  58 |     88.606353 |    713.786392 | Carlos Cano-Barbacil                                                                                                                                                  |
|  59 |    761.759180 |    242.270322 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  60 |    505.157747 |    729.628850 | Michelle Site                                                                                                                                                         |
|  61 |    365.542407 |    200.800224 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
|  62 |    960.643435 |    323.347961 | Rebecca Groom                                                                                                                                                         |
|  63 |    725.336910 |    500.764649 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
|  64 |    528.845078 |    168.806283 | Chris huh                                                                                                                                                             |
|  65 |    812.640418 |    763.941471 | Tasman Dixon                                                                                                                                                          |
|  66 |    852.311990 |    405.120274 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
|  67 |    989.018429 |    506.872656 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  68 |    590.541059 |    373.936929 | Jagged Fang Designs                                                                                                                                                   |
|  69 |    545.631477 |    132.086065 | Armin Reindl                                                                                                                                                          |
|  70 |    615.099901 |    658.665778 | Melissa Ingala                                                                                                                                                        |
|  71 |    184.239444 |    649.311372 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  72 |     90.277514 |    574.478149 | Caleb M. Brown                                                                                                                                                        |
|  73 |    747.932662 |    369.557489 | Jagged Fang Designs                                                                                                                                                   |
|  74 |    479.844846 |     18.149226 | Markus A. Grohme                                                                                                                                                      |
|  75 |    349.021556 |    311.083745 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  76 |     65.095472 |    244.415414 | T. Michael Keesey                                                                                                                                                     |
|  77 |    390.308417 |    141.610438 | Ingo Braasch                                                                                                                                                          |
|  78 |     74.366514 |    417.056376 | Sarah Werning                                                                                                                                                         |
|  79 |    422.011245 |    773.441784 | Gareth Monger                                                                                                                                                         |
|  80 |    572.953820 |    767.404017 | Sarah Werning                                                                                                                                                         |
|  81 |    502.930654 |    527.049220 | T. Tischler                                                                                                                                                           |
|  82 |    919.539843 |    693.742572 | Julio Garza                                                                                                                                                           |
|  83 |    578.510263 |    483.918817 | Jagged Fang Designs                                                                                                                                                   |
|  84 |    252.606839 |     46.308675 | Ingo Braasch                                                                                                                                                          |
|  85 |     51.587759 |    770.396216 | Mathew Wedel                                                                                                                                                          |
|  86 |    937.206244 |     96.891096 | Mattia Menchetti / Yan Wong                                                                                                                                           |
|  87 |    964.779669 |    464.041840 | Jagged Fang Designs                                                                                                                                                   |
|  88 |    938.825348 |    520.178558 | Steven Traver                                                                                                                                                         |
|  89 |    169.579222 |    143.987651 | Gareth Monger                                                                                                                                                         |
|  90 |    807.737977 |    609.512724 | Ingo Braasch                                                                                                                                                          |
|  91 |    950.740592 |     71.417066 | \[unknown\]                                                                                                                                                           |
|  92 |    431.092719 |    620.162207 | NA                                                                                                                                                                    |
|  93 |    740.136715 |    745.875188 | Katie S. Collins                                                                                                                                                      |
|  94 |    711.958877 |    678.894467 | Matt Crook                                                                                                                                                            |
|  95 |     30.754862 |    188.111436 | kreidefossilien.de                                                                                                                                                    |
|  96 |    909.581908 |    388.221408 | NA                                                                                                                                                                    |
|  97 |    503.322929 |    283.387843 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                              |
|  98 |    149.179300 |    349.143629 | Scott Hartman                                                                                                                                                         |
|  99 |    182.399825 |    328.862752 | Scott Hartman                                                                                                                                                         |
| 100 |    955.668845 |    710.716640 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 101 |    985.578370 |    394.801535 | Gareth Monger                                                                                                                                                         |
| 102 |    696.433052 |     30.980570 | Jagged Fang Designs                                                                                                                                                   |
| 103 |    829.845534 |    662.314369 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 104 |    746.108519 |    324.297501 | Auckland Museum                                                                                                                                                       |
| 105 |    536.722785 |    204.483682 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 106 |    220.029862 |    195.849718 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 107 |    971.181452 |    436.698418 | Christoph Schomburg                                                                                                                                                   |
| 108 |    976.499852 |    234.557753 | Margot Michaud                                                                                                                                                        |
| 109 |    276.581330 |    218.339031 | Kamil S. Jaron                                                                                                                                                        |
| 110 |    119.440575 |    152.502533 | Christine Axon                                                                                                                                                        |
| 111 |    605.573333 |    172.293046 | Sharon Wegner-Larsen                                                                                                                                                  |
| 112 |    472.174063 |    313.843498 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 113 |    935.535112 |    481.700766 | Tracy A. Heath                                                                                                                                                        |
| 114 |    195.992261 |    748.329030 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
| 115 |    717.387986 |    202.606140 | Margot Michaud                                                                                                                                                        |
| 116 |    205.625906 |    412.311543 | Crystal Maier                                                                                                                                                         |
| 117 |    702.358329 |    322.194343 | Gareth Monger                                                                                                                                                         |
| 118 |    885.639364 |    705.407011 | Michelle Site                                                                                                                                                         |
| 119 |    308.167026 |     38.736616 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 120 |    413.093535 |    329.884348 | Michael Day                                                                                                                                                           |
| 121 |    404.710043 |    454.094697 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 122 |    607.342686 |     98.968305 | Jaime Headden                                                                                                                                                         |
| 123 |    633.160199 |    784.501060 | Duane Raver/USFWS                                                                                                                                                     |
| 124 |    198.041242 |    380.963009 | Jaime Headden                                                                                                                                                         |
| 125 |    716.396203 |      7.234208 | Anna Willoughby                                                                                                                                                       |
| 126 |    656.746550 |    228.570023 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 127 |    401.099303 |    673.064311 | Ferran Sayol                                                                                                                                                          |
| 128 |    804.501426 |    139.471113 | Gareth Monger                                                                                                                                                         |
| 129 |    530.381986 |    665.955278 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 130 |    142.785553 |    573.091756 | Ignacio Contreras                                                                                                                                                     |
| 131 |    286.682104 |    325.680261 | Markus A. Grohme                                                                                                                                                      |
| 132 |    206.993934 |    220.703211 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 133 |    867.128090 |    649.720483 | Emily Willoughby                                                                                                                                                      |
| 134 |    302.371641 |    285.607614 | Matt Crook                                                                                                                                                            |
| 135 |     87.001836 |    278.717054 | David Orr                                                                                                                                                             |
| 136 |    990.942597 |    604.630508 | Zimices                                                                                                                                                               |
| 137 |    507.790024 |     42.006547 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 138 |    688.831475 |    784.193930 | Maija Karala                                                                                                                                                          |
| 139 |     53.717749 |    152.794112 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 140 |     35.317267 |    379.640253 | Jagged Fang Designs                                                                                                                                                   |
| 141 |    451.838613 |    386.619307 | Scott Hartman                                                                                                                                                         |
| 142 |    606.942308 |     78.419622 | Ferran Sayol                                                                                                                                                          |
| 143 |     15.397822 |    445.300793 | Jagged Fang Designs                                                                                                                                                   |
| 144 |    651.222542 |    270.433372 | Steven Traver                                                                                                                                                         |
| 145 |    997.740897 |    276.688588 | Michael P. Taylor                                                                                                                                                     |
| 146 |    424.775958 |    239.579833 | Ignacio Contreras                                                                                                                                                     |
| 147 |    423.739838 |    304.459811 | Kai R. Caspar                                                                                                                                                         |
| 148 |    551.931827 |    745.178921 | CNZdenek                                                                                                                                                              |
| 149 |     88.418979 |    545.640517 | Zimices                                                                                                                                                               |
| 150 |    144.757663 |    639.351599 | Ferran Sayol                                                                                                                                                          |
| 151 |     13.424546 |    635.720381 | Gareth Monger                                                                                                                                                         |
| 152 |    648.536406 |    353.452383 | Steven Traver                                                                                                                                                         |
| 153 |    473.485143 |    606.670274 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 154 |    496.973435 |    288.237070 | Gareth Monger                                                                                                                                                         |
| 155 |    915.649889 |    350.528873 | Gopal Murali                                                                                                                                                          |
| 156 |    744.448972 |    465.110537 | Scott Hartman                                                                                                                                                         |
| 157 |    165.824387 |    514.810703 | Matt Martyniuk                                                                                                                                                        |
| 158 |    326.353918 |    449.769539 | Skye McDavid                                                                                                                                                          |
| 159 |    676.839883 |    130.039194 | Gareth Monger                                                                                                                                                         |
| 160 |     50.359243 |    641.573856 | Michelle Site                                                                                                                                                         |
| 161 |    642.480756 |     13.361759 | Katie S. Collins                                                                                                                                                      |
| 162 |    348.375511 |    616.549166 | Matthew E. Clapham                                                                                                                                                    |
| 163 |    366.626867 |     38.956752 | Matt Crook                                                                                                                                                            |
| 164 |    776.653284 |    168.711637 | Dmitry Bogdanov                                                                                                                                                       |
| 165 |     85.453965 |    532.618149 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 166 |    872.865514 |    766.831654 | Matt Crook                                                                                                                                                            |
| 167 |    672.940242 |    542.172207 | Paul O. Lewis                                                                                                                                                         |
| 168 |    964.117670 |    582.276407 | Jagged Fang Designs                                                                                                                                                   |
| 169 |    633.212790 |    626.057372 | Zimices                                                                                                                                                               |
| 170 |   1009.832859 |    681.832464 | Natalie Claunch                                                                                                                                                       |
| 171 |    166.032574 |    555.964253 | Robert Gay                                                                                                                                                            |
| 172 |    576.499560 |    151.028648 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 173 |    730.128081 |    653.663735 | Renata F. Martins                                                                                                                                                     |
| 174 |   1011.954081 |    357.655631 | Estelle Bourdon                                                                                                                                                       |
| 175 |    157.343638 |    112.652022 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 176 |    830.744791 |    325.924824 | Matt Crook                                                                                                                                                            |
| 177 |    484.130505 |    364.723045 | Birgit Lang                                                                                                                                                           |
| 178 |    870.196311 |    471.105051 | Chris huh                                                                                                                                                             |
| 179 |    725.868943 |    776.776623 | T. Michael Keesey                                                                                                                                                     |
| 180 |    258.356800 |    529.508741 | NA                                                                                                                                                                    |
| 181 |    211.292599 |     56.335793 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 182 |    245.534760 |    227.938850 | Chris huh                                                                                                                                                             |
| 183 |    574.974280 |     91.204266 | NA                                                                                                                                                                    |
| 184 |    607.865436 |    504.817203 | Gareth Monger                                                                                                                                                         |
| 185 |    794.331638 |    211.034371 | Mattia Menchetti                                                                                                                                                      |
| 186 |    435.898248 |    256.444887 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 187 |    803.759447 |    294.013455 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 188 |    697.062720 |    723.992257 | Rebecca Groom                                                                                                                                                         |
| 189 |    449.656442 |    400.396660 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 190 |    863.548468 |    340.819393 | Markus A. Grohme                                                                                                                                                      |
| 191 |    250.298929 |    192.161211 | Jagged Fang Designs                                                                                                                                                   |
| 192 |    752.784885 |    372.303681 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 193 |    225.621113 |    596.685254 | Jagged Fang Designs                                                                                                                                                   |
| 194 |   1005.595014 |     51.643731 | Amanda Katzer                                                                                                                                                         |
| 195 |    857.402800 |    263.546662 | Scott Hartman                                                                                                                                                         |
| 196 |    607.457439 |    626.056692 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 197 |    820.487960 |    568.904742 | Harold N Eyster                                                                                                                                                       |
| 198 |    555.021173 |    725.294279 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 199 |    455.919749 |    558.791088 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 200 |    121.806871 |    785.383319 | Mattia Menchetti                                                                                                                                                      |
| 201 |    117.246522 |    439.745131 | Benchill                                                                                                                                                              |
| 202 |    970.361704 |    540.812742 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 203 |    208.127053 |    316.450146 | Zimices                                                                                                                                                               |
| 204 |    254.284682 |    433.903469 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                          |
| 205 |    360.695974 |    588.582602 | Scott Hartman                                                                                                                                                         |
| 206 |    183.667675 |    785.469812 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 207 |    921.319938 |    455.654675 | Caleb M. Brown                                                                                                                                                        |
| 208 |    637.299488 |     88.123500 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 209 |    599.353734 |    379.699213 | Kamil S. Jaron                                                                                                                                                        |
| 210 |    248.235281 |     23.439622 | Zimices                                                                                                                                                               |
| 211 |     26.701305 |    599.807119 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 212 |    952.632036 |     38.980223 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 213 |    156.950948 |     91.907552 | David Orr                                                                                                                                                             |
| 214 |    265.129626 |    276.837150 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 215 |     16.875013 |    146.747746 | xgirouxb                                                                                                                                                              |
| 216 |    983.754494 |    284.868459 | Darius Nau                                                                                                                                                            |
| 217 |    233.282605 |    755.286523 | Maija Karala                                                                                                                                                          |
| 218 |    445.793496 |    751.747032 | Tracy A. Heath                                                                                                                                                        |
| 219 |     50.808703 |    751.272865 | Chris huh                                                                                                                                                             |
| 220 |    682.910015 |     95.194579 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 221 |    431.075843 |    667.132105 | Ferran Sayol                                                                                                                                                          |
| 222 |    495.735697 |    613.625923 | Michael Scroggie                                                                                                                                                      |
| 223 |    119.372507 |    584.871431 | Sarah Alewijnse                                                                                                                                                       |
| 224 |    823.059158 |    260.692653 | Tracy A. Heath                                                                                                                                                        |
| 225 |    280.087135 |     26.242971 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 226 |    553.848827 |    262.641257 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 227 |    645.625114 |    519.801904 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 228 |    586.058470 |     12.486357 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 229 |    352.835402 |    171.233830 | Matt Crook                                                                                                                                                            |
| 230 |    667.918425 |    321.238366 | Sharon Wegner-Larsen                                                                                                                                                  |
| 231 |    350.320805 |    751.299827 | Myriam\_Ramirez                                                                                                                                                       |
| 232 |    789.110980 |    591.203260 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 233 |    393.521220 |    648.528007 | Catherine Yasuda                                                                                                                                                      |
| 234 |    942.428841 |    406.155772 | Courtney Rockenbach                                                                                                                                                   |
| 235 |    537.620486 |    315.801654 | Emily Willoughby                                                                                                                                                      |
| 236 |     15.216001 |    744.434606 | Scott Hartman                                                                                                                                                         |
| 237 |    394.804313 |    337.617002 | Jagged Fang Designs                                                                                                                                                   |
| 238 |    210.539842 |    624.073135 | Ferran Sayol                                                                                                                                                          |
| 239 |    719.600290 |    443.121793 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 240 |    362.705506 |    212.851330 | CNZdenek                                                                                                                                                              |
| 241 |    782.274461 |    157.876919 | Cesar Julian                                                                                                                                                          |
| 242 |    790.806172 |    783.204796 | Zimices                                                                                                                                                               |
| 243 |    877.378581 |    783.302775 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 244 |    545.391571 |    628.302584 | ArtFavor & annaleeblysse                                                                                                                                              |
| 245 |    995.324928 |    782.392491 | Steven Traver                                                                                                                                                         |
| 246 |    682.799033 |    234.465740 | Tauana J. Cunha                                                                                                                                                       |
| 247 |    453.622671 |    647.542043 | NA                                                                                                                                                                    |
| 248 |     67.093020 |    315.343705 | Zimices                                                                                                                                                               |
| 249 |    427.533255 |    533.162891 | Liftarn                                                                                                                                                               |
| 250 |   1003.713561 |    703.926595 | Terpsichores                                                                                                                                                          |
| 251 |    910.346429 |    485.415912 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 252 |    826.911103 |    154.774773 | Chris huh                                                                                                                                                             |
| 253 |     27.999614 |    400.224073 | Tasman Dixon                                                                                                                                                          |
| 254 |    989.976614 |    351.043467 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 255 |    162.699837 |    751.860934 | Noah Schlottman                                                                                                                                                       |
| 256 |    196.958341 |    356.109250 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 257 |    690.330741 |    751.564114 | Gareth Monger                                                                                                                                                         |
| 258 |    526.177923 |    486.077187 | Tracy A. Heath                                                                                                                                                        |
| 259 |    328.456572 |    434.776625 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                         |
| 260 |    785.181053 |    477.742917 | Matt Crook                                                                                                                                                            |
| 261 |    485.168584 |    121.977822 | M Kolmann                                                                                                                                                             |
| 262 |    706.002924 |    460.897281 | Mathew Wedel                                                                                                                                                          |
| 263 |    770.639352 |    540.725119 | Matt Crook                                                                                                                                                            |
| 264 |    257.079173 |    460.107489 | Margot Michaud                                                                                                                                                        |
| 265 |    914.135144 |    774.366872 | Erika Schumacher                                                                                                                                                      |
| 266 |    104.058550 |    127.846086 | Andy Wilson                                                                                                                                                           |
| 267 |   1000.119914 |    589.744335 | Steven Traver                                                                                                                                                         |
| 268 |    632.901511 |    412.682855 | Margot Michaud                                                                                                                                                        |
| 269 |     20.200546 |    682.295892 | NA                                                                                                                                                                    |
| 270 |    543.266893 |    430.637643 | Markus A. Grohme                                                                                                                                                      |
| 271 |    148.065902 |    591.886249 | FJDegrange                                                                                                                                                            |
| 272 |    574.126398 |    628.517817 | Steven Coombs                                                                                                                                                         |
| 273 |    211.739117 |    338.907624 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 274 |    179.291821 |    183.415507 | Steven Traver                                                                                                                                                         |
| 275 |    481.130297 |    149.636775 | Yan Wong                                                                                                                                                              |
| 276 |    326.819212 |     58.377610 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 277 |   1003.507874 |    646.822209 | Zimices                                                                                                                                                               |
| 278 |    119.860317 |    681.003280 | Markus A. Grohme                                                                                                                                                      |
| 279 |    848.698880 |    561.659622 | Gareth Monger                                                                                                                                                         |
| 280 |    843.058369 |    172.879022 | CNZdenek                                                                                                                                                              |
| 281 |     36.023537 |    134.282758 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 282 |    424.943909 |    422.544163 | Beth Reinke                                                                                                                                                           |
| 283 |    110.782693 |     59.793177 | Andy Wilson                                                                                                                                                           |
| 284 |    753.210751 |    178.970097 | Jagged Fang Designs                                                                                                                                                   |
| 285 |    864.063311 |    735.775684 | T. Michael Keesey                                                                                                                                                     |
| 286 |    876.033799 |    180.859936 | Kent Elson Sorgon                                                                                                                                                     |
| 287 |    805.115193 |    307.425802 | Matt Crook                                                                                                                                                            |
| 288 |    379.200833 |    616.513032 | Harold N Eyster                                                                                                                                                       |
| 289 |    807.442391 |      8.140681 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 290 |    893.893459 |    360.730949 | Shyamal                                                                                                                                                               |
| 291 |    253.995557 |    632.188558 | Matt Crook                                                                                                                                                            |
| 292 |    329.274048 |     48.513815 | Erika Schumacher                                                                                                                                                      |
| 293 |    805.393109 |    398.353466 | Dean Schnabel                                                                                                                                                         |
| 294 |    194.147299 |    164.617372 | Margot Michaud                                                                                                                                                        |
| 295 |    550.654937 |    224.606458 | Geoff Shaw                                                                                                                                                            |
| 296 |    893.551463 |    536.932209 | FJDegrange                                                                                                                                                            |
| 297 |     82.264525 |    343.788197 | Jagged Fang Designs                                                                                                                                                   |
| 298 |    214.958217 |     87.923680 | S.Martini                                                                                                                                                             |
| 299 |    572.734534 |    184.011196 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 300 |    887.877041 |    646.556063 | Emily Willoughby                                                                                                                                                      |
| 301 |    388.886222 |    752.890433 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 302 |     72.887668 |    368.169450 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 303 |    105.763383 |    574.204426 | Gareth Monger                                                                                                                                                         |
| 304 |    100.474412 |    384.837136 | Markus A. Grohme                                                                                                                                                      |
| 305 |    494.611121 |    636.767411 | Daniel Stadtmauer                                                                                                                                                     |
| 306 |    352.027648 |    286.913855 | Zimices                                                                                                                                                               |
| 307 |    479.058547 |    752.624125 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 308 |     17.978848 |    570.358129 | Markus A. Grohme                                                                                                                                                      |
| 309 |    155.397702 |    374.196969 | Steven Traver                                                                                                                                                         |
| 310 |    135.982736 |    305.962554 | Agnello Picorelli                                                                                                                                                     |
| 311 |    823.056859 |    473.472708 | Julio Garza                                                                                                                                                           |
| 312 |    624.726710 |    366.231893 | Matt Crook                                                                                                                                                            |
| 313 |    582.116052 |    521.048545 | Beth Reinke                                                                                                                                                           |
| 314 |    779.790771 |     62.602646 | NA                                                                                                                                                                    |
| 315 |    850.325348 |    390.839361 | S.Martini                                                                                                                                                             |
| 316 |    553.854707 |     33.886679 | Andy Wilson                                                                                                                                                           |
| 317 |     80.059826 |    674.696786 | Zimices                                                                                                                                                               |
| 318 |    118.392834 |    241.377573 | Kamil S. Jaron                                                                                                                                                        |
| 319 |     47.160435 |    738.390099 | Lafage                                                                                                                                                                |
| 320 |    472.810173 |    733.236805 | Scott Hartman                                                                                                                                                         |
| 321 |    508.843570 |    606.353995 | T. Michael Keesey                                                                                                                                                     |
| 322 |   1010.361849 |    102.543442 | Gareth Monger                                                                                                                                                         |
| 323 |    164.275594 |    722.951593 | Tasman Dixon                                                                                                                                                          |
| 324 |    543.454750 |    683.771307 | Andy Wilson                                                                                                                                                           |
| 325 |    996.855494 |     76.019196 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 326 |    438.431658 |    217.072829 | Ignacio Contreras                                                                                                                                                     |
| 327 |    983.377182 |      7.561825 | Melissa Broussard                                                                                                                                                     |
| 328 |    567.246467 |     67.850888 | John Conway                                                                                                                                                           |
| 329 |    100.382837 |    237.899803 | Margot Michaud                                                                                                                                                        |
| 330 |    193.294863 |     99.969460 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 331 |    332.798355 |     75.036185 | Matt Crook                                                                                                                                                            |
| 332 |    234.029238 |    631.142982 | Melissa Broussard                                                                                                                                                     |
| 333 |    532.205462 |    719.141183 | Nina Skinner                                                                                                                                                          |
| 334 |    121.785792 |    565.882288 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 335 |    885.099862 |    738.355222 | Lauren Anderson                                                                                                                                                       |
| 336 |    700.541025 |    218.678987 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 337 |    944.894380 |    595.745714 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 338 |    399.370636 |      9.601393 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 339 |    485.126126 |    584.021387 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 340 |    125.848733 |    654.296197 | Christoph Schomburg                                                                                                                                                   |
| 341 |    645.130038 |    147.917964 | Birgit Lang                                                                                                                                                           |
| 342 |     40.490212 |    544.584743 | Zimices                                                                                                                                                               |
| 343 |    467.600348 |    791.243695 | Matt Dempsey                                                                                                                                                          |
| 344 |    810.108234 |    550.904084 | Erika Schumacher                                                                                                                                                      |
| 345 |    763.942527 |    299.932327 | Joanna Wolfe                                                                                                                                                          |
| 346 |    394.648756 |    472.953109 | Matt Crook                                                                                                                                                            |
| 347 |    173.517435 |    404.774589 | Terpsichores                                                                                                                                                          |
| 348 |    996.983618 |    444.585212 | L. Shyamal                                                                                                                                                            |
| 349 |    645.346570 |    458.169653 | Matt Crook                                                                                                                                                            |
| 350 |    915.645674 |    165.251277 | Rebecca Groom                                                                                                                                                         |
| 351 |    153.266456 |    545.277050 | FunkMonk                                                                                                                                                              |
| 352 |    279.459254 |    596.908959 | Chris huh                                                                                                                                                             |
| 353 |    685.546770 |     70.238706 | Steven Traver                                                                                                                                                         |
| 354 |    464.503725 |    131.207450 | Tauana J. Cunha                                                                                                                                                       |
| 355 |     10.398335 |    284.952791 | T. Michael Keesey (after Mivart)                                                                                                                                      |
| 356 |    256.927700 |    210.842769 | B. Duygu Özpolat                                                                                                                                                      |
| 357 |    850.645991 |    629.436215 | Margot Michaud                                                                                                                                                        |
| 358 |    397.483449 |    240.002492 | NASA                                                                                                                                                                  |
| 359 |    415.139855 |    727.364481 | Benjamin Monod-Broca                                                                                                                                                  |
| 360 |    624.317430 |    689.325818 | Jagged Fang Designs                                                                                                                                                   |
| 361 |     87.638200 |    474.062907 | NA                                                                                                                                                                    |
| 362 |    535.341321 |    646.788862 | Yusan Yang                                                                                                                                                            |
| 363 |    147.356601 |    774.287884 | Lukas Panzarin                                                                                                                                                        |
| 364 |     27.770477 |    629.268752 | Gareth Monger                                                                                                                                                         |
| 365 |    305.272402 |    591.432136 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 366 |    557.736083 |    320.903277 | Ferran Sayol                                                                                                                                                          |
| 367 |    373.618127 |    266.012782 | Steven Traver                                                                                                                                                         |
| 368 |    164.523549 |    709.451710 | Scott Hartman                                                                                                                                                         |
| 369 |    937.615053 |    367.045539 | Rafael Maia                                                                                                                                                           |
| 370 |     72.514957 |    791.245942 | Maxime Dahirel                                                                                                                                                        |
| 371 |    605.106572 |     22.180409 | Markus A. Grohme                                                                                                                                                      |
| 372 |    829.979967 |    427.626191 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 373 |    636.555639 |    377.214241 | Sarah Alewijnse                                                                                                                                                       |
| 374 |    642.325142 |     70.904980 | Ferran Sayol                                                                                                                                                          |
| 375 |     65.205836 |    389.311971 | Scott Hartman                                                                                                                                                         |
| 376 |    892.532442 |    674.701663 | Michelle Site                                                                                                                                                         |
| 377 |    855.105339 |     44.495080 | Chris huh                                                                                                                                                             |
| 378 |    316.612604 |    335.174251 | Chris huh                                                                                                                                                             |
| 379 |    301.983640 |    316.898843 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 380 |    879.779362 |    429.321278 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 381 |    627.777289 |    142.142450 | Andy Wilson                                                                                                                                                           |
| 382 |    398.676662 |     32.208466 | Noah Schlottman                                                                                                                                                       |
| 383 |    666.887046 |    685.492097 | Gareth Monger                                                                                                                                                         |
| 384 |     24.685025 |    664.153549 | Collin Gross                                                                                                                                                          |
| 385 |    244.114676 |    768.290335 | Xavier Giroux-Bougard                                                                                                                                                 |
| 386 |   1009.318481 |    288.618792 | Gareth Monger                                                                                                                                                         |
| 387 |    939.852327 |    126.330121 | Carlos Cano-Barbacil                                                                                                                                                  |
| 388 |    981.824348 |    790.779115 | NA                                                                                                                                                                    |
| 389 |    492.009518 |    649.251177 | Felix Vaux                                                                                                                                                            |
| 390 |    731.049978 |    366.259343 | Anna Willoughby                                                                                                                                                       |
| 391 |    567.400549 |    507.254337 | Markus A. Grohme                                                                                                                                                      |
| 392 |    953.633118 |    793.105118 | Noah Schlottman                                                                                                                                                       |
| 393 |    986.735872 |    560.362586 | Tauana J. Cunha                                                                                                                                                       |
| 394 |    685.795939 |    672.074437 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 395 |    210.795503 |     29.908936 | Becky Barnes                                                                                                                                                          |
| 396 |    768.151818 |     11.432250 | Zimices                                                                                                                                                               |
| 397 |    359.269563 |    433.127483 | Zimices                                                                                                                                                               |
| 398 |    541.104309 |    414.243294 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 399 |    208.146220 |    727.410643 | Lafage                                                                                                                                                                |
| 400 |    515.669386 |    457.535651 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 401 |     17.354602 |    361.615606 | Zimices                                                                                                                                                               |
| 402 |    975.872858 |    693.313778 | Chris huh                                                                                                                                                             |
| 403 |    612.867991 |    525.684632 | Jagged Fang Designs                                                                                                                                                   |
| 404 |    557.053334 |    658.075203 | NA                                                                                                                                                                    |
| 405 |    686.111964 |    267.921411 | Margot Michaud                                                                                                                                                        |
| 406 |    116.776142 |    622.266799 | Emily Willoughby                                                                                                                                                      |
| 407 |    721.533593 |     35.891390 | Jagged Fang Designs                                                                                                                                                   |
| 408 |    112.726024 |    598.498329 | Jagged Fang Designs                                                                                                                                                   |
| 409 |    692.260519 |    301.778196 | Margot Michaud                                                                                                                                                        |
| 410 |    438.147922 |    230.099289 | Christoph Schomburg                                                                                                                                                   |
| 411 |     60.215506 |    169.196653 | Ieuan Jones                                                                                                                                                           |
| 412 |    309.993354 |    211.417360 | Zimices                                                                                                                                                               |
| 413 |    984.343166 |    261.843290 | Scott Hartman                                                                                                                                                         |
| 414 |    411.345285 |    792.665940 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 415 |    201.827802 |    786.425204 | Nick Schooler                                                                                                                                                         |
| 416 |    397.058375 |    690.204588 | Erika Schumacher                                                                                                                                                      |
| 417 |    309.711044 |    413.350127 | Margot Michaud                                                                                                                                                        |
| 418 |    743.454112 |    252.290453 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 419 |    548.283990 |    702.583487 | Gareth Monger                                                                                                                                                         |
| 420 |    206.552228 |    766.344156 | Gareth Monger                                                                                                                                                         |
| 421 |    843.812561 |    246.171081 | Xavier Giroux-Bougard                                                                                                                                                 |
| 422 |    933.384727 |    254.496782 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 423 |    602.769473 |    454.412135 | Gareth Monger                                                                                                                                                         |
| 424 |    706.071294 |     15.524938 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 425 |    511.252657 |    118.101302 | Fernando Campos De Domenico                                                                                                                                           |
| 426 |     58.730973 |      5.487487 | Gareth Monger                                                                                                                                                         |
| 427 |    191.034675 |    308.995774 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 428 |    871.315933 |    550.906153 | T. Tischler                                                                                                                                                           |
| 429 |    821.385543 |     45.056114 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 430 |     70.311486 |    121.796113 | Zimices                                                                                                                                                               |
| 431 |    285.149975 |    351.120453 | Chris huh                                                                                                                                                             |
| 432 |    569.763409 |     21.791656 | Shyamal                                                                                                                                                               |
| 433 |    802.417656 |    224.670384 | Margot Michaud                                                                                                                                                        |
| 434 |    873.490177 |     49.087110 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 435 |    987.467972 |     28.968077 | Milton Tan                                                                                                                                                            |
| 436 |    507.485075 |      7.305074 | Jaime Headden                                                                                                                                                         |
| 437 |     45.725024 |    341.832936 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 438 |     15.122281 |    778.704615 | Scott Hartman                                                                                                                                                         |
| 439 |    799.438913 |    101.133680 | Chuanixn Yu                                                                                                                                                           |
| 440 |    250.630127 |      5.173687 | Margot Michaud                                                                                                                                                        |
| 441 |    407.465733 |    355.776469 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 442 |    253.888725 |     63.165239 | Sarah Werning                                                                                                                                                         |
| 443 |    615.586478 |    230.652808 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 444 |      8.627968 |    722.885476 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 445 |    996.244696 |    627.144947 | Andy Wilson                                                                                                                                                           |
| 446 |    700.774683 |    561.656824 | Tasman Dixon                                                                                                                                                          |
| 447 |    348.960225 |     49.846102 | Gareth Monger                                                                                                                                                         |
| 448 |    154.996235 |    304.010424 | Zimices                                                                                                                                                               |
| 449 |    855.429854 |    150.944267 | NA                                                                                                                                                                    |
| 450 |    547.034975 |     82.600284 | Mark Witton                                                                                                                                                           |
| 451 |    160.045434 |    126.828107 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 452 |    864.819241 |    377.197829 | Markus A. Grohme                                                                                                                                                      |
| 453 |    785.885759 |    678.844667 | Walter Vladimir                                                                                                                                                       |
| 454 |    864.586466 |    333.644787 | Julio Garza                                                                                                                                                           |
| 455 |    836.590598 |    749.418160 | Kai R. Caspar                                                                                                                                                         |
| 456 |     17.991678 |     19.841932 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 457 |     42.228296 |    481.702203 | Jagged Fang Designs                                                                                                                                                   |
| 458 |    462.743699 |    346.123247 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 459 |    292.546449 |    400.674608 | Gareth Monger                                                                                                                                                         |
| 460 |    453.990436 |    173.291229 | Scott Hartman                                                                                                                                                         |
| 461 |   1014.973122 |    258.802445 | Gareth Monger                                                                                                                                                         |
| 462 |    210.652034 |    549.019175 | Qiang Ou                                                                                                                                                              |
| 463 |    901.776419 |    466.489086 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 464 |     13.924836 |    102.505698 | T. Michael Keesey                                                                                                                                                     |
| 465 |    384.953738 |    403.272311 | Felix Vaux                                                                                                                                                            |
| 466 |    278.584253 |    750.785183 | Chris huh                                                                                                                                                             |
| 467 |    752.325086 |    776.230841 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 468 |    125.619487 |    613.926398 | C. Camilo Julián-Caballero                                                                                                                                            |
| 469 |    192.372615 |    719.630033 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 470 |    136.343432 |    326.527436 | NA                                                                                                                                                                    |
| 471 |    113.067120 |     13.414985 | Jagged Fang Designs                                                                                                                                                   |
| 472 |    766.764255 |    342.284621 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 473 |    812.821283 |    128.405575 | Ferran Sayol                                                                                                                                                          |
| 474 |    128.749452 |    478.723549 | Matt Crook                                                                                                                                                            |
| 475 |    660.754575 |    668.654939 | Smokeybjb                                                                                                                                                             |
| 476 |    770.067278 |    407.340448 | Andy Wilson                                                                                                                                                           |
| 477 |    517.859212 |    789.023803 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 478 |    474.987016 |    376.271814 | Mark Witton                                                                                                                                                           |
| 479 |    536.963937 |    446.160344 | Jagged Fang Designs                                                                                                                                                   |
| 480 |    903.418412 |    334.105194 | Matt Crook                                                                                                                                                            |
| 481 |    582.420117 |    267.748184 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 482 |    641.590984 |    101.152247 | Scott Hartman                                                                                                                                                         |
| 483 |    274.739130 |    313.364466 | Tasman Dixon                                                                                                                                                          |
| 484 |    339.359005 |    758.779259 | NA                                                                                                                                                                    |
| 485 |     41.424044 |    526.864924 | Cesar Julian                                                                                                                                                          |
| 486 |    589.814457 |    336.983526 | Alex Slavenko                                                                                                                                                         |
| 487 |   1007.419084 |    431.531053 | Mette Aumala                                                                                                                                                          |
| 488 |    652.365902 |    768.130760 | Pete Buchholz                                                                                                                                                         |
| 489 |    440.914839 |    116.705721 | Riccardo Percudani                                                                                                                                                    |
| 490 |     41.936603 |    365.866222 | Gareth Monger                                                                                                                                                         |
| 491 |    117.574035 |    545.667461 | Steven Traver                                                                                                                                                         |
| 492 |    553.450838 |    100.433121 | Emma Hughes                                                                                                                                                           |
| 493 |    883.763236 |    792.734222 | Tasman Dixon                                                                                                                                                          |
| 494 |    633.363534 |     23.286300 | Mathew Wedel                                                                                                                                                          |
| 495 |    524.621177 |    504.324159 | Carlos Cano-Barbacil                                                                                                                                                  |
| 496 |    136.653980 |      7.653352 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 497 |     61.250140 |    614.616305 | Roberto Díaz Sibaja                                                                                                                                                   |
| 498 |    381.181586 |    329.972106 | Christoph Schomburg                                                                                                                                                   |
| 499 |    829.009585 |    274.702593 | Birgit Lang                                                                                                                                                           |
| 500 |    382.773723 |    299.017475 | Matt Martyniuk                                                                                                                                                        |
| 501 |    461.165302 |    525.739815 | Emma Kissling                                                                                                                                                         |
| 502 |    142.194000 |    139.237216 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 503 |    790.575191 |    760.151462 | John Conway                                                                                                                                                           |
| 504 |    294.267351 |    793.994734 | Jagged Fang Designs                                                                                                                                                   |
| 505 |     60.957341 |    160.236781 | Jagged Fang Designs                                                                                                                                                   |
| 506 |    403.760808 |    163.703037 | Scott Hartman                                                                                                                                                         |
| 507 |    725.425477 |    160.205677 | Erika Schumacher                                                                                                                                                      |
| 508 |    798.153386 |    569.117537 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 509 |    511.971619 |     52.798773 | NA                                                                                                                                                                    |
| 510 |    191.049113 |    171.249698 | Jagged Fang Designs                                                                                                                                                   |
| 511 |    580.205286 |    244.072017 | Scott Reid                                                                                                                                                            |
| 512 |    497.872773 |    389.391182 | Ignacio Contreras                                                                                                                                                     |
| 513 |    620.777830 |    437.121292 | Gareth Monger                                                                                                                                                         |
| 514 |    321.800043 |    165.245137 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 515 |    738.525146 |    224.058429 | Tracy A. Heath                                                                                                                                                        |
| 516 |    388.021467 |    320.050723 | Chris huh                                                                                                                                                             |
| 517 |    625.954679 |    158.444515 | Collin Gross                                                                                                                                                          |
| 518 |    754.039023 |    267.614313 | Jaime Headden                                                                                                                                                         |
| 519 |    289.136124 |    359.741547 | Scott Hartman                                                                                                                                                         |
| 520 |    447.554892 |    409.998624 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 521 |    946.756941 |    425.063674 | Chris huh                                                                                                                                                             |
| 522 |    591.533207 |     93.625668 | Smokeybjb                                                                                                                                                             |
| 523 |    461.970091 |    300.055418 | Zimices                                                                                                                                                               |

    #> Your tweet has been posted!
