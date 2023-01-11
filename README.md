
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

Dean Schnabel, C. Camilo Julián-Caballero, T. Michael Keesey, Zimices,
Kamil S. Jaron, S.Martini, Margot Michaud, Tracy A. Heath, Robbie N.
Cada (vectorized by T. Michael Keesey), Chris huh, Harold N Eyster, Iain
Reid, Gareth Monger, Noah Schlottman, photo by Carol Cummings, Anthony
Caravaggi, Jagged Fang Designs, Tauana J. Cunha, Andy Wilson, Matt
Martyniuk, Michelle Site, Nobu Tamura, vectorized by Zimices, Mathieu
Basille, Birgit Lang, Sergio A. Muñoz-Gómez, Steven Traver, FunkMonk
\[Michael B.H.\] (modified by T. Michael Keesey), Elizabeth Parker, Matt
Crook, Jessica Anne Miller, Ignacio Contreras, Scott Hartman,
Falconaumanni and T. Michael Keesey, James I. Kirkland, Luis Alcalá,
Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Danielle Alba, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), M Kolmann, Becky
Barnes, Tasman Dixon, Markus A. Grohme, Philippe Janvier (vectorized by
T. Michael Keesey), Arthur S. Brum, Mo Hassan, Steven Coombs (vectorized
by T. Michael Keesey), Emily Willoughby, Cathy, Tony Ayling, Todd
Marshall, vectorized by Zimices, Sarah Werning, Ingo Braasch, Gabriela
Palomo-Munoz, Myriam\_Ramirez, Richard Parker (vectorized by T. Michael
Keesey), Erika Schumacher, Nobu Tamura (vectorized by T. Michael
Keesey), Carlos Cano-Barbacil, Alexander Schmidt-Lebuhn, B. Duygu
Özpolat, Noah Schlottman, Acrocynus (vectorized by T. Michael Keesey),
Lafage, Ferran Sayol, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Karl Ragnar Gjertsen (vectorized by T. Michael Keesey), Maxime Dahirel,
Shyamal, DW Bapst (modified from Mitchell 1990), Neil Kelley, Smokeybjb,
Fernando Carezzano, Espen Horn (model; vectorized by T. Michael Keesey
from a photo by H. Zell), Yan Wong from wikipedia drawing (PD: Pearson
Scott Foresman), Mette Aumala, Allison Pease, David Orr, Joseph Smit
(modified by T. Michael Keesey), Nick Schooler, Matt Celeskey, Sarefo
(vectorized by T. Michael Keesey), Juan Carlos Jerí, NOAA (vectorized by
T. Michael Keesey), Rebecca Groom, Burton Robert, USFWS, Katie S.
Collins, Jake Warner, Jakovche, terngirl, Mathew Wedel, Darren Naish
(vectorized by T. Michael Keesey), Felix Vaux, Xavier Giroux-Bougard,
Nina Skinner, Sharon Wegner-Larsen, Caroline Harding, MAF (vectorized by
T. Michael Keesey), Scarlet23 (vectorized by T. Michael Keesey), Jose
Carlos Arenas-Monroy, Beth Reinke, Scott Reid, Sean McCann, FunkMonk,
Eduard Solà (vectorized by T. Michael Keesey), Cesar Julian, Smokeybjb
(vectorized by T. Michael Keesey), NASA, Kai R. Caspar, Lauren Anderson,
Bryan Carstens, Jonathan Wells, Skye McDavid, Oscar Sanisidro, Collin
Gross, L. Shyamal, Christoph Schomburg, T. Michael Keesey (vector) and
Stuart Halliday (photograph), Lukasiniho, Mareike C. Janiak, Mykle
Hoban, Josefine Bohr Brask, Mercedes Yrayzoz (vectorized by T. Michael
Keesey), Jaime Headden, modified by T. Michael Keesey, Adrian Reich,
Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey
(vectorization), Oren Peles / vectorized by Yan Wong, Henry Lydecker,
Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Caleb M. Brown, Ricardo
Araújo, SauropodomorphMonarch, T. Michael Keesey (after Mivart), Manabu
Bessho-Uehara, Joanna Wolfe, Abraão Leite, Jessica Rick, Alex Slavenko,
Noah Schlottman, photo from Casey Dunn, Martin R. Smith, Robbie N. Cada
(modified by T. Michael Keesey), Yan Wong, Thibaut Brunet, Milton Tan,
Mali’o Kodis, photograph by Hans Hillewaert, Jon Hill, Maija Karala,
Armin Reindl, Kanchi Nanjo, Hugo Gruson, Henry Fairfield Osborn,
vectorized by Zimices, Karla Martinez, Philip Chalmers (vectorized by T.
Michael Keesey), Matt Dempsey, Daniel Stadtmauer, Konsta Happonen, from
a CC-BY-NC image by pelhonen on iNaturalist, Darius Nau, Steven Haddock
• Jellywatch.org, xgirouxb, Theodore W. Pietsch (photography) and T.
Michael Keesey (vectorization), Michael Scroggie, Christopher Watson
(photo) and T. Michael Keesey (vectorization), Ernst Haeckel (vectorized
by T. Michael Keesey), Estelle Bourdon, Dmitry Bogdanov (modified by T.
Michael Keesey), Ellen Edmonson and Hugh Chrisp (vectorized by T.
Michael Keesey), Bennet McComish, photo by Avenue, Jiekun He, Mathieu
Pélissié, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Julio Garza, Michael P. Taylor,
Duane Raver (vectorized by T. Michael Keesey), Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Aviceda (photo) & T.
Michael Keesey, Mariana Ruiz Villarreal

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                  |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    163.338464 |     81.520120 | Dean Schnabel                                                                                                                                           |
|   2 |    498.046035 |    668.560598 | C. Camilo Julián-Caballero                                                                                                                              |
|   3 |    875.379392 |    689.308207 | T. Michael Keesey                                                                                                                                       |
|   4 |    278.299247 |    386.633273 | Zimices                                                                                                                                                 |
|   5 |    544.089560 |     90.011343 | Kamil S. Jaron                                                                                                                                          |
|   6 |    310.970061 |    499.701617 | S.Martini                                                                                                                                               |
|   7 |    622.288785 |    439.473142 | Margot Michaud                                                                                                                                          |
|   8 |     63.386489 |    356.773392 | Tracy A. Heath                                                                                                                                          |
|   9 |    756.531235 |    258.632569 | Margot Michaud                                                                                                                                          |
|  10 |    882.456263 |    506.818448 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                        |
|  11 |    745.124604 |    148.209111 | Chris huh                                                                                                                                               |
|  12 |    752.554565 |    557.554297 | T. Michael Keesey                                                                                                                                       |
|  13 |    146.898010 |    528.098486 | NA                                                                                                                                                      |
|  14 |    687.486449 |    729.668300 | Harold N Eyster                                                                                                                                         |
|  15 |    199.384994 |    631.254303 | Margot Michaud                                                                                                                                          |
|  16 |    404.310871 |    720.960959 | Margot Michaud                                                                                                                                          |
|  17 |    949.236476 |    185.072167 | Iain Reid                                                                                                                                               |
|  18 |    264.264129 |    711.207039 | Gareth Monger                                                                                                                                           |
|  19 |    509.231324 |    604.913690 | C. Camilo Julián-Caballero                                                                                                                              |
|  20 |    785.325388 |    628.511092 | Noah Schlottman, photo by Carol Cummings                                                                                                                |
|  21 |    421.044731 |    271.268594 | Anthony Caravaggi                                                                                                                                       |
|  22 |    344.176315 |     91.659134 | Jagged Fang Designs                                                                                                                                     |
|  23 |     70.031152 |    209.321143 | Tauana J. Cunha                                                                                                                                         |
|  24 |    274.076107 |    238.908312 | Andy Wilson                                                                                                                                             |
|  25 |    846.721795 |    420.317478 | Matt Martyniuk                                                                                                                                          |
|  26 |    320.741409 |     40.280910 | Michelle Site                                                                                                                                           |
|  27 |    160.767502 |    305.682919 | Andy Wilson                                                                                                                                             |
|  28 |    174.094156 |    587.512383 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
|  29 |    496.012488 |    550.090466 | Zimices                                                                                                                                                 |
|  30 |    484.963192 |    754.570335 | Jagged Fang Designs                                                                                                                                     |
|  31 |    115.394428 |    739.745736 | Mathieu Basille                                                                                                                                         |
|  32 |    924.062587 |     59.596984 | Jagged Fang Designs                                                                                                                                     |
|  33 |    961.546868 |    299.836988 | Birgit Lang                                                                                                                                             |
|  34 |    593.154355 |    308.945949 | Sergio A. Muñoz-Gómez                                                                                                                                   |
|  35 |    448.347782 |    443.517328 | Steven Traver                                                                                                                                           |
|  36 |    883.076192 |     89.401458 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                               |
|  37 |    840.197032 |    228.261428 | Elizabeth Parker                                                                                                                                        |
|  38 |    702.623068 |    100.422766 | T. Michael Keesey                                                                                                                                       |
|  39 |    176.359218 |    437.291819 | T. Michael Keesey                                                                                                                                       |
|  40 |     70.783653 |    670.442657 | Matt Crook                                                                                                                                              |
|  41 |     43.272708 |    119.643406 | Jessica Anne Miller                                                                                                                                     |
|  42 |     95.994317 |    441.296137 | Ignacio Contreras                                                                                                                                       |
|  43 |    364.786997 |    193.988817 | Scott Hartman                                                                                                                                           |
|  44 |    943.936856 |    618.793580 | Matt Crook                                                                                                                                              |
|  45 |    929.876650 |    402.901033 | Falconaumanni and T. Michael Keesey                                                                                                                     |
|  46 |     42.039846 |    552.619088 | T. Michael Keesey                                                                                                                                       |
|  47 |    215.987346 |    177.201821 | Matt Crook                                                                                                                                              |
|  48 |    254.456825 |    343.106338 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                    |
|  49 |    958.315586 |    740.839568 | Danielle Alba                                                                                                                                           |
|  50 |    596.151513 |    194.117992 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                       |
|  51 |    218.372176 |    486.696081 | M Kolmann                                                                                                                                               |
|  52 |    399.465636 |    143.232281 | Becky Barnes                                                                                                                                            |
|  53 |    991.084086 |    405.919782 | T. Michael Keesey                                                                                                                                       |
|  54 |     92.686816 |    483.723201 | Tasman Dixon                                                                                                                                            |
|  55 |    961.416458 |     13.468296 | Markus A. Grohme                                                                                                                                        |
|  56 |    799.815586 |    675.334085 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                      |
|  57 |    679.225339 |    639.927455 | Arthur S. Brum                                                                                                                                          |
|  58 |    716.617192 |     31.472327 | Mo Hassan                                                                                                                                               |
|  59 |    366.725707 |    573.144738 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                         |
|  60 |    441.561403 |    381.389953 | Tasman Dixon                                                                                                                                            |
|  61 |    840.157705 |    772.740474 | Emily Willoughby                                                                                                                                        |
|  62 |    578.429886 |     19.199212 | Scott Hartman                                                                                                                                           |
|  63 |    744.868575 |    458.041508 | Cathy                                                                                                                                                   |
|  64 |    861.949621 |    121.604768 | Ignacio Contreras                                                                                                                                       |
|  65 |    323.564742 |    640.081000 | Tony Ayling                                                                                                                                             |
|  66 |    863.529201 |    543.117527 | NA                                                                                                                                                      |
|  67 |     60.138039 |    255.941398 | Margot Michaud                                                                                                                                          |
|  68 |    942.727171 |    236.836762 | Todd Marshall, vectorized by Zimices                                                                                                                    |
|  69 |    318.794667 |    450.246777 | Margot Michaud                                                                                                                                          |
|  70 |     62.500589 |     22.561845 | Sarah Werning                                                                                                                                           |
|  71 |    607.259613 |    535.292833 | Ingo Braasch                                                                                                                                            |
|  72 |    571.193137 |    717.654578 | Scott Hartman                                                                                                                                           |
|  73 |     78.919097 |    772.343655 | Gabriela Palomo-Munoz                                                                                                                                   |
|  74 |   1004.980999 |    109.156134 | Michelle Site                                                                                                                                           |
|  75 |    351.486511 |    778.256561 | T. Michael Keesey                                                                                                                                       |
|  76 |      8.176835 |    518.830874 | Gareth Monger                                                                                                                                           |
|  77 |    357.452607 |    408.445244 | Myriam\_Ramirez                                                                                                                                         |
|  78 |    747.056971 |    750.064519 | Tasman Dixon                                                                                                                                            |
|  79 |    863.047070 |    306.362291 | Tasman Dixon                                                                                                                                            |
|  80 |    617.763889 |    677.527597 | Markus A. Grohme                                                                                                                                        |
|  81 |    789.798291 |    380.244358 | Scott Hartman                                                                                                                                           |
|  82 |    972.994105 |    518.580473 | Margot Michaud                                                                                                                                          |
|  83 |    511.281894 |    345.412975 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                        |
|  84 |    274.921955 |    563.985206 | Chris huh                                                                                                                                               |
|  85 |    129.572663 |    394.441663 | Sergio A. Muñoz-Gómez                                                                                                                                   |
|  86 |    715.258181 |     73.857661 | T. Michael Keesey                                                                                                                                       |
|  87 |    178.393985 |    703.301064 | Erika Schumacher                                                                                                                                        |
|  88 |    616.122254 |    772.416331 | Scott Hartman                                                                                                                                           |
|  89 |    404.292299 |     69.722507 | Anthony Caravaggi                                                                                                                                       |
|  90 |    294.915069 |    676.279083 | Zimices                                                                                                                                                 |
|  91 |    437.969351 |    506.280095 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
|  92 |    285.898140 |    788.930747 | Scott Hartman                                                                                                                                           |
|  93 |    830.498065 |    163.483204 | Ignacio Contreras                                                                                                                                       |
|  94 |    816.855461 |     16.140443 | Carlos Cano-Barbacil                                                                                                                                    |
|  95 |    906.286193 |    246.752881 | Kamil S. Jaron                                                                                                                                          |
|  96 |    966.801246 |    702.397190 | Jagged Fang Designs                                                                                                                                     |
|  97 |     10.678342 |    360.041825 | Alexander Schmidt-Lebuhn                                                                                                                                |
|  98 |    648.656029 |    351.164341 | Gareth Monger                                                                                                                                           |
|  99 |    367.262290 |    664.604018 | Steven Traver                                                                                                                                           |
| 100 |    130.191344 |    137.375870 | B. Duygu Özpolat                                                                                                                                        |
| 101 |    987.131894 |    477.734892 | Noah Schlottman                                                                                                                                         |
| 102 |    923.155597 |    723.094605 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                             |
| 103 |    855.908335 |    147.542128 | Lafage                                                                                                                                                  |
| 104 |    162.368278 |     26.119317 | Kamil S. Jaron                                                                                                                                          |
| 105 |    860.780730 |    572.511187 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 106 |    675.154893 |    465.793882 | Gareth Monger                                                                                                                                           |
| 107 |    619.374375 |    154.884388 | Gabriela Palomo-Munoz                                                                                                                                   |
| 108 |    507.196971 |    206.975466 | Zimices                                                                                                                                                 |
| 109 |    118.665714 |    628.130227 | Andy Wilson                                                                                                                                             |
| 110 |    246.949880 |    143.521124 | Ferran Sayol                                                                                                                                            |
| 111 |    399.594220 |    491.734630 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 112 |    530.175305 |    286.197216 | Margot Michaud                                                                                                                                          |
| 113 |    458.045909 |    241.189949 | Zimices                                                                                                                                                 |
| 114 |    204.407942 |    678.904990 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                  |
| 115 |    606.220139 |    245.450238 | Maxime Dahirel                                                                                                                                          |
| 116 |    489.585688 |    152.582785 | Steven Traver                                                                                                                                           |
| 117 |    432.398261 |     18.666311 | Gareth Monger                                                                                                                                           |
| 118 |    103.601680 |    588.773902 | Matt Crook                                                                                                                                              |
| 119 |    771.106458 |    521.883532 | Birgit Lang                                                                                                                                             |
| 120 |    270.112865 |     90.822836 | NA                                                                                                                                                      |
| 121 |    274.130351 |    545.820393 | Markus A. Grohme                                                                                                                                        |
| 122 |    552.339037 |    171.493757 | Shyamal                                                                                                                                                 |
| 123 |    691.784899 |    660.759562 | Chris huh                                                                                                                                               |
| 124 |    610.667835 |     44.130827 | Steven Traver                                                                                                                                           |
| 125 |    274.183172 |    582.333714 | DW Bapst (modified from Mitchell 1990)                                                                                                                  |
| 126 |    354.395525 |    792.669080 | T. Michael Keesey                                                                                                                                       |
| 127 |    540.042718 |    788.147966 | Steven Traver                                                                                                                                           |
| 128 |    811.519100 |    334.991439 | Gabriela Palomo-Munoz                                                                                                                                   |
| 129 |    577.949170 |    373.716408 | Ferran Sayol                                                                                                                                            |
| 130 |    407.397377 |    114.620975 | Margot Michaud                                                                                                                                          |
| 131 |    141.063061 |    455.722353 | Neil Kelley                                                                                                                                             |
| 132 |    242.736515 |    431.181967 | Ferran Sayol                                                                                                                                            |
| 133 |    427.338663 |    184.317977 | Smokeybjb                                                                                                                                               |
| 134 |    688.165676 |     86.518139 | Margot Michaud                                                                                                                                          |
| 135 |    220.271749 |     43.612241 | Anthony Caravaggi                                                                                                                                       |
| 136 |    191.841152 |    750.203043 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 137 |    394.261398 |     16.795958 | Matt Crook                                                                                                                                              |
| 138 |    235.829870 |      7.761995 | Scott Hartman                                                                                                                                           |
| 139 |    623.936682 |     84.062521 | Fernando Carezzano                                                                                                                                      |
| 140 |    828.556446 |     55.654846 | Andy Wilson                                                                                                                                             |
| 141 |    315.633978 |    153.094273 | Gareth Monger                                                                                                                                           |
| 142 |    674.864943 |    527.182289 | Andy Wilson                                                                                                                                             |
| 143 |    723.215719 |    316.981996 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                             |
| 144 |    222.028693 |    364.745686 | Steven Traver                                                                                                                                           |
| 145 |    382.859938 |    525.935024 | Gareth Monger                                                                                                                                           |
| 146 |    633.820372 |    794.810323 | Steven Traver                                                                                                                                           |
| 147 |    686.737989 |    562.435514 | T. Michael Keesey                                                                                                                                       |
| 148 |    632.468637 |    172.246615 | Matt Crook                                                                                                                                              |
| 149 |    733.779979 |    635.703618 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                            |
| 150 |     22.309708 |    293.040009 | Gareth Monger                                                                                                                                           |
| 151 |    271.691399 |    629.729420 | Mette Aumala                                                                                                                                            |
| 152 |    745.471579 |    776.689709 | Allison Pease                                                                                                                                           |
| 153 |    906.537248 |    484.738409 | Jagged Fang Designs                                                                                                                                     |
| 154 |    981.843410 |    194.337124 | David Orr                                                                                                                                               |
| 155 |    948.315038 |    156.211902 | Joseph Smit (modified by T. Michael Keesey)                                                                                                             |
| 156 |    388.501225 |    330.015747 | Harold N Eyster                                                                                                                                         |
| 157 |    221.896488 |    779.086060 | Nick Schooler                                                                                                                                           |
| 158 |    277.598682 |    604.669443 | T. Michael Keesey                                                                                                                                       |
| 159 |     31.902520 |    393.672425 | Zimices                                                                                                                                                 |
| 160 |    388.807433 |    160.361424 | Matt Celeskey                                                                                                                                           |
| 161 |     95.400001 |    398.389863 | Matt Crook                                                                                                                                              |
| 162 |    138.471720 |    496.349992 | Zimices                                                                                                                                                 |
| 163 |    222.832510 |    255.861076 | Ferran Sayol                                                                                                                                            |
| 164 |    262.748339 |     26.169997 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                |
| 165 |    314.725140 |    704.667625 | Juan Carlos Jerí                                                                                                                                        |
| 166 |    847.613858 |     38.100514 | NOAA (vectorized by T. Michael Keesey)                                                                                                                  |
| 167 |    979.547752 |    672.614676 | Margot Michaud                                                                                                                                          |
| 168 |    902.831900 |    465.170529 | Rebecca Groom                                                                                                                                           |
| 169 |    453.446348 |    633.258646 | Margot Michaud                                                                                                                                          |
| 170 |    886.693725 |    430.513988 | Steven Traver                                                                                                                                           |
| 171 |    638.542931 |    658.888170 | Tasman Dixon                                                                                                                                            |
| 172 |    591.271988 |    496.324901 | Burton Robert, USFWS                                                                                                                                    |
| 173 |    745.088544 |    606.150115 | Kamil S. Jaron                                                                                                                                          |
| 174 |    233.423194 |    794.693357 | Ignacio Contreras                                                                                                                                       |
| 175 |    167.027305 |    763.121785 | Steven Traver                                                                                                                                           |
| 176 |    249.280970 |    214.471096 | DW Bapst (modified from Mitchell 1990)                                                                                                                  |
| 177 |    965.553842 |    116.904514 | Steven Traver                                                                                                                                           |
| 178 |    335.024537 |     75.697448 | Steven Traver                                                                                                                                           |
| 179 |    187.706127 |    128.694019 | NA                                                                                                                                                      |
| 180 |    837.898881 |    358.885055 | Markus A. Grohme                                                                                                                                        |
| 181 |     51.303989 |    289.885134 | Katie S. Collins                                                                                                                                        |
| 182 |    763.310789 |    532.263965 | Chris huh                                                                                                                                               |
| 183 |    897.433885 |    358.220865 | Jake Warner                                                                                                                                             |
| 184 |    860.313959 |    332.876348 | C. Camilo Julián-Caballero                                                                                                                              |
| 185 |    510.887367 |    421.567731 | NA                                                                                                                                                      |
| 186 |    668.506606 |    138.409553 | T. Michael Keesey                                                                                                                                       |
| 187 |    643.324262 |     51.487651 | T. Michael Keesey                                                                                                                                       |
| 188 |    283.681839 |    417.673227 | Jakovche                                                                                                                                                |
| 189 |    411.080764 |    335.013392 | terngirl                                                                                                                                                |
| 190 |   1015.723888 |    725.248094 | NA                                                                                                                                                      |
| 191 |    555.822821 |    747.469938 | Mathew Wedel                                                                                                                                            |
| 192 |    777.550770 |    725.858462 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                          |
| 193 |    485.346190 |    369.443832 | Felix Vaux                                                                                                                                              |
| 194 |    830.815903 |    484.085287 | Gabriela Palomo-Munoz                                                                                                                                   |
| 195 |     91.392490 |    122.337638 | Iain Reid                                                                                                                                               |
| 196 |     13.692190 |    432.488061 | Xavier Giroux-Bougard                                                                                                                                   |
| 197 |    557.802863 |    138.906214 | Tracy A. Heath                                                                                                                                          |
| 198 |    587.223271 |    568.730881 | Scott Hartman                                                                                                                                           |
| 199 |    643.431944 |    255.804952 | Nina Skinner                                                                                                                                            |
| 200 |    836.135334 |    746.940488 | Sharon Wegner-Larsen                                                                                                                                    |
| 201 |    317.659062 |    423.336893 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                 |
| 202 |    990.036001 |    493.698799 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                             |
| 203 |    987.418567 |    546.059067 | Gareth Monger                                                                                                                                           |
| 204 |    199.610253 |    242.892124 | Scott Hartman                                                                                                                                           |
| 205 |     26.466176 |    734.672700 | Jose Carlos Arenas-Monroy                                                                                                                               |
| 206 |     99.046035 |    698.869938 | T. Michael Keesey                                                                                                                                       |
| 207 |     76.253462 |    138.260918 | Beth Reinke                                                                                                                                             |
| 208 |    329.529629 |    551.847806 | Markus A. Grohme                                                                                                                                        |
| 209 |    351.927728 |    377.985664 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 210 |    816.381667 |    728.635356 | Scott Reid                                                                                                                                              |
| 211 |    437.374052 |    219.148565 | T. Michael Keesey                                                                                                                                       |
| 212 |    784.431628 |    783.749210 | Gareth Monger                                                                                                                                           |
| 213 |    709.000523 |    471.855824 | Emily Willoughby                                                                                                                                        |
| 214 |    285.245366 |    136.788224 | terngirl                                                                                                                                                |
| 215 |    116.620195 |    554.917069 | Ignacio Contreras                                                                                                                                       |
| 216 |     86.296130 |    277.236681 | Michelle Site                                                                                                                                           |
| 217 |    478.454664 |    727.256087 | C. Camilo Julián-Caballero                                                                                                                              |
| 218 |    953.700717 |     82.596165 | Zimices                                                                                                                                                 |
| 219 |    303.282561 |    324.615464 | NA                                                                                                                                                      |
| 220 |    214.016829 |    231.415710 | Matt Crook                                                                                                                                              |
| 221 |   1001.528778 |    789.191037 | Sean McCann                                                                                                                                             |
| 222 |    253.691071 |    236.464451 | Gabriela Palomo-Munoz                                                                                                                                   |
| 223 |    321.005382 |    248.492856 | FunkMonk                                                                                                                                                |
| 224 |    186.674857 |    555.584613 | Gabriela Palomo-Munoz                                                                                                                                   |
| 225 |    792.921472 |     35.625873 | Gabriela Palomo-Munoz                                                                                                                                   |
| 226 |    332.439712 |    559.735517 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                           |
| 227 |    500.242585 |    502.908855 | Jose Carlos Arenas-Monroy                                                                                                                               |
| 228 |    581.569065 |    796.351219 | Markus A. Grohme                                                                                                                                        |
| 229 |    533.743019 |    246.868112 | Margot Michaud                                                                                                                                          |
| 230 |    154.136796 |    350.257368 | Cesar Julian                                                                                                                                            |
| 231 |    525.626145 |    314.075227 | Chris huh                                                                                                                                               |
| 232 |    798.217497 |    108.610597 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                             |
| 233 |     98.710755 |     64.811832 | NASA                                                                                                                                                    |
| 234 |    312.736595 |    125.389243 | NA                                                                                                                                                      |
| 235 |    213.870761 |    108.191880 | Kai R. Caspar                                                                                                                                           |
| 236 |    471.612995 |    406.002025 | Sarah Werning                                                                                                                                           |
| 237 |    779.267593 |    442.138377 | Lauren Anderson                                                                                                                                         |
| 238 |    930.766721 |    782.049564 | Jose Carlos Arenas-Monroy                                                                                                                               |
| 239 |    953.100723 |    424.909833 | Bryan Carstens                                                                                                                                          |
| 240 |    825.013654 |    381.819621 | Chris huh                                                                                                                                               |
| 241 |    255.566057 |    123.149539 | Gareth Monger                                                                                                                                           |
| 242 |    533.394801 |    439.499567 | T. Michael Keesey                                                                                                                                       |
| 243 |    519.542190 |    465.753932 | Jonathan Wells                                                                                                                                          |
| 244 |    232.266600 |     77.288717 | Skye McDavid                                                                                                                                            |
| 245 |     19.936254 |     50.929730 | Gareth Monger                                                                                                                                           |
| 246 |    408.245719 |    233.456200 | Oscar Sanisidro                                                                                                                                         |
| 247 |    173.713441 |    506.709683 | Collin Gross                                                                                                                                            |
| 248 |    107.499723 |    338.562813 | L. Shyamal                                                                                                                                              |
| 249 |    833.466126 |    190.183441 | Christoph Schomburg                                                                                                                                     |
| 250 |    221.255920 |    710.879247 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                             |
| 251 |    805.497453 |    502.766113 | Lukasiniho                                                                                                                                              |
| 252 |    236.346401 |    637.089808 | Noah Schlottman                                                                                                                                         |
| 253 |    767.796721 |    406.694255 | Mareike C. Janiak                                                                                                                                       |
| 254 |     77.501999 |    578.988313 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 255 |    311.872741 |    302.094124 | Scott Hartman                                                                                                                                           |
| 256 |    367.149513 |    428.497461 | NA                                                                                                                                                      |
| 257 |    994.675017 |    209.343073 | Mykle Hoban                                                                                                                                             |
| 258 |    323.926424 |    720.488707 | Chris huh                                                                                                                                               |
| 259 |    132.015941 |    164.293448 | Josefine Bohr Brask                                                                                                                                     |
| 260 |    948.289228 |    136.223966 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                      |
| 261 |    783.925940 |    649.043298 | Zimices                                                                                                                                                 |
| 262 |    593.990614 |    472.945325 | Tasman Dixon                                                                                                                                            |
| 263 |    779.272346 |      5.321763 | Jaime Headden, modified by T. Michael Keesey                                                                                                            |
| 264 |   1009.963948 |    227.056501 | Margot Michaud                                                                                                                                          |
| 265 |    608.863694 |    580.231625 | Beth Reinke                                                                                                                                             |
| 266 |    760.508798 |     83.238691 | Zimices                                                                                                                                                 |
| 267 |    719.583248 |    294.014758 | Steven Traver                                                                                                                                           |
| 268 |    913.928772 |    422.971285 | T. Michael Keesey                                                                                                                                       |
| 269 |    152.233962 |    231.928044 | Adrian Reich                                                                                                                                            |
| 270 |    294.938367 |    283.392053 | Matt Crook                                                                                                                                              |
| 271 |     86.659445 |    515.262366 | Scott Hartman                                                                                                                                           |
| 272 |    453.096208 |    127.078176 | Jagged Fang Designs                                                                                                                                     |
| 273 |    146.400295 |    175.633626 | L. Shyamal                                                                                                                                              |
| 274 |     75.302593 |    621.848788 | Oscar Sanisidro                                                                                                                                         |
| 275 |    324.643570 |    740.684926 | Gabriela Palomo-Munoz                                                                                                                                   |
| 276 |   1012.732076 |    645.954476 | Ferran Sayol                                                                                                                                            |
| 277 |    290.795155 |    747.924741 | Birgit Lang                                                                                                                                             |
| 278 |    754.508868 |    425.110808 | FunkMonk                                                                                                                                                |
| 279 |    524.375053 |    376.890766 | Tasman Dixon                                                                                                                                            |
| 280 |    679.118883 |    612.720180 | Steven Traver                                                                                                                                           |
| 281 |    698.058150 |    678.850619 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                      |
| 282 |    424.067519 |    657.171142 | T. Michael Keesey                                                                                                                                       |
| 283 |    846.516772 |    341.868024 | Carlos Cano-Barbacil                                                                                                                                    |
| 284 |    219.857995 |    418.290488 | Zimices                                                                                                                                                 |
| 285 |    710.210571 |    440.384918 | NA                                                                                                                                                      |
| 286 |    568.097999 |    776.617786 | Margot Michaud                                                                                                                                          |
| 287 |    386.475316 |    477.904538 | Birgit Lang                                                                                                                                             |
| 288 |    392.300817 |    395.233446 | Oren Peles / vectorized by Yan Wong                                                                                                                     |
| 289 |    993.087656 |     38.588220 | Kamil S. Jaron                                                                                                                                          |
| 290 |    435.855230 |     40.586349 | Henry Lydecker                                                                                                                                          |
| 291 |    601.280681 |    758.548315 | Gareth Monger                                                                                                                                           |
| 292 |    598.123709 |    655.208995 | Margot Michaud                                                                                                                                          |
| 293 |    679.127210 |    499.228451 | Jagged Fang Designs                                                                                                                                     |
| 294 |    866.256035 |     60.386660 | Scott Hartman                                                                                                                                           |
| 295 |    607.790618 |    622.543134 | Kamil S. Jaron                                                                                                                                          |
| 296 |    210.417365 |    733.463353 | NA                                                                                                                                                      |
| 297 |    191.865838 |    356.755789 | FunkMonk                                                                                                                                                |
| 298 |   1010.425963 |    586.087170 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 299 |    624.680274 |    748.155107 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                      |
| 300 |    247.564243 |    312.816068 | Mykle Hoban                                                                                                                                             |
| 301 |    305.623170 |    601.805825 | T. Michael Keesey                                                                                                                                       |
| 302 |    892.165198 |     32.432243 | Kamil S. Jaron                                                                                                                                          |
| 303 |    715.176337 |    782.525696 | Markus A. Grohme                                                                                                                                        |
| 304 |    611.957181 |    127.208488 | Caleb M. Brown                                                                                                                                          |
| 305 |    370.441997 |    229.816526 | Jagged Fang Designs                                                                                                                                     |
| 306 |    657.093550 |    295.024456 | Ricardo Araújo                                                                                                                                          |
| 307 |    917.391772 |    479.493571 | Margot Michaud                                                                                                                                          |
| 308 |    244.728190 |     64.812979 | Margot Michaud                                                                                                                                          |
| 309 |    101.348509 |    169.507216 | Jagged Fang Designs                                                                                                                                     |
| 310 |    897.225131 |    792.294281 | Scott Hartman                                                                                                                                           |
| 311 |    242.177162 |     94.372946 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 312 |    917.041958 |    533.897733 | SauropodomorphMonarch                                                                                                                                   |
| 313 |    442.509634 |    789.815105 | Gabriela Palomo-Munoz                                                                                                                                   |
| 314 |    516.827758 |    300.168259 | NA                                                                                                                                                      |
| 315 |    239.712077 |    563.771094 | T. Michael Keesey (after Mivart)                                                                                                                        |
| 316 |    137.420063 |    542.955405 | Jagged Fang Designs                                                                                                                                     |
| 317 |    598.479313 |    452.611572 | Gareth Monger                                                                                                                                           |
| 318 |    768.781398 |    318.347321 | Scott Hartman                                                                                                                                           |
| 319 |    191.122158 |    222.155178 | Matt Crook                                                                                                                                              |
| 320 |    240.962874 |    520.194449 | Manabu Bessho-Uehara                                                                                                                                    |
| 321 |    524.168405 |    781.021010 | Joanna Wolfe                                                                                                                                            |
| 322 |    224.286502 |     25.959308 | Margot Michaud                                                                                                                                          |
| 323 |    801.636342 |    531.707245 | Matt Crook                                                                                                                                              |
| 324 |    643.321444 |    579.856463 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 325 |    355.683096 |    134.661242 | Ferran Sayol                                                                                                                                            |
| 326 |     41.521844 |    630.161840 | Andy Wilson                                                                                                                                             |
| 327 |    704.236813 |    793.358996 | Scott Hartman                                                                                                                                           |
| 328 |    575.212916 |    222.196884 | Iain Reid                                                                                                                                               |
| 329 |    401.900515 |    458.935911 | Tasman Dixon                                                                                                                                            |
| 330 |    978.829052 |    144.521920 | Andy Wilson                                                                                                                                             |
| 331 |     71.864940 |    722.123789 | Abraão Leite                                                                                                                                            |
| 332 |   1006.094413 |    674.733943 | Jessica Rick                                                                                                                                            |
| 333 |    324.120129 |     13.186037 | Matt Crook                                                                                                                                              |
| 334 |    315.766323 |    143.610400 | Alex Slavenko                                                                                                                                           |
| 335 |    896.148701 |    283.763376 | NA                                                                                                                                                      |
| 336 |    952.287010 |    545.987634 | Margot Michaud                                                                                                                                          |
| 337 |    460.977682 |    511.622562 | Andy Wilson                                                                                                                                             |
| 338 |    177.970300 |    151.869371 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 339 |    258.241644 |    416.039441 | Gabriela Palomo-Munoz                                                                                                                                   |
| 340 |    944.692289 |     35.122047 | Zimices                                                                                                                                                 |
| 341 |    801.124098 |     63.921399 | Emily Willoughby                                                                                                                                        |
| 342 |    908.896058 |    328.258200 | Juan Carlos Jerí                                                                                                                                        |
| 343 |    549.788702 |    644.208424 | Noah Schlottman, photo from Casey Dunn                                                                                                                  |
| 344 |    445.607531 |     26.005340 | Martin R. Smith                                                                                                                                         |
| 345 |    805.993666 |    249.568458 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                          |
| 346 |     54.607216 |    422.732083 | Margot Michaud                                                                                                                                          |
| 347 |    881.848343 |      3.650337 | Markus A. Grohme                                                                                                                                        |
| 348 |    712.721437 |    381.730935 | Yan Wong                                                                                                                                                |
| 349 |    935.078514 |    468.413832 | Zimices                                                                                                                                                 |
| 350 |    359.076180 |     84.299117 | Kamil S. Jaron                                                                                                                                          |
| 351 |    735.360560 |    392.732499 | Steven Traver                                                                                                                                           |
| 352 |    432.344913 |    551.201054 | Scott Hartman                                                                                                                                           |
| 353 |    497.590095 |    178.716904 | Nina Skinner                                                                                                                                            |
| 354 |    530.956559 |    181.007396 | Kai R. Caspar                                                                                                                                           |
| 355 |    475.638531 |    414.953679 | Thibaut Brunet                                                                                                                                          |
| 356 |    441.075986 |    560.384140 | Tracy A. Heath                                                                                                                                          |
| 357 |    492.753177 |     13.822096 | Milton Tan                                                                                                                                              |
| 358 |    681.556015 |    118.813918 | Chris huh                                                                                                                                               |
| 359 |    484.168347 |    707.247720 | Kai R. Caspar                                                                                                                                           |
| 360 |    135.857561 |    697.764318 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                             |
| 361 |    740.181482 |    335.958112 | Margot Michaud                                                                                                                                          |
| 362 |    341.916710 |    154.409383 | Jon Hill                                                                                                                                                |
| 363 |    292.281281 |    108.887378 | Erika Schumacher                                                                                                                                        |
| 364 |    643.697272 |    227.438187 | T. Michael Keesey                                                                                                                                       |
| 365 |    977.756043 |    260.571716 | Jagged Fang Designs                                                                                                                                     |
| 366 |     41.811576 |    793.778123 | Chris huh                                                                                                                                               |
| 367 |    709.263132 |    499.242370 | Matt Crook                                                                                                                                              |
| 368 |     98.229958 |    423.005867 | Jagged Fang Designs                                                                                                                                     |
| 369 |    779.347800 |     58.341566 | Kamil S. Jaron                                                                                                                                          |
| 370 |    205.053392 |    563.977237 | Gabriela Palomo-Munoz                                                                                                                                   |
| 371 |    720.837593 |    665.089170 | NA                                                                                                                                                      |
| 372 |    820.519603 |    622.218274 | Maija Karala                                                                                                                                            |
| 373 |    343.766896 |    691.728679 | Gabriela Palomo-Munoz                                                                                                                                   |
| 374 |    624.776132 |    135.175712 | Gabriela Palomo-Munoz                                                                                                                                   |
| 375 |    672.192287 |    176.280451 | Margot Michaud                                                                                                                                          |
| 376 |    676.918649 |     65.687813 | Gareth Monger                                                                                                                                           |
| 377 |      8.996904 |    302.739965 | T. Michael Keesey                                                                                                                                       |
| 378 |     67.053981 |    161.858188 | Scott Hartman                                                                                                                                           |
| 379 |    369.054315 |    683.857706 | Jagged Fang Designs                                                                                                                                     |
| 380 |    490.094123 |    787.771795 | Chris huh                                                                                                                                               |
| 381 |    144.711991 |    677.005514 | Gareth Monger                                                                                                                                           |
| 382 |    741.965257 |    584.180179 | Chris huh                                                                                                                                               |
| 383 |    404.719433 |    629.146442 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                       |
| 384 |    900.078236 |    207.486255 | Tasman Dixon                                                                                                                                            |
| 385 |    572.188394 |    636.894355 | Armin Reindl                                                                                                                                            |
| 386 |    875.979440 |    164.370563 | NA                                                                                                                                                      |
| 387 |    504.415133 |    640.259980 | Juan Carlos Jerí                                                                                                                                        |
| 388 |    213.568491 |    279.752789 | Cesar Julian                                                                                                                                            |
| 389 |    952.969088 |    498.575689 | Neil Kelley                                                                                                                                             |
| 390 |    481.833628 |    307.940133 | C. Camilo Julián-Caballero                                                                                                                              |
| 391 |    871.906796 |    614.899310 | Kanchi Nanjo                                                                                                                                            |
| 392 |    140.233460 |     24.975307 | Zimices                                                                                                                                                 |
| 393 |     49.354583 |    730.888063 | Gareth Monger                                                                                                                                           |
| 394 |    817.693436 |    568.768681 | Gareth Monger                                                                                                                                           |
| 395 |    257.196510 |    366.001113 | Jagged Fang Designs                                                                                                                                     |
| 396 |    577.943335 |    240.608666 | Iain Reid                                                                                                                                               |
| 397 |    432.018596 |    528.900832 | Hugo Gruson                                                                                                                                             |
| 398 |    197.259503 |    379.674106 | NA                                                                                                                                                      |
| 399 |    878.788112 |    588.411427 | Tasman Dixon                                                                                                                                            |
| 400 |    212.490938 |    756.806548 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                           |
| 401 |    906.411601 |    457.740855 | Alex Slavenko                                                                                                                                           |
| 402 |    768.647993 |    600.613356 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 403 |    597.240368 |    740.930991 | Scott Hartman                                                                                                                                           |
| 404 |    602.887648 |    688.107263 | Christoph Schomburg                                                                                                                                     |
| 405 |     26.024463 |    366.632362 | Karla Martinez                                                                                                                                          |
| 406 |    872.976268 |     23.843044 | Margot Michaud                                                                                                                                          |
| 407 |    510.784514 |    727.031506 | Andy Wilson                                                                                                                                             |
| 408 |    305.514410 |    177.595944 | T. Michael Keesey                                                                                                                                       |
| 409 |    386.763413 |    792.963095 | Markus A. Grohme                                                                                                                                        |
| 410 |    229.269947 |    742.397400 | Yan Wong                                                                                                                                                |
| 411 |    900.002308 |    562.809446 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 412 |    728.784066 |    684.590800 | Gareth Monger                                                                                                                                           |
| 413 |    773.732821 |    109.380320 | L. Shyamal                                                                                                                                              |
| 414 |     74.451411 |    526.397088 | Zimices                                                                                                                                                 |
| 415 |    951.932826 |    780.161288 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                       |
| 416 |    616.112565 |    450.659409 | Martin R. Smith                                                                                                                                         |
| 417 |    791.850810 |    226.024711 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 418 |    343.699874 |    351.069040 | Sean McCann                                                                                                                                             |
| 419 |    957.458438 |    401.555259 | NA                                                                                                                                                      |
| 420 |    364.628107 |    556.337705 | Matt Dempsey                                                                                                                                            |
| 421 |    960.994215 |    356.931128 | Zimices                                                                                                                                                 |
| 422 |    951.073018 |    212.896268 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                          |
| 423 |    728.332588 |    519.577149 | Scott Hartman                                                                                                                                           |
| 424 |    272.640385 |    301.641854 | Jagged Fang Designs                                                                                                                                     |
| 425 |    711.764464 |    603.282433 | Emily Willoughby                                                                                                                                        |
| 426 |    603.281283 |    514.945214 | Daniel Stadtmauer                                                                                                                                       |
| 427 |    128.381242 |    244.079880 | Collin Gross                                                                                                                                            |
| 428 |    957.009130 |    445.110176 | NA                                                                                                                                                      |
| 429 |   1019.027015 |     80.486421 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                       |
| 430 |    749.518456 |    729.437060 | Scott Hartman                                                                                                                                           |
| 431 |    772.012363 |     14.713039 | Christoph Schomburg                                                                                                                                     |
| 432 |    332.265907 |     65.869376 | Jagged Fang Designs                                                                                                                                     |
| 433 |    168.803451 |    337.644653 | Darius Nau                                                                                                                                              |
| 434 |    499.885363 |    629.214460 | Chris huh                                                                                                                                               |
| 435 |    556.546611 |    366.402306 | Steven Haddock • Jellywatch.org                                                                                                                         |
| 436 |    348.312756 |    109.827217 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 437 |    385.866664 |    408.813271 | NA                                                                                                                                                      |
| 438 |    120.671415 |    450.755283 | xgirouxb                                                                                                                                                |
| 439 |    497.862017 |    519.380163 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                 |
| 440 |    684.565722 |    446.212385 | Scott Hartman                                                                                                                                           |
| 441 |    905.952088 |    155.422288 | Jose Carlos Arenas-Monroy                                                                                                                               |
| 442 |    863.209719 |    258.218004 | Michael Scroggie                                                                                                                                        |
| 443 |    237.939275 |    688.469818 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                        |
| 444 |    266.658100 |    477.066365 | Zimices                                                                                                                                                 |
| 445 |    121.471312 |    155.787701 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 446 |    904.326595 |    107.305633 | Markus A. Grohme                                                                                                                                        |
| 447 |    284.639341 |      8.494792 | Scott Hartman                                                                                                                                           |
| 448 |     69.827279 |     52.476315 | Sarah Werning                                                                                                                                           |
| 449 |     14.539041 |    141.408269 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                         |
| 450 |    834.055908 |    580.264637 | Estelle Bourdon                                                                                                                                         |
| 451 |    523.883674 |      7.799116 | Steven Traver                                                                                                                                           |
| 452 |    390.858240 |    497.885645 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                         |
| 453 |    143.301452 |    769.202723 | Chris huh                                                                                                                                               |
| 454 |   1016.711895 |    145.411030 | T. Michael Keesey                                                                                                                                       |
| 455 |    191.722636 |     22.234430 | Ferran Sayol                                                                                                                                            |
| 456 |    904.275346 |    266.562911 | Steven Traver                                                                                                                                           |
| 457 |   1010.082571 |    540.680185 | Margot Michaud                                                                                                                                          |
| 458 |    359.243675 |    247.277268 | Ignacio Contreras                                                                                                                                       |
| 459 |    431.651893 |    642.290473 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                        |
| 460 |    648.733883 |    243.973571 | Bennet McComish, photo by Avenue                                                                                                                        |
| 461 |    897.452958 |    411.300100 | Jiekun He                                                                                                                                               |
| 462 |    526.693027 |    274.309992 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 463 |    145.564694 |    210.687724 | Mathieu Pélissié                                                                                                                                        |
| 464 |    554.435354 |    689.525004 | Scott Hartman                                                                                                                                           |
| 465 |     73.012126 |     63.866309 | Scott Hartman                                                                                                                                           |
| 466 |    300.610807 |    352.540498 | Jagged Fang Designs                                                                                                                                     |
| 467 |    315.422055 |     78.573691 | Jagged Fang Designs                                                                                                                                     |
| 468 |    564.622053 |    761.259141 | Chris huh                                                                                                                                               |
| 469 |    842.345461 |    726.751428 | Gareth Monger                                                                                                                                           |
| 470 |    115.143742 |    429.023480 | Jagged Fang Designs                                                                                                                                     |
| 471 |    746.830485 |    792.470306 | Joanna Wolfe                                                                                                                                            |
| 472 |    520.368933 |    587.830213 | Cesar Julian                                                                                                                                            |
| 473 |    990.110359 |    774.021045 | Jagged Fang Designs                                                                                                                                     |
| 474 |    168.168869 |    363.076189 | Caleb M. Brown                                                                                                                                          |
| 475 |    846.897084 |    527.875308 | Zimices                                                                                                                                                 |
| 476 |    547.196570 |    631.484763 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 477 |    452.582469 |    717.959338 | Markus A. Grohme                                                                                                                                        |
| 478 |     95.689459 |    571.320767 | Scott Hartman                                                                                                                                           |
| 479 |     74.010378 |    738.981696 | Anthony Caravaggi                                                                                                                                       |
| 480 |    830.405731 |     68.728104 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 481 |    653.992888 |    552.261099 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 482 |     21.192353 |    718.386325 | NA                                                                                                                                                      |
| 483 |    159.971893 |    785.137979 | Zimices                                                                                                                                                 |
| 484 |    535.521892 |    222.195955 | Gareth Monger                                                                                                                                           |
| 485 |    796.164856 |    352.193103 | Maija Karala                                                                                                                                            |
| 486 |    135.526210 |    482.379258 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                |
| 487 |    587.677240 |    786.672304 | Markus A. Grohme                                                                                                                                        |
| 488 |    721.332089 |    573.953068 | Felix Vaux                                                                                                                                              |
| 489 |    563.027249 |    124.120813 | Jagged Fang Designs                                                                                                                                     |
| 490 |     89.156405 |    712.180163 | Jagged Fang Designs                                                                                                                                     |
| 491 |    299.156721 |     72.212968 | Tasman Dixon                                                                                                                                            |
| 492 |    662.145222 |    163.762160 | Tony Ayling                                                                                                                                             |
| 493 |    467.464716 |    393.642311 | NA                                                                                                                                                      |
| 494 |    917.739910 |    135.969839 | Andy Wilson                                                                                                                                             |
| 495 |    484.155861 |    796.531600 | Armin Reindl                                                                                                                                            |
| 496 |    994.639754 |    248.440482 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 497 |    992.602340 |    508.518025 | Scott Hartman                                                                                                                                           |
| 498 |    687.554636 |    131.517964 | Zimices                                                                                                                                                 |
| 499 |     98.655426 |    624.210750 | Ferran Sayol                                                                                                                                            |
| 500 |    661.711816 |    782.897661 | Julio Garza                                                                                                                                             |
| 501 |    872.852514 |    781.117301 | Margot Michaud                                                                                                                                          |
| 502 |    292.837313 |    695.239270 | Michael P. Taylor                                                                                                                                       |
| 503 |    463.923838 |      7.746173 | Markus A. Grohme                                                                                                                                        |
| 504 |    383.630077 |    350.518948 | Scott Hartman                                                                                                                                           |
| 505 |    631.175654 |    559.481481 | NA                                                                                                                                                      |
| 506 |    252.920856 |    650.116783 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                           |
| 507 |    189.090466 |    784.067126 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                |
| 508 |      7.465237 |    663.860287 | Aviceda (photo) & T. Michael Keesey                                                                                                                     |
| 509 |    552.932216 |      3.631566 | Chris huh                                                                                                                                               |
| 510 |    580.955717 |     45.298178 | Kai R. Caspar                                                                                                                                           |
| 511 |    931.800054 |    683.432796 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 512 |     42.761363 |    407.818390 | C. Camilo Julián-Caballero                                                                                                                              |
| 513 |    726.328557 |    116.731408 | Mariana Ruiz Villarreal                                                                                                                                 |

    #> Your tweet has been posted!
