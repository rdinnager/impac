
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
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
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Ingo Braasch, Matt Crook, Lukasiniho, Xavier Giroux-Bougard, Mathew
Wedel, Steven Traver, Maky (vectorization), Gabriella Skollar
(photography), Rebecca Lewis (editing), Mali’o Kodis, photograph by
Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>),
Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization),
Gareth Monger, Beth Reinke, Smokeybjb, Michael Scroggie, Birgit Lang,
Christoph Schomburg, Emily Willoughby, Vanessa Guerra, Gabriela
Palomo-Munoz, Jaime Headden, modified by T. Michael Keesey, Chris huh,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Ferran Sayol, Todd
Marshall, vectorized by Zimices, Jerry Oldenettel (vectorized by T.
Michael Keesey), Zimices, Kailah Thorn & Ben King, Haplochromis
(vectorized by T. Michael Keesey), Scott Hartman, Jagged Fang Designs,
Margot Michaud, Sarah Werning, Obsidian Soul (vectorized by T. Michael
Keesey), Kamil S. Jaron, Matt Wilkins, Aviceda (vectorized by T. Michael
Keesey), Lafage, Konsta Happonen, from a CC-BY-NC image by pelhonen on
iNaturalist, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Shyamal, Greg Schechter (original photo), Renato Santos
(vector silhouette), Dean Schnabel, Danielle Alba, Danny Cicchetti
(vectorized by T. Michael Keesey), T. Michael Keesey, Javiera Constanzo,
Jack Mayer Wood, Joris van der Ham (vectorized by T. Michael Keesey),
Tasman Dixon, Nobu Tamura (modified by T. Michael Keesey), Christian A.
Masnaghetti, T. Michael Keesey, from a photograph by Thea Boodhoo, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), (unknown),
Ghedoghedo (vectorized by T. Michael Keesey), Matt Celeskey, Michelle
Site, terngirl, Mali’o Kodis, photograph by P. Funch and R.M.
Kristensen, Audrey Ely, FunkMonk, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Scarlet23
(vectorized by T. Michael Keesey), Harold N Eyster, Yan Wong, Steven
Coombs, Kai R. Caspar, Tracy A. Heath, Neil Kelley, Hans Hillewaert
(vectorized by T. Michael Keesey), Jonathan Wells, (after Spotila 2004),
Gregor Bucher, Max Farnworth, Chase Brownstein, Ernst Haeckel
(vectorized by T. Michael Keesey), Terpsichores, S.Martini, Noah
Schlottman, photo by Museum of Geology, University of Tartu, M Kolmann,
Aviceda (photo) & T. Michael Keesey, Nobu Tamura (vectorized by T.
Michael Keesey), Rebecca Groom, Robert Bruce Horsfall, vectorized by
Zimices, Matt Martyniuk, Ghedoghedo, vectorized by Zimices, Dave
Angelini, Smokeybjb (vectorized by T. Michael Keesey), Tauana J. Cunha,
Zachary Quigley, Scott Reid, James I. Kirkland, Luis Alcalá, Mark A.
Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized
by T. Michael Keesey), Sebastian Stabinger, E. R. Waite & H. M. Hale
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by Hans
Hillewaert, Jaime Headden, Jaime Headden (vectorized by T. Michael
Keesey), Maija Karala, Tony Ayling (vectorized by T. Michael Keesey), Mo
Hassan, Caio Bernardes, vectorized by Zimices, Lani Mohan, Scott Hartman
(modified by T. Michael Keesey), Ryan Cupo, V. Deepak, , Jesús Gómez,
vectorized by Zimices, Amanda Katzer, Daniel Stadtmauer, Robbie N. Cada
(vectorized by T. Michael Keesey), Timothy Knepp of the U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Pranav Iyer (grey ideas), Pollyanna von Knorring and T. Michael Keesey,
Nobu Tamura, Rachel Shoop, Sarefo (vectorized by T. Michael Keesey),
Michael Scroggie, from original photograph by Gary M. Stolz, USFWS
(original photograph in public domain)., Roberto Díaz Sibaja, Michael P.
Taylor, Siobhon Egan, Nicholas J. Czaplewski, vectorized by Zimices, C.
Camilo Julián-Caballero, Sergio A. Muñoz-Gómez, Stuart Humphries, Ludwik
Gasiorowski, TaraTaylorDesign, G. M. Woodward, Andrew A. Farke, John
Gould (vectorized by T. Michael Keesey), Matt Martyniuk (modified by T.
Michael Keesey), ArtFavor & annaleeblysse, Auckland Museum and T.
Michael Keesey, Tyler Greenfield and Scott Hartman, Matt Dempsey,
Mathieu Basille, Smokeybjb (modified by Mike Keesey), Henry Lydecker,
Eric Moody, Tyler Greenfield, Scott Hartman (vectorized by T. Michael
Keesey), Duane Raver/USFWS, Stacy Spensley (Modified), Maxwell Lefroy
(vectorized by T. Michael Keesey), Didier Descouens (vectorized by T.
Michael Keesey), Becky Barnes, Prin Pattawaro (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Noah Schlottman,
photo by Casey Dunn, Michael Day, Yan Wong from illustration by Jules
Richard (1907), Felix Vaux, Dianne Bray / Museum Victoria (vectorized by
T. Michael Keesey), Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), C. W.
Nash (illustration) and Timothy J. Bartley (silhouette), Conty
(vectorized by T. Michael Keesey), Gopal Murali, Lauren Anderson, Alex
Slavenko, Kent Elson Sorgon, Ville Koistinen and T. Michael Keesey,
Cagri Cevrim, Sean McCann, Armin Reindl, Nobu Tamura, vectorized by
Zimices, C. Abraczinskas, Jake Warner, Dmitry Bogdanov, Blanco et al.,
2014, vectorized by Zimices, FunkMonk (Michael B. H.), Remes K, Ortega
F, Fierro I, Joger U, Kosma R, et al., Lip Kee Yap (vectorized by T.
Michael Keesey), CNZdenek, Robert Gay, Jaime A. Headden (vectorized by
T. Michael Keesey), David Tana, John Conway, Raven Amos, Noah
Schlottman, photo by Antonio Guillén, Filip em, Pete Buchholz, Iain
Reid, Saguaro Pictures (source photo) and T. Michael Keesey, L. Shyamal,
Emil Schmidt (vectorized by Maxime Dahirel), E. D. Cope (modified by T.
Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Sarah Alewijnse, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Julia B McHugh, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Geoff Shaw,
Alexander Schmidt-Lebuhn

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    688.688512 |     50.077060 | Ingo Braasch                                                                                                                                                   |
|   2 |    895.704089 |    613.152680 | Matt Crook                                                                                                                                                     |
|   3 |    155.806689 |     57.516398 | Lukasiniho                                                                                                                                                     |
|   4 |    176.120021 |    165.587436 | Xavier Giroux-Bougard                                                                                                                                          |
|   5 |    654.274211 |    222.481733 | Mathew Wedel                                                                                                                                                   |
|   6 |    906.061732 |    185.493241 | Steven Traver                                                                                                                                                  |
|   7 |    469.434539 |    558.984634 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                 |
|   8 |    233.941856 |    706.193881 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                 |
|   9 |    977.979773 |    677.985816 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                         |
|  10 |    243.816411 |    606.094446 | Gareth Monger                                                                                                                                                  |
|  11 |    446.744475 |    254.425818 | Beth Reinke                                                                                                                                                    |
|  12 |    854.748790 |    408.873913 | Smokeybjb                                                                                                                                                      |
|  13 |    743.654880 |    147.863666 | Michael Scroggie                                                                                                                                               |
|  14 |    347.578489 |    644.672841 | Birgit Lang                                                                                                                                                    |
|  15 |    202.100580 |    484.390253 | Christoph Schomburg                                                                                                                                            |
|  16 |    223.135800 |    331.068596 | Emily Willoughby                                                                                                                                               |
|  17 |     63.481016 |    687.682065 | Vanessa Guerra                                                                                                                                                 |
|  18 |    535.053841 |     81.974633 | Gabriela Palomo-Munoz                                                                                                                                          |
|  19 |    592.191276 |    720.928739 | Jaime Headden, modified by T. Michael Keesey                                                                                                                   |
|  20 |    101.015902 |    759.133363 | Chris huh                                                                                                                                                      |
|  21 |    124.606862 |    264.608387 | Beth Reinke                                                                                                                                                    |
|  22 |    502.021393 |    459.683602 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  23 |    838.535114 |    553.169348 | Ferran Sayol                                                                                                                                                   |
|  24 |    223.080939 |    400.570482 | Ferran Sayol                                                                                                                                                   |
|  25 |    581.848613 |    661.268599 | Todd Marshall, vectorized by Zimices                                                                                                                           |
|  26 |    742.901683 |    352.409693 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                             |
|  27 |    560.246720 |    571.085340 | Gabriela Palomo-Munoz                                                                                                                                          |
|  28 |    447.580496 |    402.968031 | Zimices                                                                                                                                                        |
|  29 |    867.533140 |    322.732635 | NA                                                                                                                                                             |
|  30 |    794.726018 |    691.697084 | Zimices                                                                                                                                                        |
|  31 |    371.301912 |     43.544810 | Zimices                                                                                                                                                        |
|  32 |    297.955406 |     55.875332 | Ferran Sayol                                                                                                                                                   |
|  33 |    634.725374 |    470.959170 | Kailah Thorn & Ben King                                                                                                                                        |
|  34 |    504.099122 |    686.277420 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
|  35 |    186.565596 |    545.986857 | Gareth Monger                                                                                                                                                  |
|  36 |    857.280362 |    192.434637 | Scott Hartman                                                                                                                                                  |
|  37 |    117.698390 |    430.170556 | Ferran Sayol                                                                                                                                                   |
|  38 |     90.494153 |    620.520841 | Jagged Fang Designs                                                                                                                                            |
|  39 |    329.018630 |    435.918260 | NA                                                                                                                                                             |
|  40 |    406.631637 |    758.396455 | Margot Michaud                                                                                                                                                 |
|  41 |    351.588459 |    344.769397 | Sarah Werning                                                                                                                                                  |
|  42 |    877.449603 |    735.395326 | Beth Reinke                                                                                                                                                    |
|  43 |     73.606373 |    161.240940 | Sarah Werning                                                                                                                                                  |
|  44 |    943.006448 |    444.331153 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
|  45 |    696.706411 |    706.037809 | Kamil S. Jaron                                                                                                                                                 |
|  46 |    285.055974 |    546.786496 | Matt Wilkins                                                                                                                                                   |
|  47 |     64.711381 |    558.657504 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                      |
|  48 |    883.002657 |     59.007308 | Lafage                                                                                                                                                         |
|  49 |    708.564761 |    578.477837 | Margot Michaud                                                                                                                                                 |
|  50 |    118.878771 |    336.693669 | Scott Hartman                                                                                                                                                  |
|  51 |    740.196647 |    453.073213 | Ferran Sayol                                                                                                                                                   |
|  52 |    168.726989 |    645.685463 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                              |
|  53 |    583.400395 |    181.246623 | Jagged Fang Designs                                                                                                                                            |
|  54 |    960.094535 |    363.763787 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                |
|  55 |    617.760014 |    614.322185 | Shyamal                                                                                                                                                        |
|  56 |    958.516204 |    550.939902 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                             |
|  57 |    972.029944 |     65.241405 | Dean Schnabel                                                                                                                                                  |
|  58 |    830.479546 |    230.154359 | Chris huh                                                                                                                                                      |
|  59 |    709.494384 |    275.967441 | Danielle Alba                                                                                                                                                  |
|  60 |    806.175535 |     60.888089 | Gareth Monger                                                                                                                                                  |
|  61 |    452.511858 |    658.426848 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                              |
|  62 |    244.411392 |    275.834887 | Emily Willoughby                                                                                                                                               |
|  63 |    188.870572 |    104.788135 | Christoph Schomburg                                                                                                                                            |
|  64 |    575.457087 |    513.889157 | Shyamal                                                                                                                                                        |
|  65 |     96.935284 |    373.824460 | T. Michael Keesey                                                                                                                                              |
|  66 |     55.445932 |     73.918435 | Gareth Monger                                                                                                                                                  |
|  67 |    532.874809 |    783.324809 | Javiera Constanzo                                                                                                                                              |
|  68 |    364.052407 |    513.671985 | Jack Mayer Wood                                                                                                                                                |
|  69 |    935.417589 |    279.196277 | Scott Hartman                                                                                                                                                  |
|  70 |    826.033747 |    481.217485 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  71 |    414.850303 |    124.632117 | Jagged Fang Designs                                                                                                                                            |
|  72 |    611.068277 |    153.021754 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                            |
|  73 |    484.704487 |    721.247424 | Tasman Dixon                                                                                                                                                   |
|  74 |    605.722625 |     31.363697 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
|  75 |    854.427209 |    447.421563 | Christian A. Masnaghetti                                                                                                                                       |
|  76 |     37.841383 |    316.741653 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                           |
|  77 |    196.144725 |     22.642647 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                               |
|  78 |    252.451872 |    181.212547 | (unknown)                                                                                                                                                      |
|  79 |    167.996386 |    716.543193 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
|  80 |    765.976086 |    361.902614 | Jagged Fang Designs                                                                                                                                            |
|  81 |    286.281308 |    482.482624 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
|  82 |    644.923835 |    790.431384 | Chris huh                                                                                                                                                      |
|  83 |    457.979563 |    350.067112 | Matt Celeskey                                                                                                                                                  |
|  84 |    990.534610 |    317.513400 | Birgit Lang                                                                                                                                                    |
|  85 |    430.953426 |    164.208457 | Michelle Site                                                                                                                                                  |
|  86 |   1009.496306 |    490.344964 | NA                                                                                                                                                             |
|  87 |    307.876562 |    744.260235 | Matt Crook                                                                                                                                                     |
|  88 |    436.966995 |    317.685830 | terngirl                                                                                                                                                       |
|  89 |    820.842737 |    660.672663 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                       |
|  90 |    996.686773 |    443.248217 | Audrey Ely                                                                                                                                                     |
|  91 |     65.565248 |    467.796864 | FunkMonk                                                                                                                                                       |
|  92 |     42.858307 |    431.436981 | NA                                                                                                                                                             |
|  93 |    670.871162 |    112.546834 | Gareth Monger                                                                                                                                                  |
|  94 |     42.076269 |    213.649697 | Steven Traver                                                                                                                                                  |
|  95 |    121.026870 |    129.697107 | Scott Hartman                                                                                                                                                  |
|  96 |    510.924662 |    614.845354 | Matt Crook                                                                                                                                                     |
|  97 |    579.275435 |    757.707237 | Michelle Site                                                                                                                                                  |
|  98 |    920.705216 |    704.865843 | Gareth Monger                                                                                                                                                  |
|  99 |     27.018959 |    489.277194 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 100 |    735.092667 |     21.245643 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                    |
| 101 |    511.882706 |    751.923494 | Sarah Werning                                                                                                                                                  |
| 102 |    381.443702 |     97.525493 | Harold N Eyster                                                                                                                                                |
| 103 |    968.666955 |    758.229518 | Jagged Fang Designs                                                                                                                                            |
| 104 |    764.694447 |    754.193984 | Yan Wong                                                                                                                                                       |
| 105 |    125.892078 |    583.134746 | NA                                                                                                                                                             |
| 106 |     93.296943 |     98.150739 | Margot Michaud                                                                                                                                                 |
| 107 |   1009.619419 |    162.441930 | Yan Wong                                                                                                                                                       |
| 108 |    678.013435 |    142.611710 | Steven Coombs                                                                                                                                                  |
| 109 |    800.938548 |    600.011862 | T. Michael Keesey                                                                                                                                              |
| 110 |    386.374245 |    590.855574 | Kai R. Caspar                                                                                                                                                  |
| 111 |    671.739976 |    202.063170 | Zimices                                                                                                                                                        |
| 112 |     55.132938 |    766.572470 | Matt Crook                                                                                                                                                     |
| 113 |    656.630049 |    637.890323 | Tracy A. Heath                                                                                                                                                 |
| 114 |     88.466760 |    300.313123 | Neil Kelley                                                                                                                                                    |
| 115 |     54.665475 |    586.704112 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 116 |     26.813696 |    173.277977 | Jonathan Wells                                                                                                                                                 |
| 117 |    212.588626 |    770.861579 | (after Spotila 2004)                                                                                                                                           |
| 118 |    256.232824 |    383.444342 | Gregor Bucher, Max Farnworth                                                                                                                                   |
| 119 |    564.239688 |    392.705933 | Matt Crook                                                                                                                                                     |
| 120 |    414.887073 |    429.414880 | Chase Brownstein                                                                                                                                               |
| 121 |    113.907758 |    185.655490 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                |
| 122 |    714.697266 |    532.472193 | T. Michael Keesey                                                                                                                                              |
| 123 |    924.350463 |     84.328119 | NA                                                                                                                                                             |
| 124 |    413.213515 |    700.568515 | Terpsichores                                                                                                                                                   |
| 125 |    466.824333 |    144.442367 | Margot Michaud                                                                                                                                                 |
| 126 |    348.711483 |    689.458759 | S.Martini                                                                                                                                                      |
| 127 |    439.350164 |    480.025737 | Scott Hartman                                                                                                                                                  |
| 128 |   1008.123773 |    275.093165 | Birgit Lang                                                                                                                                                    |
| 129 |    997.973065 |     87.566277 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                               |
| 130 |     32.010408 |    390.325723 | M Kolmann                                                                                                                                                      |
| 131 |    705.673030 |    646.914300 | Aviceda (photo) & T. Michael Keesey                                                                                                                            |
| 132 |    662.846128 |    777.788728 | Steven Traver                                                                                                                                                  |
| 133 |     24.421443 |    766.654991 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 134 |    100.060908 |    558.705561 | Margot Michaud                                                                                                                                                 |
| 135 |    249.797069 |    163.468774 | Chris huh                                                                                                                                                      |
| 136 |    830.738899 |    148.962716 | Jagged Fang Designs                                                                                                                                            |
| 137 |    365.274758 |    153.944470 | Chris huh                                                                                                                                                      |
| 138 |     20.447499 |     68.867061 | Matt Crook                                                                                                                                                     |
| 139 |    661.458162 |    344.005498 | Matt Crook                                                                                                                                                     |
| 140 |    410.822637 |    345.694664 | Margot Michaud                                                                                                                                                 |
| 141 |    439.140597 |    104.053260 | Rebecca Groom                                                                                                                                                  |
| 142 |    198.867830 |    302.742797 | Gareth Monger                                                                                                                                                  |
| 143 |    270.359329 |    292.554335 | Matt Crook                                                                                                                                                     |
| 144 |     15.177045 |     94.614431 | Matt Crook                                                                                                                                                     |
| 145 |    791.200411 |    329.494708 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                   |
| 146 |    957.467141 |    784.838267 | NA                                                                                                                                                             |
| 147 |    485.318052 |    346.768322 | Matt Wilkins                                                                                                                                                   |
| 148 |    190.730925 |    237.572358 | NA                                                                                                                                                             |
| 149 |    920.959663 |    371.033606 | Matt Martyniuk                                                                                                                                                 |
| 150 |    373.955393 |    366.045422 | Ghedoghedo, vectorized by Zimices                                                                                                                              |
| 151 |    181.348033 |    771.338134 | Dave Angelini                                                                                                                                                  |
| 152 |   1010.299243 |    597.553428 | NA                                                                                                                                                             |
| 153 |    835.271671 |    749.079371 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                    |
| 154 |    623.037212 |    479.017052 | Dean Schnabel                                                                                                                                                  |
| 155 |    222.692136 |    236.496908 | Steven Traver                                                                                                                                                  |
| 156 |     21.337710 |    355.416335 | Scott Hartman                                                                                                                                                  |
| 157 |    697.023469 |    247.763931 | Tauana J. Cunha                                                                                                                                                |
| 158 |    290.909831 |    651.358495 | Christoph Schomburg                                                                                                                                            |
| 159 |    615.143693 |    542.229509 | Zachary Quigley                                                                                                                                                |
| 160 |    395.039547 |    474.789662 | Scott Reid                                                                                                                                                     |
| 161 |    149.777825 |    117.074586 | Margot Michaud                                                                                                                                                 |
| 162 |    918.282749 |    419.100004 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 163 |     48.029740 |    660.085059 | Jagged Fang Designs                                                                                                                                            |
| 164 |    584.863115 |    463.682133 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 165 |    114.314949 |    529.012555 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                           |
| 166 |    231.734092 |    125.903052 | Sebastian Stabinger                                                                                                                                            |
| 167 |    745.696011 |    487.268815 | Chris huh                                                                                                                                                      |
| 168 |    687.658113 |     77.782765 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
| 169 |    855.744720 |    736.791609 | Birgit Lang                                                                                                                                                    |
| 170 |    129.494448 |    665.540959 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                    |
| 171 |    696.736362 |    445.435813 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 172 |    448.583305 |    627.970746 | FunkMonk                                                                                                                                                       |
| 173 |    779.145525 |    630.407520 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 174 |     43.507193 |    731.382654 | Margot Michaud                                                                                                                                                 |
| 175 |    365.527708 |    726.123265 | Jaime Headden                                                                                                                                                  |
| 176 |    983.187088 |    216.847442 | NA                                                                                                                                                             |
| 177 |     98.491136 |    539.152765 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                |
| 178 |    486.944148 |    179.836000 | Maija Karala                                                                                                                                                   |
| 179 |    238.339110 |    443.556059 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 180 |    781.854118 |    279.229492 | Gareth Monger                                                                                                                                                  |
| 181 |    730.145609 |     74.279615 | Mo Hassan                                                                                                                                                      |
| 182 |    965.725617 |    149.024500 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 183 |    667.029924 |    678.750951 | Chris huh                                                                                                                                                      |
| 184 |    490.805097 |    580.211151 | T. Michael Keesey                                                                                                                                              |
| 185 |    510.434580 |    699.926570 | Christoph Schomburg                                                                                                                                            |
| 186 |    353.681746 |    474.270533 | Caio Bernardes, vectorized by Zimices                                                                                                                          |
| 187 |    175.821121 |    793.555993 | Scott Hartman                                                                                                                                                  |
| 188 |     27.220763 |    269.511066 | Lani Mohan                                                                                                                                                     |
| 189 |     90.674713 |     15.503529 | Matt Crook                                                                                                                                                     |
| 190 |    717.276172 |    502.531296 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                  |
| 191 |     13.888571 |    231.326336 | Margot Michaud                                                                                                                                                 |
| 192 |    936.176295 |    108.472716 | Ryan Cupo                                                                                                                                                      |
| 193 |    650.678581 |    585.496416 | V. Deepak                                                                                                                                                      |
| 194 |    244.696895 |    319.101833 |                                                                                                                                                                |
| 195 |    376.281780 |    528.052470 | Jesús Gómez, vectorized by Zimices                                                                                                                             |
| 196 |    842.865813 |    623.466246 | Matt Crook                                                                                                                                                     |
| 197 |    171.739915 |    410.510287 | Amanda Katzer                                                                                                                                                  |
| 198 |    620.739865 |    686.293780 | Mo Hassan                                                                                                                                                      |
| 199 |    890.977041 |    688.330984 | Daniel Stadtmauer                                                                                                                                              |
| 200 |    654.957221 |    407.706542 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 201 |    569.226177 |    350.534807 | Daniel Stadtmauer                                                                                                                                              |
| 202 |    505.000499 |    663.833539 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                         |
| 203 |    439.782238 |    491.168347 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 204 |    272.235448 |    673.735046 | Zimices                                                                                                                                                        |
| 205 |    154.846145 |    359.426248 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                   |
| 206 |    473.194277 |    320.991879 | Nobu Tamura                                                                                                                                                    |
| 207 |    629.654834 |    568.579520 | Rebecca Groom                                                                                                                                                  |
| 208 |    894.319169 |    619.342866 | Rachel Shoop                                                                                                                                                   |
| 209 |    332.980687 |    788.884737 | Tracy A. Heath                                                                                                                                                 |
| 210 |    317.503319 |    462.220327 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                       |
| 211 |    625.732901 |    188.830504 | Margot Michaud                                                                                                                                                 |
| 212 |    243.694809 |     82.057345 | NA                                                                                                                                                             |
| 213 |    833.644264 |    257.278420 | Gareth Monger                                                                                                                                                  |
| 214 |   1003.277689 |    551.664545 | Zimices                                                                                                                                                        |
| 215 |   1008.560954 |    369.684180 | Steven Traver                                                                                                                                                  |
| 216 |    356.638334 |    550.719599 | Michael Scroggie                                                                                                                                               |
| 217 |    970.449260 |    389.033156 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                     |
| 218 |     91.825713 |    446.553287 | Steven Traver                                                                                                                                                  |
| 219 |    141.809345 |    390.230319 | Chris huh                                                                                                                                                      |
| 220 |    159.266699 |     12.965852 | Gareth Monger                                                                                                                                                  |
| 221 |    719.777532 |    787.025985 | Tracy A. Heath                                                                                                                                                 |
| 222 |    747.387938 |    222.135819 | Roberto Díaz Sibaja                                                                                                                                            |
| 223 |    919.152048 |    403.043008 | Michael P. Taylor                                                                                                                                              |
| 224 |    684.885390 |    270.293994 | Siobhon Egan                                                                                                                                                   |
| 225 |    104.740928 |    639.693977 | M Kolmann                                                                                                                                                      |
| 226 |    744.410155 |    415.425742 | Zimices                                                                                                                                                        |
| 227 |    390.225079 |    302.093912 | Jagged Fang Designs                                                                                                                                            |
| 228 |    571.956616 |    441.210165 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                  |
| 229 |    473.921076 |    453.600349 | C. Camilo Julián-Caballero                                                                                                                                     |
| 230 |    322.554538 |    274.997792 | Maija Karala                                                                                                                                                   |
| 231 |    973.750277 |    173.390530 | Gareth Monger                                                                                                                                                  |
| 232 |    178.468986 |    316.985237 | Margot Michaud                                                                                                                                                 |
| 233 |    892.726019 |    664.460704 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 234 |     67.981500 |    433.171659 | Margot Michaud                                                                                                                                                 |
| 235 |    469.768755 |    769.772333 | FunkMonk                                                                                                                                                       |
| 236 |    726.496388 |    427.269659 | Scott Hartman                                                                                                                                                  |
| 237 |   1000.156856 |    449.909100 | Stuart Humphries                                                                                                                                               |
| 238 |    938.294409 |     30.624205 | Kai R. Caspar                                                                                                                                                  |
| 239 |    357.636514 |    137.398545 | Kamil S. Jaron                                                                                                                                                 |
| 240 |    821.033565 |    589.789486 | Sebastian Stabinger                                                                                                                                            |
| 241 |    660.531101 |      9.681689 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 242 |    820.888601 |    782.569032 | Rebecca Groom                                                                                                                                                  |
| 243 |    851.184180 |    429.724903 | Chris huh                                                                                                                                                      |
| 244 |    657.626819 |    267.221725 | Ludwik Gasiorowski                                                                                                                                             |
| 245 |    316.413701 |    607.177421 | TaraTaylorDesign                                                                                                                                               |
| 246 |    868.641233 |    774.012790 | Tracy A. Heath                                                                                                                                                 |
| 247 |    423.005405 |    690.866583 | Birgit Lang                                                                                                                                                    |
| 248 |     59.403112 |    342.788838 | G. M. Woodward                                                                                                                                                 |
| 249 |    576.623511 |    207.878059 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                |
| 250 |    607.683784 |    137.838264 | Zachary Quigley                                                                                                                                                |
| 251 |    649.947627 |    721.924076 | Margot Michaud                                                                                                                                                 |
| 252 |    849.882467 |    378.362592 | NA                                                                                                                                                             |
| 253 |    992.697288 |    244.217258 | Kai R. Caspar                                                                                                                                                  |
| 254 |    687.658699 |    660.724627 | Andrew A. Farke                                                                                                                                                |
| 255 |    908.770703 |    379.925181 | Jagged Fang Designs                                                                                                                                            |
| 256 |    700.015129 |    514.223579 | Jagged Fang Designs                                                                                                                                            |
| 257 |    646.272583 |    379.291590 | Gareth Monger                                                                                                                                                  |
| 258 |    670.610144 |    732.607389 | John Gould (vectorized by T. Michael Keesey)                                                                                                                   |
| 259 |    139.713813 |    569.104225 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                 |
| 260 |    697.853448 |    669.686210 | Jagged Fang Designs                                                                                                                                            |
| 261 |    659.106023 |     90.819998 | Chris huh                                                                                                                                                      |
| 262 |    225.973335 |    202.993285 | ArtFavor & annaleeblysse                                                                                                                                       |
| 263 |    804.815922 |    141.013176 | Auckland Museum and T. Michael Keesey                                                                                                                          |
| 264 |   1006.529236 |     46.576516 | Margot Michaud                                                                                                                                                 |
| 265 |    778.266354 |    223.951063 | Tyler Greenfield and Scott Hartman                                                                                                                             |
| 266 |    270.710950 |    784.788218 | Scott Hartman                                                                                                                                                  |
| 267 |    642.084281 |    742.390901 | Matt Dempsey                                                                                                                                                   |
| 268 |    767.781334 |    719.145583 | Jagged Fang Designs                                                                                                                                            |
| 269 |    406.803476 |     12.012299 | NA                                                                                                                                                             |
| 270 |    924.143319 |    317.774352 | Margot Michaud                                                                                                                                                 |
| 271 |   1007.519492 |    786.278876 | NA                                                                                                                                                             |
| 272 |    144.077474 |    312.319678 | Mathieu Basille                                                                                                                                                |
| 273 |    546.346995 |    460.305425 | Smokeybjb (modified by Mike Keesey)                                                                                                                            |
| 274 |    932.336825 |    241.421094 | Zimices                                                                                                                                                        |
| 275 |    661.300645 |    763.559843 | Steven Traver                                                                                                                                                  |
| 276 |    412.001911 |    454.806158 | Zimices                                                                                                                                                        |
| 277 |    938.849790 |    258.558058 | Margot Michaud                                                                                                                                                 |
| 278 |    126.213043 |    707.041706 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                       |
| 279 |    793.934751 |    386.433472 | Henry Lydecker                                                                                                                                                 |
| 280 |    929.005997 |    558.301347 | Matt Crook                                                                                                                                                     |
| 281 |    602.921307 |    778.267210 | Steven Traver                                                                                                                                                  |
| 282 |    281.519554 |    310.759634 | Eric Moody                                                                                                                                                     |
| 283 |    356.734385 |    714.752197 | Zachary Quigley                                                                                                                                                |
| 284 |    996.662968 |    766.583942 | Matt Crook                                                                                                                                                     |
| 285 |    235.551846 |    525.894521 | Tyler Greenfield                                                                                                                                               |
| 286 |    307.278031 |    663.100872 | NA                                                                                                                                                             |
| 287 |    370.339195 |    387.804084 | Danielle Alba                                                                                                                                                  |
| 288 |    550.119591 |    625.647480 | Gabriela Palomo-Munoz                                                                                                                                          |
| 289 |     96.283282 |    214.280521 | Scott Hartman                                                                                                                                                  |
| 290 |    226.458540 |     61.071102 | Ferran Sayol                                                                                                                                                   |
| 291 |    372.010910 |    169.800055 | Ferran Sayol                                                                                                                                                   |
| 292 |    528.581244 |    416.217911 | Ferran Sayol                                                                                                                                                   |
| 293 |    295.433010 |     12.649005 | Scott Hartman                                                                                                                                                  |
| 294 |    304.310686 |     45.853630 | Chris huh                                                                                                                                                      |
| 295 |    765.336254 |    787.156889 | Ingo Braasch                                                                                                                                                   |
| 296 |    695.511051 |    213.471532 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 297 |    141.774486 |    460.121767 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 298 |    509.208118 |      6.226855 | Gabriela Palomo-Munoz                                                                                                                                          |
| 299 |    791.548181 |    184.120036 | Michelle Site                                                                                                                                                  |
| 300 |    287.534634 |    461.125794 | Gabriela Palomo-Munoz                                                                                                                                          |
| 301 |    976.964909 |    751.205534 | Steven Traver                                                                                                                                                  |
| 302 |    798.187276 |    749.395208 | Michelle Site                                                                                                                                                  |
| 303 |    119.997325 |    488.965724 | Steven Traver                                                                                                                                                  |
| 304 |    783.662134 |     65.009373 | Steven Traver                                                                                                                                                  |
| 305 |    615.073286 |     69.990092 | Gareth Monger                                                                                                                                                  |
| 306 |    981.144089 |    197.285889 | Zimices                                                                                                                                                        |
| 307 |     20.125884 |    624.038073 | Tasman Dixon                                                                                                                                                   |
| 308 |    623.455311 |    720.485189 | Roberto Díaz Sibaja                                                                                                                                            |
| 309 |     45.670335 |    747.112798 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                |
| 310 |    279.594038 |    368.466594 | Gareth Monger                                                                                                                                                  |
| 311 |    949.887883 |    669.419426 | Gareth Monger                                                                                                                                                  |
| 312 |    145.709718 |    654.258629 | Gareth Monger                                                                                                                                                  |
| 313 |   1012.261138 |    686.162616 | Gareth Monger                                                                                                                                                  |
| 314 |    423.997416 |    633.313173 | Mo Hassan                                                                                                                                                      |
| 315 |    663.581311 |    692.258319 | Michael Scroggie                                                                                                                                               |
| 316 |     69.603582 |    743.749741 | Jagged Fang Designs                                                                                                                                            |
| 317 |    263.830379 |    203.191271 | Gareth Monger                                                                                                                                                  |
| 318 |   1007.897026 |    745.800248 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 319 |    784.238680 |    369.827161 | Zimices                                                                                                                                                        |
| 320 |    987.680555 |    480.847438 | Matt Crook                                                                                                                                                     |
| 321 |    331.044940 |     61.926525 | Duane Raver/USFWS                                                                                                                                              |
| 322 |    844.101153 |    708.431663 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 323 |    659.217246 |    536.434379 | Scott Hartman                                                                                                                                                  |
| 324 |    149.942875 |    682.404789 | Michelle Site                                                                                                                                                  |
| 325 |    887.596531 |    596.248039 | Gabriela Palomo-Munoz                                                                                                                                          |
| 326 |    395.052944 |    669.547344 | Matt Crook                                                                                                                                                     |
| 327 |     30.199571 |    284.720364 | Matt Crook                                                                                                                                                     |
| 328 |    680.511167 |    179.970905 | Gabriela Palomo-Munoz                                                                                                                                          |
| 329 |    158.337054 |    136.003595 | NA                                                                                                                                                             |
| 330 |     58.419179 |     10.951556 | Gareth Monger                                                                                                                                                  |
| 331 |    529.587320 |    539.213069 | Matt Crook                                                                                                                                                     |
| 332 |     17.818491 |    370.285179 | Stacy Spensley (Modified)                                                                                                                                      |
| 333 |    585.894926 |    371.902754 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                               |
| 334 |    411.605214 |    144.403937 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                             |
| 335 |    701.812302 |    158.543413 | T. Michael Keesey                                                                                                                                              |
| 336 |    298.870275 |    705.151664 | Margot Michaud                                                                                                                                                 |
| 337 |    442.896583 |    771.534611 | Ferran Sayol                                                                                                                                                   |
| 338 |     17.853626 |    127.402971 | Steven Coombs                                                                                                                                                  |
| 339 |    475.793580 |    757.857496 | Zimices                                                                                                                                                        |
| 340 |    792.173636 |    465.338250 | Gareth Monger                                                                                                                                                  |
| 341 |    332.127215 |     42.547311 | C. Camilo Julián-Caballero                                                                                                                                     |
| 342 |    209.186182 |      9.189691 | Margot Michaud                                                                                                                                                 |
| 343 |    479.211423 |    311.207634 | Chris huh                                                                                                                                                      |
| 344 |    895.344957 |    636.506185 | Chris huh                                                                                                                                                      |
| 345 |     16.100935 |    544.840821 | NA                                                                                                                                                             |
| 346 |    149.457285 |    785.022054 | Jagged Fang Designs                                                                                                                                            |
| 347 |    883.693234 |    417.351199 | Chris huh                                                                                                                                                      |
| 348 |   1007.933794 |    246.967448 | Ferran Sayol                                                                                                                                                   |
| 349 |    178.561649 |    120.267140 | Becky Barnes                                                                                                                                                   |
| 350 |    137.676180 |    636.088261 | Maija Karala                                                                                                                                                   |
| 351 |    320.724414 |    116.214686 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 352 |     70.618816 |    715.755812 | Scott Hartman                                                                                                                                                  |
| 353 |      9.796862 |    334.314575 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 354 |    852.077393 |    666.173548 | Christoph Schomburg                                                                                                                                            |
| 355 |    977.031084 |    341.980291 | Gareth Monger                                                                                                                                                  |
| 356 |    265.654752 |    349.682041 | Scott Hartman                                                                                                                                                  |
| 357 |    790.474104 |     94.016076 | Michael Day                                                                                                                                                    |
| 358 |    894.526367 |    452.493706 | Zimices                                                                                                                                                        |
| 359 |    991.772334 |      3.892580 | Yan Wong from illustration by Jules Richard (1907)                                                                                                             |
| 360 |    214.082037 |     38.650007 | Roberto Díaz Sibaja                                                                                                                                            |
| 361 |    828.300285 |    609.379337 | Ingo Braasch                                                                                                                                                   |
| 362 |    911.982109 |     17.548863 | Zimices                                                                                                                                                        |
| 363 |    233.875330 |     29.951587 | Felix Vaux                                                                                                                                                     |
| 364 |    552.440665 |    206.062464 | Scott Hartman                                                                                                                                                  |
| 365 |    522.330194 |    392.812322 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                |
| 366 |      9.531578 |    192.002240 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                 |
| 367 |    569.937286 |    685.539872 | Zimices                                                                                                                                                        |
| 368 |     83.918903 |    582.268458 | Matt Crook                                                                                                                                                     |
| 369 |    825.202336 |    134.528178 | Zimices                                                                                                                                                        |
| 370 |     84.349437 |    493.795173 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                  |
| 371 |    579.780013 |    326.620782 | Christoph Schomburg                                                                                                                                            |
| 372 |    546.635053 |    449.684349 | NA                                                                                                                                                             |
| 373 |    216.291687 |    158.454010 | Kamil S. Jaron                                                                                                                                                 |
| 374 |    383.855006 |    710.489596 | Margot Michaud                                                                                                                                                 |
| 375 |    815.529372 |    457.667578 | Gareth Monger                                                                                                                                                  |
| 376 |    882.475938 |      4.563639 | Daniel Stadtmauer                                                                                                                                              |
| 377 |    353.227525 |    744.677898 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 378 |    920.596044 |    225.213872 | Steven Coombs                                                                                                                                                  |
| 379 |   1007.169282 |    637.106671 | Chris huh                                                                                                                                                      |
| 380 |    232.709783 |    351.750276 | Felix Vaux                                                                                                                                                     |
| 381 |    808.703799 |    753.652832 | Gopal Murali                                                                                                                                                   |
| 382 |    668.699648 |    521.821711 | Matt Crook                                                                                                                                                     |
| 383 |    888.018442 |    427.620585 | Zachary Quigley                                                                                                                                                |
| 384 |      4.921485 |    512.271832 | T. Michael Keesey                                                                                                                                              |
| 385 |    939.480046 |     73.711063 | Zimices                                                                                                                                                        |
| 386 |    790.999127 |    652.183893 | Birgit Lang                                                                                                                                                    |
| 387 |    650.999430 |    131.685328 | Michael P. Taylor                                                                                                                                              |
| 388 |   1002.421066 |    589.222261 | Lauren Anderson                                                                                                                                                |
| 389 |    490.382571 |    643.043457 | Alex Slavenko                                                                                                                                                  |
| 390 |    249.124775 |    138.676344 | Gareth Monger                                                                                                                                                  |
| 391 |    844.841948 |    508.928351 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 392 |     74.880115 |    196.908704 | Kent Elson Sorgon                                                                                                                                              |
| 393 |     52.110940 |    415.300110 | Shyamal                                                                                                                                                        |
| 394 |    993.820245 |    507.357490 | Birgit Lang                                                                                                                                                    |
| 395 |    776.432090 |    212.165576 | Jack Mayer Wood                                                                                                                                                |
| 396 |    119.547989 |    301.584903 | Birgit Lang                                                                                                                                                    |
| 397 |    254.770068 |    659.725309 | Scott Hartman                                                                                                                                                  |
| 398 |    605.798770 |    226.248840 | Ville Koistinen and T. Michael Keesey                                                                                                                          |
| 399 |    856.359466 |      8.862258 | Jagged Fang Designs                                                                                                                                            |
| 400 |    720.276739 |    235.932751 | Cagri Cevrim                                                                                                                                                   |
| 401 |     16.347207 |     31.288121 | Sean McCann                                                                                                                                                    |
| 402 |    724.754002 |    682.843222 | Kamil S. Jaron                                                                                                                                                 |
| 403 |    933.943218 |     57.977479 | Zimices                                                                                                                                                        |
| 404 |    552.467836 |    662.066529 | FunkMonk                                                                                                                                                       |
| 405 |    399.415319 |    561.325437 | Nobu Tamura                                                                                                                                                    |
| 406 |    684.856163 |    356.656982 | Armin Reindl                                                                                                                                                   |
| 407 |    257.137742 |    568.963680 | Margot Michaud                                                                                                                                                 |
| 408 |    740.329304 |    640.218467 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 409 |    118.487648 |    598.671889 | C. Abraczinskas                                                                                                                                                |
| 410 |     41.187417 |    718.113810 | Jaime Headden                                                                                                                                                  |
| 411 |    688.790128 |    407.759168 | Scott Hartman                                                                                                                                                  |
| 412 |    806.975474 |    292.073923 | Jake Warner                                                                                                                                                    |
| 413 |    594.598288 |    191.253156 | Matt Crook                                                                                                                                                     |
| 414 |    506.895408 |    140.577753 | FunkMonk                                                                                                                                                       |
| 415 |    188.390212 |    290.184884 | Christoph Schomburg                                                                                                                                            |
| 416 |    286.681497 |    695.023261 | Dmitry Bogdanov                                                                                                                                                |
| 417 |    149.873214 |    666.616424 | Jagged Fang Designs                                                                                                                                            |
| 418 |     10.081453 |    436.473664 | Felix Vaux                                                                                                                                                     |
| 419 |    883.239317 |    511.524744 | Blanco et al., 2014, vectorized by Zimices                                                                                                                     |
| 420 |     56.749772 |    501.893297 | FunkMonk (Michael B. H.)                                                                                                                                       |
| 421 |    509.417342 |    161.992230 | NA                                                                                                                                                             |
| 422 |    389.943330 |    150.305378 | T. Michael Keesey                                                                                                                                              |
| 423 |    810.793419 |    159.495940 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                          |
| 424 |    108.033321 |     27.379784 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 425 |    586.238560 |    342.295483 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 426 |    794.647640 |    451.428289 | Chris huh                                                                                                                                                      |
| 427 |    391.606678 |    498.038708 | Henry Lydecker                                                                                                                                                 |
| 428 |    253.106507 |    455.955393 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                  |
| 429 |    981.472698 |    286.701607 | Zimices                                                                                                                                                        |
| 430 |    459.095078 |    121.751544 | Jagged Fang Designs                                                                                                                                            |
| 431 |    528.098257 |     18.512267 | CNZdenek                                                                                                                                                       |
| 432 |    436.517565 |    139.764174 | Zimices                                                                                                                                                        |
| 433 |    660.097122 |    747.912798 | Chris huh                                                                                                                                                      |
| 434 |    476.575594 |    566.508680 | Zimices                                                                                                                                                        |
| 435 |    539.299357 |    190.065823 | Birgit Lang                                                                                                                                                    |
| 436 |    268.217087 |    558.506729 | Robert Gay                                                                                                                                                     |
| 437 |     91.108820 |    359.554319 | Scott Hartman                                                                                                                                                  |
| 438 |    194.088727 |    756.126943 | T. Michael Keesey                                                                                                                                              |
| 439 |    131.430291 |    516.815853 | Tasman Dixon                                                                                                                                                   |
| 440 |   1002.368683 |    186.699915 | Gareth Monger                                                                                                                                                  |
| 441 |    138.544446 |     19.499072 | Gareth Monger                                                                                                                                                  |
| 442 |    123.444628 |      8.598748 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                             |
| 443 |    922.326770 |    774.919029 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 444 |    895.486788 |    241.939191 | Tasman Dixon                                                                                                                                                   |
| 445 |    153.137555 |    403.369479 | David Tana                                                                                                                                                     |
| 446 |     85.831124 |    389.647692 | John Conway                                                                                                                                                    |
| 447 |    258.538909 |    767.915378 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 448 |    117.073577 |    549.452616 | Yan Wong                                                                                                                                                       |
| 449 |    770.141987 |     79.307238 | Chris huh                                                                                                                                                      |
| 450 |    994.177320 |    460.766484 | Raven Amos                                                                                                                                                     |
| 451 |    110.144932 |    388.178907 | Noah Schlottman, photo by Antonio Guillén                                                                                                                      |
| 452 |    489.832058 |    377.892029 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 453 |    151.660995 |    775.286702 | Chris huh                                                                                                                                                      |
| 454 |    668.846833 |    291.226712 | Matt Crook                                                                                                                                                     |
| 455 |    227.994629 |    779.604040 | Filip em                                                                                                                                                       |
| 456 |    374.814977 |    344.273200 | Gareth Monger                                                                                                                                                  |
| 457 |    761.095597 |     41.776704 | Matt Crook                                                                                                                                                     |
| 458 |    125.564409 |    732.841921 | Tasman Dixon                                                                                                                                                   |
| 459 |    242.486970 |    212.299680 | Gareth Monger                                                                                                                                                  |
| 460 |    649.512767 |    707.054246 | Pete Buchholz                                                                                                                                                  |
| 461 |     34.528120 |    400.431438 | Margot Michaud                                                                                                                                                 |
| 462 |    872.203991 |    619.352043 | NA                                                                                                                                                             |
| 463 |    364.662648 |    297.097497 | Jaime Headden                                                                                                                                                  |
| 464 |    385.764570 |    540.065169 | Jagged Fang Designs                                                                                                                                            |
| 465 |    917.825766 |    215.777771 | Iain Reid                                                                                                                                                      |
| 466 |    257.583049 |    539.581517 | Scott Hartman                                                                                                                                                  |
| 467 |     95.000979 |    791.480184 | Mathew Wedel                                                                                                                                                   |
| 468 |    631.685085 |    773.768218 | Tracy A. Heath                                                                                                                                                 |
| 469 |    899.673594 |     36.835040 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 470 |    984.292224 |    133.761045 | S.Martini                                                                                                                                                      |
| 471 |     80.141383 |     72.669738 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 472 |    862.092387 |    281.832539 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                          |
| 473 |    876.462695 |    376.406188 | Ferran Sayol                                                                                                                                                   |
| 474 |    450.749728 |    699.118988 | Steven Coombs                                                                                                                                                  |
| 475 |     18.287064 |    671.400396 | Tasman Dixon                                                                                                                                                   |
| 476 |    641.329186 |     77.439843 | (after Spotila 2004)                                                                                                                                           |
| 477 |    833.880916 |    771.411169 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 478 |    653.008931 |    185.023981 | L. Shyamal                                                                                                                                                     |
| 479 |    488.534658 |    601.828348 | Matt Crook                                                                                                                                                     |
| 480 |     15.053923 |    257.372453 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                    |
| 481 |    199.044491 |    790.088855 | Gareth Monger                                                                                                                                                  |
| 482 |    266.492571 |    108.710932 | Gabriela Palomo-Munoz                                                                                                                                          |
| 483 |    579.440925 |      3.542499 | Scott Hartman                                                                                                                                                  |
| 484 |    743.934275 |    725.398641 | Rebecca Groom                                                                                                                                                  |
| 485 |    204.108543 |     94.190615 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
| 486 |    930.506081 |    438.149345 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 487 |    548.639490 |    695.172482 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                         |
| 488 |    651.434443 |    488.750908 | Matt Crook                                                                                                                                                     |
| 489 |    300.367648 |    787.503705 | Dean Schnabel                                                                                                                                                  |
| 490 |    819.780178 |    753.867216 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                          |
| 491 |    357.821402 |      6.641928 | Todd Marshall, vectorized by Zimices                                                                                                                           |
| 492 |    649.558138 |    732.768176 | Scott Hartman                                                                                                                                                  |
| 493 |    363.490177 |    732.056900 | Tasman Dixon                                                                                                                                                   |
| 494 |    150.307333 |    340.515849 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 495 |    379.182300 |     88.122782 | Scott Hartman                                                                                                                                                  |
| 496 |    108.486323 |    112.617012 | Sarah Alewijnse                                                                                                                                                |
| 497 |    657.702725 |    325.540929 | Jagged Fang Designs                                                                                                                                            |
| 498 |    387.295664 |    552.793564 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 499 |    185.159980 |    425.676411 | Steven Traver                                                                                                                                                  |
| 500 |    466.790625 |    779.975841 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                         |
| 501 |     53.981296 |    359.995396 | Scott Hartman                                                                                                                                                  |
| 502 |    445.507921 |    467.888297 | Jagged Fang Designs                                                                                                                                            |
| 503 |    234.768303 |    433.665472 | Scott Hartman                                                                                                                                                  |
| 504 |    936.161752 |      5.045067 | Julia B McHugh                                                                                                                                                 |
| 505 |    535.851263 |    161.059380 | Scott Hartman                                                                                                                                                  |
| 506 |    413.698475 |    445.801162 | NA                                                                                                                                                             |
| 507 |     15.931812 |     13.400798 | Margot Michaud                                                                                                                                                 |
| 508 |    674.574094 |    380.743503 | Margot Michaud                                                                                                                                                 |
| 509 |    443.605632 |    450.404085 | Gareth Monger                                                                                                                                                  |
| 510 |    949.961353 |    642.693187 | Tasman Dixon                                                                                                                                                   |
| 511 |    411.086441 |    367.050704 | Zimices                                                                                                                                                        |
| 512 |    170.066626 |    744.864080 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                              |
| 513 |     12.088754 |    645.523492 | Gareth Monger                                                                                                                                                  |
| 514 |    703.499679 |     11.987738 | T. Michael Keesey                                                                                                                                              |
| 515 |    820.391333 |     76.828883 | L. Shyamal                                                                                                                                                     |
| 516 |    668.360583 |    372.200566 | Geoff Shaw                                                                                                                                                     |
| 517 |     92.593540 |    725.149616 | Jagged Fang Designs                                                                                                                                            |
| 518 |    576.853189 |    627.167828 | Iain Reid                                                                                                                                                      |
| 519 |    616.828693 |    395.893238 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 520 |    416.875356 |    617.661640 | Zimices                                                                                                                                                        |
| 521 |    923.759332 |     34.926884 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 522 |     43.416089 |    607.451486 | Tasman Dixon                                                                                                                                                   |
| 523 |    764.668657 |    378.522897 | Chris huh                                                                                                                                                      |
| 524 |   1007.528094 |    646.126953 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                |

I am currently testing the above. Once I am sure it is working I will
add some code to automatically print out the names of all the artists
who produced the silhouette images above (credit where credit is due\!).
