
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

Chris huh, Carlos Cano-Barbacil, Beth Reinke, Maxwell Lefroy (vectorized
by T. Michael Keesey), Margot Michaud, Zimices, T. Michael Keesey, Matt
Martyniuk (vectorized by T. Michael Keesey), Nick Schooler, Birgit Lang,
Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Steven Traver, Matt Crook, Anthony Caravaggi, Jose
Carlos Arenas-Monroy, Sarah Werning, Mathew Wedel, Shyamal, Alexander
Schmidt-Lebuhn, Milton Tan, T. Michael Keesey (after Kukalová), Trond R.
Oskars, L. Shyamal, Katie S. Collins, Roderic Page and Lois Page, Chase
Brownstein, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), xgirouxb, Nobu Tamura
(vectorized by T. Michael Keesey), T. Michael Keesey (after Walker &
al.), Rebecca Groom, kreidefossilien.de, Jagged Fang Designs, Ingo
Braasch, Scott Hartman, Gareth Monger, Tasman Dixon, Myriam\_Ramirez,
Skye McDavid, Markus A. Grohme, Siobhon Egan, Lafage, Robert Gay, Jon
Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>),
Catherine Yasuda, Michael Scroggie, Ferran Sayol, Allison Pease,
Gabriela Palomo-Munoz, (unknown), Armin Reindl, Christopher Chávez,
Josefine Bohr Brask, Haplochromis (vectorized by T. Michael Keesey),
Ludwik Gąsiorowski, Ignacio Contreras, Andy Wilson, Darren Naish
(vectorized by T. Michael Keesey), Lukasiniho, Steven Coombs, Thea
Boodhoo (photograph) and T. Michael Keesey (vectorization), Tony Ayling,
S.Martini, Jiekun He, Xavier Giroux-Bougard, Nobu Tamura and T. Michael
Keesey, J Levin W (illustration) and T. Michael Keesey (vectorization),
wsnaccad, Maxime Dahirel, Christoph Schomburg, Estelle Bourdon, Ghedo
(vectorized by T. Michael Keesey), T. Tischler, Stacy Spensley
(Modified), Andrew A. Farke, Dmitry Bogdanov (vectorized by T. Michael
Keesey), John Conway, Nobu Tamura, vectorized by Zimices, Mali’o Kodis,
image from Higgins and Kristensen, 1986, Maija Karala, Auckland Museum,
Noah Schlottman, photo by Reinhard Jahn, Oliver Voigt, T. Michael Keesey
(vectorization); Yves Bousquet (photography), Tarique Sani (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, David
Orr, Andrew A. Farke, modified from original by Robert Bruce Horsfall,
from Scott 1912, Michael P. Taylor, Dean Schnabel, Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Martin R. Smith, Smokeybjb, Felix
Vaux, Chloé Schmidt, Javier Luque, Melissa Broussard, Yan Wong, Mali’o
Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Jebulon (vectorized by
T. Michael Keesey), Lauren Anderson, T. Michael Keesey (vectorization)
and Nadiatalent (photography), Sharon Wegner-Larsen, Emma Kissling,
Terpsichores, Tony Ayling (vectorized by T. Michael Keesey), Francisco
Gascó (modified by Michael P. Taylor), FunkMonk, Jaime Headden,
\[unknown\], Dianne Bray / Museum Victoria (vectorized by T. Michael
Keesey), Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Tracy A. Heath, Matt Martyniuk, Mathilde Cordellier,
Robbie N. Cada (modified by T. Michael Keesey), Pearson Scott Foresman
(vectorized by T. Michael Keesey), Alexandre Vong, Dmitry Bogdanov, Iain
Reid, Andreas Trepte (vectorized by T. Michael Keesey), Heinrich Harder
(vectorized by William Gearty), CNZdenek, Emily Willoughby, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist, Conty
(vectorized by T. Michael Keesey), Matt Hayes, Gopal Murali, JCGiron,
Michelle Site, ДиБгд (vectorized by T. Michael Keesey), Jack Mayer Wood,
M. A. Broussard, Martien Brand (original photo), Renato Santos (vector
silhouette), Chuanixn Yu, J. J. Harrison (photo) & T. Michael Keesey,
Pete Buchholz, Neil Kelley, DW Bapst (Modified from Bulman, 1964),
Collin Gross, Juan Carlos Jerí, Matt Wilkins, Tess Linden, Roberto Díaz
Sibaja, Scott Reid, Liftarn, Renata F. Martins, Jaime Headden, modified
by T. Michael Keesey, Antonov (vectorized by T. Michael Keesey), Gabriel
Lio, vectorized by Zimices, Cathy, Anilocra (vectorization by Yan Wong),
Maha Ghazal, Kailah Thorn & Ben King, Jean-Raphaël Guillaumin
(photography) and T. Michael Keesey (vectorization), Joanna Wolfe, Jaime
A. Headden (vectorized by T. Michael Keesey), Luc Viatour (source photo)
and Andreas Plank, Manabu Sakamoto, DW Bapst (modified from Bulman,
1970), Dexter R. Mardis, Natalie Claunch, Dr. Thomas G. Barnes, USFWS,
Hans Hillewaert, Mali’o Kodis, photograph by Hans Hillewaert, C. Camilo
Julián-Caballero, Richard Lampitt, Jeremy Young / NHM (vectorization by
Yan Wong), Mark Miller, Tod Robbins, Cesar Julian, M Kolmann, Matt
Celeskey, SecretJellyMan - from Mason McNair, Wayne Decatur,
SecretJellyMan, Noah Schlottman, photo by Martin V. Sørensen, Brad
McFeeters (vectorized by T. Michael Keesey), Diego Fontaneto, Elisabeth
A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Stuart Humphries, DW Bapst (modified from Mitchell 1990), Lukas
Panzarin, Raven Amos, Kanchi Nanjo, Curtis Clark and T. Michael Keesey,
Caleb M. Gordon, david maas / dave hone, Tauana J. Cunha, Kai R. Caspar,
T. Michael Keesey (after Mauricio Antón), Martin Kevil, Mathieu
Pélissié, Darren Naish, Nemo, and T. Michael Keesey, Benjamint444,
Peileppe, Meliponicultor Itaymbere, Warren H (photography), T. Michael
Keesey (vectorization), . Original drawing by M. Antón, published in
Montoya and Morales 1984. Vectorized by O. Sanisidro, L.M. Davalos,
Darren Naish (vectorize by T. Michael Keesey), Hans Hillewaert
(vectorized by T. Michael Keesey), Didier Descouens (vectorized by T.
Michael Keesey), Rainer Schoch, Hugo Gruson, Enoch Joseph Wetsy (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Mali’o
Kodis, drawing by Manvir Singh, Steven Blackwood, Jake Warner, Prathyush
Thomas, Mason McNair, FJDegrange, Nobu Tamura (modified by T. Michael
Keesey), Michael Day, Amanda Katzer, Francis de Laporte de Castelnau
(vectorized by T. Michael Keesey), Ben Liebeskind, David Liao, Kamil S.
Jaron, Harold N Eyster, Kelly, Ian Burt (original) and T. Michael Keesey
(vectorization), Ray Simpson (vectorized by T. Michael Keesey), Sean
McCann, NOAA (vectorized by T. Michael Keesey), Arthur S. Brum, Berivan
Temiz, Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman),
SauropodomorphMonarch, Agnello Picorelli, Kosta Mumcuoglu (vectorized by
T. Michael Keesey), Mariana Ruiz Villarreal, Obsidian Soul (vectorized
by T. Michael Keesey), Kent Elson Sorgon, Danny Cicchetti (vectorized by
T. Michael Keesey), Xvazquez (vectorized by William Gearty), U.S.
National Park Service (vectorized by William Gearty), Sergio A.
Muñoz-Gómez, Jessica Anne Miller, Pollyanna von Knorring and T.
Michael Keesey, T. Michael Keesey (after Marek Velechovský), Taro Maeda,
Alex Slavenko, Caleb M. Brown, Alexis Simon, Servien (vectorized by T.
Michael Keesey), Pranav Iyer (grey ideas), Becky Barnes, Nobu Tamura
(vectorized by A. Verrière), Tim Bertelink (modified by T. Michael
Keesey), Noah Schlottman, photo from Casey Dunn, Fir0002/Flagstaffotos
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Erika Schumacher, Jakovche, Meyers Konversations-Lexikon 1897
(vectorized: Yan Wong), Douglas Brown (modified by T. Michael Keesey),
Lauren Sumner-Rooney, T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Mette Aumala, Brian
Swartz (vectorized by T. Michael Keesey), Tyler Greenfield, Mali’o
Kodis, photograph by Bruno Vellutini, T. Michael Keesey (photo by Bc999
\[Black crow\]), T. Michael Keesey, from a photograph by Thea Boodhoo,
James Neenan, Geoff Shaw, Taenadoman, Isaure Scavezzoni, Chris Jennings
(Risiatto), Henry Lydecker, Manabu Bessho-Uehara, Sherman F. Denton via
rawpixel.com (illustration) and Timothy J. Bartley (silhouette), Dori
<dori@merr.info> (source photo) and Nevit Dilmen, Chris Jennings
(vectorized by A. Verrière), Ville Koistinen and T. Michael Keesey, Yan
Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo),
White Wolf, Dmitry Bogdanov (modified by T. Michael Keesey), Вальдимар
(vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    434.257714 |    505.146375 | Chris huh                                                                                                                                                             |
|   2 |    665.487802 |    697.675134 | Carlos Cano-Barbacil                                                                                                                                                  |
|   3 |    831.374068 |    300.322460 | Beth Reinke                                                                                                                                                           |
|   4 |    116.922290 |    428.862893 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
|   5 |    523.793632 |    549.115865 | Margot Michaud                                                                                                                                                        |
|   6 |    912.349442 |    510.401219 | Zimices                                                                                                                                                               |
|   7 |    845.899409 |    114.193479 | NA                                                                                                                                                                    |
|   8 |    526.435176 |    349.042348 | T. Michael Keesey                                                                                                                                                     |
|   9 |    413.403048 |    226.583383 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
|  10 |    313.046345 |    619.129673 | Nick Schooler                                                                                                                                                         |
|  11 |    782.843549 |    598.482548 | Birgit Lang                                                                                                                                                           |
|  12 |    148.806083 |    716.179189 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
|  13 |    202.087110 |    305.571381 | Zimices                                                                                                                                                               |
|  14 |    370.792953 |    714.942510 | Zimices                                                                                                                                                               |
|  15 |    943.984964 |    437.570896 | Steven Traver                                                                                                                                                         |
|  16 |    527.920431 |    687.676669 | Matt Crook                                                                                                                                                            |
|  17 |    167.398181 |    154.042074 | Anthony Caravaggi                                                                                                                                                     |
|  18 |    554.427815 |    140.043819 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  19 |    690.767824 |    489.481235 | Sarah Werning                                                                                                                                                         |
|  20 |    945.691066 |    671.630951 | NA                                                                                                                                                                    |
|  21 |     75.028905 |    639.649070 | Mathew Wedel                                                                                                                                                          |
|  22 |    748.876831 |    115.139375 | Shyamal                                                                                                                                                               |
|  23 |     60.635637 |    305.025698 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  24 |    383.461561 |    389.635619 | Steven Traver                                                                                                                                                         |
|  25 |    486.254406 |     45.870141 | Milton Tan                                                                                                                                                            |
|  26 |     58.877678 |    104.622897 | NA                                                                                                                                                                    |
|  27 |    252.309983 |    704.785968 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
|  28 |    562.515436 |    280.077881 | Trond R. Oskars                                                                                                                                                       |
|  29 |    771.578316 |    247.774046 | L. Shyamal                                                                                                                                                            |
|  30 |     62.069294 |    541.746066 | Katie S. Collins                                                                                                                                                      |
|  31 |    470.306385 |    234.305273 | Roderic Page and Lois Page                                                                                                                                            |
|  32 |    945.549160 |    130.993730 | Steven Traver                                                                                                                                                         |
|  33 |    828.782507 |    727.346271 | Chase Brownstein                                                                                                                                                      |
|  34 |    217.698195 |    394.055415 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  35 |    648.714157 |    344.582423 | xgirouxb                                                                                                                                                              |
|  36 |    146.073959 |    771.010630 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  37 |    777.102749 |    494.725862 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
|  38 |    474.899746 |    617.542946 | Matt Crook                                                                                                                                                            |
|  39 |    330.336880 |    105.435199 | Rebecca Groom                                                                                                                                                         |
|  40 |    235.566345 |     35.426564 | Zimices                                                                                                                                                               |
|  41 |    928.990817 |    248.778014 | NA                                                                                                                                                                    |
|  42 |    911.114179 |    363.952920 | NA                                                                                                                                                                    |
|  43 |    155.384052 |    508.015433 | kreidefossilien.de                                                                                                                                                    |
|  44 |    769.968542 |    651.678335 | Jagged Fang Designs                                                                                                                                                   |
|  45 |    741.097954 |    385.464984 | Zimices                                                                                                                                                               |
|  46 |    267.629805 |    438.403863 | Ingo Braasch                                                                                                                                                          |
|  47 |    325.257700 |    320.839323 | Scott Hartman                                                                                                                                                         |
|  48 |    110.895701 |    227.339421 | Scott Hartman                                                                                                                                                         |
|  49 |    654.095127 |     72.071026 | Gareth Monger                                                                                                                                                         |
|  50 |    677.327249 |    597.287988 | Matt Crook                                                                                                                                                            |
|  51 |    633.346041 |    777.285453 | Chris huh                                                                                                                                                             |
|  52 |    160.042721 |    634.946652 | Zimices                                                                                                                                                               |
|  53 |    584.128647 |    444.759511 | Tasman Dixon                                                                                                                                                          |
|  54 |    829.455251 |    410.261118 | Myriam\_Ramirez                                                                                                                                                       |
|  55 |    671.335058 |    270.188274 | Skye McDavid                                                                                                                                                          |
|  56 |    149.553011 |     90.155067 | Markus A. Grohme                                                                                                                                                      |
|  57 |    630.601913 |    236.419334 | Siobhon Egan                                                                                                                                                          |
|  58 |    321.781584 |    148.928303 | Lafage                                                                                                                                                                |
|  59 |    807.447555 |    508.927193 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  60 |    947.882611 |    567.934330 | Robert Gay                                                                                                                                                            |
|  61 |     33.832876 |    737.121495 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
|  62 |    738.942652 |    172.066843 | Zimices                                                                                                                                                               |
|  63 |    295.590262 |    772.378930 | Chris huh                                                                                                                                                             |
|  64 |    775.234924 |     51.316111 | Zimices                                                                                                                                                               |
|  65 |    435.209046 |    583.300914 | Catherine Yasuda                                                                                                                                                      |
|  66 |    371.179781 |     21.745668 | Birgit Lang                                                                                                                                                           |
|  67 |    232.699876 |    343.527509 | Chris huh                                                                                                                                                             |
|  68 |    498.188437 |    419.329823 | Michael Scroggie                                                                                                                                                      |
|  69 |    230.016088 |    480.420252 | T. Michael Keesey                                                                                                                                                     |
|  70 |    432.105549 |     92.742455 | Ferran Sayol                                                                                                                                                          |
|  71 |    604.503258 |    412.247572 | Scott Hartman                                                                                                                                                         |
|  72 |    903.052234 |     48.392442 | Jagged Fang Designs                                                                                                                                                   |
|  73 |    553.621258 |     73.669420 | xgirouxb                                                                                                                                                              |
|  74 |    814.177937 |    209.881391 | Matt Crook                                                                                                                                                            |
|  75 |    316.049034 |     85.382574 | Scott Hartman                                                                                                                                                         |
|  76 |   1002.756369 |    265.892625 | T. Michael Keesey                                                                                                                                                     |
|  77 |    601.503019 |    577.617538 | NA                                                                                                                                                                    |
|  78 |    110.547039 |    601.298469 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  79 |    212.624063 |    592.789390 | NA                                                                                                                                                                    |
|  80 |    380.407654 |    774.513357 | Ferran Sayol                                                                                                                                                          |
|  81 |     44.383433 |    445.686485 | Trond R. Oskars                                                                                                                                                       |
|  82 |    847.825213 |    488.769645 | Allison Pease                                                                                                                                                         |
|  83 |    334.328781 |    577.594749 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  84 |    288.600196 |    268.843594 | (unknown)                                                                                                                                                             |
|  85 |     70.288377 |    429.668787 | Scott Hartman                                                                                                                                                         |
|  86 |     39.645339 |    383.187014 | Margot Michaud                                                                                                                                                        |
|  87 |    785.865725 |    184.771867 | Matt Crook                                                                                                                                                            |
|  88 |    140.901986 |    698.354129 | Michael Scroggie                                                                                                                                                      |
|  89 |    659.581128 |    181.736573 | Gareth Monger                                                                                                                                                         |
|  90 |     45.782010 |    791.746313 | Armin Reindl                                                                                                                                                          |
|  91 |    255.510738 |    236.544971 | Steven Traver                                                                                                                                                         |
|  92 |    986.144138 |    401.155427 | Gareth Monger                                                                                                                                                         |
|  93 |    915.447541 |    547.897529 | Chris huh                                                                                                                                                             |
|  94 |    946.177574 |    397.213582 | Christopher Chávez                                                                                                                                                    |
|  95 |    930.887411 |    338.203325 | Josefine Bohr Brask                                                                                                                                                   |
|  96 |   1003.097014 |    139.678231 | Gareth Monger                                                                                                                                                         |
|  97 |    615.324250 |    452.466045 | NA                                                                                                                                                                    |
|  98 |    793.236435 |    438.201157 | T. Michael Keesey                                                                                                                                                     |
|  99 |    901.128472 |    156.994793 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 100 |    992.417018 |    498.736897 | Ludwik Gąsiorowski                                                                                                                                                    |
| 101 |    415.736185 |    330.492406 | Margot Michaud                                                                                                                                                        |
| 102 |    680.928592 |    137.652221 | Ignacio Contreras                                                                                                                                                     |
| 103 |     27.103973 |    259.370131 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 104 |    540.694676 |    772.832143 | Matt Crook                                                                                                                                                            |
| 105 |    676.168525 |    219.161171 | Andy Wilson                                                                                                                                                           |
| 106 |    615.537891 |    735.314065 | Sarah Werning                                                                                                                                                         |
| 107 |    177.847030 |     18.896969 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 108 |    703.514107 |     19.682583 | Lukasiniho                                                                                                                                                            |
| 109 |    135.931623 |     13.774160 | Steven Coombs                                                                                                                                                         |
| 110 |    824.810501 |    536.864108 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 111 |    872.798108 |    429.392083 | Myriam\_Ramirez                                                                                                                                                       |
| 112 |    860.007883 |    480.206113 | Tony Ayling                                                                                                                                                           |
| 113 |    135.410715 |    253.924106 | S.Martini                                                                                                                                                             |
| 114 |    792.750709 |    337.969955 | Ferran Sayol                                                                                                                                                          |
| 115 |    985.671871 |    367.126756 | Tasman Dixon                                                                                                                                                          |
| 116 |    588.608651 |    749.202352 | Katie S. Collins                                                                                                                                                      |
| 117 |    123.764040 |    346.407349 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 118 |     20.696629 |    185.540781 | Zimices                                                                                                                                                               |
| 119 |    455.748574 |    537.169961 | Ferran Sayol                                                                                                                                                          |
| 120 |    364.402916 |    556.849605 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 121 |    176.405434 |    652.429567 | Matt Crook                                                                                                                                                            |
| 122 |    824.423013 |    626.750348 | Jiekun He                                                                                                                                                             |
| 123 |    695.824723 |    750.051493 | Matt Crook                                                                                                                                                            |
| 124 |    280.676212 |    573.441363 | Mathew Wedel                                                                                                                                                          |
| 125 |    303.930441 |    671.876300 | Zimices                                                                                                                                                               |
| 126 |     55.090907 |    407.726225 | Jagged Fang Designs                                                                                                                                                   |
| 127 |    791.066946 |    424.754721 | Xavier Giroux-Bougard                                                                                                                                                 |
| 128 |    867.729993 |    650.401926 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
| 129 |    570.901549 |    558.619599 | Chris huh                                                                                                                                                             |
| 130 |    760.723034 |    308.371883 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 131 |    585.971921 |    548.434461 | T. Michael Keesey                                                                                                                                                     |
| 132 |    876.880115 |     26.032017 | Rebecca Groom                                                                                                                                                         |
| 133 |    241.937595 |    366.614517 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 134 |    729.358368 |    203.363490 | Jagged Fang Designs                                                                                                                                                   |
| 135 |    345.325314 |    442.056116 | Matt Crook                                                                                                                                                            |
| 136 |    679.886802 |    667.650750 | NA                                                                                                                                                                    |
| 137 |     88.129565 |    727.567024 | Ferran Sayol                                                                                                                                                          |
| 138 |    271.246005 |    159.451905 | Mathew Wedel                                                                                                                                                          |
| 139 |    429.333023 |    385.326638 | Markus A. Grohme                                                                                                                                                      |
| 140 |     76.204819 |    489.375271 | Gareth Monger                                                                                                                                                         |
| 141 |    162.933264 |    368.329206 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 142 |    957.157705 |    484.265803 | wsnaccad                                                                                                                                                              |
| 143 |    117.081165 |     35.712685 | Chris huh                                                                                                                                                             |
| 144 |    392.915559 |    140.442915 | Maxime Dahirel                                                                                                                                                        |
| 145 |    731.879800 |    500.863357 | Christoph Schomburg                                                                                                                                                   |
| 146 |   1006.749519 |    189.124382 | Matt Crook                                                                                                                                                            |
| 147 |     20.653933 |    285.134417 | Chris huh                                                                                                                                                             |
| 148 |    811.452597 |    437.480546 | NA                                                                                                                                                                    |
| 149 |    100.641484 |      9.196856 | Matt Crook                                                                                                                                                            |
| 150 |    741.396070 |    304.800311 | Estelle Bourdon                                                                                                                                                       |
| 151 |     53.838535 |    208.049063 | Christopher Chávez                                                                                                                                                    |
| 152 |    744.139719 |    337.650263 | Matt Crook                                                                                                                                                            |
| 153 |    217.172615 |    739.783989 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 154 |    928.178625 |    787.445969 | Margot Michaud                                                                                                                                                        |
| 155 |     18.708890 |    421.819170 | Zimices                                                                                                                                                               |
| 156 |    698.182260 |     82.746442 | Matt Crook                                                                                                                                                            |
| 157 |   1006.181250 |    367.152858 | T. Michael Keesey                                                                                                                                                     |
| 158 |    843.809407 |     12.789596 | Margot Michaud                                                                                                                                                        |
| 159 |    760.976475 |     95.694460 | Matt Crook                                                                                                                                                            |
| 160 |    306.305348 |     43.944460 | T. Tischler                                                                                                                                                           |
| 161 |    116.581181 |    634.413788 | Ferran Sayol                                                                                                                                                          |
| 162 |    673.341047 |    633.398172 | Stacy Spensley (Modified)                                                                                                                                             |
| 163 |    539.361467 |    592.937760 | Andrew A. Farke                                                                                                                                                       |
| 164 |    359.706433 |    427.553098 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 165 |   1006.188868 |     48.212936 | NA                                                                                                                                                                    |
| 166 |    928.676298 |    166.660629 | Tasman Dixon                                                                                                                                                          |
| 167 |     58.548684 |     32.700919 | John Conway                                                                                                                                                           |
| 168 |    310.757944 |    334.867090 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 169 |     48.231220 |    485.879436 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 170 |    895.472457 |    310.190303 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 171 |    624.162564 |    538.910650 | Matt Crook                                                                                                                                                            |
| 172 |    695.705602 |    662.233577 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 173 |    727.038676 |    601.864371 | Andy Wilson                                                                                                                                                           |
| 174 |   1012.352566 |    768.034769 | Matt Crook                                                                                                                                                            |
| 175 |    995.116446 |    468.002068 | Zimices                                                                                                                                                               |
| 176 |    967.324022 |    756.951654 | T. Michael Keesey                                                                                                                                                     |
| 177 |    640.073613 |    422.591796 | Margot Michaud                                                                                                                                                        |
| 178 |    282.399130 |    125.635629 | Maija Karala                                                                                                                                                          |
| 179 |    287.399372 |    554.241407 | Auckland Museum                                                                                                                                                       |
| 180 |     81.684510 |     90.823546 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 181 |     35.520292 |     29.233361 | Ferran Sayol                                                                                                                                                          |
| 182 |    252.340854 |    464.976434 | Scott Hartman                                                                                                                                                         |
| 183 |   1009.878570 |    338.414425 | Tasman Dixon                                                                                                                                                          |
| 184 |    100.135418 |    266.472140 | Myriam\_Ramirez                                                                                                                                                       |
| 185 |    420.458728 |    282.611160 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 186 |    953.801598 |     69.311029 | Matt Crook                                                                                                                                                            |
| 187 |    694.888365 |    625.404289 | Jagged Fang Designs                                                                                                                                                   |
| 188 |     60.249786 |    239.854073 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 189 |    306.179603 |    457.903767 | Oliver Voigt                                                                                                                                                          |
| 190 |    865.623026 |    327.493585 | Zimices                                                                                                                                                               |
| 191 |    523.493634 |     14.363274 | Gareth Monger                                                                                                                                                         |
| 192 |    701.862283 |     40.577186 | Scott Hartman                                                                                                                                                         |
| 193 |    675.100525 |    538.995016 | Tasman Dixon                                                                                                                                                          |
| 194 |    360.479226 |    412.777818 | Steven Traver                                                                                                                                                         |
| 195 |    758.073038 |    554.977804 | Andy Wilson                                                                                                                                                           |
| 196 |    189.431602 |    792.346834 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 197 |   1010.235607 |    398.393918 | T. Tischler                                                                                                                                                           |
| 198 |    200.442614 |    253.719535 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 199 |    656.896968 |    724.117168 | Markus A. Grohme                                                                                                                                                      |
| 200 |    363.938032 |    762.848026 | Margot Michaud                                                                                                                                                        |
| 201 |    446.259309 |    249.130840 | David Orr                                                                                                                                                             |
| 202 |    369.778880 |     55.797035 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 203 |    242.201750 |    634.436660 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 204 |    232.606700 |    788.937627 | Michael P. Taylor                                                                                                                                                     |
| 205 |    400.317196 |    642.312539 | Matt Crook                                                                                                                                                            |
| 206 |    315.167624 |    398.782588 | Dean Schnabel                                                                                                                                                         |
| 207 |    907.559697 |    392.699866 | Matt Crook                                                                                                                                                            |
| 208 |    629.912441 |    146.227506 | Margot Michaud                                                                                                                                                        |
| 209 |    992.613250 |    522.618186 | Ferran Sayol                                                                                                                                                          |
| 210 |     11.563786 |    167.869328 | Gareth Monger                                                                                                                                                         |
| 211 |     33.208126 |    362.360254 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                  |
| 212 |    730.369365 |     13.249136 | Martin R. Smith                                                                                                                                                       |
| 213 |    131.127838 |     44.429229 | Matt Crook                                                                                                                                                            |
| 214 |    149.506767 |    411.448298 | Smokeybjb                                                                                                                                                             |
| 215 |     78.165914 |    687.526974 | Felix Vaux                                                                                                                                                            |
| 216 |    416.637252 |    362.925541 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 217 |    393.194847 |     33.932896 | Gareth Monger                                                                                                                                                         |
| 218 |    440.925699 |      8.002291 | Chloé Schmidt                                                                                                                                                         |
| 219 |    845.117866 |    381.518097 | Javier Luque                                                                                                                                                          |
| 220 |    477.462733 |    387.805552 | Gareth Monger                                                                                                                                                         |
| 221 |    330.109950 |     52.922894 | Katie S. Collins                                                                                                                                                      |
| 222 |    714.395151 |    779.662682 | Steven Traver                                                                                                                                                         |
| 223 |    372.429139 |    293.869631 | Melissa Broussard                                                                                                                                                     |
| 224 |    622.899020 |    190.594730 | Steven Traver                                                                                                                                                         |
| 225 |    225.899518 |    366.340847 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 226 |    238.449692 |    520.528636 | Yan Wong                                                                                                                                                              |
| 227 |    952.676477 |    183.705498 | Margot Michaud                                                                                                                                                        |
| 228 |    723.096458 |    332.616430 | Matt Crook                                                                                                                                                            |
| 229 |    835.124234 |    642.650806 | T. Michael Keesey                                                                                                                                                     |
| 230 |    760.121408 |    419.887739 | Zimices                                                                                                                                                               |
| 231 |    617.637694 |     12.544545 | Carlos Cano-Barbacil                                                                                                                                                  |
| 232 |    795.184750 |    135.049908 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 233 |    850.719810 |    557.091158 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
| 234 |    707.000897 |    192.000054 | Lauren Anderson                                                                                                                                                       |
| 235 |    972.952305 |    280.650249 | Margot Michaud                                                                                                                                                        |
| 236 |    265.647351 |    416.770567 | Matt Crook                                                                                                                                                            |
| 237 |    924.418689 |    743.701849 | Jagged Fang Designs                                                                                                                                                   |
| 238 |    727.112852 |    626.303468 | Smokeybjb                                                                                                                                                             |
| 239 |     91.612824 |    678.121501 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 240 |    852.884865 |    534.314553 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 241 |    928.336316 |    130.779933 | Ludwik Gąsiorowski                                                                                                                                                    |
| 242 |    536.366929 |    407.764754 | Sharon Wegner-Larsen                                                                                                                                                  |
| 243 |    982.532323 |     52.957431 | Andrew A. Farke                                                                                                                                                       |
| 244 |    885.792831 |    245.398630 | Margot Michaud                                                                                                                                                        |
| 245 |    342.803241 |    406.627252 | Emma Kissling                                                                                                                                                         |
| 246 |   1015.391925 |    470.346278 | Terpsichores                                                                                                                                                          |
| 247 |    157.725465 |    775.918076 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 248 |    900.856457 |     99.402715 | Katie S. Collins                                                                                                                                                      |
| 249 |    703.522897 |    446.713094 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 250 |    463.446937 |    117.841329 | Matt Crook                                                                                                                                                            |
| 251 |    889.875907 |    543.969180 | Matt Crook                                                                                                                                                            |
| 252 |    987.030834 |     31.443376 | FunkMonk                                                                                                                                                              |
| 253 |    308.188366 |    471.831613 | Jaime Headden                                                                                                                                                         |
| 254 |    600.046757 |    465.148744 | S.Martini                                                                                                                                                             |
| 255 |    988.166059 |    413.113456 | Birgit Lang                                                                                                                                                           |
| 256 |     39.792985 |    219.556381 | \[unknown\]                                                                                                                                                           |
| 257 |    102.649224 |     22.034586 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 258 |    115.943997 |    206.001732 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 259 |    956.153406 |    697.424378 | Maija Karala                                                                                                                                                          |
| 260 |    415.996331 |    758.989845 | Andrew A. Farke                                                                                                                                                       |
| 261 |    111.737232 |     46.806330 | Andy Wilson                                                                                                                                                           |
| 262 |     21.343862 |    598.306138 | Matt Crook                                                                                                                                                            |
| 263 |    572.203589 |    219.568913 | Tracy A. Heath                                                                                                                                                        |
| 264 |    967.660681 |    466.008254 | Matt Martyniuk                                                                                                                                                        |
| 265 |    948.048193 |     12.301936 | Matt Crook                                                                                                                                                            |
| 266 |    643.162898 |    506.532480 | Steven Traver                                                                                                                                                         |
| 267 |    297.826494 |    477.349421 | Scott Hartman                                                                                                                                                         |
| 268 |    754.182701 |    488.340147 | Mathilde Cordellier                                                                                                                                                   |
| 269 |   1014.559072 |      7.391518 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 270 |    718.539326 |    739.913647 | Katie S. Collins                                                                                                                                                      |
| 271 |     78.714430 |    392.832811 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 272 |    134.996666 |     52.961443 | Ferran Sayol                                                                                                                                                          |
| 273 |    845.018951 |    396.328337 | Gareth Monger                                                                                                                                                         |
| 274 |    592.336062 |     13.259184 | Alexandre Vong                                                                                                                                                        |
| 275 |     87.767575 |    154.296505 | Dmitry Bogdanov                                                                                                                                                       |
| 276 |    691.315252 |    793.882684 | Zimices                                                                                                                                                               |
| 277 |    858.446548 |    407.697397 | T. Michael Keesey                                                                                                                                                     |
| 278 |    599.844068 |    333.520143 | Margot Michaud                                                                                                                                                        |
| 279 |    848.241160 |    193.181185 | Iain Reid                                                                                                                                                             |
| 280 |    163.781115 |     25.763714 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 281 |    900.450103 |    128.064240 | Gareth Monger                                                                                                                                                         |
| 282 |    384.199594 |    169.536697 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 283 |    457.929192 |     24.533917 | CNZdenek                                                                                                                                                              |
| 284 |    879.321219 |    335.512979 | Emily Willoughby                                                                                                                                                      |
| 285 |    883.920412 |    629.567358 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 286 |    426.817642 |    547.583357 | Matt Crook                                                                                                                                                            |
| 287 |    982.632060 |    198.714030 | Zimices                                                                                                                                                               |
| 288 |    120.204836 |    671.134767 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 289 |     92.703352 |    741.385854 | Tasman Dixon                                                                                                                                                          |
| 290 |    711.370653 |    324.733893 | Gareth Monger                                                                                                                                                         |
| 291 |    288.383219 |    281.254038 | Matt Hayes                                                                                                                                                            |
| 292 |    181.915435 |    437.142589 | Gopal Murali                                                                                                                                                          |
| 293 |    844.426710 |    628.527531 | Ferran Sayol                                                                                                                                                          |
| 294 |    703.267617 |    610.555672 | Zimices                                                                                                                                                               |
| 295 |    431.456688 |    779.031272 | JCGiron                                                                                                                                                               |
| 296 |    862.219989 |    623.540641 | Jaime Headden                                                                                                                                                         |
| 297 |    997.274944 |    543.269302 | Lukasiniho                                                                                                                                                            |
| 298 |    167.629550 |    254.550302 | Michelle Site                                                                                                                                                         |
| 299 |    687.342772 |    414.951603 | Andy Wilson                                                                                                                                                           |
| 300 |     43.236582 |    176.453196 | Matt Crook                                                                                                                                                            |
| 301 |    618.633805 |    463.607806 | Jagged Fang Designs                                                                                                                                                   |
| 302 |    633.272597 |    686.865133 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 303 |    576.525245 |     58.465959 | NA                                                                                                                                                                    |
| 304 |    291.660585 |    658.578161 | Jack Mayer Wood                                                                                                                                                       |
| 305 |    125.019677 |    278.755471 | M. A. Broussard                                                                                                                                                       |
| 306 |     26.924065 |     89.565472 | Scott Hartman                                                                                                                                                         |
| 307 |    458.389228 |    439.629105 | Andrew A. Farke                                                                                                                                                       |
| 308 |    880.300508 |    162.073124 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 309 |    821.346000 |    227.630118 | Chuanixn Yu                                                                                                                                                           |
| 310 |    209.159423 |    562.094266 | Margot Michaud                                                                                                                                                        |
| 311 |    788.355276 |    358.607263 | Zimices                                                                                                                                                               |
| 312 |    966.194228 |    723.312532 | NA                                                                                                                                                                    |
| 313 |    765.907870 |    438.818915 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 314 |    263.102118 |    372.147197 | Zimices                                                                                                                                                               |
| 315 |    640.202187 |    318.924835 | Steven Traver                                                                                                                                                         |
| 316 |    709.895820 |    730.688083 | Matt Crook                                                                                                                                                            |
| 317 |    326.949745 |    361.573472 | Jaime Headden                                                                                                                                                         |
| 318 |    551.229006 |    344.193373 | Pete Buchholz                                                                                                                                                         |
| 319 |    510.774712 |    535.044714 | Ferran Sayol                                                                                                                                                          |
| 320 |    681.004947 |    426.313515 | Matt Crook                                                                                                                                                            |
| 321 |    431.396968 |    373.012843 | Lafage                                                                                                                                                                |
| 322 |    226.326615 |    167.475062 | T. Michael Keesey                                                                                                                                                     |
| 323 |    386.906800 |    597.860274 | Smokeybjb                                                                                                                                                             |
| 324 |     19.902031 |     63.981042 | Neil Kelley                                                                                                                                                           |
| 325 |    258.495276 |    209.401358 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 326 |   1002.248063 |    427.880183 | Margot Michaud                                                                                                                                                        |
| 327 |    716.345532 |    718.726485 | Ferran Sayol                                                                                                                                                          |
| 328 |    461.612039 |    381.791897 | Margot Michaud                                                                                                                                                        |
| 329 |     57.702945 |    750.747248 | Lukasiniho                                                                                                                                                            |
| 330 |    714.913536 |    468.788743 | Margot Michaud                                                                                                                                                        |
| 331 |    237.843545 |    458.808568 | Matt Crook                                                                                                                                                            |
| 332 |    909.197300 |     22.365312 | Sarah Werning                                                                                                                                                         |
| 333 |    536.866516 |    534.528581 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 334 |     80.138705 |    620.890494 | Matt Crook                                                                                                                                                            |
| 335 |    722.651163 |    674.321468 | Pete Buchholz                                                                                                                                                         |
| 336 |     13.810723 |    292.060760 | Zimices                                                                                                                                                               |
| 337 |    761.808551 |    337.336321 | Collin Gross                                                                                                                                                          |
| 338 |    661.028049 |    149.623141 | Gareth Monger                                                                                                                                                         |
| 339 |    277.334771 |    792.361163 | Juan Carlos Jerí                                                                                                                                                      |
| 340 |    322.375302 |    754.290122 | Tasman Dixon                                                                                                                                                          |
| 341 |    246.842082 |    254.806666 | Margot Michaud                                                                                                                                                        |
| 342 |    374.330151 |    745.542610 | Matt Crook                                                                                                                                                            |
| 343 |    488.050415 |    371.074810 | Matt Wilkins                                                                                                                                                          |
| 344 |    431.349881 |    133.643573 | Tess Linden                                                                                                                                                           |
| 345 |    627.786533 |    557.530703 | Roberto Díaz Sibaja                                                                                                                                                   |
| 346 |    407.793664 |    416.358717 | Matt Crook                                                                                                                                                            |
| 347 |    108.038499 |    677.285181 | Scott Reid                                                                                                                                                            |
| 348 |     21.301676 |    653.866476 | Liftarn                                                                                                                                                               |
| 349 |    928.930523 |    469.873499 | NA                                                                                                                                                                    |
| 350 |    984.789605 |    341.512403 | Renata F. Martins                                                                                                                                                     |
| 351 |   1004.523920 |     56.072169 | Matt Crook                                                                                                                                                            |
| 352 |    928.121238 |    738.538461 | Ferran Sayol                                                                                                                                                          |
| 353 |    433.499422 |    625.542024 | NA                                                                                                                                                                    |
| 354 |    758.581159 |    431.341738 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 355 |    462.762442 |    647.340568 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 356 |    860.633908 |    443.944609 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 357 |    910.080129 |    790.341265 | Ferran Sayol                                                                                                                                                          |
| 358 |     83.470495 |    368.374531 | Gopal Murali                                                                                                                                                          |
| 359 |    951.623718 |     47.598293 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 360 |    339.574851 |    264.557554 | Cathy                                                                                                                                                                 |
| 361 |    307.314427 |    368.642671 | Chris huh                                                                                                                                                             |
| 362 |    415.638724 |    727.984814 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 363 |    409.555354 |    664.530455 | NA                                                                                                                                                                    |
| 364 |    311.339092 |    284.633400 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 365 |    161.342975 |    663.781765 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 366 |    456.329954 |    568.861660 | M. A. Broussard                                                                                                                                                       |
| 367 |    983.415246 |    114.091795 | Melissa Broussard                                                                                                                                                     |
| 368 |    351.364149 |    680.486281 | Maha Ghazal                                                                                                                                                           |
| 369 |    592.287150 |    476.118992 | Matt Crook                                                                                                                                                            |
| 370 |    567.924585 |    775.423002 | Kailah Thorn & Ben King                                                                                                                                               |
| 371 |     48.716343 |    769.969114 | Ferran Sayol                                                                                                                                                          |
| 372 |    631.307835 |    171.263846 | Gareth Monger                                                                                                                                                         |
| 373 |    950.185292 |    324.594751 | Matt Crook                                                                                                                                                            |
| 374 |    701.460812 |    555.601420 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 375 |     91.984064 |    465.954516 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 376 |    285.085370 |    327.761455 | Joanna Wolfe                                                                                                                                                          |
| 377 |    232.713654 |    551.140217 | Gareth Monger                                                                                                                                                         |
| 378 |    483.663287 |    601.756580 | Zimices                                                                                                                                                               |
| 379 |    711.224215 |    145.575801 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 380 |    878.606309 |    562.370124 | Iain Reid                                                                                                                                                             |
| 381 |     61.581985 |     23.741535 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 382 |    807.876547 |    283.505287 | Andy Wilson                                                                                                                                                           |
| 383 |    133.728600 |    317.121834 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 384 |    360.433259 |    749.466168 | Manabu Sakamoto                                                                                                                                                       |
| 385 |    606.297859 |     15.183440 | Matt Crook                                                                                                                                                            |
| 386 |    411.634702 |     18.860098 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 387 |     59.823589 |     13.526604 | Dexter R. Mardis                                                                                                                                                      |
| 388 |    336.270970 |    543.082097 | Rebecca Groom                                                                                                                                                         |
| 389 |    678.836015 |    112.183425 | NA                                                                                                                                                                    |
| 390 |    662.799957 |    164.339798 | Natalie Claunch                                                                                                                                                       |
| 391 |    739.638450 |    490.571561 | Matt Crook                                                                                                                                                            |
| 392 |    284.404866 |    164.522927 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 393 |    823.998067 |    658.613856 | Hans Hillewaert                                                                                                                                                       |
| 394 |   1008.315276 |    750.811079 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 395 |    946.133559 |    771.950039 | Steven Traver                                                                                                                                                         |
| 396 |    648.826420 |    374.831068 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 397 |    333.195951 |     41.594657 | Zimices                                                                                                                                                               |
| 398 |    738.909633 |    700.827224 | Matt Crook                                                                                                                                                            |
| 399 |    493.194836 |     98.425910 | C. Camilo Julián-Caballero                                                                                                                                            |
| 400 |    381.818858 |    112.194726 | Zimices                                                                                                                                                               |
| 401 |    768.140105 |    455.907980 | Markus A. Grohme                                                                                                                                                      |
| 402 |    394.799001 |    263.917781 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 403 |    305.512553 |     64.632938 | Scott Reid                                                                                                                                                            |
| 404 |    735.367453 |    267.849064 | Chris huh                                                                                                                                                             |
| 405 |    291.650955 |    385.635806 | NA                                                                                                                                                                    |
| 406 |    518.937103 |    418.283915 | Steven Traver                                                                                                                                                         |
| 407 |    966.074506 |     82.544969 | Mark Miller                                                                                                                                                           |
| 408 |    936.698951 |    777.881201 | Tod Robbins                                                                                                                                                           |
| 409 |    455.353362 |    547.951424 | Cesar Julian                                                                                                                                                          |
| 410 |    884.388977 |    399.104515 | M Kolmann                                                                                                                                                             |
| 411 |    746.650325 |    616.355761 | NA                                                                                                                                                                    |
| 412 |      7.085553 |    587.686728 | Matt Crook                                                                                                                                                            |
| 413 |     34.623468 |    606.046233 | Gopal Murali                                                                                                                                                          |
| 414 |    915.850397 |    411.694928 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 415 |    395.324963 |    544.514922 | Trond R. Oskars                                                                                                                                                       |
| 416 |    327.455319 |    292.761148 | Maxime Dahirel                                                                                                                                                        |
| 417 |    263.172827 |    112.877067 | Margot Michaud                                                                                                                                                        |
| 418 |      8.338384 |    270.263521 | NA                                                                                                                                                                    |
| 419 |    109.849286 |     63.827595 | Chris huh                                                                                                                                                             |
| 420 |    317.012128 |     99.832586 | Robert Gay                                                                                                                                                            |
| 421 |    615.104435 |    326.229695 | Matt Celeskey                                                                                                                                                         |
| 422 |    887.122202 |    464.882039 | Gareth Monger                                                                                                                                                         |
| 423 |    206.789991 |     65.524302 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 424 |    981.834250 |     14.810643 | Gareth Monger                                                                                                                                                         |
| 425 |    891.094785 |    791.938506 | Wayne Decatur                                                                                                                                                         |
| 426 |   1014.995168 |    215.085529 | SecretJellyMan                                                                                                                                                        |
| 427 |    932.451742 |     51.827495 | Margot Michaud                                                                                                                                                        |
| 428 |    656.392139 |      2.993285 | NA                                                                                                                                                                    |
| 429 |    366.917052 |    668.445576 | Andy Wilson                                                                                                                                                           |
| 430 |    167.802965 |    215.256509 | Scott Hartman                                                                                                                                                         |
| 431 |    844.969011 |    263.878647 | Margot Michaud                                                                                                                                                        |
| 432 |    694.786149 |     95.275984 | NA                                                                                                                                                                    |
| 433 |    986.151745 |    587.465372 | Yan Wong                                                                                                                                                              |
| 434 |    986.551211 |     72.069300 | Anthony Caravaggi                                                                                                                                                     |
| 435 |    202.493218 |    194.840633 | S.Martini                                                                                                                                                             |
| 436 |    729.159299 |    486.075253 | Tasman Dixon                                                                                                                                                          |
| 437 |     87.584524 |     45.432661 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 438 |    614.348423 |    792.811314 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 439 |    464.216163 |    148.761221 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 440 |    905.001249 |    571.350169 | Margot Michaud                                                                                                                                                        |
| 441 |    340.399624 |    659.980653 | Gareth Monger                                                                                                                                                         |
| 442 |     91.994016 |    347.096560 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 443 |    713.116004 |    507.738683 | Stuart Humphries                                                                                                                                                      |
| 444 |    773.816135 |    220.005333 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
| 445 |    489.252193 |    388.560300 | Lukas Panzarin                                                                                                                                                        |
| 446 |    924.744522 |    459.413729 | Raven Amos                                                                                                                                                            |
| 447 |    506.980774 |    791.804566 | Scott Hartman                                                                                                                                                         |
| 448 |    373.237924 |    351.799471 | Zimices                                                                                                                                                               |
| 449 |    156.496655 |    694.026834 | Scott Reid                                                                                                                                                            |
| 450 |    956.000598 |    164.817666 | Andy Wilson                                                                                                                                                           |
| 451 |    348.837321 |    297.625517 | Felix Vaux                                                                                                                                                            |
| 452 |    800.023274 |     95.355631 | Kanchi Nanjo                                                                                                                                                          |
| 453 |    299.853816 |      8.579534 | Emily Willoughby                                                                                                                                                      |
| 454 |    505.204705 |    446.195007 | Ferran Sayol                                                                                                                                                          |
| 455 |    421.810680 |    618.584550 | T. Tischler                                                                                                                                                           |
| 456 |    708.779429 |    530.306132 | Smokeybjb                                                                                                                                                             |
| 457 |    559.629656 |     37.945812 | Matt Crook                                                                                                                                                            |
| 458 |    747.359690 |     10.989470 | Curtis Clark and T. Michael Keesey                                                                                                                                    |
| 459 |    665.776310 |    378.953105 | Caleb M. Gordon                                                                                                                                                       |
| 460 |    380.871587 |     45.063822 | SecretJellyMan                                                                                                                                                        |
| 461 |    550.379962 |     27.573794 | Zimices                                                                                                                                                               |
| 462 |    549.407678 |    391.099848 | NA                                                                                                                                                                    |
| 463 |    358.414245 |     37.329241 | Matt Hayes                                                                                                                                                            |
| 464 |    259.919482 |    749.944261 | Gareth Monger                                                                                                                                                         |
| 465 |    741.285556 |    547.513741 | Margot Michaud                                                                                                                                                        |
| 466 |    405.979745 |    296.967360 | NA                                                                                                                                                                    |
| 467 |    590.607635 |    728.592015 | david maas / dave hone                                                                                                                                                |
| 468 |    758.762251 |    498.752312 | Neil Kelley                                                                                                                                                           |
| 469 |    605.567028 |    599.750875 | Katie S. Collins                                                                                                                                                      |
| 470 |    793.490712 |    282.492576 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 471 |     17.563567 |    435.206285 | Zimices                                                                                                                                                               |
| 472 |    262.748981 |    251.229989 | NA                                                                                                                                                                    |
| 473 |    222.546454 |    194.119737 | Zimices                                                                                                                                                               |
| 474 |     18.744330 |    448.437545 | Stuart Humphries                                                                                                                                                      |
| 475 |    249.678018 |    616.583605 | Andy Wilson                                                                                                                                                           |
| 476 |    438.185831 |    742.775178 | Tauana J. Cunha                                                                                                                                                       |
| 477 |    124.096858 |    125.343014 | Emily Willoughby                                                                                                                                                      |
| 478 |    801.966587 |    633.140647 | Matt Crook                                                                                                                                                            |
| 479 |    773.710179 |     13.927741 | Matt Crook                                                                                                                                                            |
| 480 |    842.255337 |    214.214136 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 481 |   1009.981694 |    513.216611 | T. Michael Keesey                                                                                                                                                     |
| 482 |    404.428700 |    316.118276 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 483 |    748.550785 |    438.198753 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 484 |    379.668767 |    591.950245 | Dean Schnabel                                                                                                                                                         |
| 485 |    746.212581 |    425.664170 | Kai R. Caspar                                                                                                                                                         |
| 486 |    407.842875 |    540.334509 | Matt Crook                                                                                                                                                            |
| 487 |    451.494635 |     71.585110 | Matt Crook                                                                                                                                                            |
| 488 |    474.174080 |    641.024050 | NA                                                                                                                                                                    |
| 489 |    299.156494 |    713.461980 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 490 |    875.353443 |    461.289623 | Zimices                                                                                                                                                               |
| 491 |    746.413910 |    453.215853 | Martin Kevil                                                                                                                                                          |
| 492 |    929.041197 |    154.552535 | T. Michael Keesey                                                                                                                                                     |
| 493 |     54.469293 |      6.810219 | Matt Crook                                                                                                                                                            |
| 494 |     32.019888 |    493.059993 | Christoph Schomburg                                                                                                                                                   |
| 495 |     17.268532 |     18.570301 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 496 |    755.139871 |    458.166547 | Ferran Sayol                                                                                                                                                          |
| 497 |    343.724571 |    248.821108 | Andy Wilson                                                                                                                                                           |
| 498 |    967.988638 |    486.260365 | Mathieu Pélissié                                                                                                                                                      |
| 499 |    581.626648 |    593.053318 | Tasman Dixon                                                                                                                                                          |
| 500 |     98.669088 |    337.770948 | Scott Hartman                                                                                                                                                         |
| 501 |    975.327390 |    257.363054 | Ferran Sayol                                                                                                                                                          |
| 502 |    353.361225 |    263.118312 | Matt Crook                                                                                                                                                            |
| 503 |    592.354364 |     31.400459 | Ferran Sayol                                                                                                                                                          |
| 504 |    627.890339 |    367.779632 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                             |
| 505 |    313.884081 |    277.875155 | Andy Wilson                                                                                                                                                           |
| 506 |    217.678910 |    785.023378 | Matt Crook                                                                                                                                                            |
| 507 |    617.536336 |    387.211153 | Benjamint444                                                                                                                                                          |
| 508 |    910.763386 |    385.180526 | Tasman Dixon                                                                                                                                                          |
| 509 |    320.107009 |    109.315443 | Ferran Sayol                                                                                                                                                          |
| 510 |    199.190116 |    549.938852 | Peileppe                                                                                                                                                              |
| 511 |    925.721547 |     59.192165 | Neil Kelley                                                                                                                                                           |
| 512 |     24.494913 |    238.346593 | Jagged Fang Designs                                                                                                                                                   |
| 513 |    449.940589 |    683.104479 | Matt Crook                                                                                                                                                            |
| 514 |    803.512783 |    229.935784 | NA                                                                                                                                                                    |
| 515 |    821.688145 |    420.346879 | Jagged Fang Designs                                                                                                                                                   |
| 516 |    242.952521 |    759.533790 | NA                                                                                                                                                                    |
| 517 |    406.005553 |    210.982195 | Michelle Site                                                                                                                                                         |
| 518 |    683.340209 |    566.235094 | Meliponicultor Itaymbere                                                                                                                                              |
| 519 |     10.896203 |    344.895273 | Andrew A. Farke                                                                                                                                                       |
| 520 |    352.218152 |    365.298036 | Jagged Fang Designs                                                                                                                                                   |
| 521 |    219.547424 |    552.041006 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 522 |    588.503333 |    458.883874 | T. Michael Keesey                                                                                                                                                     |
| 523 |    627.816976 |     95.864937 | Ignacio Contreras                                                                                                                                                     |
| 524 |    135.800102 |    451.931422 | Matt Crook                                                                                                                                                            |
| 525 |    220.880437 |    311.665936 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 526 |    651.183667 |    757.133602 | Steven Traver                                                                                                                                                         |
| 527 |    865.900087 |    259.437813 | Tony Ayling                                                                                                                                                           |
| 528 |    935.131826 |    591.436047 | Scott Hartman                                                                                                                                                         |
| 529 |    318.066564 |    731.800372 | Chris huh                                                                                                                                                             |
| 530 |    508.769620 |    627.827741 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 531 |     27.872706 |    471.760091 | Matt Celeskey                                                                                                                                                         |
| 532 |    992.456463 |    102.326953 | Margot Michaud                                                                                                                                                        |
| 533 |    295.014878 |     58.587998 | Christoph Schomburg                                                                                                                                                   |
| 534 |    463.598880 |    169.429470 | Ferran Sayol                                                                                                                                                          |
| 535 |    151.970549 |    117.854061 | Jagged Fang Designs                                                                                                                                                   |
| 536 |    847.766249 |    654.910766 | Gareth Monger                                                                                                                                                         |
| 537 |    173.171814 |    684.698821 | Zimices                                                                                                                                                               |
| 538 |    459.123167 |    606.928569 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 539 |    529.919892 |    401.904918 | L.M. Davalos                                                                                                                                                          |
| 540 |    892.935284 |     22.380851 | Ferran Sayol                                                                                                                                                          |
| 541 |    595.073756 |    700.113855 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 542 |     99.619718 |    123.379549 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 543 |    254.665660 |     70.038063 | Mathew Wedel                                                                                                                                                          |
| 544 |    840.763409 |    366.921158 | Andy Wilson                                                                                                                                                           |
| 545 |     65.707567 |    172.388703 | NA                                                                                                                                                                    |
| 546 |    270.849186 |    264.725343 | Iain Reid                                                                                                                                                             |
| 547 |    927.135397 |    179.459896 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 548 |    616.627680 |    672.813249 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 549 |     27.315456 |    480.656020 | Tasman Dixon                                                                                                                                                          |
| 550 |    224.155854 |    769.642578 | Rainer Schoch                                                                                                                                                         |
| 551 |    937.669020 |     22.455599 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 552 |    720.631704 |    588.594013 | Matt Crook                                                                                                                                                            |
| 553 |    697.620129 |    141.228525 | NA                                                                                                                                                                    |
| 554 |    689.080975 |    644.349345 | Jagged Fang Designs                                                                                                                                                   |
| 555 |    865.150819 |    378.569570 | Gareth Monger                                                                                                                                                         |
| 556 |    254.743926 |    135.527056 | Margot Michaud                                                                                                                                                        |
| 557 |    964.169602 |     34.836477 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 558 |     11.708692 |    222.565738 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 559 |      7.702752 |    513.267644 | Hugo Gruson                                                                                                                                                           |
| 560 |    853.546356 |    600.126380 | Rebecca Groom                                                                                                                                                         |
| 561 |    909.646485 |    633.043913 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 562 |     14.208198 |    143.738576 | Birgit Lang                                                                                                                                                           |
| 563 |     26.431139 |    105.250211 | Chuanixn Yu                                                                                                                                                           |
| 564 |    608.502767 |     37.643417 | Shyamal                                                                                                                                                               |
| 565 |    574.375506 |    191.982217 | Scott Hartman                                                                                                                                                         |
| 566 |    463.643083 |    290.053779 | Matt Crook                                                                                                                                                            |
| 567 |    143.144423 |    442.888294 | Jagged Fang Designs                                                                                                                                                   |
| 568 |   1001.057185 |    773.176510 | NA                                                                                                                                                                    |
| 569 |   1011.389477 |    707.974466 | Andy Wilson                                                                                                                                                           |
| 570 |    969.225812 |     60.983440 | Christoph Schomburg                                                                                                                                                   |
| 571 |    282.150640 |    369.311357 | Chloé Schmidt                                                                                                                                                         |
| 572 |    114.937803 |    245.347772 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 573 |    875.154074 |    542.218357 | Michelle Site                                                                                                                                                         |
| 574 |   1005.187840 |     18.854529 | Sarah Werning                                                                                                                                                         |
| 575 |    988.778325 |    384.696866 | Jagged Fang Designs                                                                                                                                                   |
| 576 |    488.851210 |    170.470386 | Robert Gay                                                                                                                                                            |
| 577 |     13.195536 |    620.631651 | Javier Luque                                                                                                                                                          |
| 578 |     88.514120 |    607.554511 | Steven Blackwood                                                                                                                                                      |
| 579 |    461.866541 |    283.792905 | Chris huh                                                                                                                                                             |
| 580 |    612.104896 |    243.198114 | Carlos Cano-Barbacil                                                                                                                                                  |
| 581 |    700.110579 |    402.791403 | Margot Michaud                                                                                                                                                        |
| 582 |    448.533496 |    416.015777 | Gareth Monger                                                                                                                                                         |
| 583 |    880.247383 |    330.359334 | Andrew A. Farke                                                                                                                                                       |
| 584 |    659.962816 |    430.439150 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 585 |    709.430858 |     98.916999 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 586 |    961.296404 |    775.954780 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 587 |    686.951567 |    770.894175 | Jake Warner                                                                                                                                                           |
| 588 |    296.382173 |    571.470727 | Prathyush Thomas                                                                                                                                                      |
| 589 |    383.544115 |    678.241913 | Gopal Murali                                                                                                                                                          |
| 590 |    599.658264 |     45.937215 | Mason McNair                                                                                                                                                          |
| 591 |    234.839628 |    205.796005 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 592 |    646.855418 |    162.651124 | Ferran Sayol                                                                                                                                                          |
| 593 |     99.418052 |    103.255390 | Scott Hartman                                                                                                                                                         |
| 594 |    354.620657 |      9.539212 | Dean Schnabel                                                                                                                                                         |
| 595 |    412.018424 |    153.954718 | FJDegrange                                                                                                                                                            |
| 596 |    682.163097 |    519.811919 | Dean Schnabel                                                                                                                                                         |
| 597 |    401.642725 |    233.619646 | Liftarn                                                                                                                                                               |
| 598 |    204.985545 |    713.124126 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 599 |    764.257481 |     70.647224 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 600 |    643.349156 |    734.440433 | Scott Hartman                                                                                                                                                         |
| 601 |    145.960834 |    397.920786 | Michael Day                                                                                                                                                           |
| 602 |    208.810349 |    746.605179 | Markus A. Grohme                                                                                                                                                      |
| 603 |    182.002584 |    709.982693 | Amanda Katzer                                                                                                                                                         |
| 604 |     83.443099 |    378.576256 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 605 |    340.625720 |    458.094380 | Matt Crook                                                                                                                                                            |
| 606 |    214.002755 |    675.268966 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 607 |    847.977326 |    248.622209 | NA                                                                                                                                                                    |
| 608 |    908.416133 |    146.471660 | Ben Liebeskind                                                                                                                                                        |
| 609 |     33.978862 |    762.098348 | David Liao                                                                                                                                                            |
| 610 |    179.501366 |    693.379380 | Kamil S. Jaron                                                                                                                                                        |
| 611 |    797.501029 |    466.674983 | Steven Traver                                                                                                                                                         |
| 612 |    376.058795 |    364.714796 | Scott Hartman                                                                                                                                                         |
| 613 |    835.958713 |    497.716534 | Harold N Eyster                                                                                                                                                       |
| 614 |     82.936387 |     22.128296 | NA                                                                                                                                                                    |
| 615 |     94.809597 |    491.776408 | Kelly                                                                                                                                                                 |
| 616 |    730.911421 |    477.964930 | Steven Traver                                                                                                                                                         |
| 617 |    218.619109 |    251.168170 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 618 |    129.869825 |    737.459754 | Margot Michaud                                                                                                                                                        |
| 619 |    204.602992 |    513.288525 | Zimices                                                                                                                                                               |
| 620 |    627.403581 |    747.741829 | Scott Hartman                                                                                                                                                         |
| 621 |     33.210068 |    640.234390 | T. Michael Keesey                                                                                                                                                     |
| 622 |    665.937390 |    751.511492 | Gareth Monger                                                                                                                                                         |
| 623 |    996.390087 |    612.719622 | Gareth Monger                                                                                                                                                         |
| 624 |    488.965024 |     74.876568 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 625 |      9.412460 |    393.867541 | T. Michael Keesey                                                                                                                                                     |
| 626 |    409.578021 |    132.673504 | Matt Crook                                                                                                                                                            |
| 627 |    228.541492 |    239.350247 | Matt Crook                                                                                                                                                            |
| 628 |   1010.121234 |    487.043766 | Steven Traver                                                                                                                                                         |
| 629 |    256.253422 |    764.226547 | NA                                                                                                                                                                    |
| 630 |    159.663571 |    602.068615 | Emily Willoughby                                                                                                                                                      |
| 631 |    502.724384 |    102.056007 | Sean McCann                                                                                                                                                           |
| 632 |     10.620676 |    664.641682 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 633 |    882.267292 |     75.806939 | Ferran Sayol                                                                                                                                                          |
| 634 |    423.388783 |    353.442523 | Andy Wilson                                                                                                                                                           |
| 635 |    730.148994 |    143.679128 | Arthur S. Brum                                                                                                                                                        |
| 636 |    791.761520 |     20.835843 | Berivan Temiz                                                                                                                                                         |
| 637 |    110.977828 |    514.346890 | NA                                                                                                                                                                    |
| 638 |    785.336456 |    154.480254 | Gareth Monger                                                                                                                                                         |
| 639 |    866.432988 |    163.811406 | Jagged Fang Designs                                                                                                                                                   |
| 640 |     27.448497 |    353.216763 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 641 |    561.186782 |    183.445567 | SauropodomorphMonarch                                                                                                                                                 |
| 642 |    447.393008 |    125.262473 | NA                                                                                                                                                                    |
| 643 |    793.351116 |    494.131269 | NA                                                                                                                                                                    |
| 644 |    293.549802 |    462.245601 | Zimices                                                                                                                                                               |
| 645 |    825.052099 |    445.364835 | Andy Wilson                                                                                                                                                           |
| 646 |    589.938470 |    361.480620 | Jagged Fang Designs                                                                                                                                                   |
| 647 |    637.722285 |    131.012447 | Christoph Schomburg                                                                                                                                                   |
| 648 |    334.231119 |    417.397213 | NA                                                                                                                                                                    |
| 649 |    847.362737 |    504.803618 | Mathieu Pélissié                                                                                                                                                      |
| 650 |      4.155665 |    434.070080 | Michelle Site                                                                                                                                                         |
| 651 |    994.584576 |    782.532576 | Beth Reinke                                                                                                                                                           |
| 652 |   1008.995006 |    409.550634 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 653 |    682.872431 |    357.471335 | Agnello Picorelli                                                                                                                                                     |
| 654 |   1007.309994 |     70.158815 | Tasman Dixon                                                                                                                                                          |
| 655 |     31.188874 |    774.535647 | Felix Vaux                                                                                                                                                            |
| 656 |    559.107747 |    359.445512 | Matt Crook                                                                                                                                                            |
| 657 |    753.301528 |    679.899698 | Dean Schnabel                                                                                                                                                         |
| 658 |    792.637076 |    658.022431 | Margot Michaud                                                                                                                                                        |
| 659 |    985.388772 |    211.767128 | T. Michael Keesey                                                                                                                                                     |
| 660 |   1012.633708 |    733.402533 | Maxime Dahirel                                                                                                                                                        |
| 661 |    302.462047 |    356.695237 | Zimices                                                                                                                                                               |
| 662 |    385.383040 |    327.382555 | Ferran Sayol                                                                                                                                                          |
| 663 |    984.268284 |    246.870752 | T. Michael Keesey                                                                                                                                                     |
| 664 |   1012.786349 |     85.939593 | Jagged Fang Designs                                                                                                                                                   |
| 665 |    137.491563 |    195.679170 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 666 |    856.079177 |    323.338722 | Matt Crook                                                                                                                                                            |
| 667 |    971.295493 |    203.088233 | Gareth Monger                                                                                                                                                         |
| 668 |    222.636183 |    725.661149 | Dmitry Bogdanov                                                                                                                                                       |
| 669 |     12.726064 |     99.371920 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 670 |    260.077607 |    514.685130 | Mariana Ruiz Villarreal                                                                                                                                               |
| 671 |    156.047596 |     46.404397 | Matt Crook                                                                                                                                                            |
| 672 |    984.167301 |    264.673467 | Margot Michaud                                                                                                                                                        |
| 673 |    297.420187 |    402.356353 | David Orr                                                                                                                                                             |
| 674 |    144.617303 |    337.081121 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 675 |    383.499229 |    415.408120 | Kent Elson Sorgon                                                                                                                                                     |
| 676 |    445.751345 |    664.554124 | Tasman Dixon                                                                                                                                                          |
| 677 |    990.734010 |    695.626922 | Michael Scroggie                                                                                                                                                      |
| 678 |    826.125261 |    554.804360 | Meliponicultor Itaymbere                                                                                                                                              |
| 679 |    228.638223 |    567.334750 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 680 |    912.622466 |    772.463881 | Matt Crook                                                                                                                                                            |
| 681 |    720.698355 |    438.996669 | Matt Martyniuk                                                                                                                                                        |
| 682 |    413.887242 |    226.543822 | M Kolmann                                                                                                                                                             |
| 683 |    627.745751 |    111.556872 | L. Shyamal                                                                                                                                                            |
| 684 |    677.046336 |    625.882749 | Michael Scroggie                                                                                                                                                      |
| 685 |    426.500665 |     31.850952 | Jack Mayer Wood                                                                                                                                                       |
| 686 |    324.519180 |    744.006495 | Sharon Wegner-Larsen                                                                                                                                                  |
| 687 |    638.028997 |    205.445113 | Steven Traver                                                                                                                                                         |
| 688 |    155.184258 |    785.058182 | Christoph Schomburg                                                                                                                                                   |
| 689 |    741.867683 |    586.248753 | Gareth Monger                                                                                                                                                         |
| 690 |    230.530183 |    647.623777 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 691 |     38.007183 |    317.253879 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 692 |    189.023732 |    245.377485 | NA                                                                                                                                                                    |
| 693 |    451.665733 |    653.125370 | T. Michael Keesey                                                                                                                                                     |
| 694 |    884.070150 |    321.801911 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 695 |    729.796863 |     88.781836 | NA                                                                                                                                                                    |
| 696 |    118.946084 |    327.321436 | Iain Reid                                                                                                                                                             |
| 697 |    150.196964 |     69.118336 | Zimices                                                                                                                                                               |
| 698 |    239.209022 |     75.318870 | T. Michael Keesey                                                                                                                                                     |
| 699 |    965.842205 |    742.107916 | Margot Michaud                                                                                                                                                        |
| 700 |   1013.016655 |    560.170591 | Christoph Schomburg                                                                                                                                                   |
| 701 |    911.873811 |    132.485648 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 702 |     12.931122 |    687.025030 | Zimices                                                                                                                                                               |
| 703 |    985.407507 |    298.934838 | Zimices                                                                                                                                                               |
| 704 |    463.422287 |      7.435475 | Jessica Anne Miller                                                                                                                                                   |
| 705 |     27.403903 |    301.853265 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 706 |    227.779222 |     72.522184 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 707 |    573.138378 |     41.672946 | Tauana J. Cunha                                                                                                                                                       |
| 708 |    751.785338 |    611.838950 | T. Michael Keesey                                                                                                                                                     |
| 709 |    223.714245 |    506.349833 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 710 |    588.727450 |    392.093453 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 711 |    476.235000 |    306.374071 | Matt Crook                                                                                                                                                            |
| 712 |    319.661329 |    557.829328 | Matt Crook                                                                                                                                                            |
| 713 |    405.735405 |    783.633139 | Jagged Fang Designs                                                                                                                                                   |
| 714 |    922.342320 |    395.725614 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 715 |    109.865801 |    133.888525 | Taro Maeda                                                                                                                                                            |
| 716 |    120.458550 |    297.631675 | Steven Traver                                                                                                                                                         |
| 717 |    726.701520 |    789.995882 | Gareth Monger                                                                                                                                                         |
| 718 |    694.724919 |     59.180240 | Alex Slavenko                                                                                                                                                         |
| 719 |    207.562873 |    537.073164 | Margot Michaud                                                                                                                                                        |
| 720 |    227.044635 |    621.085433 | Ben Liebeskind                                                                                                                                                        |
| 721 |    839.127813 |    344.550605 | Gareth Monger                                                                                                                                                         |
| 722 |     65.333287 |    178.790609 | Tracy A. Heath                                                                                                                                                        |
| 723 |    155.574811 |    348.875133 | Margot Michaud                                                                                                                                                        |
| 724 |    734.054825 |    285.787298 | Yan Wong                                                                                                                                                              |
| 725 |    632.435076 |    673.940645 | Harold N Eyster                                                                                                                                                       |
| 726 |    105.427764 |    110.058925 | Chris huh                                                                                                                                                             |
| 727 |    263.825187 |    572.246537 | Caleb M. Brown                                                                                                                                                        |
| 728 |    600.896333 |    546.046828 | C. Camilo Julián-Caballero                                                                                                                                            |
| 729 |    767.428708 |    518.627123 | Michael Scroggie                                                                                                                                                      |
| 730 |    495.492127 |    543.253318 | Jagged Fang Designs                                                                                                                                                   |
| 731 |    154.284447 |    382.397181 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 732 |    613.383564 |    617.692331 | Alexis Simon                                                                                                                                                          |
| 733 |    898.059649 |    172.920323 | Scott Hartman                                                                                                                                                         |
| 734 |    888.023445 |    568.027995 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 735 |    246.415715 |    157.639702 | T. Michael Keesey                                                                                                                                                     |
| 736 |    552.312545 |    780.907221 | Zimices                                                                                                                                                               |
| 737 |    346.691727 |    358.200614 | NA                                                                                                                                                                    |
| 738 |    438.482346 |    685.643990 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 739 |    557.296258 |    534.258978 | Terpsichores                                                                                                                                                          |
| 740 |    342.109024 |    552.085502 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 741 |    484.536749 |    290.037428 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 742 |     22.038584 |    632.544592 | Sarah Werning                                                                                                                                                         |
| 743 |     43.111271 |    188.754180 | Andrew A. Farke                                                                                                                                                       |
| 744 |    534.464685 |     22.316071 | Scott Hartman                                                                                                                                                         |
| 745 |    995.410164 |    675.843037 | Melissa Broussard                                                                                                                                                     |
| 746 |    489.378739 |    641.057413 | Margot Michaud                                                                                                                                                        |
| 747 |    197.745022 |     72.407628 | Becky Barnes                                                                                                                                                          |
| 748 |    713.844843 |    544.427129 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 749 |    915.369817 |    300.940916 | Margot Michaud                                                                                                                                                        |
| 750 |    835.671157 |    619.537485 | Milton Tan                                                                                                                                                            |
| 751 |    447.171314 |    675.678974 | NA                                                                                                                                                                    |
| 752 |    393.826774 |    588.525094 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 753 |    715.118188 |    421.921527 | Jaime Headden                                                                                                                                                         |
| 754 |    120.074364 |    266.011391 | T. Michael Keesey                                                                                                                                                     |
| 755 |    318.275992 |    661.071802 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 756 |      9.621303 |    116.604872 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
| 757 |    723.438269 |    521.806458 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 758 |     26.606123 |    460.301400 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 759 |    915.625683 |    610.343230 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 760 |    505.177275 |    298.519755 | Ferran Sayol                                                                                                                                                          |
| 761 |    278.163495 |      5.539649 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 762 |    539.888733 |    572.353364 | Margot Michaud                                                                                                                                                        |
| 763 |     23.526504 |    402.484886 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 764 |    127.397899 |    110.758370 | Zimices                                                                                                                                                               |
| 765 |    143.059436 |    675.547616 | Scott Hartman                                                                                                                                                         |
| 766 |    974.768832 |    789.702384 | Scott Hartman                                                                                                                                                         |
| 767 |    821.471767 |    613.972989 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 768 |    454.544431 |    274.836185 | Liftarn                                                                                                                                                               |
| 769 |    862.783679 |    432.244519 | Sarah Werning                                                                                                                                                         |
| 770 |    865.709056 |    224.777381 | Birgit Lang                                                                                                                                                           |
| 771 |    631.741840 |    476.332382 | Gareth Monger                                                                                                                                                         |
| 772 |    189.217332 |    777.721757 | Margot Michaud                                                                                                                                                        |
| 773 |    512.555979 |     23.140039 | Milton Tan                                                                                                                                                            |
| 774 |    900.436824 |    181.864438 | Matt Celeskey                                                                                                                                                         |
| 775 |    299.801507 |    374.151208 | Cesar Julian                                                                                                                                                          |
| 776 |    447.335362 |    701.745356 | Matt Crook                                                                                                                                                            |
| 777 |    686.872361 |     34.193374 | T. Michael Keesey                                                                                                                                                     |
| 778 |    666.643347 |    570.325490 | NA                                                                                                                                                                    |
| 779 |    643.820985 |    794.820340 | Erika Schumacher                                                                                                                                                      |
| 780 |    790.464534 |    523.318472 | Jakovche                                                                                                                                                              |
| 781 |    678.817614 |    102.538332 | Chris huh                                                                                                                                                             |
| 782 |    452.499327 |    619.195677 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 783 |    654.680935 |    592.908023 | Matt Crook                                                                                                                                                            |
| 784 |    755.972938 |    469.827638 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 785 |    618.679212 |    418.476690 | FunkMonk                                                                                                                                                              |
| 786 |    923.074161 |    313.063217 | Michael P. Taylor                                                                                                                                                     |
| 787 |    932.717612 |    411.264287 | Chris huh                                                                                                                                                             |
| 788 |    687.776141 |    761.721245 | Margot Michaud                                                                                                                                                        |
| 789 |    798.197401 |    376.340487 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 790 |    366.009624 |    311.138156 | Sharon Wegner-Larsen                                                                                                                                                  |
| 791 |    625.766298 |    443.055647 | Harold N Eyster                                                                                                                                                       |
| 792 |   1005.595873 |    440.745262 | Birgit Lang                                                                                                                                                           |
| 793 |    409.742461 |    343.658812 | NA                                                                                                                                                                    |
| 794 |    936.057019 |    703.363982 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 795 |    239.168626 |    149.754387 | Sharon Wegner-Larsen                                                                                                                                                  |
| 796 |    438.931640 |    343.305805 | Dean Schnabel                                                                                                                                                         |
| 797 |    270.571697 |    101.827356 | Lauren Sumner-Rooney                                                                                                                                                  |
| 798 |      9.791297 |    356.539428 | Martin R. Smith                                                                                                                                                       |
| 799 |    197.502138 |    429.882188 | Terpsichores                                                                                                                                                          |
| 800 |     43.254592 |    313.063800 | NA                                                                                                                                                                    |
| 801 |    422.841057 |    424.281515 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 802 |    310.478609 |    173.691543 | Margot Michaud                                                                                                                                                        |
| 803 |   1014.902650 |    165.948771 | Kamil S. Jaron                                                                                                                                                        |
| 804 |    631.453895 |    723.862837 | Gareth Monger                                                                                                                                                         |
| 805 |    419.398243 |    744.567525 | Zimices                                                                                                                                                               |
| 806 |    102.796440 |    162.889721 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 807 |     20.794088 |    792.153562 | Chris huh                                                                                                                                                             |
| 808 |    694.976975 |    218.674825 | Rebecca Groom                                                                                                                                                         |
| 809 |    654.169197 |    307.712734 | Iain Reid                                                                                                                                                             |
| 810 |    238.456177 |    510.170534 | Matt Crook                                                                                                                                                            |
| 811 |    965.466535 |    530.927735 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 812 |    672.951712 |    363.421843 | Andy Wilson                                                                                                                                                           |
| 813 |    752.351303 |    623.226420 | M Kolmann                                                                                                                                                             |
| 814 |    967.650661 |    406.760985 | Zimices                                                                                                                                                               |
| 815 |     79.824486 |    762.626167 | Mette Aumala                                                                                                                                                          |
| 816 |    402.854779 |     43.116638 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
| 817 |    816.564576 |    638.947706 | Steven Traver                                                                                                                                                         |
| 818 |    332.898602 |    304.093185 | Zimices                                                                                                                                                               |
| 819 |    458.906207 |     81.035581 | NA                                                                                                                                                                    |
| 820 |    602.334785 |    487.092066 | NA                                                                                                                                                                    |
| 821 |   1004.419809 |    106.737933 | Margot Michaud                                                                                                                                                        |
| 822 |    479.457904 |    373.229857 | Tauana J. Cunha                                                                                                                                                       |
| 823 |    364.777429 |    422.168352 | Smokeybjb                                                                                                                                                             |
| 824 |    308.852049 |    124.939939 | Tyler Greenfield                                                                                                                                                      |
| 825 |    491.182376 |    275.267342 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 826 |    669.374240 |    156.978151 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 827 |    650.813933 |    529.930857 | Markus A. Grohme                                                                                                                                                      |
| 828 |    967.051893 |    255.515971 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 829 |    778.470519 |    129.469466 | Chris huh                                                                                                                                                             |
| 830 |    729.447121 |    581.337602 | Michelle Site                                                                                                                                                         |
| 831 |    592.844188 |    522.534219 | Steven Traver                                                                                                                                                         |
| 832 |    882.374291 |     12.713050 | Beth Reinke                                                                                                                                                           |
| 833 |    857.850552 |    548.029846 | \[unknown\]                                                                                                                                                           |
| 834 |    609.887464 |    248.837976 | Christoph Schomburg                                                                                                                                                   |
| 835 |    144.618871 |     29.179420 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 836 |    829.544576 |    356.229955 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 837 |     79.272673 |    704.841187 | Ingo Braasch                                                                                                                                                          |
| 838 |    755.891521 |     81.976202 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                  |
| 839 |    657.530507 |    447.630102 | James Neenan                                                                                                                                                          |
| 840 |    705.326545 |    773.685573 | Erika Schumacher                                                                                                                                                      |
| 841 |     59.550775 |    780.097280 | Ferran Sayol                                                                                                                                                          |
| 842 |    760.018136 |    183.207727 | Geoff Shaw                                                                                                                                                            |
| 843 |     82.013636 |    418.365691 | FunkMonk                                                                                                                                                              |
| 844 |    702.916883 |    541.324318 | Andy Wilson                                                                                                                                                           |
| 845 |    874.458214 |    344.183393 | Taenadoman                                                                                                                                                            |
| 846 |     30.893816 |     74.986146 | Matt Crook                                                                                                                                                            |
| 847 |    344.545273 |    783.105831 | Maija Karala                                                                                                                                                          |
| 848 |    531.760444 |    525.541058 | NA                                                                                                                                                                    |
| 849 |    678.386479 |     85.526663 | Matt Crook                                                                                                                                                            |
| 850 |    132.764338 |    663.413981 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 851 |    170.636544 |    393.389537 | Scott Hartman                                                                                                                                                         |
| 852 |    777.527122 |    417.133403 | T. Michael Keesey                                                                                                                                                     |
| 853 |    574.316172 |    395.290855 | Zimices                                                                                                                                                               |
| 854 |    290.858818 |    289.203219 | Isaure Scavezzoni                                                                                                                                                     |
| 855 |    301.370037 |    789.827880 | Cesar Julian                                                                                                                                                          |
| 856 |   1004.966286 |    159.457011 | Matt Crook                                                                                                                                                            |
| 857 |    951.361497 |    411.514070 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 858 |    232.134131 |    256.880416 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 859 |    888.733572 |    481.943810 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 860 |     12.477948 |    471.257459 | Terpsichores                                                                                                                                                          |
| 861 |    354.964991 |    289.467584 | Markus A. Grohme                                                                                                                                                      |
| 862 |    215.878189 |    226.749168 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 863 |    831.040441 |    339.970177 | NA                                                                                                                                                                    |
| 864 |    654.272031 |    515.275190 | Margot Michaud                                                                                                                                                        |
| 865 |    190.969121 |    680.776360 | Chris Jennings (Risiatto)                                                                                                                                             |
| 866 |    192.823279 |    223.944364 | Henry Lydecker                                                                                                                                                        |
| 867 |     52.416663 |    712.960700 | T. Michael Keesey                                                                                                                                                     |
| 868 |    872.219520 |    635.570855 | Steven Traver                                                                                                                                                         |
| 869 |    269.677330 |    462.974241 | Birgit Lang                                                                                                                                                           |
| 870 |    327.584142 |    282.868627 | Margot Michaud                                                                                                                                                        |
| 871 |    259.198982 |    360.279903 | Gareth Monger                                                                                                                                                         |
| 872 |    944.769740 |     28.991281 | Zimices                                                                                                                                                               |
| 873 |    492.097917 |    438.737134 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 874 |    988.108713 |    132.303681 | Manabu Bessho-Uehara                                                                                                                                                  |
| 875 |    541.167772 |    416.623079 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 876 |    978.833796 |    777.399692 | NA                                                                                                                                                                    |
| 877 |    436.343607 |    271.916765 | Harold N Eyster                                                                                                                                                       |
| 878 |    103.403929 |    733.303422 | Steven Traver                                                                                                                                                         |
| 879 |    596.154953 |    554.581242 | Zimices                                                                                                                                                               |
| 880 |    881.914784 |    408.750762 | Zimices                                                                                                                                                               |
| 881 |    786.168427 |     83.621223 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 882 |    489.509466 |    191.643795 | Michael P. Taylor                                                                                                                                                     |
| 883 |    938.485262 |    381.209830 | Alex Slavenko                                                                                                                                                         |
| 884 |    122.532769 |      5.339696 | Iain Reid                                                                                                                                                             |
| 885 |    104.809098 |     57.210884 | Margot Michaud                                                                                                                                                        |
| 886 |    942.853798 |    676.548081 | Zimices                                                                                                                                                               |
| 887 |     23.685028 |    152.301281 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 888 |      8.719441 |    153.349305 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 889 |    934.808711 |    542.495260 | Carlos Cano-Barbacil                                                                                                                                                  |
| 890 |    335.882510 |     31.331584 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 891 |      8.859576 |    457.542175 | Gareth Monger                                                                                                                                                         |
| 892 |    996.319022 |    724.240968 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 893 |   1015.777496 |    573.125177 | Michelle Site                                                                                                                                                         |
| 894 |   1004.538964 |    629.455321 | Steven Traver                                                                                                                                                         |
| 895 |    933.205926 |    664.882412 | White Wolf                                                                                                                                                            |
| 896 |     10.797477 |     43.779054 | Anthony Caravaggi                                                                                                                                                     |
| 897 |    899.103854 |    452.261203 | Zimices                                                                                                                                                               |
| 898 |     98.221556 |    663.991309 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 899 |    901.887682 |      9.291640 | Zimices                                                                                                                                                               |
| 900 |    852.369980 |    335.307095 | Margot Michaud                                                                                                                                                        |
| 901 |    121.701950 |    687.823329 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 902 |    829.328483 |    263.795774 | Scott Hartman                                                                                                                                                         |
| 903 |    359.121051 |    646.457499 | Matt Crook                                                                                                                                                            |
| 904 |    951.451999 |    753.478559 | David Orr                                                                                                                                                             |
| 905 |    826.172447 |    189.475283 | Alex Slavenko                                                                                                                                                         |
| 906 |    961.792725 |    351.245390 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |

    #> Your tweet has been posted!
