
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

Sergio A. Muñoz-Gómez, Ferran Sayol, Dinah Challen, Noah Schlottman,
Bryan Carstens, Stanton F. Fink, vectorized by Zimices, xgirouxb, Noah
Schlottman, photo by Martin V. Sørensen, Jaime Headden, Becky Barnes,
Matt Crook, Cagri Cevrim, T. Michael Keesey (after Ponomarenko), Chris
huh, Steven Traver, Michael Scroggie, Nobu Tamura (modified by T.
Michael Keesey), Gabriela Palomo-Munoz, Lukasiniho, Shyamal, Zimices,
Christoph Schomburg, Robert Bruce Horsfall (vectorized by T. Michael
Keesey), Ignacio Contreras, Gareth Monger, Margot Michaud, Scott
Hartman, Mali’o Kodis, image from the “Proceedings of the Zoological
Society of London”, Inessa Voet, Jagged Fang Designs, Scott Hartman
(modified by T. Michael Keesey), Jose Carlos Arenas-Monroy, Berivan
Temiz, Arthur Weasley (vectorized by T. Michael Keesey), Hanyong Pu,
Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming
Zhang, Songhai Jia & T. Michael Keesey, Markus A. Grohme, Mathieu
Pélissié, Rebecca Groom, Ghedoghedo (vectorized by T. Michael Keesey),
Carlos Cano-Barbacil, Manabu Sakamoto, T. Michael Keesey, Lily Hughes,
Blanco et al., 2014, vectorized by Zimices, Collin Gross, Scott Hartman
(vectorized by T. Michael Keesey), Nobu Tamura (vectorized by T. Michael
Keesey), Obsidian Soul (vectorized by T. Michael Keesey), Alexander
Schmidt-Lebuhn, Smokeybjb (modified by Mike Keesey), NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Smokeybjb, L. Shyamal, Alexandre Vong, Maija Karala, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Dmitry Bogdanov (vectorized by T. Michael Keesey),
Beth Reinke, Anna Willoughby, Nobu Tamura, vectorized by Zimices, Mathew
Wedel, Felix Vaux, Bruno C. Vellutini, CNZdenek, Ben Liebeskind,
Benjamint444, Renata F. Martins, Matt Martyniuk, Elisabeth Östman, Emily
Willoughby, Paul Baker (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, DW Bapst (modified from Bulman, 1970),
Ieuan Jones, Tasman Dixon, Birgit Lang, Andy Wilson, Juan Carlos Jerí,
Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts,
Catherine A. Forster, Joshua A. Smith, Alan L. Titus, Daniel Jaron,
Sarah Werning, Mason McNair, Chase Brownstein, Milton Tan, Fcb981
(vectorized by T. Michael Keesey), Gabriele Midolo, B. Duygu Özpolat,
Auckland Museum and T. Michael Keesey, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Danielle Alba, Kanchi
Nanjo, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Henry Lydecker, Smokeybjb (vectorized
by T. Michael Keesey), kreidefossilien.de, Pedro de Siracusa, Noah
Schlottman, photo by Carol Cummings, Jessica Anne Miller, Dmitry
Bogdanov, Steven Coombs (vectorized by T. Michael Keesey), Ludwik
Gąsiorowski, Roderic Page and Lois Page, C. Camilo Julián-Caballero,
Michelle Site, Walter Vladimir, Tauana J. Cunha, Tess Linden, Stemonitis
(photography) and T. Michael Keesey (vectorization),
SauropodomorphMonarch, Pranav Iyer (grey ideas), Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), T. Michael
Keesey (after Monika Betley), Robert Bruce Horsfall, vectorized by
Zimices, Brad McFeeters (vectorized by T. Michael Keesey), Jay Matternes
(vectorized by T. Michael Keesey), Ingo Braasch, Karla Martinez, Nobu
Tamura, Almandine (vectorized by T. Michael Keesey), Timothy Knepp of
the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Richard Parker (vectorized by T. Michael Keesey), Ghedo
(vectorized by T. Michael Keesey), Katie S. Collins, Robbie N. Cada
(vectorized by T. Michael Keesey), Dexter R. Mardis, Siobhon Egan, Tracy
A. Heath, Anthony Caravaggi, Robert Gay, modifed from Olegivvit, Cesar
Julian, Roberto Díaz Sibaja, Andrew A. Farke, SecretJellyMan, Kamil S.
Jaron, Matt Dempsey, Chris Jennings (vectorized by A. Verrière), Michele
Tobias, Iain Reid, M Kolmann, Kai R. Caspar, Crystal Maier, Yan Wong
from illustration by Charles Orbigny, Tyler Greenfield, Todd Marshall,
vectorized by Zimices, Francisco Manuel Blanco (vectorized by T. Michael
Keesey), Pollyanna von Knorring and T. Michael Keesey, DFoidl
(vectorized by T. Michael Keesey), Charles R. Knight (vectorized by T.
Michael Keesey), Jack Mayer Wood, Harold N Eyster, Jakovche, Yan Wong,
Maxime Dahirel, Stanton F. Fink (vectorized by T. Michael Keesey),
Robert Gay, Kosta Mumcuoglu (vectorized by T. Michael Keesey), Armin
Reindl, Mattia Menchetti / Yan Wong, (after Spotila 2004), James R.
Spotila and Ray Chatterji, Melissa Ingala, Tony Ayling (vectorized by T.
Michael Keesey), Tyler Greenfield and Scott Hartman, Oscar Sanisidro,
Roberto Diaz Sibaja, based on Domser, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Chris A.
Hamilton, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Andrés Sánchez, Gopal Murali, T. Tischler, Jaime Headden
(vectorized by T. Michael Keesey), Caleb M. Brown, Alex Slavenko, Karl
Ragnar Gjertsen (vectorized by T. Michael Keesey), Mathilde Cordellier,
Matus Valach, Lisa Byrne, Steven Haddock • Jellywatch.org, Frank Denota,
Andreas Trepte (vectorized by T. Michael Keesey), Jimmy Bernot, Riccardo
Percudani, Enoch Joseph Wetsy (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Kent Elson Sorgon, White Wolf, T.
Michael Keesey (after A. Y. Ivantsov), Darren Naish (vectorize by T.
Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    483.978725 |    635.742300 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|   2 |    202.015206 |    216.728247 | Ferran Sayol                                                                                                                                                          |
|   3 |    524.487767 |    278.343631 | Dinah Challen                                                                                                                                                         |
|   4 |    732.181713 |    419.591892 | Noah Schlottman                                                                                                                                                       |
|   5 |    273.339574 |    500.335845 | Bryan Carstens                                                                                                                                                        |
|   6 |    428.501486 |    448.344822 | Ferran Sayol                                                                                                                                                          |
|   7 |    920.231394 |     44.330169 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
|   8 |    352.289127 |    520.880680 | xgirouxb                                                                                                                                                              |
|   9 |    733.352866 |    223.521922 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
|  10 |    400.510355 |    631.080051 | Jaime Headden                                                                                                                                                         |
|  11 |    316.792298 |     88.791169 | Becky Barnes                                                                                                                                                          |
|  12 |    172.557714 |     75.949597 | Matt Crook                                                                                                                                                            |
|  13 |    413.581268 |    252.850328 | Cagri Cevrim                                                                                                                                                          |
|  14 |    720.179869 |    140.954935 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
|  15 |    569.349169 |    126.452650 | NA                                                                                                                                                                    |
|  16 |    844.330229 |    470.080346 | Chris huh                                                                                                                                                             |
|  17 |    595.189860 |    689.876348 | Steven Traver                                                                                                                                                         |
|  18 |    701.837449 |    697.756190 | Michael Scroggie                                                                                                                                                      |
|  19 |     92.526458 |    233.074317 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  20 |    161.850968 |    646.319524 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  21 |    853.227230 |    221.454191 | NA                                                                                                                                                                    |
|  22 |     95.200239 |    417.206749 | Lukasiniho                                                                                                                                                            |
|  23 |    490.336478 |    161.948167 | Shyamal                                                                                                                                                               |
|  24 |    715.776657 |    488.494628 | Zimices                                                                                                                                                               |
|  25 |    919.934306 |    351.177305 | Christoph Schomburg                                                                                                                                                   |
|  26 |    347.638314 |    175.968980 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
|  27 |     82.098045 |     45.123228 | Ignacio Contreras                                                                                                                                                     |
|  28 |    825.246888 |    622.379986 | Matt Crook                                                                                                                                                            |
|  29 |    814.415359 |     91.834067 | Chris huh                                                                                                                                                             |
|  30 |    643.255129 |    316.487733 | Gareth Monger                                                                                                                                                         |
|  31 |    273.880657 |    291.755457 | Margot Michaud                                                                                                                                                        |
|  32 |    775.646704 |    343.823195 | Zimices                                                                                                                                                               |
|  33 |     94.082661 |    773.822947 | Scott Hartman                                                                                                                                                         |
|  34 |    942.800212 |    573.273722 | Steven Traver                                                                                                                                                         |
|  35 |    334.265668 |    725.683131 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
|  36 |    455.154646 |     73.112336 | Inessa Voet                                                                                                                                                           |
|  37 |    924.710230 |    754.915393 | Chris huh                                                                                                                                                             |
|  38 |    411.813866 |    343.364781 | Jagged Fang Designs                                                                                                                                                   |
|  39 |    559.585480 |    515.921154 | Jagged Fang Designs                                                                                                                                                   |
|  40 |     96.566379 |    524.178383 | Scott Hartman                                                                                                                                                         |
|  41 |    150.799975 |    327.746198 | Ferran Sayol                                                                                                                                                          |
|  42 |    750.093247 |    779.004659 | Jagged Fang Designs                                                                                                                                                   |
|  43 |    315.533426 |    141.406842 | Gareth Monger                                                                                                                                                         |
|  44 |    694.365673 |    559.990660 | Zimices                                                                                                                                                               |
|  45 |    442.491187 |    556.998596 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
|  46 |    335.626643 |    369.677835 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  47 |    560.375974 |    463.206804 | Berivan Temiz                                                                                                                                                         |
|  48 |    275.684131 |    707.083045 | Zimices                                                                                                                                                               |
|  49 |    919.373760 |    128.641000 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
|  50 |    213.890215 |    413.921089 | Matt Crook                                                                                                                                                            |
|  51 |    539.820815 |    777.735998 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
|  52 |    279.560774 |    189.384259 | Scott Hartman                                                                                                                                                         |
|  53 |    191.361879 |    608.332819 | Steven Traver                                                                                                                                                         |
|  54 |    708.470785 |     48.505670 | Markus A. Grohme                                                                                                                                                      |
|  55 |    363.091095 |     24.481720 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  56 |    940.771676 |    228.137758 | Mathieu Pélissié                                                                                                                                                      |
|  57 |    588.820643 |     35.132997 | Scott Hartman                                                                                                                                                         |
|  58 |    907.079327 |    664.922247 | Rebecca Groom                                                                                                                                                         |
|  59 |    804.046032 |    726.983163 | Lukasiniho                                                                                                                                                            |
|  60 |     78.465429 |    146.819784 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  61 |     85.443254 |     79.541009 | Chris huh                                                                                                                                                             |
|  62 |    857.616971 |    520.691979 | Carlos Cano-Barbacil                                                                                                                                                  |
|  63 |    952.724585 |    469.835866 | Manabu Sakamoto                                                                                                                                                       |
|  64 |    620.498287 |    248.416763 | Markus A. Grohme                                                                                                                                                      |
|  65 |    987.369582 |    198.875971 | T. Michael Keesey                                                                                                                                                     |
|  66 |    320.856630 |    426.210124 | Scott Hartman                                                                                                                                                         |
|  67 |    212.240133 |    771.420568 | Lily Hughes                                                                                                                                                           |
|  68 |    569.446553 |    551.872455 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
|  69 |    555.623152 |    401.808968 | Steven Traver                                                                                                                                                         |
|  70 |    108.963636 |     17.337267 | Collin Gross                                                                                                                                                          |
|  71 |     63.684413 |    323.656544 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
|  72 |    619.813533 |    208.713561 | Jagged Fang Designs                                                                                                                                                   |
|  73 |    443.713811 |    752.547314 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  74 |     76.357838 |    668.526105 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  75 |    480.688682 |    471.719373 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  76 |    300.938124 |    613.190345 | T. Michael Keesey                                                                                                                                                     |
|  77 |    501.772773 |     12.759834 | NA                                                                                                                                                                    |
|  78 |    649.429281 |    614.697372 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
|  79 |    894.832548 |    420.548995 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  80 |    170.750105 |    146.493134 | Smokeybjb                                                                                                                                                             |
|  81 |    835.125350 |    358.881961 | L. Shyamal                                                                                                                                                            |
|  82 |    976.690871 |    714.114557 | Alexandre Vong                                                                                                                                                        |
|  83 |    988.303291 |     84.881977 | Maija Karala                                                                                                                                                          |
|  84 |    227.487803 |    119.163311 | Zimices                                                                                                                                                               |
|  85 |    445.180604 |    297.537399 | Alexandre Vong                                                                                                                                                        |
|  86 |    652.545368 |    127.529158 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  87 |    991.741114 |    665.360236 | Ferran Sayol                                                                                                                                                          |
|  88 |    793.325414 |    139.339560 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  89 |     81.097178 |    693.001996 | NA                                                                                                                                                                    |
|  90 |     46.273355 |    172.420278 | NA                                                                                                                                                                    |
|  91 |    140.611917 |    572.611433 | NA                                                                                                                                                                    |
|  92 |    399.340089 |    152.994995 | Beth Reinke                                                                                                                                                           |
|  93 |     68.970107 |    633.992341 | Anna Willoughby                                                                                                                                                       |
|  94 |    775.115382 |    461.202809 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  95 |     48.042946 |    437.909312 | Collin Gross                                                                                                                                                          |
|  96 |    412.021005 |    723.855890 | Chris huh                                                                                                                                                             |
|  97 |    192.148698 |    480.918730 | Margot Michaud                                                                                                                                                        |
|  98 |    929.886440 |    639.140504 | Chris huh                                                                                                                                                             |
|  99 |    346.194723 |    306.442181 | Jagged Fang Designs                                                                                                                                                   |
| 100 |    474.732037 |    783.971613 | Mathew Wedel                                                                                                                                                          |
| 101 |    366.090840 |    289.060361 | Felix Vaux                                                                                                                                                            |
| 102 |    161.720753 |    426.037811 | Matt Crook                                                                                                                                                            |
| 103 |     14.222904 |    622.777480 | Bruno C. Vellutini                                                                                                                                                    |
| 104 |     92.432800 |    717.699631 | CNZdenek                                                                                                                                                              |
| 105 |    544.198959 |    216.430005 | Ben Liebeskind                                                                                                                                                        |
| 106 |     26.289245 |    708.581201 | Rebecca Groom                                                                                                                                                         |
| 107 |     48.646917 |    557.625086 | Benjamint444                                                                                                                                                          |
| 108 |    145.669133 |    496.802070 | Cagri Cevrim                                                                                                                                                          |
| 109 |    459.066376 |    121.764051 | T. Michael Keesey                                                                                                                                                     |
| 110 |     25.798259 |    557.609686 | Renata F. Martins                                                                                                                                                     |
| 111 |    107.752291 |    747.407712 | Steven Traver                                                                                                                                                         |
| 112 |    399.039857 |    487.821442 | NA                                                                                                                                                                    |
| 113 |    445.313901 |    528.027876 | Matt Martyniuk                                                                                                                                                        |
| 114 |    972.882847 |    310.160404 | Margot Michaud                                                                                                                                                        |
| 115 |    823.457859 |     42.763463 | Elisabeth Östman                                                                                                                                                      |
| 116 |    614.843051 |    149.343252 | Emily Willoughby                                                                                                                                                      |
| 117 |    503.206274 |    130.650215 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 118 |    353.500774 |    244.109039 | Gareth Monger                                                                                                                                                         |
| 119 |    134.028410 |    414.837142 | Ferran Sayol                                                                                                                                                          |
| 120 |    770.337854 |    680.227035 | Matt Crook                                                                                                                                                            |
| 121 |    211.837146 |    638.970697 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 122 |    579.229916 |     60.559528 | Shyamal                                                                                                                                                               |
| 123 |    541.658164 |     51.973046 | Jagged Fang Designs                                                                                                                                                   |
| 124 |    573.755607 |    220.670568 | Scott Hartman                                                                                                                                                         |
| 125 |    759.122403 |     79.795264 | T. Michael Keesey                                                                                                                                                     |
| 126 |    887.376361 |    787.029096 | Ieuan Jones                                                                                                                                                           |
| 127 |    189.792060 |    161.570352 | Scott Hartman                                                                                                                                                         |
| 128 |    905.619320 |    720.372936 | Ferran Sayol                                                                                                                                                          |
| 129 |    771.857677 |     32.845400 | NA                                                                                                                                                                    |
| 130 |    781.177481 |    209.418315 | Ferran Sayol                                                                                                                                                          |
| 131 |     97.060700 |    546.048177 | Tasman Dixon                                                                                                                                                          |
| 132 |     19.589803 |     19.281458 | Matt Crook                                                                                                                                                            |
| 133 |    848.192031 |    562.541773 | Matt Crook                                                                                                                                                            |
| 134 |    992.986021 |    506.439207 | Birgit Lang                                                                                                                                                           |
| 135 |    492.064487 |    585.497183 | NA                                                                                                                                                                    |
| 136 |     19.135612 |    479.147960 | NA                                                                                                                                                                    |
| 137 |    888.443956 |    583.146964 | Andy Wilson                                                                                                                                                           |
| 138 |    760.567958 |    658.429499 | Scott Hartman                                                                                                                                                         |
| 139 |    660.935783 |    773.466010 | Matt Crook                                                                                                                                                            |
| 140 |    644.424423 |    515.628910 | T. Michael Keesey                                                                                                                                                     |
| 141 |    421.522246 |    119.445984 | Juan Carlos Jerí                                                                                                                                                      |
| 142 |     37.974334 |    368.469535 | Matt Crook                                                                                                                                                            |
| 143 |    653.456376 |    689.736642 | T. Michael Keesey                                                                                                                                                     |
| 144 |    637.138743 |    161.152389 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 145 |    619.452942 |    544.869897 | Daniel Jaron                                                                                                                                                          |
| 146 |    611.164559 |    532.807956 | Ignacio Contreras                                                                                                                                                     |
| 147 |    194.732873 |     17.513891 | Sarah Werning                                                                                                                                                         |
| 148 |    778.972701 |    570.235579 | Mason McNair                                                                                                                                                          |
| 149 |     28.021583 |    755.611207 | Chase Brownstein                                                                                                                                                      |
| 150 |     35.137992 |    390.488191 | Margot Michaud                                                                                                                                                        |
| 151 |    652.596064 |     77.329403 | Markus A. Grohme                                                                                                                                                      |
| 152 |    275.311216 |    740.068925 | Milton Tan                                                                                                                                                            |
| 153 |    528.931197 |    107.925240 | Tasman Dixon                                                                                                                                                          |
| 154 |    377.230378 |    223.534204 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 155 |    976.994492 |    288.494551 | Steven Traver                                                                                                                                                         |
| 156 |    333.159548 |     37.797560 | Markus A. Grohme                                                                                                                                                      |
| 157 |    486.280495 |    193.756690 | Jagged Fang Designs                                                                                                                                                   |
| 158 |    971.360144 |    627.507518 | Gabriele Midolo                                                                                                                                                       |
| 159 |    517.725583 |     30.203507 | B. Duygu Özpolat                                                                                                                                                      |
| 160 |    364.964276 |    457.066362 | Matt Crook                                                                                                                                                            |
| 161 |    897.386655 |    260.248900 | Matt Crook                                                                                                                                                            |
| 162 |    264.858472 |     44.530725 | NA                                                                                                                                                                    |
| 163 |    230.899849 |    436.322870 | Matt Crook                                                                                                                                                            |
| 164 |    755.607928 |    146.964223 | NA                                                                                                                                                                    |
| 165 |    268.630250 |    124.422702 | Scott Hartman                                                                                                                                                         |
| 166 |    889.715000 |    288.479493 | Chris huh                                                                                                                                                             |
| 167 |    459.565115 |    235.615437 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
| 168 |    737.382472 |     30.873369 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 169 |     37.573692 |    531.409588 | Steven Traver                                                                                                                                                         |
| 170 |    520.823542 |    726.522324 | Danielle Alba                                                                                                                                                         |
| 171 |    630.763649 |    453.385784 | Kanchi Nanjo                                                                                                                                                          |
| 172 |   1007.074545 |    622.487466 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 173 |    738.266289 |    213.310517 | Sarah Werning                                                                                                                                                         |
| 174 |     35.255992 |    285.978975 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 175 |    620.339994 |    102.661882 | Gareth Monger                                                                                                                                                         |
| 176 |    180.546036 |    752.215897 | Henry Lydecker                                                                                                                                                        |
| 177 |    193.346076 |    558.934116 | Maija Karala                                                                                                                                                          |
| 178 |     45.708932 |    579.538818 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 179 |     98.267303 |    122.536444 | Margot Michaud                                                                                                                                                        |
| 180 |    854.679513 |     17.001742 | Birgit Lang                                                                                                                                                           |
| 181 |    662.454315 |     17.785215 | kreidefossilien.de                                                                                                                                                    |
| 182 |    328.828065 |    383.053073 | Pedro de Siracusa                                                                                                                                                     |
| 183 |    799.656254 |    262.818046 | Tasman Dixon                                                                                                                                                          |
| 184 |    814.563301 |    125.281704 | Andy Wilson                                                                                                                                                           |
| 185 |    253.164614 |     24.319272 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 186 |    628.811744 |    721.491269 | Chris huh                                                                                                                                                             |
| 187 |    185.763607 |    392.337700 | Tasman Dixon                                                                                                                                                          |
| 188 |    199.587720 |    727.017615 | Jessica Anne Miller                                                                                                                                                   |
| 189 |   1003.455524 |    540.688587 | Markus A. Grohme                                                                                                                                                      |
| 190 |    841.474268 |    392.806745 | Cagri Cevrim                                                                                                                                                          |
| 191 |    466.861945 |    174.034051 | Dmitry Bogdanov                                                                                                                                                       |
| 192 |    933.471724 |    525.073599 | Jagged Fang Designs                                                                                                                                                   |
| 193 |    259.303528 |     67.752523 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
| 194 |    437.367928 |    175.004938 | Zimices                                                                                                                                                               |
| 195 |    824.676079 |    290.966978 | Chris huh                                                                                                                                                             |
| 196 |    463.333290 |    266.378993 | Ludwik Gąsiorowski                                                                                                                                                    |
| 197 |    997.457844 |      8.753968 | Roderic Page and Lois Page                                                                                                                                            |
| 198 |    257.220598 |    331.850384 | Alexandre Vong                                                                                                                                                        |
| 199 |     98.662794 |    101.693277 | C. Camilo Julián-Caballero                                                                                                                                            |
| 200 |    988.705678 |    327.717309 | Matt Crook                                                                                                                                                            |
| 201 |    493.123555 |    396.037199 | Scott Hartman                                                                                                                                                         |
| 202 |    745.315687 |    298.110968 | Michelle Site                                                                                                                                                         |
| 203 |    684.284045 |     93.127925 | Walter Vladimir                                                                                                                                                       |
| 204 |    625.017029 |    179.984060 | Margot Michaud                                                                                                                                                        |
| 205 |    468.071622 |    579.189271 | Maija Karala                                                                                                                                                          |
| 206 |    156.522679 |    123.787465 | Birgit Lang                                                                                                                                                           |
| 207 |    255.076965 |    575.484590 | Birgit Lang                                                                                                                                                           |
| 208 |    442.242374 |    385.436118 | Matt Crook                                                                                                                                                            |
| 209 |    489.295323 |    637.557262 | Matt Crook                                                                                                                                                            |
| 210 |    993.250508 |    770.562935 | Tauana J. Cunha                                                                                                                                                       |
| 211 |    246.499939 |     92.800609 | Chris huh                                                                                                                                                             |
| 212 |    380.104056 |    247.238998 | Gareth Monger                                                                                                                                                         |
| 213 |    217.280206 |    361.879530 | Tess Linden                                                                                                                                                           |
| 214 |    636.561188 |    738.657800 | Matt Crook                                                                                                                                                            |
| 215 |   1005.906802 |    256.802127 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 216 |    311.271677 |    548.438610 | SauropodomorphMonarch                                                                                                                                                 |
| 217 |    600.138481 |    415.463927 | Zimices                                                                                                                                                               |
| 218 |    924.102336 |    489.575714 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 219 |    938.194931 |    290.163241 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 220 |    824.301215 |      5.835529 | Jagged Fang Designs                                                                                                                                                   |
| 221 |    523.319492 |    749.188140 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 222 |    466.775778 |    613.423766 | Gareth Monger                                                                                                                                                         |
| 223 |      7.108079 |     45.177023 | Birgit Lang                                                                                                                                                           |
| 224 |    603.105983 |    574.004850 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 225 |    363.888491 |    604.692864 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 226 |    200.354692 |    304.825443 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 227 |    786.214068 |    514.039473 | Matt Crook                                                                                                                                                            |
| 228 |    389.865964 |     14.941671 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 229 |    163.577493 |     39.904826 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 230 |     17.239304 |    254.687467 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 231 |     76.967819 |    276.135917 | Jagged Fang Designs                                                                                                                                                   |
| 232 |    963.322582 |    727.761040 | Margot Michaud                                                                                                                                                        |
| 233 |    123.570360 |    158.681439 | Andy Wilson                                                                                                                                                           |
| 234 |    739.435461 |    380.344767 | Sarah Werning                                                                                                                                                         |
| 235 |    848.273575 |    774.309342 | Steven Traver                                                                                                                                                         |
| 236 |    406.415541 |    783.978026 | Collin Gross                                                                                                                                                          |
| 237 |   1004.565877 |    386.454705 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 238 |    688.246987 |    276.018661 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 239 |     63.450654 |    600.081669 | Steven Traver                                                                                                                                                         |
| 240 |    392.910775 |    467.099031 | Ingo Braasch                                                                                                                                                          |
| 241 |    516.103783 |    584.652875 | Karla Martinez                                                                                                                                                        |
| 242 |    453.550163 |    410.155730 | Sarah Werning                                                                                                                                                         |
| 243 |    766.159267 |     16.951367 | Sarah Werning                                                                                                                                                         |
| 244 |    325.902800 |    746.498001 | Nobu Tamura                                                                                                                                                           |
| 245 |    706.744994 |    369.150488 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 246 |    974.681046 |    523.820196 | Jaime Headden                                                                                                                                                         |
| 247 |    783.084614 |      4.190808 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 248 |    432.462484 |    364.491479 | Matt Martyniuk                                                                                                                                                        |
| 249 |    917.266229 |     83.791252 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 250 |     17.238558 |    543.089154 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                      |
| 251 |    860.172471 |    298.177771 | Carlos Cano-Barbacil                                                                                                                                                  |
| 252 |    216.242509 |    198.482638 | Zimices                                                                                                                                                               |
| 253 |    469.145008 |    729.992422 | Milton Tan                                                                                                                                                            |
| 254 |    678.057273 |    126.760116 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 255 |    145.908522 |    259.894783 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 256 |    428.816701 |    661.270247 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 257 |    401.141613 |    601.103390 | Katie S. Collins                                                                                                                                                      |
| 258 |    165.570931 |     19.037567 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 259 |    794.770112 |    767.847760 | Andy Wilson                                                                                                                                                           |
| 260 |    910.283284 |    200.575234 | Andy Wilson                                                                                                                                                           |
| 261 |    401.188613 |    452.965788 | Berivan Temiz                                                                                                                                                         |
| 262 |    139.264015 |    791.310607 | Margot Michaud                                                                                                                                                        |
| 263 |    944.349566 |     51.451779 | Dexter R. Mardis                                                                                                                                                      |
| 264 |    433.760474 |    510.321102 | Zimices                                                                                                                                                               |
| 265 |    705.192370 |     67.732927 | Siobhon Egan                                                                                                                                                          |
| 266 |    289.723561 |     20.947489 | Matt Crook                                                                                                                                                            |
| 267 |    269.658233 |    165.608583 | Markus A. Grohme                                                                                                                                                      |
| 268 |    939.497238 |     71.882637 | T. Michael Keesey                                                                                                                                                     |
| 269 |    437.593114 |    583.175387 | Zimices                                                                                                                                                               |
| 270 |    216.213757 |    574.200076 | Zimices                                                                                                                                                               |
| 271 |    721.704103 |    605.694729 | Tracy A. Heath                                                                                                                                                        |
| 272 |    403.427552 |    200.374487 | Matt Crook                                                                                                                                                            |
| 273 |    367.968648 |    110.031007 | T. Michael Keesey                                                                                                                                                     |
| 274 |    344.735938 |    722.373304 | Christoph Schomburg                                                                                                                                                   |
| 275 |    883.048841 |    695.214960 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 276 |    838.336070 |    148.359827 | NA                                                                                                                                                                    |
| 277 |     33.795069 |    589.072108 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 278 |     47.970447 |    144.136339 | NA                                                                                                                                                                    |
| 279 |   1001.224475 |    427.529618 | Anthony Caravaggi                                                                                                                                                     |
| 280 |   1004.719905 |     32.868927 | T. Michael Keesey                                                                                                                                                     |
| 281 |    971.821328 |    429.689446 | C. Camilo Julián-Caballero                                                                                                                                            |
| 282 |    103.408177 |    146.731298 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
| 283 |    395.340993 |    317.948545 | Cesar Julian                                                                                                                                                          |
| 284 |    357.896208 |    487.323448 | Roberto Díaz Sibaja                                                                                                                                                   |
| 285 |    632.278542 |    779.998714 | Sarah Werning                                                                                                                                                         |
| 286 |    669.524353 |    527.488592 | Andrew A. Farke                                                                                                                                                       |
| 287 |    787.259361 |     54.133462 | T. Michael Keesey                                                                                                                                                     |
| 288 |   1007.661602 |    340.362226 | Gareth Monger                                                                                                                                                         |
| 289 |    754.580497 |    619.118164 | SecretJellyMan                                                                                                                                                        |
| 290 |    102.491416 |    493.934842 | Kamil S. Jaron                                                                                                                                                        |
| 291 |    725.701644 |    626.270261 | Gareth Monger                                                                                                                                                         |
| 292 |     99.764074 |    557.818082 | Zimices                                                                                                                                                               |
| 293 |    868.531113 |    149.945951 | T. Michael Keesey                                                                                                                                                     |
| 294 |    351.435474 |    580.605908 | Matt Dempsey                                                                                                                                                          |
| 295 |    820.382553 |    196.727211 | Ferran Sayol                                                                                                                                                          |
| 296 |    399.767804 |    182.881053 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 297 |    634.659445 |    592.767527 | Gareth Monger                                                                                                                                                         |
| 298 |    535.101987 |    698.054932 | Chris huh                                                                                                                                                             |
| 299 |    372.095762 |    778.380704 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 300 |   1007.083652 |    126.892537 | Zimices                                                                                                                                                               |
| 301 |    190.371218 |    656.593469 | Anthony Caravaggi                                                                                                                                                     |
| 302 |   1011.139626 |    591.930550 | Gareth Monger                                                                                                                                                         |
| 303 |   1006.614640 |    278.800802 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 304 |     35.055972 |    195.705648 | Michele Tobias                                                                                                                                                        |
| 305 |    239.021431 |    144.735263 | Birgit Lang                                                                                                                                                           |
| 306 |    127.748203 |    337.014155 | Iain Reid                                                                                                                                                             |
| 307 |    223.292570 |    502.218953 | Matt Crook                                                                                                                                                            |
| 308 |    961.772957 |    449.332606 | NA                                                                                                                                                                    |
| 309 |    752.354976 |    394.545840 | M Kolmann                                                                                                                                                             |
| 310 |    217.675773 |     11.893605 | Kai R. Caspar                                                                                                                                                         |
| 311 |    336.510372 |    263.842402 | Gareth Monger                                                                                                                                                         |
| 312 |    283.402242 |    357.553600 | Gareth Monger                                                                                                                                                         |
| 313 |    760.141932 |    175.830075 | Margot Michaud                                                                                                                                                        |
| 314 |    230.539017 |    524.059536 | Crystal Maier                                                                                                                                                         |
| 315 |    590.342664 |    636.343509 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 316 |    330.085577 |    590.946577 | NA                                                                                                                                                                    |
| 317 |    629.134909 |    126.867398 | Tyler Greenfield                                                                                                                                                      |
| 318 |    894.442885 |    614.724320 | Dmitry Bogdanov                                                                                                                                                       |
| 319 |    163.079615 |    284.128724 | Zimices                                                                                                                                                               |
| 320 |    574.454771 |      6.758978 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 321 |    143.136214 |    752.704656 | T. Michael Keesey                                                                                                                                                     |
| 322 |    919.624741 |    702.527616 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 323 |    785.976113 |    302.746479 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 324 |    611.960479 |     68.812263 | xgirouxb                                                                                                                                                              |
| 325 |     56.001191 |    476.170079 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
| 326 |    198.156341 |    280.744016 | T. Michael Keesey                                                                                                                                                     |
| 327 |    824.623534 |    307.252753 | Ferran Sayol                                                                                                                                                          |
| 328 |    691.589081 |    784.544121 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 329 |    537.855022 |    323.988980 | Mathieu Pélissié                                                                                                                                                      |
| 330 |    530.528041 |    387.982250 | Ferran Sayol                                                                                                                                                          |
| 331 |    393.475576 |    718.270209 | Jack Mayer Wood                                                                                                                                                       |
| 332 |    656.703731 |    183.456514 | Maija Karala                                                                                                                                                          |
| 333 |     27.576977 |    789.846142 | Emily Willoughby                                                                                                                                                      |
| 334 |    790.097534 |    493.269296 | Kai R. Caspar                                                                                                                                                         |
| 335 |    129.070164 |    560.406607 | Andy Wilson                                                                                                                                                           |
| 336 |    538.037618 |    177.927812 | Ferran Sayol                                                                                                                                                          |
| 337 |    192.829116 |    516.582752 | Harold N Eyster                                                                                                                                                       |
| 338 |     66.116929 |    382.729639 | Matt Crook                                                                                                                                                            |
| 339 |    200.730833 |    538.450313 | Nobu Tamura                                                                                                                                                           |
| 340 |    165.071556 |     50.134996 | Markus A. Grohme                                                                                                                                                      |
| 341 |    619.762874 |     87.396918 | Birgit Lang                                                                                                                                                           |
| 342 |    361.421573 |    479.362186 | Jakovche                                                                                                                                                              |
| 343 |    798.433056 |    296.873175 | Yan Wong                                                                                                                                                              |
| 344 |    336.789588 |    789.236621 | Siobhon Egan                                                                                                                                                          |
| 345 |    142.417916 |    245.511553 | Markus A. Grohme                                                                                                                                                      |
| 346 |    816.001960 |    557.107931 | Zimices                                                                                                                                                               |
| 347 |     17.921464 |    149.963026 | Margot Michaud                                                                                                                                                        |
| 348 |    165.703575 |    533.230487 | Maxime Dahirel                                                                                                                                                        |
| 349 |    761.214588 |    768.282589 | Margot Michaud                                                                                                                                                        |
| 350 |    644.088082 |    215.372070 | NA                                                                                                                                                                    |
| 351 |     94.644412 |    293.051590 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 352 |    292.473753 |    180.265171 | Andy Wilson                                                                                                                                                           |
| 353 |    409.875206 |    682.961629 | Beth Reinke                                                                                                                                                           |
| 354 |    303.504773 |    121.825160 | Margot Michaud                                                                                                                                                        |
| 355 |    370.433215 |    712.324480 | Gareth Monger                                                                                                                                                         |
| 356 |    691.308909 |     12.569537 | Markus A. Grohme                                                                                                                                                      |
| 357 |    231.267786 |     80.050005 | Jagged Fang Designs                                                                                                                                                   |
| 358 |    321.437582 |    405.836608 | Markus A. Grohme                                                                                                                                                      |
| 359 |     88.218933 |    109.422390 | Sarah Werning                                                                                                                                                         |
| 360 |    349.007099 |    224.473198 | Chris huh                                                                                                                                                             |
| 361 |    953.814098 |    406.238921 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 362 |    633.577636 |    524.068932 | Rebecca Groom                                                                                                                                                         |
| 363 |    716.740161 |    299.843947 | Zimices                                                                                                                                                               |
| 364 |    836.362398 |     68.238925 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 365 |    188.857436 |    639.918313 | CNZdenek                                                                                                                                                              |
| 366 |    246.826535 |    785.777327 | Steven Traver                                                                                                                                                         |
| 367 |    218.724733 |    255.957792 | NA                                                                                                                                                                    |
| 368 |    922.112086 |    623.125637 | Jagged Fang Designs                                                                                                                                                   |
| 369 |    559.667827 |    206.121210 | Andy Wilson                                                                                                                                                           |
| 370 |    959.108023 |    789.730645 | Markus A. Grohme                                                                                                                                                      |
| 371 |     38.840474 |    272.537111 | Kanchi Nanjo                                                                                                                                                          |
| 372 |    602.372665 |    761.630041 | Margot Michaud                                                                                                                                                        |
| 373 |    861.353954 |    119.330211 | Margot Michaud                                                                                                                                                        |
| 374 |    649.934854 |    668.754139 | Collin Gross                                                                                                                                                          |
| 375 |    823.680352 |    482.180912 | Chris huh                                                                                                                                                             |
| 376 |    280.695329 |    533.367161 | Kai R. Caspar                                                                                                                                                         |
| 377 |    480.197140 |    217.434975 | Mathew Wedel                                                                                                                                                          |
| 378 |    330.619633 |    460.332459 | Emily Willoughby                                                                                                                                                      |
| 379 |    649.022041 |    434.536028 | Jagged Fang Designs                                                                                                                                                   |
| 380 |    952.307528 |    694.448911 | Steven Traver                                                                                                                                                         |
| 381 |    989.402028 |     53.763720 | Birgit Lang                                                                                                                                                           |
| 382 |     43.843877 |    729.622409 | Emily Willoughby                                                                                                                                                      |
| 383 |    868.102653 |     82.811982 | Scott Hartman                                                                                                                                                         |
| 384 |    796.729336 |    536.612169 | Robert Gay                                                                                                                                                            |
| 385 |    668.716283 |    592.243023 | Margot Michaud                                                                                                                                                        |
| 386 |    609.550074 |    783.055092 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                     |
| 387 |    563.328877 |     18.622249 | Steven Traver                                                                                                                                                         |
| 388 |    579.365367 |    755.260960 | Sarah Werning                                                                                                                                                         |
| 389 |    473.993851 |    378.171689 | Ignacio Contreras                                                                                                                                                     |
| 390 |    394.178265 |    433.279182 | Armin Reindl                                                                                                                                                          |
| 391 |    385.699353 |    568.387446 | NA                                                                                                                                                                    |
| 392 |    885.160805 |    399.635444 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 393 |    335.367516 |    297.257798 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 394 |    567.559415 |    788.950760 | (after Spotila 2004)                                                                                                                                                  |
| 395 |    386.785122 |    738.791035 | Markus A. Grohme                                                                                                                                                      |
| 396 |    414.312948 |    303.388052 | Kamil S. Jaron                                                                                                                                                        |
| 397 |    639.319477 |    711.585440 | Margot Michaud                                                                                                                                                        |
| 398 |     65.890013 |    646.639657 | Henry Lydecker                                                                                                                                                        |
| 399 |    725.647470 |     15.320545 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 400 |    119.312355 |    344.446696 | Gareth Monger                                                                                                                                                         |
| 401 |    265.738155 |    407.679990 | Melissa Ingala                                                                                                                                                        |
| 402 |    209.382028 |     91.819635 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 403 |    619.054678 |     15.214862 | Gareth Monger                                                                                                                                                         |
| 404 |    569.998443 |    498.165315 | Jagged Fang Designs                                                                                                                                                   |
| 405 |    186.326347 |    527.690890 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 406 |    564.594590 |    728.018522 | Zimices                                                                                                                                                               |
| 407 |    552.618227 |    539.007813 | B. Duygu Özpolat                                                                                                                                                      |
| 408 |    502.230022 |    793.038398 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 409 |    799.163026 |    794.874016 | Gareth Monger                                                                                                                                                         |
| 410 |    598.334802 |    502.907137 | Margot Michaud                                                                                                                                                        |
| 411 |    209.786133 |    175.514499 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 412 |   1005.095623 |    310.706663 | Margot Michaud                                                                                                                                                        |
| 413 |    993.770947 |    748.021397 | Jagged Fang Designs                                                                                                                                                   |
| 414 |    219.107618 |    732.841613 | NA                                                                                                                                                                    |
| 415 |    207.383466 |    789.734368 | NA                                                                                                                                                                    |
| 416 |    190.384450 |    576.400299 | NA                                                                                                                                                                    |
| 417 |    528.461376 |    121.087869 | Scott Hartman                                                                                                                                                         |
| 418 |    928.212795 |    439.973102 | Markus A. Grohme                                                                                                                                                      |
| 419 |    458.730453 |     26.856896 | Oscar Sanisidro                                                                                                                                                       |
| 420 |    920.941280 |    189.398174 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 421 |    949.913270 |    539.446196 | xgirouxb                                                                                                                                                              |
| 422 |    983.486337 |    354.937290 | Manabu Sakamoto                                                                                                                                                       |
| 423 |    704.767426 |    581.228368 | Markus A. Grohme                                                                                                                                                      |
| 424 |     80.737117 |    751.798670 | Becky Barnes                                                                                                                                                          |
| 425 |    914.441940 |    604.931879 | Felix Vaux                                                                                                                                                            |
| 426 |    587.231006 |    277.324727 | Zimices                                                                                                                                                               |
| 427 |    797.395729 |    113.174923 | Zimices                                                                                                                                                               |
| 428 |      7.419769 |     85.522360 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 429 |    963.202572 |    497.955124 | Chris A. Hamilton                                                                                                                                                     |
| 430 |    545.351972 |    576.341295 | Matt Crook                                                                                                                                                            |
| 431 |     45.204858 |     31.445628 | Ignacio Contreras                                                                                                                                                     |
| 432 |     30.579272 |    500.491422 | Scott Hartman                                                                                                                                                         |
| 433 |    658.644242 |    737.184839 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 434 |    645.192138 |    486.653466 | Matt Crook                                                                                                                                                            |
| 435 |    169.954672 |    296.834510 | Tasman Dixon                                                                                                                                                          |
| 436 |    521.959819 |     51.536505 | Gareth Monger                                                                                                                                                         |
| 437 |    963.307871 |    269.850527 | C. Camilo Julián-Caballero                                                                                                                                            |
| 438 |    798.566158 |    684.089246 | Jagged Fang Designs                                                                                                                                                   |
| 439 |    125.134638 |    692.351565 | Andrés Sánchez                                                                                                                                                        |
| 440 |    549.753759 |    224.219832 | Michelle Site                                                                                                                                                         |
| 441 |    405.789603 |    130.120448 | Mathew Wedel                                                                                                                                                          |
| 442 |    320.621593 |    731.068619 | Zimices                                                                                                                                                               |
| 443 |    263.702276 |    727.444737 | Iain Reid                                                                                                                                                             |
| 444 |    752.628105 |    673.861324 | Birgit Lang                                                                                                                                                           |
| 445 |    684.775368 |    107.976155 | Margot Michaud                                                                                                                                                        |
| 446 |    953.832897 |    516.909794 | Sarah Werning                                                                                                                                                         |
| 447 |    624.454069 |    416.823044 | Gopal Murali                                                                                                                                                          |
| 448 |    183.595566 |    127.586833 | Mathew Wedel                                                                                                                                                          |
| 449 |    690.400746 |     20.771036 | T. Tischler                                                                                                                                                           |
| 450 |    863.723251 |    436.654122 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 451 |    751.166622 |    650.072019 | Scott Hartman                                                                                                                                                         |
| 452 |     37.852518 |     68.253301 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 453 |    760.003533 |    242.033787 | Gareth Monger                                                                                                                                                         |
| 454 |    898.298857 |    220.922456 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 455 |    715.904464 |    288.163156 | Scott Hartman                                                                                                                                                         |
| 456 |    862.596787 |    445.896119 | Chris huh                                                                                                                                                             |
| 457 |    284.290404 |    787.688567 | Zimices                                                                                                                                                               |
| 458 |    407.273613 |    575.562783 | Andrew A. Farke                                                                                                                                                       |
| 459 |    829.872858 |    282.924827 | Tasman Dixon                                                                                                                                                          |
| 460 |    174.567027 |    795.174697 | Ieuan Jones                                                                                                                                                           |
| 461 |     70.907144 |    537.192653 | Zimices                                                                                                                                                               |
| 462 |    886.220770 |     75.789754 | Rebecca Groom                                                                                                                                                         |
| 463 |    931.826536 |      7.926647 | Maija Karala                                                                                                                                                          |
| 464 |    257.470836 |    353.062109 | Chris huh                                                                                                                                                             |
| 465 |    946.644157 |     42.651843 | NA                                                                                                                                                                    |
| 466 |    487.815303 |    238.561826 | T. Michael Keesey                                                                                                                                                     |
| 467 |    391.670822 |    794.960293 | Margot Michaud                                                                                                                                                        |
| 468 |    924.443019 |    168.933958 | Matt Dempsey                                                                                                                                                          |
| 469 |    997.037944 |    477.633473 | Caleb M. Brown                                                                                                                                                        |
| 470 |   1006.900915 |    356.438426 | Alex Slavenko                                                                                                                                                         |
| 471 |    382.554591 |    417.344325 | Margot Michaud                                                                                                                                                        |
| 472 |    869.964833 |    325.459904 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 473 |    349.366349 |    623.805421 | Margot Michaud                                                                                                                                                        |
| 474 |     47.819724 |    704.354989 | Oscar Sanisidro                                                                                                                                                       |
| 475 |    869.061829 |    738.847140 | Mathilde Cordellier                                                                                                                                                   |
| 476 |    567.788861 |    228.447146 | Ignacio Contreras                                                                                                                                                     |
| 477 |    786.986849 |    251.522854 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 478 |     16.008565 |    193.758729 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 479 |    200.428249 |    292.395825 | Tasman Dixon                                                                                                                                                          |
| 480 |    732.451076 |    765.920212 | Felix Vaux                                                                                                                                                            |
| 481 |    242.287051 |    678.568573 | Maija Karala                                                                                                                                                          |
| 482 |    107.885429 |    646.708253 | Matus Valach                                                                                                                                                          |
| 483 |    989.670729 |    129.426689 | Matt Crook                                                                                                                                                            |
| 484 |    122.529738 |    171.428964 | Lisa Byrne                                                                                                                                                            |
| 485 |    804.962937 |     58.190199 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 486 |     25.450315 |    418.575344 | Frank Denota                                                                                                                                                          |
| 487 |     20.724455 |    689.038072 | Zimices                                                                                                                                                               |
| 488 |    928.041213 |    613.219228 | Caleb M. Brown                                                                                                                                                        |
| 489 |    384.273546 |    506.858620 | Jagged Fang Designs                                                                                                                                                   |
| 490 |     19.566350 |    229.310347 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 491 |    898.843538 |      9.228330 | Gareth Monger                                                                                                                                                         |
| 492 |    134.671747 |     56.906017 | Ferran Sayol                                                                                                                                                          |
| 493 |     20.017596 |    452.561837 | Jagged Fang Designs                                                                                                                                                   |
| 494 |    466.274763 |    650.033580 | Matt Crook                                                                                                                                                            |
| 495 |    506.588578 |    530.807323 | Jimmy Bernot                                                                                                                                                          |
| 496 |    452.051380 |    352.284955 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 497 |     21.239064 |    400.190168 | Riccardo Percudani                                                                                                                                                    |
| 498 |    253.978027 |    252.975474 | Jagged Fang Designs                                                                                                                                                   |
| 499 |     31.833385 |    597.857638 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 500 |    792.545376 |     21.687437 | Emily Willoughby                                                                                                                                                      |
| 501 |    170.183929 |     28.217307 | Emily Willoughby                                                                                                                                                      |
| 502 |    181.549563 |    736.081267 | Sarah Werning                                                                                                                                                         |
| 503 |    442.961998 |    793.680085 | Jagged Fang Designs                                                                                                                                                   |
| 504 |     48.228455 |    380.991109 | Tasman Dixon                                                                                                                                                          |
| 505 |    999.328910 |    447.653952 | Iain Reid                                                                                                                                                             |
| 506 |     25.206403 |    515.255164 | Margot Michaud                                                                                                                                                        |
| 507 |    850.961806 |     40.456770 | Matt Crook                                                                                                                                                            |
| 508 |    135.305086 |    376.966591 | Markus A. Grohme                                                                                                                                                      |
| 509 |    649.535878 |    574.062886 | Jagged Fang Designs                                                                                                                                                   |
| 510 |    467.781385 |    565.164340 | Renata F. Martins                                                                                                                                                     |
| 511 |    503.431242 |    713.211721 | Matt Dempsey                                                                                                                                                          |
| 512 |    882.882237 |     92.501454 | NA                                                                                                                                                                    |
| 513 |    904.898865 |    771.491912 | T. Michael Keesey                                                                                                                                                     |
| 514 |    461.463595 |    132.096587 | Scott Hartman                                                                                                                                                         |
| 515 |    628.293855 |    274.718254 | Markus A. Grohme                                                                                                                                                      |
| 516 |    692.898175 |    602.194636 | NA                                                                                                                                                                    |
| 517 |    958.944114 |     13.694702 | Carlos Cano-Barbacil                                                                                                                                                  |
| 518 |    801.035161 |    275.591028 | Kent Elson Sorgon                                                                                                                                                     |
| 519 |     94.619104 |    325.487099 | Jagged Fang Designs                                                                                                                                                   |
| 520 |    370.765387 |    328.278634 | NA                                                                                                                                                                    |
| 521 |     18.876490 |    411.028085 | Ignacio Contreras                                                                                                                                                     |
| 522 |    638.851472 |    375.897000 | T. Michael Keesey                                                                                                                                                     |
| 523 |    361.531447 |    205.468723 | Gareth Monger                                                                                                                                                         |
| 524 |    382.804846 |     79.957408 | Michelle Site                                                                                                                                                         |
| 525 |    141.251656 |    227.740821 | Ferran Sayol                                                                                                                                                          |
| 526 |    839.683607 |    687.103172 | White Wolf                                                                                                                                                            |
| 527 |    381.882690 |    138.585839 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 528 |    361.275216 |    567.194412 | C. Camilo Julián-Caballero                                                                                                                                            |
| 529 |    606.802831 |    368.642762 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 530 |    797.655338 |     73.207660 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 531 |     32.512103 |    212.953124 | Michelle Site                                                                                                                                                         |
| 532 |    683.202660 |    161.459214 | Matt Crook                                                                                                                                                            |
| 533 |    691.695340 |    628.549848 | Chris huh                                                                                                                                                             |
| 534 |    414.310749 |    521.197282 | Ingo Braasch                                                                                                                                                          |
| 535 |    576.941458 |    533.121770 | Scott Hartman                                                                                                                                                         |
| 536 |    282.382052 |    645.797682 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 537 |    967.136890 |    679.418449 | C. Camilo Julián-Caballero                                                                                                                                            |
| 538 |     75.797659 |    193.843904 | Scott Hartman                                                                                                                                                         |
| 539 |     50.658940 |    163.740443 | NA                                                                                                                                                                    |
| 540 |    275.393590 |    155.345708 | Scott Hartman                                                                                                                                                         |
| 541 |    555.442301 |    762.541294 | Zimices                                                                                                                                                               |
| 542 |    393.483326 |     66.289640 | Gareth Monger                                                                                                                                                         |
| 543 |    802.412344 |    445.794341 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 544 |    457.267720 |    537.147542 | Zimices                                                                                                                                                               |
| 545 |    413.911340 |    327.367088 | Ignacio Contreras                                                                                                                                                     |
| 546 |    440.412226 |    248.182435 | Chris huh                                                                                                                                                             |
| 547 |    995.129471 |    401.373174 | Chris huh                                                                                                                                                             |
| 548 |    432.424085 |     21.343711 | L. Shyamal                                                                                                                                                            |
| 549 |    774.306352 |    158.921751 | Scott Hartman                                                                                                                                                         |
| 550 |    304.270315 |     51.152773 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 551 |    819.294836 |    436.602388 | Scott Hartman                                                                                                                                                         |

    #> Your tweet has been posted!
