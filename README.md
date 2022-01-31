
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
#> Warning in register(): Can't find generic `scale_type` in package ggplot2 to
#> register S3 method.
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

Margot Michaud, James R. Spotila and Ray Chatterji, Tasman Dixon, Kamil
S. Jaron, Ingo Braasch, Scott Hartman, Steven Traver, Armin Reindl,
Mathieu Pélissié, Iain Reid, Sean McCann, Noah Schlottman, photo by
Casey Dunn, Jagged Fang Designs, Zimices, Mathew Wedel, Michael
Scroggie, Chloé Schmidt, Francesco Veronesi (vectorized by T. Michael
Keesey), Felix Vaux, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Nobu Tamura (modified by T. Michael Keesey), Alexandre Vong, Gareth
Monger, Beth Reinke, Maija Karala, Chase Brownstein, T. Michael Keesey,
Nobu Tamura, vectorized by Zimices, Birgit Lang, Kanchi Nanjo, Bennet
McComish, photo by Hans Hillewaert, Agnello Picorelli, Dean Schnabel,
Joe Schneid (vectorized by T. Michael Keesey), Griensteidl and T.
Michael Keesey, Amanda Katzer, Rene Martin, T. Michael Keesey (after
Mivart), Cesar Julian, Ghedoghedo, Richard Ruggiero, vectorized by
Zimices, Matt Martyniuk, Dexter R. Mardis, Jaime Headden, Chris huh, C.
Camilo Julián-Caballero, Michael “FunkMonk” B. H. (vectorized by T.
Michael Keesey), Cristopher Silva, Markus A. Grohme, Shyamal, Collin
Gross, Nobu Tamura (vectorized by T. Michael Keesey), Obsidian Soul
(vectorized by T. Michael Keesey), Melissa Broussard, Pearson Scott
Foresman (vectorized by T. Michael Keesey), Matt Dempsey, Mattia
Menchetti / Yan Wong, Sarah Werning, Don Armstrong, James Neenan, Inessa
Voet, Anthony Caravaggi, Roberto Díaz Sibaja, Mo Hassan, Michelle Site,
Andrew A. Farke, Jennifer Trimble, Tyler Greenfield, Tracy A. Heath,
Thea Boodhoo (photograph) and T. Michael Keesey (vectorization),
Francesca Belem Lopes Palmeira, Gabriela Palomo-Munoz,
\<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T.
Michael Keesey), Noah Schlottman, photo from Moorea Biocode, Moussa
Direct Ltd. (photography) and T. Michael Keesey (vectorization), Matt
Crook, S.Martini, Ferran Sayol, xgirouxb, Natasha Vitek, Tony Ayling
(vectorized by Milton Tan), Nicolas Huet le Jeune and Jean-Gabriel
Prêtre (vectorized by T. Michael Keesey), Tarique Sani (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, T. Michael
Keesey (after Masteraah), Nina Skinner, Rebecca Groom, Neil Kelley, Kai
R. Caspar, Darren Naish (vectorized by T. Michael Keesey), T. Michael
Keesey (after Ponomarenko), Noah Schlottman, photo by Reinhard Jahn,
Noah Schlottman, photo by Martin V. Sørensen, Stanton F. Fink
(vectorized by T. Michael Keesey), Tony Ayling, Stacy Spensley
(Modified), FunkMonk, L. Shyamal, Mali’o Kodis, photograph by John
Slapcinsky, Ignacio Contreras, Caleb M. Brown, Martin R. Smith, from
photo by Jürgen Schoner, Didier Descouens (vectorized by T. Michael
Keesey), Emily Willoughby, Francisco Manuel Blanco (vectorized by T.
Michael Keesey), Cathy, Caleb Brown, E. D. Cope (modified by T. Michael
Keesey, Michael P. Taylor & Matthew J. Wedel), Eduard Solà (vectorized
by T. Michael Keesey), Yan Wong (vectorization) from 1873 illustration,
\[unknown\], Milton Tan, Original drawing by Antonov, vectorized by
Roberto Díaz Sibaja, Tomas Willems (vectorized by T. Michael Keesey),
Jimmy Bernot, David Orr, Mihai Dragos (vectorized by T. Michael Keesey),
Joanna Wolfe, Sergio A. Muñoz-Gómez, Maxime Dahirel, Martin R. Smith,
Thibaut Brunet, Jose Carlos Arenas-Monroy, Mason McNair, Benchill,
CNZdenek, Tauana J. Cunha, Julio Garza, M Kolmann, Alexander
Schmidt-Lebuhn, Alex Slavenko, Scarlet23 (vectorized by T. Michael
Keesey), Henry Lydecker, Smokeybjb (vectorized by T. Michael Keesey),
Scott Reid, Giant Blue Anteater (vectorized by T. Michael Keesey), Jake
Warner, Michele M Tobias, Verdilak, Carlos Cano-Barbacil, Espen Horn
(model; vectorized by T. Michael Keesey from a photo by H. Zell),
Kenneth Lacovara (vectorized by T. Michael Keesey), Robbie N. Cada
(modified by T. Michael Keesey), Conty (vectorized by T. Michael
Keesey), New York Zoological Society, Ellen Edmonson (illustration) and
Timothy J. Bartley (silhouette), Campbell Fleming, Zimices / Julián
Bayona, terngirl, Steven Coombs, Jaime Headden, modified by T. Michael
Keesey, Matt Celeskey, kreidefossilien.de, C. Abraczinskas, Nobu Tamura,
Michael B. H. (vectorized by T. Michael Keesey), Roberto Diaz Sibaja,
based on Domser, Tim Bertelink (modified by T. Michael Keesey), Chuanixn
Yu, Crystal Maier, Hans Hillewaert, Darren Naish, Nemo, and T. Michael
Keesey, FunkMonk (Michael B.H.; vectorized by T. Michael Keesey),
Smokeybjb, Gopal Murali, G. M. Woodward, Tyler Greenfield and Scott
Hartman, John Conway, Lukas Panzarin, Christopher Watson (photo) and T.
Michael Keesey (vectorization), Jakovche, Sibi (vectorized by T. Michael
Keesey), Terpsichores, Katie S. Collins, T. Michael Keesey (after A. Y.
Ivantsov), Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Mali’o Kodis, photograph by P. Funch and R.M. Kristensen, U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
NOAA Great Lakes Environmental Research Laboratory (illustration) and
Timothy J. Bartley (silhouette), Yan Wong, Mike Hanson, Juan Carlos Jerí

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                       |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    351.910478 |    581.983073 | Margot Michaud                                                                                                                                               |
|   2 |    612.901151 |    139.924061 | James R. Spotila and Ray Chatterji                                                                                                                           |
|   3 |    550.667555 |    763.746456 | Tasman Dixon                                                                                                                                                 |
|   4 |    257.280175 |    305.191315 | Kamil S. Jaron                                                                                                                                               |
|   5 |    312.875969 |    410.738433 | Ingo Braasch                                                                                                                                                 |
|   6 |    601.447165 |    656.120098 | NA                                                                                                                                                           |
|   7 |    187.446790 |    113.941516 | Margot Michaud                                                                                                                                               |
|   8 |    616.864323 |    732.787550 | Scott Hartman                                                                                                                                                |
|   9 |    750.146757 |    425.557594 | Steven Traver                                                                                                                                                |
|  10 |    824.334971 |    755.711049 | Armin Reindl                                                                                                                                                 |
|  11 |    839.935188 |    125.681342 | Mathieu Pélissié                                                                                                                                             |
|  12 |    867.807646 |    628.708943 | Iain Reid                                                                                                                                                    |
|  13 |    270.868084 |    177.496438 | Scott Hartman                                                                                                                                                |
|  14 |    773.678284 |    322.869716 | Sean McCann                                                                                                                                                  |
|  15 |    732.755763 |    706.522727 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
|  16 |    575.359130 |    253.833611 | Jagged Fang Designs                                                                                                                                          |
|  17 |    386.253408 |    635.058101 | Zimices                                                                                                                                                      |
|  18 |    754.366080 |    205.807283 | Jagged Fang Designs                                                                                                                                          |
|  19 |    495.514028 |     69.516021 | Mathew Wedel                                                                                                                                                 |
|  20 |     39.428246 |    321.575116 | Michael Scroggie                                                                                                                                             |
|  21 |    361.199172 |    319.076286 | Chloé Schmidt                                                                                                                                                |
|  22 |    656.236283 |    549.676444 | Steven Traver                                                                                                                                                |
|  23 |    889.824565 |    257.202572 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                         |
|  24 |    126.730709 |    473.301953 | Kamil S. Jaron                                                                                                                                               |
|  25 |    221.702573 |    659.017635 | Jagged Fang Designs                                                                                                                                          |
|  26 |    439.880937 |    301.459039 | Felix Vaux                                                                                                                                                   |
|  27 |    483.832826 |    480.056469 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  28 |    781.642087 |    503.782131 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                  |
|  29 |    903.729905 |    523.010157 | Steven Traver                                                                                                                                                |
|  30 |    136.538281 |    707.609592 | Alexandre Vong                                                                                                                                               |
|  31 |    518.681508 |    409.972714 | Margot Michaud                                                                                                                                               |
|  32 |    401.689264 |    128.843672 | Gareth Monger                                                                                                                                                |
|  33 |    916.351398 |    357.565270 | Margot Michaud                                                                                                                                               |
|  34 |    624.433674 |    346.053496 | Beth Reinke                                                                                                                                                  |
|  35 |    346.660276 |    220.969953 | Maija Karala                                                                                                                                                 |
|  36 |    928.350432 |    701.387697 | Chase Brownstein                                                                                                                                             |
|  37 |     42.672276 |    183.430502 | T. Michael Keesey                                                                                                                                            |
|  38 |    451.880319 |    515.133959 | Tasman Dixon                                                                                                                                                 |
|  39 |    288.823688 |     82.935646 | T. Michael Keesey                                                                                                                                            |
|  40 |    642.257442 |     42.614137 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
|  41 |    774.654901 |     30.383081 | Scott Hartman                                                                                                                                                |
|  42 |    370.492770 |    732.841821 | Birgit Lang                                                                                                                                                  |
|  43 |    958.197066 |     66.214424 | Kanchi Nanjo                                                                                                                                                 |
|  44 |    322.599667 |    512.301126 | Zimices                                                                                                                                                      |
|  45 |    803.744620 |    672.553427 | Bennet McComish, photo by Hans Hillewaert                                                                                                                    |
|  46 |    772.626586 |    228.758963 | Agnello Picorelli                                                                                                                                            |
|  47 |     74.650559 |     61.700365 | T. Michael Keesey                                                                                                                                            |
|  48 |    629.690778 |    507.373886 | Dean Schnabel                                                                                                                                                |
|  49 |    141.353888 |    220.984187 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                |
|  50 |     37.663781 |    596.908699 | Griensteidl and T. Michael Keesey                                                                                                                            |
|  51 |    923.240012 |    158.074805 | Dean Schnabel                                                                                                                                                |
|  52 |    439.385314 |     25.094210 | Amanda Katzer                                                                                                                                                |
|  53 |    135.119813 |    616.514907 | Rene Martin                                                                                                                                                  |
|  54 |    359.552488 |    118.720332 | T. Michael Keesey                                                                                                                                            |
|  55 |    200.400545 |    376.790926 | Scott Hartman                                                                                                                                                |
|  56 |    987.526660 |    592.394112 | T. Michael Keesey (after Mivart)                                                                                                                             |
|  57 |    500.436423 |    173.948296 | Gareth Monger                                                                                                                                                |
|  58 |    819.578427 |    581.401559 | Cesar Julian                                                                                                                                                 |
|  59 |    909.917834 |    466.012173 | Ghedoghedo                                                                                                                                                   |
|  60 |    463.653193 |    706.076428 | T. Michael Keesey                                                                                                                                            |
|  61 |    556.633205 |    298.178461 | Jagged Fang Designs                                                                                                                                          |
|  62 |    124.400939 |    560.798568 | Richard Ruggiero, vectorized by Zimices                                                                                                                      |
|  63 |    149.335704 |    302.344525 | NA                                                                                                                                                           |
|  64 |    229.291974 |    757.268562 | Matt Martyniuk                                                                                                                                               |
|  65 |     72.033589 |    765.169670 | Dexter R. Mardis                                                                                                                                             |
|  66 |    715.577968 |    599.620745 | Jaime Headden                                                                                                                                                |
|  67 |    749.792869 |    167.391304 | Jagged Fang Designs                                                                                                                                          |
|  68 |    213.444142 |    519.552738 | T. Michael Keesey                                                                                                                                            |
|  69 |     74.036304 |    396.865597 | Chris huh                                                                                                                                                    |
|  70 |    572.545652 |     76.422439 | C. Camilo Julián-Caballero                                                                                                                                   |
|  71 |    286.571791 |    356.689910 | C. Camilo Julián-Caballero                                                                                                                                   |
|  72 |    723.847033 |    638.946272 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                   |
|  73 |    519.849739 |    331.091235 | T. Michael Keesey                                                                                                                                            |
|  74 |    506.459646 |    590.202825 | Cristopher Silva                                                                                                                                             |
|  75 |    601.481936 |    455.267772 | Chris huh                                                                                                                                                    |
|  76 |    199.220946 |    418.187377 | Jagged Fang Designs                                                                                                                                          |
|  77 |    606.300826 |    217.044436 | Gareth Monger                                                                                                                                                |
|  78 |    741.865881 |    358.962200 | Margot Michaud                                                                                                                                               |
|  79 |    710.000007 |     71.259983 | Scott Hartman                                                                                                                                                |
|  80 |    671.661527 |    775.810049 | Markus A. Grohme                                                                                                                                             |
|  81 |    848.364782 |     54.675047 | Shyamal                                                                                                                                                      |
|  82 |    163.832249 |     29.044232 | Collin Gross                                                                                                                                                 |
|  83 |    566.140228 |     15.589405 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  84 |    945.845121 |    666.161123 | Steven Traver                                                                                                                                                |
|  85 |    805.586098 |    278.159030 | T. Michael Keesey                                                                                                                                            |
|  86 |    890.644794 |    114.322741 | Armin Reindl                                                                                                                                                 |
|  87 |    843.785575 |    459.492789 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  88 |    437.487593 |    209.958806 | Steven Traver                                                                                                                                                |
|  89 |    673.538658 |    286.023465 | Tasman Dixon                                                                                                                                                 |
|  90 |    975.921657 |    434.809203 | Kamil S. Jaron                                                                                                                                               |
|  91 |    177.948065 |     64.321055 | Scott Hartman                                                                                                                                                |
|  92 |    517.532105 |    664.517821 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                              |
|  93 |     32.570854 |    439.305377 | Zimices                                                                                                                                                      |
|  94 |    289.378731 |    695.790305 | Melissa Broussard                                                                                                                                            |
|  95 |    129.045332 |     93.163059 | Iain Reid                                                                                                                                                    |
|  96 |    836.471261 |    376.155654 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                     |
|  97 |    520.832778 |    716.072345 | Matt Dempsey                                                                                                                                                 |
|  98 |    962.404087 |    221.080614 | Markus A. Grohme                                                                                                                                             |
|  99 |    994.697071 |    341.493503 | NA                                                                                                                                                           |
| 100 |     63.549043 |    735.266029 | Scott Hartman                                                                                                                                                |
| 101 |    349.679468 |     16.140805 | Zimices                                                                                                                                                      |
| 102 |    345.422048 |    620.293465 | Mattia Menchetti / Yan Wong                                                                                                                                  |
| 103 |    426.904635 |    713.313421 | T. Michael Keesey                                                                                                                                            |
| 104 |    341.908634 |    445.460134 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                     |
| 105 |    257.756040 |    227.652428 | Sarah Werning                                                                                                                                                |
| 106 |    483.409822 |    784.918107 | Don Armstrong                                                                                                                                                |
| 107 |    956.005152 |    260.012729 | James Neenan                                                                                                                                                 |
| 108 |    324.756393 |    159.343201 | Gareth Monger                                                                                                                                                |
| 109 |    101.616122 |    252.435316 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 110 |     24.667079 |    689.920415 | NA                                                                                                                                                           |
| 111 |    611.581505 |    382.431746 | Inessa Voet                                                                                                                                                  |
| 112 |    429.590518 |    155.812624 | Anthony Caravaggi                                                                                                                                            |
| 113 |    238.412573 |    408.735308 | Roberto Díaz Sibaja                                                                                                                                          |
| 114 |    788.959901 |    341.941389 | Mo Hassan                                                                                                                                                    |
| 115 |    971.066436 |    753.698281 | Richard Ruggiero, vectorized by Zimices                                                                                                                      |
| 116 |    983.130961 |    477.878422 | Michelle Site                                                                                                                                                |
| 117 |    813.052794 |    784.342171 | Zimices                                                                                                                                                      |
| 118 |    579.785146 |    575.774204 | Andrew A. Farke                                                                                                                                              |
| 119 |    915.931588 |    580.893959 | NA                                                                                                                                                           |
| 120 |    826.063233 |    434.023267 | Gareth Monger                                                                                                                                                |
| 121 |    637.067472 |    576.082263 | Iain Reid                                                                                                                                                    |
| 122 |    946.537976 |     20.841393 | Mathew Wedel                                                                                                                                                 |
| 123 |    943.045371 |    185.964868 | Gareth Monger                                                                                                                                                |
| 124 |    264.304597 |    476.396251 | Jennifer Trimble                                                                                                                                             |
| 125 |    271.126264 |    721.239640 | Tyler Greenfield                                                                                                                                             |
| 126 |    775.320046 |    151.232364 | Tracy A. Heath                                                                                                                                               |
| 127 |   1008.505010 |    489.413659 | Sarah Werning                                                                                                                                                |
| 128 |    945.051626 |    580.342339 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                              |
| 129 |    234.083396 |    393.189495 | Francesca Belem Lopes Palmeira                                                                                                                               |
| 130 |    887.247492 |    336.590140 | Gabriela Palomo-Munoz                                                                                                                                        |
| 131 |    779.084853 |    185.942775 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                         |
| 132 |    600.549072 |    737.391858 | Rene Martin                                                                                                                                                  |
| 133 |    713.287352 |    109.729495 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 134 |    852.634309 |    339.359315 | Zimices                                                                                                                                                      |
| 135 |    647.360675 |    430.699328 | NA                                                                                                                                                           |
| 136 |    105.188429 |    143.604555 | Noah Schlottman, photo from Moorea Biocode                                                                                                                   |
| 137 |    327.196454 |     90.473958 | NA                                                                                                                                                           |
| 138 |     12.373523 |    170.021615 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                       |
| 139 |    828.796618 |    683.820305 | Matt Crook                                                                                                                                                   |
| 140 |    456.849606 |    121.647823 | Gareth Monger                                                                                                                                                |
| 141 |     76.211189 |    488.533510 | Shyamal                                                                                                                                                      |
| 142 |    615.030836 |    600.578800 | Jaime Headden                                                                                                                                                |
| 143 |    300.993862 |    620.434889 | Margot Michaud                                                                                                                                               |
| 144 |    328.550247 |    323.381950 | S.Martini                                                                                                                                                    |
| 145 |    411.100261 |    193.273030 | NA                                                                                                                                                           |
| 146 |     74.737305 |    113.281187 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 147 |    680.104545 |    396.149080 | Markus A. Grohme                                                                                                                                             |
| 148 |    706.786602 |    319.866864 | NA                                                                                                                                                           |
| 149 |    594.036751 |    789.585706 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 150 |     66.060764 |    676.293612 | Ferran Sayol                                                                                                                                                 |
| 151 |    250.019650 |    609.490146 | xgirouxb                                                                                                                                                     |
| 152 |    105.490012 |    211.197797 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 153 |    216.095019 |    238.101077 | NA                                                                                                                                                           |
| 154 |    574.565471 |    179.483250 | Anthony Caravaggi                                                                                                                                            |
| 155 |    871.949961 |    421.221625 | Margot Michaud                                                                                                                                               |
| 156 |    927.537869 |    278.086682 | Natasha Vitek                                                                                                                                                |
| 157 |    513.218238 |    517.462447 | Tony Ayling (vectorized by Milton Tan)                                                                                                                       |
| 158 |    232.297023 |     31.428038 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                              |
| 159 |    403.662885 |    446.679872 | Steven Traver                                                                                                                                                |
| 160 |    679.443616 |    227.063505 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 161 |    534.185278 |    529.628049 | T. Michael Keesey (after Masteraah)                                                                                                                          |
| 162 |     57.590420 |    525.333219 | Nina Skinner                                                                                                                                                 |
| 163 |    113.380593 |     54.012652 | NA                                                                                                                                                           |
| 164 |    260.239569 |    783.306481 | Jagged Fang Designs                                                                                                                                          |
| 165 |   1011.220087 |     21.381836 | NA                                                                                                                                                           |
| 166 |    322.150452 |    256.897819 | Gabriela Palomo-Munoz                                                                                                                                        |
| 167 |    714.782238 |    282.886097 | Matt Crook                                                                                                                                                   |
| 168 |    219.911481 |    380.969246 | Maija Karala                                                                                                                                                 |
| 169 |    765.769178 |    664.804756 | Rebecca Groom                                                                                                                                                |
| 170 |    455.177235 |    411.393907 | Scott Hartman                                                                                                                                                |
| 171 |    245.543823 |    265.499611 | Neil Kelley                                                                                                                                                  |
| 172 |     17.948223 |     73.722879 | Jagged Fang Designs                                                                                                                                          |
| 173 |     27.224630 |     44.017060 | Tyler Greenfield                                                                                                                                             |
| 174 |   1009.168148 |    220.862688 | NA                                                                                                                                                           |
| 175 |    877.379534 |     21.495914 | Zimices                                                                                                                                                      |
| 176 |    681.233615 |      6.122725 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
| 177 |    427.254424 |    570.675752 | Kai R. Caspar                                                                                                                                                |
| 178 |    404.660008 |     48.105145 | Scott Hartman                                                                                                                                                |
| 179 |    267.209792 |     11.037879 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                               |
| 180 |    400.280940 |    466.176881 | Kamil S. Jaron                                                                                                                                               |
| 181 |    971.512097 |    173.088550 | T. Michael Keesey (after Ponomarenko)                                                                                                                        |
| 182 |    791.333258 |    549.254580 | NA                                                                                                                                                           |
| 183 |    425.390128 |    616.344672 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                      |
| 184 |   1017.470548 |    146.896983 | Gareth Monger                                                                                                                                                |
| 185 |    242.728896 |    714.469072 | Scott Hartman                                                                                                                                                |
| 186 |    691.924148 |    680.381513 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                 |
| 187 |    809.364131 |     12.240785 | Tasman Dixon                                                                                                                                                 |
| 188 |    212.354253 |    213.984227 | Maija Karala                                                                                                                                                 |
| 189 |    161.582254 |    465.792698 | Margot Michaud                                                                                                                                               |
| 190 |    408.107546 |    545.580135 | Margot Michaud                                                                                                                                               |
| 191 |    672.413187 |    453.652277 | NA                                                                                                                                                           |
| 192 |   1005.459142 |    711.738201 | Dean Schnabel                                                                                                                                                |
| 193 |    234.736098 |    441.243470 | Zimices                                                                                                                                                      |
| 194 |    848.169772 |    421.898725 | Steven Traver                                                                                                                                                |
| 195 |    782.022684 |     80.452056 | Agnello Picorelli                                                                                                                                            |
| 196 |    698.235676 |    488.330494 | Zimices                                                                                                                                                      |
| 197 |    877.984514 |    740.114174 | Margot Michaud                                                                                                                                               |
| 198 |    897.574622 |    392.522162 | Dean Schnabel                                                                                                                                                |
| 199 |   1006.520950 |    512.857884 | Zimices                                                                                                                                                      |
| 200 |    946.209175 |     11.250947 | Kai R. Caspar                                                                                                                                                |
| 201 |    514.067936 |    488.242050 | Margot Michaud                                                                                                                                               |
| 202 |    424.258320 |    386.053157 | Zimices                                                                                                                                                      |
| 203 |    882.390510 |     80.236402 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                            |
| 204 |    208.591743 |    168.017875 | Scott Hartman                                                                                                                                                |
| 205 |     66.521815 |    710.354567 | Steven Traver                                                                                                                                                |
| 206 |    265.047215 |     76.468368 | Felix Vaux                                                                                                                                                   |
| 207 |    521.924976 |    233.110766 | Sarah Werning                                                                                                                                                |
| 208 |    274.872026 |    588.215928 | Tony Ayling                                                                                                                                                  |
| 209 |    461.230547 |    496.115754 | Matt Crook                                                                                                                                                   |
| 210 |    330.546629 |    750.542822 | Birgit Lang                                                                                                                                                  |
| 211 |    428.478309 |    766.124777 | Stacy Spensley (Modified)                                                                                                                                    |
| 212 |    162.976637 |    508.112975 | Steven Traver                                                                                                                                                |
| 213 |    259.469826 |    571.533869 | Margot Michaud                                                                                                                                               |
| 214 |    727.982610 |    724.341717 | Rebecca Groom                                                                                                                                                |
| 215 |     92.017684 |    458.079080 | Margot Michaud                                                                                                                                               |
| 216 |    708.454920 |    456.213709 | Chris huh                                                                                                                                                    |
| 217 |    404.922418 |    431.725231 | Zimices                                                                                                                                                      |
| 218 |    879.783437 |    177.174453 | FunkMonk                                                                                                                                                     |
| 219 |    835.381994 |    708.372726 | Jagged Fang Designs                                                                                                                                          |
| 220 |    477.391520 |    348.136214 | Markus A. Grohme                                                                                                                                             |
| 221 |    930.430861 |    211.033378 | Chloé Schmidt                                                                                                                                                |
| 222 |    583.999163 |    617.404132 | T. Michael Keesey                                                                                                                                            |
| 223 |    913.657682 |    418.311778 | Scott Hartman                                                                                                                                                |
| 224 |    813.303268 |    720.833698 | L. Shyamal                                                                                                                                                   |
| 225 |    610.995508 |    191.766548 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                  |
| 226 |    250.733365 |    629.628066 | Markus A. Grohme                                                                                                                                             |
| 227 |    439.532743 |    485.010054 | T. Michael Keesey                                                                                                                                            |
| 228 |    535.605345 |    786.905738 | Ignacio Contreras                                                                                                                                            |
| 229 |    962.101733 |    630.945183 | Caleb M. Brown                                                                                                                                               |
| 230 |    721.772145 |    513.445730 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 231 |    536.486919 |    727.363125 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                |
| 232 |    137.779243 |    650.752722 | Sarah Werning                                                                                                                                                |
| 233 |    292.157896 |    466.652009 | Zimices                                                                                                                                                      |
| 234 |    421.182651 |    482.335510 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                           |
| 235 |    667.115261 |    482.010579 | Zimices                                                                                                                                                      |
| 236 |    311.675754 |    788.039948 | Rene Martin                                                                                                                                                  |
| 237 |    545.956080 |    367.947592 | Scott Hartman                                                                                                                                                |
| 238 |    622.079220 |    408.347763 | Emily Willoughby                                                                                                                                             |
| 239 |    291.740378 |    731.023943 | Zimices                                                                                                                                                      |
| 240 |   1009.901515 |    620.762235 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                    |
| 241 |     63.134303 |    699.933228 | Mathew Wedel                                                                                                                                                 |
| 242 |     74.639546 |    188.063844 | Kanchi Nanjo                                                                                                                                                 |
| 243 |    941.311198 |    780.092711 | T. Michael Keesey                                                                                                                                            |
| 244 |    872.534323 |    377.653186 | Matt Crook                                                                                                                                                   |
| 245 |    846.066059 |    302.122154 | Matt Crook                                                                                                                                                   |
| 246 |    716.163048 |    676.736970 | C. Camilo Julián-Caballero                                                                                                                                   |
| 247 |    210.309860 |    590.047502 | Matt Crook                                                                                                                                                   |
| 248 |    337.588561 |     67.666712 | Margot Michaud                                                                                                                                               |
| 249 |    757.424181 |    719.645133 | Tasman Dixon                                                                                                                                                 |
| 250 |    722.057759 |    579.615453 | Cathy                                                                                                                                                        |
| 251 |    495.954882 |    652.748226 | Maija Karala                                                                                                                                                 |
| 252 |    844.756873 |    174.525404 | Caleb Brown                                                                                                                                                  |
| 253 |    693.548607 |    729.183162 | Birgit Lang                                                                                                                                                  |
| 254 |    912.835259 |    369.699448 | NA                                                                                                                                                           |
| 255 |    379.026588 |    613.662399 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                             |
| 256 |    987.395061 |    242.174201 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                |
| 257 |     65.179346 |    502.369253 | Jagged Fang Designs                                                                                                                                          |
| 258 |    745.964590 |    618.346951 | Zimices                                                                                                                                                      |
| 259 |    857.141437 |    322.177577 | Emily Willoughby                                                                                                                                             |
| 260 |    841.809288 |    605.645819 | Scott Hartman                                                                                                                                                |
| 261 |    209.461878 |    355.843118 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
| 262 |    360.482923 |     43.646673 | Gareth Monger                                                                                                                                                |
| 263 |    457.807679 |    242.646965 | Zimices                                                                                                                                                      |
| 264 |   1013.140829 |    424.638923 | Yan Wong (vectorization) from 1873 illustration                                                                                                              |
| 265 |    912.798260 |    330.724259 | Chloé Schmidt                                                                                                                                                |
| 266 |    857.285183 |    242.512354 | \[unknown\]                                                                                                                                                  |
| 267 |    943.371731 |    240.044201 | T. Michael Keesey                                                                                                                                            |
| 268 |    516.304105 |    544.278135 | Zimices                                                                                                                                                      |
| 269 |    244.876875 |    691.052065 | Steven Traver                                                                                                                                                |
| 270 |    266.258233 |     47.807234 | Gareth Monger                                                                                                                                                |
| 271 |    981.913003 |    278.536391 | Tasman Dixon                                                                                                                                                 |
| 272 |    827.130663 |    515.713059 | Milton Tan                                                                                                                                                   |
| 273 |     52.930897 |    485.938487 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                               |
| 274 |    693.073307 |     16.976888 | Jagged Fang Designs                                                                                                                                          |
| 275 |    764.440994 |    473.386718 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                              |
| 276 |    978.392178 |    231.763453 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 277 |     94.867247 |    300.109751 | Zimices                                                                                                                                                      |
| 278 |    806.828747 |     77.625888 | Sarah Werning                                                                                                                                                |
| 279 |    493.955226 |    121.219416 | Margot Michaud                                                                                                                                               |
| 280 |    725.459789 |    470.318889 | Zimices                                                                                                                                                      |
| 281 |    756.017311 |     90.970540 | Scott Hartman                                                                                                                                                |
| 282 |    809.486448 |    389.753859 | Matt Crook                                                                                                                                                   |
| 283 |    763.313708 |    607.215013 | Caleb M. Brown                                                                                                                                               |
| 284 |     72.911030 |    469.572319 | Jagged Fang Designs                                                                                                                                          |
| 285 |    687.484041 |    261.344513 | Jimmy Bernot                                                                                                                                                 |
| 286 |    612.046430 |    270.179147 | David Orr                                                                                                                                                    |
| 287 |     94.834103 |    229.322689 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                               |
| 288 |    508.291879 |     92.793008 | Francesca Belem Lopes Palmeira                                                                                                                               |
| 289 |    832.900138 |    542.759930 | Anthony Caravaggi                                                                                                                                            |
| 290 |     26.342599 |    389.571917 | Jagged Fang Designs                                                                                                                                          |
| 291 |    293.317045 |    149.762975 | Milton Tan                                                                                                                                                   |
| 292 |    424.086633 |     65.458757 | Joanna Wolfe                                                                                                                                                 |
| 293 |    323.931429 |    723.934559 | FunkMonk                                                                                                                                                     |
| 294 |    771.744479 |    394.554735 | Zimices                                                                                                                                                      |
| 295 |    846.304832 |    194.002769 | Gareth Monger                                                                                                                                                |
| 296 |    554.413530 |    505.060102 | Sergio A. Muñoz-Gómez                                                                                                                                        |
| 297 |    985.390651 |    525.169187 | Maxime Dahirel                                                                                                                                               |
| 298 |    320.846398 |     48.674312 | Margot Michaud                                                                                                                                               |
| 299 |    709.668417 |    753.790614 | Kamil S. Jaron                                                                                                                                               |
| 300 |    176.822639 |    217.591194 | Martin R. Smith                                                                                                                                              |
| 301 |     18.279490 |    794.654051 | Thibaut Brunet                                                                                                                                               |
| 302 |    741.622860 |    131.778642 | Zimices                                                                                                                                                      |
| 303 |     16.216276 |    105.805545 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                              |
| 304 |     45.753928 |    249.859851 | Markus A. Grohme                                                                                                                                             |
| 305 |    911.159045 |    791.533073 | Birgit Lang                                                                                                                                                  |
| 306 |    744.805951 |    249.305786 | Iain Reid                                                                                                                                                    |
| 307 |    443.162115 |    435.276864 | Jagged Fang Designs                                                                                                                                          |
| 308 |    159.356650 |    785.072035 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 309 |    262.896126 |    205.111928 | Mo Hassan                                                                                                                                                    |
| 310 |    716.108041 |    267.819116 | Emily Willoughby                                                                                                                                             |
| 311 |    730.890198 |     40.104628 | Steven Traver                                                                                                                                                |
| 312 |   1004.911423 |    265.337059 | Mason McNair                                                                                                                                                 |
| 313 |    379.183107 |    253.049249 | Benchill                                                                                                                                                     |
| 314 |    877.918113 |    455.860715 | CNZdenek                                                                                                                                                     |
| 315 |    662.263847 |    411.679348 | Iain Reid                                                                                                                                                    |
| 316 |    712.150893 |    383.137644 | Steven Traver                                                                                                                                                |
| 317 |    999.188050 |    188.762173 | Kanchi Nanjo                                                                                                                                                 |
| 318 |    583.485477 |    486.641467 | Chris huh                                                                                                                                                    |
| 319 |    592.226688 |    771.226801 | Tasman Dixon                                                                                                                                                 |
| 320 |    153.318997 |    243.206048 | Tauana J. Cunha                                                                                                                                              |
| 321 |    110.941400 |    417.855095 | Julio Garza                                                                                                                                                  |
| 322 |    916.283584 |    425.597240 | M Kolmann                                                                                                                                                    |
| 323 |    423.645631 |    415.097891 | Tracy A. Heath                                                                                                                                               |
| 324 |    551.022325 |    230.531485 | CNZdenek                                                                                                                                                     |
| 325 |    460.782301 |    549.864384 | Matt Crook                                                                                                                                                   |
| 326 |    843.863452 |    724.926372 | Margot Michaud                                                                                                                                               |
| 327 |    499.282303 |    500.523755 | Ignacio Contreras                                                                                                                                            |
| 328 |    789.954648 |      4.753355 | Scott Hartman                                                                                                                                                |
| 329 |    115.982353 |    751.292232 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 330 |    713.917334 |    246.647826 | Margot Michaud                                                                                                                                               |
| 331 |    752.003735 |    548.590577 | Gareth Monger                                                                                                                                                |
| 332 |    266.969063 |    246.921833 | Margot Michaud                                                                                                                                               |
| 333 |    690.483368 |    182.563957 | Alex Slavenko                                                                                                                                                |
| 334 |    160.015931 |     52.410861 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                  |
| 335 |    436.643912 |    447.154281 | Henry Lydecker                                                                                                                                               |
| 336 |     79.963486 |    599.766013 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 337 |    684.028931 |     96.532592 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                  |
| 338 |     19.444182 |    472.688501 | Scott Reid                                                                                                                                                   |
| 339 |    784.851013 |    733.814219 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                        |
| 340 |    249.397352 |    115.858349 | Jake Warner                                                                                                                                                  |
| 341 |    659.125878 |    697.511106 | Michele M Tobias                                                                                                                                             |
| 342 |    872.648596 |    783.098471 | T. Michael Keesey                                                                                                                                            |
| 343 |    274.218114 |    448.724910 | Verdilak                                                                                                                                                     |
| 344 |    732.571772 |    793.451042 | Markus A. Grohme                                                                                                                                             |
| 345 |    100.829077 |    283.690011 | Carlos Cano-Barbacil                                                                                                                                         |
| 346 |    535.289910 |    630.028383 | Chris huh                                                                                                                                                    |
| 347 |    325.764808 |    671.515328 | L. Shyamal                                                                                                                                                   |
| 348 |    359.304655 |    434.454936 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                  |
| 349 |    633.751004 |    590.176212 | Jimmy Bernot                                                                                                                                                 |
| 350 |    832.999166 |    101.789717 | Carlos Cano-Barbacil                                                                                                                                         |
| 351 |    481.809573 |    286.216201 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                           |
| 352 |    403.986988 |    792.873641 | NA                                                                                                                                                           |
| 353 |    386.114551 |     56.537724 | Steven Traver                                                                                                                                                |
| 354 |    357.005071 |    384.531128 | Zimices                                                                                                                                                      |
| 355 |    107.242688 |    721.024039 | Gabriela Palomo-Munoz                                                                                                                                        |
| 356 |    780.623362 |    256.811791 | Margot Michaud                                                                                                                                               |
| 357 |     75.278016 |    127.590733 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                               |
| 358 |    390.878548 |    407.080508 | NA                                                                                                                                                           |
| 359 |    754.878797 |    454.037001 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
| 360 |    425.222047 |    129.337105 | Jagged Fang Designs                                                                                                                                          |
| 361 |     37.009290 |    465.198933 | Tasman Dixon                                                                                                                                                 |
| 362 |    220.866923 |     58.898104 | New York Zoological Society                                                                                                                                  |
| 363 |    559.821179 |     47.336875 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                            |
| 364 |    416.760439 |    346.726732 | T. Michael Keesey                                                                                                                                            |
| 365 |    828.741464 |    202.809935 | Campbell Fleming                                                                                                                                             |
| 366 |    196.005721 |    484.660990 | Milton Tan                                                                                                                                                   |
| 367 |     94.375661 |    359.636428 | Kamil S. Jaron                                                                                                                                               |
| 368 |    244.401060 |    664.045110 | Zimices / Julián Bayona                                                                                                                                      |
| 369 |    146.503814 |    388.783320 | terngirl                                                                                                                                                     |
| 370 |    754.942340 |    738.217431 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 371 |    355.355582 |    344.210027 | Agnello Picorelli                                                                                                                                            |
| 372 |    697.457277 |    218.122798 | NA                                                                                                                                                           |
| 373 |    148.440068 |      7.705502 | Scott Hartman                                                                                                                                                |
| 374 |    784.459515 |    123.216775 | Matt Martyniuk                                                                                                                                               |
| 375 |    894.173631 |    590.153943 | Sarah Werning                                                                                                                                                |
| 376 |    568.605471 |    735.753951 | Steven Coombs                                                                                                                                                |
| 377 |    871.216750 |     62.614362 | NA                                                                                                                                                           |
| 378 |    851.669722 |     88.486771 | Jaime Headden, modified by T. Michael Keesey                                                                                                                 |
| 379 |    538.664041 |    454.402156 | Gareth Monger                                                                                                                                                |
| 380 |    537.973708 |     33.676296 | Zimices                                                                                                                                                      |
| 381 |     31.119837 |    111.222414 | Milton Tan                                                                                                                                                   |
| 382 |    406.120457 |    599.828549 | Margot Michaud                                                                                                                                               |
| 383 |    519.588113 |    627.004753 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
| 384 |    681.757138 |     23.952721 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 385 |    523.747490 |    212.846059 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                              |
| 386 |    997.384937 |    787.087160 | Scott Hartman                                                                                                                                                |
| 387 |    855.259908 |    223.531264 | Scott Hartman                                                                                                                                                |
| 388 |    666.423157 |    581.948853 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
| 389 |    871.941003 |    143.853189 | Gareth Monger                                                                                                                                                |
| 390 |    891.471034 |      9.172105 | Caleb M. Brown                                                                                                                                               |
| 391 |    170.317395 |    163.055497 | Armin Reindl                                                                                                                                                 |
| 392 |    405.579062 |    685.333205 | Gareth Monger                                                                                                                                                |
| 393 |    122.013742 |    374.480039 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 394 |     79.556506 |    430.653674 | Matt Celeskey                                                                                                                                                |
| 395 |    526.013597 |    742.125420 | Markus A. Grohme                                                                                                                                             |
| 396 |    844.620459 |    791.782528 | C. Camilo Julián-Caballero                                                                                                                                   |
| 397 |    490.836043 |    551.633848 | Gabriela Palomo-Munoz                                                                                                                                        |
| 398 |    856.714317 |    681.234421 | kreidefossilien.de                                                                                                                                           |
| 399 |    758.065113 |    781.523743 | C. Abraczinskas                                                                                                                                              |
| 400 |    209.579046 |    191.008350 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 401 |    596.549814 |    240.943314 | Nobu Tamura                                                                                                                                                  |
| 402 |    817.092418 |    258.234245 | Sarah Werning                                                                                                                                                |
| 403 |    632.256395 |    494.487948 | Margot Michaud                                                                                                                                               |
| 404 |    893.722420 |    599.500813 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                              |
| 405 |    803.463330 |    528.892491 | Jagged Fang Designs                                                                                                                                          |
| 406 |    116.599890 |    316.094421 | Emily Willoughby                                                                                                                                             |
| 407 |      7.010211 |    244.513874 | Michelle Site                                                                                                                                                |
| 408 |    712.311049 |    692.999429 | Scott Hartman                                                                                                                                                |
| 409 |    483.614241 |    254.976436 | Matt Crook                                                                                                                                                   |
| 410 |    559.202615 |    382.391491 | Zimices                                                                                                                                                      |
| 411 |    116.211314 |    112.259233 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                              |
| 412 |    165.383819 |    636.280181 | Roberto Diaz Sibaja, based on Domser                                                                                                                         |
| 413 |    102.340199 |     16.974825 | Gareth Monger                                                                                                                                                |
| 414 |    153.111296 |    220.976521 | Matt Crook                                                                                                                                                   |
| 415 |    348.918649 |    254.296135 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                |
| 416 |    857.236196 |    492.057152 | T. Michael Keesey                                                                                                                                            |
| 417 |    456.280013 |    359.846076 | Chuanixn Yu                                                                                                                                                  |
| 418 |     22.147627 |    220.627327 | Crystal Maier                                                                                                                                                |
| 419 |    818.171376 |     64.029925 | NA                                                                                                                                                           |
| 420 |    193.328744 |      4.953277 | Scott Hartman                                                                                                                                                |
| 421 |    425.061774 |    667.565740 | Cesar Julian                                                                                                                                                 |
| 422 |   1004.017592 |    666.378138 | Hans Hillewaert                                                                                                                                              |
| 423 |    584.407618 |    279.211101 | Kai R. Caspar                                                                                                                                                |
| 424 |    996.130982 |    131.361748 | Gareth Monger                                                                                                                                                |
| 425 |    655.928026 |    664.709472 | Matt Crook                                                                                                                                                   |
| 426 |    318.269970 |    465.836673 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                    |
| 427 |    911.759930 |     84.864404 | Caleb M. Brown                                                                                                                                               |
| 428 |    211.510730 |    275.818820 | Steven Traver                                                                                                                                                |
| 429 |    768.982642 |    172.089371 | Zimices                                                                                                                                                      |
| 430 |    300.422333 |    235.267639 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                     |
| 431 |   1007.887630 |    733.362463 | Smokeybjb                                                                                                                                                    |
| 432 |    450.695850 |     40.492387 | Gopal Murali                                                                                                                                                 |
| 433 |    697.730233 |    307.387011 | Jagged Fang Designs                                                                                                                                          |
| 434 |    145.228102 |     43.556956 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 435 |     44.033665 |    258.818827 | Gareth Monger                                                                                                                                                |
| 436 |    179.907319 |    397.696645 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 437 |    430.042287 |    113.413780 | Jake Warner                                                                                                                                                  |
| 438 |    632.684934 |    758.372630 | Armin Reindl                                                                                                                                                 |
| 439 |    300.441865 |    294.638589 | Felix Vaux                                                                                                                                                   |
| 440 |    480.026141 |     34.431889 | Markus A. Grohme                                                                                                                                             |
| 441 |    792.590304 |    637.544664 | Margot Michaud                                                                                                                                               |
| 442 |    520.480795 |    109.612766 | Gareth Monger                                                                                                                                                |
| 443 |   1012.943239 |    756.177286 | Steven Traver                                                                                                                                                |
| 444 |    939.713490 |    480.350680 | Chris huh                                                                                                                                                    |
| 445 |    674.456883 |    685.814869 | Gareth Monger                                                                                                                                                |
| 446 |    287.409301 |    664.581875 | Markus A. Grohme                                                                                                                                             |
| 447 |    449.896168 |    795.029796 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 448 |    639.999580 |     11.095185 | G. M. Woodward                                                                                                                                               |
| 449 |    202.900041 |    452.110525 | Tyler Greenfield and Scott Hartman                                                                                                                           |
| 450 |    696.779489 |    710.778486 | Chris huh                                                                                                                                                    |
| 451 |    107.789150 |    794.957677 | T. Michael Keesey                                                                                                                                            |
| 452 |     22.430469 |    513.362582 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 453 |    460.995750 |    767.048827 | NA                                                                                                                                                           |
| 454 |    932.267078 |    637.493429 | Chris huh                                                                                                                                                    |
| 455 |    725.315244 |    328.961504 | Markus A. Grohme                                                                                                                                             |
| 456 |    874.452373 |    354.845433 | NA                                                                                                                                                           |
| 457 |    490.690657 |      6.289567 | John Conway                                                                                                                                                  |
| 458 |    736.869182 |    526.843726 | Chris huh                                                                                                                                                    |
| 459 |    736.956586 |    667.760660 | Tasman Dixon                                                                                                                                                 |
| 460 |    907.289344 |    104.364676 | Lukas Panzarin                                                                                                                                               |
| 461 |    300.598666 |    333.209267 | Carlos Cano-Barbacil                                                                                                                                         |
| 462 |    464.086829 |    104.414280 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                             |
| 463 |     84.853212 |    742.419403 | Scott Hartman                                                                                                                                                |
| 464 |    961.790837 |    475.235470 | Markus A. Grohme                                                                                                                                             |
| 465 |    264.130006 |    317.054746 | Jakovche                                                                                                                                                     |
| 466 |    528.703927 |    103.057492 | Chris huh                                                                                                                                                    |
| 467 |    337.738345 |    699.807438 | T. Michael Keesey                                                                                                                                            |
| 468 |    977.344166 |    518.698070 | Birgit Lang                                                                                                                                                  |
| 469 |    189.982516 |    471.978369 | Steven Traver                                                                                                                                                |
| 470 |    361.434933 |    670.608753 | Markus A. Grohme                                                                                                                                             |
| 471 |    161.404594 |    661.451411 | Margot Michaud                                                                                                                                               |
| 472 |    546.542729 |    335.473603 | Scott Hartman                                                                                                                                                |
| 473 |    327.204908 |    775.893653 | Tauana J. Cunha                                                                                                                                              |
| 474 |   1003.038437 |    454.799155 | Sibi (vectorized by T. Michael Keesey)                                                                                                                       |
| 475 |    246.422388 |     45.716141 | Terpsichores                                                                                                                                                 |
| 476 |    693.322551 |    290.208332 | T. Michael Keesey                                                                                                                                            |
| 477 |    353.074767 |    544.201217 | Tasman Dixon                                                                                                                                                 |
| 478 |    882.597866 |    152.845108 | G. M. Woodward                                                                                                                                               |
| 479 |    805.707706 |    607.862147 | Gareth Monger                                                                                                                                                |
| 480 |    332.015475 |     33.868491 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                        |
| 481 |    262.269648 |    496.051484 | Katie S. Collins                                                                                                                                             |
| 482 |    629.220347 |    712.497228 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                     |
| 483 |     95.148960 |    161.129036 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 484 |    618.736351 |    281.049890 | Chris huh                                                                                                                                                    |
| 485 |     21.867603 |     12.238059 | Tasman Dixon                                                                                                                                                 |
| 486 |    483.008538 |    369.455730 | Jagged Fang Designs                                                                                                                                          |
| 487 |    509.152467 |    270.120114 | Armin Reindl                                                                                                                                                 |
| 488 |   1001.449680 |    109.656300 | Zimices                                                                                                                                                      |
| 489 |    778.163111 |    454.841242 | S.Martini                                                                                                                                                    |
| 490 |    857.406008 |      7.745001 | Beth Reinke                                                                                                                                                  |
| 491 |    247.146986 |     22.380798 | Scott Hartman                                                                                                                                                |
| 492 |     21.469470 |    131.475567 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                  |
| 493 |    429.985827 |    785.080053 | Matt Celeskey                                                                                                                                                |
| 494 |    560.239825 |    189.175239 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                     |
| 495 |    744.152376 |    112.513503 | NA                                                                                                                                                           |
| 496 |    183.987227 |    605.213950 | Chris huh                                                                                                                                                    |
| 497 |    206.955199 |    156.227922 | Scott Hartman                                                                                                                                                |
| 498 |   1014.201332 |    645.495005 | Gopal Murali                                                                                                                                                 |
| 499 |    949.492617 |    297.301561 | Carlos Cano-Barbacil                                                                                                                                         |
| 500 |    933.399509 |    616.451253 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                            |
| 501 |     30.638565 |    503.046658 | Shyamal                                                                                                                                                      |
| 502 |    840.103295 |     16.863348 | Margot Michaud                                                                                                                                               |
| 503 |    533.673239 |    176.892119 | Jagged Fang Designs                                                                                                                                          |
| 504 |    198.144510 |    784.774337 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                        |
| 505 |    153.161672 |    262.445759 | Gabriela Palomo-Munoz                                                                                                                                        |
| 506 |     85.551399 |    790.057055 | Nobu Tamura                                                                                                                                                  |
| 507 |    205.420688 |    690.334900 | Emily Willoughby                                                                                                                                             |
| 508 |    329.709559 |    377.690287 | Margot Michaud                                                                                                                                               |
| 509 |    409.376709 |    242.157773 | T. Michael Keesey                                                                                                                                            |
| 510 |    905.296922 |    780.937956 | Markus A. Grohme                                                                                                                                             |
| 511 |    619.442838 |    486.386484 | NA                                                                                                                                                           |
| 512 |   1008.717967 |     90.096711 | Yan Wong                                                                                                                                                     |
| 513 |      5.292072 |    142.513556 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 514 |    550.135744 |    558.636481 | Chris huh                                                                                                                                                    |
| 515 |    910.952241 |    441.909688 | Gabriela Palomo-Munoz                                                                                                                                        |
| 516 |    194.597429 |    175.793186 | Mike Hanson                                                                                                                                                  |
| 517 |    388.499062 |     31.737257 | Juan Carlos Jerí                                                                                                                                             |
| 518 |    382.539520 |     13.234412 | Zimices                                                                                                                                                      |
| 519 |    355.458324 |    191.019580 | Andrew A. Farke                                                                                                                                              |
| 520 |    191.222021 |     73.979379 | Markus A. Grohme                                                                                                                                             |
| 521 |    403.322285 |    771.821867 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                         |
| 522 |    800.015915 |    695.692629 | Jaime Headden                                                                                                                                                |
| 523 |    743.530401 |    270.104072 | Margot Michaud                                                                                                                                               |
| 524 |    199.639939 |    621.788443 | Matt Crook                                                                                                                                                   |
| 525 |     59.691629 |    415.580790 | Jagged Fang Designs                                                                                                                                          |
| 526 |    924.604754 |    760.122195 | Dean Schnabel                                                                                                                                                |

    #> Your tweet has been posted!
