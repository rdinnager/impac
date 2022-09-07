
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

Neil Kelley, Melissa Broussard, Gabriela Palomo-Munoz, Gareth Monger,
ДиБгд (vectorized by T. Michael Keesey), Jagged Fang Designs, Birgit
Lang, T. Michael Keesey, Matt Crook, Beth Reinke, Scott Hartman, Rebecca
Groom, Sarah Werning, Steven Traver, Margot Michaud, Robert Gay, modifed
from Olegivvit, Chris huh, Dmitry Bogdanov, Douglas Brown (modified by
T. Michael Keesey), Markus A. Grohme, Milton Tan, Amanda Katzer, Sergio
A. Muñoz-Gómez, Ferran Sayol, Jose Carlos Arenas-Monroy, Noah
Schlottman, photo by David J Patterson, NASA, Johan Lindgren, Michael W.
Caldwell, Takuya Konishi, Luis M. Chiappe, Andy Wilson, T. Michael
Keesey, from a photograph by Thea Boodhoo, Smokeybjb, Bennet McComish,
photo by Hans Hillewaert, Lukasiniho, Gopal Murali, Pranav Iyer (grey
ideas), L. Shyamal, Matt Martyniuk, Nobu Tamura (vectorized by T.
Michael Keesey), Unknown (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, SauropodomorphMonarch, Rene Martin, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Sean McCann, Nobu Tamura, Ieuan Jones, Andreas
Hejnol, Archaeodontosaurus (vectorized by T. Michael Keesey), Mathilde
Cordellier, I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey),
Jaime Headden, Matt Celeskey, CNZdenek, Zimices, Emily Willoughby,
Xavier Giroux-Bougard, Jack Mayer Wood, John Curtis (vectorized by T.
Michael Keesey), Ignacio Contreras, Jake Warner, Tyler McCraney, Sharon
Wegner-Larsen, Yan Wong, Tasman Dixon, Manabu Bessho-Uehara, David Orr,
Tony Ayling (vectorized by T. Michael Keesey), Dmitry Bogdanov
(vectorized by T. Michael Keesey), Henry Lydecker, Mathew Wedel, Rachel
Shoop, Renato Santos, Chloé Schmidt, Roberto Díaz Sibaja, Duane
Raver/USFWS, Dean Schnabel, Tauana J. Cunha, T. Michael Keesey (after
Joseph Wolf), Cagri Cevrim, C. Camilo Julián-Caballero, Michael Day,
Felix Vaux, Bruno C. Vellutini, Charles R. Knight, vectorized by
Zimices, Kai R. Caspar, FJDegrange, Martin R. Smith, FunkMonk, Michael
Scroggie, Luc Viatour (source photo) and Andreas Plank, Emma Hughes, Yan
Wong from wikipedia drawing (PD: Pearson Scott Foresman), Joe Schneid
(vectorized by T. Michael Keesey), Noah Schlottman, photo by Carol
Cummings, Robbie Cada (vectorized by T. Michael Keesey), Kent Elson
Sorgon, Joanna Wolfe, Robbie N. Cada (modified by T. Michael Keesey),
Harold N Eyster, A. H. Baldwin (vectorized by T. Michael Keesey),
Alexander Schmidt-Lebuhn, George Edward Lodge (modified by T. Michael
Keesey), Cesar Julian, Metalhead64 (vectorized by T. Michael Keesey),
Noah Schlottman, photo from Moorea Biocode, Darren Naish (vectorize by
T. Michael Keesey), Katie S. Collins, Andreas Trepte (vectorized by T.
Michael Keesey), Maxwell Lefroy (vectorized by T. Michael Keesey),
(unknown), Michele M Tobias from an image By Dcrjsr - Own work, CC BY
3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>, Thibaut
Brunet, Dori <dori@merr.info> (source photo) and Nevit Dilmen, Mali’o
Kodis, drawing by Manvir Singh, Noah Schlottman, photo by Carlos
Sánchez-Ortiz, Erika Schumacher, T. Michael Keesey (photo by Bc999
\[Black crow\]), Trond R. Oskars, Ghedoghedo (vectorized by T. Michael
Keesey), Robert Hering, Mathieu Pélissié, Christoph Schomburg, ArtFavor
& annaleeblysse, Christopher Laumer (vectorized by T. Michael Keesey),
Sarefo (vectorized by T. Michael Keesey), Maija Karala, Nobu Tamura
(vectorized by A. Verrière), Mali’o Kodis, traced image from the
National Science Foundation’s Turbellarian Taxonomic Database, Tony
Ayling, Scott Reid, Nobu Tamura, vectorized by Zimices, Julia B McHugh,
Roderic Page and Lois Page, Steven Coombs (vectorized by T. Michael
Keesey), Brockhaus and Efron, Mali’o Kodis, photograph property of
National Museums of Northern Ireland, Skye McDavid, Stacy Spensley
(Modified), Kamil S. Jaron, Isaure Scavezzoni, Carlos Cano-Barbacil,
Matt Martyniuk (vectorized by T. Michael Keesey), Michelle Site, H.
Filhol (vectorized by T. Michael Keesey), Tarique Sani (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Verisimilus,
Evan-Amos (vectorized by T. Michael Keesey), Tyler Greenfield and Scott
Hartman, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Frank Denota,
Patrick Fisher (vectorized by T. Michael Keesey), Robert Gay, modified
from FunkMonk (Michael B.H.) and T. Michael Keesey., Steven Coombs,
xgirouxb, Apokryltaros (vectorized by T. Michael Keesey), Fernando
Campos De Domenico, Christopher Chávez, Walter Vladimir, JCGiron,
Christine Axon, SecretJellyMan - from Mason McNair, Caleb M. Brown,
Lukas Panzarin, Armin Reindl, Becky Barnes, Iain Reid, FunkMonk
\[Michael B.H.\] (modified by T. Michael Keesey), Kosta Mumcuoglu
(vectorized by T. Michael Keesey), Darren Naish (vectorized by T.
Michael Keesey), terngirl, Juan Carlos Jerí, Joris van der Ham
(vectorized by T. Michael Keesey), Alex Slavenko, Andrew A. Farke

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     135.06390 |    485.324883 | Neil Kelley                                                                                                                                                           |
|   2 |     282.66902 |    123.530698 | Melissa Broussard                                                                                                                                                     |
|   3 |     414.22762 |    563.100525 | NA                                                                                                                                                                    |
|   4 |     654.80302 |    171.239125 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   5 |     444.05023 |    369.901404 | Gareth Monger                                                                                                                                                         |
|   6 |     840.54374 |    593.812611 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
|   7 |     735.78491 |    313.349470 | Jagged Fang Designs                                                                                                                                                   |
|   8 |     676.84898 |    653.187569 | Birgit Lang                                                                                                                                                           |
|   9 |     220.51026 |    402.427158 | Gareth Monger                                                                                                                                                         |
|  10 |     554.95650 |     96.102553 | T. Michael Keesey                                                                                                                                                     |
|  11 |     412.87732 |    152.648679 | Matt Crook                                                                                                                                                            |
|  12 |     885.25377 |    195.513932 | Beth Reinke                                                                                                                                                           |
|  13 |     241.85039 |    699.730283 | Scott Hartman                                                                                                                                                         |
|  14 |     948.77055 |     95.076198 | Birgit Lang                                                                                                                                                           |
|  15 |     180.69720 |    203.345648 | Rebecca Groom                                                                                                                                                         |
|  16 |     828.43529 |    419.004292 | Matt Crook                                                                                                                                                            |
|  17 |     326.89310 |    287.453434 | Birgit Lang                                                                                                                                                           |
|  18 |     289.00060 |    510.610269 | Sarah Werning                                                                                                                                                         |
|  19 |     257.91307 |    620.693683 | Steven Traver                                                                                                                                                         |
|  20 |     834.54700 |    734.309170 | Margot Michaud                                                                                                                                                        |
|  21 |     764.80289 |     88.957959 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
|  22 |     964.37395 |    539.006103 | T. Michael Keesey                                                                                                                                                     |
|  23 |     127.01569 |    311.926516 | Gareth Monger                                                                                                                                                         |
|  24 |     727.06385 |    689.106562 | Chris huh                                                                                                                                                             |
|  25 |     611.08935 |    559.736516 | Matt Crook                                                                                                                                                            |
|  26 |      60.93964 |    182.502719 | Dmitry Bogdanov                                                                                                                                                       |
|  27 |     667.86101 |    725.774842 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
|  28 |     147.11865 |    609.913619 | Markus A. Grohme                                                                                                                                                      |
|  29 |     511.35573 |    289.157359 | Matt Crook                                                                                                                                                            |
|  30 |     224.35294 |    748.556819 | Steven Traver                                                                                                                                                         |
|  31 |     634.20077 |     62.523708 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  32 |     684.25270 |    266.973674 | Milton Tan                                                                                                                                                            |
|  33 |     408.55561 |    704.315972 | Amanda Katzer                                                                                                                                                         |
|  34 |      73.42687 |    690.204399 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  35 |     101.02012 |    381.854571 | Ferran Sayol                                                                                                                                                          |
|  36 |     990.80342 |    331.694540 | NA                                                                                                                                                                    |
|  37 |     109.65679 |     92.106172 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  38 |     523.10539 |    514.311629 | Matt Crook                                                                                                                                                            |
|  39 |     950.07376 |    706.858175 | Steven Traver                                                                                                                                                         |
|  40 |     100.10839 |    556.891048 | Noah Schlottman, photo by David J Patterson                                                                                                                           |
|  41 |      27.75518 |    424.623224 | NASA                                                                                                                                                                  |
|  42 |     745.45876 |    197.092679 | Gareth Monger                                                                                                                                                         |
|  43 |     381.97460 |     53.868319 | Scott Hartman                                                                                                                                                         |
|  44 |     545.31417 |    430.983382 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
|  45 |     426.23752 |    637.398318 | Andy Wilson                                                                                                                                                           |
|  46 |     516.91948 |    632.079236 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                  |
|  47 |     937.35537 |     27.276992 | Smokeybjb                                                                                                                                                             |
|  48 |     642.22991 |    488.777988 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
|  49 |     957.58708 |    331.347755 | Lukasiniho                                                                                                                                                            |
|  50 |     536.28067 |    751.029571 | Gopal Murali                                                                                                                                                          |
|  51 |     120.88813 |    769.599096 | Jagged Fang Designs                                                                                                                                                   |
|  52 |     697.81097 |     26.578910 | Pranav Iyer (grey ideas)                                                                                                                                              |
|  53 |     397.30370 |    478.143079 | L. Shyamal                                                                                                                                                            |
|  54 |     548.27731 |    683.511823 | Markus A. Grohme                                                                                                                                                      |
|  55 |     627.62970 |    227.662111 | Scott Hartman                                                                                                                                                         |
|  56 |     225.92635 |    266.983571 | Matt Martyniuk                                                                                                                                                        |
|  57 |     144.60899 |    516.673167 | Gareth Monger                                                                                                                                                         |
|  58 |     832.24014 |    684.965534 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  59 |     458.48300 |    258.052718 | Matt Crook                                                                                                                                                            |
|  60 |     443.88381 |    773.556111 | Steven Traver                                                                                                                                                         |
|  61 |      95.61866 |    273.642144 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
|  62 |      77.75706 |     21.394558 | SauropodomorphMonarch                                                                                                                                                 |
|  63 |     876.55642 |    772.378402 | Steven Traver                                                                                                                                                         |
|  64 |     176.95955 |     94.848622 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  65 |     232.94736 |     25.497714 | Rene Martin                                                                                                                                                           |
|  66 |      21.03577 |    572.502746 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  67 |     507.21619 |    138.707919 | Gareth Monger                                                                                                                                                         |
|  68 |     858.35861 |    542.471591 | Rebecca Groom                                                                                                                                                         |
|  69 |     680.17806 |    416.162178 | Matt Crook                                                                                                                                                            |
|  70 |     640.54364 |    121.044489 | Smokeybjb                                                                                                                                                             |
|  71 |     745.23025 |    534.489013 | Gareth Monger                                                                                                                                                         |
|  72 |     827.41762 |     50.016396 | Sean McCann                                                                                                                                                           |
|  73 |     160.27729 |    666.284581 | Scott Hartman                                                                                                                                                         |
|  74 |     463.06797 |    463.425110 | Nobu Tamura                                                                                                                                                           |
|  75 |     277.68279 |    439.305792 | Matt Crook                                                                                                                                                            |
|  76 |     706.69255 |    597.783828 | Ieuan Jones                                                                                                                                                           |
|  77 |     344.35111 |    204.797983 | Andreas Hejnol                                                                                                                                                        |
|  78 |     893.03464 |    621.939574 | Ferran Sayol                                                                                                                                                          |
|  79 |     939.09231 |    452.735203 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
|  80 |     989.45686 |    214.803993 | Steven Traver                                                                                                                                                         |
|  81 |     983.75623 |    674.668301 | Milton Tan                                                                                                                                                            |
|  82 |     178.48192 |    407.906925 | Mathilde Cordellier                                                                                                                                                   |
|  83 |     294.98764 |    211.160324 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
|  84 |     758.66077 |    762.587456 | Jaime Headden                                                                                                                                                         |
|  85 |     805.02510 |    279.725120 | Ferran Sayol                                                                                                                                                          |
|  86 |     575.76313 |    635.642353 | Matt Crook                                                                                                                                                            |
|  87 |     454.22297 |    421.684681 | Matt Celeskey                                                                                                                                                         |
|  88 |     963.80438 |    412.632970 | NA                                                                                                                                                                    |
|  89 |     695.73163 |    207.955059 | CNZdenek                                                                                                                                                              |
|  90 |     402.81394 |    222.609653 | Zimices                                                                                                                                                               |
|  91 |     416.77523 |     64.801507 | NA                                                                                                                                                                    |
|  92 |     676.88019 |    347.075550 | Emily Willoughby                                                                                                                                                      |
|  93 |     806.84202 |    113.326995 | Gareth Monger                                                                                                                                                         |
|  94 |     205.35580 |    128.190928 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  95 |     480.80604 |     14.103901 | Xavier Giroux-Bougard                                                                                                                                                 |
|  96 |      31.98753 |    305.657819 | Lukasiniho                                                                                                                                                            |
|  97 |     199.70208 |    342.004351 | Jagged Fang Designs                                                                                                                                                   |
|  98 |     475.45282 |    732.471168 | Sarah Werning                                                                                                                                                         |
|  99 |     349.38170 |    758.174136 | Steven Traver                                                                                                                                                         |
| 100 |     237.25122 |    308.816431 | Jack Mayer Wood                                                                                                                                                       |
| 101 |     100.55454 |    431.370150 | Margot Michaud                                                                                                                                                        |
| 102 |     463.19502 |     93.863585 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 103 |     891.22568 |    517.165299 | Ignacio Contreras                                                                                                                                                     |
| 104 |      41.43903 |    108.673918 | Chris huh                                                                                                                                                             |
| 105 |     592.27591 |    192.705817 | Chris huh                                                                                                                                                             |
| 106 |     688.09131 |    788.132071 | Jake Warner                                                                                                                                                           |
| 107 |      57.02575 |    760.294696 | Gareth Monger                                                                                                                                                         |
| 108 |     713.98664 |     51.152523 | Gareth Monger                                                                                                                                                         |
| 109 |     334.72131 |    569.304616 | T. Michael Keesey                                                                                                                                                     |
| 110 |     704.16266 |    185.443111 | Matt Crook                                                                                                                                                            |
| 111 |     777.88612 |    634.723066 | Ferran Sayol                                                                                                                                                          |
| 112 |     114.51384 |    502.981450 | Tyler McCraney                                                                                                                                                        |
| 113 |     545.47666 |    401.546606 | Gareth Monger                                                                                                                                                         |
| 114 |     992.53017 |    774.230659 | Gareth Monger                                                                                                                                                         |
| 115 |      56.34511 |    587.426227 | Sharon Wegner-Larsen                                                                                                                                                  |
| 116 |     352.30366 |    533.865850 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 117 |     755.85871 |    302.228230 | Matt Celeskey                                                                                                                                                         |
| 118 |     362.30432 |    317.500821 | Yan Wong                                                                                                                                                              |
| 119 |     817.03993 |    228.101082 | Gopal Murali                                                                                                                                                          |
| 120 |     955.25856 |    784.355701 | Tasman Dixon                                                                                                                                                          |
| 121 |     712.25242 |    502.756729 | Manabu Bessho-Uehara                                                                                                                                                  |
| 122 |      99.62568 |    340.189105 | T. Michael Keesey                                                                                                                                                     |
| 123 |     558.77609 |    230.733887 | David Orr                                                                                                                                                             |
| 124 |      59.96597 |    509.906205 | NA                                                                                                                                                                    |
| 125 |     708.12661 |    458.658127 | Steven Traver                                                                                                                                                         |
| 126 |     884.47925 |      6.274281 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 127 |     921.59084 |    728.897562 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 128 |     348.30999 |    122.999174 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 129 |     473.85549 |    438.491901 | Henry Lydecker                                                                                                                                                        |
| 130 |     414.42029 |    261.988242 | Gareth Monger                                                                                                                                                         |
| 131 |      38.97151 |    280.980790 | Mathew Wedel                                                                                                                                                          |
| 132 |     326.24320 |     12.463679 | Margot Michaud                                                                                                                                                        |
| 133 |     735.96519 |    728.128172 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 134 |     205.51690 |    249.708316 | Zimices                                                                                                                                                               |
| 135 |    1016.55163 |    309.525277 | Ferran Sayol                                                                                                                                                          |
| 136 |      23.78716 |    261.156694 | Rachel Shoop                                                                                                                                                          |
| 137 |      37.09980 |     42.596826 | Margot Michaud                                                                                                                                                        |
| 138 |     930.36545 |    615.013296 | Renato Santos                                                                                                                                                         |
| 139 |     952.13127 |    256.651862 | Chloé Schmidt                                                                                                                                                         |
| 140 |     304.87024 |    188.566994 | Roberto Díaz Sibaja                                                                                                                                                   |
| 141 |     720.82450 |    123.387054 | T. Michael Keesey                                                                                                                                                     |
| 142 |      36.54646 |    340.794874 | Duane Raver/USFWS                                                                                                                                                     |
| 143 |     950.61065 |    363.860687 | Dean Schnabel                                                                                                                                                         |
| 144 |      34.58421 |    498.497117 | Tauana J. Cunha                                                                                                                                                       |
| 145 |     162.61289 |    748.861798 | Matt Crook                                                                                                                                                            |
| 146 |     269.99670 |    647.991920 | Zimices                                                                                                                                                               |
| 147 |    1001.21106 |    442.406080 | Jagged Fang Designs                                                                                                                                                   |
| 148 |     147.90596 |     21.032126 | Matt Crook                                                                                                                                                            |
| 149 |     309.32500 |    784.387809 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 150 |     334.30494 |    664.482647 | Cagri Cevrim                                                                                                                                                          |
| 151 |     266.85238 |    246.059214 | C. Camilo Julián-Caballero                                                                                                                                            |
| 152 |     784.26829 |    209.653332 | Roberto Díaz Sibaja                                                                                                                                                   |
| 153 |      31.84891 |    787.762486 | Matt Crook                                                                                                                                                            |
| 154 |      94.83560 |    253.420687 | Michael Day                                                                                                                                                           |
| 155 |     779.33996 |    301.188559 | Felix Vaux                                                                                                                                                            |
| 156 |     302.82274 |    350.592148 | Zimices                                                                                                                                                               |
| 157 |     965.84070 |    773.941490 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 158 |     569.37475 |    723.782404 | Bruno C. Vellutini                                                                                                                                                    |
| 159 |      12.95027 |     50.241699 | Xavier Giroux-Bougard                                                                                                                                                 |
| 160 |     763.45746 |     14.876622 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 161 |      42.31809 |    681.293759 | Gareth Monger                                                                                                                                                         |
| 162 |     159.97828 |    264.933227 | NA                                                                                                                                                                    |
| 163 |     255.74862 |    218.923405 | Dean Schnabel                                                                                                                                                         |
| 164 |     568.86591 |     14.869365 | Chris huh                                                                                                                                                             |
| 165 |     577.56752 |    330.958926 | Matt Crook                                                                                                                                                            |
| 166 |    1012.63040 |    152.865873 | T. Michael Keesey                                                                                                                                                     |
| 167 |     726.52020 |    619.824381 | Tasman Dixon                                                                                                                                                          |
| 168 |     564.14029 |    530.351327 | Margot Michaud                                                                                                                                                        |
| 169 |     108.91682 |    160.633277 | Ferran Sayol                                                                                                                                                          |
| 170 |     228.28732 |    785.343410 | Kai R. Caspar                                                                                                                                                         |
| 171 |     642.61411 |    356.024588 | Gareth Monger                                                                                                                                                         |
| 172 |     331.84372 |    255.816411 | T. Michael Keesey                                                                                                                                                     |
| 173 |     628.15109 |    770.748242 | FJDegrange                                                                                                                                                            |
| 174 |     746.44559 |    337.738074 | Martin R. Smith                                                                                                                                                       |
| 175 |     194.85570 |    545.494224 | Matt Celeskey                                                                                                                                                         |
| 176 |     686.67588 |    570.435215 | NA                                                                                                                                                                    |
| 177 |     541.71102 |    448.202764 | T. Michael Keesey                                                                                                                                                     |
| 178 |     962.15405 |     48.289563 | FunkMonk                                                                                                                                                              |
| 179 |      56.62586 |    720.964912 | Michael Scroggie                                                                                                                                                      |
| 180 |     815.87723 |     77.341070 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 181 |     313.23321 |    728.889646 | Zimices                                                                                                                                                               |
| 182 |     213.02542 |    178.223318 | Emma Hughes                                                                                                                                                           |
| 183 |     660.01604 |    321.256986 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 184 |     305.67466 |    745.236272 | Margot Michaud                                                                                                                                                        |
| 185 |     805.72391 |    786.285136 | CNZdenek                                                                                                                                                              |
| 186 |     100.31418 |    636.710142 | Rebecca Groom                                                                                                                                                         |
| 187 |     331.81429 |    623.158673 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 188 |     510.07958 |    701.789325 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 189 |     297.09414 |    716.258884 | Jagged Fang Designs                                                                                                                                                   |
| 190 |     610.15913 |    739.481392 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 191 |     507.87695 |    402.791083 | C. Camilo Julián-Caballero                                                                                                                                            |
| 192 |    1000.52269 |     65.862130 | Milton Tan                                                                                                                                                            |
| 193 |      67.29245 |    611.478370 | Chris huh                                                                                                                                                             |
| 194 |     127.03425 |    229.900848 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 195 |     222.28952 |    492.158811 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 196 |     358.40477 |    678.329530 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 197 |      38.92367 |    646.929767 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                         |
| 198 |     590.82103 |    544.791154 | Margot Michaud                                                                                                                                                        |
| 199 |     711.31832 |    556.273474 | Roberto Díaz Sibaja                                                                                                                                                   |
| 200 |     930.87835 |    586.886419 | Kent Elson Sorgon                                                                                                                                                     |
| 201 |     558.62344 |    176.690745 | C. Camilo Julián-Caballero                                                                                                                                            |
| 202 |     635.07102 |    581.457740 | Joanna Wolfe                                                                                                                                                          |
| 203 |      57.14699 |    623.306831 | Margot Michaud                                                                                                                                                        |
| 204 |     318.80459 |    100.183989 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 205 |     932.00753 |    505.410119 | Steven Traver                                                                                                                                                         |
| 206 |     102.73655 |    676.856523 | Harold N Eyster                                                                                                                                                       |
| 207 |     999.27878 |     51.999369 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 208 |     791.44305 |    257.836035 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 209 |     392.72507 |    294.810191 | NA                                                                                                                                                                    |
| 210 |     633.61559 |    621.567758 | NA                                                                                                                                                                    |
| 211 |     906.66897 |    323.320409 | NA                                                                                                                                                                    |
| 212 |     389.94771 |    531.653708 | Andy Wilson                                                                                                                                                           |
| 213 |     989.85045 |    238.672202 | Zimices                                                                                                                                                               |
| 214 |     492.79209 |     64.893881 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 215 |     698.12411 |    142.065566 | Scott Hartman                                                                                                                                                         |
| 216 |     637.11750 |     29.910546 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 217 |     857.68015 |    308.324996 | Jagged Fang Designs                                                                                                                                                   |
| 218 |     835.02577 |    287.017017 | Zimices                                                                                                                                                               |
| 219 |     106.55510 |    577.024696 | Markus A. Grohme                                                                                                                                                      |
| 220 |     508.63694 |    569.873784 | Cesar Julian                                                                                                                                                          |
| 221 |     703.72845 |     86.177030 | Gareth Monger                                                                                                                                                         |
| 222 |     168.73013 |     45.422893 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 223 |     612.49782 |    272.134784 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 224 |     684.20513 |    542.549749 | Scott Hartman                                                                                                                                                         |
| 225 |     271.69437 |    326.703464 | Matt Crook                                                                                                                                                            |
| 226 |      15.37683 |    143.857265 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 227 |    1001.41693 |    396.128640 | Mathew Wedel                                                                                                                                                          |
| 228 |     471.07146 |    602.341351 | Margot Michaud                                                                                                                                                        |
| 229 |     237.95330 |     53.183884 | Steven Traver                                                                                                                                                         |
| 230 |     869.62838 |     94.358927 | Scott Hartman                                                                                                                                                         |
| 231 |     350.05998 |    335.973977 | Ferran Sayol                                                                                                                                                          |
| 232 |     410.92708 |    102.723340 | Markus A. Grohme                                                                                                                                                      |
| 233 |     678.97731 |    763.277558 | Andy Wilson                                                                                                                                                           |
| 234 |     332.66970 |    606.571572 | L. Shyamal                                                                                                                                                            |
| 235 |     427.82265 |    727.396769 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 236 |     516.41872 |    661.008136 | Chris huh                                                                                                                                                             |
| 237 |     591.32531 |    453.915850 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 238 |     239.78372 |    154.051301 | Scott Hartman                                                                                                                                                         |
| 239 |     553.98338 |    195.689943 | Ferran Sayol                                                                                                                                                          |
| 240 |     465.30046 |     27.810572 | Markus A. Grohme                                                                                                                                                      |
| 241 |     632.17141 |    299.495949 | Yan Wong                                                                                                                                                              |
| 242 |     647.78733 |    377.483652 | NA                                                                                                                                                                    |
| 243 |      16.51865 |    727.536387 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 244 |      27.17011 |     68.273710 | Matt Crook                                                                                                                                                            |
| 245 |     397.23409 |    733.772463 | Chloé Schmidt                                                                                                                                                         |
| 246 |     316.79479 |    436.172274 | Gareth Monger                                                                                                                                                         |
| 247 |     737.20009 |    475.337342 | Tasman Dixon                                                                                                                                                          |
| 248 |     539.19169 |    478.307340 | Beth Reinke                                                                                                                                                           |
| 249 |     878.49281 |    645.069474 | Katie S. Collins                                                                                                                                                      |
| 250 |     446.90485 |    584.098953 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 251 |     947.09784 |    653.684929 | Steven Traver                                                                                                                                                         |
| 252 |     403.01979 |    416.784270 | Sarah Werning                                                                                                                                                         |
| 253 |     297.96179 |    755.163264 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 254 |     208.76283 |    238.423612 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 255 |     387.25254 |    675.892031 | Gareth Monger                                                                                                                                                         |
| 256 |      84.60071 |    297.297608 | Chris huh                                                                                                                                                             |
| 257 |    1003.10868 |     87.171249 | Scott Hartman                                                                                                                                                         |
| 258 |     252.95901 |    349.685441 | Margot Michaud                                                                                                                                                        |
| 259 |     240.02297 |    114.532067 | Matt Crook                                                                                                                                                            |
| 260 |     913.22833 |    712.361837 | (unknown)                                                                                                                                                             |
| 261 |    1006.18574 |    567.646426 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 262 |     817.08070 |    645.214558 | Lukasiniho                                                                                                                                                            |
| 263 |     923.19397 |    360.123786 | Roberto Díaz Sibaja                                                                                                                                                   |
| 264 |     309.40080 |    537.838018 | Jagged Fang Designs                                                                                                                                                   |
| 265 |     680.14635 |    528.650710 | Jagged Fang Designs                                                                                                                                                   |
| 266 |     629.96704 |    676.442748 | NA                                                                                                                                                                    |
| 267 |     321.45433 |    159.876865 | David Orr                                                                                                                                                             |
| 268 |     288.44186 |      7.004301 | Thibaut Brunet                                                                                                                                                        |
| 269 |     196.47758 |    570.607864 | Andy Wilson                                                                                                                                                           |
| 270 |     961.87871 |    294.943429 | CNZdenek                                                                                                                                                              |
| 271 |     812.07298 |    245.321715 | Jagged Fang Designs                                                                                                                                                   |
| 272 |     274.19899 |     59.715846 | Margot Michaud                                                                                                                                                        |
| 273 |     732.39807 |    443.414453 | Ferran Sayol                                                                                                                                                          |
| 274 |     987.48110 |    428.964886 | Margot Michaud                                                                                                                                                        |
| 275 |     782.18273 |    162.339748 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 276 |     582.01960 |    303.711681 | CNZdenek                                                                                                                                                              |
| 277 |      12.96965 |    268.955794 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 278 |     795.73397 |    132.956976 | Steven Traver                                                                                                                                                         |
| 279 |     359.38995 |    785.797459 | Jagged Fang Designs                                                                                                                                                   |
| 280 |     999.39144 |    166.061804 | Ferran Sayol                                                                                                                                                          |
| 281 |     219.72213 |    518.268820 | Ferran Sayol                                                                                                                                                          |
| 282 |     549.78924 |    552.043209 | Gopal Murali                                                                                                                                                          |
| 283 |     139.63691 |    438.804282 | Chris huh                                                                                                                                                             |
| 284 |     683.63398 |     49.690481 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 285 |     239.83253 |    133.817153 | Erika Schumacher                                                                                                                                                      |
| 286 |     392.72339 |    540.570247 | Margot Michaud                                                                                                                                                        |
| 287 |     814.19939 |    161.945345 | Matt Crook                                                                                                                                                            |
| 288 |     204.49741 |    156.981330 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 289 |     584.54720 |    737.578685 | Trond R. Oskars                                                                                                                                                       |
| 290 |     386.39353 |    795.098148 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 291 |     543.26521 |    155.368506 | Ferran Sayol                                                                                                                                                          |
| 292 |     759.70840 |    785.100755 | Gareth Monger                                                                                                                                                         |
| 293 |     533.09001 |     29.449087 | NA                                                                                                                                                                    |
| 294 |      55.53232 |    783.926189 | Robert Hering                                                                                                                                                         |
| 295 |     602.41377 |    483.040472 | Gareth Monger                                                                                                                                                         |
| 296 |     973.94685 |    259.894754 | Mathieu Pélissié                                                                                                                                                      |
| 297 |     117.46578 |    183.011884 | Zimices                                                                                                                                                               |
| 298 |     241.08778 |    184.149046 | Scott Hartman                                                                                                                                                         |
| 299 |      56.84204 |    248.242243 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 300 |     566.54096 |    351.976977 | Gareth Monger                                                                                                                                                         |
| 301 |     905.97015 |    596.097525 | Felix Vaux                                                                                                                                                            |
| 302 |     492.22490 |    195.340936 | Gareth Monger                                                                                                                                                         |
| 303 |     429.85681 |    531.307535 | Matt Crook                                                                                                                                                            |
| 304 |     752.92824 |    663.256386 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 305 |     604.17716 |    415.023676 | Andy Wilson                                                                                                                                                           |
| 306 |      75.51184 |    150.884504 | Christoph Schomburg                                                                                                                                                   |
| 307 |     835.73304 |    238.693974 | ArtFavor & annaleeblysse                                                                                                                                              |
| 308 |     131.33619 |    588.967382 | Tasman Dixon                                                                                                                                                          |
| 309 |     610.35691 |    787.058583 | Markus A. Grohme                                                                                                                                                      |
| 310 |    1008.94475 |    624.167352 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 311 |     194.86169 |    457.574467 | NA                                                                                                                                                                    |
| 312 |     200.79675 |    222.690978 | SauropodomorphMonarch                                                                                                                                                 |
| 313 |     175.67399 |    168.651580 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 314 |     682.59866 |    372.476746 | Ignacio Contreras                                                                                                                                                     |
| 315 |     658.23640 |    397.602793 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
| 316 |     373.32457 |    138.864428 | Zimices                                                                                                                                                               |
| 317 |     508.52867 |    775.333543 | Maija Karala                                                                                                                                                          |
| 318 |      52.93392 |    738.917370 | Jagged Fang Designs                                                                                                                                                   |
| 319 |     147.94997 |    733.375428 | Jagged Fang Designs                                                                                                                                                   |
| 320 |     149.48832 |    410.034948 | Ferran Sayol                                                                                                                                                          |
| 321 |     396.35076 |    447.393144 | Jagged Fang Designs                                                                                                                                                   |
| 322 |     803.86345 |    768.766605 | Jagged Fang Designs                                                                                                                                                   |
| 323 |     902.55032 |     51.012207 | Matt Crook                                                                                                                                                            |
| 324 |     435.34805 |    603.462579 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 325 |     606.94311 |    206.626595 | Margot Michaud                                                                                                                                                        |
| 326 |     565.29264 |    447.330572 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                     |
| 327 |      73.62567 |    454.881682 | T. Michael Keesey                                                                                                                                                     |
| 328 |     999.21960 |    647.651866 | Tony Ayling                                                                                                                                                           |
| 329 |     343.85230 |    548.653145 | Gareth Monger                                                                                                                                                         |
| 330 |     409.09891 |     24.926679 | C. Camilo Julián-Caballero                                                                                                                                            |
| 331 |     140.89863 |     91.534718 | Scott Reid                                                                                                                                                            |
| 332 |     144.36453 |    352.018162 | NA                                                                                                                                                                    |
| 333 |      89.94673 |    507.102813 | Andy Wilson                                                                                                                                                           |
| 334 |      32.11548 |     93.308074 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 335 |     184.65217 |     68.403269 | Zimices                                                                                                                                                               |
| 336 |     511.89566 |     44.790718 | Zimices                                                                                                                                                               |
| 337 |     913.51127 |    294.235676 | Zimices                                                                                                                                                               |
| 338 |    1010.40777 |    344.151425 | T. Michael Keesey                                                                                                                                                     |
| 339 |     462.79707 |    692.027934 | NA                                                                                                                                                                    |
| 340 |     170.74050 |     11.956876 | Julia B McHugh                                                                                                                                                        |
| 341 |      16.76638 |    767.862437 | Steven Traver                                                                                                                                                         |
| 342 |      76.09040 |    319.441601 | Milton Tan                                                                                                                                                            |
| 343 |     450.81878 |    483.178581 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 344 |     621.60240 |    634.363493 | Roderic Page and Lois Page                                                                                                                                            |
| 345 |     567.16768 |    704.616409 | Jagged Fang Designs                                                                                                                                                   |
| 346 |     687.16785 |    549.983260 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 347 |     722.25136 |    423.432760 | Ignacio Contreras                                                                                                                                                     |
| 348 |     266.43932 |     44.394503 | Smokeybjb                                                                                                                                                             |
| 349 |     467.48261 |    573.732200 | NA                                                                                                                                                                    |
| 350 |     851.29165 |    223.588109 | Chris huh                                                                                                                                                             |
| 351 |     700.25791 |    230.818441 | Margot Michaud                                                                                                                                                        |
| 352 |     163.93215 |    775.558744 | Brockhaus and Efron                                                                                                                                                   |
| 353 |     411.78302 |    430.515916 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 354 |     611.86929 |     15.781682 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 355 |     188.32265 |    632.723085 | Scott Hartman                                                                                                                                                         |
| 356 |     328.55692 |    581.413214 | T. Michael Keesey                                                                                                                                                     |
| 357 |     242.29492 |    628.677226 | Skye McDavid                                                                                                                                                          |
| 358 |     826.72699 |    697.270856 | Tasman Dixon                                                                                                                                                          |
| 359 |     114.18943 |     33.299568 | Tasman Dixon                                                                                                                                                          |
| 360 |     877.83203 |    307.250361 | NA                                                                                                                                                                    |
| 361 |     907.95591 |    341.630531 | Stacy Spensley (Modified)                                                                                                                                             |
| 362 |     314.64781 |    681.918374 | Kamil S. Jaron                                                                                                                                                        |
| 363 |     414.89480 |    519.441302 | Matt Martyniuk                                                                                                                                                        |
| 364 |     486.13130 |    180.670816 | C. Camilo Julián-Caballero                                                                                                                                            |
| 365 |     351.74403 |    732.346979 | Renato Santos                                                                                                                                                         |
| 366 |     154.25999 |    322.933116 | Chris huh                                                                                                                                                             |
| 367 |     697.34123 |    580.907656 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 368 |     753.34748 |    621.479883 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 369 |     135.32649 |    128.677953 | Tasman Dixon                                                                                                                                                          |
| 370 |     379.19536 |    236.430518 | Isaure Scavezzoni                                                                                                                                                     |
| 371 |     120.95631 |    243.787324 | CNZdenek                                                                                                                                                              |
| 372 |     260.31170 |    554.260284 | Carlos Cano-Barbacil                                                                                                                                                  |
| 373 |     366.95900 |    659.091762 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 374 |     473.62063 |    789.580574 | Kai R. Caspar                                                                                                                                                         |
| 375 |     598.22409 |    275.759542 | Scott Hartman                                                                                                                                                         |
| 376 |     137.06222 |      4.460129 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 377 |     323.86127 |    230.510660 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 378 |     390.68701 |    307.009241 | Tasman Dixon                                                                                                                                                          |
| 379 |     378.14639 |    267.521404 | Felix Vaux                                                                                                                                                            |
| 380 |     327.72832 |    271.824486 | Jack Mayer Wood                                                                                                                                                       |
| 381 |     388.51211 |    604.508108 | Erika Schumacher                                                                                                                                                      |
| 382 |     246.74215 |    591.413896 | Ignacio Contreras                                                                                                                                                     |
| 383 |      82.26624 |    129.067210 | Michelle Site                                                                                                                                                         |
| 384 |     113.42130 |    485.926964 | T. Michael Keesey                                                                                                                                                     |
| 385 |    1008.03143 |    474.523420 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 386 |     199.67300 |    668.552313 | Steven Traver                                                                                                                                                         |
| 387 |     346.53765 |    497.002151 | Tauana J. Cunha                                                                                                                                                       |
| 388 |     168.57155 |    793.014182 | Markus A. Grohme                                                                                                                                                      |
| 389 |     354.48082 |    599.597016 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                           |
| 390 |     288.91342 |    733.183998 | Chris huh                                                                                                                                                             |
| 391 |     943.57206 |    135.789658 | Zimices                                                                                                                                                               |
| 392 |     921.96708 |    378.230147 | Steven Traver                                                                                                                                                         |
| 393 |     683.80588 |    312.087382 | SauropodomorphMonarch                                                                                                                                                 |
| 394 |     789.64279 |    233.704892 | Gopal Murali                                                                                                                                                          |
| 395 |     295.99654 |    571.858522 | Ferran Sayol                                                                                                                                                          |
| 396 |     756.63842 |    268.901813 | Maija Karala                                                                                                                                                          |
| 397 |     195.04397 |    417.794878 | Matt Crook                                                                                                                                                            |
| 398 |     283.69360 |    362.110927 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 399 |     675.93341 |      7.847191 | Verisimilus                                                                                                                                                           |
| 400 |     987.72023 |      8.646467 | NA                                                                                                                                                                    |
| 401 |    1014.76861 |    745.165338 | T. Michael Keesey                                                                                                                                                     |
| 402 |     237.37460 |    207.909919 | Chris huh                                                                                                                                                             |
| 403 |     360.19137 |    110.548562 | Gareth Monger                                                                                                                                                         |
| 404 |     610.53645 |    570.875728 | Steven Traver                                                                                                                                                         |
| 405 |     779.49263 |    700.172851 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 406 |     810.06092 |    150.635254 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 407 |     728.40309 |    106.781537 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 408 |     664.67454 |    229.969461 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 409 |     719.39042 |      5.723768 | Scott Hartman                                                                                                                                                         |
| 410 |    1008.85287 |     22.440186 | NA                                                                                                                                                                    |
| 411 |     808.40973 |     98.924729 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 412 |     824.59579 |     66.265212 | Frank Denota                                                                                                                                                          |
| 413 |     858.40495 |    606.591943 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 414 |     622.66095 |    616.733497 | Markus A. Grohme                                                                                                                                                      |
| 415 |     909.15820 |    693.874929 | Michael Scroggie                                                                                                                                                      |
| 416 |     435.07063 |     10.508494 | Zimices                                                                                                                                                               |
| 417 |     743.30672 |    323.857282 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 418 |     623.63806 |    100.392909 | FunkMonk                                                                                                                                                              |
| 419 |    1008.80075 |    259.510832 | Steven Coombs                                                                                                                                                         |
| 420 |     743.67266 |    554.770259 | Tasman Dixon                                                                                                                                                          |
| 421 |     385.70429 |    330.143961 | xgirouxb                                                                                                                                                              |
| 422 |      11.56824 |    702.808176 | T. Michael Keesey                                                                                                                                                     |
| 423 |     709.55011 |    712.002123 | Steven Traver                                                                                                                                                         |
| 424 |     175.14475 |    120.292667 | Jagged Fang Designs                                                                                                                                                   |
| 425 |     758.19083 |    651.285726 | Scott Hartman                                                                                                                                                         |
| 426 |     458.91270 |    212.874951 | Zimices                                                                                                                                                               |
| 427 |     440.91758 |    291.343789 | NA                                                                                                                                                                    |
| 428 |     375.16096 |    195.947149 | Jagged Fang Designs                                                                                                                                                   |
| 429 |     730.53044 |    786.095164 | Jagged Fang Designs                                                                                                                                                   |
| 430 |     388.13837 |     94.191228 | Chris huh                                                                                                                                                             |
| 431 |     591.76625 |    706.127423 | CNZdenek                                                                                                                                                              |
| 432 |     100.59896 |    651.411211 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 433 |     249.72154 |    142.569629 | Scott Hartman                                                                                                                                                         |
| 434 |    1016.94977 |    104.323910 | Felix Vaux                                                                                                                                                            |
| 435 |     276.74089 |    682.085885 | T. Michael Keesey                                                                                                                                                     |
| 436 |     323.39941 |    187.603808 | Beth Reinke                                                                                                                                                           |
| 437 |      60.70824 |    485.172295 | Michael Scroggie                                                                                                                                                      |
| 438 |     470.43017 |    754.876146 | Tauana J. Cunha                                                                                                                                                       |
| 439 |     531.03204 |    412.606328 | Gareth Monger                                                                                                                                                         |
| 440 |     301.85464 |    521.400769 | Jagged Fang Designs                                                                                                                                                   |
| 441 |     740.62512 |    715.547273 | Steven Traver                                                                                                                                                         |
| 442 |     595.18102 |    143.403569 | Jagged Fang Designs                                                                                                                                                   |
| 443 |     180.20716 |    646.280695 | Tasman Dixon                                                                                                                                                          |
| 444 |     149.25207 |    635.829373 | Zimices                                                                                                                                                               |
| 445 |      77.82301 |    594.260132 | Fernando Campos De Domenico                                                                                                                                           |
| 446 |     716.79391 |     30.582039 | Jaime Headden                                                                                                                                                         |
| 447 |    1000.04325 |    127.209272 | Margot Michaud                                                                                                                                                        |
| 448 |    1009.01791 |    598.065237 | T. Michael Keesey                                                                                                                                                     |
| 449 |     397.43983 |    118.299545 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 450 |     927.83988 |    740.013389 | Christopher Chávez                                                                                                                                                    |
| 451 |     211.08530 |    654.490561 | Jagged Fang Designs                                                                                                                                                   |
| 452 |     653.63230 |    768.147623 | Andy Wilson                                                                                                                                                           |
| 453 |     802.55122 |    525.330858 | Ignacio Contreras                                                                                                                                                     |
| 454 |     113.41917 |    168.739006 | Scott Hartman                                                                                                                                                         |
| 455 |     410.83039 |    174.641945 | Dmitry Bogdanov                                                                                                                                                       |
| 456 |     109.84429 |     21.425496 | Tasman Dixon                                                                                                                                                          |
| 457 |      82.72896 |    188.156983 | Walter Vladimir                                                                                                                                                       |
| 458 |     542.04129 |      5.210698 | Scott Hartman                                                                                                                                                         |
| 459 |     813.48352 |    300.677431 | JCGiron                                                                                                                                                               |
| 460 |     603.73656 |    287.935723 | Christine Axon                                                                                                                                                        |
| 461 |     726.31748 |     85.355691 | Zimices                                                                                                                                                               |
| 462 |     414.37687 |     87.876097 | Gareth Monger                                                                                                                                                         |
| 463 |     761.39501 |    288.637151 | T. Michael Keesey                                                                                                                                                     |
| 464 |     140.78040 |    142.329318 | Scott Hartman                                                                                                                                                         |
| 465 |     435.50015 |    444.057224 | Gareth Monger                                                                                                                                                         |
| 466 |     180.06279 |    243.059040 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 467 |     921.71679 |    279.901518 | Caleb M. Brown                                                                                                                                                        |
| 468 |     983.48043 |    147.628127 | Lukas Panzarin                                                                                                                                                        |
| 469 |     131.58021 |    262.037039 | Markus A. Grohme                                                                                                                                                      |
| 470 |      19.66567 |    664.665765 | Margot Michaud                                                                                                                                                        |
| 471 |     573.74660 |    796.583771 | Armin Reindl                                                                                                                                                          |
| 472 |     170.77699 |    288.527352 | C. Camilo Julián-Caballero                                                                                                                                            |
| 473 |     387.96103 |    748.544535 | Margot Michaud                                                                                                                                                        |
| 474 |     147.14764 |    708.553326 | Smokeybjb                                                                                                                                                             |
| 475 |      55.92180 |    393.502026 | Mathew Wedel                                                                                                                                                          |
| 476 |     682.75956 |    449.455007 | Andy Wilson                                                                                                                                                           |
| 477 |     841.77837 |     80.874596 | Matt Crook                                                                                                                                                            |
| 478 |     536.11792 |    781.802744 | Neil Kelley                                                                                                                                                           |
| 479 |     120.19945 |    339.365440 | Martin R. Smith                                                                                                                                                       |
| 480 |      55.18989 |    159.590850 | Gareth Monger                                                                                                                                                         |
| 481 |     288.65244 |    785.768963 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 482 |     744.07423 |    145.710587 | NA                                                                                                                                                                    |
| 483 |     701.96183 |    480.282792 | Erika Schumacher                                                                                                                                                      |
| 484 |     716.76764 |    343.891472 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 485 |     984.87589 |    175.083670 | Andy Wilson                                                                                                                                                           |
| 486 |     230.98896 |    562.803672 | Gareth Monger                                                                                                                                                         |
| 487 |     171.31638 |    583.324917 | Ferran Sayol                                                                                                                                                          |
| 488 |     521.95125 |    492.376224 | Matt Crook                                                                                                                                                            |
| 489 |     772.23918 |    254.133089 | Gareth Monger                                                                                                                                                         |
| 490 |     447.57687 |    321.663604 | T. Michael Keesey                                                                                                                                                     |
| 491 |     896.91188 |     38.982560 | Scott Hartman                                                                                                                                                         |
| 492 |     936.40589 |    763.721465 | Becky Barnes                                                                                                                                                          |
| 493 |     650.67780 |    200.968680 | Chris huh                                                                                                                                                             |
| 494 |     110.62236 |    218.495261 | Dmitry Bogdanov                                                                                                                                                       |
| 495 |     475.85148 |    229.246276 | Maija Karala                                                                                                                                                          |
| 496 |     541.37447 |    613.253129 | Andy Wilson                                                                                                                                                           |
| 497 |     123.06478 |    703.133978 | Scott Hartman                                                                                                                                                         |
| 498 |     709.52134 |    766.737755 | Iain Reid                                                                                                                                                             |
| 499 |    1004.22194 |    414.002267 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 500 |     112.88277 |    694.833052 | Jack Mayer Wood                                                                                                                                                       |
| 501 |     343.10756 |    428.581395 | Smokeybjb                                                                                                                                                             |
| 502 |     913.48691 |     12.541908 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 503 |     372.15386 |    246.465874 | Jagged Fang Designs                                                                                                                                                   |
| 504 |     547.22669 |    711.944469 | Zimices                                                                                                                                                               |
| 505 |     974.64941 |    153.005863 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 506 |     177.16189 |    368.024729 | Steven Traver                                                                                                                                                         |
| 507 |     340.50558 |    153.578429 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 508 |     584.50734 |    396.304744 | Tasman Dixon                                                                                                                                                          |
| 509 |     694.69857 |    127.969244 | Gareth Monger                                                                                                                                                         |
| 510 |     282.72821 |    405.828650 | Nobu Tamura                                                                                                                                                           |
| 511 |     259.60115 |    787.204217 | Tasman Dixon                                                                                                                                                          |
| 512 |     911.97824 |    308.316901 | Matt Celeskey                                                                                                                                                         |
| 513 |     590.18583 |    464.128263 | Scott Hartman                                                                                                                                                         |
| 514 |     362.00185 |      5.577918 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 515 |     395.69444 |    254.236121 | Jagged Fang Designs                                                                                                                                                   |
| 516 |     400.51895 |    201.813943 | Chris huh                                                                                                                                                             |
| 517 |     970.64863 |    247.052906 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 518 |     260.16564 |    292.252362 | terngirl                                                                                                                                                              |
| 519 |     254.31246 |    466.598271 | Jagged Fang Designs                                                                                                                                                   |
| 520 |     972.78753 |     37.033296 | Juan Carlos Jerí                                                                                                                                                      |
| 521 |     495.78357 |     26.243556 | Nobu Tamura                                                                                                                                                           |
| 522 |     648.13403 |    209.988019 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 523 |     354.24825 |     15.640153 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 524 |     605.36543 |    773.702090 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 525 |     207.23160 |    476.997517 | Alex Slavenko                                                                                                                                                         |
| 526 |     138.67901 |     39.223537 | Gareth Monger                                                                                                                                                         |
| 527 |     862.58477 |    236.364457 | Andrew A. Farke                                                                                                                                                       |
| 528 |     860.60181 |     14.739783 | Scott Hartman                                                                                                                                                         |
| 529 |     276.42306 |    722.359735 | Gareth Monger                                                                                                                                                         |

    #> Your tweet has been posted!
