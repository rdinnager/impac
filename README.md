
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

Collin Gross, Margot Michaud, Gopal Murali, Christoph Schomburg, C.
Camilo Julián-Caballero, Harold N Eyster, Armin Reindl, Tauana J. Cunha,
Gareth Monger, B. Duygu Özpolat, Markus A. Grohme, Xavier
Giroux-Bougard, Alexander Schmidt-Lebuhn, Jagged Fang Designs, Rebecca
Groom, Caleb M. Brown, Lukas Panzarin, Original photo by Andrew Murray,
vectorized by Roberto Díaz Sibaja, Andy Wilson, Konsta Happonen, from a
CC-BY-NC image by sokolkov2002 on iNaturalist, Kai R. Caspar, Sarah
Werning, Philippe Janvier (vectorized by T. Michael Keesey), Yan Wong,
Matt Crook, Maxime Dahirel, Scott Hartman, Marie Russell, Hanyong Pu,
Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming
Zhang, Songhai Jia & T. Michael Keesey, SauropodomorphMonarch, Zimices,
Steven Traver, Melissa Ingala, Matt Wilkins, Ignacio Contreras, Chris
huh, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Cagri Cevrim, Alan Manson (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Chase
Brownstein, Ieuan Jones, Nobu Tamura (vectorized by T. Michael Keesey),
Tasman Dixon, Mette Aumala, Amanda Katzer, Joseph J. W. Sertich, Mark A.
Loewen, C. W. Nash (illustration) and Timothy J. Bartley (silhouette),
Julio Garza, FunkMonk, T. Michael Keesey, Frank Denota, Jennifer
Trimble, Tyler McCraney, Mali’o Kodis, photograph from Jersabek et al,
2003, Caio Bernardes, vectorized by Zimices, Ingo Braasch, Jaime
Headden, Gabriela Palomo-Munoz, Beth Reinke, Maija Karala, Erika
Schumacher, Ewald Rübsamen, Felix Vaux, Joanna Wolfe, Brad McFeeters
(vectorized by T. Michael Keesey), kreidefossilien.de, Kamil S. Jaron,
Birgit Lang, Verdilak, T. Michael Keesey (vectorization) and Nadiatalent
(photography), Air Kebir NRG, MPF (vectorized by T. Michael Keesey),
Michele Tobias, Ferran Sayol, Stanton F. Fink (vectorized by T. Michael
Keesey), Michael Scroggie, Jimmy Bernot, Noah Schlottman, photo by David
J Patterson, Myriam\_Ramirez, T. Michael Keesey (vectorization); Yves
Bousquet (photography), Diana Pomeroy, Matt Wilkins (photo by Patrick
Kavanagh), Mattia Menchetti, Daniel Jaron, Dmitry Bogdanov (vectorized
by T. Michael Keesey), Martin R. Smith, T. Michael Keesey (after Colin
M. L. Burnett), Dean Schnabel, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Andrew A. Farke, David Sim
(photograph) and T. Michael Keesey (vectorization), Noah Schlottman,
photo from Casey Dunn, Kimberly Haddrell, Emily Willoughby, Sergio A.
Muñoz-Gómez, Sean McCann, Shyamal, Rachel Shoop, Margret Flinsch,
vectorized by Zimices, Mathieu Pélissié, Courtney Rockenbach, Roberto
Díaz Sibaja, Adam Stuart Smith (vectorized by T. Michael Keesey),
Mali’o Kodis, photograph by Jim Vargo, Dori <dori@merr.info> (source
photo) and Nevit Dilmen, Mathew Wedel, Michael P. Taylor, Siobhon Egan,
James R. Spotila and Ray Chatterji, Dantheman9758 (vectorized by T.
Michael Keesey), CNZdenek, Juan Carlos Jerí, Hugo Gruson, xgirouxb,
Manabu Sakamoto, Steven Coombs, Lukasiniho, Cristina Guijarro, Ray
Simpson (vectorized by T. Michael Keesey), Katie S. Collins, Mathilde
Cordellier, Duane Raver (vectorized by T. Michael Keesey), Nobu Tamura,
Benjamin Monod-Broca, Noah Schlottman, Mo Hassan, Unknown (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Nina
Skinner, Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Darren
Naish (vectorized by T. Michael Keesey), Jean-Raphaël Guillaumin
(photography) and T. Michael Keesey (vectorization), M Kolmann, V.
Deepak, Didier Descouens (vectorized by T. Michael Keesey), A. H.
Baldwin (vectorized by T. Michael Keesey), Richard J. Harris, John
Conway, Eduard Solà (vectorized by T. Michael Keesey), Nobu Tamura,
vectorized by Zimices, Tyler Greenfield, Smokeybjb (modified by Mike
Keesey), Cesar Julian, Hans Hillewaert (vectorized by T. Michael
Keesey), Ghedoghedo (vectorized by T. Michael Keesey), Ellen Edmonson
and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette),
Chuanixn Yu, Andrew A. Farke, shell lines added by Yan Wong, Neil
Kelley, Smokeybjb, vectorized by Zimices, Tim Bertelink (modified by T.
Michael Keesey), NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Robbie N. Cada
(vectorized by T. Michael Keesey), Dmitry Bogdanov, Mykle Hoban, Darren
Naish (vectorize by T. Michael Keesey), Kanchi Nanjo, L. Shyamal, Iain
Reid, Matt Dempsey, Smokeybjb, James I. Kirkland, Luis Alcalá, Mark A.
Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized
by T. Michael Keesey), Scott Hartman, modified by T. Michael Keesey,
Lisa Byrne, Acrocynus (vectorized by T. Michael Keesey), Alex Slavenko,
Brian Gratwicke (photo) and T. Michael Keesey (vectorization), Mark
Witton, I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey),
Noah Schlottman, photo by Casey Dunn, DW Bapst (Modified from Bulman,
1964), Kent Elson Sorgon, Lisa M. “Pixxl” (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Lankester Edwin Ray
(vectorized by T. Michael Keesey), Becky Barnes, Renata F. Martins,
Michael B. H. (vectorized by T. Michael Keesey), Dave Souza (vectorized
by T. Michael Keesey), Steven Haddock • Jellywatch.org, Lafage,
Francesca Belem Lopes Palmeira, terngirl, T. Tischler, Vijay Cavale
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey),
Carlos Cano-Barbacil, Henry Lydecker, Pranav Iyer (grey ideas),
Christopher Chávez, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), Arthur Weasley (vectorized by T. Michael Keesey), T.
Michael Keesey (after Heinrich Harder), Obsidian Soul (vectorized by T.
Michael Keesey), Lauren Sumner-Rooney, Michelle Site, Andreas Trepte
(vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                          |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     198.34931 |    584.998448 | Collin Gross                                                                                                                                                    |
|   2 |     937.48144 |    651.601614 | Margot Michaud                                                                                                                                                  |
|   3 |     414.14981 |    676.582465 | Margot Michaud                                                                                                                                                  |
|   4 |     320.22093 |    519.049701 | Gopal Murali                                                                                                                                                    |
|   5 |     570.28609 |    327.290170 | Christoph Schomburg                                                                                                                                             |
|   6 |     543.86830 |    546.647257 | C. Camilo Julián-Caballero                                                                                                                                      |
|   7 |     127.48959 |    278.788129 | Harold N Eyster                                                                                                                                                 |
|   8 |     257.80338 |     75.899947 | Armin Reindl                                                                                                                                                    |
|   9 |      68.97198 |    172.961678 | Tauana J. Cunha                                                                                                                                                 |
|  10 |     859.26976 |    292.742545 | Gareth Monger                                                                                                                                                   |
|  11 |     565.28520 |    201.012156 | B. Duygu Özpolat                                                                                                                                                |
|  12 |     682.13564 |    416.654007 | Markus A. Grohme                                                                                                                                                |
|  13 |     639.40774 |    704.967073 | Xavier Giroux-Bougard                                                                                                                                           |
|  14 |     646.03348 |    553.775430 | Alexander Schmidt-Lebuhn                                                                                                                                        |
|  15 |     218.99048 |    173.145183 | Jagged Fang Designs                                                                                                                                             |
|  16 |     799.11086 |    545.628590 | Rebecca Groom                                                                                                                                                   |
|  17 |     537.85912 |    670.498199 | Caleb M. Brown                                                                                                                                                  |
|  18 |     307.68283 |    290.113307 | Lukas Panzarin                                                                                                                                                  |
|  19 |     510.12511 |    403.093470 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                              |
|  20 |     851.02530 |    679.832594 | Andy Wilson                                                                                                                                                     |
|  21 |     470.19127 |     62.225496 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                           |
|  22 |     402.97235 |    451.373215 | Kai R. Caspar                                                                                                                                                   |
|  23 |     730.49718 |    330.186179 | NA                                                                                                                                                              |
|  24 |     952.90638 |    462.721697 | Sarah Werning                                                                                                                                                   |
|  25 |      87.75986 |    457.145071 | NA                                                                                                                                                              |
|  26 |     114.80781 |    700.308229 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                              |
|  27 |     452.83599 |    199.459432 | Yan Wong                                                                                                                                                        |
|  28 |     863.14648 |    757.530872 | Matt Crook                                                                                                                                                      |
|  29 |     683.12703 |    253.431497 | Maxime Dahirel                                                                                                                                                  |
|  30 |     624.22473 |     96.256637 | Scott Hartman                                                                                                                                                   |
|  31 |     121.12301 |     85.898633 | Marie Russell                                                                                                                                                   |
|  32 |     552.59921 |    480.125665 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                     |
|  33 |     345.10693 |    102.532152 | Markus A. Grohme                                                                                                                                                |
|  34 |     458.98841 |    292.708476 | SauropodomorphMonarch                                                                                                                                           |
|  35 |     367.74501 |    366.352466 | Zimices                                                                                                                                                         |
|  36 |      75.61384 |    554.251597 | Gareth Monger                                                                                                                                                   |
|  37 |     258.14940 |    400.255800 | Steven Traver                                                                                                                                                   |
|  38 |     454.87036 |    743.785383 | Andy Wilson                                                                                                                                                     |
|  39 |     325.23005 |    727.589653 | Jagged Fang Designs                                                                                                                                             |
|  40 |     729.29104 |    614.944803 | Margot Michaud                                                                                                                                                  |
|  41 |     114.37643 |    392.568627 | Margot Michaud                                                                                                                                                  |
|  42 |     597.27462 |     42.609221 | Melissa Ingala                                                                                                                                                  |
|  43 |     717.84471 |     31.396028 | Scott Hartman                                                                                                                                                   |
|  44 |     917.88125 |     91.037312 | Gareth Monger                                                                                                                                                   |
|  45 |     370.98709 |    184.542907 | Matt Wilkins                                                                                                                                                    |
|  46 |     196.10752 |    345.414790 | Andy Wilson                                                                                                                                                     |
|  47 |     300.78592 |    627.262212 | Zimices                                                                                                                                                         |
|  48 |     905.30661 |    569.341278 | Xavier Giroux-Bougard                                                                                                                                           |
|  49 |     720.59971 |    552.284864 | Ignacio Contreras                                                                                                                                               |
|  50 |     748.33781 |    145.179832 | Gareth Monger                                                                                                                                                   |
|  51 |     746.92598 |    721.841151 | Collin Gross                                                                                                                                                    |
|  52 |     195.77578 |    480.940461 | Ignacio Contreras                                                                                                                                               |
|  53 |     743.82429 |     68.176535 | Chris huh                                                                                                                                                       |
|  54 |     432.58350 |    617.655653 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                             |
|  55 |     522.92452 |    138.175332 | Cagri Cevrim                                                                                                                                                    |
|  56 |     966.51289 |    295.479821 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
|  57 |     969.91341 |     81.188566 | NA                                                                                                                                                              |
|  58 |     213.43094 |    109.926313 | Chris huh                                                                                                                                                       |
|  59 |     315.66792 |     23.806751 | Chris huh                                                                                                                                                       |
|  60 |     215.51971 |    771.960332 | Zimices                                                                                                                                                         |
|  61 |     556.40213 |    733.532284 | Chase Brownstein                                                                                                                                                |
|  62 |     275.73236 |    204.187576 | Ieuan Jones                                                                                                                                                     |
|  63 |     250.76018 |    695.711047 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  64 |     674.98518 |    451.191810 | Tasman Dixon                                                                                                                                                    |
|  65 |     296.49178 |    441.417605 | Armin Reindl                                                                                                                                                    |
|  66 |     335.50747 |    776.268553 | Mette Aumala                                                                                                                                                    |
|  67 |     253.64963 |    258.742964 | Chris huh                                                                                                                                                       |
|  68 |     179.67102 |     37.191646 | Amanda Katzer                                                                                                                                                   |
|  69 |     615.05859 |    619.450882 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                            |
|  70 |     648.01475 |    368.454665 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                   |
|  71 |     829.58158 |     25.428225 | Julio Garza                                                                                                                                                     |
|  72 |     468.59360 |    504.022959 | FunkMonk                                                                                                                                                        |
|  73 |     728.28331 |    179.087860 | Margot Michaud                                                                                                                                                  |
|  74 |     497.08521 |    590.377907 | NA                                                                                                                                                              |
|  75 |     598.98075 |    130.428381 | T. Michael Keesey                                                                                                                                               |
|  76 |     909.12032 |    536.053167 | Frank Denota                                                                                                                                                    |
|  77 |     953.23881 |    164.592108 | Jagged Fang Designs                                                                                                                                             |
|  78 |     445.15153 |    385.161141 | Chris huh                                                                                                                                                       |
|  79 |      67.62795 |     24.011432 | Jennifer Trimble                                                                                                                                                |
|  80 |     489.11701 |    242.252057 | Tyler McCraney                                                                                                                                                  |
|  81 |      66.49703 |    633.669008 | Sarah Werning                                                                                                                                                   |
|  82 |      91.55333 |    242.973593 | Margot Michaud                                                                                                                                                  |
|  83 |     405.91175 |     53.242289 | Scott Hartman                                                                                                                                                   |
|  84 |      23.72096 |    304.692756 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                              |
|  85 |     728.01767 |    743.888886 | Markus A. Grohme                                                                                                                                                |
|  86 |      49.44866 |     72.885861 | Caio Bernardes, vectorized by Zimices                                                                                                                           |
|  87 |     967.29578 |    745.239201 | Zimices                                                                                                                                                         |
|  88 |     609.86545 |    518.535852 | Kai R. Caspar                                                                                                                                                   |
|  89 |     489.01449 |    264.677407 | Ingo Braasch                                                                                                                                                    |
|  90 |     714.39461 |    702.196485 | T. Michael Keesey                                                                                                                                               |
|  91 |     454.33817 |    437.750133 | Andy Wilson                                                                                                                                                     |
|  92 |     236.56857 |    521.656103 | Margot Michaud                                                                                                                                                  |
|  93 |     523.06246 |     40.726779 | Jaime Headden                                                                                                                                                   |
|  94 |     766.21602 |    480.434275 | Gabriela Palomo-Munoz                                                                                                                                           |
|  95 |    1000.12509 |    311.026812 | Beth Reinke                                                                                                                                                     |
|  96 |      59.14359 |    319.040448 | Chris huh                                                                                                                                                       |
|  97 |     870.47778 |    504.675557 | Maija Karala                                                                                                                                                    |
|  98 |     164.43146 |    220.267515 | Erika Schumacher                                                                                                                                                |
|  99 |     303.12481 |     59.019316 | Ewald Rübsamen                                                                                                                                                  |
| 100 |     111.88017 |    325.875707 | Felix Vaux                                                                                                                                                      |
| 101 |     251.56195 |    148.664163 | C. Camilo Julián-Caballero                                                                                                                                      |
| 102 |     773.35656 |    111.433054 | Joanna Wolfe                                                                                                                                                    |
| 103 |     295.16645 |    591.215477 | Erika Schumacher                                                                                                                                                |
| 104 |     871.88817 |    103.572368 | Zimices                                                                                                                                                         |
| 105 |     132.62621 |     17.466140 | Chris huh                                                                                                                                                       |
| 106 |     951.79845 |    711.349971 | T. Michael Keesey                                                                                                                                               |
| 107 |     972.72459 |    596.316232 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                             |
| 108 |     633.00700 |    275.542857 | Margot Michaud                                                                                                                                                  |
| 109 |     204.82958 |    387.533587 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                |
| 110 |     998.21523 |    143.054514 | NA                                                                                                                                                              |
| 111 |     942.44912 |    271.811670 | kreidefossilien.de                                                                                                                                              |
| 112 |     681.28809 |    494.581224 | Steven Traver                                                                                                                                                   |
| 113 |     681.32789 |    759.712010 | Kamil S. Jaron                                                                                                                                                  |
| 114 |     828.04972 |    634.688788 | Zimices                                                                                                                                                         |
| 115 |     281.55706 |    505.463147 | Margot Michaud                                                                                                                                                  |
| 116 |     651.83327 |    169.411528 | Birgit Lang                                                                                                                                                     |
| 117 |     810.96597 |     61.303233 | Verdilak                                                                                                                                                        |
| 118 |     448.47763 |    116.811772 | Felix Vaux                                                                                                                                                      |
| 119 |     649.19587 |    319.926563 | Jagged Fang Designs                                                                                                                                             |
| 120 |     135.85046 |    122.102274 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                 |
| 121 |     479.20877 |    216.743317 | Gabriela Palomo-Munoz                                                                                                                                           |
| 122 |      46.95176 |    416.608676 | Air Kebir NRG                                                                                                                                                   |
| 123 |      65.72244 |    340.910993 | NA                                                                                                                                                              |
| 124 |     788.72565 |    678.122747 | Matt Crook                                                                                                                                                      |
| 125 |     632.64673 |    556.012173 | MPF (vectorized by T. Michael Keesey)                                                                                                                           |
| 126 |     817.55706 |    598.030515 | Beth Reinke                                                                                                                                                     |
| 127 |     903.95094 |    456.352655 | Jaime Headden                                                                                                                                                   |
| 128 |     172.65009 |    530.592711 | Michele Tobias                                                                                                                                                  |
| 129 |    1001.78928 |    477.638299 | Ferran Sayol                                                                                                                                                    |
| 130 |     106.67222 |    644.095471 | Jaime Headden                                                                                                                                                   |
| 131 |     699.73281 |    732.176457 | Gareth Monger                                                                                                                                                   |
| 132 |     508.66027 |    363.860661 | Jagged Fang Designs                                                                                                                                             |
| 133 |     642.42127 |    785.516523 | Gabriela Palomo-Munoz                                                                                                                                           |
| 134 |     922.71618 |    322.730724 | Scott Hartman                                                                                                                                                   |
| 135 |      55.02764 |    226.808231 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                               |
| 136 |     626.10748 |    208.178178 | Gareth Monger                                                                                                                                                   |
| 137 |     684.28982 |     48.106740 | Margot Michaud                                                                                                                                                  |
| 138 |     773.29394 |    429.833396 | Matt Crook                                                                                                                                                      |
| 139 |     996.11104 |    725.555604 | Margot Michaud                                                                                                                                                  |
| 140 |     710.61701 |    777.359909 | Matt Crook                                                                                                                                                      |
| 141 |      13.92877 |    537.212184 | Michael Scroggie                                                                                                                                                |
| 142 |     757.07246 |    403.295399 | Michael Scroggie                                                                                                                                                |
| 143 |     770.47218 |    346.499164 | Ferran Sayol                                                                                                                                                    |
| 144 |      32.39144 |    119.883612 | Gareth Monger                                                                                                                                                   |
| 145 |     498.11817 |    334.059528 | Zimices                                                                                                                                                         |
| 146 |     593.95372 |      8.978771 | Collin Gross                                                                                                                                                    |
| 147 |     596.71928 |    407.381653 | Kamil S. Jaron                                                                                                                                                  |
| 148 |     424.05573 |    182.201417 | Tauana J. Cunha                                                                                                                                                 |
| 149 |     704.15701 |    678.639828 | Steven Traver                                                                                                                                                   |
| 150 |      50.28323 |     46.955732 | NA                                                                                                                                                              |
| 151 |    1004.66135 |    242.661253 | Matt Crook                                                                                                                                                      |
| 152 |     631.18648 |    165.657566 | Jagged Fang Designs                                                                                                                                             |
| 153 |     892.23488 |    690.367349 | Jimmy Bernot                                                                                                                                                    |
| 154 |     304.30708 |    776.816511 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 155 |     405.00950 |      6.226880 | Noah Schlottman, photo by David J Patterson                                                                                                                     |
| 156 |     990.29071 |    406.097572 | NA                                                                                                                                                              |
| 157 |     628.85312 |    647.983451 | Matt Crook                                                                                                                                                      |
| 158 |     782.79961 |    222.156332 | Myriam\_Ramirez                                                                                                                                                 |
| 159 |    1012.99398 |    119.549229 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                  |
| 160 |      27.96006 |    365.426233 | Sarah Werning                                                                                                                                                   |
| 161 |     673.19353 |    388.143384 | Margot Michaud                                                                                                                                                  |
| 162 |     289.63182 |    567.427362 | Markus A. Grohme                                                                                                                                                |
| 163 |     177.49193 |    243.828226 | Caleb M. Brown                                                                                                                                                  |
| 164 |     601.63491 |    655.495800 | Zimices                                                                                                                                                         |
| 165 |     744.25570 |    700.428486 | Diana Pomeroy                                                                                                                                                   |
| 166 |     444.62702 |    264.734500 | Markus A. Grohme                                                                                                                                                |
| 167 |     213.95980 |    432.013402 | Maija Karala                                                                                                                                                    |
| 168 |     482.21758 |    514.271996 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                        |
| 169 |     416.29018 |    412.495181 | T. Michael Keesey                                                                                                                                               |
| 170 |      38.89134 |    481.432546 | Gareth Monger                                                                                                                                                   |
| 171 |      12.82922 |    460.209129 | NA                                                                                                                                                              |
| 172 |    1003.36722 |    437.085460 | Margot Michaud                                                                                                                                                  |
| 173 |     357.06291 |    408.403054 | C. Camilo Julián-Caballero                                                                                                                                      |
| 174 |     374.15704 |    731.080011 | Chris huh                                                                                                                                                       |
| 175 |     593.94299 |    449.947679 | Mattia Menchetti                                                                                                                                                |
| 176 |     764.01971 |    372.308287 | T. Michael Keesey                                                                                                                                               |
| 177 |     777.71775 |    786.914932 | Daniel Jaron                                                                                                                                                    |
| 178 |     476.51204 |    167.404250 | Gabriela Palomo-Munoz                                                                                                                                           |
| 179 |      91.21380 |    777.514510 | Steven Traver                                                                                                                                                   |
| 180 |     248.48822 |    237.229814 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 181 |     290.32029 |    353.873204 | Martin R. Smith                                                                                                                                                 |
| 182 |     237.59997 |    672.238322 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                   |
| 183 |     309.27380 |    139.853894 | Ferran Sayol                                                                                                                                                    |
| 184 |     397.72296 |    225.818184 | Gareth Monger                                                                                                                                                   |
| 185 |     513.62683 |    218.761010 | Tasman Dixon                                                                                                                                                    |
| 186 |    1003.11080 |    770.392501 | NA                                                                                                                                                              |
| 187 |     675.89473 |    183.994286 | Chris huh                                                                                                                                                       |
| 188 |     449.48719 |     27.827677 | Ignacio Contreras                                                                                                                                               |
| 189 |    1000.25744 |    365.151761 | Dean Schnabel                                                                                                                                                   |
| 190 |     485.42123 |    142.200228 | Scott Hartman                                                                                                                                                   |
| 191 |     723.20493 |    447.503357 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                        |
| 192 |     437.95423 |    562.802080 | Matt Crook                                                                                                                                                      |
| 193 |     208.56379 |    615.692461 | Jagged Fang Designs                                                                                                                                             |
| 194 |     314.58180 |    328.750146 | Matt Crook                                                                                                                                                      |
| 195 |      90.96920 |    411.306538 | NA                                                                                                                                                              |
| 196 |    1007.22973 |    193.065902 | Tauana J. Cunha                                                                                                                                                 |
| 197 |     133.18011 |    543.149200 | Andrew A. Farke                                                                                                                                                 |
| 198 |      15.33753 |    560.389510 | Felix Vaux                                                                                                                                                      |
| 199 |     613.55053 |    677.000082 | Chris huh                                                                                                                                                       |
| 200 |     548.69113 |    578.670784 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                    |
| 201 |     878.35108 |     47.518718 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 202 |     902.23979 |    474.345783 | Zimices                                                                                                                                                         |
| 203 |     859.15670 |     72.744131 | Margot Michaud                                                                                                                                                  |
| 204 |     948.23400 |    766.793583 | Andy Wilson                                                                                                                                                     |
| 205 |     185.62130 |    142.957052 | NA                                                                                                                                                              |
| 206 |     190.42049 |    696.458421 | NA                                                                                                                                                              |
| 207 |     616.78778 |    152.540314 | Tasman Dixon                                                                                                                                                    |
| 208 |      24.60714 |    640.251431 | Andy Wilson                                                                                                                                                     |
| 209 |     225.17872 |    292.819353 | Noah Schlottman, photo from Casey Dunn                                                                                                                          |
| 210 |     361.52935 |     43.186893 | Andy Wilson                                                                                                                                                     |
| 211 |     489.73862 |    288.783252 | SauropodomorphMonarch                                                                                                                                           |
| 212 |     178.64679 |    733.648078 | Kimberly Haddrell                                                                                                                                               |
| 213 |      32.81032 |    630.624156 | Emily Willoughby                                                                                                                                                |
| 214 |     195.73598 |    292.829141 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 215 |     646.38962 |    232.273356 | Sean McCann                                                                                                                                                     |
| 216 |     335.02474 |    665.508022 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 217 |     638.38616 |    141.283904 | Shyamal                                                                                                                                                         |
| 218 |     270.25806 |    531.259158 | Matt Crook                                                                                                                                                      |
| 219 |     687.54406 |    120.668873 | Rachel Shoop                                                                                                                                                    |
| 220 |     145.16321 |    625.126288 | Steven Traver                                                                                                                                                   |
| 221 |     807.09665 |    643.914558 | Gareth Monger                                                                                                                                                   |
| 222 |     912.59746 |     13.442274 | Margret Flinsch, vectorized by Zimices                                                                                                                          |
| 223 |     606.37148 |    569.017109 | Mathieu Pélissié                                                                                                                                                |
| 224 |     678.11907 |    742.947729 | Courtney Rockenbach                                                                                                                                             |
| 225 |     435.03590 |     14.832736 | FunkMonk                                                                                                                                                        |
| 226 |     648.85945 |    762.822531 | Roberto Díaz Sibaja                                                                                                                                             |
| 227 |     943.25692 |    207.506721 | Chris huh                                                                                                                                                       |
| 228 |     939.67716 |    224.401987 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                             |
| 229 |     281.72639 |    331.970532 | Zimices                                                                                                                                                         |
| 230 |     386.38051 |    297.022354 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                           |
| 231 |     611.06591 |    497.797076 | Gareth Monger                                                                                                                                                   |
| 232 |     560.81450 |    458.962829 | Jagged Fang Designs                                                                                                                                             |
| 233 |     774.85468 |    276.415510 | Margot Michaud                                                                                                                                                  |
| 234 |     285.91226 |    663.654788 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                           |
| 235 |     341.63935 |    255.129472 | Scott Hartman                                                                                                                                                   |
| 236 |     946.24506 |    684.785857 | Scott Hartman                                                                                                                                                   |
| 237 |     995.76970 |    163.659998 | Mathew Wedel                                                                                                                                                    |
| 238 |     694.99810 |    337.640939 | Michael P. Taylor                                                                                                                                               |
| 239 |     732.44522 |     98.063490 | Siobhon Egan                                                                                                                                                    |
| 240 |     375.77239 |    634.817346 | Tasman Dixon                                                                                                                                                    |
| 241 |     582.37519 |    586.926446 | James R. Spotila and Ray Chatterji                                                                                                                              |
| 242 |     219.15015 |    232.645332 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                 |
| 243 |     962.53577 |     15.152347 | B. Duygu Özpolat                                                                                                                                                |
| 244 |     992.02002 |    782.031182 | Scott Hartman                                                                                                                                                   |
| 245 |     237.91323 |     57.894262 | NA                                                                                                                                                              |
| 246 |     773.20993 |    559.794583 | CNZdenek                                                                                                                                                        |
| 247 |     877.96836 |      7.044271 | Margot Michaud                                                                                                                                                  |
| 248 |     792.76790 |    163.664480 | Margot Michaud                                                                                                                                                  |
| 249 |     160.46138 |    385.308443 | NA                                                                                                                                                              |
| 250 |     961.22981 |    189.734560 | Juan Carlos Jerí                                                                                                                                                |
| 251 |     328.05330 |    153.546244 | Matt Crook                                                                                                                                                      |
| 252 |      17.79858 |    342.659697 | Hugo Gruson                                                                                                                                                     |
| 253 |     124.93177 |    348.204915 | xgirouxb                                                                                                                                                        |
| 254 |     927.35628 |    181.886676 | Manabu Sakamoto                                                                                                                                                 |
| 255 |     652.22401 |    480.413203 | Steven Coombs                                                                                                                                                   |
| 256 |      47.13204 |    269.609728 | James R. Spotila and Ray Chatterji                                                                                                                              |
| 257 |     426.58330 |    223.640247 | Chris huh                                                                                                                                                       |
| 258 |     472.69691 |    465.078415 | Zimices                                                                                                                                                         |
| 259 |     643.08152 |    657.754583 | T. Michael Keesey                                                                                                                                               |
| 260 |      41.79082 |    344.353449 | Lukasiniho                                                                                                                                                      |
| 261 |     205.45332 |    732.742557 | Cristina Guijarro                                                                                                                                               |
| 262 |       9.02168 |    247.205262 | Gopal Murali                                                                                                                                                    |
| 263 |      99.21013 |    428.382749 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                   |
| 264 |     270.43929 |    556.318604 | Ferran Sayol                                                                                                                                                    |
| 265 |     477.04185 |    227.249532 | Tasman Dixon                                                                                                                                                    |
| 266 |     374.30592 |    610.590107 | NA                                                                                                                                                              |
| 267 |     481.21896 |    778.112737 | Gabriela Palomo-Munoz                                                                                                                                           |
| 268 |     340.08844 |    584.540887 | Katie S. Collins                                                                                                                                                |
| 269 |     407.97967 |     85.146967 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 270 |      44.39217 |    242.402783 | NA                                                                                                                                                              |
| 271 |     932.65317 |     27.542250 | Steven Traver                                                                                                                                                   |
| 272 |     307.78740 |    466.594833 | Lukasiniho                                                                                                                                                      |
| 273 |     743.48944 |    248.251127 | Mathilde Cordellier                                                                                                                                             |
| 274 |     612.05457 |    599.257561 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                   |
| 275 |     451.35715 |    340.216811 | Nobu Tamura                                                                                                                                                     |
| 276 |     654.82843 |     54.599681 | T. Michael Keesey                                                                                                                                               |
| 277 |     746.14152 |    584.023710 | Zimices                                                                                                                                                         |
| 278 |     520.19099 |    576.730428 | Andy Wilson                                                                                                                                                     |
| 279 |     108.72808 |     36.464366 | Yan Wong                                                                                                                                                        |
| 280 |     310.99813 |    232.742578 | Gareth Monger                                                                                                                                                   |
| 281 |     672.37591 |    784.256106 | Mathieu Pélissié                                                                                                                                                |
| 282 |     386.46513 |    318.460948 | Andy Wilson                                                                                                                                                     |
| 283 |     716.19521 |    721.923198 | Benjamin Monod-Broca                                                                                                                                            |
| 284 |     135.43121 |    789.061952 | Noah Schlottman                                                                                                                                                 |
| 285 |     142.27618 |    771.935049 | Matt Crook                                                                                                                                                      |
| 286 |     267.43043 |    126.824831 | Mo Hassan                                                                                                                                                       |
| 287 |     765.29798 |    754.837805 | T. Michael Keesey                                                                                                                                               |
| 288 |      17.14251 |    655.736241 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 289 |     274.83530 |    368.512099 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 290 |     141.05536 |    521.015996 | Zimices                                                                                                                                                         |
| 291 |     342.12854 |    427.806941 | Jaime Headden                                                                                                                                                   |
| 292 |     514.42058 |    250.241497 | Scott Hartman                                                                                                                                                   |
| 293 |     371.24316 |    659.191504 | Nina Skinner                                                                                                                                                    |
| 294 |     826.74201 |    503.148565 | Zimices                                                                                                                                                         |
| 295 |     945.15708 |    316.183028 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 296 |     408.85867 |    777.771224 | Erika Schumacher                                                                                                                                                |
| 297 |    1006.16352 |    668.390162 | Yan Wong                                                                                                                                                        |
| 298 |     629.55632 |     68.255368 | T. Michael Keesey                                                                                                                                               |
| 299 |     698.20447 |    320.248499 | Matt Crook                                                                                                                                                      |
| 300 |     798.91309 |    501.579566 | Collin Gross                                                                                                                                                    |
| 301 |     691.83625 |    601.851367 | Birgit Lang                                                                                                                                                     |
| 302 |     705.25158 |    386.243650 | Margot Michaud                                                                                                                                                  |
| 303 |     337.15408 |    749.329612 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                           |
| 304 |     778.12628 |    244.873495 | Ferran Sayol                                                                                                                                                    |
| 305 |     937.99445 |    344.312394 | Roberto Díaz Sibaja                                                                                                                                             |
| 306 |     471.43969 |    404.518600 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                  |
| 307 |     169.66196 |     86.070835 | Margot Michaud                                                                                                                                                  |
| 308 |     629.84416 |    477.580101 | Matt Crook                                                                                                                                                      |
| 309 |     420.27465 |     77.597792 | Dean Schnabel                                                                                                                                                   |
| 310 |      21.01456 |    420.495905 | NA                                                                                                                                                              |
| 311 |     871.39691 |    620.337863 | T. Michael Keesey                                                                                                                                               |
| 312 |     619.67704 |    194.311712 | Xavier Giroux-Bougard                                                                                                                                           |
| 313 |     496.16212 |    119.323231 | Kamil S. Jaron                                                                                                                                                  |
| 314 |     583.94547 |    780.351840 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                     |
| 315 |      22.93788 |     96.694289 | NA                                                                                                                                                              |
| 316 |     778.03784 |     40.004664 | Kimberly Haddrell                                                                                                                                               |
| 317 |     288.84330 |    789.326655 | C. Camilo Julián-Caballero                                                                                                                                      |
| 318 |     269.60140 |     15.998133 | NA                                                                                                                                                              |
| 319 |     494.60714 |    708.808388 | Verdilak                                                                                                                                                        |
| 320 |     751.25805 |    640.250322 | M Kolmann                                                                                                                                                       |
| 321 |     831.01326 |     91.793776 | Mathilde Cordellier                                                                                                                                             |
| 322 |     623.86781 |    668.978790 | Margot Michaud                                                                                                                                                  |
| 323 |     933.46029 |    388.010584 | T. Michael Keesey                                                                                                                                               |
| 324 |     109.04525 |    147.226933 | Christoph Schomburg                                                                                                                                             |
| 325 |     375.36005 |     75.706658 | Chris huh                                                                                                                                                       |
| 326 |     466.85431 |    546.608256 | Roberto Díaz Sibaja                                                                                                                                             |
| 327 |     258.44678 |    498.137361 | V. Deepak                                                                                                                                                       |
| 328 |      21.60226 |     30.970710 | CNZdenek                                                                                                                                                        |
| 329 |     912.50365 |    604.070105 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                              |
| 330 |     725.18589 |    503.045152 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                 |
| 331 |     735.14241 |    757.882073 | Joanna Wolfe                                                                                                                                                    |
| 332 |     410.39191 |    119.206953 | Steven Traver                                                                                                                                                   |
| 333 |     530.28734 |    266.021282 | Richard J. Harris                                                                                                                                               |
| 334 |     794.61425 |    742.882358 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 335 |      59.79755 |    306.832534 | John Conway                                                                                                                                                     |
| 336 |     110.20031 |    481.903289 | Jagged Fang Designs                                                                                                                                             |
| 337 |     203.21797 |    212.332941 | Jagged Fang Designs                                                                                                                                             |
| 338 |     425.41814 |    401.208660 | Scott Hartman                                                                                                                                                   |
| 339 |     360.98868 |    265.456013 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                   |
| 340 |     733.31801 |    770.163946 | NA                                                                                                                                                              |
| 341 |    1015.69954 |     88.225440 | Felix Vaux                                                                                                                                                      |
| 342 |     173.29416 |    761.978597 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 343 |     426.11570 |    254.518660 | Markus A. Grohme                                                                                                                                                |
| 344 |     865.05793 |    633.342319 | Tyler Greenfield                                                                                                                                                |
| 345 |     507.12417 |    231.498016 | Steven Traver                                                                                                                                                   |
| 346 |     414.59552 |    379.026095 | Yan Wong                                                                                                                                                        |
| 347 |     421.71139 |    477.043569 | Smokeybjb (modified by Mike Keesey)                                                                                                                             |
| 348 |     762.73939 |    458.529492 | Chris huh                                                                                                                                                       |
| 349 |     575.74928 |    482.952677 | Zimices                                                                                                                                                         |
| 350 |     145.18396 |    423.029604 | Zimices                                                                                                                                                         |
| 351 |      16.08718 |    678.003079 | Cesar Julian                                                                                                                                                    |
| 352 |     162.12464 |    748.189965 | Chris huh                                                                                                                                                       |
| 353 |     377.14914 |    125.655769 | Ferran Sayol                                                                                                                                                    |
| 354 |     734.68830 |    526.002845 | NA                                                                                                                                                              |
| 355 |     623.34789 |     11.535741 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                               |
| 356 |     398.11056 |    790.987011 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 357 |     180.94552 |    797.202997 | T. Michael Keesey                                                                                                                                               |
| 358 |     290.24364 |    425.308069 | Joanna Wolfe                                                                                                                                                    |
| 359 |     877.29221 |     75.786901 | Chris huh                                                                                                                                                       |
| 360 |     325.90095 |    578.949707 | Jagged Fang Designs                                                                                                                                             |
| 361 |    1003.68894 |     64.989249 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                               |
| 362 |     603.55356 |    429.111943 | Jagged Fang Designs                                                                                                                                             |
| 363 |     909.52978 |    547.609709 | Chuanixn Yu                                                                                                                                                     |
| 364 |      16.86083 |    762.785424 | Gabriela Palomo-Munoz                                                                                                                                           |
| 365 |      58.53535 |    787.261486 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                  |
| 366 |     206.85341 |    128.997210 | Zimices                                                                                                                                                         |
| 367 |     953.22720 |    111.645989 | Zimices                                                                                                                                                         |
| 368 |     628.28720 |    540.274316 | Jagged Fang Designs                                                                                                                                             |
| 369 |    1002.13986 |    690.523203 | Neil Kelley                                                                                                                                                     |
| 370 |     195.33946 |    254.104566 | Zimices                                                                                                                                                         |
| 371 |     437.28477 |    233.284991 | Smokeybjb, vectorized by Zimices                                                                                                                                |
| 372 |     390.86775 |    748.867510 | Steven Traver                                                                                                                                                   |
| 373 |     116.78620 |    626.373942 | Ferran Sayol                                                                                                                                                    |
| 374 |     214.35605 |    526.359653 | Andrew A. Farke                                                                                                                                                 |
| 375 |     425.72274 |    457.381333 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                   |
| 376 |     720.03187 |    480.240294 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                           |
| 377 |     956.62784 |    142.150700 | Collin Gross                                                                                                                                                    |
| 378 |     332.20521 |     83.737604 | Gabriela Palomo-Munoz                                                                                                                                           |
| 379 |     635.69481 |    295.972739 | Markus A. Grohme                                                                                                                                                |
| 380 |     237.28189 |    471.211590 | Markus A. Grohme                                                                                                                                                |
| 381 |     227.76045 |    498.181756 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                   |
| 382 |     757.26487 |    316.133846 | Steven Traver                                                                                                                                                   |
| 383 |      23.56320 |     43.457608 | Steven Coombs                                                                                                                                                   |
| 384 |     774.37413 |    287.580429 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                |
| 385 |     292.02657 |    314.262446 | Gareth Monger                                                                                                                                                   |
| 386 |    1010.50556 |    626.802110 | Gareth Monger                                                                                                                                                   |
| 387 |     572.71013 |    112.834813 | Scott Hartman                                                                                                                                                   |
| 388 |     905.49034 |    487.526509 | CNZdenek                                                                                                                                                        |
| 389 |     225.60971 |    643.885920 | NA                                                                                                                                                              |
| 390 |     151.08026 |    141.320828 | Jagged Fang Designs                                                                                                                                             |
| 391 |     303.28779 |    266.154116 | Erika Schumacher                                                                                                                                                |
| 392 |     365.89948 |    586.784270 | Ferran Sayol                                                                                                                                                    |
| 393 |     708.29813 |    111.874919 | Dmitry Bogdanov                                                                                                                                                 |
| 394 |     928.08577 |    361.938645 | Zimices                                                                                                                                                         |
| 395 |     512.02731 |     90.464561 | NA                                                                                                                                                              |
| 396 |     413.35903 |     24.931713 | Zimices                                                                                                                                                         |
| 397 |     565.62903 |    513.491698 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 398 |     289.48271 |    135.725146 | Gareth Monger                                                                                                                                                   |
| 399 |     678.35100 |    323.114954 | B. Duygu Özpolat                                                                                                                                                |
| 400 |     769.72569 |    332.435980 | NA                                                                                                                                                              |
| 401 |     483.14497 |    321.080249 | Mykle Hoban                                                                                                                                                     |
| 402 |     723.16135 |    402.681366 | T. Michael Keesey                                                                                                                                               |
| 403 |     630.11437 |    328.912308 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                   |
| 404 |     980.00173 |    463.690740 | Kanchi Nanjo                                                                                                                                                    |
| 405 |     616.30321 |    380.305734 | Matt Crook                                                                                                                                                      |
| 406 |     780.02302 |    394.663649 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 407 |      41.34544 |    382.821967 | Chuanixn Yu                                                                                                                                                     |
| 408 |     757.79078 |    214.535523 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 409 |     992.25270 |    575.165608 | Chris huh                                                                                                                                                       |
| 410 |     329.33938 |    561.434329 | Scott Hartman                                                                                                                                                   |
| 411 |     481.57078 |    794.174019 | xgirouxb                                                                                                                                                        |
| 412 |     319.88646 |    688.436167 | Ferran Sayol                                                                                                                                                    |
| 413 |     257.95819 |    615.984070 | L. Shyamal                                                                                                                                                      |
| 414 |     320.99511 |    661.055840 | Iain Reid                                                                                                                                                       |
| 415 |      24.71628 |    220.040047 | Andy Wilson                                                                                                                                                     |
| 416 |     986.21854 |    531.161920 | Matt Dempsey                                                                                                                                                    |
| 417 |     206.01431 |     62.323693 | Smokeybjb                                                                                                                                                       |
| 418 |    1006.49222 |    172.454548 | Chris huh                                                                                                                                                       |
| 419 |     675.60563 |     64.171575 | Jagged Fang Designs                                                                                                                                             |
| 420 |     353.75276 |    389.531413 | Mathew Wedel                                                                                                                                                    |
| 421 |    1013.52569 |    713.915823 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                            |
| 422 |     393.33053 |    519.526403 | Beth Reinke                                                                                                                                                     |
| 423 |      89.73323 |    792.297009 | Gabriela Palomo-Munoz                                                                                                                                           |
| 424 |      68.33173 |    408.074593 | Scott Hartman, modified by T. Michael Keesey                                                                                                                    |
| 425 |     519.02833 |      7.732091 | Chris huh                                                                                                                                                       |
| 426 |     269.28849 |    750.047393 | M Kolmann                                                                                                                                                       |
| 427 |     104.91284 |    310.612679 | Shyamal                                                                                                                                                         |
| 428 |    1006.15742 |    387.866620 | Collin Gross                                                                                                                                                    |
| 429 |      48.47093 |    397.690133 | Jagged Fang Designs                                                                                                                                             |
| 430 |    1002.14892 |    558.046088 | NA                                                                                                                                                              |
| 431 |     698.56505 |    650.677974 | Birgit Lang                                                                                                                                                     |
| 432 |     283.88302 |    454.954838 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 433 |     123.66956 |    420.334831 | Manabu Sakamoto                                                                                                                                                 |
| 434 |     244.00081 |     21.693852 | Birgit Lang                                                                                                                                                     |
| 435 |     458.86001 |    574.568372 | Steven Traver                                                                                                                                                   |
| 436 |     333.49693 |    414.090713 | Noah Schlottman                                                                                                                                                 |
| 437 |      38.43064 |     17.447499 | Jagged Fang Designs                                                                                                                                             |
| 438 |     194.91795 |      6.497643 | Lisa Byrne                                                                                                                                                      |
| 439 |     983.16378 |    359.426284 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                     |
| 440 |     282.49319 |    696.167759 | Alex Slavenko                                                                                                                                                   |
| 441 |     353.84184 |    465.429750 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                   |
| 442 |     628.34718 |    396.915244 | Scott Hartman                                                                                                                                                   |
| 443 |      27.23051 |    793.452375 | Chris huh                                                                                                                                                       |
| 444 |     607.79611 |    775.844668 | Emily Willoughby                                                                                                                                                |
| 445 |    1014.25972 |    325.895798 | Kai R. Caspar                                                                                                                                                   |
| 446 |      85.97318 |    298.822388 | Christoph Schomburg                                                                                                                                             |
| 447 |     157.76795 |    149.214923 | Scott Hartman                                                                                                                                                   |
| 448 |     737.68575 |    225.214527 | Steven Coombs                                                                                                                                                   |
| 449 |     510.18769 |    734.361896 | Mark Witton                                                                                                                                                     |
| 450 |     701.24318 |    467.362467 | Ingo Braasch                                                                                                                                                    |
| 451 |     184.26668 |    416.130749 | Gabriela Palomo-Munoz                                                                                                                                           |
| 452 |     782.52568 |    652.617994 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                     |
| 453 |      80.78327 |    482.527785 | FunkMonk                                                                                                                                                        |
| 454 |     636.64945 |    252.801580 | Scott Hartman                                                                                                                                                   |
| 455 |     347.61197 |    726.915296 | Dean Schnabel                                                                                                                                                   |
| 456 |      34.18387 |    773.517735 | Jagged Fang Designs                                                                                                                                             |
| 457 |     918.73347 |    441.841898 | Ferran Sayol                                                                                                                                                    |
| 458 |     316.68944 |    310.085099 | NA                                                                                                                                                              |
| 459 |     434.32869 |    469.711055 | Gareth Monger                                                                                                                                                   |
| 460 |     564.24617 |     81.844242 | Matt Crook                                                                                                                                                      |
| 461 |     450.94424 |    789.561637 | Scott Hartman                                                                                                                                                   |
| 462 |     128.10803 |    184.031478 | Joanna Wolfe                                                                                                                                                    |
| 463 |     534.27733 |    383.787479 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 464 |     247.19800 |     49.234904 | Noah Schlottman, photo by Casey Dunn                                                                                                                            |
| 465 |     961.89943 |    536.450547 | DW Bapst (Modified from Bulman, 1964)                                                                                                                           |
| 466 |     825.73562 |    518.995031 | Kent Elson Sorgon                                                                                                                                               |
| 467 |     154.58356 |    547.536465 | Chris huh                                                                                                                                                       |
| 468 |     346.86243 |    675.892811 | Zimices                                                                                                                                                         |
| 469 |     669.19617 |    586.718497 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 470 |     663.36587 |    631.024870 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                           |
| 471 |     518.59074 |    281.578405 | Sarah Werning                                                                                                                                                   |
| 472 |     235.82938 |    317.076170 | Becky Barnes                                                                                                                                                    |
| 473 |     393.98957 |    278.897032 | Matt Crook                                                                                                                                                      |
| 474 |     220.46557 |    537.533919 | Scott Hartman                                                                                                                                                   |
| 475 |      64.83674 |    118.542232 | Renata F. Martins                                                                                                                                               |
| 476 |     951.50665 |    398.540842 | Emily Willoughby                                                                                                                                                |
| 477 |     127.55641 |    491.690318 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                 |
| 478 |     391.90820 |    562.381123 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                    |
| 479 |     284.64020 |     90.029443 | Chris huh                                                                                                                                                       |
| 480 |      34.41815 |    144.106739 | Scott Hartman                                                                                                                                                   |
| 481 |     351.47051 |    314.799484 | Jagged Fang Designs                                                                                                                                             |
| 482 |     755.82847 |    383.147074 | Xavier Giroux-Bougard                                                                                                                                           |
| 483 |     440.04372 |    209.269611 | Steven Traver                                                                                                                                                   |
| 484 |     667.65734 |    133.055039 | Steven Haddock • Jellywatch.org                                                                                                                                 |
| 485 |     479.86682 |    133.639285 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 486 |      78.59302 |    432.014340 | Lafage                                                                                                                                                          |
| 487 |     279.47357 |    600.194350 | Scott Hartman                                                                                                                                                   |
| 488 |     518.18445 |    303.391747 | Chris huh                                                                                                                                                       |
| 489 |     439.87308 |    361.316241 | Francesca Belem Lopes Palmeira                                                                                                                                  |
| 490 |     361.02199 |    740.543253 | Caleb M. Brown                                                                                                                                                  |
| 491 |     933.24125 |    784.862912 | terngirl                                                                                                                                                        |
| 492 |     583.42332 |    560.170281 | T. Tischler                                                                                                                                                     |
| 493 |     982.46320 |    516.409170 | Ignacio Contreras                                                                                                                                               |
| 494 |     623.44558 |    231.363880 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 495 |      67.05334 |    494.313520 | Jagged Fang Designs                                                                                                                                             |
| 496 |     263.32147 |    652.494391 | NA                                                                                                                                                              |
| 497 |     372.67557 |     59.595410 | Margot Michaud                                                                                                                                                  |
| 498 |     604.13267 |     29.391330 | Chuanixn Yu                                                                                                                                                     |
| 499 |      20.79900 |    157.095872 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                 |
| 500 |     459.53812 |    533.467838 | Jagged Fang Designs                                                                                                                                             |
| 501 |     479.71739 |    198.993411 | Chris huh                                                                                                                                                       |
| 502 |     420.59644 |    717.851623 | Carlos Cano-Barbacil                                                                                                                                            |
| 503 |     705.69213 |     59.107306 | Gareth Monger                                                                                                                                                   |
| 504 |     351.29115 |    245.856241 | xgirouxb                                                                                                                                                        |
| 505 |     502.15779 |    382.593347 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 506 |     382.50882 |    246.815401 | Erika Schumacher                                                                                                                                                |
| 507 |     394.73332 |     41.363912 | Henry Lydecker                                                                                                                                                  |
| 508 |     847.13476 |     65.430276 | Pranav Iyer (grey ideas)                                                                                                                                        |
| 509 |     556.36013 |    134.488095 | Christopher Chávez                                                                                                                                              |
| 510 |     408.58429 |    428.667227 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 511 |     940.49648 |    547.046160 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                |
| 512 |     345.71224 |    565.305730 | T. Michael Keesey (after Heinrich Harder)                                                                                                                       |
| 513 |     145.03151 |    367.648420 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                 |
| 514 |      23.88902 |    256.321594 | Maija Karala                                                                                                                                                    |
| 515 |     304.56199 |    796.364924 | Markus A. Grohme                                                                                                                                                |
| 516 |     473.19878 |    476.365814 | Henry Lydecker                                                                                                                                                  |
| 517 |     362.98577 |    432.940623 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 518 |     439.97067 |    593.565016 | Jaime Headden                                                                                                                                                   |
| 519 |      41.63302 |    658.680289 | Lauren Sumner-Rooney                                                                                                                                            |
| 520 |     758.92012 |    445.196664 | Chris huh                                                                                                                                                       |
| 521 |     417.56956 |    794.143146 | Erika Schumacher                                                                                                                                                |
| 522 |     773.05037 |    474.200009 | Michelle Site                                                                                                                                                   |
| 523 |    1006.80529 |    452.314942 | Sean McCann                                                                                                                                                     |
| 524 |     444.71052 |    277.760987 | Gareth Monger                                                                                                                                                   |
| 525 |     548.68810 |    507.199005 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                 |
| 526 |      24.28299 |     53.598675 | Tyler Greenfield                                                                                                                                                |
| 527 |     435.68967 |    149.071781 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                |
| 528 |     934.33561 |     94.508910 | Tyler Greenfield                                                                                                                                                |
| 529 |     345.51684 |    331.056275 | Sarah Werning                                                                                                                                                   |
| 530 |     171.07829 |    621.467389 | Zimices                                                                                                                                                         |

    #> Your tweet has been posted!
