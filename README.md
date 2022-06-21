
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

Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey), Matt
Crook, M Hutchinson, Jaime A. Headden (vectorized by T. Michael Keesey),
Joanna Wolfe, Margot Michaud, Jaime Headden, Nobu Tamura, Kai R. Caspar,
Sharon Wegner-Larsen, Jay Matternes, vectorized by Zimices, T. Michael
Keesey, Verdilak, Christoph Schomburg, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Tracy A. Heath, Matt Martyniuk, Michael Day, Mali’o
Kodis, image from the “Proceedings of the Zoological Society of London”,
Chris huh, Leann Biancani, photo by Kenneth Clifton, Lukasiniho, Lauren
Sumner-Rooney, Emily Jane McTavish, from Haeckel, E. H. P. A.
(1904).Kunstformen der Natur. Bibliographisches, Gareth Monger, U.S.
National Park Service (vectorized by William Gearty), Mathieu Basille,
Markus A. Grohme, Sarah Werning, FunkMonk, DW Bapst (modified from Bates
et al., 2005), Emily Willoughby, Gopal Murali, Andy Wilson, Oscar
Sanisidro, Sean McCann, Alex Slavenko, Ferran Sayol, Tasman Dixon,
Steven Coombs, Zimices, Jagged Fang Designs, Carlos Cano-Barbacil, Alan
Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Scott Hartman, Steven Traver, Gabriela Palomo-Munoz,
Henry Lydecker, Dmitry Bogdanov, Ghedoghedo (vectorized by T. Michael
Keesey), Yan Wong, Christine Axon, Mattia Menchetti, Josefine Bohr
Brask, Jiekun He, Mateus Zica (modified by T. Michael Keesey), Ignacio
Contreras, Martien Brand (original photo), Renato Santos (vector
silhouette), Andrew A. Farke, Lily Hughes, Tyler Greenfield and Scott
Hartman, terngirl, Madeleine Price Ball, Lafage, Maxwell Lefroy
(vectorized by T. Michael Keesey), Ben Moon, T. Michael Keesey (after
Masteraah), Erika Schumacher, FJDegrange, Apokryltaros (vectorized by T.
Michael Keesey), Alexandre Vong, Shyamal, Mike Hanson, Francesco
“Architetto” Rollandin, Smokeybjb, vectorized by Zimices, Ieuan Jones,
Raven Amos, Anthony Caravaggi, Anna Willoughby, Martin Kevil, Michael
Scroggie, Nina Skinner, Martin R. Smith, after Skovsted et al 2015,
Xavier Giroux-Bougard, Noah Schlottman, photo by David J Patterson,
Peileppe, Jessica Anne Miller, T. Michael Keesey (vector) and Stuart
Halliday (photograph), Birgit Lang, based on a photo by D. Sikes, Kailah
Thorn & Mark Hutchinson, Michael P. Taylor, Caleb M. Brown, Tauana J.
Cunha, Inessa Voet, Mathilde Cordellier, Collin Gross, Nobu Tamura,
vectorized by Zimices, Roderic Page and Lois Page, Neil Kelley, M
Kolmann, Robert Gay, Lukas Panzarin, Conty (vectorized by T. Michael
Keesey), Sergio A. Muñoz-Gómez, Kanako Bessho-Uehara, Frank Förster,
Melissa Broussard, Javier Luque & Sarah Gerken, Birgit Lang, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Unknown (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Robbie N. Cada (modified by T. Michael
Keesey), (after McCulloch 1908), Nicholas J. Czaplewski, vectorized by
Zimices, Smokeybjb, Chris Hay, Chuanixn Yu, Jonathan Wells, Renata F.
Martins, Steven Blackwood, Pete Buchholz, Sarah Alewijnse, Jakovche,
Saguaro Pictures (source photo) and T. Michael Keesey, M. Garfield & K.
Anderson (modified by T. Michael Keesey), Lukas Panzarin (vectorized by
T. Michael Keesey), xgirouxb, Dean Schnabel, Riccardo Percudani, Nobu
Tamura (vectorized by T. Michael Keesey), Mali’o Kodis, photograph by
“Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>), Mihai
Dragos (vectorized by T. Michael Keesey), Ramona J Heim, Brad McFeeters
(vectorized by T. Michael Keesey), Amanda Katzer, Martin R. Smith, Yan
Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo),
Zachary Quigley, Alexander Schmidt-Lebuhn, Matt Dempsey, Timothy Knepp
(vectorized by T. Michael Keesey), Aviceda (photo) & T. Michael Keesey,
Pranav Iyer (grey ideas), Rebecca Groom, Darren Naish (vectorize by T.
Michael Keesey), Cathy, Meyers Konversations-Lexikon 1897 (vectorized:
Yan Wong), Yan Wong from illustration by Jules Richard (1907), NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), T. Michael Keesey (after James & al.), Kamil S.
Jaron, David Orr, Campbell Fleming, Alexandra van der Geer, Eric Moody,
Mo Hassan, Heinrich Harder (vectorized by William Gearty), Jake Warner,
Hugo Gruson, Armin Reindl, T. Michael Keesey (after Heinrich Harder),
Matt Celeskey, C. Camilo Julián-Caballero, Kent Elson Sorgon, Karina
Garcia, Darren Naish (vectorized by T. Michael Keesey), DW Bapst,
modified from Figure 1 of Belanger (2011, PALAIOS)., Ernst Haeckel
(vectorized by T. Michael Keesey), Antonov (vectorized by T. Michael
Keesey), Michelle Site, Roberto Díaz Sibaja, Mathew Wedel, Timothy Knepp
of the U.S. Fish and Wildlife Service (illustration) and Timothy J.
Bartley (silhouette), Remes K, Ortega F, Fierro I, Joger U, Kosma R, et
al., Becky Barnes, Filip em, Ingo Braasch, Rene Martin, T. Tischler,
Mason McNair, Yan Wong from wikipedia drawing (PD: Pearson Scott
Foresman), Tyler Greenfield, Falconaumanni and T. Michael Keesey, Iain
Reid

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     661.30049 |    729.787874 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                        |
|   2 |     643.08513 |    124.322283 | Matt Crook                                                                                                                                                            |
|   3 |     194.29957 |    573.668944 | M Hutchinson                                                                                                                                                          |
|   4 |     567.52596 |    478.066802 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
|   5 |      89.25744 |    117.912873 | Joanna Wolfe                                                                                                                                                          |
|   6 |     257.18689 |     85.020181 | Margot Michaud                                                                                                                                                        |
|   7 |     589.12135 |    415.291044 | Jaime Headden                                                                                                                                                         |
|   8 |     688.05757 |    369.259714 | Nobu Tamura                                                                                                                                                           |
|   9 |     885.64566 |    572.416081 | Kai R. Caspar                                                                                                                                                         |
|  10 |     400.18034 |    270.722873 | Sharon Wegner-Larsen                                                                                                                                                  |
|  11 |      73.60053 |    299.074101 | Jay Matternes, vectorized by Zimices                                                                                                                                  |
|  12 |     111.72447 |    651.646820 | T. Michael Keesey                                                                                                                                                     |
|  13 |     506.59782 |    678.358033 | Verdilak                                                                                                                                                              |
|  14 |     770.02853 |    580.481880 | Christoph Schomburg                                                                                                                                                   |
|  15 |     397.76154 |    458.987343 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  16 |     718.11276 |    275.790246 | Tracy A. Heath                                                                                                                                                        |
|  17 |     872.67464 |     46.421921 | Matt Martyniuk                                                                                                                                                        |
|  18 |     892.86623 |    258.271385 | Michael Day                                                                                                                                                           |
|  19 |     941.89354 |    607.289322 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
|  20 |      63.62667 |    480.858495 | Chris huh                                                                                                                                                             |
|  21 |     805.09385 |    702.783715 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
|  22 |     395.75681 |    711.115811 | Lukasiniho                                                                                                                                                            |
|  23 |     327.41406 |    360.683719 | Lauren Sumner-Rooney                                                                                                                                                  |
|  24 |     799.55417 |    459.364191 | Matt Martyniuk                                                                                                                                                        |
|  25 |     422.68960 |    109.831233 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                        |
|  26 |     178.77422 |    408.219445 | Gareth Monger                                                                                                                                                         |
|  27 |     557.08691 |    548.812388 | Margot Michaud                                                                                                                                                        |
|  28 |     944.10535 |    102.446898 | Matt Martyniuk                                                                                                                                                        |
|  29 |     264.08241 |    480.507234 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
|  30 |     913.39333 |    425.707689 | Gareth Monger                                                                                                                                                         |
|  31 |     269.50033 |    725.339548 | Mathieu Basille                                                                                                                                                       |
|  32 |     285.50207 |    605.795090 | Markus A. Grohme                                                                                                                                                      |
|  33 |     292.18308 |    172.241023 | Sarah Werning                                                                                                                                                         |
|  34 |     486.50777 |    343.122938 | FunkMonk                                                                                                                                                              |
|  35 |    1010.24967 |    295.092004 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
|  36 |     519.11036 |    191.173278 | Emily Willoughby                                                                                                                                                      |
|  37 |     590.98970 |    245.092596 | NA                                                                                                                                                                    |
|  38 |     158.57034 |    148.716486 | Gopal Murali                                                                                                                                                          |
|  39 |     453.57001 |    586.862858 | Andy Wilson                                                                                                                                                           |
|  40 |     477.69439 |     46.219410 | Oscar Sanisidro                                                                                                                                                       |
|  41 |     784.43021 |    184.534463 | Sean McCann                                                                                                                                                           |
|  42 |     271.47312 |    657.518884 | Alex Slavenko                                                                                                                                                         |
|  43 |     238.10270 |    274.398783 | NA                                                                                                                                                                    |
|  44 |      32.58356 |    570.715164 | Emily Willoughby                                                                                                                                                      |
|  45 |     959.37403 |    692.858365 | Ferran Sayol                                                                                                                                                          |
|  46 |     742.61241 |    763.268576 | Tasman Dixon                                                                                                                                                          |
|  47 |     600.42507 |     66.778537 | Andy Wilson                                                                                                                                                           |
|  48 |     935.24766 |    516.306489 | Margot Michaud                                                                                                                                                        |
|  49 |     821.88954 |    133.338047 | Steven Coombs                                                                                                                                                         |
|  50 |      61.22694 |    419.974252 | Zimices                                                                                                                                                               |
|  51 |     887.44041 |    332.702853 | Jagged Fang Designs                                                                                                                                                   |
|  52 |     331.16022 |    561.523197 | Zimices                                                                                                                                                               |
|  53 |     677.02970 |    546.181516 | Ferran Sayol                                                                                                                                                          |
|  54 |     125.81740 |    228.997840 | NA                                                                                                                                                                    |
|  55 |     358.17240 |     37.747119 | Carlos Cano-Barbacil                                                                                                                                                  |
|  56 |     212.94260 |    343.512288 | Margot Michaud                                                                                                                                                        |
|  57 |    1003.75986 |    418.710174 | T. Michael Keesey                                                                                                                                                     |
|  58 |      94.77014 |     27.072204 | Gareth Monger                                                                                                                                                         |
|  59 |     992.48690 |    235.823852 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  60 |     690.93618 |    656.333599 | Margot Michaud                                                                                                                                                        |
|  61 |      40.98869 |    725.284865 | T. Michael Keesey                                                                                                                                                     |
|  62 |     484.07361 |    419.473982 | Scott Hartman                                                                                                                                                         |
|  63 |     920.22195 |    782.513513 | Jagged Fang Designs                                                                                                                                                   |
|  64 |     376.58519 |    661.954130 | Steven Traver                                                                                                                                                         |
|  65 |     500.98951 |    773.598159 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  66 |     655.52882 |    772.218313 | Henry Lydecker                                                                                                                                                        |
|  67 |     389.18525 |    418.504488 | Dmitry Bogdanov                                                                                                                                                       |
|  68 |     653.77634 |    324.957049 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  69 |     864.05231 |     19.701282 | Jagged Fang Designs                                                                                                                                                   |
|  70 |     483.94866 |    293.610352 | Tasman Dixon                                                                                                                                                          |
|  71 |      97.20726 |    197.853505 | Yan Wong                                                                                                                                                              |
|  72 |     850.80353 |     89.035422 | Christine Axon                                                                                                                                                        |
|  73 |     613.34711 |    656.204210 | Mattia Menchetti                                                                                                                                                      |
|  74 |     419.44645 |    363.114958 | Josefine Bohr Brask                                                                                                                                                   |
|  75 |     865.17256 |    676.306224 | Jiekun He                                                                                                                                                             |
|  76 |     661.37542 |    199.762771 | Ferran Sayol                                                                                                                                                          |
|  77 |     516.25401 |    113.561065 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
|  78 |      90.75645 |    768.748756 | Ignacio Contreras                                                                                                                                                     |
|  79 |     688.44744 |    447.651166 | NA                                                                                                                                                                    |
|  80 |     162.72195 |     48.842603 | Margot Michaud                                                                                                                                                        |
|  81 |     184.91183 |    187.176976 | Andy Wilson                                                                                                                                                           |
|  82 |     773.31181 |     41.141495 | Gareth Monger                                                                                                                                                         |
|  83 |     864.68679 |    174.541946 | Christoph Schomburg                                                                                                                                                   |
|  84 |     983.99885 |     44.748104 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
|  85 |     782.93383 |    398.231772 | Gopal Murali                                                                                                                                                          |
|  86 |     966.72666 |      5.779238 | Markus A. Grohme                                                                                                                                                      |
|  87 |     946.96624 |    143.990967 | Zimices                                                                                                                                                               |
|  88 |     778.26062 |     68.911862 | Gareth Monger                                                                                                                                                         |
|  89 |     331.59048 |    727.080535 | Gareth Monger                                                                                                                                                         |
|  90 |     834.17917 |    778.532087 | Andrew A. Farke                                                                                                                                                       |
|  91 |     764.58153 |    630.904886 | Christoph Schomburg                                                                                                                                                   |
|  92 |     233.24086 |     24.406318 | Jagged Fang Designs                                                                                                                                                   |
|  93 |     205.17971 |    522.102791 | Lily Hughes                                                                                                                                                           |
|  94 |     886.04735 |    634.771927 | Markus A. Grohme                                                                                                                                                      |
|  95 |     870.18008 |    376.469727 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
|  96 |     376.42714 |    179.280797 | Andy Wilson                                                                                                                                                           |
|  97 |     848.68470 |    487.342617 | Chris huh                                                                                                                                                             |
|  98 |     816.03499 |    321.291961 | terngirl                                                                                                                                                              |
|  99 |     203.05424 |    646.505972 | Madeleine Price Ball                                                                                                                                                  |
| 100 |     709.19179 |     26.616267 | Lafage                                                                                                                                                                |
| 101 |     616.52279 |    383.346986 | NA                                                                                                                                                                    |
| 102 |     621.05494 |    699.733571 | NA                                                                                                                                                                    |
| 103 |     198.20896 |    488.914632 | Scott Hartman                                                                                                                                                         |
| 104 |     140.55899 |    458.117185 | Lafage                                                                                                                                                                |
| 105 |     587.87867 |    765.429166 | Tasman Dixon                                                                                                                                                          |
| 106 |     970.21094 |    448.081807 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 107 |     185.98897 |    727.243710 | T. Michael Keesey                                                                                                                                                     |
| 108 |     753.85253 |    123.331069 | Matt Crook                                                                                                                                                            |
| 109 |     104.23838 |    508.006292 | Chris huh                                                                                                                                                             |
| 110 |      44.10216 |    655.682220 | Matt Crook                                                                                                                                                            |
| 111 |     725.17438 |    111.202875 | Ben Moon                                                                                                                                                              |
| 112 |     790.93250 |    210.390143 | T. Michael Keesey                                                                                                                                                     |
| 113 |     880.28963 |    740.056723 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 114 |     141.28124 |    536.162584 | Dmitry Bogdanov                                                                                                                                                       |
| 115 |     377.91939 |    502.074064 | Erika Schumacher                                                                                                                                                      |
| 116 |     397.33136 |    765.811268 | FJDegrange                                                                                                                                                            |
| 117 |     131.20660 |    441.064615 | Matt Crook                                                                                                                                                            |
| 118 |     373.53998 |    789.047184 | Tasman Dixon                                                                                                                                                          |
| 119 |     770.85199 |    671.062965 | T. Michael Keesey                                                                                                                                                     |
| 120 |      38.77363 |    198.248036 | Gareth Monger                                                                                                                                                         |
| 121 |     720.56700 |    213.702949 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 122 |     398.76016 |      8.841163 | Steven Traver                                                                                                                                                         |
| 123 |      37.80506 |    370.435959 | Zimices                                                                                                                                                               |
| 124 |     660.38252 |    480.227437 | Alexandre Vong                                                                                                                                                        |
| 125 |     416.86794 |    192.075173 | Shyamal                                                                                                                                                               |
| 126 |     893.69468 |    692.671600 | Matt Crook                                                                                                                                                            |
| 127 |     667.28010 |    287.982152 | Jaime Headden                                                                                                                                                         |
| 128 |     661.86929 |    443.650517 | Mike Hanson                                                                                                                                                           |
| 129 |     572.11990 |    628.646868 | Matt Crook                                                                                                                                                            |
| 130 |     317.07290 |    247.382452 | Markus A. Grohme                                                                                                                                                      |
| 131 |      87.30660 |    704.438901 | Margot Michaud                                                                                                                                                        |
| 132 |    1000.81044 |    599.434146 | Steven Traver                                                                                                                                                         |
| 133 |     924.15759 |    700.232730 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 134 |      15.08669 |    303.651098 | Margot Michaud                                                                                                                                                        |
| 135 |     256.80438 |    535.814283 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 136 |     420.67326 |    522.252878 | Matt Crook                                                                                                                                                            |
| 137 |      55.55851 |    501.730418 | Steven Traver                                                                                                                                                         |
| 138 |     179.14409 |    115.810739 | Ieuan Jones                                                                                                                                                           |
| 139 |     114.30152 |    416.951517 | Matt Crook                                                                                                                                                            |
| 140 |     405.44748 |    247.207594 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 141 |      32.45395 |    151.709591 | Matt Crook                                                                                                                                                            |
| 142 |      43.26626 |     39.508862 | T. Michael Keesey                                                                                                                                                     |
| 143 |     351.75616 |    388.009548 | Raven Amos                                                                                                                                                            |
| 144 |     195.64952 |    692.413115 | Steven Traver                                                                                                                                                         |
| 145 |     336.19699 |     96.689482 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 146 |     164.86049 |    276.028693 | Anthony Caravaggi                                                                                                                                                     |
| 147 |     985.69319 |    752.742128 | Anna Willoughby                                                                                                                                                       |
| 148 |     164.40039 |    482.555314 | Gareth Monger                                                                                                                                                         |
| 149 |     724.81045 |    402.720114 | Yan Wong                                                                                                                                                              |
| 150 |     429.46088 |    220.053241 | Martin Kevil                                                                                                                                                          |
| 151 |     138.59652 |    289.183663 | T. Michael Keesey                                                                                                                                                     |
| 152 |     710.68226 |    163.550822 | NA                                                                                                                                                                    |
| 153 |     560.62220 |    512.819041 | NA                                                                                                                                                                    |
| 154 |     619.85963 |    436.267320 | Matt Crook                                                                                                                                                            |
| 155 |     947.63101 |    372.567675 | Margot Michaud                                                                                                                                                        |
| 156 |     811.04259 |    285.794938 | Michael Scroggie                                                                                                                                                      |
| 157 |     159.52131 |    592.419741 | Zimices                                                                                                                                                               |
| 158 |     757.04065 |    412.190801 | Margot Michaud                                                                                                                                                        |
| 159 |     486.49255 |    396.411292 | Nina Skinner                                                                                                                                                          |
| 160 |     840.97141 |    643.793904 | Andy Wilson                                                                                                                                                           |
| 161 |     138.95361 |    482.092293 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 162 |     940.73601 |    626.137348 | Xavier Giroux-Bougard                                                                                                                                                 |
| 163 |      73.25815 |    249.008178 | Gareth Monger                                                                                                                                                         |
| 164 |     710.12604 |    190.033877 | Andy Wilson                                                                                                                                                           |
| 165 |     288.07919 |    774.810884 | T. Michael Keesey                                                                                                                                                     |
| 166 |     354.45621 |    734.531785 | Scott Hartman                                                                                                                                                         |
| 167 |     217.57256 |    717.420081 | Christine Axon                                                                                                                                                        |
| 168 |     482.93457 |    724.347352 | Scott Hartman                                                                                                                                                         |
| 169 |     399.32567 |    624.929081 | Gareth Monger                                                                                                                                                         |
| 170 |     364.96871 |    600.410501 | Anthony Caravaggi                                                                                                                                                     |
| 171 |     558.14945 |    329.189445 | Steven Traver                                                                                                                                                         |
| 172 |     567.64734 |    372.406824 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 173 |     943.22258 |    313.681567 | Peileppe                                                                                                                                                              |
| 174 |      19.53606 |    334.912165 | Jessica Anne Miller                                                                                                                                                   |
| 175 |     179.96200 |    763.659928 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 176 |     807.15970 |     90.469479 | Matt Crook                                                                                                                                                            |
| 177 |     327.80770 |    223.974250 | Margot Michaud                                                                                                                                                        |
| 178 |     677.88428 |    501.752897 | NA                                                                                                                                                                    |
| 179 |     327.14368 |    275.766173 | Scott Hartman                                                                                                                                                         |
| 180 |     646.58277 |    457.420442 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 181 |     271.26588 |    235.256214 | Steven Traver                                                                                                                                                         |
| 182 |     174.15988 |    749.444641 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 183 |      65.48638 |     11.907628 | Michael P. Taylor                                                                                                                                                     |
| 184 |     529.29164 |    747.554902 | Erika Schumacher                                                                                                                                                      |
| 185 |     456.48445 |    170.720282 | Caleb M. Brown                                                                                                                                                        |
| 186 |     966.33369 |    193.485924 | Margot Michaud                                                                                                                                                        |
| 187 |     590.73146 |     34.424510 | Tauana J. Cunha                                                                                                                                                       |
| 188 |     257.94423 |    579.521404 | Inessa Voet                                                                                                                                                           |
| 189 |     247.85989 |    769.030595 | Matt Crook                                                                                                                                                            |
| 190 |     703.24656 |    464.374695 | Scott Hartman                                                                                                                                                         |
| 191 |     528.19352 |    419.242051 | NA                                                                                                                                                                    |
| 192 |      89.05197 |    321.675819 | Mathilde Cordellier                                                                                                                                                   |
| 193 |     989.20531 |    780.515014 | NA                                                                                                                                                                    |
| 194 |     590.86457 |     10.766379 | Collin Gross                                                                                                                                                          |
| 195 |     618.35783 |     25.497795 | Scott Hartman                                                                                                                                                         |
| 196 |     382.14239 |    532.691156 | Gareth Monger                                                                                                                                                         |
| 197 |     268.86622 |     33.054245 | Margot Michaud                                                                                                                                                        |
| 198 |     857.04767 |    294.494368 | Tauana J. Cunha                                                                                                                                                       |
| 199 |      17.30662 |     11.540023 | Andy Wilson                                                                                                                                                           |
| 200 |     607.46739 |    767.973566 | Gareth Monger                                                                                                                                                         |
| 201 |     734.39436 |    458.774845 | Margot Michaud                                                                                                                                                        |
| 202 |     291.85134 |    435.640820 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 203 |     266.16501 |    677.095756 | Roderic Page and Lois Page                                                                                                                                            |
| 204 |     443.47131 |    487.540810 | Neil Kelley                                                                                                                                                           |
| 205 |     924.11056 |    350.855585 | Jagged Fang Designs                                                                                                                                                   |
| 206 |     196.54438 |    148.766449 | Matt Crook                                                                                                                                                            |
| 207 |     671.47279 |    402.517318 | Jessica Anne Miller                                                                                                                                                   |
| 208 |     737.19645 |    184.810492 | Scott Hartman                                                                                                                                                         |
| 209 |     751.12685 |     24.810099 | Steven Traver                                                                                                                                                         |
| 210 |     684.69461 |    633.383708 | M Kolmann                                                                                                                                                             |
| 211 |     627.77100 |      6.278980 | Robert Gay                                                                                                                                                            |
| 212 |     101.11999 |    451.638223 | Jagged Fang Designs                                                                                                                                                   |
| 213 |     833.78360 |    387.859999 | Matt Crook                                                                                                                                                            |
| 214 |     233.60301 |    696.673397 | Scott Hartman                                                                                                                                                         |
| 215 |     716.91614 |    692.821465 | Lukas Panzarin                                                                                                                                                        |
| 216 |     184.97570 |    621.331178 | Chris huh                                                                                                                                                             |
| 217 |     170.64057 |    657.642560 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 218 |     683.32109 |    192.313099 | Gareth Monger                                                                                                                                                         |
| 219 |     244.75319 |    417.841614 | Matt Crook                                                                                                                                                            |
| 220 |     949.23431 |     58.052735 | Anthony Caravaggi                                                                                                                                                     |
| 221 |     456.48509 |    470.794516 | Zimices                                                                                                                                                               |
| 222 |     265.27345 |    379.953821 | Margot Michaud                                                                                                                                                        |
| 223 |     574.14091 |    351.431935 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 224 |     339.50024 |     75.314858 | Gareth Monger                                                                                                                                                         |
| 225 |     607.56301 |    475.932117 | Matt Crook                                                                                                                                                            |
| 226 |     120.92550 |    375.179642 | Tracy A. Heath                                                                                                                                                        |
| 227 |     537.21538 |    382.618598 | Scott Hartman                                                                                                                                                         |
| 228 |     978.30889 |    115.508854 | Scott Hartman                                                                                                                                                         |
| 229 |     496.72182 |    420.898026 | Anna Willoughby                                                                                                                                                       |
| 230 |     738.06387 |    326.919091 | Kanako Bessho-Uehara                                                                                                                                                  |
| 231 |     151.43671 |    515.736972 | Frank Förster                                                                                                                                                         |
| 232 |     206.96693 |    222.292350 | Scott Hartman                                                                                                                                                         |
| 233 |      92.89333 |     48.155157 | Margot Michaud                                                                                                                                                        |
| 234 |     755.51340 |    504.844360 | NA                                                                                                                                                                    |
| 235 |     133.64403 |    355.431262 | Melissa Broussard                                                                                                                                                     |
| 236 |     912.32371 |     26.670393 | Zimices                                                                                                                                                               |
| 237 |     680.01233 |    618.338770 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 238 |     589.94002 |    317.669900 | NA                                                                                                                                                                    |
| 239 |     481.26693 |    743.623257 | Margot Michaud                                                                                                                                                        |
| 240 |     924.21898 |    734.667890 | Scott Hartman                                                                                                                                                         |
| 241 |     681.31131 |     57.051512 | Neil Kelley                                                                                                                                                           |
| 242 |     136.81545 |     45.130742 | Andrew A. Farke                                                                                                                                                       |
| 243 |     792.71232 |    526.902530 | Matt Crook                                                                                                                                                            |
| 244 |     955.98696 |    671.871364 | Birgit Lang                                                                                                                                                           |
| 245 |      10.08889 |    353.562098 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 246 |     367.34892 |    553.897267 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 247 |     661.99889 |    687.372192 | Andy Wilson                                                                                                                                                           |
| 248 |     989.44939 |    557.047760 | T. Michael Keesey                                                                                                                                                     |
| 249 |     916.41991 |     72.231351 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 250 |     194.05028 |    781.213707 | Scott Hartman                                                                                                                                                         |
| 251 |     918.73887 |    381.400822 | Yan Wong                                                                                                                                                              |
| 252 |     892.55831 |    155.824735 | NA                                                                                                                                                                    |
| 253 |     576.25702 |    675.787780 | (after McCulloch 1908)                                                                                                                                                |
| 254 |      49.18280 |    605.303087 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 255 |     482.18180 |    258.552374 | Gareth Monger                                                                                                                                                         |
| 256 |     985.62939 |    359.973778 | Zimices                                                                                                                                                               |
| 257 |     981.49936 |    491.553298 | Smokeybjb                                                                                                                                                             |
| 258 |     656.10917 |     32.287619 | NA                                                                                                                                                                    |
| 259 |     265.88578 |    125.064114 | Chris Hay                                                                                                                                                             |
| 260 |     590.60937 |    735.237196 | NA                                                                                                                                                                    |
| 261 |      18.10514 |    466.586708 | Chuanixn Yu                                                                                                                                                           |
| 262 |     827.99033 |    260.624581 | Jonathan Wells                                                                                                                                                        |
| 263 |      25.85908 |     89.415932 | Gopal Murali                                                                                                                                                          |
| 264 |     175.30792 |    634.043590 | Zimices                                                                                                                                                               |
| 265 |     780.92987 |    368.881269 | NA                                                                                                                                                                    |
| 266 |     215.98929 |    586.845433 | Jagged Fang Designs                                                                                                                                                   |
| 267 |     349.87068 |    122.738350 | Renata F. Martins                                                                                                                                                     |
| 268 |     269.03368 |    639.275001 | Steven Blackwood                                                                                                                                                      |
| 269 |     100.03485 |    534.909502 | T. Michael Keesey                                                                                                                                                     |
| 270 |     889.08595 |    122.341552 | Melissa Broussard                                                                                                                                                     |
| 271 |     968.29136 |    257.054244 | Pete Buchholz                                                                                                                                                         |
| 272 |      23.28826 |    635.652105 | Sarah Alewijnse                                                                                                                                                       |
| 273 |     687.34875 |    135.190082 | Jakovche                                                                                                                                                              |
| 274 |     386.79692 |    429.567188 | Scott Hartman                                                                                                                                                         |
| 275 |     210.47093 |    747.095086 | Nobu Tamura                                                                                                                                                           |
| 276 |     795.17582 |    262.920521 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 277 |     341.87668 |    459.633505 | Chris huh                                                                                                                                                             |
| 278 |      18.30419 |    749.216536 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                             |
| 279 |     619.33911 |    558.351718 | Margot Michaud                                                                                                                                                        |
| 280 |     760.24853 |     88.963530 | Steven Coombs                                                                                                                                                         |
| 281 |     335.55529 |    526.037103 | Ferran Sayol                                                                                                                                                          |
| 282 |     973.48317 |    234.548614 | Michael Scroggie                                                                                                                                                      |
| 283 |     809.00045 |    240.104341 | Tasman Dixon                                                                                                                                                          |
| 284 |     700.84170 |    420.867164 | T. Michael Keesey                                                                                                                                                     |
| 285 |     584.03011 |    638.319535 | Ferran Sayol                                                                                                                                                          |
| 286 |     966.64949 |    480.409185 | Scott Hartman                                                                                                                                                         |
| 287 |     434.67835 |    157.143121 | Tauana J. Cunha                                                                                                                                                       |
| 288 |     843.00393 |    620.030897 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 289 |      19.50817 |    139.684675 | Margot Michaud                                                                                                                                                        |
| 290 |     738.08183 |    525.292114 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                      |
| 291 |      16.23569 |    709.114699 | Matt Crook                                                                                                                                                            |
| 292 |     563.11872 |    433.165411 | Markus A. Grohme                                                                                                                                                      |
| 293 |     444.17070 |     49.367563 | Chris huh                                                                                                                                                             |
| 294 |     966.46164 |    790.137399 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
| 295 |     109.46075 |    790.886729 | xgirouxb                                                                                                                                                              |
| 296 |     832.63551 |    504.631592 | Ferran Sayol                                                                                                                                                          |
| 297 |     241.92983 |    231.713797 | Margot Michaud                                                                                                                                                        |
| 298 |      40.37183 |    454.225825 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 299 |     837.51705 |    472.926488 | Andy Wilson                                                                                                                                                           |
| 300 |      82.73795 |    436.594726 | Dean Schnabel                                                                                                                                                         |
| 301 |     399.53111 |    788.230344 | Emily Willoughby                                                                                                                                                      |
| 302 |     799.84467 |    347.297473 | Gareth Monger                                                                                                                                                         |
| 303 |     910.20786 |    754.740151 | Scott Hartman                                                                                                                                                         |
| 304 |     166.69262 |    675.571884 | Matt Crook                                                                                                                                                            |
| 305 |     447.76304 |    553.856914 | Chris huh                                                                                                                                                             |
| 306 |    1010.03190 |    635.049937 | Matt Crook                                                                                                                                                            |
| 307 |     905.29434 |    369.262829 | Riccardo Percudani                                                                                                                                                    |
| 308 |     540.45376 |    761.253698 | Zimices                                                                                                                                                               |
| 309 |     659.43260 |     12.481437 | Shyamal                                                                                                                                                               |
| 310 |     882.07860 |    465.263368 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 311 |     689.60083 |    602.446773 | Smokeybjb                                                                                                                                                             |
| 312 |     730.09464 |    636.022149 | Zimices                                                                                                                                                               |
| 313 |     981.89058 |    414.872052 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 314 |     816.87715 |    149.522687 | Zimices                                                                                                                                                               |
| 315 |     507.99416 |     77.041599 | Margot Michaud                                                                                                                                                        |
| 316 |     617.86613 |    754.201881 | NA                                                                                                                                                                    |
| 317 |     208.65558 |    366.233177 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 318 |     506.01165 |    387.028641 | Smokeybjb                                                                                                                                                             |
| 319 |     855.37576 |    348.723112 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 320 |     210.81202 |    706.290245 | Markus A. Grohme                                                                                                                                                      |
| 321 |     165.87216 |    536.296761 | Dean Schnabel                                                                                                                                                         |
| 322 |     570.30003 |    140.097316 | NA                                                                                                                                                                    |
| 323 |     358.27596 |    481.187833 | Alexandre Vong                                                                                                                                                        |
| 324 |     711.40095 |    476.458012 | T. Michael Keesey                                                                                                                                                     |
| 325 |     660.96074 |    594.888205 | Ramona J Heim                                                                                                                                                         |
| 326 |      89.34310 |    363.819294 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 327 |     635.20690 |    611.201093 | Scott Hartman                                                                                                                                                         |
| 328 |     233.99743 |    211.634679 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 329 |     544.26914 |    210.671780 | Amanda Katzer                                                                                                                                                         |
| 330 |     623.88792 |    498.988540 | Ignacio Contreras                                                                                                                                                     |
| 331 |     976.84741 |    380.641389 | Tauana J. Cunha                                                                                                                                                       |
| 332 |     964.22037 |    340.074900 | Jagged Fang Designs                                                                                                                                                   |
| 333 |     762.06513 |    222.383700 | Gareth Monger                                                                                                                                                         |
| 334 |     241.66508 |      7.775079 | Scott Hartman                                                                                                                                                         |
| 335 |     640.94430 |    167.905666 | Yan Wong                                                                                                                                                              |
| 336 |     482.14339 |    145.168253 | Jagged Fang Designs                                                                                                                                                   |
| 337 |     217.94841 |    792.442548 | NA                                                                                                                                                                    |
| 338 |     118.57829 |     70.336559 | Birgit Lang                                                                                                                                                           |
| 339 |     706.99686 |      4.664831 | Chris huh                                                                                                                                                             |
| 340 |     418.15000 |    324.834781 | Gareth Monger                                                                                                                                                         |
| 341 |    1013.51868 |    511.432906 | Martin R. Smith                                                                                                                                                       |
| 342 |     829.28838 |    417.317804 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 343 |     173.14829 |    714.047740 | M Kolmann                                                                                                                                                             |
| 344 |     586.39344 |    783.550488 | Zachary Quigley                                                                                                                                                       |
| 345 |     929.18096 |    537.281388 | Jaime Headden                                                                                                                                                         |
| 346 |     434.88030 |    187.373547 | Gareth Monger                                                                                                                                                         |
| 347 |     404.36229 |    166.267728 | NA                                                                                                                                                                    |
| 348 |     487.08182 |    785.772195 | Scott Hartman                                                                                                                                                         |
| 349 |     256.62429 |    626.131431 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 350 |    1001.48155 |     78.227695 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 351 |     452.81178 |    203.287958 | Zimices                                                                                                                                                               |
| 352 |     780.66371 |     18.858470 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 353 |     704.27568 |    726.467146 | Matt Dempsey                                                                                                                                                          |
| 354 |      20.69653 |    286.084671 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 355 |     542.23967 |     64.146040 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 356 |     926.31213 |    479.237511 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 357 |      39.01491 |    620.475207 | Melissa Broussard                                                                                                                                                     |
| 358 |     948.49892 |     31.530458 | Rebecca Groom                                                                                                                                                         |
| 359 |     142.84292 |    756.262324 | NA                                                                                                                                                                    |
| 360 |    1018.86105 |     38.748696 | Gareth Monger                                                                                                                                                         |
| 361 |     803.94712 |    634.874665 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 362 |     784.61964 |    245.432229 | Cathy                                                                                                                                                                 |
| 363 |     950.06822 |    286.105900 | Kai R. Caspar                                                                                                                                                         |
| 364 |     684.84125 |    686.410817 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 365 |     358.81629 |    763.069477 | Margot Michaud                                                                                                                                                        |
| 366 |     143.36754 |    421.748525 | Lafage                                                                                                                                                                |
| 367 |     569.93574 |    714.628950 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 368 |     710.71750 |     40.796949 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 369 |     682.37768 |    375.467588 | Joanna Wolfe                                                                                                                                                          |
| 370 |      33.89653 |    646.580525 | Scott Hartman                                                                                                                                                         |
| 371 |     222.98408 |    664.934712 | NA                                                                                                                                                                    |
| 372 |     733.55770 |    702.728339 | Jagged Fang Designs                                                                                                                                                   |
| 373 |     373.11247 |    360.064534 | Steven Traver                                                                                                                                                         |
| 374 |     460.14351 |    155.402941 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 375 |     213.77448 |    609.736930 | Matt Crook                                                                                                                                                            |
| 376 |     156.28956 |    776.600976 | Birgit Lang                                                                                                                                                           |
| 377 |     791.15169 |     31.485923 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 378 |      36.06283 |    346.966186 | Martin Kevil                                                                                                                                                          |
| 379 |     543.83959 |    148.617114 | Tasman Dixon                                                                                                                                                          |
| 380 |    1017.73023 |    118.989605 | T. Michael Keesey                                                                                                                                                     |
| 381 |     523.03285 |    251.980364 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 382 |     334.01094 |    786.404155 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 383 |     413.90241 |    212.543821 | Gareth Monger                                                                                                                                                         |
| 384 |     334.15409 |    500.899031 | Birgit Lang                                                                                                                                                           |
| 385 |     167.75871 |    506.081640 | Jagged Fang Designs                                                                                                                                                   |
| 386 |     220.45725 |    435.447863 | Margot Michaud                                                                                                                                                        |
| 387 |     242.25505 |    128.458251 | Steven Traver                                                                                                                                                         |
| 388 |     170.05885 |    612.755073 | Gareth Monger                                                                                                                                                         |
| 389 |     651.46950 |    627.656881 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 390 |      74.70518 |    180.526649 | Scott Hartman                                                                                                                                                         |
| 391 |     514.85229 |    450.046730 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 392 |     255.38750 |    784.877311 | Kamil S. Jaron                                                                                                                                                        |
| 393 |     142.70756 |    329.738262 | David Orr                                                                                                                                                             |
| 394 |     882.01516 |    524.759111 | Campbell Fleming                                                                                                                                                      |
| 395 |     830.55292 |    586.172883 | Gareth Monger                                                                                                                                                         |
| 396 |     352.31303 |    626.260050 | Chuanixn Yu                                                                                                                                                           |
| 397 |     580.97895 |    126.245681 | T. Michael Keesey                                                                                                                                                     |
| 398 |     772.78129 |     51.841835 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 399 |     151.05745 |     13.975626 | Alexandra van der Geer                                                                                                                                                |
| 400 |     865.26221 |    762.654573 | Jagged Fang Designs                                                                                                                                                   |
| 401 |     384.81387 |    372.706175 | Eric Moody                                                                                                                                                            |
| 402 |     235.11582 |    384.335964 | Mo Hassan                                                                                                                                                             |
| 403 |     406.59060 |    388.969345 | Jagged Fang Designs                                                                                                                                                   |
| 404 |     977.02650 |    128.301077 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 405 |     156.26079 |    252.859790 | Jake Warner                                                                                                                                                           |
| 406 |      15.49656 |    681.444794 | Hugo Gruson                                                                                                                                                           |
| 407 |     167.02186 |    371.619870 | Sean McCann                                                                                                                                                           |
| 408 |      62.62996 |    576.191132 | Armin Reindl                                                                                                                                                          |
| 409 |     361.35151 |    526.708889 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 410 |     196.79513 |    455.879532 | T. Michael Keesey                                                                                                                                                     |
| 411 |     362.13923 |    748.364563 | terngirl                                                                                                                                                              |
| 412 |     180.17016 |    171.229738 | Chris huh                                                                                                                                                             |
| 413 |      72.29071 |     47.968179 | NA                                                                                                                                                                    |
| 414 |     799.68349 |    430.134387 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 415 |     470.80601 |    709.574870 | Christoph Schomburg                                                                                                                                                   |
| 416 |     854.57349 |    448.020795 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 417 |     352.30350 |    713.087455 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 418 |     960.51622 |    172.949362 | NA                                                                                                                                                                    |
| 419 |     523.03946 |    730.766702 | Matt Crook                                                                                                                                                            |
| 420 |     450.76231 |    536.245211 | Tasman Dixon                                                                                                                                                          |
| 421 |     706.30731 |    703.355329 | Matt Celeskey                                                                                                                                                         |
| 422 |     775.62185 |    789.235666 | C. Camilo Julián-Caballero                                                                                                                                            |
| 423 |     137.90650 |      7.014285 | Chris huh                                                                                                                                                             |
| 424 |     428.49803 |    783.881659 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 425 |     808.82852 |    372.692758 | Gareth Monger                                                                                                                                                         |
| 426 |     699.83311 |    149.595391 | Jagged Fang Designs                                                                                                                                                   |
| 427 |      74.79289 |    376.878595 | NA                                                                                                                                                                    |
| 428 |     495.99527 |     10.336277 | Kent Elson Sorgon                                                                                                                                                     |
| 429 |     211.05053 |    128.775511 | Tasman Dixon                                                                                                                                                          |
| 430 |     158.52317 |    208.268794 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 431 |     949.49663 |    754.006263 | Ferran Sayol                                                                                                                                                          |
| 432 |      23.77490 |    115.402574 | Andy Wilson                                                                                                                                                           |
| 433 |     666.97710 |     24.904807 | Sarah Werning                                                                                                                                                         |
| 434 |     613.71006 |    688.420670 | Chris huh                                                                                                                                                             |
| 435 |     112.37256 |    138.799788 | Gareth Monger                                                                                                                                                         |
| 436 |     299.45951 |    776.692936 | Cathy                                                                                                                                                                 |
| 437 |     988.26365 |    525.088776 | Scott Hartman                                                                                                                                                         |
| 438 |     173.72863 |     88.310596 | Margot Michaud                                                                                                                                                        |
| 439 |     937.85178 |     42.228284 | Jagged Fang Designs                                                                                                                                                   |
| 440 |     482.27270 |    151.926569 | Markus A. Grohme                                                                                                                                                      |
| 441 |     286.77730 |     16.735683 | Margot Michaud                                                                                                                                                        |
| 442 |     589.84628 |    201.484259 | Michael Scroggie                                                                                                                                                      |
| 443 |     734.83522 |    732.076728 | Karina Garcia                                                                                                                                                         |
| 444 |     859.04713 |    398.159900 | Matt Crook                                                                                                                                                            |
| 445 |     564.28673 |    442.347078 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 446 |     202.01342 |     37.210228 | Matt Crook                                                                                                                                                            |
| 447 |     919.34207 |    672.347814 | Sarah Werning                                                                                                                                                         |
| 448 |      25.53739 |     60.652819 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 449 |     816.36547 |     36.631439 | Jessica Anne Miller                                                                                                                                                   |
| 450 |     837.52973 |    669.204818 | Xavier Giroux-Bougard                                                                                                                                                 |
| 451 |     912.86282 |    136.419149 | Margot Michaud                                                                                                                                                        |
| 452 |     976.89694 |    595.233239 | Sarah Werning                                                                                                                                                         |
| 453 |    1009.75366 |    555.767748 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 454 |     660.20839 |    301.849504 | Zimices                                                                                                                                                               |
| 455 |     301.49111 |    524.271824 | Ignacio Contreras                                                                                                                                                     |
| 456 |     811.31665 |    519.956213 | Zimices                                                                                                                                                               |
| 457 |      11.50404 |    519.025986 | Michael Scroggie                                                                                                                                                      |
| 458 |      55.24943 |    360.507048 | Xavier Giroux-Bougard                                                                                                                                                 |
| 459 |     640.31705 |    785.042175 | Matt Crook                                                                                                                                                            |
| 460 |     520.98637 |    235.640361 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 461 |      76.79918 |    747.380095 | Steven Traver                                                                                                                                                         |
| 462 |     491.26532 |    473.195647 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 463 |     218.09570 |    165.997554 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 464 |     279.71086 |     51.311504 | Tasman Dixon                                                                                                                                                          |
| 465 |     200.07648 |    382.519049 | Jagged Fang Designs                                                                                                                                                   |
| 466 |     758.96857 |    533.615662 | Ignacio Contreras                                                                                                                                                     |
| 467 |     314.02555 |    294.226828 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 468 |     540.26663 |    502.360820 | Michael Scroggie                                                                                                                                                      |
| 469 |      71.48648 |    529.105572 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 470 |     139.32217 |     83.612383 | Smokeybjb                                                                                                                                                             |
| 471 |      53.80612 |    636.927634 | Michelle Site                                                                                                                                                         |
| 472 |     854.59151 |    662.436536 | Markus A. Grohme                                                                                                                                                      |
| 473 |    1004.99296 |    739.483709 | Roberto Díaz Sibaja                                                                                                                                                   |
| 474 |    1004.83637 |     64.024702 | Gareth Monger                                                                                                                                                         |
| 475 |     134.26993 |    173.737779 | Christoph Schomburg                                                                                                                                                   |
| 476 |     268.36832 |      6.110530 | Mathew Wedel                                                                                                                                                          |
| 477 |     104.29646 |    440.949190 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 478 |     146.17713 |    308.080287 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 479 |     528.90110 |    598.413028 | Andy Wilson                                                                                                                                                           |
| 480 |      59.33365 |    381.463580 | Becky Barnes                                                                                                                                                          |
| 481 |      16.19436 |    238.232046 | Scott Hartman                                                                                                                                                         |
| 482 |     203.10381 |    233.214715 | Filip em                                                                                                                                                              |
| 483 |      95.67065 |      5.222406 | Chris huh                                                                                                                                                             |
| 484 |     679.15178 |    345.977125 | xgirouxb                                                                                                                                                              |
| 485 |     386.43839 |    340.114265 | Riccardo Percudani                                                                                                                                                    |
| 486 |     884.18311 |    495.953871 | Ignacio Contreras                                                                                                                                                     |
| 487 |     439.82001 |    646.037522 | Michael Scroggie                                                                                                                                                      |
| 488 |     316.97077 |     15.981464 | Joanna Wolfe                                                                                                                                                          |
| 489 |     876.09798 |    717.003117 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 490 |     942.27638 |     16.198972 | Scott Hartman                                                                                                                                                         |
| 491 |     825.41655 |    168.298310 | Tasman Dixon                                                                                                                                                          |
| 492 |    1008.31294 |    783.660234 | Steven Traver                                                                                                                                                         |
| 493 |     230.40822 |    685.726453 | Kent Elson Sorgon                                                                                                                                                     |
| 494 |      41.46453 |    445.967734 | Chris huh                                                                                                                                                             |
| 495 |     434.48948 |    233.546705 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 496 |     269.26897 |    305.750161 | Ingo Braasch                                                                                                                                                          |
| 497 |     994.08506 |    479.243383 | Tasman Dixon                                                                                                                                                          |
| 498 |      50.61860 |    789.430434 | Rene Martin                                                                                                                                                           |
| 499 |     296.12352 |    629.321732 | Carlos Cano-Barbacil                                                                                                                                                  |
| 500 |      17.28326 |    272.864273 | Zimices                                                                                                                                                               |
| 501 |     251.69403 |    291.468484 | Matt Crook                                                                                                                                                            |
| 502 |     779.70234 |    751.873894 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 503 |     418.65899 |    204.640049 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 504 |     736.34270 |    380.593150 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 505 |     521.12478 |    615.704121 | T. Tischler                                                                                                                                                           |
| 506 |     658.13137 |    515.429064 | Mason McNair                                                                                                                                                          |
| 507 |     703.39886 |    680.082277 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 508 |     595.63815 |    509.890766 | Tyler Greenfield                                                                                                                                                      |
| 509 |     459.08462 |    185.767772 | Markus A. Grohme                                                                                                                                                      |
| 510 |     341.76433 |    396.628179 | NA                                                                                                                                                                    |
| 511 |      15.13977 |    317.730213 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 512 |     201.18907 |    629.522646 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 513 |     129.85759 |    780.615583 | Markus A. Grohme                                                                                                                                                      |
| 514 |     745.86719 |    434.544708 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 515 |     188.05051 |    546.959531 | NA                                                                                                                                                                    |
| 516 |    1008.95643 |    538.190460 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 517 |     437.60851 |    382.239331 | Iain Reid                                                                                                                                                             |
| 518 |     172.40962 |    702.498974 | Zimices                                                                                                                                                               |
| 519 |     943.08764 |    127.441321 | Zimices                                                                                                                                                               |
| 520 |     684.09786 |    788.028730 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 521 |     252.41012 |    400.960793 | Carlos Cano-Barbacil                                                                                                                                                  |
| 522 |     724.69971 |    234.961364 | Caleb M. Brown                                                                                                                                                        |

    #> Your tweet has been posted!
