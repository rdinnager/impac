
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

Kamil S. Jaron, Steven Coombs, L. Shyamal, Tasman Dixon, Martin Kevil,
T. Michael Keesey, Zimices, Natalie Claunch, Jose Carlos Arenas-Monroy,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Matt Crook, Steven
Traver, Gareth Monger, Noah Schlottman, photo by Antonio Guillén, Margot
Michaud, Markus A. Grohme, Rebecca Groom, Ferran Sayol, Joanna Wolfe,
Jagged Fang Designs, Manabu Sakamoto, Michelle Site, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Kailah Thorn & Ben
King, Tyler McCraney, Lukasiniho, Hans Hillewaert (vectorized by T.
Michael Keesey), Jon M Laurent, Scott Hartman, Kai R. Caspar, Emily
Willoughby, Nobu Tamura (vectorized by T. Michael Keesey), Alexander
Schmidt-Lebuhn, Milton Tan, Chris huh, Ignacio Contreras, xgirouxb,
Ghedoghedo (vectorized by T. Michael Keesey), Yan Wong (vectorization)
from 1873 illustration, Alex Slavenko, Michael Wolf (photo), Hans
Hillewaert (editing), T. Michael Keesey (vectorization), Stanton F. Fink
(vectorized by T. Michael Keesey), Eduard Solà (vectorized by T. Michael
Keesey), Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Shyamal, T. Michael Keesey (after Mivart), Nobu Tamura,
vectorized by Zimices, Sarah Werning, Beth Reinke, Tauana J. Cunha, NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), Amanda Katzer, Andrew A. Farke, modified from
original by Robert Bruce Horsfall, from Scott 1912, Qiang Ou, Conty
(vectorized by T. Michael Keesey), Dantheman9758 (vectorized by T.
Michael Keesey), Yan Wong, Andrew A. Farke, Bryan Carstens, Gabriela
Palomo-Munoz, Darren Naish (vectorized by T. Michael Keesey), Ludwik
Gasiorowski, T. Michael Keesey (after C. De Muizon), Jonathan Wells, I.
Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Yan Wong from
SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo), Mathilde
Cordellier, NOAA (vectorized by T. Michael Keesey), Maxime Dahirel,
Armin Reindl, Aviceda (vectorized by T. Michael Keesey), Jack Mayer
Wood, Katie S. Collins, Sharon Wegner-Larsen, Dmitry Bogdanov, Sebastian
Stabinger, Michele M Tobias, Jaime Headden, Diego Fontaneto, Elisabeth
A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Obsidian Soul (vectorized by T. Michael Keesey), Juan Carlos Jerí, Henry
Fairfield Osborn, vectorized by Zimices, Jake Warner, Ghedoghedo,
vectorized by Zimices, Matthew E. Clapham, Ben Liebeskind, Gordon E.
Robertson, Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on
iNaturalist, Campbell Fleming, Tony Ayling (vectorized by T. Michael
Keesey), Patrick Strutzenberger, Warren H (photography), T. Michael
Keesey (vectorization), T. Michael Keesey, from a photograph by Thea
Boodhoo, Emil Schmidt (vectorized by Maxime Dahirel), Kevin Sánchez,
Lafage, CNZdenek, George Edward Lodge (vectorized by T. Michael Keesey),
Rainer Schoch, Matt Wilkins, Ingo Braasch, Noah Schlottman, photo from
Casey Dunn, Caleb M. Brown, Eduard Solà Vázquez, vectorised by Yan Wong,
Matt Martyniuk (vectorized by T. Michael Keesey), Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), DW Bapst (modified from Bulman, 1970), Nobu Tamura, Sergio A.
Muñoz-Gómez, Giant Blue Anteater (vectorized by T. Michael Keesey), B
Kimmel, James R. Spotila and Ray Chatterji, Robert Bruce Horsfall,
vectorized by Zimices, Tracy A. Heath, Scott Hartman, modified by T.
Michael Keesey, Almandine (vectorized by T. Michael Keesey), Scott Reid,
Manabu Bessho-Uehara, Rebecca Groom (Based on Photo by Andreas Trepte),
Felix Vaux, Steven Blackwood, Roberto Díaz Sibaja, Andrew Farke and
Joseph Sertich, Douglas Brown (modified by T. Michael Keesey), Birgit
Lang, Jessica Anne Miller, Mathieu Basille, Sean McCann, Matt Celeskey,
J. J. Harrison (photo) & T. Michael Keesey, Dave Angelini, Becky Barnes,
L.M. Davalos, Melissa Broussard, Conty, Carlos Cano-Barbacil, Didier
Descouens (vectorized by T. Michael Keesey), Mo Hassan, Pearson Scott
Foresman (vectorized by T. Michael Keesey), DW Bapst (Modified from
photograph taken by Charles Mitchell), Yan Wong from drawing by T. F.
Zimmermann, Dmitry Bogdanov, vectorized by Zimices, Nobu Tamura
(modified by T. Michael Keesey), Mali’o Kodis, image from Brockhaus and
Efron Encyclopedic Dictionary, Cesar Julian, Matt Wilkins (photo by
Patrick Kavanagh), Mattia Menchetti, Mali’o Kodis, drawing by Manvir
Singh, Griensteidl and T. Michael Keesey, Brian Gratwicke (photo) and T.
Michael Keesey (vectorization), Steven Haddock • Jellywatch.org, Pete
Buchholz, Konsta Happonen, from a CC-BY-NC image by pelhonen on
iNaturalist, Harold N Eyster, Chase Brownstein, Collin Gross, Moussa
Direct Ltd. (photography) and T. Michael Keesey (vectorization), Tyler
Greenfield, Michele Tobias, Mathew Wedel, Mary Harrsch (modified by T.
Michael Keesey), Cathy, Christoph Schomburg, Zachary Quigley,
Terpsichores, Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael
Keesey), Mariana Ruiz Villarreal, Arthur S. Brum, Dmitry Bogdanov
(modified by T. Michael Keesey), James Neenan, Smokeybjb (vectorized by
T. Michael Keesey), Nick Schooler, Oscar Sanisidro, Robert Bruce
Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the
Western Hemisphere”, Hans Hillewaert (photo) and T. Michael Keesey
(vectorization), T. Michael Keesey (photo by Darren Swim), Cristina
Guijarro, Robert Gay, François Michonneau, Kanchi Nanjo, Oliver
Griffith, Taro Maeda, Tyler Greenfield and Dean Schnabel, U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette), Ian
Burt (original) and T. Michael Keesey (vectorization), Iain Reid, Derek
Bakken (photograph) and T. Michael Keesey (vectorization), Mali’o Kodis,
photograph property of National Museums of Northern Ireland, Kent Elson
Sorgon, Tommaso Cancellario, Anthony Caravaggi, nicubunu, Jay Matternes
(modified by T. Michael Keesey), Christopher Laumer (vectorized by T.
Michael Keesey), C. Camilo Julián-Caballero, Neil Kelley, Mason McNair,
Luis Cunha, FunkMonk, Y. de Hoev. (vectorized by T. Michael Keesey),
Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Servien (vectorized by T. Michael Keesey), Lily Hughes,
Tyler Greenfield and Scott Hartman, Jimmy Bernot, Inessa Voet, C.
Abraczinskas, Francisco Gascó (modified by Michael P. Taylor),
Apokryltaros (vectorized by T. Michael Keesey), Jaime Headden
(vectorized by T. Michael Keesey), Arthur Grosset (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Michael Ströck
(vectorized by T. Michael Keesey), Frank Förster, Ghedo and T. Michael
Keesey, Verdilak, Stanton F. Fink, vectorized by Zimices, Auckland
Museum, S.Martini, Darren Naish (vectorize by T. Michael Keesey), Pedro
de Siracusa, Maija Karala, Original drawing by Antonov, vectorized by
Roberto Díaz Sibaja, Danielle Alba, Stemonitis (photography) and T.
Michael Keesey (vectorization), Crystal Maier, Original drawing by
Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Sibi (vectorized by
T. Michael Keesey), M Kolmann, Tim Bertelink (modified by T. Michael
Keesey), Timothy Knepp (vectorized by T. Michael Keesey), T. Michael
Keesey (after James & al.), Greg Schechter (original photo), Renato
Santos (vector silhouette), Tambja (vectorized by T. Michael Keesey),
Mercedes Yrayzoz (vectorized by T. Michael Keesey), Mark Hannaford
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Brad McFeeters (vectorized by T. Michael Keesey), Scarlet23
(vectorized by T. Michael Keesey), Trond R. Oskars, Ron Holmes/U. S.
Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Michael Scroggie, Geoff Shaw,
\<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T.
Michael Keesey), Gregor Bucher, Max Farnworth, Karl Ragnar Gjertsen
(vectorized by T. Michael Keesey), Baheerathan Murugavel, Matt
Martyniuk, E. Lear, 1819 (vectorization by Yan Wong), Kailah Thorn &
Mark Hutchinson, Chloé Schmidt, Mali’o Kodis, image from the
Biodiversity Heritage Library, Roberto Diaz Sibaja, based on Domser

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    393.678613 |    657.292541 | Kamil S. Jaron                                                                                                                                                        |
|   2 |    368.383679 |    742.461965 | Steven Coombs                                                                                                                                                         |
|   3 |    887.738208 |    442.607204 | L. Shyamal                                                                                                                                                            |
|   4 |    313.759382 |    452.634610 | Tasman Dixon                                                                                                                                                          |
|   5 |    190.463713 |    569.950520 | Martin Kevil                                                                                                                                                          |
|   6 |    640.331038 |    269.587282 | T. Michael Keesey                                                                                                                                                     |
|   7 |    690.123438 |    697.684517 | Zimices                                                                                                                                                               |
|   8 |    448.982196 |    452.712750 | Natalie Claunch                                                                                                                                                       |
|   9 |    945.823784 |    293.707348 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  10 |    407.690583 |    324.109381 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  11 |    194.970692 |    329.755244 | Matt Crook                                                                                                                                                            |
|  12 |    764.964697 |     92.173551 | Steven Traver                                                                                                                                                         |
|  13 |    798.904478 |    543.873439 | Gareth Monger                                                                                                                                                         |
|  14 |    317.193165 |     84.920284 | T. Michael Keesey                                                                                                                                                     |
|  15 |    658.143883 |     49.845312 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
|  16 |    895.808480 |    582.654809 | Margot Michaud                                                                                                                                                        |
|  17 |    883.873531 |    719.522023 | Tasman Dixon                                                                                                                                                          |
|  18 |    817.363587 |    290.288256 | Matt Crook                                                                                                                                                            |
|  19 |    132.217014 |    692.849821 | Markus A. Grohme                                                                                                                                                      |
|  20 |    464.837474 |    184.600566 | Rebecca Groom                                                                                                                                                         |
|  21 |    568.262155 |    511.250147 | Margot Michaud                                                                                                                                                        |
|  22 |    254.874811 |    502.680405 | NA                                                                                                                                                                    |
|  23 |    577.663867 |     93.276535 | Ferran Sayol                                                                                                                                                          |
|  24 |    114.184584 |    117.370346 | Matt Crook                                                                                                                                                            |
|  25 |    661.496529 |    351.148959 | Tasman Dixon                                                                                                                                                          |
|  26 |     76.608161 |    483.798888 | Joanna Wolfe                                                                                                                                                          |
|  27 |    731.601563 |    451.664860 | L. Shyamal                                                                                                                                                            |
|  28 |     68.271394 |    293.706168 | Ferran Sayol                                                                                                                                                          |
|  29 |    413.727147 |    159.911691 | Jagged Fang Designs                                                                                                                                                   |
|  30 |    933.674668 |     86.453360 | Manabu Sakamoto                                                                                                                                                       |
|  31 |    661.768096 |    453.383782 | Michelle Site                                                                                                                                                         |
|  32 |    229.421216 |    213.397542 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
|  33 |    220.043798 |     65.065013 | Kailah Thorn & Ben King                                                                                                                                               |
|  34 |    496.588738 |    230.431668 | Markus A. Grohme                                                                                                                                                      |
|  35 |    333.889695 |    404.431267 | Tyler McCraney                                                                                                                                                        |
|  36 |    958.977554 |    656.121827 | Lukasiniho                                                                                                                                                            |
|  37 |    217.722132 |    637.863154 | Lukasiniho                                                                                                                                                            |
|  38 |    343.254233 |    205.788555 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
|  39 |    541.996468 |    689.253628 | Jon M Laurent                                                                                                                                                         |
|  40 |    820.324116 |    685.698349 | Gareth Monger                                                                                                                                                         |
|  41 |    598.101534 |    622.056169 | Scott Hartman                                                                                                                                                         |
|  42 |    634.132986 |    177.132286 | Scott Hartman                                                                                                                                                         |
|  43 |    661.061970 |    583.782202 | Kai R. Caspar                                                                                                                                                         |
|  44 |    258.716570 |    723.428874 | Emily Willoughby                                                                                                                                                      |
|  45 |    460.675421 |     84.656647 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  46 |    842.958152 |    142.954834 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  47 |    440.515980 |    541.773227 | NA                                                                                                                                                                    |
|  48 |    102.724756 |     52.647348 | Emily Willoughby                                                                                                                                                      |
|  49 |     71.072341 |    715.307336 | Jagged Fang Designs                                                                                                                                                   |
|  50 |    903.573458 |    370.921554 | NA                                                                                                                                                                    |
|  51 |    531.009133 |    399.973714 | Joanna Wolfe                                                                                                                                                          |
|  52 |     74.094930 |    614.259636 | Steven Traver                                                                                                                                                         |
|  53 |    720.356724 |    254.874050 | Milton Tan                                                                                                                                                            |
|  54 |    201.638951 |    457.947018 | Scott Hartman                                                                                                                                                         |
|  55 |    692.958175 |    223.309959 | Gareth Monger                                                                                                                                                         |
|  56 |    763.551209 |    644.289970 | Chris huh                                                                                                                                                             |
|  57 |    765.063962 |    357.748912 | NA                                                                                                                                                                    |
|  58 |    453.071503 |     34.956627 | Ignacio Contreras                                                                                                                                                     |
|  59 |    943.531475 |     27.936710 | Milton Tan                                                                                                                                                            |
|  60 |    599.181216 |    419.289179 | xgirouxb                                                                                                                                                              |
|  61 |    513.473845 |    767.233575 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  62 |    342.991301 |    616.543343 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
|  63 |    190.639610 |    404.255403 | Alex Slavenko                                                                                                                                                         |
|  64 |     71.635974 |    383.245727 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
|  65 |    116.959891 |    770.171740 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
|  66 |     92.701339 |    223.855832 | Markus A. Grohme                                                                                                                                                      |
|  67 |    992.838356 |    423.938350 | Gareth Monger                                                                                                                                                         |
|  68 |    483.842532 |    146.336050 | Chris huh                                                                                                                                                             |
|  69 |    895.746374 |    213.743599 | Gareth Monger                                                                                                                                                         |
|  70 |     71.183340 |    107.963270 | Jagged Fang Designs                                                                                                                                                   |
|  71 |    812.986404 |    766.984586 | Gareth Monger                                                                                                                                                         |
|  72 |    199.638735 |    158.922191 | Markus A. Grohme                                                                                                                                                      |
|  73 |    107.633289 |    666.074062 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
|  74 |    377.675977 |    782.572009 | Gareth Monger                                                                                                                                                         |
|  75 |    355.409039 |     60.939672 | Steven Traver                                                                                                                                                         |
|  76 |    768.469734 |    194.922278 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
|  77 |    977.300421 |    186.648800 | L. Shyamal                                                                                                                                                            |
|  78 |    514.445569 |    360.667331 | Markus A. Grohme                                                                                                                                                      |
|  79 |    855.451419 |    329.917499 | Markus A. Grohme                                                                                                                                                      |
|  80 |     60.271079 |    194.857071 | Shyamal                                                                                                                                                               |
|  81 |    553.946061 |    594.599171 | Markus A. Grohme                                                                                                                                                      |
|  82 |    548.638620 |    560.039434 | Jagged Fang Designs                                                                                                                                                   |
|  83 |    979.479286 |    546.494163 | T. Michael Keesey (after Mivart)                                                                                                                                      |
|  84 |    434.358712 |    605.229710 | Steven Traver                                                                                                                                                         |
|  85 |    944.118889 |    757.064639 | Zimices                                                                                                                                                               |
|  86 |    270.641338 |    780.758415 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  87 |    669.721542 |    771.627914 | Sarah Werning                                                                                                                                                         |
|  88 |    346.558637 |    288.655460 | Beth Reinke                                                                                                                                                           |
|  89 |    152.044148 |    262.018602 | Chris huh                                                                                                                                                             |
|  90 |    276.085629 |    252.535455 | Tasman Dixon                                                                                                                                                          |
|  91 |    884.094850 |    527.401228 | Tauana J. Cunha                                                                                                                                                       |
|  92 |    152.652463 |    518.582920 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  93 |    316.102510 |    553.234469 | Amanda Katzer                                                                                                                                                         |
|  94 |    817.586667 |    427.723713 | Matt Crook                                                                                                                                                            |
|  95 |    345.477212 |    444.849992 | Margot Michaud                                                                                                                                                        |
|  96 |    797.309809 |    170.246962 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
|  97 |    887.608825 |    398.191636 | Ignacio Contreras                                                                                                                                                     |
|  98 |    832.056411 |     26.040216 | Gareth Monger                                                                                                                                                         |
|  99 |    269.385212 |    316.622127 | Qiang Ou                                                                                                                                                              |
| 100 |    565.362497 |    166.028114 | Sarah Werning                                                                                                                                                         |
| 101 |    986.848930 |    144.699606 | Matt Crook                                                                                                                                                            |
| 102 |     39.073553 |    249.200820 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 103 |     42.480029 |    562.531748 | Ferran Sayol                                                                                                                                                          |
| 104 |    267.749722 |    182.917841 | Jagged Fang Designs                                                                                                                                                   |
| 105 |    746.043585 |    737.481765 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                       |
| 106 |    626.318037 |    326.125177 | Yan Wong                                                                                                                                                              |
| 107 |    734.684619 |    602.253853 | Alex Slavenko                                                                                                                                                         |
| 108 |    474.235992 |    254.418964 | NA                                                                                                                                                                    |
| 109 |    301.535312 |    416.727119 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 110 |    325.607919 |    125.644007 | Scott Hartman                                                                                                                                                         |
| 111 |    962.542983 |    468.888951 | Gareth Monger                                                                                                                                                         |
| 112 |    947.875746 |    449.217878 | Margot Michaud                                                                                                                                                        |
| 113 |     97.769339 |    260.047837 | Andrew A. Farke                                                                                                                                                       |
| 114 |    261.811234 |    345.208364 | Scott Hartman                                                                                                                                                         |
| 115 |    863.076371 |    569.613879 | Margot Michaud                                                                                                                                                        |
| 116 |    771.156400 |     24.752211 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 117 |    141.479272 |    605.511861 | Matt Crook                                                                                                                                                            |
| 118 |    175.591515 |     80.444685 | Bryan Carstens                                                                                                                                                        |
| 119 |    725.986162 |    562.994527 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 120 |    514.869580 |      7.447987 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 121 |    754.406247 |    279.423559 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 122 |    866.801660 |     31.746869 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 123 |     13.309001 |    262.089658 | Zimices                                                                                                                                                               |
| 124 |    254.619012 |    761.668778 | Steven Traver                                                                                                                                                         |
| 125 |    321.940105 |    499.998521 | NA                                                                                                                                                                    |
| 126 |    498.376216 |    464.291527 | Ferran Sayol                                                                                                                                                          |
| 127 |    870.349408 |    292.820784 | Ludwik Gasiorowski                                                                                                                                                    |
| 128 |    893.916411 |    692.222048 | Gareth Monger                                                                                                                                                         |
| 129 |    406.767898 |    759.037002 | NA                                                                                                                                                                    |
| 130 |    144.231357 |    376.303045 | NA                                                                                                                                                                    |
| 131 |    252.131764 |    397.850659 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 132 |    437.009345 |    679.284164 | Ferran Sayol                                                                                                                                                          |
| 133 |    538.555721 |    314.308952 | Andrew A. Farke                                                                                                                                                       |
| 134 |    990.670489 |     64.845069 | Zimices                                                                                                                                                               |
| 135 |    196.192647 |    785.655919 | Zimices                                                                                                                                                               |
| 136 |    234.081748 |    426.103793 | Zimices                                                                                                                                                               |
| 137 |    556.763806 |    634.294718 | Gareth Monger                                                                                                                                                         |
| 138 |     59.493079 |    565.836323 | Jonathan Wells                                                                                                                                                        |
| 139 |    557.493082 |    325.834459 | Jagged Fang Designs                                                                                                                                                   |
| 140 |    272.217093 |    553.249976 | Scott Hartman                                                                                                                                                         |
| 141 |    494.155232 |    435.652399 | Gareth Monger                                                                                                                                                         |
| 142 |    525.876569 |    463.511734 | Margot Michaud                                                                                                                                                        |
| 143 |    358.090798 |    387.246766 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 144 |    266.371498 |    464.786979 | Margot Michaud                                                                                                                                                        |
| 145 |   1019.449571 |    335.791547 | Gareth Monger                                                                                                                                                         |
| 146 |    998.630410 |    329.962243 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
| 147 |    688.896674 |     68.961680 | Beth Reinke                                                                                                                                                           |
| 148 |    936.371092 |    441.800400 | Mathilde Cordellier                                                                                                                                                   |
| 149 |    803.412140 |    259.541261 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 150 |    719.777585 |     33.668839 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 151 |     70.256910 |    396.299769 | Maxime Dahirel                                                                                                                                                        |
| 152 |    397.415564 |    493.424225 | Armin Reindl                                                                                                                                                          |
| 153 |    700.817704 |    122.185539 | Emily Willoughby                                                                                                                                                      |
| 154 |    396.730844 |    283.941720 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 155 |     12.633725 |     61.414694 | Emily Willoughby                                                                                                                                                      |
| 156 |    207.037655 |    720.203506 | Zimices                                                                                                                                                               |
| 157 |    134.181085 |    725.236768 | Scott Hartman                                                                                                                                                         |
| 158 |    455.874975 |    742.830296 | Matt Crook                                                                                                                                                            |
| 159 |    217.282455 |    541.905258 | Margot Michaud                                                                                                                                                        |
| 160 |    107.287813 |     32.239351 | Gareth Monger                                                                                                                                                         |
| 161 |    719.610273 |    401.270070 | Scott Hartman                                                                                                                                                         |
| 162 |    311.412433 |    248.533356 | Jack Mayer Wood                                                                                                                                                       |
| 163 |     12.722532 |    500.453397 | Mathilde Cordellier                                                                                                                                                   |
| 164 |     18.084580 |    725.336930 | Katie S. Collins                                                                                                                                                      |
| 165 |    709.859187 |    605.814514 | T. Michael Keesey                                                                                                                                                     |
| 166 |     51.124345 |     16.448212 | Joanna Wolfe                                                                                                                                                          |
| 167 |    567.877143 |    655.831656 | Sharon Wegner-Larsen                                                                                                                                                  |
| 168 |    545.382825 |    264.785028 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 169 |    235.414632 |    462.274660 | Dmitry Bogdanov                                                                                                                                                       |
| 170 |    972.091915 |    442.947323 | Matt Crook                                                                                                                                                            |
| 171 |    534.973343 |    636.788224 | Sebastian Stabinger                                                                                                                                                   |
| 172 |    948.115025 |    348.463982 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 173 |     30.594048 |    142.949797 | Michele M Tobias                                                                                                                                                      |
| 174 |    802.153759 |     18.335825 | Ferran Sayol                                                                                                                                                          |
| 175 |    181.340500 |    173.117076 | Jaime Headden                                                                                                                                                         |
| 176 |    988.125164 |    719.410295 | Steven Traver                                                                                                                                                         |
| 177 |    410.630048 |    251.982992 | Gareth Monger                                                                                                                                                         |
| 178 |     20.561314 |    752.912993 | T. Michael Keesey                                                                                                                                                     |
| 179 |    891.045060 |    380.834652 | Emily Willoughby                                                                                                                                                      |
| 180 |    521.438791 |    190.058411 | Margot Michaud                                                                                                                                                        |
| 181 |    106.394268 |    136.172361 | T. Michael Keesey                                                                                                                                                     |
| 182 |    728.187803 |    597.129190 | Martin Kevil                                                                                                                                                          |
| 183 |    511.040497 |    326.167857 | Ludwik Gasiorowski                                                                                                                                                    |
| 184 |    800.359903 |    143.088929 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 185 |    345.479447 |    680.663182 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 186 |    583.627039 |     65.905044 | Tasman Dixon                                                                                                                                                          |
| 187 |    543.076035 |     13.893840 | Matt Crook                                                                                                                                                            |
| 188 |     54.128970 |     75.124262 | Margot Michaud                                                                                                                                                        |
| 189 |    956.258653 |    195.252568 | Juan Carlos Jerí                                                                                                                                                      |
| 190 |   1015.591408 |    710.193726 | NA                                                                                                                                                                    |
| 191 |    939.312537 |    724.672219 | Kamil S. Jaron                                                                                                                                                        |
| 192 |    304.429972 |    293.332549 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 193 |    778.862401 |    444.389906 | Matt Crook                                                                                                                                                            |
| 194 |    369.021202 |    794.700745 | Jake Warner                                                                                                                                                           |
| 195 |    389.639783 |    793.662638 | Ignacio Contreras                                                                                                                                                     |
| 196 |    138.023273 |    734.128560 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 197 |    868.983382 |    644.669091 | Matthew E. Clapham                                                                                                                                                    |
| 198 |    538.231674 |    183.270454 | Steven Traver                                                                                                                                                         |
| 199 |    397.857626 |     20.757022 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 200 |    465.907233 |    452.985311 | Scott Hartman                                                                                                                                                         |
| 201 |    473.156182 |    639.365602 | Margot Michaud                                                                                                                                                        |
| 202 |    291.453242 |    305.215687 | Zimices                                                                                                                                                               |
| 203 |    399.582288 |    464.827499 | Ben Liebeskind                                                                                                                                                        |
| 204 |    515.129176 |    207.875130 | Gareth Monger                                                                                                                                                         |
| 205 |    793.935130 |     12.438840 | Margot Michaud                                                                                                                                                        |
| 206 |    869.657397 |     93.961422 | Beth Reinke                                                                                                                                                           |
| 207 |    193.333872 |    417.625131 | Ferran Sayol                                                                                                                                                          |
| 208 |    962.351783 |    711.606837 | Andrew A. Farke                                                                                                                                                       |
| 209 |    988.120939 |    345.220564 | Zimices                                                                                                                                                               |
| 210 |    313.288735 |    659.691891 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 211 |    813.723311 |    245.008295 | Gordon E. Robertson                                                                                                                                                   |
| 212 |    582.479243 |    200.051137 | Margot Michaud                                                                                                                                                        |
| 213 |    370.542571 |    508.333945 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 214 |    125.001184 |    357.564138 | Jagged Fang Designs                                                                                                                                                   |
| 215 |    309.434853 |    632.479841 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 216 |    671.122603 |    725.226089 | Campbell Fleming                                                                                                                                                      |
| 217 |    776.422651 |    738.038866 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 218 |    456.930774 |    210.293463 | Gareth Monger                                                                                                                                                         |
| 219 |    381.005486 |    565.790435 | Ferran Sayol                                                                                                                                                          |
| 220 |    739.387726 |    675.797258 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 221 |    726.590487 |    648.006488 | NA                                                                                                                                                                    |
| 222 |     23.306804 |    572.121150 | Patrick Strutzenberger                                                                                                                                                |
| 223 |    905.266340 |      4.404372 | Scott Hartman                                                                                                                                                         |
| 224 |    198.763555 |    744.955681 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 225 |    975.671830 |     54.886728 | Rebecca Groom                                                                                                                                                         |
| 226 |    313.436172 |    541.638031 | T. Michael Keesey                                                                                                                                                     |
| 227 |    596.305656 |     34.209974 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                                  |
| 228 |    644.530370 |    209.409031 | T. Michael Keesey                                                                                                                                                     |
| 229 |    846.241604 |    394.934978 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 230 |    424.028685 |    750.214004 | Kevin Sánchez                                                                                                                                                         |
| 231 |    950.637699 |    437.619964 | Lafage                                                                                                                                                                |
| 232 |     31.004358 |    784.973187 | Jagged Fang Designs                                                                                                                                                   |
| 233 |     23.573770 |    595.440399 | Ignacio Contreras                                                                                                                                                     |
| 234 |    293.640302 |     12.325828 | CNZdenek                                                                                                                                                              |
| 235 |    296.258944 |    713.005783 | Gareth Monger                                                                                                                                                         |
| 236 |    590.194511 |    355.478716 | Zimices                                                                                                                                                               |
| 237 |    783.528610 |    471.268746 | Katie S. Collins                                                                                                                                                      |
| 238 |    652.627327 |    696.756250 | Margot Michaud                                                                                                                                                        |
| 239 |   1011.084556 |     62.573717 | NA                                                                                                                                                                    |
| 240 |    128.328253 |    192.017697 | Gareth Monger                                                                                                                                                         |
| 241 |    724.091214 |    376.470467 | Matt Crook                                                                                                                                                            |
| 242 |    493.875239 |    518.770251 | Steven Traver                                                                                                                                                         |
| 243 |   1005.866248 |     88.778229 | Scott Hartman                                                                                                                                                         |
| 244 |    600.045708 |    548.513093 | Steven Traver                                                                                                                                                         |
| 245 |    489.538617 |    474.090538 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 246 |    946.206320 |    506.774189 | Zimices                                                                                                                                                               |
| 247 |    720.725814 |     23.214163 | Rainer Schoch                                                                                                                                                         |
| 248 |    949.777573 |    578.854215 | Matt Wilkins                                                                                                                                                          |
| 249 |    587.334726 |    373.446657 | Lukasiniho                                                                                                                                                            |
| 250 |    564.170685 |     35.357407 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 251 |    953.396335 |    404.533501 | Margot Michaud                                                                                                                                                        |
| 252 |    243.334755 |    125.871651 | Tasman Dixon                                                                                                                                                          |
| 253 |    678.083601 |    278.492323 | Tasman Dixon                                                                                                                                                          |
| 254 |    294.552614 |    650.088621 | Zimices                                                                                                                                                               |
| 255 |    435.063452 |    698.261664 | Ingo Braasch                                                                                                                                                          |
| 256 |    794.177228 |    155.174082 | Tasman Dixon                                                                                                                                                          |
| 257 |    730.830259 |    585.749768 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 258 |    949.219140 |    556.646609 | NA                                                                                                                                                                    |
| 259 |    364.929281 |    543.319077 | T. Michael Keesey                                                                                                                                                     |
| 260 |     78.478471 |    713.125480 | Caleb M. Brown                                                                                                                                                        |
| 261 |    126.581557 |    174.701874 | NA                                                                                                                                                                    |
| 262 |    772.420820 |    117.880837 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                           |
| 263 |     89.375312 |    548.008030 | Zimices                                                                                                                                                               |
| 264 |    584.406627 |    750.699940 | Sarah Werning                                                                                                                                                         |
| 265 |     26.107619 |    555.853159 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 266 |    609.433171 |    169.981571 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 267 |    622.569580 |      9.760562 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 268 |    909.247118 |    110.797361 | T. Michael Keesey                                                                                                                                                     |
| 269 |    344.165474 |    506.216819 | Emily Willoughby                                                                                                                                                      |
| 270 |    889.282137 |    644.900113 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 271 |    603.314614 |    734.486008 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 272 |    885.194798 |     12.701049 | Matt Crook                                                                                                                                                            |
| 273 |    278.607608 |    599.363327 | NA                                                                                                                                                                    |
| 274 |    274.432900 |    618.541345 | Steven Traver                                                                                                                                                         |
| 275 |    493.306539 |    686.969687 | Nobu Tamura                                                                                                                                                           |
| 276 |    925.881305 |    388.883020 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 277 |      3.525776 |    748.622957 | Mathilde Cordellier                                                                                                                                                   |
| 278 |    292.652497 |    378.348115 | Margot Michaud                                                                                                                                                        |
| 279 |    685.496715 |    651.635467 | Zimices                                                                                                                                                               |
| 280 |    794.755334 |    190.421811 | Scott Hartman                                                                                                                                                         |
| 281 |     54.612811 |     81.266706 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 282 |    803.818631 |    711.034784 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 283 |    514.640303 |    574.434134 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 284 |    605.275256 |    655.646372 | Ignacio Contreras                                                                                                                                                     |
| 285 |    612.749835 |    769.961037 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 286 |    435.890659 |    176.101042 | B Kimmel                                                                                                                                                              |
| 287 |    667.803477 |    170.810113 | T. Michael Keesey                                                                                                                                                     |
| 288 |    838.767479 |    647.982236 | Tauana J. Cunha                                                                                                                                                       |
| 289 |    613.053807 |    367.822518 | Emily Willoughby                                                                                                                                                      |
| 290 |    467.761212 |    670.609150 | Zimices                                                                                                                                                               |
| 291 |    574.932857 |     83.469376 | Gareth Monger                                                                                                                                                         |
| 292 |    854.824399 |    656.736783 | Chris huh                                                                                                                                                             |
| 293 |     80.927999 |     66.442406 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 294 |    521.078536 |    113.965653 | Yan Wong                                                                                                                                                              |
| 295 |    625.385652 |    632.513467 | Ferran Sayol                                                                                                                                                          |
| 296 |    723.043160 |    623.233587 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 297 |    904.429812 |    790.201619 | Tracy A. Heath                                                                                                                                                        |
| 298 |    439.590723 |    271.868166 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 299 |    117.960840 |    121.001833 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 300 |    791.668954 |    382.158752 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 301 |    890.714850 |    762.580392 | Zimices                                                                                                                                                               |
| 302 |    441.695408 |    126.276725 | Kamil S. Jaron                                                                                                                                                        |
| 303 |     49.382500 |    633.896517 | Scott Reid                                                                                                                                                            |
| 304 |    322.172817 |    559.292448 | Sarah Werning                                                                                                                                                         |
| 305 |    720.055474 |    602.735369 | Tasman Dixon                                                                                                                                                          |
| 306 |    733.253368 |    505.786851 | Manabu Bessho-Uehara                                                                                                                                                  |
| 307 |    528.190606 |    478.355238 | Markus A. Grohme                                                                                                                                                      |
| 308 |     47.804934 |    343.202561 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 309 |    528.101486 |     16.796481 | Felix Vaux                                                                                                                                                            |
| 310 |    934.514333 |    496.327665 | Steven Blackwood                                                                                                                                                      |
| 311 |    729.745801 |     67.054851 | Roberto Díaz Sibaja                                                                                                                                                   |
| 312 |    787.778291 |    454.895416 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 313 |     16.177368 |    171.174172 | Zimices                                                                                                                                                               |
| 314 |    205.525567 |    605.612791 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 315 |    775.525327 |    425.535643 | Alex Slavenko                                                                                                                                                         |
| 316 |     68.699607 |    318.651886 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 317 |    298.643692 |    570.501348 | Steven Traver                                                                                                                                                         |
| 318 |    441.186800 |    184.210057 | Rebecca Groom                                                                                                                                                         |
| 319 |    472.753799 |    706.401346 | Yan Wong                                                                                                                                                              |
| 320 |    845.950300 |    242.446778 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 321 |    419.483476 |    789.890546 | Zimices                                                                                                                                                               |
| 322 |    523.132370 |    133.918799 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 323 |    494.515181 |    572.519722 | Jagged Fang Designs                                                                                                                                                   |
| 324 |    997.137023 |    618.567509 | Birgit Lang                                                                                                                                                           |
| 325 |    822.884735 |    614.131498 | Jessica Anne Miller                                                                                                                                                   |
| 326 |      8.590483 |    705.814316 | Mathieu Basille                                                                                                                                                       |
| 327 |    323.778172 |    433.316476 | NA                                                                                                                                                                    |
| 328 |    536.529186 |    437.156909 | Sarah Werning                                                                                                                                                         |
| 329 |    201.326118 |    688.196587 | Sean McCann                                                                                                                                                           |
| 330 |    829.717249 |    221.353055 | Ferran Sayol                                                                                                                                                          |
| 331 |    460.896992 |    160.119039 | Chris huh                                                                                                                                                             |
| 332 |    624.711932 |    591.491588 | Margot Michaud                                                                                                                                                        |
| 333 |    731.555144 |    128.064833 | Matt Celeskey                                                                                                                                                         |
| 334 |    721.247677 |    787.592536 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 335 |    785.904405 |    249.235078 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 336 |    533.182291 |    107.841397 | Dave Angelini                                                                                                                                                         |
| 337 |    484.580710 |    489.628536 | Becky Barnes                                                                                                                                                          |
| 338 |    387.160931 |    543.149186 | Tracy A. Heath                                                                                                                                                        |
| 339 |   1004.419373 |    736.214527 | Tasman Dixon                                                                                                                                                          |
| 340 |    134.331295 |     87.410572 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 341 |    943.803220 |    716.632463 | L. Shyamal                                                                                                                                                            |
| 342 |    748.362587 |    611.478824 | NA                                                                                                                                                                    |
| 343 |    787.912319 |    198.903854 | Margot Michaud                                                                                                                                                        |
| 344 |    502.706971 |    312.113401 | L.M. Davalos                                                                                                                                                          |
| 345 |    329.924734 |    701.830760 | Melissa Broussard                                                                                                                                                     |
| 346 |    439.597105 |    648.534583 | Matt Crook                                                                                                                                                            |
| 347 |    771.781535 |    300.907448 | Conty                                                                                                                                                                 |
| 348 |    152.359981 |    479.674037 | Margot Michaud                                                                                                                                                        |
| 349 |    707.319834 |    396.747442 | T. Michael Keesey                                                                                                                                                     |
| 350 |    981.007898 |     72.757375 | NA                                                                                                                                                                    |
| 351 |    322.232947 |    516.741917 | Carlos Cano-Barbacil                                                                                                                                                  |
| 352 |    581.827417 |    154.667892 | Matt Crook                                                                                                                                                            |
| 353 |    816.420783 |     50.954001 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 354 |     36.797187 |    647.052976 | Jagged Fang Designs                                                                                                                                                   |
| 355 |    166.248716 |    597.808641 | Steven Traver                                                                                                                                                         |
| 356 |    306.220244 |    336.429614 | Yan Wong                                                                                                                                                              |
| 357 |    185.429871 |    771.759790 | Mo Hassan                                                                                                                                                             |
| 358 |    148.099337 |    193.501853 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 359 |   1009.111490 |    584.239794 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 360 |    236.977533 |    146.789650 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 361 |    866.678493 |    599.233848 | NA                                                                                                                                                                    |
| 362 |    746.534105 |    595.146939 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 363 |    281.524280 |    679.742291 | Ingo Braasch                                                                                                                                                          |
| 364 |    812.158596 |    723.129711 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 365 |    159.126560 |    279.413956 | Caleb M. Brown                                                                                                                                                        |
| 366 |    758.976325 |    379.371394 | Caleb M. Brown                                                                                                                                                        |
| 367 |     89.114032 |    142.495596 | Zimices                                                                                                                                                               |
| 368 |    508.334313 |    719.991382 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 369 |    374.762440 |    764.234069 | NA                                                                                                                                                                    |
| 370 |    652.047487 |    234.281062 | Cesar Julian                                                                                                                                                          |
| 371 |    303.699452 |    272.684224 | Chris huh                                                                                                                                                             |
| 372 |    839.839414 |    471.947436 | Jessica Anne Miller                                                                                                                                                   |
| 373 |    631.693858 |    143.780554 | Kai R. Caspar                                                                                                                                                         |
| 374 |    787.075119 |    612.848037 | Zimices                                                                                                                                                               |
| 375 |     50.314017 |    162.805957 | NA                                                                                                                                                                    |
| 376 |    821.792039 |    172.624000 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 377 |    839.533489 |    354.792380 | Felix Vaux                                                                                                                                                            |
| 378 |    545.165143 |    574.884081 | Jagged Fang Designs                                                                                                                                                   |
| 379 |    191.259351 |    496.082579 | Conty                                                                                                                                                                 |
| 380 |    898.816380 |    105.234968 | NA                                                                                                                                                                    |
| 381 |    424.184532 |    102.912907 | Mattia Menchetti                                                                                                                                                      |
| 382 |    965.585035 |    730.287093 | T. Michael Keesey                                                                                                                                                     |
| 383 |    266.567326 |    757.443763 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 384 |    299.191417 |    760.603447 | Zimices                                                                                                                                                               |
| 385 |    976.770299 |    788.493048 | Steven Traver                                                                                                                                                         |
| 386 |    109.793655 |     16.886938 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 387 |    777.618709 |    105.697565 | Mathilde Cordellier                                                                                                                                                   |
| 388 |    122.992892 |     54.792543 | Chris huh                                                                                                                                                             |
| 389 |    132.716090 |    746.729627 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 390 |    662.483173 |    327.227477 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 391 |    324.874676 |    714.425213 | Matt Crook                                                                                                                                                            |
| 392 |    757.598493 |     40.420769 | Chris huh                                                                                                                                                             |
| 393 |    779.242075 |    188.384999 | Pete Buchholz                                                                                                                                                         |
| 394 |    720.450844 |    308.785526 | Lafage                                                                                                                                                                |
| 395 |    873.120070 |    498.353366 | L. Shyamal                                                                                                                                                            |
| 396 |    843.737670 |     62.475007 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
| 397 |    142.822182 |    618.805149 | Harold N Eyster                                                                                                                                                       |
| 398 |    648.244118 |    729.442324 | Yan Wong                                                                                                                                                              |
| 399 |    836.159144 |    633.904949 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 400 |    294.401594 |    742.669948 | Rebecca Groom                                                                                                                                                         |
| 401 |     47.909665 |    411.707406 | Yan Wong                                                                                                                                                              |
| 402 |    521.378890 |    308.043950 | Tauana J. Cunha                                                                                                                                                       |
| 403 |    618.562242 |    661.908114 | T. Michael Keesey                                                                                                                                                     |
| 404 |    159.862174 |    779.888855 | Chase Brownstein                                                                                                                                                      |
| 405 |    141.874209 |    535.899795 | Gareth Monger                                                                                                                                                         |
| 406 |    139.870371 |    384.633587 | Collin Gross                                                                                                                                                          |
| 407 |    656.404285 |    316.490493 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 408 |    705.099956 |    298.372947 | Ferran Sayol                                                                                                                                                          |
| 409 |    684.795907 |     92.604362 | Margot Michaud                                                                                                                                                        |
| 410 |    595.013073 |    219.913784 | Gareth Monger                                                                                                                                                         |
| 411 |    323.854302 |    510.050804 | Tyler Greenfield                                                                                                                                                      |
| 412 |     94.795654 |    746.625351 | L. Shyamal                                                                                                                                                            |
| 413 |    876.964378 |    659.052575 | NA                                                                                                                                                                    |
| 414 |    427.553031 |    284.629960 | Ferran Sayol                                                                                                                                                          |
| 415 |    942.480060 |    154.674352 | Margot Michaud                                                                                                                                                        |
| 416 |     79.342751 |     94.743159 | Matt Crook                                                                                                                                                            |
| 417 |     33.031442 |    629.425275 | Margot Michaud                                                                                                                                                        |
| 418 |    105.107248 |    430.688196 | Chris huh                                                                                                                                                             |
| 419 |    709.254450 |     90.422238 | L. Shyamal                                                                                                                                                            |
| 420 |    868.885300 |     50.722627 | Michele Tobias                                                                                                                                                        |
| 421 |    188.033687 |    537.267509 | Mathew Wedel                                                                                                                                                          |
| 422 |    636.089672 |    608.956472 | Nobu Tamura                                                                                                                                                           |
| 423 |    587.478850 |    770.186152 | T. Michael Keesey                                                                                                                                                     |
| 424 |    917.855674 |    239.724007 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 425 |    695.838654 |    512.373900 | Scott Hartman                                                                                                                                                         |
| 426 |    357.738359 |    459.259183 | Zimices                                                                                                                                                               |
| 427 |    619.281728 |    672.710989 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 428 |     59.742891 |    761.107201 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 429 |    211.404547 |    102.438339 | Steven Traver                                                                                                                                                         |
| 430 |    476.889178 |    162.334854 | Gareth Monger                                                                                                                                                         |
| 431 |    438.161462 |    726.381412 | Cathy                                                                                                                                                                 |
| 432 |    339.324135 |    489.373172 | Christoph Schomburg                                                                                                                                                   |
| 433 |     12.830902 |    420.235757 | Zachary Quigley                                                                                                                                                       |
| 434 |    631.483808 |    678.147598 | Jagged Fang Designs                                                                                                                                                   |
| 435 |    301.899544 |    266.947587 | Terpsichores                                                                                                                                                          |
| 436 |    797.143505 |    280.508084 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 437 |    325.268399 |    111.264004 | Steven Traver                                                                                                                                                         |
| 438 |    698.627880 |      9.398152 | Markus A. Grohme                                                                                                                                                      |
| 439 |    553.480323 |     46.357459 | Zimices                                                                                                                                                               |
| 440 |    255.096985 |    273.312680 | Margot Michaud                                                                                                                                                        |
| 441 |     53.697265 |    151.716523 | Michelle Site                                                                                                                                                         |
| 442 |    570.512080 |    191.772226 | Mariana Ruiz Villarreal                                                                                                                                               |
| 443 |    562.323789 |    569.736098 | Arthur S. Brum                                                                                                                                                        |
| 444 |    291.258673 |    355.743466 | Matt Crook                                                                                                                                                            |
| 445 |    736.786323 |    687.766402 | Zimices                                                                                                                                                               |
| 446 |    699.567920 |    622.537100 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 447 |    908.830802 |    498.644687 | Jagged Fang Designs                                                                                                                                                   |
| 448 |    572.660311 |    241.583433 | Joanna Wolfe                                                                                                                                                          |
| 449 |    176.133367 |    784.214902 | Gareth Monger                                                                                                                                                         |
| 450 |    363.082519 |    711.035372 | Steven Traver                                                                                                                                                         |
| 451 |    510.724191 |    626.863646 | Tauana J. Cunha                                                                                                                                                       |
| 452 |    112.086831 |    650.855136 | Margot Michaud                                                                                                                                                        |
| 453 |    610.360584 |    159.148211 | Zimices                                                                                                                                                               |
| 454 |    565.641690 |    269.651324 | NA                                                                                                                                                                    |
| 455 |    821.532349 |    265.909119 | Ben Liebeskind                                                                                                                                                        |
| 456 |    238.883492 |    599.355899 | James Neenan                                                                                                                                                          |
| 457 |    765.246127 |    583.806401 | Matt Crook                                                                                                                                                            |
| 458 |     21.239279 |     81.958819 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 459 |    685.826691 |    285.475718 | Nick Schooler                                                                                                                                                         |
| 460 |    560.940664 |    303.302204 | Zimices                                                                                                                                                               |
| 461 |    458.192482 |    479.904053 | Michelle Site                                                                                                                                                         |
| 462 |     22.874272 |     10.058032 | L. Shyamal                                                                                                                                                            |
| 463 |    286.459886 |    613.542800 | Ferran Sayol                                                                                                                                                          |
| 464 |    759.233609 |    698.414747 | NA                                                                                                                                                                    |
| 465 |    582.770449 |     27.799521 | Collin Gross                                                                                                                                                          |
| 466 |    221.713110 |    693.376342 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 467 |    583.405225 |    213.580829 | NA                                                                                                                                                                    |
| 468 |    576.995530 |    227.047294 | NA                                                                                                                                                                    |
| 469 |    427.338973 |    383.346537 | Scott Hartman                                                                                                                                                         |
| 470 |    595.814441 |    195.112169 | Ferran Sayol                                                                                                                                                          |
| 471 |    474.976711 |    277.484546 | Dmitry Bogdanov                                                                                                                                                       |
| 472 |    264.396127 |    584.564914 | Zimices                                                                                                                                                               |
| 473 |    588.904676 |    779.214079 | Oscar Sanisidro                                                                                                                                                       |
| 474 |    199.465142 |     67.444851 | Joanna Wolfe                                                                                                                                                          |
| 475 |     41.509991 |    683.810532 | Lukasiniho                                                                                                                                                            |
| 476 |    767.993574 |    157.848200 | Margot Michaud                                                                                                                                                        |
| 477 |    298.626391 |    594.111478 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 478 |    841.464036 |    216.272076 | Gareth Monger                                                                                                                                                         |
| 479 |    642.462677 |    505.267906 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 480 |    810.632101 |    101.190469 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 481 |    703.235539 |    519.906506 | Chris huh                                                                                                                                                             |
| 482 |    316.226260 |     71.151848 | Tauana J. Cunha                                                                                                                                                       |
| 483 |    593.091150 |    300.098752 | Tasman Dixon                                                                                                                                                          |
| 484 |    813.853185 |    464.649003 | Tracy A. Heath                                                                                                                                                        |
| 485 |    819.031609 |    326.482593 | Collin Gross                                                                                                                                                          |
| 486 |    762.476925 |    663.755220 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 487 |    420.503164 |    110.172144 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 488 |    218.121632 |    678.981212 | Scott Hartman                                                                                                                                                         |
| 489 |    109.851891 |    723.210390 | Cristina Guijarro                                                                                                                                                     |
| 490 |    964.116722 |    792.370093 | Robert Gay                                                                                                                                                            |
| 491 |    899.587748 |    701.985928 | François Michonneau                                                                                                                                                   |
| 492 |     67.223143 |     65.644141 | Kanchi Nanjo                                                                                                                                                          |
| 493 |    540.986408 |    325.913335 | Gareth Monger                                                                                                                                                         |
| 494 |    513.061744 |    296.000099 | Emily Willoughby                                                                                                                                                      |
| 495 |    413.452021 |    201.577105 | Oliver Griffith                                                                                                                                                       |
| 496 |    918.403713 |    260.827982 | Matt Crook                                                                                                                                                            |
| 497 |   1010.289286 |     78.063489 | Zimices                                                                                                                                                               |
| 498 |     33.738048 |    750.243061 | Markus A. Grohme                                                                                                                                                      |
| 499 |     66.045896 |    254.277218 | Christoph Schomburg                                                                                                                                                   |
| 500 |     15.052714 |    531.158632 | Taro Maeda                                                                                                                                                            |
| 501 |    809.103135 |    213.478861 | Steven Traver                                                                                                                                                         |
| 502 |    867.846099 |     39.046425 | Alex Slavenko                                                                                                                                                         |
| 503 |    788.078581 |    207.751520 | Margot Michaud                                                                                                                                                        |
| 504 |    885.866750 |     79.297994 | NA                                                                                                                                                                    |
| 505 |    477.564654 |    267.205955 | Scott Hartman                                                                                                                                                         |
| 506 |    758.498930 |    306.297583 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 507 |    545.238765 |    644.798618 | Ferran Sayol                                                                                                                                                          |
| 508 |    787.106027 |     38.999034 | Gareth Monger                                                                                                                                                         |
| 509 |    279.450924 |    490.122823 | Birgit Lang                                                                                                                                                           |
| 510 |    311.678267 |    675.186363 | Chris huh                                                                                                                                                             |
| 511 |    127.437441 |    536.472680 | Ferran Sayol                                                                                                                                                          |
| 512 |   1015.595310 |    546.242269 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 513 |    313.798563 |    682.531028 | Katie S. Collins                                                                                                                                                      |
| 514 |    685.975742 |    660.084169 | Ignacio Contreras                                                                                                                                                     |
| 515 |    387.314987 |    459.193864 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 516 |    320.272270 |    692.112392 | Caleb M. Brown                                                                                                                                                        |
| 517 |    979.863662 |    693.934102 | Matt Crook                                                                                                                                                            |
| 518 |    183.899597 |    671.832059 | T. Michael Keesey                                                                                                                                                     |
| 519 |    463.633309 |    795.823307 | Iain Reid                                                                                                                                                             |
| 520 |    293.003924 |    530.061385 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 521 |    255.815164 |    154.439914 | Caleb M. Brown                                                                                                                                                        |
| 522 |    711.521106 |    532.431684 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 523 |    729.184178 |    294.441894 | Zimices                                                                                                                                                               |
| 524 |     31.489509 |    678.168762 | Roberto Díaz Sibaja                                                                                                                                                   |
| 525 |    994.564470 |    353.167985 | Kent Elson Sorgon                                                                                                                                                     |
| 526 |    610.331404 |    716.360934 | Tommaso Cancellario                                                                                                                                                   |
| 527 |    201.806603 |    698.663994 | Kai R. Caspar                                                                                                                                                         |
| 528 |    621.553970 |    127.104344 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 529 |    601.056706 |    742.166085 | Jagged Fang Designs                                                                                                                                                   |
| 530 |    776.722278 |    399.182104 | Chris huh                                                                                                                                                             |
| 531 |    164.360701 |    190.424458 | Dmitry Bogdanov                                                                                                                                                       |
| 532 |    678.584905 |    116.386817 | Anthony Caravaggi                                                                                                                                                     |
| 533 |     83.172166 |    794.325520 | Margot Michaud                                                                                                                                                        |
| 534 |    414.537788 |    716.931366 | François Michonneau                                                                                                                                                   |
| 535 |    282.455308 |    164.230855 | Tauana J. Cunha                                                                                                                                                       |
| 536 |    934.558785 |    489.399218 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 537 |    330.213188 |    160.530114 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 538 |    444.208907 |    772.217801 | Ferran Sayol                                                                                                                                                          |
| 539 |    230.834248 |    683.189896 | NA                                                                                                                                                                    |
| 540 |    596.452841 |    392.777718 | nicubunu                                                                                                                                                              |
| 541 |    114.976106 |    561.204156 | Joanna Wolfe                                                                                                                                                          |
| 542 |    409.619636 |    503.488456 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                         |
| 543 |     85.346988 |    571.089884 | Tracy A. Heath                                                                                                                                                        |
| 544 |    439.381331 |    343.314101 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 545 |    960.661033 |    223.117212 | Jagged Fang Designs                                                                                                                                                   |
| 546 |    382.899183 |    390.062789 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
| 547 |    956.944814 |     67.105329 | NA                                                                                                                                                                    |
| 548 |    980.283985 |    495.505354 | Matt Crook                                                                                                                                                            |
| 549 |    149.025916 |     51.531669 | Zimices                                                                                                                                                               |
| 550 |    679.752030 |    126.101894 | Gareth Monger                                                                                                                                                         |
| 551 |     12.709471 |    212.535006 | Roberto Díaz Sibaja                                                                                                                                                   |
| 552 |    549.092859 |    281.426624 | Gareth Monger                                                                                                                                                         |
| 553 |    343.684099 |    160.018573 | Gareth Monger                                                                                                                                                         |
| 554 |    117.555159 |    551.926888 | Arthur S. Brum                                                                                                                                                        |
| 555 |    580.986857 |    758.894632 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 556 |    407.072661 |    385.846865 | Felix Vaux                                                                                                                                                            |
| 557 |    735.139662 |    315.031355 | Zimices                                                                                                                                                               |
| 558 |    262.961345 |    559.316870 | Zimices                                                                                                                                                               |
| 559 |     71.739233 |    408.183021 | Nick Schooler                                                                                                                                                         |
| 560 |    271.252870 |    741.374520 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 561 |    487.743446 |     22.295640 | Zimices                                                                                                                                                               |
| 562 |    271.445253 |    294.305143 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 563 |    826.603352 |    789.602107 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 564 |    742.545355 |    768.320912 | Steven Traver                                                                                                                                                         |
| 565 |    239.077876 |    414.332402 | NA                                                                                                                                                                    |
| 566 |    857.594656 |    591.164954 | C. Camilo Julián-Caballero                                                                                                                                            |
| 567 |    590.810292 |    339.914539 | Cesar Julian                                                                                                                                                          |
| 568 |    221.336485 |    266.329155 | Margot Michaud                                                                                                                                                        |
| 569 |    179.356659 |    117.213494 | Zimices                                                                                                                                                               |
| 570 |    464.875088 |    205.632393 | C. Camilo Julián-Caballero                                                                                                                                            |
| 571 |    842.156263 |      4.394256 | Neil Kelley                                                                                                                                                           |
| 572 |    286.985339 |    427.761207 | Ferran Sayol                                                                                                                                                          |
| 573 |     20.321333 |    123.216952 | Beth Reinke                                                                                                                                                           |
| 574 |    428.488556 |    484.666993 | Gareth Monger                                                                                                                                                         |
| 575 |    774.033999 |    169.017314 | Cesar Julian                                                                                                                                                          |
| 576 |    971.914640 |     85.261078 | Steven Coombs                                                                                                                                                         |
| 577 |    688.610020 |    466.871504 | Harold N Eyster                                                                                                                                                       |
| 578 |    969.591094 |    357.845206 | NA                                                                                                                                                                    |
| 579 |    809.732557 |    475.648833 | Lukasiniho                                                                                                                                                            |
| 580 |    612.303210 |    487.772415 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 581 |     18.533881 |    236.916391 | B Kimmel                                                                                                                                                              |
| 582 |    578.710950 |    302.937776 | NA                                                                                                                                                                    |
| 583 |    268.630679 |    632.440596 | Zimices                                                                                                                                                               |
| 584 |    925.854027 |    412.356291 | Michelle Site                                                                                                                                                         |
| 585 |     72.209829 |    345.961292 | Steven Traver                                                                                                                                                         |
| 586 |    111.239072 |    252.328586 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 587 |    146.560247 |    231.321194 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 588 |    147.952670 |     16.456796 | Mason McNair                                                                                                                                                          |
| 589 |    402.724118 |    119.979489 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 590 |    804.300423 |    610.997561 | NA                                                                                                                                                                    |
| 591 |    552.607183 |    145.731390 | NA                                                                                                                                                                    |
| 592 |    764.717402 |    140.541040 | Mo Hassan                                                                                                                                                             |
| 593 |    512.886838 |    252.043792 | Scott Hartman                                                                                                                                                         |
| 594 |    494.702116 |    499.292400 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 595 |   1008.287987 |    615.355618 | Steven Traver                                                                                                                                                         |
| 596 |    700.871523 |    200.888418 | Luis Cunha                                                                                                                                                            |
| 597 |    746.012726 |    162.800235 | C. Camilo Julián-Caballero                                                                                                                                            |
| 598 |    721.274497 |    553.432116 | Caleb M. Brown                                                                                                                                                        |
| 599 |    154.962432 |    381.140084 | Jaime Headden                                                                                                                                                         |
| 600 |    636.891007 |    671.308005 | FunkMonk                                                                                                                                                              |
| 601 |    399.077095 |    439.910240 | Jagged Fang Designs                                                                                                                                                   |
| 602 |     36.187600 |    170.645951 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 603 |    995.352006 |    285.474041 | Armin Reindl                                                                                                                                                          |
| 604 |    729.449633 |    394.593269 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 605 |     64.021265 |    685.021358 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                         |
| 606 |    141.352037 |    716.128457 | Matt Crook                                                                                                                                                            |
| 607 |    436.626053 |    501.066741 | Scott Hartman                                                                                                                                                         |
| 608 |    617.980981 |    553.743579 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 609 |    987.340127 |     91.424714 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 610 |    759.592075 |     49.360808 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 611 |   1013.408093 |    171.078992 | Felix Vaux                                                                                                                                                            |
| 612 |    888.228864 |    486.400166 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 613 |    771.861575 |    515.557720 | Tasman Dixon                                                                                                                                                          |
| 614 |    702.421723 |    467.534624 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 615 |     75.075432 |    419.396224 | Gareth Monger                                                                                                                                                         |
| 616 |     95.362741 |    208.307458 | Lily Hughes                                                                                                                                                           |
| 617 |    836.240046 |    727.659705 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 618 |      9.107947 |      7.686288 | NA                                                                                                                                                                    |
| 619 |   1013.673859 |    216.666784 | Steven Traver                                                                                                                                                         |
| 620 |    572.552162 |    329.999269 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 621 |    373.661584 |     38.249072 | Michelle Site                                                                                                                                                         |
| 622 |    629.806044 |     87.766718 | Pete Buchholz                                                                                                                                                         |
| 623 |   1013.289752 |    474.317708 | NA                                                                                                                                                                    |
| 624 |    717.709212 |    427.690998 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 625 |    591.730706 |    311.597903 | Jimmy Bernot                                                                                                                                                          |
| 626 |    948.030643 |    204.587222 | Steven Traver                                                                                                                                                         |
| 627 |   1003.172566 |    253.657234 | Inessa Voet                                                                                                                                                           |
| 628 |    238.397628 |    106.118435 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 629 |    191.433730 |    181.156347 | NA                                                                                                                                                                    |
| 630 |    604.798386 |    206.755436 | Scott Hartman                                                                                                                                                         |
| 631 |    901.627199 |    134.416919 | Ignacio Contreras                                                                                                                                                     |
| 632 |    306.160876 |     37.736559 | Chase Brownstein                                                                                                                                                      |
| 633 |    451.454503 |    378.236149 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 634 |     18.352601 |    156.195192 | Ferran Sayol                                                                                                                                                          |
| 635 |    399.163029 |    138.815757 | Mathew Wedel                                                                                                                                                          |
| 636 |    834.522286 |    230.725255 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 637 |    137.075798 |     28.217761 | C. Abraczinskas                                                                                                                                                       |
| 638 |    824.959995 |    378.148195 | T. Michael Keesey                                                                                                                                                     |
| 639 |    415.797926 |    141.582005 | Scott Hartman                                                                                                                                                         |
| 640 |    200.929812 |    110.342826 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 641 |   1013.153658 |    698.753636 | Gareth Monger                                                                                                                                                         |
| 642 |    459.375416 |    391.091035 | Gareth Monger                                                                                                                                                         |
| 643 |    626.689194 |    778.681800 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 644 |    589.187672 |    631.278589 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 645 |    316.390106 |    334.376808 | Emily Willoughby                                                                                                                                                      |
| 646 |    450.588403 |    654.112261 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 647 |    586.535013 |    652.521231 | Harold N Eyster                                                                                                                                                       |
| 648 |    577.188708 |    543.869493 | Chris huh                                                                                                                                                             |
| 649 |    142.707599 |    108.056951 | NA                                                                                                                                                                    |
| 650 |    622.898597 |     23.337270 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 651 |    505.745940 |    602.653123 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 652 |    535.200386 |     41.373044 | Scott Hartman                                                                                                                                                         |
| 653 |    330.608202 |    756.666306 | Frank Förster                                                                                                                                                         |
| 654 |    550.037889 |    414.717607 | Matt Crook                                                                                                                                                            |
| 655 |    710.222568 |    677.427045 | Margot Michaud                                                                                                                                                        |
| 656 |    821.218617 |    486.667681 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 657 |    927.093789 |    428.418169 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 658 |    652.271257 |     77.337372 | Margot Michaud                                                                                                                                                        |
| 659 |    549.942561 |    337.678130 | Collin Gross                                                                                                                                                          |
| 660 |    414.166434 |    181.137960 | Tasman Dixon                                                                                                                                                          |
| 661 |    138.827413 |    408.358325 | Martin Kevil                                                                                                                                                          |
| 662 |     12.008412 |    671.165277 | Felix Vaux                                                                                                                                                            |
| 663 |    168.629438 |    506.753401 | Matt Crook                                                                                                                                                            |
| 664 |     57.919821 |    119.158517 | Chris huh                                                                                                                                                             |
| 665 |    471.305237 |    715.499045 | Birgit Lang                                                                                                                                                           |
| 666 |     67.578491 |    553.431795 | Zimices                                                                                                                                                               |
| 667 |    775.620640 |    709.435184 | Chris huh                                                                                                                                                             |
| 668 |    199.619882 |     82.082570 | Matt Crook                                                                                                                                                            |
| 669 |    464.102308 |    338.206593 | Zimices                                                                                                                                                               |
| 670 |    530.265899 |     25.505334 | Margot Michaud                                                                                                                                                        |
| 671 |     20.287240 |    773.980329 | Ignacio Contreras                                                                                                                                                     |
| 672 |    805.713875 |     53.104605 | Ferran Sayol                                                                                                                                                          |
| 673 |    167.679829 |    431.412661 | Carlos Cano-Barbacil                                                                                                                                                  |
| 674 |    141.608415 |    645.178966 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 675 |    152.399678 |    284.993756 | Margot Michaud                                                                                                                                                        |
| 676 |    759.937159 |    498.899288 | Verdilak                                                                                                                                                              |
| 677 |    765.451711 |    441.836034 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 678 |    812.739884 |    385.128958 | Scott Hartman                                                                                                                                                         |
| 679 |    814.733067 |    391.983882 | Scott Hartman                                                                                                                                                         |
| 680 |    828.575657 |     70.521302 | Harold N Eyster                                                                                                                                                       |
| 681 |    743.564079 |    785.487674 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 682 |    963.699362 |    483.154647 | Tasman Dixon                                                                                                                                                          |
| 683 |     64.062083 |    755.729783 | Birgit Lang                                                                                                                                                           |
| 684 |    736.861022 |    331.157405 | NA                                                                                                                                                                    |
| 685 |    787.819759 |    702.779810 | T. Michael Keesey                                                                                                                                                     |
| 686 |     54.169173 |     90.465695 | Beth Reinke                                                                                                                                                           |
| 687 |    320.044477 |    423.294950 | Zimices                                                                                                                                                               |
| 688 |    614.860341 |    697.550076 | Auckland Museum                                                                                                                                                       |
| 689 |    587.401785 |     74.593565 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 690 |    303.669375 |    561.941127 | Gareth Monger                                                                                                                                                         |
| 691 |    187.547285 |    429.628980 | T. Michael Keesey                                                                                                                                                     |
| 692 |    439.657343 |    754.176379 | Margot Michaud                                                                                                                                                        |
| 693 |   1009.875788 |    117.725362 | Margot Michaud                                                                                                                                                        |
| 694 |    651.290846 |     90.537395 | T. Michael Keesey                                                                                                                                                     |
| 695 |    740.382685 |    656.072798 | Chris huh                                                                                                                                                             |
| 696 |    499.246818 |    739.351776 | Jagged Fang Designs                                                                                                                                                   |
| 697 |    997.516620 |    609.189645 | Juan Carlos Jerí                                                                                                                                                      |
| 698 |    571.995222 |    283.137874 | Tracy A. Heath                                                                                                                                                        |
| 699 |    890.549209 |    659.721249 | S.Martini                                                                                                                                                             |
| 700 |    457.765206 |     11.109513 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 701 |    675.351058 |    310.278047 | Jagged Fang Designs                                                                                                                                                   |
| 702 |     34.769188 |    759.787326 | Margot Michaud                                                                                                                                                        |
| 703 |    306.456893 |    281.737336 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 704 |    656.408231 |    718.305385 | Ferran Sayol                                                                                                                                                          |
| 705 |    806.329022 |    372.156515 | Mattia Menchetti                                                                                                                                                      |
| 706 |    682.494160 |    508.415045 | Gareth Monger                                                                                                                                                         |
| 707 |   1012.636284 |    498.928536 | Katie S. Collins                                                                                                                                                      |
| 708 |    174.999254 |    484.382661 | Steven Traver                                                                                                                                                         |
| 709 |    823.673794 |    388.026889 | Zimices                                                                                                                                                               |
| 710 |    504.698029 |    795.332317 | T. Michael Keesey                                                                                                                                                     |
| 711 |     96.779023 |     12.107478 | Gareth Monger                                                                                                                                                         |
| 712 |     21.733743 |    565.875064 | Zimices                                                                                                                                                               |
| 713 |    647.884071 |      9.971531 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 714 |    426.320523 |    769.761430 | Gareth Monger                                                                                                                                                         |
| 715 |    353.918688 |    486.920557 | Steven Traver                                                                                                                                                         |
| 716 |    672.188455 |     83.795269 | Matt Crook                                                                                                                                                            |
| 717 |    137.880920 |    302.700845 | C. Camilo Julián-Caballero                                                                                                                                            |
| 718 |    518.040616 |    276.384492 | Iain Reid                                                                                                                                                             |
| 719 |    456.216715 |    693.453318 | Christoph Schomburg                                                                                                                                                   |
| 720 |     18.916294 |    336.252016 | Kai R. Caspar                                                                                                                                                         |
| 721 |    599.798203 |    763.587703 | Pedro de Siracusa                                                                                                                                                     |
| 722 |    979.228158 |    473.851969 | Maija Karala                                                                                                                                                          |
| 723 |    487.402030 |    256.278916 | Mathilde Cordellier                                                                                                                                                   |
| 724 |    922.077381 |    793.744093 | xgirouxb                                                                                                                                                              |
| 725 |    774.510748 |    224.763953 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 726 |    510.503550 |    453.602402 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 727 |    307.156262 |    700.611676 | Steven Traver                                                                                                                                                         |
| 728 |    554.257561 |    786.036907 | Margot Michaud                                                                                                                                                        |
| 729 |    247.465815 |    140.938592 | Zimices                                                                                                                                                               |
| 730 |    323.768646 |    652.510838 | T. Michael Keesey                                                                                                                                                     |
| 731 |    923.622371 |    533.652538 | Danielle Alba                                                                                                                                                         |
| 732 |    440.421932 |    327.273774 | Chris huh                                                                                                                                                             |
| 733 |    243.565554 |     70.280418 | Katie S. Collins                                                                                                                                                      |
| 734 |    128.397519 |    342.811665 | Mattia Menchetti                                                                                                                                                      |
| 735 |    131.448571 |    283.691274 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 736 |    458.248137 |    602.767834 | NA                                                                                                                                                                    |
| 737 |    402.622007 |    213.182735 | Mathilde Cordellier                                                                                                                                                   |
| 738 |    220.099836 |    609.114139 | Matt Crook                                                                                                                                                            |
| 739 |   1017.550111 |    584.225431 | Ferran Sayol                                                                                                                                                          |
| 740 |   1003.647216 |    228.545122 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 741 |    649.554872 |    334.407840 | Christoph Schomburg                                                                                                                                                   |
| 742 |    624.410226 |    159.050341 | Caleb M. Brown                                                                                                                                                        |
| 743 |    254.906713 |    616.467071 | Zimices                                                                                                                                                               |
| 744 |    954.366631 |    243.103027 | Sarah Werning                                                                                                                                                         |
| 745 |    477.007334 |    329.278838 | Emily Willoughby                                                                                                                                                      |
| 746 |    415.724942 |    275.300027 | NA                                                                                                                                                                    |
| 747 |    915.779496 |    609.122677 | Ferran Sayol                                                                                                                                                          |
| 748 |    351.330298 |    678.234841 | NA                                                                                                                                                                    |
| 749 |   1011.539116 |    290.861382 | Gareth Monger                                                                                                                                                         |
| 750 |    656.072237 |    275.229789 | Matt Crook                                                                                                                                                            |
| 751 |    827.098668 |    704.243684 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 752 |    542.081558 |    791.446243 | Harold N Eyster                                                                                                                                                       |
| 753 |    713.218764 |    410.494021 | Yan Wong                                                                                                                                                              |
| 754 |    205.594362 |    132.852058 | Ferran Sayol                                                                                                                                                          |
| 755 |    561.111657 |    316.445463 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 756 |    391.771405 |     53.883146 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 757 |    638.712244 |    307.906151 | Matt Crook                                                                                                                                                            |
| 758 |   1003.901186 |    785.378295 | Matt Crook                                                                                                                                                            |
| 759 |    554.729222 |     24.944011 | Lily Hughes                                                                                                                                                           |
| 760 |    328.473125 |    528.777469 | Jaime Headden                                                                                                                                                         |
| 761 |    282.189775 |    583.021334 | Crystal Maier                                                                                                                                                         |
| 762 |    444.176985 |    359.870042 | Steven Traver                                                                                                                                                         |
| 763 |    554.354289 |    312.936287 | Arthur S. Brum                                                                                                                                                        |
| 764 |    447.832108 |    154.111581 | Scott Hartman                                                                                                                                                         |
| 765 |   1016.732306 |    382.496346 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 766 |    582.768666 |    574.563615 | Christoph Schomburg                                                                                                                                                   |
| 767 |     87.042251 |    719.123751 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 768 |    867.149052 |    160.230862 | Carlos Cano-Barbacil                                                                                                                                                  |
| 769 |    455.934184 |    244.120003 | Zimices                                                                                                                                                               |
| 770 |    805.659830 |    125.136371 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                |
| 771 |     61.275718 |    425.756241 | Gareth Monger                                                                                                                                                         |
| 772 |    698.471464 |    369.726600 | Steven Traver                                                                                                                                                         |
| 773 |    429.311163 |    206.124377 | Gareth Monger                                                                                                                                                         |
| 774 |    224.508987 |     86.831630 | M Kolmann                                                                                                                                                             |
| 775 |    468.814385 |    390.847311 | Tracy A. Heath                                                                                                                                                        |
| 776 |    520.823588 |    153.100475 | Caleb M. Brown                                                                                                                                                        |
| 777 |      9.080462 |    470.497054 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 778 |    640.081462 |    721.497901 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 779 |     18.052458 |    224.715701 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 780 |    515.967509 |    526.422469 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 781 |    405.587626 |    224.577115 | Jagged Fang Designs                                                                                                                                                   |
| 782 |    133.213794 |    438.525977 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 783 |     43.735483 |    138.658090 | M Kolmann                                                                                                                                                             |
| 784 |      7.903885 |    438.520563 | Cesar Julian                                                                                                                                                          |
| 785 |    772.323094 |     37.576502 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 786 |    510.871491 |    748.266444 | Markus A. Grohme                                                                                                                                                      |
| 787 |    721.839037 |    534.088813 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                    |
| 788 |     55.737552 |    528.182463 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 789 |    490.096336 |    107.204981 | Chris huh                                                                                                                                                             |
| 790 |    659.330430 |    390.422693 | Kent Elson Sorgon                                                                                                                                                     |
| 791 |    225.464594 |    188.336551 | Margot Michaud                                                                                                                                                        |
| 792 |    566.282823 |     54.819510 | Matt Crook                                                                                                                                                            |
| 793 |    911.823169 |    129.718149 | Jake Warner                                                                                                                                                           |
| 794 |    876.519125 |    146.463406 | Gareth Monger                                                                                                                                                         |
| 795 |    189.050471 |    129.382538 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 796 |     81.352452 |    245.531208 | NA                                                                                                                                                                    |
| 797 |    336.329991 |    428.283545 | NA                                                                                                                                                                    |
| 798 |     54.057835 |    178.017592 | Jagged Fang Designs                                                                                                                                                   |
| 799 |    462.858765 |    102.263140 | Zimices                                                                                                                                                               |
| 800 |    903.441160 |    687.501014 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 801 |    477.635685 |    440.303853 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 802 |    491.427347 |    792.971879 | Becky Barnes                                                                                                                                                          |
| 803 |    472.621676 |    733.629426 | Patrick Strutzenberger                                                                                                                                                |
| 804 |     37.691620 |    728.860615 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 805 |    595.118389 |     17.880085 | Amanda Katzer                                                                                                                                                         |
| 806 |    112.779753 |     93.042504 | Trond R. Oskars                                                                                                                                                       |
| 807 |     39.944153 |    312.324579 | Jagged Fang Designs                                                                                                                                                   |
| 808 |    684.584147 |    199.376104 | NA                                                                                                                                                                    |
| 809 |     94.076392 |    325.017606 | Zimices                                                                                                                                                               |
| 810 |    483.852771 |     95.281326 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 811 |    501.401521 |    483.174387 | Birgit Lang                                                                                                                                                           |
| 812 |   1001.898024 |    268.146822 | Steven Traver                                                                                                                                                         |
| 813 |    522.916189 |    612.723876 | Pete Buchholz                                                                                                                                                         |
| 814 |    323.365543 |     85.594499 | FunkMonk                                                                                                                                                              |
| 815 |    852.193878 |    494.124108 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 816 |    839.413984 |    346.722151 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 817 |    498.344138 |    417.546836 | Michael Scroggie                                                                                                                                                      |
| 818 |    226.373951 |    127.816768 | Kamil S. Jaron                                                                                                                                                        |
| 819 |    800.766830 |    734.232425 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 820 |    505.270753 |     14.006597 | Gareth Monger                                                                                                                                                         |
| 821 |     52.432377 |    215.104686 | Zimices                                                                                                                                                               |
| 822 |    201.695380 |    484.904709 | Kanchi Nanjo                                                                                                                                                          |
| 823 |    691.681661 |    319.528473 | Steven Traver                                                                                                                                                         |
| 824 |    177.237556 |    709.735735 | Matt Crook                                                                                                                                                            |
| 825 |    925.787955 |    212.537798 | Geoff Shaw                                                                                                                                                            |
| 826 |    778.977868 |    606.705239 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 827 |    876.676131 |    273.874862 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 828 |    518.885375 |    537.401902 | Collin Gross                                                                                                                                                          |
| 829 |    192.923989 |    102.156804 | Ferran Sayol                                                                                                                                                          |
| 830 |    483.016733 |    292.100708 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                                  |
| 831 |     31.019028 |     57.834580 | Milton Tan                                                                                                                                                            |
| 832 |    142.165346 |    291.104629 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 833 |    187.906977 |    600.113325 | Gregor Bucher, Max Farnworth                                                                                                                                          |
| 834 |    584.587683 |     85.535316 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 835 |    838.662918 |    710.537424 | NA                                                                                                                                                                    |
| 836 |     84.060010 |    371.987260 | Maija Karala                                                                                                                                                          |
| 837 |    139.584829 |    789.788375 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 838 |    608.689982 |     64.842871 | Steven Traver                                                                                                                                                         |
| 839 |    767.323293 |    715.334021 | Zimices                                                                                                                                                               |
| 840 |    542.229597 |    448.558079 | Matt Crook                                                                                                                                                            |
| 841 |    661.994782 |    241.675640 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 842 |     95.560270 |    181.745661 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 843 |    697.829923 |    307.175901 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 844 |    825.235427 |    320.193765 | Anthony Caravaggi                                                                                                                                                     |
| 845 |    746.079499 |    487.341433 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 846 |    265.642786 |     26.153389 | Chris huh                                                                                                                                                             |
| 847 |     88.776712 |    392.366889 | Juan Carlos Jerí                                                                                                                                                      |
| 848 |     10.230257 |    290.847094 | Tasman Dixon                                                                                                                                                          |
| 849 |    700.304820 |    314.625366 | Zimices                                                                                                                                                               |
| 850 |    937.895719 |    235.760957 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 851 |    169.835499 |     39.257054 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 852 |    472.383569 |    429.123672 | Kevin Sánchez                                                                                                                                                         |
| 853 |    577.929687 |    178.563407 | Jagged Fang Designs                                                                                                                                                   |
| 854 |    598.827935 |    581.461970 | Tasman Dixon                                                                                                                                                          |
| 855 |    448.304302 |     84.329379 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
| 856 |    488.649019 |    275.333686 | L. Shyamal                                                                                                                                                            |
| 857 |    760.950508 |    174.102969 | Baheerathan Murugavel                                                                                                                                                 |
| 858 |    762.134487 |    753.825378 | NA                                                                                                                                                                    |
| 859 |    553.411733 |    651.688858 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 860 |    435.394731 |    260.854903 | Gareth Monger                                                                                                                                                         |
| 861 |    636.971409 |     76.966918 | T. Michael Keesey                                                                                                                                                     |
| 862 |    594.332094 |    282.881557 | Maija Karala                                                                                                                                                          |
| 863 |    205.014566 |    768.404439 | Matt Martyniuk                                                                                                                                                        |
| 864 |    479.733658 |    382.988883 | Margot Michaud                                                                                                                                                        |
| 865 |    508.030034 |    427.990187 | NA                                                                                                                                                                    |
| 866 |    782.871657 |    291.753174 | NA                                                                                                                                                                    |
| 867 |    568.864036 |     76.989883 | Matt Crook                                                                                                                                                            |
| 868 |     28.823208 |    429.595223 | Scott Hartman                                                                                                                                                         |
| 869 |    153.841752 |    536.657301 | Maija Karala                                                                                                                                                          |
| 870 |    626.384309 |    193.479378 | Milton Tan                                                                                                                                                            |
| 871 |    278.801797 |    530.627175 | NA                                                                                                                                                                    |
| 872 |    429.263984 |    231.382134 | Zimices                                                                                                                                                               |
| 873 |    583.354408 |    264.956490 | Steven Traver                                                                                                                                                         |
| 874 |    876.058544 |    744.142973 | Margot Michaud                                                                                                                                                        |
| 875 |    160.070845 |     63.038847 | Matt Crook                                                                                                                                                            |
| 876 |     47.142964 |    571.592868 | Chris huh                                                                                                                                                             |
| 877 |    713.037475 |    135.173498 | Markus A. Grohme                                                                                                                                                      |
| 878 |    957.310113 |    614.123707 | Christoph Schomburg                                                                                                                                                   |
| 879 |    186.550547 |    512.717370 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 880 |    859.595386 |    728.941445 | Christoph Schomburg                                                                                                                                                   |
| 881 |    899.155464 |    624.140589 | Gareth Monger                                                                                                                                                         |
| 882 |    294.842514 |    152.910083 | Ferran Sayol                                                                                                                                                          |
| 883 |     20.363666 |     89.520704 | CNZdenek                                                                                                                                                              |
| 884 |   1001.923024 |    710.513981 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                    |
| 885 |    562.635354 |    228.207767 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 886 |    458.962037 |    640.543935 | Tommaso Cancellario                                                                                                                                                   |
| 887 |    831.485080 |    241.276555 | Gareth Monger                                                                                                                                                         |
| 888 |    580.124285 |     43.941176 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 889 |    535.631659 |    156.247095 | Chloé Schmidt                                                                                                                                                         |
| 890 |    606.662035 |    791.970872 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 891 |   1011.286130 |    304.327972 | Crystal Maier                                                                                                                                                         |
| 892 |    542.822557 |    205.745372 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
| 893 |    658.577112 |    683.297906 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 894 |    796.456664 |    109.688452 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 895 |    588.641621 |    288.573118 | NA                                                                                                                                                                    |
| 896 |    554.221302 |    383.170980 | Margot Michaud                                                                                                                                                        |
| 897 |    785.943126 |    793.871974 | Jagged Fang Designs                                                                                                                                                   |
| 898 |    779.055696 |    414.964965 | Ferran Sayol                                                                                                                                                          |

    #> Your tweet has been posted!
