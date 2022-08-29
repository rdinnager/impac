
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

T. Tischler, Chris huh, Andrew A. Farke, shell lines added by Yan Wong,
Emily Willoughby, Dantheman9758 (vectorized by T. Michael Keesey),
Michael Scroggie, Daniel Stadtmauer, Matt Martyniuk (vectorized by T.
Michael Keesey), Scott Hartman, Pete Buchholz, Yan Wong, Tasman Dixon,
Lukasiniho, Robert Bruce Horsfall, vectorized by Zimices, Gabriela
Palomo-Munoz, Steven Traver, CNZdenek, Margot Michaud, Warren H
(photography), T. Michael Keesey (vectorization), Andy Wilson, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Alexis Simon, T. Michael
Keesey, Gustav Mützel, Gareth Monger, Jagged Fang Designs, NASA, Jessica
Anne Miller, Roberto Díaz Sibaja, Zimices, Darius Nau, Joanna Wolfe,
Ignacio Contreras, Tracy A. Heath, Alexander Schmidt-Lebuhn, Ghedoghedo
(vectorized by T. Michael Keesey), Lafage, Cesar Julian, Mary Harrsch
(modified by T. Michael Keesey), Obsidian Soul (vectorized by T. Michael
Keesey), Birgit Lang, Unknown (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Erika Schumacher, Auckland Museum and
T. Michael Keesey, Ferran Sayol, Iain Reid, Matt Crook, Michael P.
Taylor, Nobu Tamura (vectorized by T. Michael Keesey), Jay Matternes,
vectorized by Zimices, Lily Hughes, Collin Gross, Maija Karala, Rebecca
Groom, Kamil S. Jaron, Tauana J. Cunha, C. Camilo Julián-Caballero, Noah
Schlottman, photo by Martin V. Sørensen, Felix Vaux, Alexandre Vong,
Heinrich Harder (vectorized by William Gearty), Maxime Dahirel, Zachary
Quigley, Jay Matternes (modified by T. Michael Keesey), Christoph
Schomburg, T. Michael Keesey (vectorization); Thorsten Assmann, Jörn
Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea
Matern, Anika Timm, and David W. Wrase (photography), terngirl, Luis
Cunha, Arthur S. Brum, Jake Warner, Verisimilus, Markus A. Grohme, A. R.
McCulloch (vectorized by T. Michael Keesey), Sarah Werning, T. Michael
Keesey (from a mount by Allis Markham), Chris Jennings (vectorized by A.
Verrière), Carlos Cano-Barbacil, Jim Bendon (photography) and T. Michael
Keesey (vectorization), T. Michael Keesey (after Mivart), Matthew E.
Clapham, Josep Marti Solans, Jose Carlos Arenas-Monroy, Melissa
Broussard, Inessa Voet, Yan Wong from illustration by Charles Orbigny,
Sergio A. Muñoz-Gómez, Mathilde Cordellier, T. Michael Keesey (after
Mauricio Antón), Alex Slavenko, Didier Descouens (vectorized by T.
Michael Keesey), Mathieu Basille, L. Shyamal, T. Michael Keesey and
Tanetahi, Stanton F. Fink (vectorized by T. Michael Keesey), Lisa M.
“Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Robbie N. Cada (modified by T. Michael Keesey), Julio
Garza, Caleb M. Brown, Kai R. Caspar, Robert Hering, Owen Jones, Henry
Lydecker, Sharon Wegner-Larsen, xgirouxb, Oren Peles / vectorized by Yan
Wong, C. Abraczinskas, Remes K, Ortega F, Fierro I, Joger U, Kosma R, et
al., M Kolmann, Christopher Laumer (vectorized by T. Michael Keesey),
Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy, Beth
Reinke, Frank Denota, Kanchi Nanjo, Jack Mayer Wood, Juan Carlos Jerí,
Duane Raver/USFWS, Michael Scroggie, from original photograph by Gary M.
Stolz, USFWS (original photograph in public domain)., James R. Spotila
and Ray Chatterji, B Kimmel, Chase Brownstein, Sean McCann, U.S.
National Park Service (vectorized by William Gearty), Philip Chalmers
(vectorized by T. Michael Keesey), Conty (vectorized by T. Michael
Keesey), Ray Simpson (vectorized by T. Michael Keesey), Manabu
Bessho-Uehara, Archaeodontosaurus (vectorized by T. Michael Keesey),
Kristina Gagalova, Javier Luque, Adam Stuart Smith (vectorized by T.
Michael Keesey), Mattia Menchetti, Wayne Decatur, C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), Mathew Wedel, Becky
Barnes, S.Martini, Michael Wolf (photo), Hans Hillewaert (editing), T.
Michael Keesey (vectorization), Michele Tobias, Francesca Belem Lopes
Palmeira, Chloé Schmidt, Ingo Braasch, Terpsichores, Cristopher Silva,
Julia B McHugh, Marie Russell, Michelle Site, T. K. Robinson, Jiekun He,
Evan-Amos (vectorized by T. Michael Keesey), G. M. Woodward, Abraão B.
Leite, Darren Naish, Nemo, and T. Michael Keesey, Kent Elson Sorgon,
Chuanixn Yu, Jakovche, Andrew A. Farke, Mareike C. Janiak, Anthony
Caravaggi, Katie S. Collins, Rafael Maia, Xavier Giroux-Bougard, Dean
Schnabel, Lauren Anderson, Enoch Joseph Wetsy (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Shyamal, Jaime
Headden, Air Kebir NRG, Griensteidl and T. Michael Keesey, T. Michael
Keesey (after Ponomarenko), Agnello Picorelli, FunkMonk, Jon Hill, Tim
H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael
Keesey), T. Michael Keesey (photo by Darren Swim), Mo Hassan, Campbell
Fleming, Mathieu Pélissié, Paul Baker (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Bryan Carstens, Oscar
Sanisidro, Smokeybjb, vectorized by Zimices, Michael B. H. (vectorized
by T. Michael Keesey), Jaime Headden, modified by T. Michael Keesey,
Matt Wilkins, T. Michael Keesey (photo by J. M. Garg), Smokeybjb
(vectorized by T. Michael Keesey), Chris Hay, DW Bapst (Modified from
photograph taken by Charles Mitchell), Dave Angelini, T. Michael Keesey
(after A. Y. Ivantsov), Zimices / Julián Bayona, nicubunu, Renata F.
Martins, Aline M. Ghilardi, Hans Hillewaert, Apokryltaros (vectorized by
T. Michael Keesey), Harold N Eyster, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
wsnaccad, (after Spotila 2004), Noah Schlottman, Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Nobu Tamura (vectorized by
A. Verrière), Original drawing by Nobu Tamura, vectorized by Roberto
Díaz Sibaja, Fernando Carezzano, Pranav Iyer (grey ideas), Neil Kelley,
T. Michael Keesey, from a photograph by Thea Boodhoo, Jerry Oldenettel
(vectorized by T. Michael Keesey), Aviceda (photo) & T. Michael Keesey,
Jimmy Bernot, Pedro de Siracusa, Jaime Chirinos (vectorized by T.
Michael Keesey), Tim Bertelink (modified by T. Michael Keesey), Ramona J
Heim, David Orr, Crystal Maier, Greg Schechter (original photo), Renato
Santos (vector silhouette), Mariana Ruiz Villarreal, Martin R. Smith,
FJDegrange, Giant Blue Anteater (vectorized by T. Michael Keesey),
Bennet McComish, photo by Avenue, Dmitry Bogdanov, Mali’o Kodis,
photograph by P. Funch and R.M. Kristensen, Mali’o Kodis, photograph
from Jersabek et al, 2003, Jonathan Wells, Estelle Bourdon, ДиБгд
(vectorized by T. Michael Keesey), Eduard Solà (vectorized by T. Michael
Keesey), T. Michael Keesey (after Walker & al.), Manabu Sakamoto, Nobu
Tamura, vectorized by Zimices, Courtney Rockenbach, Geoff Shaw, Milton
Tan, Jessica Rick, Steven Blackwood, V. Deepak, Melissa Ingala, Mali’o
Kodis, photograph by G. Giribet, NOAA (vectorized by T. Michael Keesey),
Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Hugo Gruson, Dinah Challen, Lukas Panzarin, Joe Schneid
(vectorized by T. Michael Keesey), Todd Marshall, vectorized by Zimices,
Kailah Thorn & Ben King, Christopher Watson (photo) and T. Michael
Keesey (vectorization), www.studiospectre.com, Ludwik Gąsiorowski, M.
Garfield & K. Anderson (modified by T. Michael Keesey), Nobu Tamura,
Andrew A. Farke, modified from original by H. Milne Edwards, Matt
Martyniuk, T. Michael Keesey (after Colin M. L. Burnett), Mali’o Kodis,
photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>), Noah
Schlottman, photo by Reinhard Jahn, Dave Souza (vectorized by T. Michael
Keesey), Armin Reindl, Meliponicultor Itaymbere, Ricardo Araújo, E. J.
Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael
Keesey), Ian Burt (original) and T. Michael Keesey (vectorization),
Allison Pease, T. Michael Keesey (after Masteraah), Richard Lampitt,
Jeremy Young / NHM (vectorization by Yan Wong), Yan Wong from drawing by
Joseph Smit, Dein Freund der Baum (vectorized by T. Michael Keesey),
Aleksey Nagovitsyn (vectorized by T. Michael Keesey), Keith Murdock
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Haplochromis (vectorized by T. Michael Keesey),
SauropodomorphMonarch

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    240.571039 |    256.208968 | T. Tischler                                                                                                                                                                          |
|   2 |    173.773330 |    392.240039 | Chris huh                                                                                                                                                                            |
|   3 |    169.991430 |    504.848227 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
|   4 |    806.672255 |    227.421715 | Emily Willoughby                                                                                                                                                                     |
|   5 |    625.742714 |    282.293890 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                                      |
|   6 |    872.517367 |    387.741659 | NA                                                                                                                                                                                   |
|   7 |    635.327608 |    146.002739 | Michael Scroggie                                                                                                                                                                     |
|   8 |    424.922118 |    136.267448 | Daniel Stadtmauer                                                                                                                                                                    |
|   9 |    947.090399 |    460.589257 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
|  10 |    851.392156 |    534.912047 | Scott Hartman                                                                                                                                                                        |
|  11 |    781.921969 |    120.045336 | Pete Buchholz                                                                                                                                                                        |
|  12 |    666.456365 |    705.930987 | Yan Wong                                                                                                                                                                             |
|  13 |    490.991846 |    605.102946 | Tasman Dixon                                                                                                                                                                         |
|  14 |     91.830322 |    301.438245 | Lukasiniho                                                                                                                                                                           |
|  15 |    162.367099 |    675.294011 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
|  16 |    302.014881 |    590.005022 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  17 |    811.602379 |    343.792878 | Steven Traver                                                                                                                                                                        |
|  18 |    680.594290 |    509.277303 | CNZdenek                                                                                                                                                                             |
|  19 |    402.659909 |    452.886398 | Margot Michaud                                                                                                                                                                       |
|  20 |     61.027318 |    399.936976 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                                            |
|  21 |    453.834907 |    262.435669 | Andy Wilson                                                                                                                                                                          |
|  22 |    554.719527 |    396.367294 | Tasman Dixon                                                                                                                                                                         |
|  23 |    536.043686 |     68.207958 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  24 |     38.400620 |    511.491561 | Alexis Simon                                                                                                                                                                         |
|  25 |    325.165679 |    328.431648 | T. Michael Keesey                                                                                                                                                                    |
|  26 |    130.669291 |    177.500762 | Gustav Mützel                                                                                                                                                                        |
|  27 |    949.046354 |    221.905104 | Gareth Monger                                                                                                                                                                        |
|  28 |    172.891564 |    104.298372 | NA                                                                                                                                                                                   |
|  29 |    129.762168 |    609.709453 | Jagged Fang Designs                                                                                                                                                                  |
|  30 |    804.721383 |    643.892567 | NASA                                                                                                                                                                                 |
|  31 |    267.939835 |    148.307946 | Jessica Anne Miller                                                                                                                                                                  |
|  32 |    424.611454 |    381.713121 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  33 |    909.731718 |    726.509898 | Zimices                                                                                                                                                                              |
|  34 |    438.164243 |    184.258552 | Darius Nau                                                                                                                                                                           |
|  35 |    316.482397 |    763.304297 | Scott Hartman                                                                                                                                                                        |
|  36 |    355.587710 |    717.061165 | Joanna Wolfe                                                                                                                                                                         |
|  37 |    893.269311 |     32.335646 | Ignacio Contreras                                                                                                                                                                    |
|  38 |    723.145176 |    405.851435 | Tracy A. Heath                                                                                                                                                                       |
|  39 |     29.191970 |    157.509762 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  40 |    485.940697 |    335.318006 | Tasman Dixon                                                                                                                                                                         |
|  41 |    769.583042 |     66.803041 | T. Michael Keesey                                                                                                                                                                    |
|  42 |    683.460232 |    599.415625 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
|  43 |    299.152830 |    514.192527 | Lafage                                                                                                                                                                               |
|  44 |    940.688389 |     94.739278 | Cesar Julian                                                                                                                                                                         |
|  45 |    580.410737 |     23.061545 | Scott Hartman                                                                                                                                                                        |
|  46 |    103.927648 |     33.945588 | Scott Hartman                                                                                                                                                                        |
|  47 |    884.787827 |    482.120893 | Gareth Monger                                                                                                                                                                        |
|  48 |    486.226614 |    555.297213 | NA                                                                                                                                                                                   |
|  49 |    963.678536 |    572.020333 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                         |
|  50 |    196.688966 |    313.070007 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
|  51 |    539.958375 |    475.128783 | Birgit Lang                                                                                                                                                                          |
|  52 |    361.458732 |     19.390377 | Steven Traver                                                                                                                                                                        |
|  53 |    508.978267 |    733.556541 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
|  54 |    254.278083 |    433.250872 | Erika Schumacher                                                                                                                                                                     |
|  55 |    332.179430 |    668.959452 | Cesar Julian                                                                                                                                                                         |
|  56 |    243.984496 |     39.034413 | Auckland Museum and T. Michael Keesey                                                                                                                                                |
|  57 |    968.311389 |    311.618860 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  58 |    332.485736 |     68.451394 | Gareth Monger                                                                                                                                                                        |
|  59 |    404.076054 |    574.916703 | Margot Michaud                                                                                                                                                                       |
|  60 |    914.136577 |    648.688423 | Ferran Sayol                                                                                                                                                                         |
|  61 |    835.697789 |    499.327700 | Emily Willoughby                                                                                                                                                                     |
|  62 |    107.693340 |    137.153867 | Iain Reid                                                                                                                                                                            |
|  63 |    866.095063 |    145.328055 | Steven Traver                                                                                                                                                                        |
|  64 |    120.444438 |    770.686214 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  65 |    166.897850 |    557.906150 | Gareth Monger                                                                                                                                                                        |
|  66 |    216.552793 |    735.494946 | Matt Crook                                                                                                                                                                           |
|  67 |    240.903070 |    354.761069 | Michael P. Taylor                                                                                                                                                                    |
|  68 |    517.619384 |    444.125287 | Scott Hartman                                                                                                                                                                        |
|  69 |    796.323612 |    285.494268 | Margot Michaud                                                                                                                                                                       |
|  70 |    635.140602 |    365.129399 | Zimices                                                                                                                                                                              |
|  71 |     62.585453 |    592.794139 | Scott Hartman                                                                                                                                                                        |
|  72 |     90.439779 |    513.843858 | Yan Wong                                                                                                                                                                             |
|  73 |    304.023250 |    371.952994 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  74 |    809.954924 |    770.209412 | Jay Matternes, vectorized by Zimices                                                                                                                                                 |
|  75 |    131.723504 |    249.777123 | Gareth Monger                                                                                                                                                                        |
|  76 |    553.664154 |    566.398773 | Zimices                                                                                                                                                                              |
|  77 |    401.372729 |    756.258806 | Matt Crook                                                                                                                                                                           |
|  78 |    775.968516 |    546.183818 | Lily Hughes                                                                                                                                                                          |
|  79 |    325.664812 |    207.601404 | Collin Gross                                                                                                                                                                         |
|  80 |     19.229592 |     97.115319 | Maija Karala                                                                                                                                                                         |
|  81 |    819.187841 |    428.825437 | Margot Michaud                                                                                                                                                                       |
|  82 |    622.775968 |     37.544667 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  83 |    333.138339 |    626.861591 | Scott Hartman                                                                                                                                                                        |
|  84 |     25.149741 |    754.567604 | Rebecca Groom                                                                                                                                                                        |
|  85 |    924.803015 |    786.670818 | Joanna Wolfe                                                                                                                                                                         |
|  86 |     60.728165 |    179.352819 | Kamil S. Jaron                                                                                                                                                                       |
|  87 |    131.779943 |    440.679367 | Matt Crook                                                                                                                                                                           |
|  88 |    329.144126 |    701.696722 | Rebecca Groom                                                                                                                                                                        |
|  89 |    905.916347 |    468.390741 | Tauana J. Cunha                                                                                                                                                                      |
|  90 |   1004.878015 |    311.195396 | Margot Michaud                                                                                                                                                                       |
|  91 |     47.618887 |    667.911910 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  92 |   1004.102488 |    621.373995 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
|  93 |    974.124218 |    690.922065 | Felix Vaux                                                                                                                                                                           |
|  94 |    844.525331 |    423.451478 | Alexandre Vong                                                                                                                                                                       |
|  95 |    342.976764 |    188.478068 | Heinrich Harder (vectorized by William Gearty)                                                                                                                                       |
|  96 |     20.154195 |    290.841000 | Maxime Dahirel                                                                                                                                                                       |
|  97 |    742.910773 |    310.124265 | Zachary Quigley                                                                                                                                                                      |
|  98 |    995.259976 |     25.051337 | Steven Traver                                                                                                                                                                        |
|  99 |    622.006621 |    529.336010 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                                        |
| 100 |    555.608510 |    686.777343 | Christoph Schomburg                                                                                                                                                                  |
| 101 |    390.785269 |    773.176582 | Joanna Wolfe                                                                                                                                                                         |
| 102 |    589.759556 |    580.284242 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 103 |    550.767656 |    279.134462 | Andy Wilson                                                                                                                                                                          |
| 104 |    594.238511 |    542.792679 | terngirl                                                                                                                                                                             |
| 105 |    330.361572 |    114.077342 | Erika Schumacher                                                                                                                                                                     |
| 106 |    961.934448 |    138.691877 | NA                                                                                                                                                                                   |
| 107 |    912.884519 |    298.467484 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 108 |    714.651600 |    783.907434 | CNZdenek                                                                                                                                                                             |
| 109 |    831.835045 |    718.660648 | Erika Schumacher                                                                                                                                                                     |
| 110 |    559.768063 |    641.235329 | NA                                                                                                                                                                                   |
| 111 |    463.457937 |     25.949257 | Tracy A. Heath                                                                                                                                                                       |
| 112 |    710.953044 |     17.475791 | Luis Cunha                                                                                                                                                                           |
| 113 |    986.622032 |    121.300784 | Jagged Fang Designs                                                                                                                                                                  |
| 114 |    236.492053 |    174.103831 | Gareth Monger                                                                                                                                                                        |
| 115 |    362.756454 |    234.575285 | Arthur S. Brum                                                                                                                                                                       |
| 116 |    974.219693 |    735.175056 | Zimices                                                                                                                                                                              |
| 117 |    414.037947 |     85.363931 | Jake Warner                                                                                                                                                                          |
| 118 |    567.789944 |    525.027744 | Verisimilus                                                                                                                                                                          |
| 119 |    547.673647 |    501.921373 | Jagged Fang Designs                                                                                                                                                                  |
| 120 |    338.471183 |    101.251202 | Markus A. Grohme                                                                                                                                                                     |
| 121 |    432.662942 |    688.882532 | Felix Vaux                                                                                                                                                                           |
| 122 |    872.823910 |    273.410383 | Gareth Monger                                                                                                                                                                        |
| 123 |    795.074728 |    403.053445 | Chris huh                                                                                                                                                                            |
| 124 |    250.682603 |    221.390383 | Erika Schumacher                                                                                                                                                                     |
| 125 |    244.239315 |    789.218589 | Jagged Fang Designs                                                                                                                                                                  |
| 126 |     96.100485 |     87.029748 | Ferran Sayol                                                                                                                                                                         |
| 127 |   1005.909647 |    645.241825 | Tasman Dixon                                                                                                                                                                         |
| 128 |    491.009639 |    416.868566 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                                    |
| 129 |    750.478026 |     28.186310 | Andy Wilson                                                                                                                                                                          |
| 130 |    556.756198 |    372.831406 | Gareth Monger                                                                                                                                                                        |
| 131 |    414.166171 |    636.789535 | Margot Michaud                                                                                                                                                                       |
| 132 |    420.011482 |    532.404272 | Yan Wong                                                                                                                                                                             |
| 133 |    520.976098 |    554.078854 | Sarah Werning                                                                                                                                                                        |
| 134 |    233.818827 |    474.718294 | Zimices                                                                                                                                                                              |
| 135 |   1008.457466 |    135.944770 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 136 |    268.983775 |    306.862715 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                                    |
| 137 |    754.045885 |    433.398971 | Chris Jennings (vectorized by A. Verrière)                                                                                                                                           |
| 138 |    123.198543 |      5.649746 | NA                                                                                                                                                                                   |
| 139 |     63.277437 |    619.672464 | Gareth Monger                                                                                                                                                                        |
| 140 |    370.430323 |    188.794645 | Emily Willoughby                                                                                                                                                                     |
| 141 |    965.363176 |    527.749363 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 142 |    198.248183 |    215.620275 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 143 |    285.100457 |    203.365574 | T. Michael Keesey                                                                                                                                                                    |
| 144 |    450.630059 |     96.490513 | Jagged Fang Designs                                                                                                                                                                  |
| 145 |    868.290518 |    573.085919 | Margot Michaud                                                                                                                                                                       |
| 146 |    253.779293 |    744.840855 | Michael P. Taylor                                                                                                                                                                    |
| 147 |    541.472289 |    545.919951 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 148 |    444.950408 |    419.863553 | T. Michael Keesey (after Mivart)                                                                                                                                                     |
| 149 |    912.811229 |    382.500072 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 150 |    990.260616 |    705.687250 | Joanna Wolfe                                                                                                                                                                         |
| 151 |    838.653034 |    571.625215 | Joanna Wolfe                                                                                                                                                                         |
| 152 |    334.538390 |    449.755395 | Matthew E. Clapham                                                                                                                                                                   |
| 153 |    146.628289 |    196.622782 | Josep Marti Solans                                                                                                                                                                   |
| 154 |    129.653983 |    315.671855 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 155 |    545.394542 |    133.713242 | Ferran Sayol                                                                                                                                                                         |
| 156 |    992.140789 |    721.427853 | Melissa Broussard                                                                                                                                                                    |
| 157 |    163.529344 |    222.178329 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 158 |    437.549202 |    725.599088 | Gareth Monger                                                                                                                                                                        |
| 159 |    598.716349 |    624.899497 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 160 |    783.191709 |     28.629289 | Gareth Monger                                                                                                                                                                        |
| 161 |    881.186598 |    582.616556 | Melissa Broussard                                                                                                                                                                    |
| 162 |    484.694638 |    459.261872 | Inessa Voet                                                                                                                                                                          |
| 163 |     63.029591 |    782.200353 | Yan Wong from illustration by Charles Orbigny                                                                                                                                        |
| 164 |    955.091025 |    759.349291 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 165 |    991.960424 |    373.847979 | Matt Crook                                                                                                                                                                           |
| 166 |    881.098062 |    791.167559 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 167 |    403.544401 |    317.170794 | Jagged Fang Designs                                                                                                                                                                  |
| 168 |    852.940081 |    739.061157 | Mathilde Cordellier                                                                                                                                                                  |
| 169 |    458.384522 |    164.192036 | T. Michael Keesey (after Mauricio Antón)                                                                                                                                             |
| 170 |    939.914352 |    394.303242 | Kamil S. Jaron                                                                                                                                                                       |
| 171 |    629.529147 |    571.206158 | Alex Slavenko                                                                                                                                                                        |
| 172 |    800.955469 |    577.518966 | Gareth Monger                                                                                                                                                                        |
| 173 |    408.727447 |    222.518356 | Birgit Lang                                                                                                                                                                          |
| 174 |    400.885525 |    266.776354 | Steven Traver                                                                                                                                                                        |
| 175 |    436.330044 |    557.151667 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 176 |    579.493859 |    598.954793 | Mathieu Basille                                                                                                                                                                      |
| 177 |    295.792456 |    121.165989 | L. Shyamal                                                                                                                                                                           |
| 178 |    540.368691 |    107.611092 | Emily Willoughby                                                                                                                                                                     |
| 179 |    857.985954 |    295.871563 | T. Michael Keesey and Tanetahi                                                                                                                                                       |
| 180 |    814.694780 |     19.206251 | NA                                                                                                                                                                                   |
| 181 |    261.159066 |    732.041282 | Markus A. Grohme                                                                                                                                                                     |
| 182 |    534.098086 |    716.457690 | NA                                                                                                                                                                                   |
| 183 |     40.909263 |    653.467351 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 184 |    175.865863 |    420.794339 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                      |
| 185 |    715.008287 |    549.056025 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 186 |    561.773492 |    328.194120 | Julio Garza                                                                                                                                                                          |
| 187 |     73.423268 |    154.849051 | Jagged Fang Designs                                                                                                                                                                  |
| 188 |    142.168277 |    218.921798 | Caleb M. Brown                                                                                                                                                                       |
| 189 |    229.901506 |     87.180687 | Alexandre Vong                                                                                                                                                                       |
| 190 |    386.312476 |    508.724803 | Chris huh                                                                                                                                                                            |
| 191 |    318.775135 |    408.685743 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 192 |    691.291125 |    425.095419 | Kai R. Caspar                                                                                                                                                                        |
| 193 |    166.932071 |    274.772040 | T. Michael Keesey                                                                                                                                                                    |
| 194 |    872.619334 |     13.900991 | NA                                                                                                                                                                                   |
| 195 |    815.569623 |    173.538803 | Robert Hering                                                                                                                                                                        |
| 196 |    358.459454 |    649.288368 | Owen Jones                                                                                                                                                                           |
| 197 |    441.871253 |     16.174793 | Henry Lydecker                                                                                                                                                                       |
| 198 |     19.912994 |    647.926263 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 199 |     54.363781 |     70.142006 | Steven Traver                                                                                                                                                                        |
| 200 |    641.189291 |    454.721897 | xgirouxb                                                                                                                                                                             |
| 201 |    827.807453 |    575.390421 | Oren Peles / vectorized by Yan Wong                                                                                                                                                  |
| 202 |    996.848456 |    529.502119 | Zimices                                                                                                                                                                              |
| 203 |    742.798284 |    774.520260 | Michael Scroggie                                                                                                                                                                     |
| 204 |    147.252147 |    210.500028 | C. Abraczinskas                                                                                                                                                                      |
| 205 |    894.646506 |    758.196581 | Alexandre Vong                                                                                                                                                                       |
| 206 |    439.539840 |    344.111880 | Scott Hartman                                                                                                                                                                        |
| 207 |    867.917268 |     74.197851 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                                |
| 208 |    964.971995 |    781.797966 | M Kolmann                                                                                                                                                                            |
| 209 |    365.739778 |    359.523295 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                                 |
| 210 |    699.150991 |     83.240440 | Steven Traver                                                                                                                                                                        |
| 211 |    806.411269 |    683.249654 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                                       |
| 212 |    285.895542 |    406.477801 | Markus A. Grohme                                                                                                                                                                     |
| 213 |     17.028465 |    155.142957 | Beth Reinke                                                                                                                                                                          |
| 214 |    870.980018 |    184.400019 | Sarah Werning                                                                                                                                                                        |
| 215 |    667.167370 |    532.202716 | Frank Denota                                                                                                                                                                         |
| 216 |    651.728320 |    432.208092 | Steven Traver                                                                                                                                                                        |
| 217 |    751.835351 |    584.336568 | Chris huh                                                                                                                                                                            |
| 218 |    509.194357 |    213.891517 | Kanchi Nanjo                                                                                                                                                                         |
| 219 |    698.049061 |     28.928382 | Jack Mayer Wood                                                                                                                                                                      |
| 220 |    995.886577 |    154.530958 | Gareth Monger                                                                                                                                                                        |
| 221 |    207.412700 |    173.331330 | NA                                                                                                                                                                                   |
| 222 |    270.443852 |    746.788099 | Juan Carlos Jerí                                                                                                                                                                     |
| 223 |    849.574222 |    476.554177 | Jagged Fang Designs                                                                                                                                                                  |
| 224 |    185.831565 |    599.593645 | Mathilde Cordellier                                                                                                                                                                  |
| 225 |    973.354420 |    252.575348 | Steven Traver                                                                                                                                                                        |
| 226 |    663.648479 |     68.520995 | Duane Raver/USFWS                                                                                                                                                                    |
| 227 |    713.966785 |    115.780135 | Andy Wilson                                                                                                                                                                          |
| 228 |    780.463280 |    782.684305 | Gareth Monger                                                                                                                                                                        |
| 229 |     95.300289 |    241.317233 | Margot Michaud                                                                                                                                                                       |
| 230 |    938.642430 |     67.036430 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                           |
| 231 |    943.926786 |    604.213538 | Ferran Sayol                                                                                                                                                                         |
| 232 |    244.625803 |    585.317621 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 233 |    726.699015 |    167.068267 | Jake Warner                                                                                                                                                                          |
| 234 |    314.160125 |    639.535503 | Jagged Fang Designs                                                                                                                                                                  |
| 235 |    275.972746 |    472.745087 | Yan Wong                                                                                                                                                                             |
| 236 |    570.766871 |    201.615030 | T. Michael Keesey                                                                                                                                                                    |
| 237 |     86.823516 |    254.103792 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 238 |    534.517661 |    189.887931 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 239 |    833.402520 |     42.305141 | T. Michael Keesey                                                                                                                                                                    |
| 240 |    367.712126 |     92.128907 | B Kimmel                                                                                                                                                                             |
| 241 |    429.313801 |     98.830116 | Gareth Monger                                                                                                                                                                        |
| 242 |    143.227625 |    284.849317 | NA                                                                                                                                                                                   |
| 243 |    599.299879 |    434.821740 | NA                                                                                                                                                                                   |
| 244 |    771.036968 |    413.495276 | Steven Traver                                                                                                                                                                        |
| 245 |   1002.662618 |    509.019832 | Chase Brownstein                                                                                                                                                                     |
| 246 |    460.160061 |    563.970375 | Sean McCann                                                                                                                                                                          |
| 247 |    906.261913 |    603.531867 | U.S. National Park Service (vectorized by William Gearty)                                                                                                                            |
| 248 |    521.494780 |    596.301903 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 249 |    615.965514 |    406.868191 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
| 250 |    996.495670 |    404.905861 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 251 |    594.519804 |    450.087528 | Zimices                                                                                                                                                                              |
| 252 |    355.427437 |    162.671225 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                        |
| 253 |    784.912485 |     15.051817 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 254 |     14.677327 |    131.742190 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 255 |    155.276752 |    425.105481 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                                 |
| 256 |    295.326386 |    698.918972 | Matt Crook                                                                                                                                                                           |
| 257 |    595.939243 |      7.556750 | Ferran Sayol                                                                                                                                                                         |
| 258 |    970.686027 |     61.410298 | Kristina Gagalova                                                                                                                                                                    |
| 259 |    300.626246 |    220.162294 | Javier Luque                                                                                                                                                                         |
| 260 |    806.877589 |    307.552320 | NA                                                                                                                                                                                   |
| 261 |     72.678120 |    103.551313 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                                  |
| 262 |    169.940160 |     49.342523 | Zimices                                                                                                                                                                              |
| 263 |     52.750217 |    149.258916 | Margot Michaud                                                                                                                                                                       |
| 264 |    917.218854 |    688.686668 | Chris huh                                                                                                                                                                            |
| 265 |    909.158155 |    583.097019 | Jagged Fang Designs                                                                                                                                                                  |
| 266 |    528.556556 |    281.913056 | T. Michael Keesey                                                                                                                                                                    |
| 267 |     56.916210 |    220.427820 | CNZdenek                                                                                                                                                                             |
| 268 |    687.862872 |     60.194558 | Mattia Menchetti                                                                                                                                                                     |
| 269 |    565.196122 |    537.394276 | Wayne Decatur                                                                                                                                                                        |
| 270 |    212.956007 |     55.765329 | Matt Crook                                                                                                                                                                           |
| 271 |    667.918472 |    321.052325 | Ferran Sayol                                                                                                                                                                         |
| 272 |    125.233370 |     79.427439 | NASA                                                                                                                                                                                 |
| 273 |    430.219877 |    729.688409 | Margot Michaud                                                                                                                                                                       |
| 274 |    124.352274 |    333.171750 | Ferran Sayol                                                                                                                                                                         |
| 275 |    837.808430 |     53.394148 | Zimices                                                                                                                                                                              |
| 276 |    640.493726 |    780.680306 | NA                                                                                                                                                                                   |
| 277 |    342.261365 |    436.627949 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 278 |    848.911301 |    494.087005 | Beth Reinke                                                                                                                                                                          |
| 279 |     14.803125 |    624.304553 | Margot Michaud                                                                                                                                                                       |
| 280 |    154.673322 |    529.734997 | Zimices                                                                                                                                                                              |
| 281 |    785.863889 |    471.250925 | Margot Michaud                                                                                                                                                                       |
| 282 |    327.076031 |    486.396095 | Scott Hartman                                                                                                                                                                        |
| 283 |    236.668663 |    761.353702 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                        |
| 284 |    694.900348 |    344.987092 | Mathew Wedel                                                                                                                                                                         |
| 285 |    550.203276 |    743.603382 | Becky Barnes                                                                                                                                                                         |
| 286 |    455.617815 |    473.833833 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 287 |    923.665488 |    590.486456 | S.Martini                                                                                                                                                                            |
| 288 |     59.159387 |     45.502325 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 289 |    884.144788 |    318.041238 | Birgit Lang                                                                                                                                                                          |
| 290 |     67.069629 |    204.202558 | Michele Tobias                                                                                                                                                                       |
| 291 |    862.519503 |    675.117713 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 292 |    554.992139 |    115.201635 | Francesca Belem Lopes Palmeira                                                                                                                                                       |
| 293 |    803.611337 |    728.301273 | Matt Crook                                                                                                                                                                           |
| 294 |    142.233256 |    298.934775 | Chris huh                                                                                                                                                                            |
| 295 |    473.011305 |    195.827532 | Scott Hartman                                                                                                                                                                        |
| 296 |    877.019958 |    553.287833 | NA                                                                                                                                                                                   |
| 297 |    357.085889 |    123.995064 | Birgit Lang                                                                                                                                                                          |
| 298 |    470.680619 |    770.262701 | Margot Michaud                                                                                                                                                                       |
| 299 |    228.664734 |    203.358434 | Chloé Schmidt                                                                                                                                                                        |
| 300 |    445.981178 |    210.096554 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 301 |    425.900027 |    487.812735 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 302 |    667.614381 |     18.115150 | NA                                                                                                                                                                                   |
| 303 |    419.258834 |     62.767609 | Ferran Sayol                                                                                                                                                                         |
| 304 |    292.412893 |    546.821513 | Ingo Braasch                                                                                                                                                                         |
| 305 |    496.531793 |     84.629438 | Terpsichores                                                                                                                                                                         |
| 306 |    653.765153 |     80.913325 | Cristopher Silva                                                                                                                                                                     |
| 307 |    930.477289 |    745.899828 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 308 |    996.181264 |    222.643231 | Julia B McHugh                                                                                                                                                                       |
| 309 |    866.964167 |    722.217722 | Erika Schumacher                                                                                                                                                                     |
| 310 |    644.999754 |    400.594893 | Zimices                                                                                                                                                                              |
| 311 |     81.260358 |    745.420819 | Iain Reid                                                                                                                                                                            |
| 312 |    146.927227 |    717.563241 | Maxime Dahirel                                                                                                                                                                       |
| 313 |    580.584916 |    336.896656 | Marie Russell                                                                                                                                                                        |
| 314 |    790.761824 |    163.641942 | Michelle Site                                                                                                                                                                        |
| 315 |     41.026133 |     42.844823 | Joanna Wolfe                                                                                                                                                                         |
| 316 |    757.878687 |    183.353123 | Emily Willoughby                                                                                                                                                                     |
| 317 |    974.358092 |    614.809170 | Felix Vaux                                                                                                                                                                           |
| 318 |   1007.175564 |    350.548186 | T. K. Robinson                                                                                                                                                                       |
| 319 |    947.768469 |    229.676038 | Felix Vaux                                                                                                                                                                           |
| 320 |    535.241147 |    294.508971 | T. Michael Keesey                                                                                                                                                                    |
| 321 |    373.283824 |    493.203055 | Zimices                                                                                                                                                                              |
| 322 |    767.583840 |    384.168728 | Jiekun He                                                                                                                                                                            |
| 323 |    504.324506 |     30.844229 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                                          |
| 324 |    318.097470 |    248.264927 | L. Shyamal                                                                                                                                                                           |
| 325 |    960.429003 |    705.289015 | Tracy A. Heath                                                                                                                                                                       |
| 326 |    783.178273 |    380.932267 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 327 |    566.788259 |    270.047511 | G. M. Woodward                                                                                                                                                                       |
| 328 |    511.183190 |    680.660452 | Tauana J. Cunha                                                                                                                                                                      |
| 329 |     16.734606 |     80.229025 | Jagged Fang Designs                                                                                                                                                                  |
| 330 |    722.113584 |     85.415360 | Abraão B. Leite                                                                                                                                                                      |
| 331 |    456.819558 |    712.374995 | Chris huh                                                                                                                                                                            |
| 332 |    654.554770 |    513.183930 | Gareth Monger                                                                                                                                                                        |
| 333 |    283.387782 |    462.818694 | Mattia Menchetti                                                                                                                                                                     |
| 334 |    430.959318 |    748.374437 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                                            |
| 335 |    788.092210 |    394.194602 | Kent Elson Sorgon                                                                                                                                                                    |
| 336 |     56.471672 |    556.034155 | Chris huh                                                                                                                                                                            |
| 337 |    403.372466 |    547.253918 | Chuanixn Yu                                                                                                                                                                          |
| 338 |    141.868180 |    272.577055 | Ingo Braasch                                                                                                                                                                         |
| 339 |    114.090828 |    224.083978 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 340 |    329.104428 |    465.721835 | Juan Carlos Jerí                                                                                                                                                                     |
| 341 |    692.457690 |    449.627735 | Jakovche                                                                                                                                                                             |
| 342 |    541.928200 |    126.714368 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 343 |    315.999202 |    617.136941 | Andrew A. Farke                                                                                                                                                                      |
| 344 |    123.394263 |    416.674400 | Andy Wilson                                                                                                                                                                          |
| 345 |    829.906292 |     87.899017 | Iain Reid                                                                                                                                                                            |
| 346 |    247.798094 |    507.798121 | Felix Vaux                                                                                                                                                                           |
| 347 |    535.884306 |    686.325039 | Mareike C. Janiak                                                                                                                                                                    |
| 348 |    335.366396 |    238.044274 | Zimices                                                                                                                                                                              |
| 349 |    404.432159 |    473.844662 | L. Shyamal                                                                                                                                                                           |
| 350 |    255.099918 |    320.242966 | Zimices                                                                                                                                                                              |
| 351 |    787.352955 |    571.762451 | Matt Crook                                                                                                                                                                           |
| 352 |    411.435893 |    253.103680 | Scott Hartman                                                                                                                                                                        |
| 353 |     39.347725 |    723.502330 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 354 |    106.489224 |    499.527850 | T. Michael Keesey                                                                                                                                                                    |
| 355 |    217.009392 |    115.257145 | Ferran Sayol                                                                                                                                                                         |
| 356 |    242.108748 |    550.867626 | NA                                                                                                                                                                                   |
| 357 |    148.024190 |    729.512164 | Julio Garza                                                                                                                                                                          |
| 358 |    322.515034 |    546.462568 | Matt Crook                                                                                                                                                                           |
| 359 |    994.869469 |    732.620966 | Mathieu Basille                                                                                                                                                                      |
| 360 |    484.734947 |    104.681570 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 361 |    619.674858 |    513.194384 | Anthony Caravaggi                                                                                                                                                                    |
| 362 |   1010.784495 |    284.977047 | Pete Buchholz                                                                                                                                                                        |
| 363 |    930.952887 |    483.333913 | Katie S. Collins                                                                                                                                                                     |
| 364 |    523.521444 |    695.417576 | Matt Crook                                                                                                                                                                           |
| 365 |    531.421519 |    260.085193 | T. Michael Keesey                                                                                                                                                                    |
| 366 |    382.064531 |    628.972196 | Andrew A. Farke                                                                                                                                                                      |
| 367 |    339.913312 |    296.195532 | Jagged Fang Designs                                                                                                                                                                  |
| 368 |    997.913983 |    246.544255 | T. Michael Keesey                                                                                                                                                                    |
| 369 |    245.685167 |     70.725409 | Rafael Maia                                                                                                                                                                          |
| 370 |    903.710951 |    171.267629 | Caleb M. Brown                                                                                                                                                                       |
| 371 |    856.275399 |    751.377843 | Margot Michaud                                                                                                                                                                       |
| 372 |    337.153741 |    404.972005 | NA                                                                                                                                                                                   |
| 373 |     44.946617 |    682.215733 | T. Michael Keesey                                                                                                                                                                    |
| 374 |    800.596454 |    481.006858 | Scott Hartman                                                                                                                                                                        |
| 375 |    535.078819 |    554.214434 | Xavier Giroux-Bougard                                                                                                                                                                |
| 376 |    256.068647 |    616.714836 | Matt Crook                                                                                                                                                                           |
| 377 |    220.853602 |    796.891626 | CNZdenek                                                                                                                                                                             |
| 378 |    919.486748 |    396.165909 | Zimices                                                                                                                                                                              |
| 379 |     76.409877 |    334.747820 | Matt Crook                                                                                                                                                                           |
| 380 |    535.433880 |    658.799353 | Chase Brownstein                                                                                                                                                                     |
| 381 |    526.647305 |    161.527863 | Matt Crook                                                                                                                                                                           |
| 382 |    357.189040 |    201.843999 | Birgit Lang                                                                                                                                                                          |
| 383 |    318.961130 |    778.154846 | Andy Wilson                                                                                                                                                                          |
| 384 |    161.833923 |    250.509278 | Dean Schnabel                                                                                                                                                                        |
| 385 |     15.211553 |    320.182527 | Scott Hartman                                                                                                                                                                        |
| 386 |    333.389685 |    275.975505 | Chris huh                                                                                                                                                                            |
| 387 |    772.294603 |    148.947903 | Scott Hartman                                                                                                                                                                        |
| 388 |    391.322411 |    791.167621 | Markus A. Grohme                                                                                                                                                                     |
| 389 |    938.576333 |    366.801547 | Rebecca Groom                                                                                                                                                                        |
| 390 |    787.704149 |    708.903265 | Steven Traver                                                                                                                                                                        |
| 391 |    355.874293 |    284.289969 | Margot Michaud                                                                                                                                                                       |
| 392 |   1010.208672 |    419.055343 | NA                                                                                                                                                                                   |
| 393 |    764.446853 |    167.924224 | Birgit Lang                                                                                                                                                                          |
| 394 |    379.921945 |    289.167982 | Lauren Anderson                                                                                                                                                                      |
| 395 |    166.172522 |    430.230410 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 396 |    590.978825 |    212.936333 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 397 |    753.420920 |    161.515078 | Birgit Lang                                                                                                                                                                          |
| 398 |    222.083821 |    753.702359 | Inessa Voet                                                                                                                                                                          |
| 399 |    678.129254 |    473.671591 | Shyamal                                                                                                                                                                              |
| 400 |      8.534531 |    395.960301 | Mathew Wedel                                                                                                                                                                         |
| 401 |    419.772973 |    103.002982 | Zimices                                                                                                                                                                              |
| 402 |    916.275896 |     16.861912 | Jaime Headden                                                                                                                                                                        |
| 403 |    958.337724 |    721.572474 | Zimices                                                                                                                                                                              |
| 404 |    573.743291 |    789.271799 | Matt Crook                                                                                                                                                                           |
| 405 |    295.176758 |    522.668584 | Dean Schnabel                                                                                                                                                                        |
| 406 |    434.030870 |    789.809700 | Air Kebir NRG                                                                                                                                                                        |
| 407 |    510.417940 |    563.494533 | Margot Michaud                                                                                                                                                                       |
| 408 |    365.517572 |     38.552585 | Emily Willoughby                                                                                                                                                                     |
| 409 |    689.852728 |    236.414442 | Zimices                                                                                                                                                                              |
| 410 |    857.849377 |    776.423501 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 411 |    147.864410 |    358.588456 | NA                                                                                                                                                                                   |
| 412 |    922.674338 |    424.948227 | Yan Wong                                                                                                                                                                             |
| 413 |    222.110356 |    603.092430 | Steven Traver                                                                                                                                                                        |
| 414 |    336.911501 |    621.376286 | Cesar Julian                                                                                                                                                                         |
| 415 |    811.198957 |    131.802827 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 416 |    633.958938 |    498.298722 | T. Michael Keesey (after Ponomarenko)                                                                                                                                                |
| 417 |    638.721766 |    214.058664 | Birgit Lang                                                                                                                                                                          |
| 418 |    152.677036 |    465.733167 | Alexandre Vong                                                                                                                                                                       |
| 419 |    105.367857 |    101.769531 | Agnello Picorelli                                                                                                                                                                    |
| 420 |    435.806260 |     55.011479 | NA                                                                                                                                                                                   |
| 421 |    281.469986 |    341.312604 | FunkMonk                                                                                                                                                                             |
| 422 |    443.289804 |     40.093128 | Jon Hill                                                                                                                                                                             |
| 423 |    517.316694 |    177.847659 | Scott Hartman                                                                                                                                                                        |
| 424 |    249.536229 |    674.291957 | Mattia Menchetti                                                                                                                                                                     |
| 425 |    925.506280 |     50.904534 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                                  |
| 426 |    856.840215 |     84.016351 | Zimices                                                                                                                                                                              |
| 427 |    420.166057 |     45.740698 | Zimices                                                                                                                                                                              |
| 428 |    924.458723 |    186.967938 | Maija Karala                                                                                                                                                                         |
| 429 |    898.540807 |    451.428984 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                             |
| 430 |    165.385910 |    524.035174 | Zimices                                                                                                                                                                              |
| 431 |    386.479092 |    113.522065 | Mo Hassan                                                                                                                                                                            |
| 432 |    865.914357 |    789.811272 | NA                                                                                                                                                                                   |
| 433 |    232.917173 |    499.760295 | Christoph Schomburg                                                                                                                                                                  |
| 434 |    834.954941 |    395.998555 | Campbell Fleming                                                                                                                                                                     |
| 435 |    424.630258 |    772.104667 | Matt Crook                                                                                                                                                                           |
| 436 |    270.619030 |    661.303896 | Matt Crook                                                                                                                                                                           |
| 437 |    924.644291 |    164.981797 | Margot Michaud                                                                                                                                                                       |
| 438 |   1002.093247 |    482.899121 | Mathieu Pélissié                                                                                                                                                                     |
| 439 |    814.995822 |    475.003580 | Joanna Wolfe                                                                                                                                                                         |
| 440 |    565.729366 |    317.504923 | Matt Crook                                                                                                                                                                           |
| 441 |    613.173446 |    619.341409 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 442 |    551.292510 |    459.682971 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
| 443 |    639.889400 |     72.006580 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 444 |     47.883071 |    701.754120 | Bryan Carstens                                                                                                                                                                       |
| 445 |    108.932180 |    271.688261 | Jagged Fang Designs                                                                                                                                                                  |
| 446 |    927.267521 |    471.380381 | NA                                                                                                                                                                                   |
| 447 |    995.561053 |    687.625300 | Maxime Dahirel                                                                                                                                                                       |
| 448 |    438.706377 |    624.928734 | NA                                                                                                                                                                                   |
| 449 |    263.486330 |    535.210955 | NA                                                                                                                                                                                   |
| 450 |     99.006543 |     16.969670 | NA                                                                                                                                                                                   |
| 451 |     12.715434 |    166.258525 | Oscar Sanisidro                                                                                                                                                                      |
| 452 |     32.445909 |     30.941462 | T. Michael Keesey                                                                                                                                                                    |
| 453 |     86.264719 |    434.056167 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 454 |    768.519490 |    398.145166 | Markus A. Grohme                                                                                                                                                                     |
| 455 |    613.082481 |    205.885828 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 456 |    203.348521 |    191.135549 | Margot Michaud                                                                                                                                                                       |
| 457 |    548.687480 |    149.169371 | Scott Hartman                                                                                                                                                                        |
| 458 |    137.305224 |    743.572933 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 459 |    864.450940 |    222.657146 | Matt Wilkins                                                                                                                                                                         |
| 460 |    800.154682 |      8.091907 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                              |
| 461 |    565.445962 |    167.513182 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 462 |    387.630733 |    412.464487 | Kamil S. Jaron                                                                                                                                                                       |
| 463 |    826.506906 |    732.764822 | Zimices                                                                                                                                                                              |
| 464 |    281.893653 |     13.152883 | Matt Crook                                                                                                                                                                           |
| 465 |   1007.492949 |     93.333622 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                                              |
| 466 |    917.484660 |    769.238928 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
| 467 |    257.107657 |    495.566312 | Jagged Fang Designs                                                                                                                                                                  |
| 468 |    462.873379 |    616.652337 | NA                                                                                                                                                                                   |
| 469 |    476.176532 |    480.528586 | Chris Hay                                                                                                                                                                            |
| 470 |    268.824156 |    718.026524 | Steven Traver                                                                                                                                                                        |
| 471 |    121.455211 |    197.294896 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                        |
| 472 |    292.721279 |    618.716409 | Dave Angelini                                                                                                                                                                        |
| 473 |    880.903409 |    670.862525 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 474 |     53.241036 |    768.473775 | Ignacio Contreras                                                                                                                                                                    |
| 475 |    410.250351 |    330.874124 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                                             |
| 476 |    725.871202 |    266.885542 | Zimices / Julián Bayona                                                                                                                                                              |
| 477 |   1013.942954 |     76.795563 | T. Tischler                                                                                                                                                                          |
| 478 |    332.999361 |    199.480979 | Zimices                                                                                                                                                                              |
| 479 |    311.395522 |    166.710399 | Ferran Sayol                                                                                                                                                                         |
| 480 |    495.766643 |     19.318926 | Rebecca Groom                                                                                                                                                                        |
| 481 |    900.295315 |    335.828586 | nicubunu                                                                                                                                                                             |
| 482 |    803.938207 |     89.363007 | Sarah Werning                                                                                                                                                                        |
| 483 |    164.325462 |    625.582999 | NA                                                                                                                                                                                   |
| 484 |    652.008035 |    288.715078 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 485 |    572.957495 |    608.637165 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 486 |   1015.520228 |    364.673805 | Renata F. Martins                                                                                                                                                                    |
| 487 |     57.268703 |    258.510236 | Aline M. Ghilardi                                                                                                                                                                    |
| 488 |    471.206408 |    426.189435 | Sarah Werning                                                                                                                                                                        |
| 489 |    473.611533 |    286.349473 | Terpsichores                                                                                                                                                                         |
| 490 |    712.498130 |    278.389894 | Matt Crook                                                                                                                                                                           |
| 491 |    814.661253 |    460.287110 | Hans Hillewaert                                                                                                                                                                      |
| 492 |    321.445619 |    279.635038 | NA                                                                                                                                                                                   |
| 493 |    749.099092 |    616.799269 | Margot Michaud                                                                                                                                                                       |
| 494 |    337.225320 |    796.840080 | Kai R. Caspar                                                                                                                                                                        |
| 495 |    509.404757 |    414.496258 | Markus A. Grohme                                                                                                                                                                     |
| 496 |    677.331134 |    227.794892 | Zimices                                                                                                                                                                              |
| 497 |    711.305121 |    131.923387 | Tasman Dixon                                                                                                                                                                         |
| 498 |    495.497528 |    371.715348 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 499 |    990.861810 |    423.040917 | Gareth Monger                                                                                                                                                                        |
| 500 |    763.070921 |    772.709615 | Chase Brownstein                                                                                                                                                                     |
| 501 |    205.888951 |    419.538540 | terngirl                                                                                                                                                                             |
| 502 |    854.299099 |    107.258244 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 503 |     24.314512 |    436.387414 | Matt Crook                                                                                                                                                                           |
| 504 |    341.989863 |    636.821358 | Harold N Eyster                                                                                                                                                                      |
| 505 |    821.544918 |    562.183026 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 506 |    114.341658 |    439.655737 | Zimices                                                                                                                                                                              |
| 507 |    906.288943 |     79.382072 | Birgit Lang                                                                                                                                                                          |
| 508 |    984.269158 |    489.867312 | wsnaccad                                                                                                                                                                             |
| 509 |    200.265734 |     65.941082 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 510 |    264.181469 |      6.299213 | (after Spotila 2004)                                                                                                                                                                 |
| 511 |    286.769147 |    279.089611 | Mo Hassan                                                                                                                                                                            |
| 512 |    985.546753 |    630.081477 | Matt Crook                                                                                                                                                                           |
| 513 |    204.783665 |    782.586713 | Lafage                                                                                                                                                                               |
| 514 |    873.067547 |    168.053882 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 515 |    834.715911 |    708.925006 | Andrew A. Farke                                                                                                                                                                      |
| 516 |    876.601078 |    303.021010 | Sarah Werning                                                                                                                                                                        |
| 517 |    661.033091 |    637.083166 | Noah Schlottman                                                                                                                                                                      |
| 518 |    938.919371 |    408.367532 | Chuanixn Yu                                                                                                                                                                          |
| 519 |    323.144984 |    361.030693 | Zimices                                                                                                                                                                              |
| 520 |    589.147197 |    441.584941 | Margot Michaud                                                                                                                                                                       |
| 521 |    396.004678 |    239.773691 | Jagged Fang Designs                                                                                                                                                                  |
| 522 |    371.687622 |     99.067157 | Tasman Dixon                                                                                                                                                                         |
| 523 |    806.871591 |    158.927446 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                                           |
| 524 |   1011.020337 |    193.293201 | Jack Mayer Wood                                                                                                                                                                      |
| 525 |    642.593860 |    541.808024 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                              |
| 526 |    147.099979 |    783.108857 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 527 |    379.114285 |    361.488786 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 528 |    799.298462 |    181.010993 | Shyamal                                                                                                                                                                              |
| 529 |    156.161365 |    143.087898 | Christoph Schomburg                                                                                                                                                                  |
| 530 |    239.972432 |    490.459910 | Dean Schnabel                                                                                                                                                                        |
| 531 |     17.008024 |    785.034928 | Maija Karala                                                                                                                                                                         |
| 532 |     84.052869 |    153.158127 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 533 |    276.988738 |    771.209341 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 534 |    478.552110 |    315.365597 | Fernando Carezzano                                                                                                                                                                   |
| 535 |    501.203887 |    491.597171 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 536 |    982.741026 |    673.096116 | Chris huh                                                                                                                                                                            |
| 537 |    665.479366 |    771.787090 | NA                                                                                                                                                                                   |
| 538 |    613.561506 |    219.403496 | Neil Kelley                                                                                                                                                                          |
| 539 |    121.067786 |    359.158917 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                                    |
| 540 |    427.364584 |    509.675622 | Jiekun He                                                                                                                                                                            |
| 541 |    428.791434 |    636.534265 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                                 |
| 542 |    119.416558 |    698.616724 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                                   |
| 543 |    211.500863 |    591.514312 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 544 |     61.043473 |    237.886317 | Matt Crook                                                                                                                                                                           |
| 545 |   1017.121403 |    148.106346 | T. Michael Keesey                                                                                                                                                                    |
| 546 |    410.864522 |    694.030701 | Andy Wilson                                                                                                                                                                          |
| 547 |    856.396459 |    123.059549 | T. Michael Keesey                                                                                                                                                                    |
| 548 |    278.400119 |    640.827003 | Steven Traver                                                                                                                                                                        |
| 549 |    888.772671 |    562.332153 | Tauana J. Cunha                                                                                                                                                                      |
| 550 |     26.562442 |      7.243270 | Caleb M. Brown                                                                                                                                                                       |
| 551 |    655.178340 |    533.294823 | Aviceda (photo) & T. Michael Keesey                                                                                                                                                  |
| 552 |    539.662312 |    178.423059 | Juan Carlos Jerí                                                                                                                                                                     |
| 553 |   1009.406470 |    183.058749 | Alex Slavenko                                                                                                                                                                        |
| 554 |    564.587281 |    155.943468 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 555 |    548.565255 |    338.646769 | Matt Crook                                                                                                                                                                           |
| 556 |    143.096515 |     44.222599 | Ferran Sayol                                                                                                                                                                         |
| 557 |    264.202636 |    480.524070 | Matt Crook                                                                                                                                                                           |
| 558 |    307.078531 |    289.791563 | Michelle Site                                                                                                                                                                        |
| 559 |    343.648504 |    375.608594 | Matt Crook                                                                                                                                                                           |
| 560 |    685.873835 |     76.008626 | Abraão B. Leite                                                                                                                                                                      |
| 561 |    154.091694 |    337.912647 | Shyamal                                                                                                                                                                              |
| 562 |    596.327195 |     29.518682 | NA                                                                                                                                                                                   |
| 563 |     10.386516 |    739.142611 | Ferran Sayol                                                                                                                                                                         |
| 564 |    910.393418 |    126.297897 | Maxime Dahirel                                                                                                                                                                       |
| 565 |    346.716648 |    215.400324 | Harold N Eyster                                                                                                                                                                      |
| 566 |    860.105564 |    763.665710 | Michele Tobias                                                                                                                                                                       |
| 567 |   1008.868664 |     51.726304 | Zimices                                                                                                                                                                              |
| 568 |    818.314027 |    256.928284 | Michelle Site                                                                                                                                                                        |
| 569 |     37.876248 |    634.004720 | NA                                                                                                                                                                                   |
| 570 |    570.062720 |    430.656492 | Felix Vaux                                                                                                                                                                           |
| 571 |    123.662625 |    756.898949 | Jimmy Bernot                                                                                                                                                                         |
| 572 |    297.786035 |    461.746864 | NA                                                                                                                                                                                   |
| 573 |    943.397476 |     55.100847 | U.S. National Park Service (vectorized by William Gearty)                                                                                                                            |
| 574 |    396.121356 |    483.274595 | Rebecca Groom                                                                                                                                                                        |
| 575 |    770.761740 |    509.375928 | Chuanixn Yu                                                                                                                                                                          |
| 576 |    966.517916 |    666.501452 | Chris huh                                                                                                                                                                            |
| 577 |    354.812207 |    687.954041 | Jagged Fang Designs                                                                                                                                                                  |
| 578 |    413.002380 |    781.688205 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 579 |    902.891964 |     51.425223 | Steven Traver                                                                                                                                                                        |
| 580 |    151.050670 |    413.811029 | Jaime Headden                                                                                                                                                                        |
| 581 |    847.168087 |     99.471950 | Scott Hartman                                                                                                                                                                        |
| 582 |    972.134132 |    513.820722 | Pedro de Siracusa                                                                                                                                                                    |
| 583 |    117.842912 |     58.986356 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 584 |    460.974297 |    343.173916 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                     |
| 585 |    286.586835 |    231.913732 | Dean Schnabel                                                                                                                                                                        |
| 586 |   1011.610306 |    387.846622 | Andrew A. Farke                                                                                                                                                                      |
| 587 |    842.836474 |    168.527705 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 588 |    888.604295 |     44.001674 | NA                                                                                                                                                                                   |
| 589 |    373.058335 |    176.779179 | NA                                                                                                                                                                                   |
| 590 |     61.374787 |    646.639616 | Ramona J Heim                                                                                                                                                                        |
| 591 |    506.333503 |    423.162706 | Christoph Schomburg                                                                                                                                                                  |
| 592 |    984.286722 |    217.660780 | Gareth Monger                                                                                                                                                                        |
| 593 |    358.268807 |    259.528707 | Mo Hassan                                                                                                                                                                            |
| 594 |    450.993122 |    433.816827 | Emily Willoughby                                                                                                                                                                     |
| 595 |    376.044441 |    265.317014 | Steven Traver                                                                                                                                                                        |
| 596 |    600.722126 |    531.196901 | Zimices                                                                                                                                                                              |
| 597 |    331.090374 |    529.668200 | Caleb M. Brown                                                                                                                                                                       |
| 598 |    751.737862 |    191.842906 | Dean Schnabel                                                                                                                                                                        |
| 599 |    967.434029 |    221.670985 | David Orr                                                                                                                                                                            |
| 600 |     59.488320 |    568.229291 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 601 |    198.712990 |    597.165878 | Crystal Maier                                                                                                                                                                        |
| 602 |    237.900547 |     82.321261 | Tasman Dixon                                                                                                                                                                         |
| 603 |    707.757768 |    364.807921 | Beth Reinke                                                                                                                                                                          |
| 604 |    406.162120 |    617.331830 | T. Michael Keesey                                                                                                                                                                    |
| 605 |    904.624863 |    321.324532 | Rebecca Groom                                                                                                                                                                        |
| 606 |      8.960699 |    209.880250 | Gareth Monger                                                                                                                                                                        |
| 607 |    137.188023 |    352.850160 | T. Michael Keesey                                                                                                                                                                    |
| 608 |    508.172470 |    163.844097 | Matt Crook                                                                                                                                                                           |
| 609 |    443.061110 |    763.908135 | Christoph Schomburg                                                                                                                                                                  |
| 610 |    756.030194 |    576.524480 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 611 |    794.988645 |    439.835085 | Margot Michaud                                                                                                                                                                       |
| 612 |    439.675120 |    169.467535 | terngirl                                                                                                                                                                             |
| 613 |    348.975628 |    777.862006 | Ferran Sayol                                                                                                                                                                         |
| 614 |    957.287653 |    379.296757 | Gareth Monger                                                                                                                                                                        |
| 615 |    504.925360 |    300.333483 | Chris huh                                                                                                                                                                            |
| 616 |    584.016878 |    406.901516 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                                   |
| 617 |    420.859119 |    757.892298 | Jagged Fang Designs                                                                                                                                                                  |
| 618 |    273.262756 |     87.203720 | Mariana Ruiz Villarreal                                                                                                                                                              |
| 619 |    895.491448 |    188.693626 | Manabu Bessho-Uehara                                                                                                                                                                 |
| 620 |    819.871533 |     36.989368 | Iain Reid                                                                                                                                                                            |
| 621 |    942.169329 |    732.189267 | Martin R. Smith                                                                                                                                                                      |
| 622 |    351.644642 |     92.062631 | Matt Crook                                                                                                                                                                           |
| 623 |    468.165654 |    788.827145 | FJDegrange                                                                                                                                                                           |
| 624 |    894.258438 |    284.149395 | Dean Schnabel                                                                                                                                                                        |
| 625 |    714.820627 |    150.787624 | Lafage                                                                                                                                                                               |
| 626 |    183.884181 |    439.740204 | Caleb M. Brown                                                                                                                                                                       |
| 627 |    107.694926 |    481.756272 | Ignacio Contreras                                                                                                                                                                    |
| 628 |    283.327323 |    737.754278 | NA                                                                                                                                                                                   |
| 629 |    700.701821 |    213.307161 | Jessica Anne Miller                                                                                                                                                                  |
| 630 |    425.235659 |    673.283434 | Matt Crook                                                                                                                                                                           |
| 631 |    657.351516 |    310.470853 | Gareth Monger                                                                                                                                                                        |
| 632 |    600.449051 |    478.369359 | Darius Nau                                                                                                                                                                           |
| 633 |    106.455834 |    545.638818 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 634 |    991.179306 |    200.643214 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 635 |    623.163306 |    444.846768 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                                |
| 636 |    357.186233 |    636.916343 | Scott Hartman                                                                                                                                                                        |
| 637 |     42.316193 |    574.145561 | Bennet McComish, photo by Avenue                                                                                                                                                     |
| 638 |    868.849597 |     62.226530 | Margot Michaud                                                                                                                                                                       |
| 639 |    702.858547 |    468.450360 | Dmitry Bogdanov                                                                                                                                                                      |
| 640 |    350.288079 |    614.351175 | Zimices                                                                                                                                                                              |
| 641 |    943.621387 |    281.877226 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                             |
| 642 |    194.156498 |    467.020585 | Markus A. Grohme                                                                                                                                                                     |
| 643 |    315.254419 |     49.134794 | Sarah Werning                                                                                                                                                                        |
| 644 |    818.856909 |    119.577288 | Margot Michaud                                                                                                                                                                       |
| 645 |    649.136542 |     16.245511 | NA                                                                                                                                                                                   |
| 646 |    151.649170 |    700.804221 | Margot Michaud                                                                                                                                                                       |
| 647 |    132.358282 |    796.888876 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 648 |   1015.206617 |    793.360034 | Lukasiniho                                                                                                                                                                           |
| 649 |    175.400514 |     18.803802 | Kamil S. Jaron                                                                                                                                                                       |
| 650 |    236.769039 |    749.574057 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                                   |
| 651 |    854.616708 |    589.155247 | Scott Hartman                                                                                                                                                                        |
| 652 |    602.724878 |    563.142993 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 653 |      8.945104 |    660.937330 | Matt Crook                                                                                                                                                                           |
| 654 |    690.141243 |    640.571468 | Tasman Dixon                                                                                                                                                                         |
| 655 |    458.698570 |     38.043666 | Jonathan Wells                                                                                                                                                                       |
| 656 |    768.684805 |     85.644960 | NA                                                                                                                                                                                   |
| 657 |    103.455832 |    194.862789 | Alexandre Vong                                                                                                                                                                       |
| 658 |     62.517744 |    735.134751 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                             |
| 659 |    974.487715 |     10.996942 | Estelle Bourdon                                                                                                                                                                      |
| 660 |    439.128147 |    498.286887 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                                              |
| 661 |    684.000815 |    382.440645 | Matt Crook                                                                                                                                                                           |
| 662 |    897.901584 |    369.245324 | Katie S. Collins                                                                                                                                                                     |
| 663 |    282.468517 |    395.406166 | Maija Karala                                                                                                                                                                         |
| 664 |    963.916213 |    280.766907 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
| 665 |    667.281157 |    551.532989 | Dean Schnabel                                                                                                                                                                        |
| 666 |    307.780197 |    696.465787 | Scott Hartman                                                                                                                                                                        |
| 667 |      7.925940 |    303.872389 | Ignacio Contreras                                                                                                                                                                    |
| 668 |    281.117724 |    726.015408 | Ferran Sayol                                                                                                                                                                         |
| 669 |    246.077750 |    563.602013 | Ferran Sayol                                                                                                                                                                         |
| 670 |    611.778961 |    563.686510 | T. Michael Keesey (after Walker & al.)                                                                                                                                               |
| 671 |    996.969173 |    661.180420 | NA                                                                                                                                                                                   |
| 672 |    722.474131 |    201.824900 | Dean Schnabel                                                                                                                                                                        |
| 673 |     79.063201 |    793.342610 | Manabu Sakamoto                                                                                                                                                                      |
| 674 |    742.817602 |    568.580884 | Steven Traver                                                                                                                                                                        |
| 675 |     56.449978 |    306.291203 | Steven Traver                                                                                                                                                                        |
| 676 |    804.552298 |    668.157848 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 677 |    359.761572 |    174.759745 | Margot Michaud                                                                                                                                                                       |
| 678 |    315.901191 |    353.854165 | Scott Hartman                                                                                                                                                                        |
| 679 |    873.199700 |    519.173067 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 680 |     65.146002 |    143.050231 | Steven Traver                                                                                                                                                                        |
| 681 |    309.465665 |     89.048495 | Courtney Rockenbach                                                                                                                                                                  |
| 682 |    408.749531 |    242.649537 | Geoff Shaw                                                                                                                                                                           |
| 683 |    384.960848 |    492.543396 | Gareth Monger                                                                                                                                                                        |
| 684 |    849.188416 |    389.836339 | NA                                                                                                                                                                                   |
| 685 |    450.691678 |    611.721586 | Mathieu Pélissié                                                                                                                                                                     |
| 686 |    279.575657 |    124.104933 | Ingo Braasch                                                                                                                                                                         |
| 687 |    839.872661 |     12.086675 | Margot Michaud                                                                                                                                                                       |
| 688 |    374.628861 |    201.561881 | Ignacio Contreras                                                                                                                                                                    |
| 689 |    474.051986 |    505.911110 | Markus A. Grohme                                                                                                                                                                     |
| 690 |    983.448089 |    593.121974 | T. Michael Keesey                                                                                                                                                                    |
| 691 |     15.561853 |    720.869961 | Steven Traver                                                                                                                                                                        |
| 692 |   1014.110728 |    652.402734 | Anthony Caravaggi                                                                                                                                                                    |
| 693 |    882.795113 |    120.231226 | NA                                                                                                                                                                                   |
| 694 |    165.438128 |    202.001347 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 695 |    573.385670 |    324.596872 | terngirl                                                                                                                                                                             |
| 696 |    777.469744 |    388.060263 | Milton Tan                                                                                                                                                                           |
| 697 |      8.445234 |    429.089896 | Jessica Rick                                                                                                                                                                         |
| 698 |    397.620220 |     66.841806 | Scott Hartman                                                                                                                                                                        |
| 699 |     95.002366 |    788.961291 | Chris huh                                                                                                                                                                            |
| 700 |    505.368309 |    672.128459 | Christoph Schomburg                                                                                                                                                                  |
| 701 |    259.755512 |    466.995741 | Steven Blackwood                                                                                                                                                                     |
| 702 |    459.151072 |    735.842734 | V. Deepak                                                                                                                                                                            |
| 703 |    685.537698 |    530.163131 | Christoph Schomburg                                                                                                                                                                  |
| 704 |    854.850330 |    562.193854 | Yan Wong                                                                                                                                                                             |
| 705 |     34.700026 |    779.779131 | NASA                                                                                                                                                                                 |
| 706 |     58.022630 |    572.827161 | Margot Michaud                                                                                                                                                                       |
| 707 |    117.535239 |    470.993939 | Matt Crook                                                                                                                                                                           |
| 708 |    255.808815 |    300.505066 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 709 |     73.905021 |    132.698696 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                                   |
| 710 |    686.758293 |     40.386891 | Andy Wilson                                                                                                                                                                          |
| 711 |    548.470695 |    661.649137 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 712 |    941.279305 |    530.784717 | Ferran Sayol                                                                                                                                                                         |
| 713 |     21.663950 |    313.246803 | Jagged Fang Designs                                                                                                                                                                  |
| 714 |    156.726574 |     15.366574 | Xavier Giroux-Bougard                                                                                                                                                                |
| 715 |    488.390763 |      7.368846 | Melissa Ingala                                                                                                                                                                       |
| 716 |    451.396844 |    386.625900 | T. Michael Keesey                                                                                                                                                                    |
| 717 |    529.926628 |    527.011976 | Jiekun He                                                                                                                                                                            |
| 718 |    276.355138 |     43.569938 | Michele Tobias                                                                                                                                                                       |
| 719 |    448.956150 |    791.306026 | Yan Wong                                                                                                                                                                             |
| 720 |    351.922090 |    405.186773 | NA                                                                                                                                                                                   |
| 721 |    891.525256 |    420.557654 | Ferran Sayol                                                                                                                                                                         |
| 722 |    487.627099 |     92.261548 | Birgit Lang                                                                                                                                                                          |
| 723 |    126.884874 |    720.050378 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 724 |    237.482250 |    599.323402 | Ingo Braasch                                                                                                                                                                         |
| 725 |    261.435314 |    631.362744 | NA                                                                                                                                                                                   |
| 726 |    758.631594 |    787.200768 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 727 |     26.241984 |    258.021024 | Andrew A. Farke                                                                                                                                                                      |
| 728 |    760.122189 |    303.890641 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                               |
| 729 |    285.290589 |    299.911286 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 730 |    836.224396 |    738.705068 | Andy Wilson                                                                                                                                                                          |
| 731 |    271.965724 |    707.481120 | Matt Crook                                                                                                                                                                           |
| 732 |    851.065809 |    606.387821 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 733 |    980.559167 |    392.200585 | Dean Schnabel                                                                                                                                                                        |
| 734 |    436.928049 |    535.636260 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 735 |    973.088741 |    589.579371 | Hugo Gruson                                                                                                                                                                          |
| 736 |    879.156945 |    738.161890 | NA                                                                                                                                                                                   |
| 737 |    891.996901 |    520.886860 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 738 |    394.607130 |    204.315288 | Andy Wilson                                                                                                                                                                          |
| 739 |      7.683576 |    106.584917 | Dinah Challen                                                                                                                                                                        |
| 740 |    124.379507 |     12.277149 | FunkMonk                                                                                                                                                                             |
| 741 |    691.158608 |    388.381054 | Matt Crook                                                                                                                                                                           |
| 742 |   1007.352932 |    461.679492 | Birgit Lang                                                                                                                                                                          |
| 743 |    768.958421 |    176.410865 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 744 |    281.107238 |    495.889884 | Margot Michaud                                                                                                                                                                       |
| 745 |     77.961422 |    450.338629 | Ferran Sayol                                                                                                                                                                         |
| 746 |    902.542432 |     62.113230 | Margot Michaud                                                                                                                                                                       |
| 747 |    807.093109 |    385.619791 | Lukas Panzarin                                                                                                                                                                       |
| 748 |    504.832071 |    583.039246 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 749 |    954.021378 |    243.027097 | Zimices                                                                                                                                                                              |
| 750 |     29.522559 |    659.358368 | Jagged Fang Designs                                                                                                                                                                  |
| 751 |    574.753140 |    288.646505 | Collin Gross                                                                                                                                                                         |
| 752 |    267.311655 |    199.231741 | NA                                                                                                                                                                                   |
| 753 |    256.584900 |     67.102537 | Birgit Lang                                                                                                                                                                          |
| 754 |    795.821323 |    412.359716 | Andy Wilson                                                                                                                                                                          |
| 755 |    755.161212 |    602.623861 | Jimmy Bernot                                                                                                                                                                         |
| 756 |    902.190208 |    116.402407 | Zimices                                                                                                                                                                              |
| 757 |    257.319956 |    790.747965 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 758 |     28.579644 |    157.591217 | Steven Traver                                                                                                                                                                        |
| 759 |    759.243644 |    379.390615 | Scott Hartman                                                                                                                                                                        |
| 760 |    671.035496 |    402.462021 | L. Shyamal                                                                                                                                                                           |
| 761 |    182.846063 |    194.983514 | Steven Traver                                                                                                                                                                        |
| 762 |     57.262161 |     99.926844 | Scott Hartman                                                                                                                                                                        |
| 763 |    861.217192 |    653.009491 | Pedro de Siracusa                                                                                                                                                                    |
| 764 |    842.256403 |     69.048943 | Zimices                                                                                                                                                                              |
| 765 |    135.134079 |    733.911854 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
| 766 |    478.309121 |    657.635726 | Scott Hartman                                                                                                                                                                        |
| 767 |    922.998373 |    172.964428 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 768 |    823.583148 |    454.077067 | Iain Reid                                                                                                                                                                            |
| 769 |    461.537304 |    572.806551 | Markus A. Grohme                                                                                                                                                                     |
| 770 |    362.228167 |    371.312355 | Maija Karala                                                                                                                                                                         |
| 771 |    615.577642 |    596.592221 | Gareth Monger                                                                                                                                                                        |
| 772 |    335.459871 |    143.831291 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 773 |    254.576349 |    556.846709 | Maija Karala                                                                                                                                                                         |
| 774 |    549.502118 |    730.257689 | NA                                                                                                                                                                                   |
| 775 |    415.358246 |    492.614500 | Ignacio Contreras                                                                                                                                                                    |
| 776 |    613.091106 |     31.565698 | Todd Marshall, vectorized by Zimices                                                                                                                                                 |
| 777 |    973.329778 |    233.613035 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 778 |    120.321949 |    789.311006 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 779 |    436.168378 |     85.305804 | Kailah Thorn & Ben King                                                                                                                                                              |
| 780 |    124.688475 |    233.824774 | T. Michael Keesey                                                                                                                                                                    |
| 781 |    763.580472 |    426.918101 | NA                                                                                                                                                                                   |
| 782 |    923.294034 |    328.484856 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 783 |    517.970309 |    242.697308 | Matt Crook                                                                                                                                                                           |
| 784 |    314.855375 |    481.183557 | Christoph Schomburg                                                                                                                                                                  |
| 785 |     87.813924 |    377.630371 | xgirouxb                                                                                                                                                                             |
| 786 |     51.001569 |    630.950526 | Matt Crook                                                                                                                                                                           |
| 787 |    198.470818 |      5.865321 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                     |
| 788 |    938.319690 |    167.732320 | www.studiospectre.com                                                                                                                                                                |
| 789 |    997.424552 |    131.597895 | Gareth Monger                                                                                                                                                                        |
| 790 |    778.481631 |    521.629247 | Zimices / Julián Bayona                                                                                                                                                              |
| 791 |    647.761277 |     48.324694 | Rebecca Groom                                                                                                                                                                        |
| 792 |    712.352622 |    127.428839 | Zimices                                                                                                                                                                              |
| 793 |    105.872576 |    759.282825 | Ludwik Gąsiorowski                                                                                                                                                                   |
| 794 |    260.641651 |    351.639571 | Andrew A. Farke                                                                                                                                                                      |
| 795 |   1004.385161 |    696.464454 | Chris huh                                                                                                                                                                            |
| 796 |    381.908991 |    639.735590 | Smokeybjb, vectorized by Zimices                                                                                                                                                     |
| 797 |    916.553251 |    570.915349 | M. Garfield & K. Anderson (modified by T. Michael Keesey)                                                                                                                            |
| 798 |    747.495384 |    316.336455 | Chris huh                                                                                                                                                                            |
| 799 |    404.151388 |    291.941469 | NA                                                                                                                                                                                   |
| 800 |    573.313321 |    774.311400 | Sarah Werning                                                                                                                                                                        |
| 801 |    699.423908 |    441.519114 | Nobu Tamura                                                                                                                                                                          |
| 802 |     94.359136 |    110.655837 | Chris huh                                                                                                                                                                            |
| 803 |    390.465747 |    155.448994 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 804 |    609.940604 |    793.034474 | Christoph Schomburg                                                                                                                                                                  |
| 805 |    390.058119 |    284.374352 | Cristopher Silva                                                                                                                                                                     |
| 806 |    538.051684 |    706.024823 | Scott Hartman                                                                                                                                                                        |
| 807 |    335.428064 |    286.376282 | Margot Michaud                                                                                                                                                                       |
| 808 |    207.598975 |    412.370183 | Mathew Wedel                                                                                                                                                                         |
| 809 |    657.283082 |    781.104341 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                          |
| 810 |     21.719703 |    685.874578 | Ferran Sayol                                                                                                                                                                         |
| 811 |    239.095654 |    734.793582 | Steven Traver                                                                                                                                                                        |
| 812 |    331.488295 |    227.275533 | T. Michael Keesey                                                                                                                                                                    |
| 813 |    252.982252 |     78.091014 | Maija Karala                                                                                                                                                                         |
| 814 |    698.514218 |    135.343960 | Dean Schnabel                                                                                                                                                                        |
| 815 |    900.070486 |    350.050752 | NA                                                                                                                                                                                   |
| 816 |    953.249629 |     18.375204 | Zimices                                                                                                                                                                              |
| 817 |    322.622445 |    126.144938 | Ferran Sayol                                                                                                                                                                         |
| 818 |   1014.766013 |    522.111666 | Ferran Sayol                                                                                                                                                                         |
| 819 |    162.054666 |    448.709258 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 820 |    689.655979 |    462.262830 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 821 |   1010.289397 |    125.994760 | Gareth Monger                                                                                                                                                                        |
| 822 |    737.061685 |    186.986359 | NA                                                                                                                                                                                   |
| 823 |    414.964153 |    303.286143 | Andy Wilson                                                                                                                                                                          |
| 824 |    386.939182 |     40.766672 | Margot Michaud                                                                                                                                                                       |
| 825 |     45.946846 |     31.874670 | Zimices                                                                                                                                                                              |
| 826 |    346.713336 |    363.227217 | Zimices                                                                                                                                                                              |
| 827 |    418.911741 |     22.770318 | Andy Wilson                                                                                                                                                                          |
| 828 |    999.797840 |    747.197804 | Matt Martyniuk                                                                                                                                                                       |
| 829 |   1007.593166 |    149.861103 | NA                                                                                                                                                                                   |
| 830 |    517.174619 |    352.638293 | Gareth Monger                                                                                                                                                                        |
| 831 |    171.678078 |     30.541825 | Zimices                                                                                                                                                                              |
| 832 |    141.337022 |    456.390244 | Steven Traver                                                                                                                                                                        |
| 833 |    457.679040 |    673.434212 | Maija Karala                                                                                                                                                                         |
| 834 |    888.389968 |    259.816233 | Maxime Dahirel                                                                                                                                                                       |
| 835 |    667.422229 |     28.943909 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 836 |    835.699743 |    467.230969 | Yan Wong                                                                                                                                                                             |
| 837 |    330.809918 |    411.240649 | Jagged Fang Designs                                                                                                                                                                  |
| 838 |    270.701699 |    220.164272 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 839 |    703.142143 |     45.685577 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                                        |
| 840 |    497.079874 |    264.108198 | Steven Traver                                                                                                                                                                        |
| 841 |    963.806580 |     36.874734 | NA                                                                                                                                                                                   |
| 842 |    307.842116 |    279.669126 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                                     |
| 843 |    789.299959 |    152.944239 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                                              |
| 844 |    970.676615 |    537.318736 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 845 |    915.315305 |    356.369543 | Zimices                                                                                                                                                                              |
| 846 |    180.822975 |    783.734215 | Matt Crook                                                                                                                                                                           |
| 847 |    956.122939 |    230.583683 | Rebecca Groom                                                                                                                                                                        |
| 848 |    976.645465 |    205.878050 | Chris huh                                                                                                                                                                            |
| 849 |     94.875389 |     68.517422 | Emily Willoughby                                                                                                                                                                     |
| 850 |    146.325700 |    449.114105 | Matthew E. Clapham                                                                                                                                                                   |
| 851 |    515.928140 |    538.874842 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 852 |      7.501394 |    712.216308 | Jagged Fang Designs                                                                                                                                                                  |
| 853 |    826.975137 |    483.606548 | Margot Michaud                                                                                                                                                                       |
| 854 |    594.183803 |    340.182631 | Robert Hering                                                                                                                                                                        |
| 855 |    945.823958 |    618.000447 | Armin Reindl                                                                                                                                                                         |
| 856 |    430.171329 |    328.707235 | Scott Hartman                                                                                                                                                                        |
| 857 |    869.487445 |    582.422667 | Jake Warner                                                                                                                                                                          |
| 858 |   1000.061018 |    431.439407 | Henry Lydecker                                                                                                                                                                       |
| 859 |    462.369533 |    499.212857 | Jagged Fang Designs                                                                                                                                                                  |
| 860 |    526.438721 |    201.825693 | Matt Crook                                                                                                                                                                           |
| 861 |    670.369411 |    469.174181 | Matt Crook                                                                                                                                                                           |
| 862 |    727.019663 |    633.392029 | Ferran Sayol                                                                                                                                                                         |
| 863 |    515.875376 |     92.388493 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 864 |    519.500158 |    110.265001 | Gareth Monger                                                                                                                                                                        |
| 865 |    671.993882 |    788.283089 | Steven Traver                                                                                                                                                                        |
| 866 |    883.469815 |    325.221091 | Matt Martyniuk                                                                                                                                                                       |
| 867 |    970.118381 |    495.232936 | Meliponicultor Itaymbere                                                                                                                                                             |
| 868 |     97.199606 |    796.991632 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 869 |    735.091801 |      6.390239 | Jagged Fang Designs                                                                                                                                                                  |
| 870 |    853.754190 |    784.048372 | Ferran Sayol                                                                                                                                                                         |
| 871 |    281.874896 |    100.026538 | Ferran Sayol                                                                                                                                                                         |
| 872 |    654.863463 |    419.326717 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 873 |    247.299202 |     97.480876 | Ricardo Araújo                                                                                                                                                                       |
| 874 |    776.540456 |    763.441310 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 875 |    261.096572 |    459.578854 | Kamil S. Jaron                                                                                                                                                                       |
| 876 |    430.515090 |    523.572883 | Steven Traver                                                                                                                                                                        |
| 877 |     80.655997 |    720.628048 | Robert Hering                                                                                                                                                                        |
| 878 |    148.190662 |    748.123088 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 879 |    825.259374 |    410.152507 | Ferran Sayol                                                                                                                                                                         |
| 880 |     99.354379 |    577.414008 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                                 |
| 881 |     53.370177 |    733.225507 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                                            |
| 882 |    863.937905 |    545.727786 | Allison Pease                                                                                                                                                                        |
| 883 |    640.630298 |    340.234295 | Ludwik Gąsiorowski                                                                                                                                                                   |
| 884 |    560.410338 |    749.935111 | Matt Crook                                                                                                                                                                           |
| 885 |    130.215981 |    458.370924 | T. Michael Keesey                                                                                                                                                                    |
| 886 |    943.682711 |    250.720369 | Tasman Dixon                                                                                                                                                                         |
| 887 |    302.342797 |    739.785564 | Steven Traver                                                                                                                                                                        |
| 888 |    970.493250 |    384.742800 | NA                                                                                                                                                                                   |
| 889 |    363.024542 |    751.432573 | T. Michael Keesey (after Masteraah)                                                                                                                                                  |
| 890 |    320.739792 |    372.317779 | xgirouxb                                                                                                                                                                             |
| 891 |    349.593580 |    490.293324 | Nobu Tamura                                                                                                                                                                          |
| 892 |    977.242965 |    714.888803 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 893 |    914.454653 |     41.139647 | Steven Traver                                                                                                                                                                        |
| 894 |     64.573887 |     58.961656 | NA                                                                                                                                                                                   |
| 895 |     36.721165 |    277.591043 | Maxime Dahirel                                                                                                                                                                       |
| 896 |    431.624634 |    316.663737 | Yan Wong from drawing by Joseph Smit                                                                                                                                                 |
| 897 |    782.354588 |    727.801087 | Margot Michaud                                                                                                                                                                       |
| 898 |    887.496707 |     11.037275 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                               |
| 899 |   1015.811375 |      8.975533 | Matt Crook                                                                                                                                                                           |
| 900 |    183.165957 |    710.293113 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                                 |
| 901 |     85.016061 |    201.901432 | Mo Hassan                                                                                                                                                                            |
| 902 |    522.738667 |    790.563500 | Zimices                                                                                                                                                                              |
| 903 |    942.410542 |     43.322657 | NA                                                                                                                                                                                   |
| 904 |     39.387226 |    691.326224 | Matt Crook                                                                                                                                                                           |
| 905 |    785.980033 |     43.408252 | Zimices                                                                                                                                                                              |
| 906 |   1002.119150 |    231.445293 | Mo Hassan                                                                                                                                                                            |
| 907 |    772.492908 |    574.633154 | T. Michael Keesey                                                                                                                                                                    |
| 908 |    295.248223 |     49.728395 | CNZdenek                                                                                                                                                                             |
| 909 |    934.770443 |    673.386333 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                                              |
| 910 |    418.370523 |    345.957907 | L. Shyamal                                                                                                                                                                           |
| 911 |    285.940590 |    110.834179 | Matt Crook                                                                                                                                                                           |
| 912 |    460.827449 |    529.312100 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 913 |   1018.630346 |    225.664307 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 914 |     53.279423 |    280.179169 | Steven Traver                                                                                                                                                                        |
| 915 |    760.260623 |    528.364248 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 916 |    225.318285 |    658.248199 | Javier Luque                                                                                                                                                                         |
| 917 |    537.669479 |    328.945703 | Matt Crook                                                                                                                                                                           |
| 918 |    573.362871 |    301.859897 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 919 |   1003.865155 |    757.407570 | Chris huh                                                                                                                                                                            |
| 920 |    193.056998 |    733.730464 | Steven Traver                                                                                                                                                                        |
| 921 |    733.342651 |    145.986318 | Crystal Maier                                                                                                                                                                        |
| 922 |    900.201413 |    410.790759 | SauropodomorphMonarch                                                                                                                                                                |
| 923 |    403.959882 |    602.672567 | NA                                                                                                                                                                                   |

    #> Your tweet has been posted!
