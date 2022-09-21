
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

Roberto Díaz Sibaja, Melissa Broussard, Ghedoghedo (vectorized by T.
Michael Keesey), Margot Michaud, Birgit Lang, T. Michael Keesey, Steven
Traver, Gareth Monger, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Louis Ranjard, Emily Willoughby, Zimices, J. J. Harrison
(photo) & T. Michael Keesey, Scott Hartman, Yan Wong, James I. Kirkland,
Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Christoph Schomburg, Sergio
A. Muñoz-Gómez, Maija Karala, Gustav Mützel, Sarah Werning, Armin
Reindl, Matt Celeskey, Ray Simpson (vectorized by T. Michael Keesey),
Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime
Dahirel), Unknown (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Beth Reinke, Patrick Fisher (vectorized by T. Michael
Keesey), Sharon Wegner-Larsen, Maxime Dahirel, Andrew A. Farke, modified
from original by Robert Bruce Horsfall, from Scott 1912, Todd Marshall,
vectorized by Zimices, Jagged Fang Designs, Agnello Picorelli, Bruno
Maggia, Matt Hayes, Markus A. Grohme, Matt Crook, Andy Wilson, Tracy A.
Heath, L. Shyamal, Pranav Iyer (grey ideas), Matt Dempsey, Cesar Julian,
Mr E? (vectorized by T. Michael Keesey), Collin Gross, Matt Martyniuk
(vectorized by T. Michael Keesey), Jonathan Wells, Rebecca Groom,
Ricardo Araújo, Birgit Lang, based on a photo by D. Sikes, Jaime
Headden, Gabriela Palomo-Munoz, Lukasiniho, Melissa Ingala, Mathew
Wedel, Jose Carlos Arenas-Monroy, Trond R. Oskars, Noah Schlottman,
photo by Adam G. Clause, T. Tischler, Erika Schumacher, Anthony
Caravaggi, Lauren Sumner-Rooney, Alexandre Vong, Tasman Dixon, L.M.
Davalos, Ignacio Contreras, Matt Martyniuk (modified by Serenchia),
Becky Barnes, Noah Schlottman, photo by Casey Dunn, Chris huh, Michelle
Site, Michael Scroggie, Shyamal, Noah Schlottman, photo by Antonio
Guillén, Ferran Sayol, Robbie N. Cada (vectorized by T. Michael
Keesey), Xavier Giroux-Bougard, T. Michael Keesey (vectorization) and
Nadiatalent (photography), Nobu Tamura and T. Michael Keesey, T. Michael
Keesey (after Marek Velechovský), Tyler McCraney, Jessica Anne Miller,
Matt Wilkins, T. Michael Keesey (photo by Darren Swim), Ernst Haeckel
(vectorized by T. Michael Keesey), Walter Vladimir, Mathieu Basille,
Martin R. Smith, M Kolmann, Alex Slavenko, Julio Garza, E. J. Van
Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael
Keesey), Scarlet23 (vectorized by T. Michael Keesey), Berivan Temiz,
Sean McCann, Lankester Edwin Ray (vectorized by T. Michael Keesey),
kreidefossilien.de, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and
Timothy J. Bartley (silhouette), Dmitry Bogdanov (modified by T. Michael
Keesey), Christine Axon, (after Spotila 2004), Jan A. Venter, Herbert H.
T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Nobu Tamura (vectorized by T. Michael Keesey), Josefine Bohr
Brask, Chuanixn Yu, Noah Schlottman, Iain Reid, Mo Hassan, Chloé
Schmidt, Milton Tan, Lily Hughes, Javier Luque, Kai R. Caspar, Maxime
Dahirel (digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Manabu Bessho-Uehara, Ingo
Braasch, C. Camilo Julián-Caballero, Mathilde Cordellier, Nicolas Huet
le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey),
Dmitry Bogdanov, Curtis Clark and T. Michael Keesey, Jon M Laurent, Tony
Ayling (vectorized by T. Michael Keesey), Gopal Murali, Steven Coombs,
Tauana J. Cunha, Caleb M. Brown, Dean Schnabel, Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), (unknown),
Isaure Scavezzoni, Servien (vectorized by T. Michael Keesey), Mali’o
Kodis, image from the “Proceedings of the Zoological Society of London”,
Kamil S. Jaron, Joanna Wolfe, SauropodomorphMonarch, Obsidian Soul
(vectorized by T. Michael Keesey), Harold N Eyster, Conty, Nobu Tamura
(modified by T. Michael Keesey), Vanessa Guerra, Smokeybjb, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist, Inessa
Voet, Raven Amos, Brad McFeeters (vectorized by T. Michael Keesey),
Andrew R. Gehrke, Crystal Maier, Rene Martin, Madeleine Price Ball,
Matthew Hooge (vectorized by T. Michael Keesey), B. Duygu Özpolat,
xgirouxb, FunkMonk, Dave Souza (vectorized by T. Michael Keesey), NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), FunkMonk (Michael B.H.; vectorized by T.
Michael Keesey), Gordon E. Robertson, Matt Martyniuk, CNZdenek, Michael
Day, Francisco Gascó (modified by Michael P. Taylor), Allison Pease,
Terpsichores, Jack Mayer Wood, G. M. Woodward, Nobu Tamura, Andrew A.
Farke, Smith609 and T. Michael Keesey, Thea Boodhoo (photograph) and T.
Michael Keesey (vectorization), Darren Naish (vectorize by T. Michael
Keesey), Cagri Cevrim, Renata F. Martins, Nobu Tamura, vectorized by
Zimices, Ghedo (vectorized by T. Michael Keesey), Dmitry Bogdanov and
FunkMonk (vectorized by T. Michael Keesey), Douglas Brown (modified by
T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                  |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |     373.48476 |    274.710246 | Roberto Díaz Sibaja                                                                                                                                     |
|   2 |     848.65220 |    694.396645 | Melissa Broussard                                                                                                                                       |
|   3 |     654.90398 |    246.808295 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                            |
|   4 |     504.13229 |    263.340955 | Margot Michaud                                                                                                                                          |
|   5 |     283.84831 |    706.295527 | Birgit Lang                                                                                                                                             |
|   6 |     731.43095 |    443.380025 | NA                                                                                                                                                      |
|   7 |     566.40360 |    639.962805 | T. Michael Keesey                                                                                                                                       |
|   8 |     197.35709 |    113.659756 | Steven Traver                                                                                                                                           |
|   9 |      58.96585 |    645.311917 | Gareth Monger                                                                                                                                           |
|  10 |     719.01887 |    105.520538 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  11 |     671.97698 |    668.740435 | Louis Ranjard                                                                                                                                           |
|  12 |      31.73954 |    418.270897 | Emily Willoughby                                                                                                                                        |
|  13 |     361.66451 |    623.516684 | Zimices                                                                                                                                                 |
|  14 |      88.39855 |    206.698120 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                              |
|  15 |     357.44201 |    500.360588 | Scott Hartman                                                                                                                                           |
|  16 |     397.03848 |    715.492051 | Gareth Monger                                                                                                                                           |
|  17 |     198.52070 |    214.008878 | Yan Wong                                                                                                                                                |
|  18 |     147.95952 |    518.996652 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                    |
|  19 |     655.21157 |    523.805624 | Christoph Schomburg                                                                                                                                     |
|  20 |     151.87720 |    371.053423 | Sergio A. Muñoz-Gómez                                                                                                                                   |
|  21 |     476.62374 |    384.633943 | Maija Karala                                                                                                                                            |
|  22 |     349.65305 |     78.824775 | Gustav Mützel                                                                                                                                           |
|  23 |     767.89281 |    650.562840 | Sarah Werning                                                                                                                                           |
|  24 |     866.81275 |    226.072735 | Armin Reindl                                                                                                                                            |
|  25 |     260.46381 |    549.492900 | T. Michael Keesey                                                                                                                                       |
|  26 |     943.78985 |    578.201694 | Matt Celeskey                                                                                                                                           |
|  27 |     958.38507 |    384.352850 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                           |
|  28 |     965.38874 |    280.974201 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                           |
|  29 |     151.59564 |    585.409709 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  30 |     572.52216 |    378.081950 | Beth Reinke                                                                                                                                             |
|  31 |     227.94041 |     37.219104 | Scott Hartman                                                                                                                                           |
|  32 |     819.09539 |    375.280268 | NA                                                                                                                                                      |
|  33 |     471.32639 |    476.574262 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                        |
|  34 |     459.82354 |    141.668981 | T. Michael Keesey                                                                                                                                       |
|  35 |     152.95458 |    708.706279 | Sharon Wegner-Larsen                                                                                                                                    |
|  36 |     308.27783 |    388.217804 | T. Michael Keesey                                                                                                                                       |
|  37 |     607.75027 |    738.050729 | Maxime Dahirel                                                                                                                                          |
|  38 |     216.15841 |    464.385559 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                       |
|  39 |     167.78869 |    632.866692 | Todd Marshall, vectorized by Zimices                                                                                                                    |
|  40 |      66.93772 |     23.529405 | Maija Karala                                                                                                                                            |
|  41 |     493.52841 |    682.087018 | Jagged Fang Designs                                                                                                                                     |
|  42 |     816.24894 |    481.198725 | Jagged Fang Designs                                                                                                                                     |
|  43 |     754.78668 |    589.464245 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  44 |     735.02657 |    258.784277 | Agnello Picorelli                                                                                                                                       |
|  45 |     225.27457 |    288.442527 | Scott Hartman                                                                                                                                           |
|  46 |     331.73762 |    151.272546 | Emily Willoughby                                                                                                                                        |
|  47 |     276.60515 |    195.466360 | Bruno Maggia                                                                                                                                            |
|  48 |     952.68665 |    668.696097 | Matt Hayes                                                                                                                                              |
|  49 |     925.49425 |    777.079749 | Jagged Fang Designs                                                                                                                                     |
|  50 |     322.70003 |     17.536993 | Markus A. Grohme                                                                                                                                        |
|  51 |     536.71777 |    507.327804 | Matt Crook                                                                                                                                              |
|  52 |     924.91345 |    473.147990 | Andy Wilson                                                                                                                                             |
|  53 |     947.52445 |    177.609159 | Steven Traver                                                                                                                                           |
|  54 |     955.09965 |     26.567733 | Zimices                                                                                                                                                 |
|  55 |     100.02534 |    483.810513 | Tracy A. Heath                                                                                                                                          |
|  56 |      70.81415 |    136.009883 | Matt Crook                                                                                                                                              |
|  57 |      88.63939 |    343.791727 | L. Shyamal                                                                                                                                              |
|  58 |     721.15169 |    754.722054 | Zimices                                                                                                                                                 |
|  59 |     410.01132 |    235.804747 | Pranav Iyer (grey ideas)                                                                                                                                |
|  60 |     665.82849 |    342.151403 | Jagged Fang Designs                                                                                                                                     |
|  61 |     439.99592 |     46.929975 | NA                                                                                                                                                      |
|  62 |     239.22199 |    377.510373 | Matt Crook                                                                                                                                              |
|  63 |     811.43772 |    540.891422 | Matt Dempsey                                                                                                                                            |
|  64 |     503.30218 |    742.848462 | Gareth Monger                                                                                                                                           |
|  65 |     634.22119 |    436.836720 | Cesar Julian                                                                                                                                            |
|  66 |     162.60364 |     50.599297 | Emily Willoughby                                                                                                                                        |
|  67 |     376.69833 |    419.640198 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                 |
|  68 |      71.09874 |    545.215396 | Collin Gross                                                                                                                                            |
|  69 |     826.05111 |    775.565933 | T. Michael Keesey                                                                                                                                       |
|  70 |     455.17443 |    571.088089 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                        |
|  71 |     960.95979 |    745.475567 | Jonathan Wells                                                                                                                                          |
|  72 |     928.21467 |     69.095661 | Rebecca Groom                                                                                                                                           |
|  73 |     868.39486 |    357.336879 | NA                                                                                                                                                      |
|  74 |     385.39896 |    127.056516 | Ricardo Araújo                                                                                                                                          |
|  75 |     759.72591 |    194.113037 | Birgit Lang, based on a photo by D. Sikes                                                                                                               |
|  76 |     102.34726 |    442.277604 | Zimices                                                                                                                                                 |
|  77 |     189.87761 |    151.426855 | Jaime Headden                                                                                                                                           |
|  78 |      32.27790 |    738.652698 | NA                                                                                                                                                      |
|  79 |     193.14683 |    767.956117 | Gabriela Palomo-Munoz                                                                                                                                   |
|  80 |     294.85085 |    608.152135 | Lukasiniho                                                                                                                                              |
|  81 |     881.24109 |    135.825547 | Melissa Ingala                                                                                                                                          |
|  82 |     356.23567 |    583.031265 | Christoph Schomburg                                                                                                                                     |
|  83 |      47.52143 |    785.706955 | Mathew Wedel                                                                                                                                            |
|  84 |     242.50097 |    234.318001 | Collin Gross                                                                                                                                            |
|  85 |     990.45694 |    505.702167 | Jose Carlos Arenas-Monroy                                                                                                                               |
|  86 |     359.67214 |    724.043386 | Trond R. Oskars                                                                                                                                         |
|  87 |     592.92600 |    269.719505 | Noah Schlottman, photo by Adam G. Clause                                                                                                                |
|  88 |     561.05915 |    570.681443 | T. Tischler                                                                                                                                             |
|  89 |     235.46827 |    335.627615 | Maxime Dahirel                                                                                                                                          |
|  90 |     716.21316 |    539.230429 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  91 |     658.38048 |    596.049696 | Erika Schumacher                                                                                                                                        |
|  92 |     691.42160 |    356.080407 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
|  93 |     561.96331 |    547.215192 | Margot Michaud                                                                                                                                          |
|  94 |      88.74904 |     75.593881 | Zimices                                                                                                                                                 |
|  95 |     525.04940 |    116.021649 | Anthony Caravaggi                                                                                                                                       |
|  96 |     566.02910 |    757.677418 | T. Michael Keesey                                                                                                                                       |
|  97 |     313.87278 |    782.314107 | Gabriela Palomo-Munoz                                                                                                                                   |
|  98 |     167.81196 |    556.046109 | Gareth Monger                                                                                                                                           |
|  99 |     314.89929 |    216.008621 | Markus A. Grohme                                                                                                                                        |
| 100 |     955.90940 |    112.905074 | Lauren Sumner-Rooney                                                                                                                                    |
| 101 |     898.81892 |    232.036447 | Alexandre Vong                                                                                                                                          |
| 102 |     416.15056 |    330.296269 | Tasman Dixon                                                                                                                                            |
| 103 |     196.43589 |    679.110199 | Matt Crook                                                                                                                                              |
| 104 |     371.93882 |    170.039938 | Alexandre Vong                                                                                                                                          |
| 105 |     811.05125 |    290.042219 | L.M. Davalos                                                                                                                                            |
| 106 |     348.57371 |    533.516096 | Jagged Fang Designs                                                                                                                                     |
| 107 |     774.85980 |    431.072549 | Zimices                                                                                                                                                 |
| 108 |     833.91622 |    593.546685 | Gareth Monger                                                                                                                                           |
| 109 |      39.85683 |     39.495246 | Andy Wilson                                                                                                                                             |
| 110 |     137.09005 |    244.715498 | Gareth Monger                                                                                                                                           |
| 111 |     879.26843 |    521.133380 | Yan Wong                                                                                                                                                |
| 112 |     141.63667 |    185.685635 | Zimices                                                                                                                                                 |
| 113 |     604.48593 |    306.073280 | Tasman Dixon                                                                                                                                            |
| 114 |     996.58550 |    107.680714 | Gareth Monger                                                                                                                                           |
| 115 |     257.96001 |    634.959765 | Ignacio Contreras                                                                                                                                       |
| 116 |     449.74204 |    784.897691 | Matt Martyniuk (modified by Serenchia)                                                                                                                  |
| 117 |     734.26300 |    186.285992 | Becky Barnes                                                                                                                                            |
| 118 |     152.19358 |    745.564189 | Margot Michaud                                                                                                                                          |
| 119 |     909.14050 |    510.319296 | T. Michael Keesey                                                                                                                                       |
| 120 |     470.47149 |     12.799174 | Margot Michaud                                                                                                                                          |
| 121 |    1002.94911 |    433.476414 | Jagged Fang Designs                                                                                                                                     |
| 122 |     386.16515 |    333.885719 | Noah Schlottman, photo by Casey Dunn                                                                                                                    |
| 123 |     490.59035 |    345.169058 | Scott Hartman                                                                                                                                           |
| 124 |     297.33156 |     31.312735 | Erika Schumacher                                                                                                                                        |
| 125 |     642.11118 |    373.065620 | Chris huh                                                                                                                                               |
| 126 |     161.09493 |     79.548631 | Scott Hartman                                                                                                                                           |
| 127 |     660.71925 |    410.676476 | Gareth Monger                                                                                                                                           |
| 128 |     766.27471 |    355.577513 | Matt Crook                                                                                                                                              |
| 129 |     225.59623 |    601.731454 | NA                                                                                                                                                      |
| 130 |     840.95652 |    465.881689 | Michelle Site                                                                                                                                           |
| 131 |     666.06895 |    713.005297 | Zimices                                                                                                                                                 |
| 132 |      73.39839 |    365.096002 | Michael Scroggie                                                                                                                                        |
| 133 |     819.27586 |    220.395537 | Steven Traver                                                                                                                                           |
| 134 |     657.38208 |    721.281047 | Beth Reinke                                                                                                                                             |
| 135 |     237.99411 |    780.348480 | T. Michael Keesey                                                                                                                                       |
| 136 |     517.49538 |    325.941276 | Tasman Dixon                                                                                                                                            |
| 137 |     157.17645 |    226.520391 | Shyamal                                                                                                                                                 |
| 138 |     182.20454 |    391.223681 | Matt Crook                                                                                                                                              |
| 139 |     519.08002 |    581.728402 | Noah Schlottman, photo by Antonio Guillén                                                                                                               |
| 140 |     198.10690 |    357.341073 | Jagged Fang Designs                                                                                                                                     |
| 141 |     891.32367 |    620.531491 | Steven Traver                                                                                                                                           |
| 142 |      24.65105 |    342.790029 | Ferran Sayol                                                                                                                                            |
| 143 |     223.86987 |    756.048268 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                        |
| 144 |      40.45434 |     88.373031 | Xavier Giroux-Bougard                                                                                                                                   |
| 145 |     716.09414 |     12.311017 | Zimices                                                                                                                                                 |
| 146 |     990.27594 |    473.835193 | Markus A. Grohme                                                                                                                                        |
| 147 |     277.35396 |    131.596186 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                         |
| 148 |     726.64164 |    206.877008 | Nobu Tamura and T. Michael Keesey                                                                                                                       |
| 149 |     761.62002 |    765.600003 | T. Michael Keesey (after Marek Velechovský)                                                                                                             |
| 150 |     101.58265 |    779.928713 | Margot Michaud                                                                                                                                          |
| 151 |     268.46663 |    618.220617 | Zimices                                                                                                                                                 |
| 152 |     483.92542 |    516.958459 | Tyler McCraney                                                                                                                                          |
| 153 |     773.32828 |    708.216362 | Jessica Anne Miller                                                                                                                                     |
| 154 |     879.69674 |    410.371772 | Matt Wilkins                                                                                                                                            |
| 155 |     578.74788 |    110.218114 | Gareth Monger                                                                                                                                           |
| 156 |     259.94733 |    405.781878 | T. Michael Keesey (photo by Darren Swim)                                                                                                                |
| 157 |     232.04556 |    714.514084 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                         |
| 158 |     986.13683 |    452.019947 | Noah Schlottman, photo by Casey Dunn                                                                                                                    |
| 159 |     200.67018 |     68.517792 | Walter Vladimir                                                                                                                                         |
| 160 |     465.40013 |    209.286430 | Mathieu Basille                                                                                                                                         |
| 161 |     300.13033 |    301.159104 | Matt Crook                                                                                                                                              |
| 162 |     317.98476 |    460.116172 | Martin R. Smith                                                                                                                                         |
| 163 |      31.93701 |     54.033129 | NA                                                                                                                                                      |
| 164 |     420.62553 |    637.602341 | Steven Traver                                                                                                                                           |
| 165 |     318.92014 |    114.629444 | Zimices                                                                                                                                                 |
| 166 |    1007.54253 |    527.813700 | Scott Hartman                                                                                                                                           |
| 167 |     511.94047 |     13.587790 | NA                                                                                                                                                      |
| 168 |     957.27688 |    437.429797 | Zimices                                                                                                                                                 |
| 169 |     988.71806 |    215.556583 | M Kolmann                                                                                                                                               |
| 170 |     598.68156 |    332.291045 | Alex Slavenko                                                                                                                                           |
| 171 |     252.14824 |    647.531174 | Scott Hartman                                                                                                                                           |
| 172 |     876.60852 |    319.500253 | Julio Garza                                                                                                                                             |
| 173 |     944.88840 |    631.767747 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                    |
| 174 |     700.99807 |    379.636757 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                             |
| 175 |     192.73493 |     86.505940 | Zimices                                                                                                                                                 |
| 176 |     981.23247 |     71.800462 | Emily Willoughby                                                                                                                                        |
| 177 |     915.25689 |    344.465733 | Matt Crook                                                                                                                                              |
| 178 |     474.34129 |    186.665117 | Berivan Temiz                                                                                                                                           |
| 179 |     181.56657 |    498.680842 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 180 |     891.73777 |    469.494144 | Andy Wilson                                                                                                                                             |
| 181 |     800.26623 |    461.650036 | Emily Willoughby                                                                                                                                        |
| 182 |     253.25326 |     97.864290 | Chris huh                                                                                                                                               |
| 183 |     316.51367 |     59.412117 | Ignacio Contreras                                                                                                                                       |
| 184 |      65.33069 |    758.116239 | Jose Carlos Arenas-Monroy                                                                                                                               |
| 185 |     349.64272 |     46.920596 | Markus A. Grohme                                                                                                                                        |
| 186 |     855.61616 |     31.074756 | NA                                                                                                                                                      |
| 187 |     210.76275 |    738.387365 | Sean McCann                                                                                                                                             |
| 188 |     205.59055 |    710.578934 | Collin Gross                                                                                                                                            |
| 189 |     939.79689 |    763.647498 | Jaime Headden                                                                                                                                           |
| 190 |      42.76641 |    711.352637 | Andy Wilson                                                                                                                                             |
| 191 |      32.85366 |    238.987148 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                   |
| 192 |      74.96549 |    579.858821 | kreidefossilien.de                                                                                                                                      |
| 193 |     883.55569 |     29.954212 | NA                                                                                                                                                      |
| 194 |      52.72938 |    280.086087 | Matt Crook                                                                                                                                              |
| 195 |     294.25214 |    507.134640 | Steven Traver                                                                                                                                           |
| 196 |     116.78642 |    376.651836 | NA                                                                                                                                                      |
| 197 |     133.31684 |    467.724881 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                             |
| 198 |     856.46547 |    555.794657 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                  |
| 199 |     765.85379 |      8.504221 | Markus A. Grohme                                                                                                                                        |
| 200 |     838.17486 |    446.637978 | Jaime Headden                                                                                                                                           |
| 201 |      13.25465 |    264.738638 | Gabriela Palomo-Munoz                                                                                                                                   |
| 202 |     901.17498 |    430.089939 | Matt Crook                                                                                                                                              |
| 203 |     465.41778 |    307.027147 | NA                                                                                                                                                      |
| 204 |      92.52098 |    285.140387 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                         |
| 205 |     990.07436 |    541.719763 | Christine Axon                                                                                                                                          |
| 206 |     660.53945 |    152.840364 | Birgit Lang                                                                                                                                             |
| 207 |      42.52479 |    211.758545 | (after Spotila 2004)                                                                                                                                    |
| 208 |     293.27194 |    273.283256 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                     |
| 209 |     235.40417 |     18.726070 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 210 |     750.24090 |    553.261428 | Josefine Bohr Brask                                                                                                                                     |
| 211 |     215.02733 |    162.590767 | Gareth Monger                                                                                                                                           |
| 212 |     511.06806 |    418.356846 | Chuanixn Yu                                                                                                                                             |
| 213 |     436.85839 |    616.307140 | Armin Reindl                                                                                                                                            |
| 214 |     891.35519 |    300.613732 | Birgit Lang                                                                                                                                             |
| 215 |     835.12687 |     12.558274 | Noah Schlottman                                                                                                                                         |
| 216 |     690.83062 |    215.266864 | Iain Reid                                                                                                                                               |
| 217 |     155.22383 |    762.277448 | NA                                                                                                                                                      |
| 218 |     402.10378 |    513.809442 | NA                                                                                                                                                      |
| 219 |     378.38725 |    402.128127 | Noah Schlottman                                                                                                                                         |
| 220 |      30.60957 |    493.876133 | Matt Crook                                                                                                                                              |
| 221 |     440.31284 |    683.378724 | Lauren Sumner-Rooney                                                                                                                                    |
| 222 |     135.59511 |    295.373841 | Rebecca Groom                                                                                                                                           |
| 223 |     718.01942 |    719.965516 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 224 |     954.88678 |    770.210836 | NA                                                                                                                                                      |
| 225 |     677.91086 |    206.839337 | Ferran Sayol                                                                                                                                            |
| 226 |     400.43073 |    468.508336 | NA                                                                                                                                                      |
| 227 |      79.20137 |    724.649946 | Mo Hassan                                                                                                                                               |
| 228 |      42.46017 |    578.012271 | Chloé Schmidt                                                                                                                                           |
| 229 |     114.79411 |    246.997831 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                        |
| 230 |     711.53005 |    792.394491 | Collin Gross                                                                                                                                            |
| 231 |     612.90924 |    563.396702 | Andy Wilson                                                                                                                                             |
| 232 |     321.61891 |    600.031800 | Matt Wilkins                                                                                                                                            |
| 233 |     859.31339 |    527.226710 | Milton Tan                                                                                                                                              |
| 234 |     472.57937 |     95.625677 | Margot Michaud                                                                                                                                          |
| 235 |     970.51133 |    734.449010 | Gareth Monger                                                                                                                                           |
| 236 |     409.70662 |    169.816106 | Markus A. Grohme                                                                                                                                        |
| 237 |     752.56209 |    155.447295 | Lily Hughes                                                                                                                                             |
| 238 |     557.02962 |    101.748286 | Andy Wilson                                                                                                                                             |
| 239 |      87.17599 |    418.335659 | Zimices                                                                                                                                                 |
| 240 |     482.22084 |     82.064392 | Zimices                                                                                                                                                 |
| 241 |     264.81208 |     53.949834 | Markus A. Grohme                                                                                                                                        |
| 242 |     340.16265 |    767.820293 | Ferran Sayol                                                                                                                                            |
| 243 |     603.03773 |    241.966869 | Scott Hartman                                                                                                                                           |
| 244 |     400.23235 |    359.631852 | Chris huh                                                                                                                                               |
| 245 |     782.03465 |    597.070115 | Gareth Monger                                                                                                                                           |
| 246 |      98.24119 |    756.604111 | Javier Luque                                                                                                                                            |
| 247 |     567.70741 |    141.832722 | Milton Tan                                                                                                                                              |
| 248 |      75.63594 |     54.218182 | Erika Schumacher                                                                                                                                        |
| 249 |      41.14125 |    109.638682 | Zimices                                                                                                                                                 |
| 250 |      63.33865 |    350.572113 | Kai R. Caspar                                                                                                                                           |
| 251 |     976.05758 |    617.895898 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                              |
| 252 |     613.57053 |    606.926688 | Jagged Fang Designs                                                                                                                                     |
| 253 |     145.89461 |     20.596715 | Manabu Bessho-Uehara                                                                                                                                    |
| 254 |     158.16758 |    249.851953 | Ingo Braasch                                                                                                                                            |
| 255 |     157.81106 |    459.847986 | Margot Michaud                                                                                                                                          |
| 256 |     845.28254 |    303.209431 | Jose Carlos Arenas-Monroy                                                                                                                               |
| 257 |    1012.80711 |    685.468256 | Gareth Monger                                                                                                                                           |
| 258 |     876.55094 |    441.699389 | NA                                                                                                                                                      |
| 259 |      20.77071 |    671.903773 | Tasman Dixon                                                                                                                                            |
| 260 |     950.61067 |    512.415481 | C. Camilo Julián-Caballero                                                                                                                              |
| 261 |     907.41606 |     73.653927 | Armin Reindl                                                                                                                                            |
| 262 |     268.76551 |    679.050632 | Mathilde Cordellier                                                                                                                                     |
| 263 |      16.84811 |    575.793903 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                         |
| 264 |     893.60343 |     56.156692 | (after Spotila 2004)                                                                                                                                    |
| 265 |      41.82236 |    259.728567 | Markus A. Grohme                                                                                                                                        |
| 266 |     618.92178 |    463.207386 | Dmitry Bogdanov                                                                                                                                         |
| 267 |    1006.95788 |     89.075480 | Michael Scroggie                                                                                                                                        |
| 268 |      20.80240 |    326.993446 | Steven Traver                                                                                                                                           |
| 269 |     127.27508 |    132.417092 | Chuanixn Yu                                                                                                                                             |
| 270 |     275.53687 |     70.938985 | Markus A. Grohme                                                                                                                                        |
| 271 |     400.86537 |     25.272795 | Gareth Monger                                                                                                                                           |
| 272 |     109.53378 |    614.515364 | Christoph Schomburg                                                                                                                                     |
| 273 |     297.34477 |    244.819702 | Curtis Clark and T. Michael Keesey                                                                                                                      |
| 274 |     390.11984 |    203.189647 | Maija Karala                                                                                                                                            |
| 275 |     596.16195 |    491.792246 | Andy Wilson                                                                                                                                             |
| 276 |      15.11073 |    121.760918 | Jon M Laurent                                                                                                                                           |
| 277 |     259.66393 |    305.530749 | Scott Hartman                                                                                                                                           |
| 278 |     649.58086 |    418.881241 | T. Michael Keesey                                                                                                                                       |
| 279 |      81.93261 |    793.729836 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                           |
| 280 |     343.68104 |    189.682640 | Emily Willoughby                                                                                                                                        |
| 281 |     408.42228 |    789.645824 | Milton Tan                                                                                                                                              |
| 282 |     829.69739 |    512.758769 | NA                                                                                                                                                      |
| 283 |     873.77865 |    587.939157 | NA                                                                                                                                                      |
| 284 |     618.86770 |    508.284522 | Margot Michaud                                                                                                                                          |
| 285 |     799.07523 |    693.356553 | Gopal Murali                                                                                                                                            |
| 286 |     379.85326 |    550.241636 | Gareth Monger                                                                                                                                           |
| 287 |     639.33967 |    171.484959 | Alexandre Vong                                                                                                                                          |
| 288 |     397.69361 |    384.835407 | Gareth Monger                                                                                                                                           |
| 289 |     514.03808 |    482.404139 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 290 |      90.60555 |    462.544848 | Steven Coombs                                                                                                                                           |
| 291 |     587.14092 |    531.169892 | Jagged Fang Designs                                                                                                                                     |
| 292 |      20.04554 |    721.362587 | Gareth Monger                                                                                                                                           |
| 293 |    1005.12855 |    459.867487 | Jagged Fang Designs                                                                                                                                     |
| 294 |     191.44686 |    311.351322 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 295 |     500.26771 |    787.358386 | Tauana J. Cunha                                                                                                                                         |
| 296 |      70.35350 |    686.851092 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 297 |     229.67853 |     77.693427 | Margot Michaud                                                                                                                                          |
| 298 |     166.54889 |     93.005532 | Caleb M. Brown                                                                                                                                          |
| 299 |     797.82648 |    242.207770 | Dean Schnabel                                                                                                                                           |
| 300 |     771.81085 |    610.905709 | Sarah Werning                                                                                                                                           |
| 301 |     227.15212 |    417.154418 | Matt Crook                                                                                                                                              |
| 302 |     168.16393 |    280.269216 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                       |
| 303 |     837.34067 |    260.467189 | Steven Traver                                                                                                                                           |
| 304 |    1008.03394 |    607.120466 | Jagged Fang Designs                                                                                                                                     |
| 305 |     178.89509 |     20.527547 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 306 |     327.14212 |    551.253829 | Dean Schnabel                                                                                                                                           |
| 307 |     801.18207 |    624.753805 | (unknown)                                                                                                                                               |
| 308 |      78.62873 |    604.975653 | Isaure Scavezzoni                                                                                                                                       |
| 309 |     424.13813 |    733.013446 | NA                                                                                                                                                      |
| 310 |     168.50914 |    478.213024 | Servien (vectorized by T. Michael Keesey)                                                                                                               |
| 311 |     285.65112 |    466.877167 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                          |
| 312 |     441.68186 |    260.711839 | Scott Hartman                                                                                                                                           |
| 313 |     628.78925 |    401.646695 | Kamil S. Jaron                                                                                                                                          |
| 314 |     408.70658 |      9.868584 | Christoph Schomburg                                                                                                                                     |
| 315 |     239.15376 |    120.436846 | Chris huh                                                                                                                                               |
| 316 |     152.95900 |    738.680156 | Armin Reindl                                                                                                                                            |
| 317 |     912.87140 |    321.578008 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 318 |    1002.48720 |    625.239407 | Sarah Werning                                                                                                                                           |
| 319 |     259.32700 |    772.204803 | T. Michael Keesey                                                                                                                                       |
| 320 |    1006.52739 |    716.492564 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                  |
| 321 |     164.63889 |    693.321582 | Joanna Wolfe                                                                                                                                            |
| 322 |     957.63105 |     55.500295 | NA                                                                                                                                                      |
| 323 |     348.02687 |     59.346706 | Jaime Headden                                                                                                                                           |
| 324 |     912.89227 |    286.449267 | Sergio A. Muñoz-Gómez                                                                                                                                   |
| 325 |     839.47387 |    179.846500 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 326 |     260.16919 |    598.638873 | NA                                                                                                                                                      |
| 327 |     921.77159 |    145.210613 | Jagged Fang Designs                                                                                                                                     |
| 328 |     555.44592 |    297.779808 | Steven Traver                                                                                                                                           |
| 329 |     253.60672 |    657.251893 | T. Michael Keesey                                                                                                                                       |
| 330 |     172.52820 |    379.304890 | Matt Crook                                                                                                                                              |
| 331 |     287.49980 |    225.597117 | SauropodomorphMonarch                                                                                                                                   |
| 332 |      31.80419 |    457.167406 | Matt Crook                                                                                                                                              |
| 333 |      96.21002 |    647.727432 | Kai R. Caspar                                                                                                                                           |
| 334 |     340.80227 |    606.136578 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                         |
| 335 |     554.40110 |    442.940999 | Jagged Fang Designs                                                                                                                                     |
| 336 |     915.76396 |    739.029372 | Birgit Lang                                                                                                                                             |
| 337 |     700.32151 |    615.889406 | NA                                                                                                                                                      |
| 338 |     159.47066 |    785.813372 | Harold N Eyster                                                                                                                                         |
| 339 |     806.97612 |    259.256357 | Chris huh                                                                                                                                               |
| 340 |     447.44063 |    732.084919 | NA                                                                                                                                                      |
| 341 |     623.68422 |    302.658050 | Tasman Dixon                                                                                                                                            |
| 342 |     507.43625 |    184.152629 | NA                                                                                                                                                      |
| 343 |     960.16137 |    345.290167 | Sarah Werning                                                                                                                                           |
| 344 |     760.22249 |    203.444179 | Chris huh                                                                                                                                               |
| 345 |      24.96101 |    296.660451 | NA                                                                                                                                                      |
| 346 |     727.35850 |    376.120555 | Iain Reid                                                                                                                                               |
| 347 |      90.85218 |    627.800397 | Conty                                                                                                                                                   |
| 348 |      60.70440 |    426.262514 | Chris huh                                                                                                                                               |
| 349 |     385.45890 |    312.978585 | Markus A. Grohme                                                                                                                                        |
| 350 |     483.95293 |    111.460933 | Matt Crook                                                                                                                                              |
| 351 |     514.99703 |     21.335967 | Margot Michaud                                                                                                                                          |
| 352 |     916.26574 |    608.867477 | Tasman Dixon                                                                                                                                            |
| 353 |      32.39583 |    198.352029 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 354 |     816.92731 |    452.887037 | Andy Wilson                                                                                                                                             |
| 355 |     745.81389 |    707.491965 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                          |
| 356 |     529.38257 |    196.727428 | Gabriela Palomo-Munoz                                                                                                                                   |
| 357 |     962.02677 |    717.305504 | Steven Traver                                                                                                                                           |
| 358 |     914.87223 |    299.708763 | Matt Crook                                                                                                                                              |
| 359 |     491.89197 |    170.651329 | Chris huh                                                                                                                                               |
| 360 |     231.99965 |    154.678141 | Steven Coombs                                                                                                                                           |
| 361 |     367.25595 |    346.735120 | Jagged Fang Designs                                                                                                                                     |
| 362 |     695.58087 |    271.086600 | Melissa Broussard                                                                                                                                       |
| 363 |     787.44476 |    566.588897 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 364 |     383.83439 |     34.369987 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                             |
| 365 |     240.58296 |    735.522127 | Vanessa Guerra                                                                                                                                          |
| 366 |     848.10288 |    457.957525 | T. Michael Keesey                                                                                                                                       |
| 367 |     105.10802 |     56.120549 | Anthony Caravaggi                                                                                                                                       |
| 368 |    1017.56096 |    191.426512 | Agnello Picorelli                                                                                                                                       |
| 369 |     577.47542 |    648.901161 | Margot Michaud                                                                                                                                          |
| 370 |     403.34524 |    348.046660 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 371 |     238.67989 |    513.821817 | Smokeybjb                                                                                                                                               |
| 372 |     761.33079 |    751.777835 | Scott Hartman                                                                                                                                           |
| 373 |     285.48708 |    322.343721 | Christoph Schomburg                                                                                                                                     |
| 374 |     229.49872 |    507.440673 | Cesar Julian                                                                                                                                            |
| 375 |     471.79475 |    435.064245 | L. Shyamal                                                                                                                                              |
| 376 |     422.36438 |    481.737664 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                   |
| 377 |     242.21591 |    132.164618 | Inessa Voet                                                                                                                                             |
| 378 |    1008.87786 |    268.616916 | Dean Schnabel                                                                                                                                           |
| 379 |     702.60817 |    784.674947 | Dmitry Bogdanov                                                                                                                                         |
| 380 |     375.59254 |      8.425929 | Raven Amos                                                                                                                                              |
| 381 |     343.64140 |     95.513785 | Harold N Eyster                                                                                                                                         |
| 382 |     100.97320 |    359.778562 | Yan Wong                                                                                                                                                |
| 383 |     229.39538 |    675.596365 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                        |
| 384 |     466.55339 |    538.634271 | Matt Crook                                                                                                                                              |
| 385 |     896.85662 |    373.092855 | Collin Gross                                                                                                                                            |
| 386 |     124.83804 |    555.432008 | T. Michael Keesey                                                                                                                                       |
| 387 |     308.49343 |    664.189013 | Andrew R. Gehrke                                                                                                                                        |
| 388 |     270.35008 |     79.584647 | Gareth Monger                                                                                                                                           |
| 389 |     964.07085 |    243.064179 | Chris huh                                                                                                                                               |
| 390 |     289.53095 |    103.840830 | Chris huh                                                                                                                                               |
| 391 |     978.06487 |     83.316098 | Dmitry Bogdanov                                                                                                                                         |
| 392 |     503.09148 |    319.045134 | Armin Reindl                                                                                                                                            |
| 393 |     251.99221 |    251.633127 | Chris huh                                                                                                                                               |
| 394 |      78.52823 |    382.865618 | Crystal Maier                                                                                                                                           |
| 395 |     614.42715 |    582.516964 | Dean Schnabel                                                                                                                                           |
| 396 |     831.23499 |    251.795762 | Rene Martin                                                                                                                                             |
| 397 |     203.51347 |    529.289878 | NA                                                                                                                                                      |
| 398 |     864.65558 |    159.969431 | NA                                                                                                                                                      |
| 399 |     647.62514 |    461.248196 | Madeleine Price Ball                                                                                                                                    |
| 400 |     579.31230 |    154.523566 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 401 |     198.12667 |    581.143621 | Chris huh                                                                                                                                               |
| 402 |     674.54344 |     11.916357 | Kai R. Caspar                                                                                                                                           |
| 403 |     321.53594 |    727.447410 | Gareth Monger                                                                                                                                           |
| 404 |    1012.12589 |    581.723813 | T. Michael Keesey                                                                                                                                       |
| 405 |     744.69995 |    609.329384 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                         |
| 406 |     544.93466 |    759.460193 | B. Duygu Özpolat                                                                                                                                        |
| 407 |     897.82351 |    271.810038 | xgirouxb                                                                                                                                                |
| 408 |     164.55348 |    577.837743 | Chris huh                                                                                                                                               |
| 409 |     347.05623 |    423.241418 | Matt Crook                                                                                                                                              |
| 410 |     614.76363 |      7.510781 | Andy Wilson                                                                                                                                             |
| 411 |     331.91363 |    682.307207 | Sarah Werning                                                                                                                                           |
| 412 |     705.04810 |    550.421411 | Mathew Wedel                                                                                                                                            |
| 413 |     213.06022 |     13.256494 | Jagged Fang Designs                                                                                                                                     |
| 414 |     444.82249 |    249.926515 | FunkMonk                                                                                                                                                |
| 415 |     635.67936 |    586.461122 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                            |
| 416 |     749.22280 |    511.174676 | Jagged Fang Designs                                                                                                                                     |
| 417 |     393.82828 |     92.706608 | Jagged Fang Designs                                                                                                                                     |
| 418 |     414.67852 |    431.993354 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                   |
| 419 |     905.03934 |    532.993456 | Ignacio Contreras                                                                                                                                       |
| 420 |     997.78859 |     58.734440 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                |
| 421 |     324.61504 |    272.938516 | Jaime Headden                                                                                                                                           |
| 422 |     233.78915 |    624.315307 | Zimices                                                                                                                                                 |
| 423 |     906.78045 |     28.104960 | Chris huh                                                                                                                                               |
| 424 |     273.08148 |    393.871204 | Mathew Wedel                                                                                                                                            |
| 425 |     317.13529 |     79.039041 | Mathew Wedel                                                                                                                                            |
| 426 |     367.95441 |    769.380991 | Gordon E. Robertson                                                                                                                                     |
| 427 |    1013.88461 |    146.860091 | T. Michael Keesey                                                                                                                                       |
| 428 |      12.96438 |    214.428315 | Agnello Picorelli                                                                                                                                       |
| 429 |     642.27719 |    311.172328 | Scott Hartman                                                                                                                                           |
| 430 |     499.96183 |     33.141246 | Margot Michaud                                                                                                                                          |
| 431 |     901.77523 |    704.531161 | Matt Martyniuk                                                                                                                                          |
| 432 |      26.97124 |     60.144275 | CNZdenek                                                                                                                                                |
| 433 |     734.37497 |    566.006418 | Markus A. Grohme                                                                                                                                        |
| 434 |    1007.84214 |    323.220691 | Matt Crook                                                                                                                                              |
| 435 |     604.24543 |    545.427290 | Gareth Monger                                                                                                                                           |
| 436 |     355.18409 |    202.371416 | CNZdenek                                                                                                                                                |
| 437 |     858.50992 |    330.109306 | Jagged Fang Designs                                                                                                                                     |
| 438 |     944.07993 |    489.627480 | Michael Day                                                                                                                                             |
| 439 |      39.42586 |    226.244649 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                         |
| 440 |     759.88668 |    218.017823 | Allison Pease                                                                                                                                           |
| 441 |     318.92361 |    629.017327 | Servien (vectorized by T. Michael Keesey)                                                                                                               |
| 442 |     328.79541 |     35.052324 | Julio Garza                                                                                                                                             |
| 443 |     432.40399 |    214.303966 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                       |
| 444 |      38.83139 |     68.662769 | Scott Hartman                                                                                                                                           |
| 445 |     681.81175 |    398.160437 | Matt Martyniuk                                                                                                                                          |
| 446 |     726.92176 |    354.511636 | Matt Martyniuk (modified by Serenchia)                                                                                                                  |
| 447 |     337.48916 |    744.925249 | Jagged Fang Designs                                                                                                                                     |
| 448 |     335.68541 |    334.794736 | Terpsichores                                                                                                                                            |
| 449 |     568.22498 |    702.471718 | Jack Mayer Wood                                                                                                                                         |
| 450 |     105.25332 |    604.049744 | Jack Mayer Wood                                                                                                                                         |
| 451 |     371.27374 |    788.566709 | G. M. Woodward                                                                                                                                          |
| 452 |     461.02327 |    329.024808 | Nobu Tamura                                                                                                                                             |
| 453 |     242.36755 |    574.343747 | Mathilde Cordellier                                                                                                                                     |
| 454 |     996.76318 |    371.449575 | Andrew A. Farke                                                                                                                                         |
| 455 |     605.75088 |    156.800858 | Scott Hartman                                                                                                                                           |
| 456 |     121.08784 |    410.021211 | Andrew A. Farke                                                                                                                                         |
| 457 |     285.15579 |    643.094346 | T. Michael Keesey                                                                                                                                       |
| 458 |     531.35651 |    452.809848 | Smith609 and T. Michael Keesey                                                                                                                          |
| 459 |     561.12018 |    615.236769 | Jagged Fang Designs                                                                                                                                     |
| 460 |     754.06895 |    784.364028 | Zimices                                                                                                                                                 |
| 461 |     768.41602 |    314.590388 | Zimices                                                                                                                                                 |
| 462 |     182.11782 |    464.867963 | Tasman Dixon                                                                                                                                            |
| 463 |     646.33556 |    620.261996 | Gareth Monger                                                                                                                                           |
| 464 |     898.99201 |    196.235441 | Chris huh                                                                                                                                               |
| 465 |     871.58094 |    600.113783 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                         |
| 466 |     836.57504 |    426.086290 | Margot Michaud                                                                                                                                          |
| 467 |     356.59155 |    211.736210 | FunkMonk                                                                                                                                                |
| 468 |     361.40125 |    471.037768 | Margot Michaud                                                                                                                                          |
| 469 |     380.41177 |    130.002681 | M Kolmann                                                                                                                                               |
| 470 |     653.32813 |    791.342147 | Andrew A. Farke                                                                                                                                         |
| 471 |      11.43050 |    768.887167 | Gareth Monger                                                                                                                                           |
| 472 |     110.60555 |    266.329555 | Zimices                                                                                                                                                 |
| 473 |     200.29277 |    513.061766 | Mathew Wedel                                                                                                                                            |
| 474 |     790.68669 |     15.689669 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                           |
| 475 |     384.29052 |    566.489117 | Scott Hartman                                                                                                                                           |
| 476 |     109.01555 |     71.397177 | Chris huh                                                                                                                                               |
| 477 |     421.15220 |    608.786055 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                           |
| 478 |     158.80751 |    427.474650 | Matt Crook                                                                                                                                              |
| 479 |     134.61909 |    782.237365 | T. Michael Keesey                                                                                                                                       |
| 480 |     926.91391 |    713.903907 | Matt Crook                                                                                                                                              |
| 481 |     648.42338 |    762.359155 | Cagri Cevrim                                                                                                                                            |
| 482 |     986.27800 |    793.099385 | Markus A. Grohme                                                                                                                                        |
| 483 |     390.22528 |    778.536766 | Scott Hartman                                                                                                                                           |
| 484 |     470.40001 |    752.456187 | Christine Axon                                                                                                                                          |
| 485 |     188.93888 |    329.959058 | Renata F. Martins                                                                                                                                       |
| 486 |     256.09465 |    169.407889 | Margot Michaud                                                                                                                                          |
| 487 |     257.74086 |     89.459333 | Markus A. Grohme                                                                                                                                        |
| 488 |     162.76490 |      6.067246 | Nobu Tamura, vectorized by Zimices                                                                                                                      |
| 489 |     841.45781 |    753.475893 | T. Michael Keesey                                                                                                                                       |
| 490 |     541.98393 |    728.177415 | Scott Hartman                                                                                                                                           |
| 491 |     654.87815 |    385.315967 | Margot Michaud                                                                                                                                          |
| 492 |     447.86234 |    279.457507 | Markus A. Grohme                                                                                                                                        |
| 493 |     861.70381 |    566.224344 | Ignacio Contreras                                                                                                                                       |
| 494 |     451.71472 |    347.128222 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 495 |     395.33052 |    530.969506 | Gabriela Palomo-Munoz                                                                                                                                   |
| 496 |     404.18085 |    127.213449 | Iain Reid                                                                                                                                               |
| 497 |     272.20505 |    422.298245 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                          |
| 498 |     388.06628 |    320.713079 | Ignacio Contreras                                                                                                                                       |
| 499 |     304.81968 |     42.655492 | Margot Michaud                                                                                                                                          |
| 500 |     502.72132 |    207.875090 | Markus A. Grohme                                                                                                                                        |
| 501 |     374.01398 |    376.632491 | Matt Crook                                                                                                                                              |
| 502 |     295.71874 |    755.802532 | Douglas Brown (modified by T. Michael Keesey)                                                                                                           |
| 503 |     458.98384 |    694.386368 | Chris huh                                                                                                                                               |
| 504 |     425.57597 |    506.293658 | Jagged Fang Designs                                                                                                                                     |
| 505 |     139.48184 |    122.038491 | Chris huh                                                                                                                                               |

    #> Your tweet has been posted!
