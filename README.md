
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

Birgit Lang, Jagged Fang Designs, Armin Reindl, Steven Traver, Joanna
Wolfe, T. Michael Keesey, Chris A. Hamilton, Gareth Monger, U.S.
National Park Service (vectorized by William Gearty), Tauana J. Cunha,
Robbie N. Cada (vectorized by T. Michael Keesey), Hugo Gruson, Becky
Barnes, Matt Martyniuk, Gabriela Palomo-Munoz, Tasman Dixon, Michelle
Site, Ferran Sayol, C. Camilo Julián-Caballero, Zimices, Sarah Werning,
Chris huh, Noah Schlottman, Margot Michaud, Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Matt Crook, Markus A. Grohme, Erika Schumacher, Oren Peles / vectorized
by Yan Wong, Collin Gross, Florian Pfaff, Jan Sevcik (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Nicholas J.
Czaplewski, vectorized by Zimices, Obsidian Soul (vectorized by T.
Michael Keesey), Felix Vaux, David Orr, Chase Brownstein, Michele M
Tobias, Nobu Tamura (vectorized by T. Michael Keesey), Andrés Sánchez,
Saguaro Pictures (source photo) and T. Michael Keesey, Alexander
Schmidt-Lebuhn, Martin Kevil, Abraão Leite, Jakovche, Maxwell Lefroy
(vectorized by T. Michael Keesey), Scott Hartman, Filip em, Juan Carlos
Jerí, Andrew A. Farke, Shyamal, Christoph Schomburg, Dmitry Bogdanov,
Ingo Braasch, Alex Slavenko, Yan Wong, Lukas Panzarin, C. Abraczinskas,
Yan Wong (vectorization) from 1873 illustration, Stacy Spensley
(Modified), FunkMonk, A. H. Baldwin (vectorized by T. Michael Keesey),
Smokeybjb, vectorized by Zimices, Michael Scroggie, Jesús Gómez,
vectorized by Zimices, Andrew R. Gehrke, Ray Simpson (vectorized by T.
Michael Keesey), SauropodomorphMonarch, Mathilde Cordellier, Andy
Wilson, Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey),
Philip Chalmers (vectorized by T. Michael Keesey), Darren Naish
(vectorize by T. Michael Keesey), Andreas Preuss / marauder, Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Hans
Hillewaert (vectorized by T. Michael Keesey), Dean Schnabel, Manabu
Bessho-Uehara, Aadx, Antonov (vectorized by T. Michael Keesey), Kamil S.
Jaron, S.Martini, Henry Fairfield Osborn, vectorized by Zimices,
Meliponicultor Itaymbere, Mark Miller, Lisa Byrne, Sam Fraser-Smith
(vectorized by T. Michael Keesey), Mathew Wedel, Caleb M. Brown,
Apokryltaros (vectorized by T. Michael Keesey), Scott Hartman
(vectorized by William Gearty), Maxime Dahirel, Nobu Tamura, vectorized
by Zimices, Jose Carlos Arenas-Monroy, Anna Willoughby, M Kolmann,
Ludwik Gasiorowski, Elisabeth Östman, Chloé Schmidt, Tambja (vectorized
by T. Michael Keesey), Benjamin Monod-Broca, Steven Coombs, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Jaime Headden, Benchill, Dave Angelini, Konsta
Happonen, Dmitry Bogdanov (vectorized by T. Michael Keesey), E. D. Cope
(modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
Gopal Murali, B. Duygu Özpolat, Lukas Panzarin (vectorized by T. Michael
Keesey), , Rebecca Groom, SecretJellyMan - from Mason McNair, Mike
Keesey (vectorization) and Vaibhavcho (photography), Lukasiniho, Bruno
C. Vellutini, Nobu Tamura, Anilocra (vectorization by Yan Wong),
Jennifer Trimble, Walter Vladimir, Vijay Cavale (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Ekaterina
Kopeykina (vectorized by T. Michael Keesey), Sean McCann, Arthur S.
Brum, LeonardoG (photography) and T. Michael Keesey (vectorization),
Maija Karala, Tracy A. Heath, Birgit Lang; based on a drawing by C.L.
Koch, Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Ignacio Contreras, www.studiospectre.com,
Jay Matternes (modified by T. Michael Keesey), Scott Reid, Xavier
Giroux-Bougard, E. R. Waite & H. M. Hale (vectorized by T. Michael
Keesey), Chuanixn Yu, Sharon Wegner-Larsen, Iain Reid, Emily Willoughby,
Katie S. Collins, Lankester Edwin Ray (vectorized by T. Michael Keesey),
Milton Tan, Arthur Weasley (vectorized by T. Michael Keesey), Jay
Matternes, vectorized by Zimices, L. Shyamal, Geoff Shaw, Rene Martin,
Brad McFeeters (vectorized by T. Michael Keesey), Henry Lydecker,
Jonathan Wells, Philippe Janvier (vectorized by T. Michael Keesey),
Steven Haddock • Jellywatch.org, Siobhon Egan, Smokeybjb, Jessica Rick,
Michael P. Taylor, Scarlet23 (vectorized by T. Michael Keesey), Tyler
Greenfield and Scott Hartman, Pearson Scott Foresman (vectorized by T.
Michael Keesey), Mathieu Basille, Jaime Headden, modified by T. Michael
Keesey, Mattia Menchetti / Yan Wong, Zachary Quigley, Beth Reinke,
Thibaut Brunet, Lafage, Blanco et al., 2014, vectorized by Zimices,
Mette Aumala, Jordan Mallon (vectorized by T. Michael Keesey),
Myriam\_Ramirez, Agnello Picorelli, Neil Kelley

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    723.551424 |    507.386758 | Birgit Lang                                                                                                                                                        |
|   2 |     86.645300 |    210.125259 | Jagged Fang Designs                                                                                                                                                |
|   3 |    443.349133 |    710.763455 | Armin Reindl                                                                                                                                                       |
|   4 |    764.840069 |    165.771912 | Steven Traver                                                                                                                                                      |
|   5 |    198.435970 |    118.358506 | Joanna Wolfe                                                                                                                                                       |
|   6 |    410.122794 |    115.123882 | T. Michael Keesey                                                                                                                                                  |
|   7 |    104.178530 |    489.550084 | Chris A. Hamilton                                                                                                                                                  |
|   8 |    116.873731 |    369.439873 | Gareth Monger                                                                                                                                                      |
|   9 |    490.283558 |    481.742361 | Gareth Monger                                                                                                                                                      |
|  10 |    307.235105 |    619.439132 | U.S. National Park Service (vectorized by William Gearty)                                                                                                          |
|  11 |    273.195941 |    461.171299 | Tauana J. Cunha                                                                                                                                                    |
|  12 |    958.581151 |    137.037385 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
|  13 |    566.463167 |    649.181778 | Hugo Gruson                                                                                                                                                        |
|  14 |    556.587398 |    389.054840 | Becky Barnes                                                                                                                                                       |
|  15 |    704.696541 |    452.931697 | Matt Martyniuk                                                                                                                                                     |
|  16 |    496.075647 |    287.020463 | Gabriela Palomo-Munoz                                                                                                                                              |
|  17 |    619.119283 |    126.533329 | Tasman Dixon                                                                                                                                                       |
|  18 |    865.715469 |    371.962519 | Michelle Site                                                                                                                                                      |
|  19 |    504.167905 |    683.147976 | Ferran Sayol                                                                                                                                                       |
|  20 |    851.841538 |    570.310101 | Jagged Fang Designs                                                                                                                                                |
|  21 |    941.474735 |    253.883916 | C. Camilo Julián-Caballero                                                                                                                                         |
|  22 |    950.250566 |    368.719552 | Zimices                                                                                                                                                            |
|  23 |    254.644092 |    738.097953 | Sarah Werning                                                                                                                                                      |
|  24 |    602.901736 |    746.382089 | Chris huh                                                                                                                                                          |
|  25 |    974.988055 |    528.032223 | Noah Schlottman                                                                                                                                                    |
|  26 |     64.183076 |    270.137304 | Margot Michaud                                                                                                                                                     |
|  27 |    769.187143 |    683.360926 | Steven Traver                                                                                                                                                      |
|  28 |    792.908995 |    328.087134 | Zimices                                                                                                                                                            |
|  29 |    267.547054 |    180.150553 | Margot Michaud                                                                                                                                                     |
|  30 |    363.773826 |    304.990042 | T. Michael Keesey                                                                                                                                                  |
|  31 |    488.902264 |     70.495540 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
|  32 |    874.835348 |    741.828712 | Matt Crook                                                                                                                                                         |
|  33 |    247.865083 |    302.974246 | Markus A. Grohme                                                                                                                                                   |
|  34 |    102.426433 |    610.187419 | C. Camilo Julián-Caballero                                                                                                                                         |
|  35 |    953.321779 |     59.695055 | Erika Schumacher                                                                                                                                                   |
|  36 |    429.254130 |    354.689023 | T. Michael Keesey                                                                                                                                                  |
|  37 |     72.505112 |    756.662893 | Zimices                                                                                                                                                            |
|  38 |    656.192069 |    664.087872 | Armin Reindl                                                                                                                                                       |
|  39 |    314.905850 |     78.382713 | Oren Peles / vectorized by Yan Wong                                                                                                                                |
|  40 |    697.022992 |    381.154991 | Collin Gross                                                                                                                                                       |
|  41 |    593.768365 |    557.177827 | Chris huh                                                                                                                                                          |
|  42 |    679.271720 |    241.416887 | Florian Pfaff                                                                                                                                                      |
|  43 |    366.059618 |    662.985805 | Jagged Fang Designs                                                                                                                                                |
|  44 |    758.360751 |    610.689021 | Zimices                                                                                                                                                            |
|  45 |    375.130621 |    209.698623 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
|  46 |    673.200479 |     39.369749 | Gareth Monger                                                                                                                                                      |
|  47 |    582.821537 |    500.496012 | Margot Michaud                                                                                                                                                     |
|  48 |     35.272057 |    102.201650 | T. Michael Keesey                                                                                                                                                  |
|  49 |    382.764392 |    469.248324 | Ferran Sayol                                                                                                                                                       |
|  50 |    175.219165 |     77.446494 | Markus A. Grohme                                                                                                                                                   |
|  51 |    863.150365 |    493.851446 | Steven Traver                                                                                                                                                      |
|  52 |    511.459425 |    161.227842 | Steven Traver                                                                                                                                                      |
|  53 |    613.871962 |    330.161246 | Margot Michaud                                                                                                                                                     |
|  54 |    574.264030 |    213.086890 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                      |
|  55 |    555.374682 |    248.393979 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                    |
|  56 |    931.654320 |    674.533307 | Felix Vaux                                                                                                                                                         |
|  57 |    346.183461 |    767.186541 | NA                                                                                                                                                                 |
|  58 |    823.068972 |    273.800237 | David Orr                                                                                                                                                          |
|  59 |    156.038822 |    733.526902 | NA                                                                                                                                                                 |
|  60 |    789.373410 |     50.685341 | Gabriela Palomo-Munoz                                                                                                                                              |
|  61 |    404.314263 |    298.489959 | Gareth Monger                                                                                                                                                      |
|  62 |    439.739846 |    582.502186 | Chase Brownstein                                                                                                                                                   |
|  63 |    945.947281 |    786.710571 | Markus A. Grohme                                                                                                                                                   |
|  64 |    725.870295 |    293.299642 | Michele M Tobias                                                                                                                                                   |
|  65 |    115.907593 |     37.169084 | Markus A. Grohme                                                                                                                                                   |
|  66 |    729.234056 |    763.512880 | Margot Michaud                                                                                                                                                     |
|  67 |    959.136588 |    176.898751 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  68 |    987.677883 |    684.611089 | Andrés Sánchez                                                                                                                                                     |
|  69 |    589.323099 |     63.444079 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                              |
|  70 |    563.840055 |    447.506749 | Alexander Schmidt-Lebuhn                                                                                                                                           |
|  71 |    530.206088 |    779.504392 | Markus A. Grohme                                                                                                                                                   |
|  72 |    142.762378 |    178.028135 | Martin Kevil                                                                                                                                                       |
|  73 |    897.157259 |    388.636723 | Abraão Leite                                                                                                                                                       |
|  74 |    341.195515 |    397.046265 | Steven Traver                                                                                                                                                      |
|  75 |    458.787205 |    747.100333 | Zimices                                                                                                                                                            |
|  76 |    431.226251 |    527.047058 | NA                                                                                                                                                                 |
|  77 |    645.229417 |    774.183074 | Matt Crook                                                                                                                                                         |
|  78 |    791.436761 |    384.522367 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
|  79 |     39.180603 |    652.655746 | Ferran Sayol                                                                                                                                                       |
|  80 |    515.638751 |    402.767329 | Jakovche                                                                                                                                                           |
|  81 |    913.274624 |    552.183625 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                   |
|  82 |    228.358908 |    571.327707 | Tasman Dixon                                                                                                                                                       |
|  83 |    710.870427 |    623.231139 | Scott Hartman                                                                                                                                                      |
|  84 |    482.635047 |    794.776321 | Filip em                                                                                                                                                           |
|  85 |    843.257372 |    652.017791 | Juan Carlos Jerí                                                                                                                                                   |
|  86 |    202.433719 |    368.143025 | T. Michael Keesey                                                                                                                                                  |
|  87 |    383.259438 |     38.176558 | Andrew A. Farke                                                                                                                                                    |
|  88 |    863.278017 |     71.078635 | Shyamal                                                                                                                                                            |
|  89 |    802.564570 |    435.624702 | Christoph Schomburg                                                                                                                                                |
|  90 |    908.601550 |    320.920087 | Noah Schlottman                                                                                                                                                    |
|  91 |    451.835728 |    667.122768 | Dmitry Bogdanov                                                                                                                                                    |
|  92 |    892.980699 |    203.415514 | Ingo Braasch                                                                                                                                                       |
|  93 |    210.674146 |    596.826451 | NA                                                                                                                                                                 |
|  94 |    154.322441 |    292.512796 | Margot Michaud                                                                                                                                                     |
|  95 |    898.071416 |    636.254833 | Alex Slavenko                                                                                                                                                      |
|  96 |    199.341327 |    700.643662 | Yan Wong                                                                                                                                                           |
|  97 |    969.147170 |    319.556519 | Jagged Fang Designs                                                                                                                                                |
|  98 |    607.807881 |    590.593995 | Birgit Lang                                                                                                                                                        |
|  99 |    354.084351 |    724.457110 | C. Camilo Julián-Caballero                                                                                                                                         |
| 100 |     47.761115 |    244.770781 | Lukas Panzarin                                                                                                                                                     |
| 101 |    849.863153 |     22.497216 | Andrew A. Farke                                                                                                                                                    |
| 102 |    885.057012 |    107.898510 | Gareth Monger                                                                                                                                                      |
| 103 |      9.835324 |    607.500734 | NA                                                                                                                                                                 |
| 104 |    324.305350 |    354.013040 | Scott Hartman                                                                                                                                                      |
| 105 |    642.592175 |    428.480007 | C. Abraczinskas                                                                                                                                                    |
| 106 |    448.273864 |    205.395121 | Matt Crook                                                                                                                                                         |
| 107 |    234.534387 |    789.406624 | Tasman Dixon                                                                                                                                                       |
| 108 |     39.979325 |    339.418174 | Gabriela Palomo-Munoz                                                                                                                                              |
| 109 |    620.507055 |    648.207606 | Yan Wong (vectorization) from 1873 illustration                                                                                                                    |
| 110 |    508.934690 |     16.011932 | Stacy Spensley (Modified)                                                                                                                                          |
| 111 |     38.699723 |     19.810046 | FunkMonk                                                                                                                                                           |
| 112 |    508.340738 |    344.028688 | Margot Michaud                                                                                                                                                     |
| 113 |    881.023849 |    422.957139 | Margot Michaud                                                                                                                                                     |
| 114 |    395.421108 |    547.860572 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                    |
| 115 |     33.356387 |    368.155803 | Smokeybjb, vectorized by Zimices                                                                                                                                   |
| 116 |     44.256037 |    695.412168 | Michael Scroggie                                                                                                                                                   |
| 117 |    214.812633 |     35.418803 | Jagged Fang Designs                                                                                                                                                |
| 118 |    365.082057 |    483.975889 | Matt Crook                                                                                                                                                         |
| 119 |    185.604601 |    327.683624 | Matt Crook                                                                                                                                                         |
| 120 |    898.851047 |    181.427661 | Zimices                                                                                                                                                            |
| 121 |    186.099555 |    654.884214 | Matt Crook                                                                                                                                                         |
| 122 |    512.284071 |    186.355658 | Zimices                                                                                                                                                            |
| 123 |    974.508438 |    297.479894 | T. Michael Keesey                                                                                                                                                  |
| 124 |     61.919670 |    574.714418 | Tasman Dixon                                                                                                                                                       |
| 125 |     36.885304 |    172.869055 | Scott Hartman                                                                                                                                                      |
| 126 |    446.209769 |    288.351614 | C. Camilo Julián-Caballero                                                                                                                                         |
| 127 |    564.337396 |    107.516838 | Matt Crook                                                                                                                                                         |
| 128 |     63.188656 |    323.991287 | Margot Michaud                                                                                                                                                     |
| 129 |     11.599493 |    219.421165 | Birgit Lang                                                                                                                                                        |
| 130 |   1011.848175 |    422.250681 | T. Michael Keesey                                                                                                                                                  |
| 131 |    275.713134 |    329.721654 | Scott Hartman                                                                                                                                                      |
| 132 |    578.596671 |    479.446449 | Margot Michaud                                                                                                                                                     |
| 133 |    637.775993 |    461.294045 | Chris huh                                                                                                                                                          |
| 134 |     71.019884 |    707.878821 | Zimices                                                                                                                                                            |
| 135 |    116.448857 |    125.389621 | Gabriela Palomo-Munoz                                                                                                                                              |
| 136 |    241.139321 |    340.437755 | FunkMonk                                                                                                                                                           |
| 137 |     47.123095 |    307.636299 | Jesús Gómez, vectorized by Zimices                                                                                                                                 |
| 138 |    652.870116 |    515.049389 | Zimices                                                                                                                                                            |
| 139 |    904.786934 |    156.069947 | Matt Martyniuk                                                                                                                                                     |
| 140 |    958.003925 |    199.956745 | Jagged Fang Designs                                                                                                                                                |
| 141 |    119.655564 |    670.670879 | Andrew R. Gehrke                                                                                                                                                   |
| 142 |    674.771695 |    576.239828 | NA                                                                                                                                                                 |
| 143 |    340.029540 |    374.365218 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                      |
| 144 |    907.853204 |     27.196008 | T. Michael Keesey                                                                                                                                                  |
| 145 |    801.950426 |    728.910996 | Ferran Sayol                                                                                                                                                       |
| 146 |    563.172299 |    472.711433 | Tasman Dixon                                                                                                                                                       |
| 147 |    740.023886 |     16.724145 | SauropodomorphMonarch                                                                                                                                              |
| 148 |    681.767168 |    256.237571 | Armin Reindl                                                                                                                                                       |
| 149 |    222.517635 |    416.464191 | Ferran Sayol                                                                                                                                                       |
| 150 |    519.863765 |    578.633821 | Matt Crook                                                                                                                                                         |
| 151 |    204.958363 |    500.543115 | Mathilde Cordellier                                                                                                                                                |
| 152 |    722.092990 |     87.172595 | Andy Wilson                                                                                                                                                        |
| 153 |    489.565985 |    590.130119 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 154 |    116.444455 |    571.685556 | Zimices                                                                                                                                                            |
| 155 |    998.228642 |    337.664775 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                         |
| 156 |     88.746712 |    682.564879 | Gareth Monger                                                                                                                                                      |
| 157 |    848.339672 |    431.903223 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                  |
| 158 |    313.196467 |    316.155488 | Markus A. Grohme                                                                                                                                                   |
| 159 |    306.762934 |    512.228690 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                      |
| 160 |    215.026993 |    529.260494 | Andreas Preuss / marauder                                                                                                                                          |
| 161 |    755.070671 |    556.045726 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                             |
| 162 |    727.306194 |    218.665647 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                  |
| 163 |    331.574420 |    691.911994 | Margot Michaud                                                                                                                                                     |
| 164 |    674.941370 |    128.965168 | Dean Schnabel                                                                                                                                                      |
| 165 |   1007.358588 |    307.727668 | Manabu Bessho-Uehara                                                                                                                                               |
| 166 |   1009.706965 |    191.954236 | Aadx                                                                                                                                                               |
| 167 |    367.600321 |    177.529958 | Antonov (vectorized by T. Michael Keesey)                                                                                                                          |
| 168 |    622.594161 |    205.420541 | Kamil S. Jaron                                                                                                                                                     |
| 169 |    144.248841 |    657.498438 | S.Martini                                                                                                                                                          |
| 170 |    960.388864 |     13.773492 | Scott Hartman                                                                                                                                                      |
| 171 |    646.227428 |    176.449007 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                      |
| 172 |    620.410907 |     81.793862 | Matt Crook                                                                                                                                                         |
| 173 |    210.154515 |    151.664831 | Meliponicultor Itaymbere                                                                                                                                           |
| 174 |    349.782628 |    547.821417 | Mark Miller                                                                                                                                                        |
| 175 |    175.728580 |    622.741091 | Jagged Fang Designs                                                                                                                                                |
| 176 |     19.638615 |    535.555844 | NA                                                                                                                                                                 |
| 177 |    596.598312 |    436.343251 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 178 |    954.355760 |    751.928352 | Christoph Schomburg                                                                                                                                                |
| 179 |    225.865618 |    171.566000 | Margot Michaud                                                                                                                                                     |
| 180 |    422.428922 |     42.096098 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 181 |    366.560192 |    105.795429 | Chris huh                                                                                                                                                          |
| 182 |    829.042656 |    536.229944 | Lisa Byrne                                                                                                                                                         |
| 183 |    175.674724 |    224.801409 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                 |
| 184 |    155.226889 |    605.446003 | Zimices                                                                                                                                                            |
| 185 |    824.938665 |    579.324564 | Gabriela Palomo-Munoz                                                                                                                                              |
| 186 |    935.778151 |    219.076317 | Jagged Fang Designs                                                                                                                                                |
| 187 |    339.066830 |     25.673338 | Zimices                                                                                                                                                            |
| 188 |     85.630281 |    130.696967 | Andy Wilson                                                                                                                                                        |
| 189 |     75.444718 |    381.301099 | Mathew Wedel                                                                                                                                                       |
| 190 |    141.121405 |    262.261708 | Ingo Braasch                                                                                                                                                       |
| 191 |    108.468270 |    534.358896 | Steven Traver                                                                                                                                                      |
| 192 |   1007.813482 |    111.344121 | Steven Traver                                                                                                                                                      |
| 193 |    923.238316 |    594.284118 | Caleb M. Brown                                                                                                                                                     |
| 194 |    432.120268 |    479.151832 | Matt Crook                                                                                                                                                         |
| 195 |    842.597809 |    323.655109 | Dmitry Bogdanov                                                                                                                                                    |
| 196 |    311.570820 |    738.575050 | Matt Crook                                                                                                                                                         |
| 197 |    604.266964 |    612.575044 | Zimices                                                                                                                                                            |
| 198 |    868.725681 |    234.234913 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                     |
| 199 |    214.009469 |    547.564813 | Scott Hartman (vectorized by William Gearty)                                                                                                                       |
| 200 |    395.622736 |    374.881506 | Margot Michaud                                                                                                                                                     |
| 201 |     94.932892 |    638.907296 | FunkMonk                                                                                                                                                           |
| 202 |    869.975307 |    554.585746 | NA                                                                                                                                                                 |
| 203 |    704.744136 |    649.576253 | Gareth Monger                                                                                                                                                      |
| 204 |    991.796837 |    766.561071 | Maxime Dahirel                                                                                                                                                     |
| 205 |    367.883922 |    699.151625 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 206 |    202.729842 |    618.553991 | Chris huh                                                                                                                                                          |
| 207 |    230.869531 |     47.101046 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 208 |    268.779614 |    764.988384 | Andrew A. Farke                                                                                                                                                    |
| 209 |    522.463387 |    757.110605 | Anna Willoughby                                                                                                                                                    |
| 210 |    146.317402 |    570.093617 | Margot Michaud                                                                                                                                                     |
| 211 |    506.994164 |    632.963808 | Collin Gross                                                                                                                                                       |
| 212 |    831.582633 |    367.598979 | Matt Martyniuk                                                                                                                                                     |
| 213 |    419.027058 |    148.497469 | NA                                                                                                                                                                 |
| 214 |    546.201555 |    502.412523 | Birgit Lang                                                                                                                                                        |
| 215 |    316.501179 |     13.624426 | M Kolmann                                                                                                                                                          |
| 216 |     39.521971 |    672.258008 | Dean Schnabel                                                                                                                                                      |
| 217 |    571.093707 |    299.224652 | Ludwik Gasiorowski                                                                                                                                                 |
| 218 |   1008.172288 |     33.705001 | Markus A. Grohme                                                                                                                                                   |
| 219 |   1002.592381 |     82.296695 | Elisabeth Östman                                                                                                                                                   |
| 220 |    613.569600 |     53.650434 | Chloé Schmidt                                                                                                                                                      |
| 221 |    669.529824 |    151.629905 | Gabriela Palomo-Munoz                                                                                                                                              |
| 222 |    246.214485 |    549.401169 | Scott Hartman                                                                                                                                                      |
| 223 |    103.816541 |     13.486667 | Tambja (vectorized by T. Michael Keesey)                                                                                                                           |
| 224 |    612.253016 |    381.264577 | Benjamin Monod-Broca                                                                                                                                               |
| 225 |    794.043924 |    506.735206 | Gareth Monger                                                                                                                                                      |
| 226 |    886.560503 |     26.356573 | T. Michael Keesey                                                                                                                                                  |
| 227 |    703.387488 |    595.482102 | Ferran Sayol                                                                                                                                                       |
| 228 |    878.183559 |    146.094045 | Matt Martyniuk                                                                                                                                                     |
| 229 |    558.723784 |    428.378616 | Margot Michaud                                                                                                                                                     |
| 230 |    937.967714 |     99.320020 | Steven Coombs                                                                                                                                                      |
| 231 |    261.251287 |     17.788880 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                             |
| 232 |    846.903274 |    706.224729 | Jaime Headden                                                                                                                                                      |
| 233 |    426.742335 |      9.357394 | Benchill                                                                                                                                                           |
| 234 |    177.381145 |    254.597237 | Dave Angelini                                                                                                                                                      |
| 235 |     20.233943 |     41.370916 | Matt Martyniuk                                                                                                                                                     |
| 236 |    689.791367 |    332.387933 | Markus A. Grohme                                                                                                                                                   |
| 237 |     13.712354 |    291.681916 | NA                                                                                                                                                                 |
| 238 |    907.421696 |    731.729945 | Konsta Happonen                                                                                                                                                    |
| 239 |    737.685420 |    428.600533 | Chris huh                                                                                                                                                          |
| 240 |     99.806208 |    651.975075 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 241 |    540.294806 |    540.556289 | Gareth Monger                                                                                                                                                      |
| 242 |    134.237192 |    105.202122 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 243 |    450.401749 |    445.593082 | NA                                                                                                                                                                 |
| 244 |    696.577410 |    342.837168 | Chris huh                                                                                                                                                          |
| 245 |    727.804437 |    461.511012 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                   |
| 246 |     21.728515 |    705.164941 | Jaime Headden                                                                                                                                                      |
| 247 |    465.117260 |    449.020086 | T. Michael Keesey                                                                                                                                                  |
| 248 |    707.435816 |    724.316817 | Zimices                                                                                                                                                            |
| 249 |    295.421662 |    361.928686 | Scott Hartman                                                                                                                                                      |
| 250 |    428.663080 |    777.842118 | Gopal Murali                                                                                                                                                       |
| 251 |    966.192062 |    216.438310 | Margot Michaud                                                                                                                                                     |
| 252 |    799.345014 |     14.124460 | B. Duygu Özpolat                                                                                                                                                   |
| 253 |    355.260623 |     13.771161 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                   |
| 254 |    553.083763 |     26.084101 | Gabriela Palomo-Munoz                                                                                                                                              |
| 255 |     63.147990 |    395.124685 | Jagged Fang Designs                                                                                                                                                |
| 256 |    718.220406 |    409.494528 |                                                                                                                                                                    |
| 257 |    976.753337 |    103.440618 | Rebecca Groom                                                                                                                                                      |
| 258 |    492.133933 |    131.541165 | Zimices                                                                                                                                                            |
| 259 |    641.295206 |    582.175440 | Michelle Site                                                                                                                                                      |
| 260 |    182.466436 |    127.913890 | Scott Hartman                                                                                                                                                      |
| 261 |    744.427308 |    443.671691 | Margot Michaud                                                                                                                                                     |
| 262 |    105.151253 |    301.383669 | Chris huh                                                                                                                                                          |
| 263 |    159.290923 |    341.086991 | Scott Hartman                                                                                                                                                      |
| 264 |    914.596526 |    499.017280 | Chris huh                                                                                                                                                          |
| 265 |    333.735025 |    287.885541 | Matt Crook                                                                                                                                                         |
| 266 |   1013.607518 |    670.618437 | SecretJellyMan - from Mason McNair                                                                                                                                 |
| 267 |    581.654296 |    707.704436 | Ferran Sayol                                                                                                                                                       |
| 268 |    789.896595 |    567.080597 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 269 |    889.988589 |     50.682203 | Scott Hartman                                                                                                                                                      |
| 270 |     28.474586 |    387.858489 | Jagged Fang Designs                                                                                                                                                |
| 271 |    679.052704 |    410.847927 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 272 |    457.929393 |    777.050464 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                           |
| 273 |    309.898920 |      7.549022 | Scott Hartman                                                                                                                                                      |
| 274 |    276.745328 |    130.192411 | Lukasiniho                                                                                                                                                         |
| 275 |    633.019158 |    405.568396 | Zimices                                                                                                                                                            |
| 276 |   1006.140457 |    232.942285 | Steven Traver                                                                                                                                                      |
| 277 |      8.523793 |    454.441651 | Bruno C. Vellutini                                                                                                                                                 |
| 278 |    432.101357 |    157.978352 | Nobu Tamura                                                                                                                                                        |
| 279 |    681.525690 |    302.370915 | Gareth Monger                                                                                                                                                      |
| 280 |    493.786825 |    362.852629 | Gabriela Palomo-Munoz                                                                                                                                              |
| 281 |    857.618179 |    677.158873 | Anilocra (vectorization by Yan Wong)                                                                                                                               |
| 282 |    131.385713 |    237.499988 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 283 |    324.596208 |    334.877535 | Jennifer Trimble                                                                                                                                                   |
| 284 |    385.914176 |    405.912639 | Alex Slavenko                                                                                                                                                      |
| 285 |    835.725149 |    396.220073 | Walter Vladimir                                                                                                                                                    |
| 286 |    754.882284 |    267.157875 | C. Camilo Julián-Caballero                                                                                                                                         |
| 287 |    939.483553 |    550.733912 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 288 |     37.086385 |      8.672414 | Margot Michaud                                                                                                                                                     |
| 289 |    608.943977 |    363.432804 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                              |
| 290 |    971.748001 |    189.012829 | Andrew A. Farke                                                                                                                                                    |
| 291 |    832.353430 |    614.124544 | Scott Hartman                                                                                                                                                      |
| 292 |    293.794630 |    536.983424 | Sean McCann                                                                                                                                                        |
| 293 |    471.898798 |    344.680124 | Jaime Headden                                                                                                                                                      |
| 294 |    431.804783 |    547.415331 | Matt Crook                                                                                                                                                         |
| 295 |    647.512394 |    299.127818 | Ferran Sayol                                                                                                                                                       |
| 296 |    344.694946 |    567.514567 | Matt Crook                                                                                                                                                         |
| 297 |    884.091629 |    528.416158 | Mathew Wedel                                                                                                                                                       |
| 298 |    631.486061 |    251.765143 | Birgit Lang                                                                                                                                                        |
| 299 |    784.632255 |    550.166683 | C. Camilo Julián-Caballero                                                                                                                                         |
| 300 |     35.256370 |    291.036440 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                      |
| 301 |    595.630508 |    766.078879 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 302 |    985.109875 |     40.177738 | Arthur S. Brum                                                                                                                                                     |
| 303 |     17.740355 |    730.592155 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                      |
| 304 |    325.131028 |    564.316426 | Jagged Fang Designs                                                                                                                                                |
| 305 |    363.497934 |    126.477839 | Ferran Sayol                                                                                                                                                       |
| 306 |    693.088687 |    757.469394 | Matt Crook                                                                                                                                                         |
| 307 |   1008.724848 |     22.934187 | Maija Karala                                                                                                                                                       |
| 308 |    793.429132 |    525.534092 | Scott Hartman                                                                                                                                                      |
| 309 |    702.102144 |    261.069092 | Gareth Monger                                                                                                                                                      |
| 310 |    527.822707 |    550.111396 | Tracy A. Heath                                                                                                                                                     |
| 311 |    448.704211 |    131.237194 | Andrew A. Farke                                                                                                                                                    |
| 312 |    550.728103 |      9.273981 | NA                                                                                                                                                                 |
| 313 |    913.815203 |    337.902592 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                       |
| 314 |    545.788630 |    353.027945 | Jagged Fang Designs                                                                                                                                                |
| 315 |     18.003521 |    347.668375 | Maija Karala                                                                                                                                                       |
| 316 |    868.842655 |    302.039448 | NA                                                                                                                                                                 |
| 317 |    642.778086 |    533.129513 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 318 |    907.287634 |    610.555129 | Zimices                                                                                                                                                            |
| 319 |    495.835085 |    232.698662 | Ignacio Contreras                                                                                                                                                  |
| 320 |    447.449643 |    691.248804 | Steven Traver                                                                                                                                                      |
| 321 |    103.575964 |    440.923606 | Birgit Lang                                                                                                                                                        |
| 322 |    194.862181 |     11.314132 | T. Michael Keesey                                                                                                                                                  |
| 323 |    752.802112 |    539.900394 | www.studiospectre.com                                                                                                                                              |
| 324 |    449.217662 |    496.857453 | T. Michael Keesey                                                                                                                                                  |
| 325 |    487.248299 |    753.015996 | Matt Crook                                                                                                                                                         |
| 326 |    968.862777 |    334.566759 | Chris huh                                                                                                                                                          |
| 327 |    957.909526 |    668.169755 | Steven Traver                                                                                                                                                      |
| 328 |    119.855879 |    712.139887 | Caleb M. Brown                                                                                                                                                     |
| 329 |    942.049353 |    423.299881 | Gareth Monger                                                                                                                                                      |
| 330 |    670.267453 |    344.429216 | Jagged Fang Designs                                                                                                                                                |
| 331 |    257.907931 |    687.541551 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                      |
| 332 |     35.012034 |    605.972252 | NA                                                                                                                                                                 |
| 333 |    602.698461 |    641.136924 | Matt Crook                                                                                                                                                         |
| 334 |    520.752403 |    426.702061 | Maija Karala                                                                                                                                                       |
| 335 |    250.350072 |    142.979083 | Steven Traver                                                                                                                                                      |
| 336 |    768.934440 |    624.447484 | Scott Reid                                                                                                                                                         |
| 337 |    644.765621 |    155.174819 | T. Michael Keesey                                                                                                                                                  |
| 338 |    497.376492 |    556.236874 | Jagged Fang Designs                                                                                                                                                |
| 339 |    265.552685 |     45.024210 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 340 |    387.073758 |    391.522503 | Xavier Giroux-Bougard                                                                                                                                              |
| 341 |    714.824557 |     36.276237 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 342 |    381.904437 |    627.050530 | Matt Crook                                                                                                                                                         |
| 343 |    183.644119 |    152.710414 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                         |
| 344 |    627.707857 |    268.182127 | Chuanixn Yu                                                                                                                                                        |
| 345 |    175.678673 |    388.582996 | Sharon Wegner-Larsen                                                                                                                                               |
| 346 |    993.546677 |    404.498594 | Iain Reid                                                                                                                                                          |
| 347 |    212.985002 |    124.805293 | Emily Willoughby                                                                                                                                                   |
| 348 |    684.295905 |    100.723465 | Katie S. Collins                                                                                                                                                   |
| 349 |    814.458200 |    496.640693 | Birgit Lang                                                                                                                                                        |
| 350 |    917.947882 |    469.632554 | Yan Wong                                                                                                                                                           |
| 351 |    288.265124 |    679.006209 | Jagged Fang Designs                                                                                                                                                |
| 352 |    240.269859 |    352.698803 | Tasman Dixon                                                                                                                                                       |
| 353 |    369.895037 |    379.310920 | Matt Crook                                                                                                                                                         |
| 354 |    236.120400 |    774.619535 | Chris huh                                                                                                                                                          |
| 355 |    834.656651 |    244.576169 | Zimices                                                                                                                                                            |
| 356 |    144.370262 |    557.342435 | Markus A. Grohme                                                                                                                                                   |
| 357 |    155.630329 |    669.171805 | Markus A. Grohme                                                                                                                                                   |
| 358 |    611.196867 |    673.519140 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                              |
| 359 |    773.843976 |    733.817228 | Steven Traver                                                                                                                                                      |
| 360 |    700.146711 |    794.177817 | Markus A. Grohme                                                                                                                                                   |
| 361 |    338.417328 |    531.285187 | Gareth Monger                                                                                                                                                      |
| 362 |    919.191954 |    118.923822 | Milton Tan                                                                                                                                                         |
| 363 |    539.727594 |    130.620461 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                   |
| 364 |     96.919015 |    238.852609 | NA                                                                                                                                                                 |
| 365 |    420.796502 |    645.135934 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 366 |    880.911993 |    573.009106 | Xavier Giroux-Bougard                                                                                                                                              |
| 367 |    920.101070 |    302.226133 | Jay Matternes, vectorized by Zimices                                                                                                                               |
| 368 |    764.539983 |    427.334007 | L. Shyamal                                                                                                                                                         |
| 369 |    124.522958 |    432.682330 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 370 |     22.209567 |    185.856503 | Caleb M. Brown                                                                                                                                                     |
| 371 |    570.250632 |    598.085618 | T. Michael Keesey                                                                                                                                                  |
| 372 |    508.458610 |    612.938125 | Zimices                                                                                                                                                            |
| 373 |    318.397762 |    796.294870 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 374 |    889.066368 |     94.475515 | Gabriela Palomo-Munoz                                                                                                                                              |
| 375 |    275.885292 |    568.972940 | Steven Traver                                                                                                                                                      |
| 376 |    663.495365 |    475.700478 | Geoff Shaw                                                                                                                                                         |
| 377 |    229.593450 |    677.927769 | Tasman Dixon                                                                                                                                                       |
| 378 |    385.667412 |    742.725645 | Jaime Headden                                                                                                                                                      |
| 379 |    541.278732 |    711.062228 | M Kolmann                                                                                                                                                          |
| 380 |     98.971475 |    255.282284 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 381 |    116.135349 |    793.033079 | Scott Hartman                                                                                                                                                      |
| 382 |    592.253847 |    187.232386 | Steven Traver                                                                                                                                                      |
| 383 |    996.746751 |    210.140351 | Markus A. Grohme                                                                                                                                                   |
| 384 |     82.157741 |    229.515600 | C. Camilo Julián-Caballero                                                                                                                                         |
| 385 |    793.382379 |    774.343981 | Zimices                                                                                                                                                            |
| 386 |    481.606889 |    382.670430 | Rene Martin                                                                                                                                                        |
| 387 |    717.562571 |    565.180073 | Rene Martin                                                                                                                                                        |
| 388 |    146.435200 |    208.154782 | Anna Willoughby                                                                                                                                                    |
| 389 |    477.396902 |    409.066166 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                   |
| 390 |    736.497503 |     61.701642 | Gareth Monger                                                                                                                                                      |
| 391 |    596.304045 |    465.157548 | Zimices                                                                                                                                                            |
| 392 |    861.388586 |    655.065478 | NA                                                                                                                                                                 |
| 393 |    648.432228 |    278.452927 | Margot Michaud                                                                                                                                                     |
| 394 |    627.159047 |    292.103107 | Erika Schumacher                                                                                                                                                   |
| 395 |     77.114311 |    290.546561 | Margot Michaud                                                                                                                                                     |
| 396 |    182.803760 |    208.646907 | Dmitry Bogdanov                                                                                                                                                    |
| 397 |    108.847906 |    558.177283 | Margot Michaud                                                                                                                                                     |
| 398 |    202.170573 |    403.005854 | Henry Lydecker                                                                                                                                                     |
| 399 |    917.238402 |    422.957529 | Steven Traver                                                                                                                                                      |
| 400 |   1005.791134 |    287.217975 | Gareth Monger                                                                                                                                                      |
| 401 |    653.812354 |    727.833678 | Margot Michaud                                                                                                                                                     |
| 402 |    345.676492 |    204.118631 | Gabriela Palomo-Munoz                                                                                                                                              |
| 403 |    324.988913 |    305.290170 | Collin Gross                                                                                                                                                       |
| 404 |    662.577488 |    548.900779 | Jonathan Wells                                                                                                                                                     |
| 405 |    473.786725 |    397.862354 | Markus A. Grohme                                                                                                                                                   |
| 406 |     32.075952 |    397.445557 | Scott Hartman                                                                                                                                                      |
| 407 |     59.348505 |    359.829505 | Collin Gross                                                                                                                                                       |
| 408 |     57.657575 |    171.020507 | Matt Crook                                                                                                                                                         |
| 409 |     90.602246 |    334.380439 | Tasman Dixon                                                                                                                                                       |
| 410 |    389.105485 |    678.427634 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                 |
| 411 |    901.851641 |    650.226528 | Ferran Sayol                                                                                                                                                       |
| 412 |    332.258097 |    257.208898 | Christoph Schomburg                                                                                                                                                |
| 413 |    905.375639 |    515.551721 | Zimices                                                                                                                                                            |
| 414 |    720.878375 |    634.298061 | Steven Haddock • Jellywatch.org                                                                                                                                    |
| 415 |    628.917615 |     92.690551 | Tasman Dixon                                                                                                                                                       |
| 416 |     15.201410 |    489.528597 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 417 |    365.951663 |     66.749975 | Chris huh                                                                                                                                                          |
| 418 |    527.484083 |    494.294440 | NA                                                                                                                                                                 |
| 419 |     69.027817 |    565.954499 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 420 |    278.935060 |    149.159771 | Zimices                                                                                                                                                            |
| 421 |    713.192107 |    417.643009 | Mathew Wedel                                                                                                                                                       |
| 422 |    262.464968 |     92.160286 | Andy Wilson                                                                                                                                                        |
| 423 |    416.110818 |    748.985764 | T. Michael Keesey                                                                                                                                                  |
| 424 |    383.709864 |    525.078778 | Milton Tan                                                                                                                                                         |
| 425 |     96.395424 |    247.300360 | Siobhon Egan                                                                                                                                                       |
| 426 |    606.885482 |    291.081671 | Matt Crook                                                                                                                                                         |
| 427 |    600.093523 |    235.417957 | Jagged Fang Designs                                                                                                                                                |
| 428 |     34.508623 |    634.914518 | Gareth Monger                                                                                                                                                      |
| 429 |     29.951691 |    228.155733 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 430 |    770.103147 |    522.354263 | Ferran Sayol                                                                                                                                                       |
| 431 |    337.656612 |    486.899493 | Gabriela Palomo-Munoz                                                                                                                                              |
| 432 |     16.241362 |     78.099561 | Steven Traver                                                                                                                                                      |
| 433 |   1007.058710 |    328.504513 | Smokeybjb                                                                                                                                                          |
| 434 |    761.338508 |    355.242594 | Jessica Rick                                                                                                                                                       |
| 435 |    207.654549 |    457.171104 | Gareth Monger                                                                                                                                                      |
| 436 |    113.796406 |    523.732682 | Alex Slavenko                                                                                                                                                      |
| 437 |    644.796064 |    499.699115 | Ingo Braasch                                                                                                                                                       |
| 438 |    757.038504 |     20.145116 | Matt Crook                                                                                                                                                         |
| 439 |    570.059749 |    760.014533 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 440 |    564.366821 |    683.496118 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 441 |    716.246999 |    473.227198 | Margot Michaud                                                                                                                                                     |
| 442 |    607.057529 |    111.747171 | NA                                                                                                                                                                 |
| 443 |    113.673361 |    290.237486 | Collin Gross                                                                                                                                                       |
| 444 |    784.716772 |    299.130225 | Smokeybjb                                                                                                                                                          |
| 445 |    577.600854 |      6.738651 | Xavier Giroux-Bougard                                                                                                                                              |
| 446 |    801.990859 |    360.861011 | Shyamal                                                                                                                                                            |
| 447 |    820.065780 |    718.292256 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 448 |    376.316912 |    148.716341 | Scott Hartman                                                                                                                                                      |
| 449 |    511.364585 |    313.463196 | NA                                                                                                                                                                 |
| 450 |    972.935995 |     27.465223 | Iain Reid                                                                                                                                                          |
| 451 |    221.964980 |    185.309175 | Jagged Fang Designs                                                                                                                                                |
| 452 |    683.708300 |     68.646847 | Gareth Monger                                                                                                                                                      |
| 453 |    890.837943 |    287.668738 | Tasman Dixon                                                                                                                                                       |
| 454 |    439.792219 |    762.452029 | Jagged Fang Designs                                                                                                                                                |
| 455 |    801.798958 |    750.209777 | Scott Hartman                                                                                                                                                      |
| 456 |    799.118445 |    791.703431 | Markus A. Grohme                                                                                                                                                   |
| 457 |    646.078333 |    192.290137 | Zimices                                                                                                                                                            |
| 458 |     51.172647 |    193.325270 | Shyamal                                                                                                                                                            |
| 459 |    983.731101 |    750.786429 | Michael P. Taylor                                                                                                                                                  |
| 460 |    896.133767 |    585.242717 | T. Michael Keesey                                                                                                                                                  |
| 461 |     87.636311 |    580.355926 | Scott Hartman                                                                                                                                                      |
| 462 |    378.938287 |    416.741475 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                        |
| 463 |    930.550778 |    105.957817 | Ignacio Contreras                                                                                                                                                  |
| 464 |     71.137574 |     21.824219 | Tyler Greenfield and Scott Hartman                                                                                                                                 |
| 465 |    644.159914 |     67.121375 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                           |
| 466 |    827.482877 |    349.470318 | Tasman Dixon                                                                                                                                                       |
| 467 |    438.959320 |    173.806603 | Mathieu Basille                                                                                                                                                    |
| 468 |    200.444803 |      5.333954 | Markus A. Grohme                                                                                                                                                   |
| 469 |    510.676191 |    651.679750 | Jaime Headden, modified by T. Michael Keesey                                                                                                                       |
| 470 |    890.666925 |    160.941571 | Mattia Menchetti / Yan Wong                                                                                                                                        |
| 471 |    424.463275 |    574.632879 | Scott Hartman                                                                                                                                                      |
| 472 |    521.993224 |    766.806116 | Zachary Quigley                                                                                                                                                    |
| 473 |    884.288684 |    673.689655 | Sarah Werning                                                                                                                                                      |
| 474 |    632.200230 |     43.383990 | Beth Reinke                                                                                                                                                        |
| 475 |    269.753657 |    781.282353 | Mark Miller                                                                                                                                                        |
| 476 |    390.283243 |     14.330234 | Tasman Dixon                                                                                                                                                       |
| 477 |    150.844537 |    321.723328 | Thibaut Brunet                                                                                                                                                     |
| 478 |    337.341755 |    417.598740 | Emily Willoughby                                                                                                                                                   |
| 479 |     22.474163 |    259.702789 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 480 |    905.919059 |    709.933114 | Lafage                                                                                                                                                             |
| 481 |    120.980832 |    148.758620 | Chris huh                                                                                                                                                          |
| 482 |    290.760674 |    735.261493 | Matt Crook                                                                                                                                                         |
| 483 |    417.389731 |    229.955402 | Sarah Werning                                                                                                                                                      |
| 484 |    924.015791 |    160.671348 | Alex Slavenko                                                                                                                                                      |
| 485 |    387.448167 |    796.434195 | Blanco et al., 2014, vectorized by Zimices                                                                                                                         |
| 486 |    849.743437 |      6.307906 | Mette Aumala                                                                                                                                                       |
| 487 |    464.214977 |    370.619763 | Sarah Werning                                                                                                                                                      |
| 488 |     27.317589 |    319.423823 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                    |
| 489 |    625.852696 |      6.809079 | Thibaut Brunet                                                                                                                                                     |
| 490 |    601.363720 |    124.948009 | Ignacio Contreras                                                                                                                                                  |
| 491 |    229.289355 |    330.851492 | Andy Wilson                                                                                                                                                        |
| 492 |    406.848179 |    687.760398 | Scott Hartman                                                                                                                                                      |
| 493 |    358.846730 |    508.443130 | Noah Schlottman                                                                                                                                                    |
| 494 |    837.374171 |    425.698904 | T. Michael Keesey                                                                                                                                                  |
| 495 |    651.201716 |    368.984046 | Scott Hartman                                                                                                                                                      |
| 496 |    361.854665 |    588.420921 | Christoph Schomburg                                                                                                                                                |
| 497 |    831.789825 |    600.074936 | Chris huh                                                                                                                                                          |
| 498 |    702.545503 |    678.960943 | Birgit Lang                                                                                                                                                        |
| 499 |    189.187283 |    706.971309 | Steven Traver                                                                                                                                                      |
| 500 |    636.329074 |    285.860974 | Siobhon Egan                                                                                                                                                       |
| 501 |    826.484956 |    527.777178 | Henry Lydecker                                                                                                                                                     |
| 502 |    957.535428 |    639.902220 | T. Michael Keesey                                                                                                                                                  |
| 503 |    524.499783 |    384.688728 | Jagged Fang Designs                                                                                                                                                |
| 504 |    493.584376 |    571.185187 | Alex Slavenko                                                                                                                                                      |
| 505 |    686.871109 |      8.505166 | Scott Hartman                                                                                                                                                      |
| 506 |    988.310963 |    634.852226 | Rebecca Groom                                                                                                                                                      |
| 507 |   1010.022016 |    716.083273 | Joanna Wolfe                                                                                                                                                       |
| 508 |    347.839327 |     50.186461 | Rene Martin                                                                                                                                                        |
| 509 |    435.323935 |    430.240740 | Myriam\_Ramirez                                                                                                                                                    |
| 510 |    232.782012 |    157.973900 | Margot Michaud                                                                                                                                                     |
| 511 |    295.541934 |    287.232651 | Zimices                                                                                                                                                            |
| 512 |    927.710318 |    573.266280 | Agnello Picorelli                                                                                                                                                  |
| 513 |     22.815250 |    196.692923 | Neil Kelley                                                                                                                                                        |

    #> Your tweet has been posted!
