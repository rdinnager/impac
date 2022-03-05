
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

Rebecca Groom, Yan Wong from illustration by Jules Richard (1907),
Zimices, Kanchi Nanjo, Pedro de Siracusa, Andreas Hejnol, Steven Coombs,
Collin Gross, Gareth Monger, Mali’o Kodis, photograph by Cordell
Expeditions at Cal Academy, Ferran Sayol, Margot Michaud, Jakovche,
Chris huh, Andy Wilson, Hans Hillewaert (vectorized by T. Michael
Keesey), Andreas Preuss / marauder, Jagged Fang Designs, Matt Crook, E.
R. Waite & H. M. Hale (vectorized by T. Michael Keesey), CNZdenek,
Tauana J. Cunha, Ignacio Contreras, Steven Traver, Sarah Werning, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Blanco et al., 2014,
vectorized by Zimices, Michele Tobias, Ghedoghedo (vectorized by T.
Michael Keesey), Jaime Headden, Zachary Quigley, Smokeybjb, Erika
Schumacher, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), T. Michael Keesey, Jerry Oldenettel (vectorized by T.
Michael Keesey), Alexandre Vong, Shyamal, FunkMonk, M Kolmann, Jonathan
Wells, Darren Naish (vectorize by T. Michael Keesey), New York
Zoological Society, George Edward Lodge, Kai R. Caspar, Scott Reid, Nobu
Tamura, Steven Haddock • Jellywatch.org, Julio Garza, Emma Kissling,
Xavier Giroux-Bougard, Robert Gay, Javiera Constanzo, Andrew Farke and
Joseph Sertich, Christoph Schomburg, Dean Schnabel, Nick Schooler, Kent
Elson Sorgon, Nobu Tamura (vectorized by T. Michael Keesey), Gabriela
Palomo-Munoz, Renata F. Martins, JCGiron, Javier Luque, Armin Reindl,
Joanna Wolfe, Nobu Tamura (modified by T. Michael Keesey), Tasman Dixon,
Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey), Ian Burt
(original) and T. Michael Keesey (vectorization), C. Camilo
Julián-Caballero, Carlos Cano-Barbacil, Scott Hartman, Robbie N. Cada
(modified by T. Michael Keesey), Jaime Headden, modified by T. Michael
Keesey, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J.
Bartley (silhouette), Matt Wilkins (photo by Patrick Kavanagh), Maxime
Dahirel, Birgit Lang, Manabu Bessho-Uehara, Noah Schlottman, photo by
Hans De Blauwe, Crystal Maier, George Edward Lodge (modified by T.
Michael Keesey), Kristina Gagalova, Yan Wong, Pranav Iyer (grey ideas),
Maija Karala, Michelle Site, Obsidian Soul (vectorized by T. Michael
Keesey), François Michonneau, Henry Fairfield Osborn, vectorized by
Zimices, zoosnow, Roberto Díaz Sibaja, Kamil S. Jaron, David Sim
(photograph) and T. Michael Keesey (vectorization), Jack Mayer Wood,
Archaeodontosaurus (vectorized by T. Michael Keesey), T. Michael Keesey
(after A. Y. Ivantsov), Chloé Schmidt, Kimberly Haddrell, Robert Hering,
Matt Martyniuk (vectorized by T. Michael Keesey), Alexander
Schmidt-Lebuhn, Nobu Tamura, modified by Andrew A. Farke, Samanta
Orellana, (unknown), Michael Scroggie, Prin Pattawaro (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Tracy A. Heath,
Trond R. Oskars, Jose Carlos Arenas-Monroy, Steve Hillebrand/U. S. Fish
and Wildlife Service (source photo), T. Michael Keesey (vectorization),
Chuanixn Yu, Beth Reinke, L. Shyamal, Harold N Eyster, Sebastian
Stabinger, Lukasiniho, Dmitry Bogdanov, Felix Vaux and Steven A.
Trewick, JJ Harrison (vectorized by T. Michael Keesey), Caio Bernardes,
vectorized by Zimices, Mo Hassan, Emily Willoughby, Matus Valach, Sharon
Wegner-Larsen, Vanessa Guerra, Matt Martyniuk, Mali’o Kodis, image by
Rebecca Ritger, Francis de Laporte de Castelnau (vectorized by T.
Michael Keesey), Tyler Greenfield, DW Bapst (Modified from Bulman,
1964), Allison Pease, Marie Russell, Warren H (photography), T. Michael
Keesey (vectorization), Tyler McCraney, Bruno Maggia, Michele M Tobias,
Markus A. Grohme, Stephen O’Connor (vectorized by T. Michael Keesey),
Milton Tan, Andrew A. Farke, Felix Vaux, Martin Kevil, Gopal Murali,
Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist, Óscar
San-Isidro (vectorized by T. Michael Keesey), Todd Marshall, vectorized
by Zimices, Duane Raver (vectorized by T. Michael Keesey), Dave
Angelini, Tambja (vectorized by T. Michael Keesey), James R. Spotila and
Ray Chatterji, Jake Warner, Saguaro Pictures (source photo) and T.
Michael Keesey, Mette Aumala, Ingo Braasch, Smokeybjb, vectorized by
Zimices, Ludwik Gasiorowski, Matt Wilkins, Nobu Tamura, vectorized by
Zimices, Michael B. H. (vectorized by T. Michael Keesey), Neil Kelley,
Darius Nau, Apokryltaros (vectorized by T. Michael Keesey), Donovan
Reginald Rosevear (vectorized by T. Michael Keesey), T. Michael Keesey
(from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel
Vences), Josefine Bohr Brask, H. Filhol (vectorized by T. Michael
Keesey), Christopher Laumer (vectorized by T. Michael Keesey), Henry
Lydecker, White Wolf, Verisimilus, Dianne Bray / Museum Victoria
(vectorized by T. Michael Keesey), Dexter R. Mardis, David Orr,
Pollyanna von Knorring and T. Michael Keesey, Conty (vectorized by T.
Michael Keesey), Darren Naish (vectorized by T. Michael Keesey), Mattia
Menchetti, Nobu Tamura (vectorized by A. Verrière), John Conway, , Ernst
Haeckel (vectorized by T. Michael Keesey), Pete Buchholz, Amanda Katzer,
Michael P. Taylor, T. Michael Keesey (after Heinrich Harder), M
Hutchinson, Matt Dempsey, Zsoldos Márton (vectorized by T. Michael
Keesey), Mathew Wedel, SauropodomorphMonarch, T. Michael Keesey (after
James & al.)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    806.609082 |    633.354352 | Rebecca Groom                                                                                                                                                  |
|   2 |    321.165887 |    377.629565 | Yan Wong from illustration by Jules Richard (1907)                                                                                                             |
|   3 |    911.210450 |    606.610477 | Zimices                                                                                                                                                        |
|   4 |    659.404323 |    158.045859 | Kanchi Nanjo                                                                                                                                                   |
|   5 |    359.159582 |    649.806526 | Pedro de Siracusa                                                                                                                                              |
|   6 |    621.807187 |    561.826059 | Andreas Hejnol                                                                                                                                                 |
|   7 |    585.505851 |    337.491955 | Steven Coombs                                                                                                                                                  |
|   8 |    448.360019 |     71.799519 | Steven Coombs                                                                                                                                                  |
|   9 |    535.891278 |    667.898616 | Collin Gross                                                                                                                                                   |
|  10 |    718.407742 |    448.829415 | Gareth Monger                                                                                                                                                  |
|  11 |    872.914696 |    224.421198 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                 |
|  12 |    170.584363 |    633.144138 | Ferran Sayol                                                                                                                                                   |
|  13 |    422.134367 |    272.905526 | Margot Michaud                                                                                                                                                 |
|  14 |    509.185597 |    153.117038 | Jakovche                                                                                                                                                       |
|  15 |    577.743071 |    448.433987 | Ferran Sayol                                                                                                                                                   |
|  16 |     82.157738 |    420.696935 | Chris huh                                                                                                                                                      |
|  17 |     75.030610 |    199.946394 | Andy Wilson                                                                                                                                                    |
|  18 |    347.287494 |    463.499083 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
|  19 |    120.861055 |     39.595864 | Andreas Preuss / marauder                                                                                                                                      |
|  20 |    572.209947 |    769.997745 | Jagged Fang Designs                                                                                                                                            |
|  21 |    938.059748 |     51.341921 | NA                                                                                                                                                             |
|  22 |    389.877777 |    729.473167 | Matt Crook                                                                                                                                                     |
|  23 |    857.601585 |    335.256951 | Zimices                                                                                                                                                        |
|  24 |    236.611224 |    777.437249 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
|  25 |    194.978993 |    253.208773 | CNZdenek                                                                                                                                                       |
|  26 |    262.424849 |    112.910428 | Tauana J. Cunha                                                                                                                                                |
|  27 |    715.977018 |    746.259583 | Ignacio Contreras                                                                                                                                              |
|  28 |    795.582104 |    145.796306 | Steven Traver                                                                                                                                                  |
|  29 |    184.645927 |    311.329426 | Sarah Werning                                                                                                                                                  |
|  30 |    286.431357 |    566.053334 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  31 |    900.602497 |    767.366147 | Blanco et al., 2014, vectorized by Zimices                                                                                                                     |
|  32 |    768.928317 |    547.677994 | Michele Tobias                                                                                                                                                 |
|  33 |    836.401053 |    706.041653 | Chris huh                                                                                                                                                      |
|  34 |    166.804056 |    500.728153 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
|  35 |    959.918608 |    429.173344 | Jaime Headden                                                                                                                                                  |
|  36 |    443.711849 |    770.778130 | Zachary Quigley                                                                                                                                                |
|  37 |    452.605794 |    535.892859 | NA                                                                                                                                                             |
|  38 |     92.115305 |    106.312400 | Jagged Fang Designs                                                                                                                                            |
|  39 |    445.792358 |     33.879465 | Smokeybjb                                                                                                                                                      |
|  40 |    888.936567 |    102.040089 | Erika Schumacher                                                                                                                                               |
|  41 |    897.919550 |    469.912222 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                |
|  42 |    339.630127 |    726.960010 | T. Michael Keesey                                                                                                                                              |
|  43 |    743.587454 |    238.371356 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                             |
|  44 |    971.017233 |    298.880104 | Alexandre Vong                                                                                                                                                 |
|  45 |    777.690304 |     57.424267 | Margot Michaud                                                                                                                                                 |
|  46 |    684.499419 |    674.670793 | Shyamal                                                                                                                                                        |
|  47 |    224.764355 |    209.407444 | Chris huh                                                                                                                                                      |
|  48 |    956.200934 |    690.834138 | FunkMonk                                                                                                                                                       |
|  49 |    595.090547 |    260.651904 | Margot Michaud                                                                                                                                                 |
|  50 |    479.390074 |    206.242100 | M Kolmann                                                                                                                                                      |
|  51 |     89.060870 |    326.979795 | Sarah Werning                                                                                                                                                  |
|  52 |    770.497303 |    286.636449 | Jonathan Wells                                                                                                                                                 |
|  53 |    390.442016 |    155.553538 | Steven Coombs                                                                                                                                                  |
|  54 |     62.219862 |    540.465888 | M Kolmann                                                                                                                                                      |
|  55 |    220.703619 |    438.809197 | Steven Traver                                                                                                                                                  |
|  56 |    305.839104 |    305.863246 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
|  57 |    504.584960 |    527.212599 | Gareth Monger                                                                                                                                                  |
|  58 |    676.344388 |    620.751541 | Chris huh                                                                                                                                                      |
|  59 |     82.303133 |    718.927790 | New York Zoological Society                                                                                                                                    |
|  60 |    934.898530 |    517.100026 | T. Michael Keesey                                                                                                                                              |
|  61 |    805.059501 |    393.345438 | George Edward Lodge                                                                                                                                            |
|  62 |    498.330198 |    427.366656 | Kai R. Caspar                                                                                                                                                  |
|  63 |    973.490078 |    205.550121 | Scott Reid                                                                                                                                                     |
|  64 |    112.462160 |    164.494521 | Steven Traver                                                                                                                                                  |
|  65 |    533.132722 |    290.422366 | Nobu Tamura                                                                                                                                                    |
|  66 |    336.476214 |     40.238666 | Jagged Fang Designs                                                                                                                                            |
|  67 |    951.948752 |    388.255143 | Steven Haddock • Jellywatch.org                                                                                                                                |
|  68 |    593.707085 |     27.268443 | FunkMonk                                                                                                                                                       |
|  69 |    706.715234 |    357.265502 | Julio Garza                                                                                                                                                    |
|  70 |    338.978285 |    198.937841 | Chris huh                                                                                                                                                      |
|  71 |    422.103189 |    336.684409 | Emma Kissling                                                                                                                                                  |
|  72 |    242.573270 |    542.863709 | Xavier Giroux-Bougard                                                                                                                                          |
|  73 |    138.119694 |    262.831586 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  74 |    379.535758 |    576.866971 | Robert Gay                                                                                                                                                     |
|  75 |    538.433524 |     55.483363 | Jagged Fang Designs                                                                                                                                            |
|  76 |    595.593169 |    377.636649 | Javiera Constanzo                                                                                                                                              |
|  77 |    865.828892 |     32.186365 | Andrew Farke and Joseph Sertich                                                                                                                                |
|  78 |    810.280196 |    505.336490 | Christoph Schomburg                                                                                                                                            |
|  79 |     43.473945 |    557.044863 | Chris huh                                                                                                                                                      |
|  80 |    231.668843 |    332.337114 | Dean Schnabel                                                                                                                                                  |
|  81 |    790.057071 |    475.701814 | Rebecca Groom                                                                                                                                                  |
|  82 |    215.951623 |     43.055473 | Andy Wilson                                                                                                                                                    |
|  83 |     58.827792 |    462.065479 | Nick Schooler                                                                                                                                                  |
|  84 |    425.841935 |    114.407282 | Kent Elson Sorgon                                                                                                                                              |
|  85 |    693.483398 |    569.589885 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  86 |    592.030374 |    119.739239 | Christoph Schomburg                                                                                                                                            |
|  87 |    546.679833 |    715.357362 | Gabriela Palomo-Munoz                                                                                                                                          |
|  88 |    671.788397 |    419.839125 | Renata F. Martins                                                                                                                                              |
|  89 |    237.013262 |    748.953075 | NA                                                                                                                                                             |
|  90 |    984.023732 |    564.364302 | JCGiron                                                                                                                                                        |
|  91 |    975.362469 |    114.391909 | Javier Luque                                                                                                                                                   |
|  92 |    978.188401 |     18.539760 | Zimices                                                                                                                                                        |
|  93 |    684.493633 |    306.787695 | Armin Reindl                                                                                                                                                   |
|  94 |    854.745843 |    583.785175 | Joanna Wolfe                                                                                                                                                   |
|  95 |    471.999260 |    748.805301 | T. Michael Keesey                                                                                                                                              |
|  96 |    161.650887 |    465.403252 | Jagged Fang Designs                                                                                                                                            |
|  97 |     43.966616 |    633.280918 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
|  98 |    374.676191 |    511.885055 | Tasman Dixon                                                                                                                                                   |
|  99 |    614.588250 |    486.004413 | Matt Crook                                                                                                                                                     |
| 100 |    357.089245 |     94.998332 | Margot Michaud                                                                                                                                                 |
| 101 |     57.080606 |    606.026149 | Jagged Fang Designs                                                                                                                                            |
| 102 |    167.659743 |    133.545061 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                 |
| 103 |    255.000798 |    179.849121 | Steven Traver                                                                                                                                                  |
| 104 |    186.162608 |    577.976780 | NA                                                                                                                                                             |
| 105 |     36.006966 |    329.639046 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                      |
| 106 |     23.234838 |    406.033211 | C. Camilo Julián-Caballero                                                                                                                                     |
| 107 |    139.701799 |    231.216893 | Carlos Cano-Barbacil                                                                                                                                           |
| 108 |    974.260441 |    737.525267 | Scott Hartman                                                                                                                                                  |
| 109 |    684.420910 |    392.274883 | Scott Hartman                                                                                                                                                  |
| 110 |     39.184462 |    484.370391 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
| 111 |    162.152853 |    408.865647 | Jaime Headden                                                                                                                                                  |
| 112 |    946.150752 |    349.546924 | Scott Hartman                                                                                                                                                  |
| 113 |    840.885728 |    787.384488 | Jagged Fang Designs                                                                                                                                            |
| 114 |    569.109890 |    509.487133 | Jaime Headden, modified by T. Michael Keesey                                                                                                                   |
| 115 |    242.496710 |    282.652389 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 116 |     37.127128 |    393.633635 | Chris huh                                                                                                                                                      |
| 117 |    185.122953 |    348.705046 | Gabriela Palomo-Munoz                                                                                                                                          |
| 118 |     25.171138 |    244.215652 | T. Michael Keesey                                                                                                                                              |
| 119 |    280.776210 |    683.973270 | Steven Traver                                                                                                                                                  |
| 120 |    797.706626 |    260.319219 | Margot Michaud                                                                                                                                                 |
| 121 |    503.284260 |    103.966012 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                       |
| 122 |    260.992113 |    343.427438 | Gareth Monger                                                                                                                                                  |
| 123 |    196.007560 |     23.275748 | Ferran Sayol                                                                                                                                                   |
| 124 |    665.963389 |     24.300612 | Maxime Dahirel                                                                                                                                                 |
| 125 |    487.347628 |     58.101427 | Jagged Fang Designs                                                                                                                                            |
| 126 |    464.255806 |    166.050593 | Ferran Sayol                                                                                                                                                   |
| 127 |    417.450659 |    555.638512 | Scott Hartman                                                                                                                                                  |
| 128 |    907.565647 |    545.890436 | Birgit Lang                                                                                                                                                    |
| 129 |    870.394337 |    542.469611 | Chris huh                                                                                                                                                      |
| 130 |    771.095016 |    418.871267 | Manabu Bessho-Uehara                                                                                                                                           |
| 131 |    635.610860 |    432.719122 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                       |
| 132 |    765.741305 |    672.451198 | Margot Michaud                                                                                                                                                 |
| 133 |    417.423864 |    603.451780 | Gabriela Palomo-Munoz                                                                                                                                          |
| 134 |    726.497250 |    597.372532 | Birgit Lang                                                                                                                                                    |
| 135 |    713.575264 |    409.982440 | Gareth Monger                                                                                                                                                  |
| 136 |    992.303424 |    667.234941 | Collin Gross                                                                                                                                                   |
| 137 |    996.144210 |    504.958343 | Crystal Maier                                                                                                                                                  |
| 138 |    938.470444 |    644.026904 | FunkMonk                                                                                                                                                       |
| 139 |    571.854936 |     52.296233 | Blanco et al., 2014, vectorized by Zimices                                                                                                                     |
| 140 |   1002.429964 |    777.000615 | Matt Crook                                                                                                                                                     |
| 141 |    882.427207 |    135.437715 | Steven Traver                                                                                                                                                  |
| 142 |    852.101614 |    744.653249 | Nobu Tamura                                                                                                                                                    |
| 143 |    167.871661 |     86.142780 | Matt Crook                                                                                                                                                     |
| 144 |    602.154062 |    723.674499 | Ferran Sayol                                                                                                                                                   |
| 145 |    539.482108 |     36.317094 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                            |
| 146 |    751.060487 |    709.502784 | Kristina Gagalova                                                                                                                                              |
| 147 |    184.797136 |    295.085560 | Yan Wong                                                                                                                                                       |
| 148 |    109.210574 |    783.536261 | Chris huh                                                                                                                                                      |
| 149 |    610.301370 |     89.946995 | Andy Wilson                                                                                                                                                    |
| 150 |    756.024810 |     19.458532 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 151 |    792.991023 |    221.466219 | Gabriela Palomo-Munoz                                                                                                                                          |
| 152 |    554.055786 |    540.415574 | Zimices                                                                                                                                                        |
| 153 |     37.770511 |    361.818165 | Maija Karala                                                                                                                                                   |
| 154 |    189.737271 |     65.475244 | Margot Michaud                                                                                                                                                 |
| 155 |    569.683657 |    210.584491 | Michelle Site                                                                                                                                                  |
| 156 |    696.697973 |    585.696679 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 157 |    407.368231 |    429.237977 | Matt Crook                                                                                                                                                     |
| 158 |    694.931691 |     21.212655 | Birgit Lang                                                                                                                                                    |
| 159 |    188.193584 |    727.442183 | François Michonneau                                                                                                                                            |
| 160 |    989.534455 |    603.997748 | Matt Crook                                                                                                                                                     |
| 161 |    165.058357 |     48.092698 | Margot Michaud                                                                                                                                                 |
| 162 |    214.217950 |    188.098135 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                  |
| 163 |    332.831544 |     19.485219 | Chris huh                                                                                                                                                      |
| 164 |    935.964830 |    273.979560 | zoosnow                                                                                                                                                        |
| 165 |    207.516159 |    406.110875 | NA                                                                                                                                                             |
| 166 |    550.935472 |    585.115216 | Roberto Díaz Sibaja                                                                                                                                            |
| 167 |    473.428552 |     10.866453 | Kamil S. Jaron                                                                                                                                                 |
| 168 |    411.902665 |    129.449489 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                   |
| 169 |     70.545377 |    685.631558 | Margot Michaud                                                                                                                                                 |
| 170 |     16.541963 |    663.544494 | Matt Crook                                                                                                                                                     |
| 171 |    296.144174 |    639.893857 | NA                                                                                                                                                             |
| 172 |    803.393950 |    748.003565 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 173 |    703.300438 |    324.781052 | Jack Mayer Wood                                                                                                                                                |
| 174 |    934.802938 |     30.696900 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                           |
| 175 |     55.684121 |    128.565468 | Zimices                                                                                                                                                        |
| 176 |    349.117876 |    123.316706 | Matt Crook                                                                                                                                                     |
| 177 |    135.881952 |    743.912679 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                       |
| 178 |     36.474079 |     81.966371 | Crystal Maier                                                                                                                                                  |
| 179 |    571.084957 |    558.153995 | Chloé Schmidt                                                                                                                                                  |
| 180 |     91.089547 |    606.059786 | M Kolmann                                                                                                                                                      |
| 181 |    299.825033 |    246.438013 | NA                                                                                                                                                             |
| 182 |    136.196499 |     81.486991 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 183 |    727.304562 |    113.923627 | Sarah Werning                                                                                                                                                  |
| 184 |    750.434386 |    321.287623 | Kimberly Haddrell                                                                                                                                              |
| 185 |     58.659946 |    260.027063 | Ferran Sayol                                                                                                                                                   |
| 186 |    722.442567 |    389.739051 | Robert Hering                                                                                                                                                  |
| 187 |    838.834829 |    532.501799 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 188 |    657.017181 |    491.655659 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                               |
| 189 |    477.619717 |    303.010034 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 190 |     98.263542 |    448.585298 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                       |
| 191 |    668.014855 |    710.241826 | Steven Traver                                                                                                                                                  |
| 192 |    310.020682 |    599.059466 | Matt Crook                                                                                                                                                     |
| 193 |     15.814080 |    779.405057 | Samanta Orellana                                                                                                                                               |
| 194 |    603.002556 |    518.624092 | Steven Coombs                                                                                                                                                  |
| 195 |    419.031170 |    648.710422 | Matt Crook                                                                                                                                                     |
| 196 |    312.033434 |     82.844977 | Sarah Werning                                                                                                                                                  |
| 197 |    586.125192 |    223.475055 | T. Michael Keesey                                                                                                                                              |
| 198 |    686.718694 |    541.229532 | Gabriela Palomo-Munoz                                                                                                                                          |
| 199 |    101.071533 |    388.820111 | Nobu Tamura                                                                                                                                                    |
| 200 |    921.465492 |    143.522667 | Kamil S. Jaron                                                                                                                                                 |
| 201 |   1002.800452 |    168.457831 | (unknown)                                                                                                                                                      |
| 202 |    798.890734 |    768.723710 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 203 |    626.476308 |    749.261690 | NA                                                                                                                                                             |
| 204 |     20.994070 |    121.506220 | T. Michael Keesey                                                                                                                                              |
| 205 |    547.614570 |    475.304557 | Michael Scroggie                                                                                                                                               |
| 206 |    299.107520 |    619.673889 | Margot Michaud                                                                                                                                                 |
| 207 |    284.237724 |    256.215577 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 208 |    885.907037 |    687.658116 | Gabriela Palomo-Munoz                                                                                                                                          |
| 209 |    356.960725 |     63.219481 | Steven Traver                                                                                                                                                  |
| 210 |    601.292156 |    461.360090 | Gabriela Palomo-Munoz                                                                                                                                          |
| 211 |    578.842320 |     64.006315 | Chris huh                                                                                                                                                      |
| 212 |    795.411161 |     97.362557 | Tracy A. Heath                                                                                                                                                 |
| 213 |    697.311659 |     41.936428 | Zimices                                                                                                                                                        |
| 214 |     41.719569 |     29.706681 | Margot Michaud                                                                                                                                                 |
| 215 |    959.812668 |    619.929831 | Gabriela Palomo-Munoz                                                                                                                                          |
| 216 |    853.475329 |    367.503227 | Gareth Monger                                                                                                                                                  |
| 217 |    672.428061 |     54.915269 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 218 |    421.140834 |    312.581654 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                 |
| 219 |    799.254370 |    199.378552 | Trond R. Oskars                                                                                                                                                |
| 220 |    879.186762 |    749.555330 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 221 |    121.399865 |    470.809964 | Steven Traver                                                                                                                                                  |
| 222 |    214.074945 |    152.688732 | Armin Reindl                                                                                                                                                   |
| 223 |      6.846031 |    163.328627 | Xavier Giroux-Bougard                                                                                                                                          |
| 224 |    152.966995 |    785.680314 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                             |
| 225 |    477.941916 |    196.888431 | FunkMonk                                                                                                                                                       |
| 226 |     65.254383 |    773.272038 | Matt Crook                                                                                                                                                     |
| 227 |   1001.501983 |    714.828112 | Chuanixn Yu                                                                                                                                                    |
| 228 |    413.112486 |    189.873660 | Beth Reinke                                                                                                                                                    |
| 229 |     41.756290 |    519.165643 | L. Shyamal                                                                                                                                                     |
| 230 |    639.392231 |     44.701619 | Harold N Eyster                                                                                                                                                |
| 231 |    381.207172 |    542.310999 | Gabriela Palomo-Munoz                                                                                                                                          |
| 232 |    757.641896 |    689.189632 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 233 |    835.042535 |    452.412033 | NA                                                                                                                                                             |
| 234 |    286.574603 |    503.164343 | Gabriela Palomo-Munoz                                                                                                                                          |
| 235 |    419.111189 |    749.769468 | Sebastian Stabinger                                                                                                                                            |
| 236 |    452.467454 |    148.384747 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 237 |    965.055943 |    784.670886 | Lukasiniho                                                                                                                                                     |
| 238 |    158.401604 |    762.552988 | NA                                                                                                                                                             |
| 239 |    735.901138 |     89.882908 | T. Michael Keesey                                                                                                                                              |
| 240 |    195.239503 |    747.393501 | Dmitry Bogdanov                                                                                                                                                |
| 241 |    705.147990 |    506.536697 | Zimices                                                                                                                                                        |
| 242 |    165.122513 |    546.920360 | Felix Vaux and Steven A. Trewick                                                                                                                               |
| 243 |    658.317331 |    304.576056 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                  |
| 244 |    904.569078 |    662.755310 | Caio Bernardes, vectorized by Zimices                                                                                                                          |
| 245 |    532.855050 |    120.789344 | Rebecca Groom                                                                                                                                                  |
| 246 |    953.572317 |    745.567357 | Mo Hassan                                                                                                                                                      |
| 247 |    648.337325 |    771.649920 | Matt Crook                                                                                                                                                     |
| 248 |    923.551127 |    754.252100 | Emily Willoughby                                                                                                                                               |
| 249 |    500.336453 |    314.483488 | T. Michael Keesey                                                                                                                                              |
| 250 |    354.410602 |    544.977164 | Margot Michaud                                                                                                                                                 |
| 251 |    114.181439 |    216.184678 | Jagged Fang Designs                                                                                                                                            |
| 252 |    884.082490 |    730.778819 | Jagged Fang Designs                                                                                                                                            |
| 253 |    657.672624 |    787.214497 | Ferran Sayol                                                                                                                                                   |
| 254 |     91.788666 |    293.935220 | Matus Valach                                                                                                                                                   |
| 255 |    872.771588 |    379.678951 | Sharon Wegner-Larsen                                                                                                                                           |
| 256 |    818.366345 |    271.391146 | Chris huh                                                                                                                                                      |
| 257 |    564.927912 |    402.177823 | Gareth Monger                                                                                                                                                  |
| 258 |     36.273860 |    788.248567 | Tracy A. Heath                                                                                                                                                 |
| 259 |    596.546694 |    295.646919 | Margot Michaud                                                                                                                                                 |
| 260 |    288.287568 |     46.247398 | Zimices                                                                                                                                                        |
| 261 |     34.144194 |    583.027803 | Zimices                                                                                                                                                        |
| 262 |    721.399166 |    644.527537 | Vanessa Guerra                                                                                                                                                 |
| 263 |    529.775604 |    686.155072 | Matt Martyniuk                                                                                                                                                 |
| 264 |     70.920174 |    668.476956 | Margot Michaud                                                                                                                                                 |
| 265 |    981.123634 |    142.206337 | Carlos Cano-Barbacil                                                                                                                                           |
| 266 |    731.083655 |    166.816521 | Matt Martyniuk                                                                                                                                                 |
| 267 |     62.689554 |    568.749860 | Chris huh                                                                                                                                                      |
| 268 |    433.399745 |    452.674975 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                          |
| 269 |    593.086577 |    776.432427 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                              |
| 270 |    138.608424 |    535.563986 | Tasman Dixon                                                                                                                                                   |
| 271 |    532.745384 |    235.657849 | Tyler Greenfield                                                                                                                                               |
| 272 |    547.734930 |    229.511390 | Gareth Monger                                                                                                                                                  |
| 273 |    357.122601 |     40.685305 | DW Bapst (Modified from Bulman, 1964)                                                                                                                          |
| 274 |    132.557002 |    446.727076 | Allison Pease                                                                                                                                                  |
| 275 |    720.558997 |    423.480912 | Margot Michaud                                                                                                                                                 |
| 276 |    526.537860 |    747.998090 | T. Michael Keesey                                                                                                                                              |
| 277 |    543.356572 |    574.713727 | Ferran Sayol                                                                                                                                                   |
| 278 |    418.089480 |    488.048003 | Matt Crook                                                                                                                                                     |
| 279 |    320.467607 |    794.264100 | Gareth Monger                                                                                                                                                  |
| 280 |     36.180995 |     55.448497 | Birgit Lang                                                                                                                                                    |
| 281 |     74.745366 |    226.472697 | Gareth Monger                                                                                                                                                  |
| 282 |    203.703859 |    794.813277 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 283 |    150.172227 |    205.619307 | Marie Russell                                                                                                                                                  |
| 284 |    756.694085 |    245.731256 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                      |
| 285 |    978.421132 |     36.636904 | Jagged Fang Designs                                                                                                                                            |
| 286 |    255.250888 |    728.645206 | Zimices                                                                                                                                                        |
| 287 |    914.105892 |    133.314355 | Dmitry Bogdanov                                                                                                                                                |
| 288 |    719.119525 |    290.207416 | Tyler McCraney                                                                                                                                                 |
| 289 |    666.822017 |    545.392045 | Christoph Schomburg                                                                                                                                            |
| 290 |    312.821974 |    757.150432 | Gabriela Palomo-Munoz                                                                                                                                          |
| 291 |    193.125490 |    563.402597 | Andy Wilson                                                                                                                                                    |
| 292 |    295.469685 |    425.995976 | Ferran Sayol                                                                                                                                                   |
| 293 |    165.292104 |    438.854513 | Zimices                                                                                                                                                        |
| 294 |    573.555342 |    103.732212 | Maija Karala                                                                                                                                                   |
| 295 |    417.035832 |     50.785630 | Matt Crook                                                                                                                                                     |
| 296 |    385.159325 |     97.604483 | Gareth Monger                                                                                                                                                  |
| 297 |    119.563436 |    734.069634 | Tasman Dixon                                                                                                                                                   |
| 298 |    300.933137 |    350.524490 | Bruno Maggia                                                                                                                                                   |
| 299 |     93.121821 |    567.534781 | Andy Wilson                                                                                                                                                    |
| 300 |     25.128366 |    293.981373 | Ferran Sayol                                                                                                                                                   |
| 301 |    475.142845 |    232.964834 | Yan Wong                                                                                                                                                       |
| 302 |    903.386508 |     37.782169 | Gabriela Palomo-Munoz                                                                                                                                          |
| 303 |    709.779058 |    301.818246 | Jagged Fang Designs                                                                                                                                            |
| 304 |    471.541162 |     49.424342 | Christoph Schomburg                                                                                                                                            |
| 305 |    897.159935 |    515.704376 | Michele M Tobias                                                                                                                                               |
| 306 |    998.245283 |    463.967524 | Markus A. Grohme                                                                                                                                               |
| 307 |    475.171998 |    216.009164 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                             |
| 308 |    567.944586 |    368.223106 | NA                                                                                                                                                             |
| 309 |    418.068516 |    616.865019 | Caio Bernardes, vectorized by Zimices                                                                                                                          |
| 310 |     16.371326 |    744.107768 | Gareth Monger                                                                                                                                                  |
| 311 |    104.621497 |    526.622773 | Christoph Schomburg                                                                                                                                            |
| 312 |    782.974931 |    703.571120 | Steven Traver                                                                                                                                                  |
| 313 |    271.722369 |    330.025498 | Milton Tan                                                                                                                                                     |
| 314 |    990.800607 |     76.606088 | T. Michael Keesey                                                                                                                                              |
| 315 |    629.668994 |    288.925320 | Chris huh                                                                                                                                                      |
| 316 |    904.792135 |    386.208685 | Andrew A. Farke                                                                                                                                                |
| 317 |    787.073403 |    733.990058 | Margot Michaud                                                                                                                                                 |
| 318 |     15.385947 |    343.306802 | Michael Scroggie                                                                                                                                               |
| 319 |    421.343026 |     17.435681 | Chuanixn Yu                                                                                                                                                    |
| 320 |    298.328347 |    184.597197 | L. Shyamal                                                                                                                                                     |
| 321 |    970.673969 |     72.624801 | Felix Vaux                                                                                                                                                     |
| 322 |    918.246367 |     64.099853 | Christoph Schomburg                                                                                                                                            |
| 323 |    344.490346 |    277.254284 | Chris huh                                                                                                                                                      |
| 324 |    324.013032 |    776.164116 | Collin Gross                                                                                                                                                   |
| 325 |    717.879305 |    697.033274 | Martin Kevil                                                                                                                                                   |
| 326 |   1004.527264 |    685.186360 | Jaime Headden                                                                                                                                                  |
| 327 |    423.498992 |    297.667205 | Margot Michaud                                                                                                                                                 |
| 328 |   1013.408722 |    120.967509 | Gopal Murali                                                                                                                                                   |
| 329 |    450.283553 |    609.859625 | Zimices                                                                                                                                                        |
| 330 |    292.622474 |    747.403325 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 331 |    936.672173 |    572.239274 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                              |
| 332 |    741.384525 |    496.650348 | NA                                                                                                                                                             |
| 333 |    837.337455 |    296.871174 | Scott Hartman                                                                                                                                                  |
| 334 |    528.296411 |    264.243781 | Felix Vaux                                                                                                                                                     |
| 335 |    176.480090 |    170.322489 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                             |
| 336 |    904.536589 |    294.487787 | Jagged Fang Designs                                                                                                                                            |
| 337 |    104.734178 |    178.839791 | Xavier Giroux-Bougard                                                                                                                                          |
| 338 |    715.027560 |    141.000477 | Matt Crook                                                                                                                                                     |
| 339 |    608.345484 |    793.969856 | Todd Marshall, vectorized by Zimices                                                                                                                           |
| 340 |    303.795828 |      7.468282 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                  |
| 341 |    591.218383 |    200.334944 | Dave Angelini                                                                                                                                                  |
| 342 |    975.121717 |    763.713048 | Scott Hartman                                                                                                                                                  |
| 343 |    758.324341 |    794.993387 | Tambja (vectorized by T. Michael Keesey)                                                                                                                       |
| 344 |    424.829984 |    518.923965 | Tracy A. Heath                                                                                                                                                 |
| 345 |     37.475733 |    768.028312 | Chris huh                                                                                                                                                      |
| 346 |    666.862452 |    380.875873 | Jagged Fang Designs                                                                                                                                            |
| 347 |    630.157373 |    721.686736 | Felix Vaux                                                                                                                                                     |
| 348 |     25.376508 |    380.637400 | Matt Crook                                                                                                                                                     |
| 349 |     21.166462 |     15.933581 | Gareth Monger                                                                                                                                                  |
| 350 |     18.985694 |    445.795232 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 351 |    195.357641 |    143.685819 | Jake Warner                                                                                                                                                    |
| 352 |      8.588364 |    135.207256 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                          |
| 353 |    390.209966 |      7.015202 | Chris huh                                                                                                                                                      |
| 354 |    521.167633 |      5.348041 | Markus A. Grohme                                                                                                                                               |
| 355 |    139.320837 |    428.072405 | Mette Aumala                                                                                                                                                   |
| 356 |    711.735110 |     90.716810 | Yan Wong                                                                                                                                                       |
| 357 |    614.418420 |    223.322246 | Ingo Braasch                                                                                                                                                   |
| 358 |    865.076526 |     62.275160 | Andy Wilson                                                                                                                                                    |
| 359 |    666.862181 |    646.009986 | Scott Hartman                                                                                                                                                  |
| 360 |    109.110630 |    598.456325 | FunkMonk                                                                                                                                                       |
| 361 |    915.692108 |    359.540890 | Smokeybjb, vectorized by Zimices                                                                                                                               |
| 362 |     95.919933 |     63.530132 | T. Michael Keesey                                                                                                                                              |
| 363 |    656.665184 |    285.388060 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 364 |    953.355603 |    728.749822 | Lukasiniho                                                                                                                                                     |
| 365 |    580.308331 |    300.927196 | C. Camilo Julián-Caballero                                                                                                                                     |
| 366 |    391.398707 |    411.626523 | Scott Hartman                                                                                                                                                  |
| 367 |    592.044056 |    482.862157 | Yan Wong                                                                                                                                                       |
| 368 |    382.227214 |    430.738896 | Jagged Fang Designs                                                                                                                                            |
| 369 |    345.899821 |    146.546778 | Markus A. Grohme                                                                                                                                               |
| 370 |    203.066112 |    468.807820 | Gareth Monger                                                                                                                                                  |
| 371 |    915.527339 |    788.327857 | Margot Michaud                                                                                                                                                 |
| 372 |     85.602444 |     80.432462 | Matt Martyniuk                                                                                                                                                 |
| 373 |    892.805755 |    161.810924 | Chris huh                                                                                                                                                      |
| 374 |   1011.613762 |    352.859057 | Ludwik Gasiorowski                                                                                                                                             |
| 375 |    477.212596 |    322.596909 | Andrew A. Farke                                                                                                                                                |
| 376 |    258.512898 |    475.294695 | Collin Gross                                                                                                                                                   |
| 377 |    484.039149 |    588.418401 | Matt Crook                                                                                                                                                     |
| 378 |    841.007249 |    546.264191 | Chris huh                                                                                                                                                      |
| 379 |    767.886817 |    201.956786 | Gareth Monger                                                                                                                                                  |
| 380 |    680.390309 |    776.979668 | Markus A. Grohme                                                                                                                                               |
| 381 |    864.092892 |    411.307062 | Matt Wilkins                                                                                                                                                   |
| 382 |     88.878543 |    713.191042 | NA                                                                                                                                                             |
| 383 |    925.976787 |    372.842464 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 384 |    566.896750 |    133.690364 | Andy Wilson                                                                                                                                                    |
| 385 |    728.495352 |    576.593917 | Matt Crook                                                                                                                                                     |
| 386 |    445.466790 |    323.774671 | Milton Tan                                                                                                                                                     |
| 387 |    825.842893 |    478.467061 | Matt Crook                                                                                                                                                     |
| 388 |    141.064515 |    673.291292 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
| 389 |    678.330399 |    509.281455 | Gabriela Palomo-Munoz                                                                                                                                          |
| 390 |    380.199560 |    135.716999 | Sarah Werning                                                                                                                                                  |
| 391 |    327.542070 |    520.883238 | Neil Kelley                                                                                                                                                    |
| 392 |    857.110860 |    611.932150 | Darius Nau                                                                                                                                                     |
| 393 |    496.732950 |    712.511249 | Scott Hartman                                                                                                                                                  |
| 394 |    547.987072 |    791.091382 | Dmitry Bogdanov                                                                                                                                                |
| 395 |    881.235155 |    634.513062 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 396 |    808.876003 |    589.534011 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
| 397 |    450.834131 |     23.647955 | Ignacio Contreras                                                                                                                                              |
| 398 |    575.893031 |    740.461422 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                    |
| 399 |    823.476654 |     91.262015 | Steven Traver                                                                                                                                                  |
| 400 |    362.958932 |     25.225558 | Robert Gay                                                                                                                                                     |
| 401 |    517.938843 |    781.774994 | NA                                                                                                                                                             |
| 402 |    692.185402 |    526.563221 | Zimices                                                                                                                                                        |
| 403 |    308.195440 |    410.813820 | Scott Hartman                                                                                                                                                  |
| 404 |    402.832358 |    539.178414 | Tasman Dixon                                                                                                                                                   |
| 405 |    215.639073 |    353.657241 | Lukasiniho                                                                                                                                                     |
| 406 |    280.741880 |    600.207992 | Michelle Site                                                                                                                                                  |
| 407 |    676.039716 |    269.766774 | Steven Traver                                                                                                                                                  |
| 408 |    260.518163 |     31.362426 | Scott Hartman                                                                                                                                                  |
| 409 |    728.119017 |     10.467325 | Kamil S. Jaron                                                                                                                                                 |
| 410 |    455.324963 |    790.722038 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                              |
| 411 |    800.598035 |    696.103805 | Rebecca Groom                                                                                                                                                  |
| 412 |    788.070346 |      8.901028 | Tasman Dixon                                                                                                                                                   |
| 413 |    703.190030 |     70.218292 | Markus A. Grohme                                                                                                                                               |
| 414 |    237.678061 |    791.450105 | Steven Traver                                                                                                                                                  |
| 415 |    755.445605 |     95.182651 | Jake Warner                                                                                                                                                    |
| 416 |    348.811660 |    440.947274 | Matt Crook                                                                                                                                                     |
| 417 |    433.213715 |    219.547656 | Jagged Fang Designs                                                                                                                                            |
| 418 |    879.132438 |      8.615708 | T. Michael Keesey                                                                                                                                              |
| 419 |    654.471984 |    450.657672 | Steven Traver                                                                                                                                                  |
| 420 |    913.862615 |    733.106992 | Gareth Monger                                                                                                                                                  |
| 421 |    459.077801 |    713.780662 | Markus A. Grohme                                                                                                                                               |
| 422 |    458.822564 |    101.625001 | Chris huh                                                                                                                                                      |
| 423 |    442.459566 |    134.741892 | Josefine Bohr Brask                                                                                                                                            |
| 424 |    392.010940 |    221.888086 | Kai R. Caspar                                                                                                                                                  |
| 425 |    814.132198 |    454.701708 | Chris huh                                                                                                                                                      |
| 426 |     15.815494 |    702.064541 | Kanchi Nanjo                                                                                                                                                   |
| 427 |    315.711987 |    698.568744 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                    |
| 428 |    499.830097 |    226.619947 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 429 |    554.221248 |    126.675684 | Robert Gay                                                                                                                                                     |
| 430 |    149.715626 |    731.125017 | Tauana J. Cunha                                                                                                                                                |
| 431 |     86.563151 |    741.335157 | Kimberly Haddrell                                                                                                                                              |
| 432 |    744.710596 |    378.380832 | Markus A. Grohme                                                                                                                                               |
| 433 |    122.744862 |    773.480469 | Ferran Sayol                                                                                                                                                   |
| 434 |   1008.542578 |    151.822614 | Zimices                                                                                                                                                        |
| 435 |     55.608973 |    708.550191 | Maija Karala                                                                                                                                                   |
| 436 |    220.486443 |    462.228929 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                           |
| 437 |    316.061046 |    222.763807 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
| 438 |    604.584056 |     38.543095 | Matt Crook                                                                                                                                                     |
| 439 |    523.370324 |     87.700355 | Henry Lydecker                                                                                                                                                 |
| 440 |    566.047217 |    234.082449 | Margot Michaud                                                                                                                                                 |
| 441 |    718.985338 |    189.469531 | Ignacio Contreras                                                                                                                                              |
| 442 |    849.639579 |    282.398764 | White Wolf                                                                                                                                                     |
| 443 |    266.695451 |    405.924242 | Jagged Fang Designs                                                                                                                                            |
| 444 |    358.560488 |    714.046812 | Chris huh                                                                                                                                                      |
| 445 |   1009.881399 |     69.430352 | Gareth Monger                                                                                                                                                  |
| 446 |    534.674104 |    364.857189 | NA                                                                                                                                                             |
| 447 |    258.837663 |     38.593299 | NA                                                                                                                                                             |
| 448 |    422.025987 |    791.221420 | NA                                                                                                                                                             |
| 449 |    790.274668 |    793.590281 | Verisimilus                                                                                                                                                    |
| 450 |    447.744182 |    175.353327 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                |
| 451 |     64.372419 |    527.945481 | Dexter R. Mardis                                                                                                                                               |
| 452 |    212.875652 |    579.997711 | T. Michael Keesey                                                                                                                                              |
| 453 |    527.609650 |    393.821844 | David Orr                                                                                                                                                      |
| 454 |    885.147971 |    148.806256 | Zimices                                                                                                                                                        |
| 455 |    471.373027 |    721.990171 | FunkMonk                                                                                                                                                       |
| 456 |    739.034763 |    335.778480 | Matt Crook                                                                                                                                                     |
| 457 |     24.473676 |    514.320190 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                   |
| 458 |    867.218232 |    558.975413 | Chris huh                                                                                                                                                      |
| 459 |    916.774361 |    420.416083 | Andrew A. Farke                                                                                                                                                |
| 460 |    903.516986 |    649.733225 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 461 |    281.730237 |    758.975889 | Andrew A. Farke                                                                                                                                                |
| 462 |    766.972942 |      9.176089 | Margot Michaud                                                                                                                                                 |
| 463 |    848.893784 |    433.557585 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                 |
| 464 |    591.782638 |    175.277895 | Julio Garza                                                                                                                                                    |
| 465 |    939.622796 |    225.658104 | Gabriela Palomo-Munoz                                                                                                                                          |
| 466 |    722.265778 |    789.021646 | Mattia Menchetti                                                                                                                                               |
| 467 |    741.939956 |    269.414150 | Chris huh                                                                                                                                                      |
| 468 |    439.992016 |    184.820929 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 469 |    331.139837 |    166.796245 | Scott Hartman                                                                                                                                                  |
| 470 |    665.722438 |    588.222582 | Tasman Dixon                                                                                                                                                   |
| 471 |    640.830596 |      7.813610 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                        |
| 472 |    482.220291 |    546.483837 | Margot Michaud                                                                                                                                                 |
| 473 |    274.171784 |    635.158833 | Zimices                                                                                                                                                        |
| 474 |   1011.947682 |    647.657279 | Zimices                                                                                                                                                        |
| 475 |    290.616478 |     68.643516 | Margot Michaud                                                                                                                                                 |
| 476 |    893.989793 |    580.074748 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 477 |    460.866125 |    475.823019 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 478 |    866.277659 |    640.426722 | Scott Hartman                                                                                                                                                  |
| 479 |    803.310803 |    179.877532 | John Conway                                                                                                                                                    |
| 480 |    743.802231 |    299.748974 | Ferran Sayol                                                                                                                                                   |
| 481 |    970.910980 |    710.491163 | Steven Traver                                                                                                                                                  |
| 482 |    852.865979 |    482.598743 |                                                                                                                                                                |
| 483 |    124.966380 |    306.091060 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                |
| 484 |    465.927390 |    460.268938 | Tasman Dixon                                                                                                                                                   |
| 485 |    193.718796 |     95.240670 | Ferran Sayol                                                                                                                                                   |
| 486 |    315.011868 |    232.658850 | Zimices                                                                                                                                                        |
| 487 |    373.384227 |    406.145514 | Pete Buchholz                                                                                                                                                  |
| 488 |    617.456017 |    421.574931 | Matt Crook                                                                                                                                                     |
| 489 |    973.533693 |    470.782197 | Amanda Katzer                                                                                                                                                  |
| 490 |    612.372706 |     72.983665 | Scott Hartman                                                                                                                                                  |
| 491 |    916.566118 |    409.270535 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 492 |    618.172261 |    399.390962 | Tracy A. Heath                                                                                                                                                 |
| 493 |    596.677078 |    137.125310 | T. Michael Keesey                                                                                                                                              |
| 494 |    746.498329 |    608.183711 | Michael P. Taylor                                                                                                                                              |
| 495 |    259.370913 |     16.311538 | Margot Michaud                                                                                                                                                 |
| 496 |    171.609914 |    111.436708 | T. Michael Keesey (after Heinrich Harder)                                                                                                                      |
| 497 |    822.670790 |    735.700852 | Zimices                                                                                                                                                        |
| 498 |    972.080378 |    514.229149 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 499 |    651.474766 |    689.716545 | NA                                                                                                                                                             |
| 500 |    849.968333 |    681.197387 | Jagged Fang Designs                                                                                                                                            |
| 501 |    829.721734 |     71.131818 | Chuanixn Yu                                                                                                                                                    |
| 502 |    153.612242 |    338.091119 | Zimices                                                                                                                                                        |
| 503 |    204.108416 |    593.342763 | Kai R. Caspar                                                                                                                                                  |
| 504 |    172.349107 |    155.356070 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 505 |    155.994740 |     66.733426 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 506 |   1003.326935 |    623.256040 | Steven Traver                                                                                                                                                  |
| 507 |    452.833042 |    733.589471 | Jaime Headden                                                                                                                                                  |
| 508 |    480.332743 |    275.716042 | M Hutchinson                                                                                                                                                   |
| 509 |    889.505346 |    787.895742 | Matt Dempsey                                                                                                                                                   |
| 510 |      3.845702 |     44.682598 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 511 |    504.343532 |    457.725261 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                               |
| 512 |     47.796789 |    667.731206 | Jagged Fang Designs                                                                                                                                            |
| 513 |    908.610474 |    678.874970 | Mathew Wedel                                                                                                                                                   |
| 514 |    212.294819 |    176.994091 | Scott Hartman                                                                                                                                                  |
| 515 |    142.211407 |    358.935049 | Matt Crook                                                                                                                                                     |
| 516 |    434.660000 |    411.175678 | Jagged Fang Designs                                                                                                                                            |
| 517 |    379.698234 |    123.372756 | NA                                                                                                                                                             |
| 518 |    785.754376 |    513.307233 | Scott Hartman                                                                                                                                                  |
| 519 |    448.958300 |      6.171321 | Gareth Monger                                                                                                                                                  |
| 520 |    740.982146 |    366.424774 | Scott Hartman                                                                                                                                                  |
| 521 |    855.151943 |    737.096758 | SauropodomorphMonarch                                                                                                                                          |
| 522 |    965.437082 |      3.341193 | Scott Hartman                                                                                                                                                  |
| 523 |    364.229369 |    794.176284 | C. Camilo Julián-Caballero                                                                                                                                     |
| 524 |     37.855634 |    138.656283 | Beth Reinke                                                                                                                                                    |
| 525 |    641.109566 |    393.041746 | Jaime Headden                                                                                                                                                  |
| 526 |    350.101450 |    331.659752 | NA                                                                                                                                                             |
| 527 |    331.729790 |    582.100884 | T. Michael Keesey (after James & al.)                                                                                                                          |
| 528 |    378.633013 |    181.862650 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                       |
| 529 |     15.472717 |    549.300408 | Gareth Monger                                                                                                                                                  |

    #> Your tweet has been posted!
