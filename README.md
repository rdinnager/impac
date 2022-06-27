
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

Gabriela Palomo-Munoz, Andy Wilson, Duane Raver (vectorized by T.
Michael Keesey), Philip Chalmers (vectorized by T. Michael Keesey),
Ignacio Contreras, Andrew R. Gehrke, Chris huh, Prin Pattawaro (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Jose
Carlos Arenas-Monroy, Amanda Katzer, Neil Kelley, Yan Wong, Maija
Karala, Michelle Site, Katie S. Collins, C. Camilo Julián-Caballero,
Jonathan Wells, Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Ferran Sayol, Zimices, Markus A. Grohme, Nobu Tamura
(vectorized by T. Michael Keesey), Noah Schlottman, photo by Carlos
Sánchez-Ortiz, Tasman Dixon, Yan Wong from wikipedia drawing (PD:
Pearson Scott Foresman), Jagged Fang Designs, Gareth Monger, Sarah
Werning, Greg Schechter (original photo), Renato Santos (vector
silhouette), Arthur S. Brum, Anna Willoughby, Kamil S. Jaron, Jiekun He,
Hans Hillewaert, Zachary Quigley, George Edward Lodge, Steven Blackwood,
Margot Michaud, Shyamal, Lily Hughes, Henry Lydecker, Mathilde
Cordellier, Scott Hartman, Conty (vectorized by T. Michael Keesey), Dean
Schnabel, Matt Crook, FunkMonk, T. Michael Keesey, CNZdenek, Beth
Reinke, Tracy A. Heath, Michele M Tobias from an image By Dcrjsr - Own
work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Ricardo N. Martinez & Oscar
A. Alcober, Steven Traver, Scott Hartman (vectorized by William Gearty),
Nobu Tamura, vectorized by Zimices, Ingo Braasch, Pollyanna von Knorring
and T. Michael Keesey, Melissa Broussard, Smokeybjb, Birgit Lang, C.
Abraczinskas, Juan Carlos Jerí, Caleb M. Brown, Metalhead64 (vectorized
by T. Michael Keesey), Manabu Bessho-Uehara, Mr E? (vectorized by T.
Michael Keesey), Tyler McCraney, Carlos Cano-Barbacil, Collin Gross,
Michele Tobias, Matt Dempsey, Chris Jennings (Risiatto), Agnello
Picorelli, Nina Skinner, Becky Barnes, Noah Schlottman, Emily
Willoughby, Michael B. H. (vectorized by T. Michael Keesey), Eric Moody,
Geoff Shaw, Conty, Christine Axon, Jessica Anne Miller, Roberto Díaz
Sibaja, Crystal Maier, Mathieu Pélissié, Milton Tan, Young and Zhao
(1972:figure 4), modified by Michael P. Taylor, Iain Reid, Chuanixn Yu,
Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and
Timothy J. Bartley (silhouette), Sherman F. Denton via rawpixel.com
(illustration) and Timothy J. Bartley (silhouette), Mathieu Basille,
Robert Bruce Horsfall (vectorized by T. Michael Keesey), Stanton F. Fink
(vectorized by T. Michael Keesey), Mathew Wedel, Sergio A. Muñoz-Gómez,
Kailah Thorn & Mark Hutchinson, Brad McFeeters (vectorized by T. Michael
Keesey), Terpsichores, Samanta Orellana, L. Shyamal, Felix Vaux, Mali’o
Kodis, photograph property of National Museums of Northern Ireland,
Sebastian Stabinger, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Nobu Tamura,
modified by Andrew A. Farke, Stephen O’Connor (vectorized by T. Michael
Keesey), Timothy Knepp (vectorized by T. Michael Keesey), Andrew A.
Farke, xgirouxb, Heinrich Harder (vectorized by William Gearty), Steven
Coombs (vectorized by T. Michael Keesey), Obsidian Soul (vectorized by
T. Michael Keesey), Matthew E. Clapham, Chloé Schmidt, Dave Souza
(vectorized by T. Michael Keesey), B. Duygu Özpolat, Michael P. Taylor,
Mathew Stewart, Steven Coombs, Alexander Schmidt-Lebuhn, Erika
Schumacher, Gabriele Midolo, Peter Coxhead, T. Michael Keesey (after
James & al.), George Edward Lodge (vectorized by T. Michael Keesey),
Matus Valach, Rebecca Groom, Jimmy Bernot, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Lukasiniho, SecretJellyMan, Dmitry Bogdanov, V. Deepak, Mariana Ruiz
Villarreal (modified by T. Michael Keesey), Smokeybjb (vectorized by T.
Michael Keesey), Nicholas J. Czaplewski, vectorized by Zimices, Cagri
Cevrim, Brian Swartz (vectorized by T. Michael Keesey), Sharon
Wegner-Larsen, Rene Martin, T. Tischler, Noah Schlottman, photo from
Casey Dunn, Tyler Greenfield, Darren Naish (vectorize by T. Michael
Keesey), Mette Aumala, Roberto Diaz Sibaja, based on Domser, Ewald
Rübsamen, Christoph Schomburg, Apokryltaros (vectorized by T. Michael
Keesey), Falconaumanni and T. Michael Keesey, Aviceda (vectorized by T.
Michael Keesey), Scott Hartman (vectorized by T. Michael Keesey), Alex
Slavenko, T. Michael Keesey (from a mount by Allis Markham), M Kolmann,
Julien Louys, T. Michael Keesey (vector) and Stuart Halliday
(photograph), Ghedoghedo (vectorized by T. Michael Keesey), Arthur
Weasley (vectorized by T. Michael Keesey), Tony Ayling, Andrew Farke and
Joseph Sertich, David Orr, FunkMonk (Michael B.H.; vectorized by T.
Michael Keesey), Oscar Sanisidro, Lukas Panzarin, Michele M Tobias,
Michael Scroggie, John Conway, Cathy, Robbie N. Cada (vectorized by T.
Michael Keesey), Jaime Headden, Harold N Eyster, Christina N. Hodson,
Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Kanako Bessho-Uehara, Martin R. Smith, Óscar San−Isidro
(vectorized by T. Michael Keesey), Sean McCann, DW Bapst (Modified from
photograph taken by Charles Mitchell), Siobhon Egan

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    581.987251 |    179.086599 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   2 |    549.825685 |    536.797441 | Andy Wilson                                                                                                                                                           |
|   3 |    796.185049 |    165.759656 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
|   4 |    552.531189 |    330.495905 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
|   5 |    244.759268 |    627.174514 | Ignacio Contreras                                                                                                                                                     |
|   6 |    741.517567 |    394.625579 | Andrew R. Gehrke                                                                                                                                                      |
|   7 |    782.182898 |     29.768767 | Chris huh                                                                                                                                                             |
|   8 |    894.171962 |    328.099566 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
|   9 |    687.822680 |    254.593422 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  10 |    505.130040 |    443.931662 | Amanda Katzer                                                                                                                                                         |
|  11 |    614.843747 |    700.431713 | Neil Kelley                                                                                                                                                           |
|  12 |    310.599415 |    734.706059 | Chris huh                                                                                                                                                             |
|  13 |    695.114669 |     82.773603 | Yan Wong                                                                                                                                                              |
|  14 |    421.807276 |    786.836415 | Maija Karala                                                                                                                                                          |
|  15 |    672.557179 |    512.151642 | NA                                                                                                                                                                    |
|  16 |    925.075621 |    641.664747 | Michelle Site                                                                                                                                                         |
|  17 |    280.800460 |    266.134219 | Katie S. Collins                                                                                                                                                      |
|  18 |    477.273798 |    759.191264 | C. Camilo Julián-Caballero                                                                                                                                            |
|  19 |    115.116100 |    731.234725 | Jonathan Wells                                                                                                                                                        |
|  20 |    371.431164 |    589.725085 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
|  21 |     63.415680 |    522.801040 | Ferran Sayol                                                                                                                                                          |
|  22 |    576.057023 |    626.848302 | Zimices                                                                                                                                                               |
|  23 |    950.396510 |    481.093254 | Markus A. Grohme                                                                                                                                                      |
|  24 |    878.833644 |    544.705498 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  25 |    838.061156 |    715.211745 | Chris huh                                                                                                                                                             |
|  26 |    749.446293 |    605.116211 | Ferran Sayol                                                                                                                                                          |
|  27 |    376.917103 |    509.368150 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  28 |     66.703080 |    164.278064 | NA                                                                                                                                                                    |
|  29 |    187.140667 |    513.608660 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
|  30 |     60.643177 |    473.362615 | Tasman Dixon                                                                                                                                                          |
|  31 |    180.292385 |     53.981826 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  32 |    680.275758 |    116.564661 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
|  33 |    342.435431 |     91.788423 | C. Camilo Julián-Caballero                                                                                                                                            |
|  34 |    922.896369 |    108.301052 | Jagged Fang Designs                                                                                                                                                   |
|  35 |     74.229144 |    624.303392 | Zimices                                                                                                                                                               |
|  36 |    372.102541 |     29.893646 | Gareth Monger                                                                                                                                                         |
|  37 |    539.536474 |     84.465742 | Sarah Werning                                                                                                                                                         |
|  38 |    447.289996 |    692.185221 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  39 |    428.074814 |    104.714246 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                    |
|  40 |    791.936735 |    524.813550 | NA                                                                                                                                                                    |
|  41 |    717.259075 |    691.588734 | NA                                                                                                                                                                    |
|  42 |    946.503245 |    744.825135 | Arthur S. Brum                                                                                                                                                        |
|  43 |    636.333802 |    753.150288 | Anna Willoughby                                                                                                                                                       |
|  44 |    963.513191 |    550.650296 | Gareth Monger                                                                                                                                                         |
|  45 |    979.687668 |    281.166289 | Kamil S. Jaron                                                                                                                                                        |
|  46 |     87.403595 |     66.417976 | Maija Karala                                                                                                                                                          |
|  47 |     42.356734 |    343.759643 | Jiekun He                                                                                                                                                             |
|  48 |    837.563541 |    237.704555 | Hans Hillewaert                                                                                                                                                       |
|  49 |    642.807298 |    364.027362 | NA                                                                                                                                                                    |
|  50 |    949.347398 |    174.926317 | Ferran Sayol                                                                                                                                                          |
|  51 |    836.520493 |    445.472997 | Jagged Fang Designs                                                                                                                                                   |
|  52 |    919.346558 |     18.366751 | Zachary Quigley                                                                                                                                                       |
|  53 |    788.686833 |    361.160084 | George Edward Lodge                                                                                                                                                   |
|  54 |    304.953124 |    452.992047 | Steven Blackwood                                                                                                                                                      |
|  55 |    496.865762 |    187.867877 | Margot Michaud                                                                                                                                                        |
|  56 |    800.450887 |    664.072715 | Shyamal                                                                                                                                                               |
|  57 |    518.034868 |    482.695923 | Chris huh                                                                                                                                                             |
|  58 |    161.231581 |    776.145852 | Lily Hughes                                                                                                                                                           |
|  59 |    275.352191 |    766.077176 | NA                                                                                                                                                                    |
|  60 |    779.625539 |    782.577196 | Markus A. Grohme                                                                                                                                                      |
|  61 |    126.828108 |    576.943788 | Henry Lydecker                                                                                                                                                        |
|  62 |     76.665212 |    424.106059 | Zimices                                                                                                                                                               |
|  63 |    683.927813 |    398.079483 | Mathilde Cordellier                                                                                                                                                   |
|  64 |    130.858187 |    113.160180 | Scott Hartman                                                                                                                                                         |
|  65 |     49.765997 |    264.360206 | Ignacio Contreras                                                                                                                                                     |
|  66 |    867.597541 |    789.311033 | Ferran Sayol                                                                                                                                                          |
|  67 |     46.612710 |     23.040173 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  68 |    949.502864 |    413.144772 | Dean Schnabel                                                                                                                                                         |
|  69 |    808.609309 |    100.115436 | Matt Crook                                                                                                                                                            |
|  70 |    434.472230 |    556.564648 | Margot Michaud                                                                                                                                                        |
|  71 |     32.864518 |    207.679506 | Ferran Sayol                                                                                                                                                          |
|  72 |    408.958611 |    467.895956 | Zimices                                                                                                                                                               |
|  73 |    507.235414 |    612.516473 | Scott Hartman                                                                                                                                                         |
|  74 |    500.891401 |    632.201874 | FunkMonk                                                                                                                                                              |
|  75 |    614.989273 |    101.096179 | T. Michael Keesey                                                                                                                                                     |
|  76 |    147.849614 |    446.813396 | NA                                                                                                                                                                    |
|  77 |    188.248335 |    453.632575 | Dean Schnabel                                                                                                                                                         |
|  78 |     71.710499 |    684.838838 | CNZdenek                                                                                                                                                              |
|  79 |    229.354281 |     19.743448 | Beth Reinke                                                                                                                                                           |
|  80 |    322.271600 |    686.864928 | Tracy A. Heath                                                                                                                                                        |
|  81 |   1004.131851 |    666.926279 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
|  82 |    143.787707 |     93.961751 | NA                                                                                                                                                                    |
|  83 |    932.813415 |     57.126747 | Zimices                                                                                                                                                               |
|  84 |    131.628812 |    656.119668 | NA                                                                                                                                                                    |
|  85 |    290.180715 |    491.157028 | Zimices                                                                                                                                                               |
|  86 |     48.082151 |    752.688737 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  87 |    683.862582 |    635.573906 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
|  88 |    625.790032 |    561.832038 | Matt Crook                                                                                                                                                            |
|  89 |    274.753256 |    559.062792 | Dean Schnabel                                                                                                                                                         |
|  90 |    425.078529 |    498.343691 | Steven Traver                                                                                                                                                         |
|  91 |    923.986533 |    274.103275 | Scott Hartman                                                                                                                                                         |
|  92 |    572.230646 |    256.220674 | Ferran Sayol                                                                                                                                                          |
|  93 |    268.473482 |    692.396841 | Matt Crook                                                                                                                                                            |
|  94 |    552.968023 |    686.622586 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  95 |    515.381068 |    781.990239 | Scott Hartman (vectorized by William Gearty)                                                                                                                          |
|  96 |    631.018418 |     21.917000 | CNZdenek                                                                                                                                                              |
|  97 |    683.996705 |    318.808354 | Jagged Fang Designs                                                                                                                                                   |
|  98 |    257.282715 |     98.020906 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  99 |    799.461292 |    296.584551 | Ingo Braasch                                                                                                                                                          |
| 100 |    999.043636 |    170.490303 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 101 |    529.651520 |    715.383899 | Tasman Dixon                                                                                                                                                          |
| 102 |    513.269026 |    261.002143 | Matt Crook                                                                                                                                                            |
| 103 |    629.558706 |    780.371351 | Melissa Broussard                                                                                                                                                     |
| 104 |    926.257769 |    605.760699 | Zimices                                                                                                                                                               |
| 105 |    949.110362 |    692.170215 | Ferran Sayol                                                                                                                                                          |
| 106 |    146.680961 |    471.068639 | Markus A. Grohme                                                                                                                                                      |
| 107 |    941.333181 |     77.657918 | Smokeybjb                                                                                                                                                             |
| 108 |    477.902328 |     44.914311 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 109 |    279.620211 |     56.453336 | Birgit Lang                                                                                                                                                           |
| 110 |    398.507314 |    123.822835 | C. Abraczinskas                                                                                                                                                       |
| 111 |   1001.536277 |     54.626818 | Zimices                                                                                                                                                               |
| 112 |   1007.534599 |    359.372861 | Matt Crook                                                                                                                                                            |
| 113 |    504.870198 |    396.197300 | Juan Carlos Jerí                                                                                                                                                      |
| 114 |    849.943902 |    750.355492 | Caleb M. Brown                                                                                                                                                        |
| 115 |    997.491091 |    445.257457 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 116 |    649.575946 |    150.157718 | Manabu Bessho-Uehara                                                                                                                                                  |
| 117 |    627.892997 |    652.250604 | Birgit Lang                                                                                                                                                           |
| 118 |    315.803769 |    519.689207 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 119 |    383.010073 |    707.571242 | Tasman Dixon                                                                                                                                                          |
| 120 |    345.983910 |    617.996999 | Tyler McCraney                                                                                                                                                        |
| 121 |    294.935850 |    693.369806 | Carlos Cano-Barbacil                                                                                                                                                  |
| 122 |    329.690929 |    644.894568 | Zimices                                                                                                                                                               |
| 123 |    874.759197 |    445.083849 | Collin Gross                                                                                                                                                          |
| 124 |    978.935628 |    603.198232 | Michele Tobias                                                                                                                                                        |
| 125 |    288.862582 |    527.709762 | Matt Crook                                                                                                                                                            |
| 126 |    615.881290 |    237.510595 | T. Michael Keesey                                                                                                                                                     |
| 127 |    482.898102 |    525.532262 | Matt Dempsey                                                                                                                                                          |
| 128 |    305.981184 |     30.336895 | Sarah Werning                                                                                                                                                         |
| 129 |   1007.859042 |    401.497341 | Chris Jennings (Risiatto)                                                                                                                                             |
| 130 |    826.385813 |    586.112988 | Agnello Picorelli                                                                                                                                                     |
| 131 |    856.963074 |    405.936725 | Nina Skinner                                                                                                                                                          |
| 132 |    733.381090 |    562.443726 | Becky Barnes                                                                                                                                                          |
| 133 |    632.250038 |     51.843173 | Noah Schlottman                                                                                                                                                       |
| 134 |    523.817112 |     18.051683 | Emily Willoughby                                                                                                                                                      |
| 135 |    869.653519 |    674.151029 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 136 |    609.915180 |    143.164743 | Eric Moody                                                                                                                                                            |
| 137 |    885.095292 |    419.525151 | Margot Michaud                                                                                                                                                        |
| 138 |    970.661753 |    359.344874 | Matt Crook                                                                                                                                                            |
| 139 |    586.666595 |    467.938645 | Tasman Dixon                                                                                                                                                          |
| 140 |     85.678678 |    386.636123 | Margot Michaud                                                                                                                                                        |
| 141 |    399.542114 |    146.460564 | Andy Wilson                                                                                                                                                           |
| 142 |    461.553942 |    580.582791 | Scott Hartman                                                                                                                                                         |
| 143 |    198.058083 |     72.417404 | Geoff Shaw                                                                                                                                                            |
| 144 |    279.852083 |    611.964070 | Collin Gross                                                                                                                                                          |
| 145 |    918.707385 |    718.429304 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 146 |    765.182507 |    261.604809 | Steven Traver                                                                                                                                                         |
| 147 |    555.104937 |    391.078010 | NA                                                                                                                                                                    |
| 148 |    981.856551 |     91.657217 | NA                                                                                                                                                                    |
| 149 |    466.445823 |    392.610712 | Conty                                                                                                                                                                 |
| 150 |    520.413598 |    160.134372 | Ferran Sayol                                                                                                                                                          |
| 151 |    975.765352 |    779.315914 | Juan Carlos Jerí                                                                                                                                                      |
| 152 |    626.422133 |    429.305708 | Christine Axon                                                                                                                                                        |
| 153 |    962.709448 |    452.249291 | Jessica Anne Miller                                                                                                                                                   |
| 154 |     48.106460 |    112.528217 | Gareth Monger                                                                                                                                                         |
| 155 |    461.073724 |     65.478472 | Roberto Díaz Sibaja                                                                                                                                                   |
| 156 |    661.134610 |    609.213862 | Margot Michaud                                                                                                                                                        |
| 157 |    190.226910 |    503.994088 | Melissa Broussard                                                                                                                                                     |
| 158 |     25.216013 |     90.110613 | Gareth Monger                                                                                                                                                         |
| 159 |    773.821410 |    202.051270 | Crystal Maier                                                                                                                                                         |
| 160 |    560.245346 |    669.195830 | Kamil S. Jaron                                                                                                                                                        |
| 161 |    471.710530 |      8.191984 | Jagged Fang Designs                                                                                                                                                   |
| 162 |    295.132418 |    780.648863 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 163 |     57.548316 |    787.387298 | Matt Crook                                                                                                                                                            |
| 164 |   1000.082685 |    619.739357 | Mathieu Pélissié                                                                                                                                                      |
| 165 |     22.948944 |    251.963499 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 166 |    664.578352 |    177.322413 | Matt Crook                                                                                                                                                            |
| 167 |    498.666190 |    495.995878 | NA                                                                                                                                                                    |
| 168 |    884.587888 |    197.273517 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 169 |    179.628221 |    753.011103 | Mathieu Pélissié                                                                                                                                                      |
| 170 |    154.998870 |    129.057983 | Milton Tan                                                                                                                                                            |
| 171 |    521.426436 |    756.967806 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 172 |    591.311426 |    491.961420 | Iain Reid                                                                                                                                                             |
| 173 |    404.636153 |    623.291887 | Markus A. Grohme                                                                                                                                                      |
| 174 |    955.492692 |    506.877628 | Jagged Fang Designs                                                                                                                                                   |
| 175 |    674.334324 |    139.026620 | Jagged Fang Designs                                                                                                                                                   |
| 176 |    756.241976 |    114.136132 | Chuanixn Yu                                                                                                                                                           |
| 177 |    516.425456 |    645.508378 | Jiekun He                                                                                                                                                             |
| 178 |    464.608212 |    468.704552 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 179 |    136.793341 |    514.609960 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 180 |    886.776862 |    769.118667 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 181 |    415.708146 |    167.653030 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 182 |    562.986536 |    495.389310 | Mathieu Basille                                                                                                                                                       |
| 183 |    176.133949 |    684.963631 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 184 |     16.329245 |    711.121844 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 185 |    708.160432 |     15.864165 | Noah Schlottman                                                                                                                                                       |
| 186 |    392.799168 |    686.196497 | Mathew Wedel                                                                                                                                                          |
| 187 |    244.519025 |    486.091345 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 188 |    616.083982 |    359.443544 | Chris huh                                                                                                                                                             |
| 189 |    527.325718 |    604.181988 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 190 |   1002.299159 |    778.716025 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 191 |    543.099423 |    654.347066 | Birgit Lang                                                                                                                                                           |
| 192 |    914.972623 |    445.713201 | Steven Traver                                                                                                                                                         |
| 193 |    677.655867 |    733.584061 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 194 |    714.505953 |    339.650788 | NA                                                                                                                                                                    |
| 195 |    564.252330 |    756.308032 | Terpsichores                                                                                                                                                          |
| 196 |     39.675317 |    719.387264 | Samanta Orellana                                                                                                                                                      |
| 197 |    672.519256 |    777.883061 | Matt Crook                                                                                                                                                            |
| 198 |    322.431531 |    558.871340 | NA                                                                                                                                                                    |
| 199 |    216.958429 |    431.147769 | T. Michael Keesey                                                                                                                                                     |
| 200 |     21.363840 |    579.073096 | Markus A. Grohme                                                                                                                                                      |
| 201 |    764.356255 |    758.850716 | Zimices                                                                                                                                                               |
| 202 |    878.256196 |     62.045120 | L. Shyamal                                                                                                                                                            |
| 203 |    115.602383 |    559.229143 | Markus A. Grohme                                                                                                                                                      |
| 204 |     76.019768 |    794.859941 | Zimices                                                                                                                                                               |
| 205 |    640.863195 |     69.467332 | Matt Crook                                                                                                                                                            |
| 206 |    626.396216 |    462.443089 | Scott Hartman                                                                                                                                                         |
| 207 |    977.545928 |     43.131069 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 208 |    947.257559 |    386.270002 | Gareth Monger                                                                                                                                                         |
| 209 |     29.414834 |    495.719263 | Andy Wilson                                                                                                                                                           |
| 210 |    510.831197 |    587.069385 | Felix Vaux                                                                                                                                                            |
| 211 |    185.728843 |    722.650691 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 212 |    659.146068 |    651.752142 | Zimices                                                                                                                                                               |
| 213 |    751.884148 |    467.185650 | Sebastian Stabinger                                                                                                                                                   |
| 214 |    989.176261 |    505.776741 | Tasman Dixon                                                                                                                                                          |
| 215 |    756.337905 |    495.552116 | Ferran Sayol                                                                                                                                                          |
| 216 |    657.885671 |     47.857911 | NA                                                                                                                                                                    |
| 217 |    585.601578 |    244.438705 | Scott Hartman                                                                                                                                                         |
| 218 |    703.924531 |    453.848673 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 219 |   1000.589811 |    382.704775 | Scott Hartman                                                                                                                                                         |
| 220 |    984.936708 |     75.279749 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 221 |    911.208420 |    674.410757 | Matt Crook                                                                                                                                                            |
| 222 |    220.432112 |    444.681714 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 223 |     57.315746 |    227.187485 | T. Michael Keesey                                                                                                                                                     |
| 224 |    115.589876 |    628.067545 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 225 |   1000.329303 |    129.738105 | L. Shyamal                                                                                                                                                            |
| 226 |    760.548338 |    130.299305 | Jagged Fang Designs                                                                                                                                                   |
| 227 |    105.301961 |     86.469181 | Scott Hartman                                                                                                                                                         |
| 228 |    205.392458 |    522.054684 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 229 |    726.948828 |    319.352393 | Andrew A. Farke                                                                                                                                                       |
| 230 |    826.958575 |     68.893660 | Markus A. Grohme                                                                                                                                                      |
| 231 |    757.489976 |     66.990266 | xgirouxb                                                                                                                                                              |
| 232 |     35.002720 |    769.336454 | Geoff Shaw                                                                                                                                                            |
| 233 |    512.677053 |    573.566044 | Chris huh                                                                                                                                                             |
| 234 |    543.248889 |      3.381714 | Smokeybjb                                                                                                                                                             |
| 235 |    591.251694 |    107.251007 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 236 |    233.875190 |      6.312541 | Markus A. Grohme                                                                                                                                                      |
| 237 |    905.521745 |    401.722614 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 238 |     89.137722 |    205.803619 | Zimices                                                                                                                                                               |
| 239 |    969.605855 |    391.484482 | Scott Hartman                                                                                                                                                         |
| 240 |    323.382317 |    788.348372 | Yan Wong                                                                                                                                                              |
| 241 |    695.528264 |    779.978707 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 242 |    792.335996 |    276.095156 | Zimices                                                                                                                                                               |
| 243 |    761.881001 |    228.685338 | Matthew E. Clapham                                                                                                                                                    |
| 244 |    600.807988 |    389.299097 | NA                                                                                                                                                                    |
| 245 |    155.112213 |    493.862763 | Chloé Schmidt                                                                                                                                                         |
| 246 |    813.462361 |    315.576488 | Emily Willoughby                                                                                                                                                      |
| 247 |    998.520822 |      9.530469 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 248 |    974.727675 |    530.766820 | Dean Schnabel                                                                                                                                                         |
| 249 |    902.654194 |    146.453142 | B. Duygu Özpolat                                                                                                                                                      |
| 250 |    939.068897 |    309.708218 | Tracy A. Heath                                                                                                                                                        |
| 251 |    401.761269 |    737.516665 | Michael P. Taylor                                                                                                                                                     |
| 252 |    378.579021 |    434.262949 | Zimices                                                                                                                                                               |
| 253 |     73.631473 |     28.609756 | Margot Michaud                                                                                                                                                        |
| 254 |     33.508796 |    310.340189 | Tasman Dixon                                                                                                                                                          |
| 255 |    383.762567 |     59.303075 | Kamil S. Jaron                                                                                                                                                        |
| 256 |    467.472945 |    129.744672 | Melissa Broussard                                                                                                                                                     |
| 257 |    740.312096 |    203.454813 | Mathew Stewart                                                                                                                                                        |
| 258 |    444.296518 |     20.540996 | NA                                                                                                                                                                    |
| 259 |    647.188620 |    443.435739 | Jagged Fang Designs                                                                                                                                                   |
| 260 |    106.371324 |     36.689404 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 261 |    918.948865 |    374.423181 | Scott Hartman                                                                                                                                                         |
| 262 |    697.125013 |    182.742237 | Zimices                                                                                                                                                               |
| 263 |    426.270582 |    515.310647 | Steven Coombs                                                                                                                                                         |
| 264 |    636.442046 |    624.287609 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 265 |    864.293235 |    635.681510 | Margot Michaud                                                                                                                                                        |
| 266 |    806.908671 |    583.873312 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 267 |    495.204574 |    298.080417 | Erika Schumacher                                                                                                                                                      |
| 268 |    217.804257 |    510.129420 | Scott Hartman                                                                                                                                                         |
| 269 |    551.614130 |    201.415571 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 270 |    594.636437 |    410.155829 | Smokeybjb                                                                                                                                                             |
| 271 |    162.504601 |    560.211589 | Mathew Wedel                                                                                                                                                          |
| 272 |    923.555239 |    508.591642 | Gabriele Midolo                                                                                                                                                       |
| 273 |    947.374578 |    527.732606 | Peter Coxhead                                                                                                                                                         |
| 274 |     46.801941 |    454.568167 | Gareth Monger                                                                                                                                                         |
| 275 |    516.992250 |    742.574664 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 276 |    450.761759 |    191.261866 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 277 |   1003.321570 |    729.221844 | Steven Traver                                                                                                                                                         |
| 278 |    805.365747 |    129.219221 | Zimices                                                                                                                                                               |
| 279 |    462.590273 |    620.888611 | Beth Reinke                                                                                                                                                           |
| 280 |    710.951964 |    357.252700 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 281 |    586.525216 |     34.994505 | Scott Hartman                                                                                                                                                         |
| 282 |    136.638992 |    144.873197 | Scott Hartman                                                                                                                                                         |
| 283 |    514.536833 |    142.417607 | Emily Willoughby                                                                                                                                                      |
| 284 |    285.908596 |    707.189724 | Matus Valach                                                                                                                                                          |
| 285 |    791.343596 |     84.747438 | Gareth Monger                                                                                                                                                         |
| 286 |    521.252077 |    704.997975 | Scott Hartman                                                                                                                                                         |
| 287 |    319.160421 |    663.036728 | Mathew Wedel                                                                                                                                                          |
| 288 |    831.408825 |    114.756684 | NA                                                                                                                                                                    |
| 289 |    400.967770 |    417.137320 | Gareth Monger                                                                                                                                                         |
| 290 |    153.387428 |    421.566709 | NA                                                                                                                                                                    |
| 291 |    830.566173 |    676.542595 | Ferran Sayol                                                                                                                                                          |
| 292 |    500.619300 |    167.808984 | Gareth Monger                                                                                                                                                         |
| 293 |    917.937037 |    793.886050 | Tasman Dixon                                                                                                                                                          |
| 294 |    105.794846 |     22.619191 | Margot Michaud                                                                                                                                                        |
| 295 |    671.801173 |    572.281477 | Andy Wilson                                                                                                                                                           |
| 296 |    422.384134 |    392.692917 | Rebecca Groom                                                                                                                                                         |
| 297 |     35.082060 |    291.911003 | Jagged Fang Designs                                                                                                                                                   |
| 298 |   1004.851037 |     81.883161 | Jimmy Bernot                                                                                                                                                          |
| 299 |    612.329925 |    310.918778 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 300 |    214.243744 |    713.698548 | Michelle Site                                                                                                                                                         |
| 301 |    535.964019 |    749.324834 | Steven Traver                                                                                                                                                         |
| 302 |    386.991309 |    659.661588 | T. Michael Keesey                                                                                                                                                     |
| 303 |    431.884936 |    587.128809 | Chris huh                                                                                                                                                             |
| 304 |    979.819629 |    697.484045 | Scott Hartman (vectorized by William Gearty)                                                                                                                          |
| 305 |    692.434438 |    590.108884 | Caleb M. Brown                                                                                                                                                        |
| 306 |    117.406160 |    399.447707 | Jagged Fang Designs                                                                                                                                                   |
| 307 |    628.407241 |    156.669504 | Lukasiniho                                                                                                                                                            |
| 308 |    884.532550 |    756.422064 | Andy Wilson                                                                                                                                                           |
| 309 |    244.795889 |     46.935548 | Gareth Monger                                                                                                                                                         |
| 310 |     98.644797 |    144.070299 | Kamil S. Jaron                                                                                                                                                        |
| 311 |    353.940442 |    127.467594 | Zimices                                                                                                                                                               |
| 312 |    120.049881 |    753.488793 | Margot Michaud                                                                                                                                                        |
| 313 |    855.852819 |    464.466745 | SecretJellyMan                                                                                                                                                        |
| 314 |     36.886637 |    132.877183 | Jagged Fang Designs                                                                                                                                                   |
| 315 |    444.797314 |    641.846830 | Dmitry Bogdanov                                                                                                                                                       |
| 316 |    607.251482 |    530.694137 | V. Deepak                                                                                                                                                             |
| 317 |    368.613524 |    625.836349 | Matt Dempsey                                                                                                                                                          |
| 318 |     34.737704 |    330.488014 | Scott Hartman                                                                                                                                                         |
| 319 |   1003.877298 |     20.028877 | Jagged Fang Designs                                                                                                                                                   |
| 320 |    570.715010 |     91.719059 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 321 |     55.806255 |    511.747213 | NA                                                                                                                                                                    |
| 322 |    141.135731 |    154.511164 | Scott Hartman                                                                                                                                                         |
| 323 |    610.684121 |    484.382006 | Beth Reinke                                                                                                                                                           |
| 324 |    757.048950 |    283.864074 | Yan Wong                                                                                                                                                              |
| 325 |    158.477406 |    599.821823 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 326 |    842.786735 |    140.731770 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 327 |    424.737503 |    142.346108 | Gareth Monger                                                                                                                                                         |
| 328 |    491.467695 |    319.776795 | Andrew A. Farke                                                                                                                                                       |
| 329 |      5.692980 |    444.397523 | T. Michael Keesey                                                                                                                                                     |
| 330 |    770.737363 |    679.605989 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 331 |    480.685437 |     26.549316 | Maija Karala                                                                                                                                                          |
| 332 |    527.205278 |    189.875001 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 333 |    976.351373 |    337.201330 | Kamil S. Jaron                                                                                                                                                        |
| 334 |    133.808366 |    565.677996 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 335 |    571.991982 |    117.272614 | Chris huh                                                                                                                                                             |
| 336 |    476.347848 |    509.342685 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 337 |    829.435048 |    332.633384 | Tracy A. Heath                                                                                                                                                        |
| 338 |    466.019795 |    728.296523 | Cagri Cevrim                                                                                                                                                          |
| 339 |    339.432205 |    421.598615 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
| 340 |    300.402470 |    649.268002 | Sharon Wegner-Larsen                                                                                                                                                  |
| 341 |     62.220411 |      6.222556 | Rene Martin                                                                                                                                                           |
| 342 |    742.351296 |    300.300817 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 343 |    358.648666 |    657.989804 | Geoff Shaw                                                                                                                                                            |
| 344 |    682.783706 |     26.221262 | Jagged Fang Designs                                                                                                                                                   |
| 345 |    892.239569 |    285.849614 | Ferran Sayol                                                                                                                                                          |
| 346 |    241.288859 |    791.980042 | Andy Wilson                                                                                                                                                           |
| 347 |    210.180885 |     96.816537 | Gareth Monger                                                                                                                                                         |
| 348 |    348.757953 |    438.125612 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 349 |     61.466072 |    579.880979 | Jagged Fang Designs                                                                                                                                                   |
| 350 |    687.184478 |    685.561677 | Kamil S. Jaron                                                                                                                                                        |
| 351 |     59.542086 |    660.115542 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 352 |    679.898103 |    191.059491 | Markus A. Grohme                                                                                                                                                      |
| 353 |    321.589749 |    614.095344 | T. Tischler                                                                                                                                                           |
| 354 |    803.427063 |    740.657062 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 355 |     60.775829 |    501.665453 | Collin Gross                                                                                                                                                          |
| 356 |    989.619850 |    213.536688 | Sarah Werning                                                                                                                                                         |
| 357 |    846.423453 |    481.757781 | Markus A. Grohme                                                                                                                                                      |
| 358 |     51.664714 |     40.866884 | Tyler Greenfield                                                                                                                                                      |
| 359 |    474.818220 |    365.784889 | Melissa Broussard                                                                                                                                                     |
| 360 |     16.119393 |    276.588358 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 361 |    515.802735 |      7.659601 | Smokeybjb                                                                                                                                                             |
| 362 |     23.704088 |    115.105271 | Tasman Dixon                                                                                                                                                          |
| 363 |    567.474098 |    789.460332 | Zimices                                                                                                                                                               |
| 364 |     20.106133 |     36.083508 | Jagged Fang Designs                                                                                                                                                   |
| 365 |    143.530568 |    433.128558 | Mette Aumala                                                                                                                                                          |
| 366 |    244.310553 |    461.213534 | NA                                                                                                                                                                    |
| 367 |    913.077392 |    210.848614 | Kamil S. Jaron                                                                                                                                                        |
| 368 |    164.847550 |    696.094220 | Collin Gross                                                                                                                                                          |
| 369 |     61.451602 |    637.981947 | Scott Hartman                                                                                                                                                         |
| 370 |     20.406280 |    566.999021 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 371 |    142.982966 |    671.682548 | C. Camilo Julián-Caballero                                                                                                                                            |
| 372 |   1004.499514 |    587.767125 | Matt Crook                                                                                                                                                            |
| 373 |    898.913780 |    569.414152 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 374 |    827.147448 |    106.726538 | Jagged Fang Designs                                                                                                                                                   |
| 375 |    709.295588 |    139.427706 | Beth Reinke                                                                                                                                                           |
| 376 |    549.655998 |    630.473990 | Ewald Rübsamen                                                                                                                                                        |
| 377 |     87.372511 |    443.953070 | Michael P. Taylor                                                                                                                                                     |
| 378 |    988.575572 |    679.225074 | Christoph Schomburg                                                                                                                                                   |
| 379 |     82.672603 |    765.505261 | Zimices                                                                                                                                                               |
| 380 |    976.206091 |    584.181329 | Scott Hartman                                                                                                                                                         |
| 381 |    688.811515 |    333.954003 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 382 |    101.900354 |     46.336374 | Melissa Broussard                                                                                                                                                     |
| 383 |    529.695611 |    409.960789 | Tasman Dixon                                                                                                                                                          |
| 384 |    381.566993 |    771.208188 | Roberto Díaz Sibaja                                                                                                                                                   |
| 385 |    576.415083 |    693.220741 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 386 |    483.274640 |    543.931693 | Margot Michaud                                                                                                                                                        |
| 387 |    165.016259 |      8.064306 | Chris huh                                                                                                                                                             |
| 388 |    530.396756 |    169.220661 | Matt Crook                                                                                                                                                            |
| 389 |    767.472318 |    698.734374 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 390 |    828.098813 |      8.621317 | Erika Schumacher                                                                                                                                                      |
| 391 |     60.921237 |    713.948839 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 392 |    824.707689 |    478.486738 | T. Michael Keesey                                                                                                                                                     |
| 393 |    386.790017 |    558.090145 | Matt Crook                                                                                                                                                            |
| 394 |    128.411645 |    793.426569 | Shyamal                                                                                                                                                               |
| 395 |    732.794984 |    761.845414 | Margot Michaud                                                                                                                                                        |
| 396 |    589.538362 |    776.877474 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 397 |    307.076944 |      9.962686 | Chris huh                                                                                                                                                             |
| 398 |    468.073151 |     89.431016 | Alex Slavenko                                                                                                                                                         |
| 399 |    170.487456 |    740.284387 | Sarah Werning                                                                                                                                                         |
| 400 |    393.981161 |      7.318779 | Ferran Sayol                                                                                                                                                          |
| 401 |    283.936617 |     73.996076 | Neil Kelley                                                                                                                                                           |
| 402 |     60.146641 |    405.544899 | Scott Hartman                                                                                                                                                         |
| 403 |    770.644918 |    444.567453 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 404 |    482.357950 |    560.502359 | Melissa Broussard                                                                                                                                                     |
| 405 |    468.832741 |    406.684430 | Jagged Fang Designs                                                                                                                                                   |
| 406 |   1005.676107 |    702.079715 | Dmitry Bogdanov                                                                                                                                                       |
| 407 |    495.738157 |    250.341267 | M Kolmann                                                                                                                                                             |
| 408 |     25.978403 |    235.489759 | Julien Louys                                                                                                                                                          |
| 409 |    354.872525 |      7.106194 | NA                                                                                                                                                                    |
| 410 |    732.409150 |    791.610451 | FunkMonk                                                                                                                                                              |
| 411 |    658.117986 |    586.216548 | Margot Michaud                                                                                                                                                        |
| 412 |     81.879956 |    362.307727 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 413 |     72.719154 |     44.261639 | Chris huh                                                                                                                                                             |
| 414 |    550.298435 |    219.404273 | Zimices                                                                                                                                                               |
| 415 |    609.306890 |    339.273103 | T. Michael Keesey                                                                                                                                                     |
| 416 |    444.632846 |    176.259207 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 417 |    751.375695 |    103.376525 | Alex Slavenko                                                                                                                                                         |
| 418 |    587.465033 |    735.357855 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 419 |    554.306498 |     26.153382 | Shyamal                                                                                                                                                               |
| 420 |    350.472208 |    771.356104 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 421 |     61.918423 |     91.388959 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 422 |    762.507526 |    741.714903 | Tony Ayling                                                                                                                                                           |
| 423 |     40.516370 |    443.756685 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 424 |    273.384079 |     27.968357 | David Orr                                                                                                                                                             |
| 425 |     16.694370 |    516.863419 | Scott Hartman                                                                                                                                                         |
| 426 |    807.860968 |    757.600158 | Margot Michaud                                                                                                                                                        |
| 427 |    845.610619 |    619.591679 | Ferran Sayol                                                                                                                                                          |
| 428 |     32.389640 |    586.460168 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 429 |    258.025313 |    513.853592 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 430 |    275.561683 |    789.020984 | NA                                                                                                                                                                    |
| 431 |   1009.085898 |    205.945769 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 432 |    132.790491 |    459.312047 | Chris huh                                                                                                                                                             |
| 433 |    188.560497 |    101.050549 | Roberto Díaz Sibaja                                                                                                                                                   |
| 434 |    559.495378 |    105.884254 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 435 |    331.663009 |     44.867242 | Scott Hartman                                                                                                                                                         |
| 436 |    811.083704 |    416.164488 | Iain Reid                                                                                                                                                             |
| 437 |    523.648554 |    670.906912 | Scott Hartman                                                                                                                                                         |
| 438 |    168.216324 |     58.008469 | Oscar Sanisidro                                                                                                                                                       |
| 439 |    799.970178 |    259.562177 | Dmitry Bogdanov                                                                                                                                                       |
| 440 |    963.583904 |    730.254817 | Yan Wong                                                                                                                                                              |
| 441 |    623.715922 |     35.098744 | Scott Hartman                                                                                                                                                         |
| 442 |    870.128139 |    615.747734 | Jagged Fang Designs                                                                                                                                                   |
| 443 |     16.650957 |    734.456285 | Matt Crook                                                                                                                                                            |
| 444 |    114.532284 |     12.986560 | Mathew Wedel                                                                                                                                                          |
| 445 |    847.190630 |     58.995548 | Lukas Panzarin                                                                                                                                                        |
| 446 |    593.562269 |    210.700308 | T. Michael Keesey                                                                                                                                                     |
| 447 |    862.693082 |    364.661214 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 448 |    288.577426 |    665.878431 | Michele M Tobias                                                                                                                                                      |
| 449 |    628.367311 |    295.263204 | Margot Michaud                                                                                                                                                        |
| 450 |    216.895759 |    535.940223 | Steven Traver                                                                                                                                                         |
| 451 |    311.585078 |    500.166899 | Michael Scroggie                                                                                                                                                      |
| 452 |    785.145424 |     58.533762 | Chris huh                                                                                                                                                             |
| 453 |    733.218495 |    328.777526 | Zimices                                                                                                                                                               |
| 454 |    425.722630 |    769.202318 | Steven Traver                                                                                                                                                         |
| 455 |    827.326437 |    612.904121 | Scott Hartman                                                                                                                                                         |
| 456 |    662.822870 |    306.431903 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 457 |    947.547567 |    791.070556 | John Conway                                                                                                                                                           |
| 458 |    701.399389 |    576.177516 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 459 |    907.387968 |    411.078883 | Markus A. Grohme                                                                                                                                                      |
| 460 |    355.835191 |    141.002738 | Markus A. Grohme                                                                                                                                                      |
| 461 |    522.377103 |     34.317263 | Jagged Fang Designs                                                                                                                                                   |
| 462 |    788.004432 |    464.408061 | FunkMonk                                                                                                                                                              |
| 463 |    663.729841 |    372.409253 | NA                                                                                                                                                                    |
| 464 |    772.774191 |     74.926279 | Chuanixn Yu                                                                                                                                                           |
| 465 |    141.386692 |    167.836764 | Matt Crook                                                                                                                                                            |
| 466 |    646.250175 |    164.886581 | Christoph Schomburg                                                                                                                                                   |
| 467 |   1001.430265 |    795.601631 | NA                                                                                                                                                                    |
| 468 |    242.191076 |    708.787679 | Cathy                                                                                                                                                                 |
| 469 |    825.448989 |    410.652355 | Jagged Fang Designs                                                                                                                                                   |
| 470 |    177.256319 |    794.416220 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 471 |     26.143216 |     56.593458 | Steven Blackwood                                                                                                                                                      |
| 472 |     75.529991 |    228.230910 | Smokeybjb                                                                                                                                                             |
| 473 |    744.331413 |    697.998077 | Matt Crook                                                                                                                                                            |
| 474 |    498.509069 |    290.130844 | Zimices                                                                                                                                                               |
| 475 |    104.793960 |    449.465326 | Ingo Braasch                                                                                                                                                          |
| 476 |    936.078207 |    729.047985 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 477 |    344.296758 |    540.766598 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 478 |    507.794622 |    510.541388 | Markus A. Grohme                                                                                                                                                      |
| 479 |   1003.109311 |    527.764339 | Birgit Lang                                                                                                                                                           |
| 480 |    763.204009 |    577.339637 | NA                                                                                                                                                                    |
| 481 |    537.001570 |    494.253634 | Jiekun He                                                                                                                                                             |
| 482 |    185.675413 |    681.165776 | Birgit Lang                                                                                                                                                           |
| 483 |    704.737338 |    745.243701 | Felix Vaux                                                                                                                                                            |
| 484 |    627.935941 |    133.932614 | xgirouxb                                                                                                                                                              |
| 485 |    853.855083 |    350.037883 | Jaime Headden                                                                                                                                                         |
| 486 |    124.783776 |    638.467280 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 487 |    637.977434 |    206.110361 | Ferran Sayol                                                                                                                                                          |
| 488 |     91.808873 |    189.932810 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 489 |    422.817175 |    525.573701 | Scott Hartman                                                                                                                                                         |
| 490 |    299.488271 |    604.183581 | Harold N Eyster                                                                                                                                                       |
| 491 |      8.921568 |    319.311498 | Christina N. Hodson                                                                                                                                                   |
| 492 |    414.288350 |    413.885029 | Tasman Dixon                                                                                                                                                          |
| 493 |    749.071449 |    543.887758 | Katie S. Collins                                                                                                                                                      |
| 494 |    998.585936 |    344.100717 | NA                                                                                                                                                                    |
| 495 |    652.062637 |    169.952744 | Chris huh                                                                                                                                                             |
| 496 |    986.670207 |    457.740142 | Scott Hartman                                                                                                                                                         |
| 497 |     39.715443 |      6.788433 | Scott Hartman                                                                                                                                                         |
| 498 |    852.315880 |     10.731678 | Andy Wilson                                                                                                                                                           |
| 499 |    910.542173 |    782.390127 | Ferran Sayol                                                                                                                                                          |
| 500 |    214.006757 |    730.752453 | Zimices                                                                                                                                                               |
| 501 |    362.695457 |    689.669296 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 502 |    162.104457 |     18.940278 | T. Michael Keesey                                                                                                                                                     |
| 503 |    657.024902 |    429.644061 | Zimices                                                                                                                                                               |
| 504 |    367.326021 |    648.817748 | Kanako Bessho-Uehara                                                                                                                                                  |
| 505 |   1015.418893 |    342.626406 | Martin R. Smith                                                                                                                                                       |
| 506 |     26.786831 |    670.824445 | Zimices                                                                                                                                                               |
| 507 |    974.236764 |    330.762887 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 508 |    563.655457 |    654.800060 | T. Michael Keesey                                                                                                                                                     |
| 509 |    715.895884 |    477.564514 | Sean McCann                                                                                                                                                           |
| 510 |    847.685174 |    267.847993 | Zimices                                                                                                                                                               |
| 511 |    935.719713 |    521.475337 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 512 |    428.576463 |    650.480073 | Siobhon Egan                                                                                                                                                          |

    #> Your tweet has been posted!
