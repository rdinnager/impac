
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

Matt Crook, James R. Spotila and Ray Chatterji, Gabriela Palomo-Munoz,
Jagged Fang Designs, Katie S. Collins, Sarah Werning, Tasman Dixon,
Zachary Quigley, Ieuan Jones, Matt Martyniuk, Sergio A. Muñoz-Gómez,
Steven Traver, Matus Valach, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Scott Hartman, Chris huh, T. Michael Keesey (vectorization);
Yves Bousquet (photography), Felix Vaux, Michelle Site, Tracy A. Heath,
Zimices, Inessa Voet, Margot Michaud, Smith609 and T. Michael Keesey,
Collin Gross, Maxwell Lefroy (vectorized by T. Michael Keesey), Lukas
Panzarin, Ferran Sayol, Sebastian Stabinger, Nobu Tamura, vectorized by
Zimices, Mathew Wedel, Roberto Díaz Sibaja, Nobu Tamura (vectorized by
T. Michael Keesey), Iain Reid, Shyamal, Giant Blue Anteater (vectorized
by T. Michael Keesey), Smokeybjb, Tauana J. Cunha, Tony Ayling
(vectorized by Milton Tan), www.studiospectre.com, Beth Reinke, T.
Michael Keesey, Original drawing by Antonov, vectorized by Roberto Díaz
Sibaja, Kamil S. Jaron, CNZdenek, Jack Mayer Wood, David Orr, Lauren
Anderson, Dinah Challen, Matt Martyniuk (modified by Serenchia), Sharon
Wegner-Larsen, Lukasiniho, Oren Peles / vectorized by Yan Wong, Joanna
Wolfe, Nobu Tamura, Falconaumanni and T. Michael Keesey, Gareth Monger,
Alex Slavenko, Mason McNair, DW Bapst (modified from Bates et al.,
2005), Alexandre Vong, Jaime Headden, Jimmy Bernot, Matt Wilkins (photo
by Patrick Kavanagh), L. Shyamal, Matthew E. Clapham, Francis de Laporte
de Castelnau (vectorized by T. Michael Keesey), Anthony Caravaggi,
Robert Bruce Horsfall, vectorized by Zimices, Emily Willoughby, Jaime A.
Headden (vectorized by T. Michael Keesey), C. Camilo Julián-Caballero,
Mattia Menchetti, Carlos Cano-Barbacil, Rebecca Groom, Arthur S. Brum,
Plukenet, C. W. Nash (illustration) and Timothy J. Bartley (silhouette),
. Original drawing by M. Antón, published in Montoya and Morales 1984.
Vectorized by O. Sanisidro, Rainer Schoch, Henry Lydecker, wsnaccad,
Gabriele Midolo, Melissa Broussard, Timothy Knepp of the U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Dmitry Bogdanov, Steve Hillebrand/U. S. Fish and Wildlife Service
(source photo), T. Michael Keesey (vectorization), Andrew A. Farke,
Jiekun He, Martin R. Smith, Juan Carlos Jerí, Harold N Eyster, Andy
Wilson, Hugo Gruson, Anilocra (vectorization by Yan Wong), Mary Harrsch
(modified by T. Michael Keesey), Chuanixn Yu, Tommaso Cancellario,
Scarlet23 (vectorized by T. Michael Keesey), M Kolmann, FunkMonk, Armin
Reindl, Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey),
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Birgit Lang, Joschua Knüppe,
Alexander Schmidt-Lebuhn, T. Michael Keesey (photo by Sean Mack), Darren
Naish (vectorized by T. Michael Keesey), Jose Carlos Arenas-Monroy, A.
H. Baldwin (vectorized by T. Michael Keesey), Gabriel Lio, vectorized by
Zimices, Christoph Schomburg, Michael P. Taylor, Markus A. Grohme,
Charles R. Knight (vectorized by T. Michael Keesey), Michael “FunkMonk”
B. H. (vectorized by T. Michael Keesey), Scott Hartman (vectorized by T.
Michael Keesey), Sidney Frederic Harmer, Arthur Everett Shipley
(vectorized by Maxime Dahirel), Smokeybjb (vectorized by T. Michael
Keesey), Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Ingo Braasch, Noah
Schlottman, photo by Martin V. Sørensen, Siobhon Egan, Todd Marshall,
vectorized by Zimices, Ralf Janssen, Nikola-Michael Prpic & Wim G. M.
Damen (vectorized by T. Michael Keesey), terngirl, Terpsichores,
Peileppe, John Curtis (vectorized by T. Michael Keesey), Taro Maeda,
Matt Martyniuk (vectorized by T. Michael Keesey), Mike Hanson,
Benjamint444, Andreas Trepte (vectorized by T. Michael Keesey), Hans
Hillewaert (vectorized by T. Michael Keesey), Caio Bernardes, vectorized
by Zimices, Doug Backlund (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Ignacio Contreras, Tony Ayling, Mathieu
Pélissié, Maxime Dahirel, Jerry Oldenettel (vectorized by T. Michael
Keesey), Michele M Tobias, Cristian Osorio & Paula Carrera, Proyecto
Carnivoros Australes (www.carnivorosaustrales.org), Chloé Schmidt,
Ghedoghedo (vectorized by T. Michael Keesey), Birgit Lang; based on a
drawing by C.L. Koch, Sean McCann, Dean Schnabel, Gopal Murali,
Griensteidl and T. Michael Keesey, Lani Mohan, Christine Axon, Scott
Hartman (modified by T. Michael Keesey), Jebulon (vectorized by T.
Michael Keesey), Matt Hayes, Baheerathan Murugavel, Mali’o Kodis, image
by Rebecca Ritger, Emily Jane McTavish, from Haeckel, E. H. P. A.
(1904).Kunstformen der Natur. Bibliographisches, Jon Hill (Photo by
Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Andrew A.
Farke, modified from original by Robert Bruce Horsfall, from Scott 1912,
Emily Jane McTavish, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Caleb M. Brown, Luc
Viatour (source photo) and Andreas Plank, ArtFavor & annaleeblysse,
Steven Coombs, Philippe Janvier (vectorized by T. Michael Keesey), Frank
Förster (based on a picture by Jerry Kirkhart; modified by T. Michael
Keesey), Geoff Shaw, Chris Hay, Yan Wong from photo by Denes Emoke, Lisa
M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Kanchi Nanjo, Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Erika Schumacher,
xgirouxb, Dmitry Bogdanov, vectorized by Zimices, Smokeybjb (modified by
T. Michael Keesey), Riccardo Percudani, G. M. Woodward, Andrew A. Farke,
modified from original by H. Milne Edwards, H. F. O. March (modified by
T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Nina Skinner,
Diana Pomeroy, Jonathan Lawley, Mali’o Kodis, image from the Smithsonian
Institution, Servien (vectorized by T. Michael Keesey), Maija Karala,
Renata F. Martins, Conty, Mali’o Kodis, photograph by Bruno Vellutini,
T. Tischler, Campbell Fleming, Karina Garcia, Javiera Constanzo,
kreidefossilien.de, T. Michael Keesey (after Joseph Wolf), Pearson Scott
Foresman (vectorized by T. Michael Keesey), Renato de Carvalho Ferreira,
Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist,
Henry Fairfield Osborn, vectorized by Zimices, Xavier Giroux-Bougard,
Oliver Voigt, Burton Robert, USFWS, Verisimilus, Jon Hill (Photo by
DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Wynston
Cooper (photo) and Albertonykus (silhouette), Crystal Maier,
Apokryltaros (vectorized by T. Michael Keesey), Charles Doolittle
Walcott (vectorized by T. Michael Keesey), NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Heinrich Harder (vectorized by William Gearty), Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Roule Jammes (vectorized by T. Michael Keesey), Julio Garza, Noah
Schlottman, photo by Casey Dunn, Remes K, Ortega F, Fierro I, Joger U,
Kosma R, et al., Ville Koistinen (vectorized by T. Michael Keesey),
Zimices / Julián Bayona, Jaime Headden, modified by T. Michael Keesey,
B. Duygu Özpolat, Yan Wong, Richard Lampitt, Jeremy Young / NHM
(vectorization by Yan Wong), Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Kanako
Bessho-Uehara, Scott Hartman, modified by T. Michael Keesey, Oscar
Sanisidro, Anna Willoughby, Cesar Julian, LeonardoG (photography) and T.
Michael Keesey (vectorization), Pete Buchholz, Nobu Tamura, modified by
Andrew A. Farke, Lee Harding (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Evan-Amos (vectorized by T. Michael
Keesey), Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Ghedo (vectorized by T. Michael
Keesey), Kent Elson Sorgon, Myriam\_Ramirez, nicubunu, Didier Descouens
(vectorized by T. Michael Keesey), T. Michael Keesey (after Kukalová),
Mihai Dragos (vectorized by T. Michael Keesey), Mike Keesey
(vectorization) and Vaibhavcho (photography), Karla Martinez, George
Edward Lodge, Joseph Wolf, 1863 (vectorization by Dinah Challen), Milton
Tan, Trond R. Oskars, Farelli (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, T. Michael Keesey (from a mount by
Allis Markham), DFoidl (vectorized by T. Michael Keesey), Michael B. H.
(vectorized by T. Michael Keesey), Ernst Haeckel (vectorized by T.
Michael Keesey), Qiang Ou, Yan Wong from illustration by Charles
Orbigny, Mali’o Kodis, photograph by G. Giribet, Tyler McCraney,
Verdilak, Jon Hill, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), Armelle Ansart (photograph), Maxime Dahirel
(digitisation), Hans Hillewaert

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    147.183236 |    602.636470 | Matt Crook                                                                                                                                                            |
|   2 |    765.643787 |    574.338740 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|   3 |    896.932225 |    113.626541 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   4 |    268.902247 |    777.991660 | Jagged Fang Designs                                                                                                                                                   |
|   5 |    545.763241 |    682.638222 | Katie S. Collins                                                                                                                                                      |
|   6 |    414.356683 |    621.356222 | Sarah Werning                                                                                                                                                         |
|   7 |    699.483043 |    245.663659 | Tasman Dixon                                                                                                                                                          |
|   8 |    945.661958 |    325.303354 | Zachary Quigley                                                                                                                                                       |
|   9 |    303.548220 |    142.709470 | Ieuan Jones                                                                                                                                                           |
|  10 |    782.304215 |    445.035499 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  11 |    613.622547 |    406.488764 | Matt Martyniuk                                                                                                                                                        |
|  12 |    215.314196 |    699.902918 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  13 |    169.761040 |    343.849667 | Steven Traver                                                                                                                                                         |
|  14 |    687.552251 |    326.383410 | Jagged Fang Designs                                                                                                                                                   |
|  15 |    895.229076 |    524.971518 | Matus Valach                                                                                                                                                          |
|  16 |    629.949433 |     65.979668 | Steven Traver                                                                                                                                                         |
|  17 |    358.086959 |    554.198848 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  18 |    236.731534 |    509.456353 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  19 |    422.841270 |    379.376105 | Scott Hartman                                                                                                                                                         |
|  20 |     82.418639 |    387.626538 | NA                                                                                                                                                                    |
|  21 |    365.685755 |    290.800094 | Matt Crook                                                                                                                                                            |
|  22 |    622.426139 |    170.055061 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  23 |    891.416660 |    367.218274 | Scott Hartman                                                                                                                                                         |
|  24 |    267.158500 |    455.520767 | Chris huh                                                                                                                                                             |
|  25 |    851.581529 |    287.179930 | Tasman Dixon                                                                                                                                                          |
|  26 |    508.944319 |    477.837101 | Katie S. Collins                                                                                                                                                      |
|  27 |     60.931592 |    642.698613 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
|  28 |    668.330929 |    735.458238 | Felix Vaux                                                                                                                                                            |
|  29 |    483.037607 |     79.251731 | Steven Traver                                                                                                                                                         |
|  30 |    781.227788 |    714.850048 | Michelle Site                                                                                                                                                         |
|  31 |    112.241353 |    453.905772 | Jagged Fang Designs                                                                                                                                                   |
|  32 |    537.763446 |    275.168166 | Tracy A. Heath                                                                                                                                                        |
|  33 |    115.733844 |    524.669373 | Zimices                                                                                                                                                               |
|  34 |    902.872053 |    682.756213 | NA                                                                                                                                                                    |
|  35 |    306.968212 |    741.192623 | Inessa Voet                                                                                                                                                           |
|  36 |    277.423941 |    604.397766 | Zimices                                                                                                                                                               |
|  37 |    100.542524 |    205.491280 | Margot Michaud                                                                                                                                                        |
|  38 |    974.439377 |    418.832056 | Smith609 and T. Michael Keesey                                                                                                                                        |
|  39 |    298.197310 |     33.983599 | Collin Gross                                                                                                                                                          |
|  40 |    639.471232 |    584.368638 | Zimices                                                                                                                                                               |
|  41 |    417.029784 |    695.509577 | Matt Crook                                                                                                                                                            |
|  42 |    716.511421 |    119.985896 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
|  43 |     68.653393 |     52.680283 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  44 |    197.308108 |    241.069418 | Lukas Panzarin                                                                                                                                                        |
|  45 |    670.337715 |    491.693216 | Matt Crook                                                                                                                                                            |
|  46 |    111.342206 |    735.803003 | Ferran Sayol                                                                                                                                                          |
|  47 |    349.090462 |    219.124827 | Sebastian Stabinger                                                                                                                                                   |
|  48 |    100.460092 |    112.657043 | Matt Crook                                                                                                                                                            |
|  49 |    730.120673 |    637.715344 | Tasman Dixon                                                                                                                                                          |
|  50 |    522.829036 |    196.070905 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  51 |    772.125104 |     71.355073 | Steven Traver                                                                                                                                                         |
|  52 |    443.905138 |    329.860228 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  53 |    340.875767 |    421.019531 | Mathew Wedel                                                                                                                                                          |
|  54 |    697.027371 |    385.704078 | Tasman Dixon                                                                                                                                                          |
|  55 |    653.280039 |    672.236537 | Roberto Díaz Sibaja                                                                                                                                                   |
|  56 |    502.933332 |    574.078120 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  57 |    927.809212 |    756.115953 | Iain Reid                                                                                                                                                             |
|  58 |    812.438026 |    235.460463 | Jagged Fang Designs                                                                                                                                                   |
|  59 |    546.047283 |    349.333379 | Shyamal                                                                                                                                                               |
|  60 |    983.585587 |    668.677846 | NA                                                                                                                                                                    |
|  61 |    532.983846 |     25.400618 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
|  62 |    957.493754 |    233.085850 | Smokeybjb                                                                                                                                                             |
|  63 |    969.196250 |     65.914475 | Ferran Sayol                                                                                                                                                          |
|  64 |    974.920593 |    308.500876 | Tauana J. Cunha                                                                                                                                                       |
|  65 |    931.060657 |     68.310620 | Tauana J. Cunha                                                                                                                                                       |
|  66 |    246.890372 |    216.200817 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
|  67 |    167.492912 |    769.784221 | Margot Michaud                                                                                                                                                        |
|  68 |    832.253567 |    650.122735 | www.studiospectre.com                                                                                                                                                 |
|  69 |    134.299779 |    679.493625 | Jagged Fang Designs                                                                                                                                                   |
|  70 |    935.895530 |    680.965763 | Beth Reinke                                                                                                                                                           |
|  71 |    538.741288 |    140.508044 | T. Michael Keesey                                                                                                                                                     |
|  72 |    849.380028 |    615.673421 | Matt Crook                                                                                                                                                            |
|  73 |   1002.817176 |    438.541291 | Margot Michaud                                                                                                                                                        |
|  74 |     24.895981 |    549.166159 | Zimices                                                                                                                                                               |
|  75 |    523.159041 |    173.397890 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
|  76 |    198.110104 |    294.672991 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  77 |     65.369478 |    331.065010 | Kamil S. Jaron                                                                                                                                                        |
|  78 |    783.449022 |    788.833015 | Steven Traver                                                                                                                                                         |
|  79 |     44.346893 |    737.809101 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  80 |    825.319664 |    764.446149 | CNZdenek                                                                                                                                                              |
|  81 |    766.663666 |    342.392001 | Jack Mayer Wood                                                                                                                                                       |
|  82 |    251.977240 |    397.282568 | Margot Michaud                                                                                                                                                        |
|  83 |    770.957077 |    266.485628 | David Orr                                                                                                                                                             |
|  84 |    689.448992 |    768.914732 | Sarah Werning                                                                                                                                                         |
|  85 |    805.870912 |    614.807942 | Lauren Anderson                                                                                                                                                       |
|  86 |    201.570619 |    660.539407 | Dinah Challen                                                                                                                                                         |
|  87 |     28.812376 |     22.823549 | Chris huh                                                                                                                                                             |
|  88 |    323.105004 |    667.772874 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
|  89 |    737.026570 |    270.555638 | Sharon Wegner-Larsen                                                                                                                                                  |
|  90 |    386.773400 |    754.276918 | Lukasiniho                                                                                                                                                            |
|  91 |     17.232499 |    492.804954 | Jagged Fang Designs                                                                                                                                                   |
|  92 |     18.753139 |    190.042404 | CNZdenek                                                                                                                                                              |
|  93 |    192.858801 |     45.530247 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
|  94 |    888.166746 |    399.196319 | Joanna Wolfe                                                                                                                                                          |
|  95 |     17.393524 |    622.079255 | Michelle Site                                                                                                                                                         |
|  96 |    468.706556 |    300.457738 | Nobu Tamura                                                                                                                                                           |
|  97 |    858.914255 |    531.048461 | Lukasiniho                                                                                                                                                            |
|  98 |    402.654488 |    461.741177 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
|  99 |     51.403296 |    771.448441 | Gareth Monger                                                                                                                                                         |
| 100 |    181.822857 |     11.900556 | Zimices                                                                                                                                                               |
| 101 |    817.313920 |    396.645270 | Alex Slavenko                                                                                                                                                         |
| 102 |    947.805889 |    274.447294 | NA                                                                                                                                                                    |
| 103 |    241.958531 |    714.707782 | Gareth Monger                                                                                                                                                         |
| 104 |    578.971432 |     90.399068 | Mason McNair                                                                                                                                                          |
| 105 |    226.769952 |    731.030038 | NA                                                                                                                                                                    |
| 106 |    392.827205 |    504.912907 | Tasman Dixon                                                                                                                                                          |
| 107 |    997.292079 |    294.322396 | Scott Hartman                                                                                                                                                         |
| 108 |    757.686116 |    390.767653 | Tasman Dixon                                                                                                                                                          |
| 109 |    212.821032 |    668.598968 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
| 110 |    646.798037 |    109.515857 | NA                                                                                                                                                                    |
| 111 |    687.237408 |    645.305150 | Michelle Site                                                                                                                                                         |
| 112 |    260.334820 |    315.343536 | Alexandre Vong                                                                                                                                                        |
| 113 |     54.172287 |    712.503725 | Matt Crook                                                                                                                                                            |
| 114 |    923.060216 |    561.191157 | Gareth Monger                                                                                                                                                         |
| 115 |    801.182682 |    504.785582 | Steven Traver                                                                                                                                                         |
| 116 |    424.629176 |    188.032461 | NA                                                                                                                                                                    |
| 117 |    421.589354 |     30.675685 | Jaime Headden                                                                                                                                                         |
| 118 |    917.448805 |    529.984576 | Jagged Fang Designs                                                                                                                                                   |
| 119 |    825.993288 |    106.923488 | T. Michael Keesey                                                                                                                                                     |
| 120 |    819.671816 |    176.691015 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 121 |    864.644605 |    341.312419 | Steven Traver                                                                                                                                                         |
| 122 |    277.198766 |    659.671056 | Gareth Monger                                                                                                                                                         |
| 123 |    634.184346 |    422.851271 | Jagged Fang Designs                                                                                                                                                   |
| 124 |    908.053699 |    437.882026 | T. Michael Keesey                                                                                                                                                     |
| 125 |    712.685361 |    197.140753 | Margot Michaud                                                                                                                                                        |
| 126 |     52.537059 |    113.302492 | Jimmy Bernot                                                                                                                                                          |
| 127 |    826.216346 |    598.925398 | Mason McNair                                                                                                                                                          |
| 128 |    518.511691 |    692.013259 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 129 |    147.286128 |    477.703442 | Zimices                                                                                                                                                               |
| 130 |    208.837659 |    758.379848 | Gareth Monger                                                                                                                                                         |
| 131 |    443.145369 |     88.012475 | Joanna Wolfe                                                                                                                                                          |
| 132 |    234.032861 |     61.180842 | Zimices                                                                                                                                                               |
| 133 |    617.957026 |    289.722893 | Scott Hartman                                                                                                                                                         |
| 134 |    458.990233 |    266.984966 | L. Shyamal                                                                                                                                                            |
| 135 |    203.967566 |    486.656030 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 136 |    457.325422 |    749.329826 | Matthew E. Clapham                                                                                                                                                    |
| 137 |   1010.438114 |    246.459879 | Jagged Fang Designs                                                                                                                                                   |
| 138 |    301.132480 |    274.916750 | Chris huh                                                                                                                                                             |
| 139 |    918.119384 |     98.102670 | Shyamal                                                                                                                                                               |
| 140 |     56.183599 |    559.626599 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 141 |    825.748430 |    157.133720 | Zimices                                                                                                                                                               |
| 142 |    724.170617 |    661.214124 | Anthony Caravaggi                                                                                                                                                     |
| 143 |     57.128683 |    252.189980 | Matt Crook                                                                                                                                                            |
| 144 |    634.902128 |    624.866931 | Zimices                                                                                                                                                               |
| 145 |    174.750177 |     54.605701 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 146 |    488.400324 |    303.463223 | Alexandre Vong                                                                                                                                                        |
| 147 |    209.035680 |    546.899664 | T. Michael Keesey                                                                                                                                                     |
| 148 |    175.857346 |    590.601822 | T. Michael Keesey                                                                                                                                                     |
| 149 |    126.662009 |    115.555263 | Ferran Sayol                                                                                                                                                          |
| 150 |     49.126140 |    494.627127 | Emily Willoughby                                                                                                                                                      |
| 151 |    759.946165 |    260.169593 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 152 |    790.589100 |     19.045856 | C. Camilo Julián-Caballero                                                                                                                                            |
| 153 |    675.068286 |    131.430658 | Steven Traver                                                                                                                                                         |
| 154 |    855.062187 |    446.805927 | Beth Reinke                                                                                                                                                           |
| 155 |     93.300881 |     74.115290 | Steven Traver                                                                                                                                                         |
| 156 |    292.736669 |    250.039645 | Matt Crook                                                                                                                                                            |
| 157 |    126.446682 |    574.657353 | Steven Traver                                                                                                                                                         |
| 158 |    784.632364 |    209.244867 | Mattia Menchetti                                                                                                                                                      |
| 159 |     84.330895 |    568.188899 | Carlos Cano-Barbacil                                                                                                                                                  |
| 160 |    297.917370 |    553.950236 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 161 |     78.833464 |    316.802016 | Rebecca Groom                                                                                                                                                         |
| 162 |    215.024765 |     81.267723 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 163 |    301.712191 |    687.980485 | Arthur S. Brum                                                                                                                                                        |
| 164 |    837.105250 |    747.257158 | Gareth Monger                                                                                                                                                         |
| 165 |    870.139598 |    508.547334 | C. Camilo Julián-Caballero                                                                                                                                            |
| 166 |    563.008730 |    163.920702 | NA                                                                                                                                                                    |
| 167 |    853.280948 |    429.782986 | Steven Traver                                                                                                                                                         |
| 168 |    569.943728 |    566.062742 | Chris huh                                                                                                                                                             |
| 169 |     26.383330 |    330.335903 | Plukenet                                                                                                                                                              |
| 170 |    630.941966 |    114.698598 | Michelle Site                                                                                                                                                         |
| 171 |    387.820094 |    314.934698 | L. Shyamal                                                                                                                                                            |
| 172 |    158.168202 |    682.489575 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 173 |    700.146850 |     31.543875 | Tasman Dixon                                                                                                                                                          |
| 174 |    603.641142 |    320.411229 | Margot Michaud                                                                                                                                                        |
| 175 |    772.824028 |    511.770979 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 176 |    999.434274 |    614.744193 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 177 |    158.098769 |    295.857958 | Zimices                                                                                                                                                               |
| 178 |    263.860180 |    405.340696 | Rainer Schoch                                                                                                                                                         |
| 179 |    900.517671 |    659.977414 | Henry Lydecker                                                                                                                                                        |
| 180 |     12.134243 |    259.013522 | Sarah Werning                                                                                                                                                         |
| 181 |    354.125138 |    196.746429 | wsnaccad                                                                                                                                                              |
| 182 |     44.841731 |    293.211817 | Margot Michaud                                                                                                                                                        |
| 183 |      7.717342 |    455.573273 | NA                                                                                                                                                                    |
| 184 |    201.244547 |     63.741871 | Gabriele Midolo                                                                                                                                                       |
| 185 |    554.812839 |    585.777337 | Iain Reid                                                                                                                                                             |
| 186 |   1013.940872 |     41.214360 | Katie S. Collins                                                                                                                                                      |
| 187 |    445.140117 |    106.764716 | Steven Traver                                                                                                                                                         |
| 188 |     14.680155 |    272.388219 | Sarah Werning                                                                                                                                                         |
| 189 |    720.693029 |    607.368924 | Tasman Dixon                                                                                                                                                          |
| 190 |    437.606611 |    286.166209 | Matt Crook                                                                                                                                                            |
| 191 |    752.780961 |    181.394417 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 192 |    744.490574 |    520.909056 | Melissa Broussard                                                                                                                                                     |
| 193 |    320.222572 |    475.788739 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 194 |    750.439243 |    109.470195 | Dmitry Bogdanov                                                                                                                                                       |
| 195 |    294.523031 |    308.972896 | Jagged Fang Designs                                                                                                                                                   |
| 196 |    720.069955 |    545.442352 | Scott Hartman                                                                                                                                                         |
| 197 |    338.807907 |    488.706752 | Katie S. Collins                                                                                                                                                      |
| 198 |    809.581752 |    722.437118 | Margot Michaud                                                                                                                                                        |
| 199 |    911.921874 |    390.980894 | Michelle Site                                                                                                                                                         |
| 200 |    552.789903 |     42.752575 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 201 |    517.543805 |    374.323200 | Zimices                                                                                                                                                               |
| 202 |    187.636573 |    261.976659 | NA                                                                                                                                                                    |
| 203 |     17.081169 |    595.871077 | Tasman Dixon                                                                                                                                                          |
| 204 |    607.710840 |    781.612356 | NA                                                                                                                                                                    |
| 205 |    131.247014 |    666.082661 | T. Michael Keesey                                                                                                                                                     |
| 206 |     94.096034 |    788.847615 | Tracy A. Heath                                                                                                                                                        |
| 207 |    732.200521 |    494.326135 | Andrew A. Farke                                                                                                                                                       |
| 208 |    342.580952 |    714.742415 | Jiekun He                                                                                                                                                             |
| 209 |    885.279987 |    217.971912 | Zimices                                                                                                                                                               |
| 210 |    643.699276 |     13.337170 | Gareth Monger                                                                                                                                                         |
| 211 |    806.837358 |    702.221555 | Anthony Caravaggi                                                                                                                                                     |
| 212 |    115.601578 |     73.169998 | Martin R. Smith                                                                                                                                                       |
| 213 |    966.507372 |    256.582370 | Zimices                                                                                                                                                               |
| 214 |    535.411645 |    390.124842 | Juan Carlos Jerí                                                                                                                                                      |
| 215 |    619.960675 |    704.552253 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
| 216 |    884.747653 |    252.515298 | Scott Hartman                                                                                                                                                         |
| 217 |    185.188535 |     70.867131 | Steven Traver                                                                                                                                                         |
| 218 |    441.765448 |    645.723585 | Gareth Monger                                                                                                                                                         |
| 219 |    289.953030 |     62.494058 | Harold N Eyster                                                                                                                                                       |
| 220 |    979.425739 |    213.949766 | Zimices                                                                                                                                                               |
| 221 |    981.180523 |    779.864119 | Alex Slavenko                                                                                                                                                         |
| 222 |    154.055422 |    539.474869 | Andy Wilson                                                                                                                                                           |
| 223 |    594.762134 |    225.619112 | Hugo Gruson                                                                                                                                                           |
| 224 |    737.878254 |    666.946623 | Matt Crook                                                                                                                                                            |
| 225 |    788.777145 |    740.660490 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 226 |     19.496367 |    102.103198 | Rebecca Groom                                                                                                                                                         |
| 227 |     81.201770 |    476.209821 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 228 |    801.719912 |    487.478358 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 229 |    191.953633 |    746.603630 | Zimices                                                                                                                                                               |
| 230 |    351.804020 |    464.343729 | Chuanixn Yu                                                                                                                                                           |
| 231 |    302.671973 |    221.314319 | Tommaso Cancellario                                                                                                                                                   |
| 232 |     30.894934 |    576.180233 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 233 |    266.470113 |    744.110336 | T. Michael Keesey                                                                                                                                                     |
| 234 |    999.253150 |    183.572893 | T. Michael Keesey                                                                                                                                                     |
| 235 |    926.063152 |    264.116492 | M Kolmann                                                                                                                                                             |
| 236 |    631.121143 |    777.240857 | FunkMonk                                                                                                                                                              |
| 237 |    359.311461 |    784.514400 | Armin Reindl                                                                                                                                                          |
| 238 |    392.229105 |    717.153183 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 239 |    358.846980 |     66.749115 | Tasman Dixon                                                                                                                                                          |
| 240 |    608.145136 |    535.746654 | Jagged Fang Designs                                                                                                                                                   |
| 241 |    734.522797 |    470.732968 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 242 |    244.128269 |    333.625814 | Birgit Lang                                                                                                                                                           |
| 243 |    433.321990 |    353.332191 | Gareth Monger                                                                                                                                                         |
| 244 |    323.431122 |    283.088186 | Joschua Knüppe                                                                                                                                                        |
| 245 |    659.105930 |    701.751810 | Scott Hartman                                                                                                                                                         |
| 246 |    262.120167 |     43.896103 | Matt Crook                                                                                                                                                            |
| 247 |    961.690847 |    778.104137 | Margot Michaud                                                                                                                                                        |
| 248 |    998.609519 |    516.674657 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 249 |    370.546988 |    477.784987 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 250 |    542.649810 |    174.659876 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 251 |    787.973555 |    313.543271 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 252 |    696.584782 |    187.371246 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 253 |    979.459494 |    524.438986 | Shyamal                                                                                                                                                               |
| 254 |    723.031276 |     45.135648 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 255 |    200.109438 |    696.033773 | Christoph Schomburg                                                                                                                                                   |
| 256 |    842.935828 |    242.437678 | Gareth Monger                                                                                                                                                         |
| 257 |    925.482715 |    639.396889 | Joanna Wolfe                                                                                                                                                          |
| 258 |    238.545639 |    491.796907 | NA                                                                                                                                                                    |
| 259 |   1007.411801 |    604.979297 | Andy Wilson                                                                                                                                                           |
| 260 |    871.269003 |    236.406598 | Michael P. Taylor                                                                                                                                                     |
| 261 |    428.683752 |    423.250227 | Chris huh                                                                                                                                                             |
| 262 |    590.071593 |    558.493711 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 263 |    995.206611 |    792.141748 | Markus A. Grohme                                                                                                                                                      |
| 264 |    256.329985 |    484.324523 | Markus A. Grohme                                                                                                                                                      |
| 265 |    105.697100 |     15.259169 | T. Michael Keesey                                                                                                                                                     |
| 266 |    595.876265 |    600.575375 | Joanna Wolfe                                                                                                                                                          |
| 267 |    725.867376 |    779.265538 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 268 |    248.001114 |    189.248864 | Lukasiniho                                                                                                                                                            |
| 269 |   1007.392084 |    781.476144 | Zimices                                                                                                                                                               |
| 270 |     24.839821 |    115.484237 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 271 |    327.039860 |    461.946784 | NA                                                                                                                                                                    |
| 272 |    385.903181 |     11.292001 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 273 |    637.865148 |    347.971726 | NA                                                                                                                                                                    |
| 274 |    372.903398 |     37.028739 | Tasman Dixon                                                                                                                                                          |
| 275 |    261.704653 |    642.538507 | Ferran Sayol                                                                                                                                                          |
| 276 |    618.488475 |    332.419575 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 277 |    191.115390 |    575.233169 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 278 |    441.420164 |    407.367089 | Matt Crook                                                                                                                                                            |
| 279 |    929.328248 |    394.373220 | Andy Wilson                                                                                                                                                           |
| 280 |    606.369407 |     74.221750 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 281 |     33.999271 |    405.692171 | Juan Carlos Jerí                                                                                                                                                      |
| 282 |    252.004733 |    198.387135 | Tasman Dixon                                                                                                                                                          |
| 283 |    913.573279 |    649.925168 | Michael P. Taylor                                                                                                                                                     |
| 284 |    107.965943 |    777.579134 | Chris huh                                                                                                                                                             |
| 285 |     11.750898 |    158.847257 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 286 |     25.459003 |    235.122589 | Ingo Braasch                                                                                                                                                          |
| 287 |     91.861225 |    268.228505 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 288 |    313.286313 |    272.754599 | L. Shyamal                                                                                                                                                            |
| 289 |     68.349868 |    290.816316 | Siobhon Egan                                                                                                                                                          |
| 290 |    395.974846 |    657.838049 | Felix Vaux                                                                                                                                                            |
| 291 |    625.872318 |    436.978411 | Christoph Schomburg                                                                                                                                                   |
| 292 |    298.870413 |    521.633366 | NA                                                                                                                                                                    |
| 293 |    121.705372 |    420.366366 | Scott Hartman                                                                                                                                                         |
| 294 |    229.136589 |    284.080268 | Tasman Dixon                                                                                                                                                          |
| 295 |    710.432555 |    742.943023 | Steven Traver                                                                                                                                                         |
| 296 |    128.067491 |    451.147227 | Zimices                                                                                                                                                               |
| 297 |    120.095311 |    460.681227 | Matus Valach                                                                                                                                                          |
| 298 |    568.761506 |    330.971344 | M Kolmann                                                                                                                                                             |
| 299 |    656.164243 |    376.495630 | Gareth Monger                                                                                                                                                         |
| 300 |    856.705194 |    776.320341 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 301 |    889.427491 |    536.554960 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 302 |    105.668539 |    566.097814 | terngirl                                                                                                                                                              |
| 303 |    420.115956 |    115.879067 | Shyamal                                                                                                                                                               |
| 304 |    439.962575 |    765.343586 | Scott Hartman                                                                                                                                                         |
| 305 |    147.812193 |    554.110348 | Kamil S. Jaron                                                                                                                                                        |
| 306 |    291.396491 |    538.338667 | FunkMonk                                                                                                                                                              |
| 307 |    383.599608 |    357.664898 | Terpsichores                                                                                                                                                          |
| 308 |    245.873989 |    270.970870 | Peileppe                                                                                                                                                              |
| 309 |    196.759597 |    612.369836 | Sharon Wegner-Larsen                                                                                                                                                  |
| 310 |    152.321471 |     30.368981 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 311 |     23.386984 |    749.172901 | Taro Maeda                                                                                                                                                            |
| 312 |    872.549084 |    404.701201 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 313 |    146.495475 |      9.087239 | terngirl                                                                                                                                                              |
| 314 |    165.549328 |    643.822544 | Ferran Sayol                                                                                                                                                          |
| 315 |    335.065308 |    270.252548 | Armin Reindl                                                                                                                                                          |
| 316 |    417.700755 |     73.394562 | Ferran Sayol                                                                                                                                                          |
| 317 |    519.185857 |    409.017658 | Tasman Dixon                                                                                                                                                          |
| 318 |    617.392788 |    356.483342 | Markus A. Grohme                                                                                                                                                      |
| 319 |    889.389863 |    771.550115 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 320 |    366.779878 |    510.343168 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 321 |    230.802515 |    480.782379 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 322 |    319.307586 |    483.082381 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 323 |    828.020457 |    385.172821 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 324 |    741.229154 |    721.868158 | Margot Michaud                                                                                                                                                        |
| 325 |    265.966658 |     68.422947 | Mike Hanson                                                                                                                                                           |
| 326 |    371.799194 |    427.217159 | Zimices                                                                                                                                                               |
| 327 |    861.304155 |    180.383539 | Sharon Wegner-Larsen                                                                                                                                                  |
| 328 |     13.404810 |    211.133896 | Benjamint444                                                                                                                                                          |
| 329 |    998.735417 |     91.590513 | Alex Slavenko                                                                                                                                                         |
| 330 |    617.857278 |    372.908230 | Zimices                                                                                                                                                               |
| 331 |    174.083204 |    528.253012 | Gareth Monger                                                                                                                                                         |
| 332 |     21.078310 |    706.162019 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 333 |     23.482559 |    531.139096 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 334 |    807.645466 |    356.841893 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 335 |    145.105313 |    419.584566 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 336 |    911.673633 |    454.188403 | NA                                                                                                                                                                    |
| 337 |    299.428994 |    670.064392 | Andy Wilson                                                                                                                                                           |
| 338 |    787.988657 |    647.956971 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 339 |    741.527070 |    697.845078 | Harold N Eyster                                                                                                                                                       |
| 340 |    282.942841 |    758.936148 | Steven Traver                                                                                                                                                         |
| 341 |    428.198657 |    590.320255 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 342 |    796.881550 |    522.085685 | Markus A. Grohme                                                                                                                                                      |
| 343 |     32.784569 |    690.901745 | Margot Michaud                                                                                                                                                        |
| 344 |     70.474752 |    430.221310 | Zimices                                                                                                                                                               |
| 345 |    711.917037 |     20.205224 | Ignacio Contreras                                                                                                                                                     |
| 346 |    918.994781 |     11.817788 | Tasman Dixon                                                                                                                                                          |
| 347 |    925.790207 |    296.693379 | Carlos Cano-Barbacil                                                                                                                                                  |
| 348 |    612.550707 |    132.420230 | Tony Ayling                                                                                                                                                           |
| 349 |    513.554707 |    131.041379 | Scott Hartman                                                                                                                                                         |
| 350 |    848.407302 |    388.859407 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 351 |     10.511817 |    719.250807 | Mathieu Pélissié                                                                                                                                                      |
| 352 |    782.143879 |    177.268953 | Beth Reinke                                                                                                                                                           |
| 353 |     15.558424 |     12.291317 | Maxime Dahirel                                                                                                                                                        |
| 354 |     21.820343 |    132.178014 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 355 |   1002.900149 |    136.513763 | Jaime Headden                                                                                                                                                         |
| 356 |    239.717259 |    746.952348 | Anthony Caravaggi                                                                                                                                                     |
| 357 |    593.546845 |    249.385802 | Michele M Tobias                                                                                                                                                      |
| 358 |    738.445219 |     10.790544 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 359 |    851.152306 |    588.661987 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 360 |    442.384400 |    201.094273 | Shyamal                                                                                                                                                               |
| 361 |    382.025682 |     95.584405 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 362 |    486.862984 |    595.661004 | FunkMonk                                                                                                                                                              |
| 363 |    613.898755 |    454.338818 | Scott Hartman                                                                                                                                                         |
| 364 |    940.247536 |    387.875371 | NA                                                                                                                                                                    |
| 365 |    291.056767 |     42.601305 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 366 |    815.337951 |    329.429072 | Lukasiniho                                                                                                                                                            |
| 367 |    629.566525 |    639.567822 | Beth Reinke                                                                                                                                                           |
| 368 |    282.878976 |     75.021991 | Ferran Sayol                                                                                                                                                          |
| 369 |    673.199595 |    384.575276 | Roberto Díaz Sibaja                                                                                                                                                   |
| 370 |    534.705193 |    245.358774 | Chloé Schmidt                                                                                                                                                         |
| 371 |    723.859223 |    341.156073 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 372 |    519.254366 |    213.932350 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 373 |    184.909257 |    780.723264 | NA                                                                                                                                                                    |
| 374 |    416.724012 |     55.685857 | Terpsichores                                                                                                                                                          |
| 375 |     11.798317 |     34.645600 | Matt Crook                                                                                                                                                            |
| 376 |     67.963296 |    474.538295 | FunkMonk                                                                                                                                                              |
| 377 |    622.940438 |     31.725321 | Matt Crook                                                                                                                                                            |
| 378 |    274.369557 |    753.730614 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                          |
| 379 |    408.822139 |      8.606933 | Sean McCann                                                                                                                                                           |
| 380 |    750.612472 |    303.658056 | Tony Ayling                                                                                                                                                           |
| 381 |    420.791336 |    543.060753 | Scott Hartman                                                                                                                                                         |
| 382 |     80.531383 |    555.900865 | Matt Crook                                                                                                                                                            |
| 383 |   1015.205694 |    507.526293 | Zimices                                                                                                                                                               |
| 384 |    846.225374 |    691.701698 | Dean Schnabel                                                                                                                                                         |
| 385 |    776.383679 |    155.963836 | Ferran Sayol                                                                                                                                                          |
| 386 |    372.995957 |    322.223681 | Matt Crook                                                                                                                                                            |
| 387 |    362.496464 |    104.044918 | Zimices                                                                                                                                                               |
| 388 |    374.805502 |    651.529246 | Gopal Murali                                                                                                                                                          |
| 389 |    746.348310 |     45.382118 | Steven Traver                                                                                                                                                         |
| 390 |    313.866956 |    256.343896 | Andrew A. Farke                                                                                                                                                       |
| 391 |    911.415175 |     71.355631 | Margot Michaud                                                                                                                                                        |
| 392 |    545.791890 |    227.496689 | NA                                                                                                                                                                    |
| 393 |    323.751839 |    374.161843 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 394 |    262.295011 |     26.997134 | Steven Traver                                                                                                                                                         |
| 395 |    369.114574 |    455.235605 | Lani Mohan                                                                                                                                                            |
| 396 |    494.490912 |    291.364868 | Peileppe                                                                                                                                                              |
| 397 |    822.998287 |     72.870367 | Christine Axon                                                                                                                                                        |
| 398 |    712.784700 |    210.461800 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 399 |    322.406364 |    619.485792 | Scott Hartman                                                                                                                                                         |
| 400 |    187.589730 |    670.803519 | T. Michael Keesey                                                                                                                                                     |
| 401 |    910.480397 |    668.854449 | Birgit Lang                                                                                                                                                           |
| 402 |    338.401951 |    450.230417 | NA                                                                                                                                                                    |
| 403 |     80.988310 |     22.652131 | Birgit Lang                                                                                                                                                           |
| 404 |     55.880715 |    351.975141 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
| 405 |    712.260719 |    714.068932 | NA                                                                                                                                                                    |
| 406 |    511.706577 |    314.163520 | T. Michael Keesey                                                                                                                                                     |
| 407 |    131.831857 |    404.168507 | C. Camilo Julián-Caballero                                                                                                                                            |
| 408 |    819.890105 |    710.515463 | Tracy A. Heath                                                                                                                                                        |
| 409 |    160.811403 |     42.992465 | Jagged Fang Designs                                                                                                                                                   |
| 410 |     96.195066 |    351.467228 | Matt Hayes                                                                                                                                                            |
| 411 |    154.911405 |     94.483775 | Matt Crook                                                                                                                                                            |
| 412 |    341.203545 |    243.482941 | Baheerathan Murugavel                                                                                                                                                 |
| 413 |    684.271107 |      5.877641 | Gareth Monger                                                                                                                                                         |
| 414 |    369.454075 |    346.385462 | Katie S. Collins                                                                                                                                                      |
| 415 |    474.775416 |    711.128692 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 416 |    541.903303 |     83.155365 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 417 |    975.920183 |    500.978252 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 418 |    284.364036 |    283.530573 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 419 |    757.796537 |    607.907705 | Matt Crook                                                                                                                                                            |
| 420 |    104.595904 |    430.578008 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                        |
| 421 |    398.220826 |    216.505126 | Scott Hartman                                                                                                                                                         |
| 422 |    374.365348 |    492.153186 | NA                                                                                                                                                                    |
| 423 |    417.676509 |    298.688494 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
| 424 |    746.850985 |    136.948772 | Andy Wilson                                                                                                                                                           |
| 425 |     54.633597 |    485.030234 | Chris huh                                                                                                                                                             |
| 426 |    644.789777 |    307.379587 | Zimices                                                                                                                                                               |
| 427 |    896.680098 |    788.929358 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 428 |    474.178027 |    281.256029 | Zimices                                                                                                                                                               |
| 429 |    453.858353 |    363.918649 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 430 |    608.203030 |     87.215141 | Birgit Lang                                                                                                                                                           |
| 431 |    999.258995 |     38.276723 | Emily Jane McTavish                                                                                                                                                   |
| 432 |     10.052363 |    442.015275 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 433 |    450.599259 |    609.036590 | Jagged Fang Designs                                                                                                                                                   |
| 434 |    985.135566 |    136.979868 | Caleb M. Brown                                                                                                                                                        |
| 435 |    465.653887 |    291.559653 | Ingo Braasch                                                                                                                                                          |
| 436 |    509.764239 |    231.523687 | Andy Wilson                                                                                                                                                           |
| 437 |    146.726388 |    568.188312 | Matt Crook                                                                                                                                                            |
| 438 |    326.450125 |    642.697219 | L. Shyamal                                                                                                                                                            |
| 439 |     92.481066 |    616.449270 | Zimices                                                                                                                                                               |
| 440 |    511.558865 |    561.935458 | Markus A. Grohme                                                                                                                                                      |
| 441 |   1015.526933 |    575.070119 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 442 |    585.327849 |    678.509512 | Jagged Fang Designs                                                                                                                                                   |
| 443 |    789.897190 |    776.769999 | Andy Wilson                                                                                                                                                           |
| 444 |    875.038628 |    626.580181 | Roberto Díaz Sibaja                                                                                                                                                   |
| 445 |    722.209148 |    793.722890 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 446 |    586.922800 |    369.703638 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 447 |    922.820310 |    592.603864 | Carlos Cano-Barbacil                                                                                                                                                  |
| 448 |    845.820259 |    672.160706 | Margot Michaud                                                                                                                                                        |
| 449 |    325.699767 |    689.223404 | ArtFavor & annaleeblysse                                                                                                                                              |
| 450 |    194.906902 |    455.063389 | T. Michael Keesey                                                                                                                                                     |
| 451 |    922.610874 |    464.576406 | Maxime Dahirel                                                                                                                                                        |
| 452 |    559.570450 |    364.227208 | Steven Coombs                                                                                                                                                         |
| 453 |    656.920401 |    598.026447 | Matt Martyniuk                                                                                                                                                        |
| 454 |   1004.216631 |    403.233289 | Tauana J. Cunha                                                                                                                                                       |
| 455 |    257.759129 |    337.345966 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 456 |    205.344029 |    639.164291 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                   |
| 457 |     47.361316 |    313.385773 | Geoff Shaw                                                                                                                                                            |
| 458 |    872.995261 |    326.509206 | Andy Wilson                                                                                                                                                           |
| 459 |    767.409134 |    687.783262 | Melissa Broussard                                                                                                                                                     |
| 460 |    413.663588 |    197.855735 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 461 |    443.580106 |    176.460103 | Matt Crook                                                                                                                                                            |
| 462 |    201.894670 |    438.905469 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 463 |    946.005667 |    301.154601 | Chris Hay                                                                                                                                                             |
| 464 |    702.938995 |    293.355619 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 465 |    190.364328 |    531.754423 | Zimices                                                                                                                                                               |
| 466 |    623.834119 |    544.855989 | Chris huh                                                                                                                                                             |
| 467 |    843.908598 |     13.466061 | Jagged Fang Designs                                                                                                                                                   |
| 468 |    756.830595 |    490.082565 | Markus A. Grohme                                                                                                                                                      |
| 469 |    268.212873 |    185.753830 | Steven Traver                                                                                                                                                         |
| 470 |    198.394489 |    524.519323 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 471 |    771.861652 |    284.907837 | Tasman Dixon                                                                                                                                                          |
| 472 |     59.505666 |    574.579190 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 473 |    618.683687 |    618.950741 | Terpsichores                                                                                                                                                          |
| 474 |    153.686128 |    671.476023 | Gareth Monger                                                                                                                                                         |
| 475 |    810.010719 |     57.684819 | Steven Traver                                                                                                                                                         |
| 476 |    279.103783 |    532.574641 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 477 |    174.172029 |    797.637549 | Jaime Headden                                                                                                                                                         |
| 478 |    285.922213 |    219.896237 | Kanchi Nanjo                                                                                                                                                          |
| 479 |    829.516429 |    167.879796 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 480 |    232.946539 |    275.276897 | Erika Schumacher                                                                                                                                                      |
| 481 |   1004.520219 |    238.694087 | xgirouxb                                                                                                                                                              |
| 482 |    364.650622 |    441.182920 | Scott Hartman                                                                                                                                                         |
| 483 |    173.592117 |    289.685482 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 484 |     96.002516 |    665.133090 | Matt Crook                                                                                                                                                            |
| 485 |    785.309132 |    169.756568 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 486 |    842.600426 |    766.222819 | Ieuan Jones                                                                                                                                                           |
| 487 |    226.278510 |    669.492562 | Steven Traver                                                                                                                                                         |
| 488 |    300.767315 |    676.309484 | Alex Slavenko                                                                                                                                                         |
| 489 |    614.182441 |    117.102718 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 490 |     25.252081 |    159.547157 | Joanna Wolfe                                                                                                                                                          |
| 491 |    472.667172 |    724.550382 | Margot Michaud                                                                                                                                                        |
| 492 |    897.768571 |     90.605056 | Andy Wilson                                                                                                                                                           |
| 493 |     22.628230 |    424.915361 | Scott Hartman                                                                                                                                                         |
| 494 |    246.238252 |    795.971402 | T. Michael Keesey                                                                                                                                                     |
| 495 |     91.813904 |    304.879248 | Emily Willoughby                                                                                                                                                      |
| 496 |    539.990613 |     49.725611 | Mathieu Pélissié                                                                                                                                                      |
| 497 |    394.541036 |    586.330133 | Harold N Eyster                                                                                                                                                       |
| 498 |     27.175977 |    294.885728 | Margot Michaud                                                                                                                                                        |
| 499 |    721.258102 |    322.702435 | Chris huh                                                                                                                                                             |
| 500 |    607.541390 |    236.968384 | Zimices                                                                                                                                                               |
| 501 |    339.949299 |    640.986339 | Riccardo Percudani                                                                                                                                                    |
| 502 |    701.291466 |     54.320396 | NA                                                                                                                                                                    |
| 503 |    813.459109 |    120.767516 | Tracy A. Heath                                                                                                                                                        |
| 504 |    735.822809 |    199.249406 | Andy Wilson                                                                                                                                                           |
| 505 |    317.638582 |     86.253131 | Ferran Sayol                                                                                                                                                          |
| 506 |    632.566823 |    767.675408 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 507 |    430.068763 |     18.544742 | Zimices                                                                                                                                                               |
| 508 |     96.455302 |    576.166240 | G. M. Woodward                                                                                                                                                        |
| 509 |    176.078093 |    103.453481 | Matt Crook                                                                                                                                                            |
| 510 |    949.627002 |    358.972951 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 511 |    972.425638 |    373.060881 | Matt Crook                                                                                                                                                            |
| 512 |    696.798048 |    415.349777 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 513 |    879.849388 |    240.631111 | Markus A. Grohme                                                                                                                                                      |
| 514 |    748.070390 |    453.040487 | Matt Crook                                                                                                                                                            |
| 515 |   1008.348716 |    473.705608 | Smokeybjb                                                                                                                                                             |
| 516 |      3.674446 |    220.406863 | Michelle Site                                                                                                                                                         |
| 517 |    510.252563 |    731.026383 | Nina Skinner                                                                                                                                                          |
| 518 |    109.922037 |    682.707303 | Gareth Monger                                                                                                                                                         |
| 519 |    829.925746 |    192.625653 | Sarah Werning                                                                                                                                                         |
| 520 |    376.356920 |    337.298761 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 521 |    347.972443 |    684.950125 | Diana Pomeroy                                                                                                                                                         |
| 522 |    678.475539 |    120.458654 | Jonathan Lawley                                                                                                                                                       |
| 523 |    147.185479 |    391.054757 | Zimices                                                                                                                                                               |
| 524 |    763.208055 |    747.741092 | Gareth Monger                                                                                                                                                         |
| 525 |     67.551514 |    313.720072 | Harold N Eyster                                                                                                                                                       |
| 526 |    160.923004 |    197.645260 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 527 |    496.281558 |    393.649560 | T. Michael Keesey                                                                                                                                                     |
| 528 |    884.487356 |    784.194098 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 529 |    413.832328 |    790.648927 | Steven Traver                                                                                                                                                         |
| 530 |    749.141914 |    254.780853 | Matt Crook                                                                                                                                                            |
| 531 |    733.791188 |    184.923416 | Maija Karala                                                                                                                                                          |
| 532 |     67.947608 |    282.857923 | Iain Reid                                                                                                                                                             |
| 533 |    264.688780 |    381.881491 | NA                                                                                                                                                                    |
| 534 |     23.586726 |    474.719362 | Lukasiniho                                                                                                                                                            |
| 535 |    381.046869 |    676.487871 | Ignacio Contreras                                                                                                                                                     |
| 536 |    773.185401 |    118.553023 | Jaime Headden                                                                                                                                                         |
| 537 |    766.519393 |    129.501213 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 538 |    771.007454 |    366.665977 | Harold N Eyster                                                                                                                                                       |
| 539 |    511.614905 |    399.643035 | Renata F. Martins                                                                                                                                                     |
| 540 |    240.932162 |     29.797184 | T. Michael Keesey                                                                                                                                                     |
| 541 |    434.678718 |    560.314376 | Conty                                                                                                                                                                 |
| 542 |    220.197521 |    216.540762 | Taro Maeda                                                                                                                                                            |
| 543 |    781.421586 |    732.257523 | Jagged Fang Designs                                                                                                                                                   |
| 544 |     83.448204 |    782.535641 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 545 |    902.397078 |      3.667417 | Steven Coombs                                                                                                                                                         |
| 546 |    545.316174 |    316.164100 | Dmitry Bogdanov                                                                                                                                                       |
| 547 |    462.217374 |    619.803727 | T. Tischler                                                                                                                                                           |
| 548 |    168.448821 |    275.748416 | NA                                                                                                                                                                    |
| 549 |    224.577948 |    409.700062 | Jagged Fang Designs                                                                                                                                                   |
| 550 |    769.772291 |    739.595481 | Campbell Fleming                                                                                                                                                      |
| 551 |    231.192477 |    269.379922 | Zimices                                                                                                                                                               |
| 552 |    209.238918 |     29.674794 | Chris huh                                                                                                                                                             |
| 553 |    894.037353 |    334.140954 | C. Camilo Julián-Caballero                                                                                                                                            |
| 554 |    345.124438 |    345.605436 | Karina Garcia                                                                                                                                                         |
| 555 |    381.761763 |    762.275555 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 556 |    368.405167 |    731.279361 | Margot Michaud                                                                                                                                                        |
| 557 |    105.032442 |    595.847387 | Matt Crook                                                                                                                                                            |
| 558 |    862.441044 |    719.877150 | Javiera Constanzo                                                                                                                                                     |
| 559 |    443.676832 |    131.168146 | kreidefossilien.de                                                                                                                                                    |
| 560 |    393.541407 |    567.880222 | Michelle Site                                                                                                                                                         |
| 561 |    783.456748 |    403.478016 | Steven Traver                                                                                                                                                         |
| 562 |    744.861453 |    163.995039 | Tracy A. Heath                                                                                                                                                        |
| 563 |    800.041414 |    387.546243 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 564 |   1015.125987 |    318.980766 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 565 |    887.213189 |    609.813522 | Steven Traver                                                                                                                                                         |
| 566 |    411.534675 |    592.113293 | Steven Traver                                                                                                                                                         |
| 567 |    584.838504 |    784.938750 | Renato de Carvalho Ferreira                                                                                                                                           |
| 568 |    866.860555 |    616.120150 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 569 |    118.982543 |    596.437169 | Kamil S. Jaron                                                                                                                                                        |
| 570 |    205.897402 |     84.260162 | Emily Willoughby                                                                                                                                                      |
| 571 |    727.110025 |    555.997067 | Ingo Braasch                                                                                                                                                          |
| 572 |    169.155266 |     68.362458 | NA                                                                                                                                                                    |
| 573 |     79.738355 |    267.412558 | Andy Wilson                                                                                                                                                           |
| 574 |    702.026084 |    349.155067 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 575 |    636.522478 |    732.032096 | Matt Crook                                                                                                                                                            |
| 576 |    535.441886 |    160.898874 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 577 |    961.630677 |    737.679531 | Chloé Schmidt                                                                                                                                                         |
| 578 |     29.237665 |    125.789170 | Zimices                                                                                                                                                               |
| 579 |    313.425371 |    789.769242 | L. Shyamal                                                                                                                                                            |
| 580 |     37.467519 |    626.483846 | Gareth Monger                                                                                                                                                         |
| 581 |    790.897699 |    145.119697 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 582 |     53.503422 |    730.879555 | Margot Michaud                                                                                                                                                        |
| 583 |     53.387703 |    455.392875 | Steven Traver                                                                                                                                                         |
| 584 |    990.212523 |    745.861408 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 585 |    474.673578 |    788.569820 | Gareth Monger                                                                                                                                                         |
| 586 |    820.979269 |    209.288356 | Matt Crook                                                                                                                                                            |
| 587 |    224.519999 |     48.439900 | Margot Michaud                                                                                                                                                        |
| 588 |    643.635339 |    638.706119 | Matt Crook                                                                                                                                                            |
| 589 |    182.922085 |     87.786320 | NA                                                                                                                                                                    |
| 590 |     92.450492 |    279.724915 | Maija Karala                                                                                                                                                          |
| 591 |    927.534702 |    417.445801 | Ferran Sayol                                                                                                                                                          |
| 592 |    274.824732 |    547.434593 | Chris huh                                                                                                                                                             |
| 593 |    966.405367 |    760.310230 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 594 |    871.035905 |    589.395216 | NA                                                                                                                                                                    |
| 595 |    851.744447 |    731.320693 | Steven Traver                                                                                                                                                         |
| 596 |    886.354331 |    643.361464 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 597 |    437.677802 |    775.228592 | Chris huh                                                                                                                                                             |
| 598 |    781.111312 |    678.295085 | Xavier Giroux-Bougard                                                                                                                                                 |
| 599 |     64.001506 |     16.040324 | Gareth Monger                                                                                                                                                         |
| 600 |    246.659159 |    755.094229 | Steven Traver                                                                                                                                                         |
| 601 |    622.618729 |    271.759677 | Maija Karala                                                                                                                                                          |
| 602 |    846.397767 |    480.132523 | Gareth Monger                                                                                                                                                         |
| 603 |    867.877678 |    761.365083 | Oliver Voigt                                                                                                                                                          |
| 604 |    745.538990 |    591.549361 | Katie S. Collins                                                                                                                                                      |
| 605 |    571.650368 |     40.319278 | Scott Hartman                                                                                                                                                         |
| 606 |    953.130955 |    108.011112 | Steven Traver                                                                                                                                                         |
| 607 |    635.210882 |    759.734681 | Birgit Lang                                                                                                                                                           |
| 608 |     47.302973 |    432.655179 | Burton Robert, USFWS                                                                                                                                                  |
| 609 |    159.830921 |    621.104518 | Verisimilus                                                                                                                                                           |
| 610 |    214.303637 |    720.007395 | Jagged Fang Designs                                                                                                                                                   |
| 611 |    516.356445 |    797.937127 | Chris huh                                                                                                                                                             |
| 612 |    668.826614 |    237.701990 | Zimices                                                                                                                                                               |
| 613 |    545.911916 |    554.125000 | Gareth Monger                                                                                                                                                         |
| 614 |    354.820091 |    571.727796 | Gareth Monger                                                                                                                                                         |
| 615 |    396.453228 |    677.059573 | Renata F. Martins                                                                                                                                                     |
| 616 |    280.773198 |    518.790811 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 617 |    249.924745 |    432.176917 | Jagged Fang Designs                                                                                                                                                   |
| 618 |    552.771518 |    408.967257 | Carlos Cano-Barbacil                                                                                                                                                  |
| 619 |    668.440085 |    652.191207 | T. Michael Keesey                                                                                                                                                     |
| 620 |    384.823168 |    773.339180 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 621 |    364.449836 |    673.241604 | Harold N Eyster                                                                                                                                                       |
| 622 |    653.846648 |     63.165534 | Scott Hartman                                                                                                                                                         |
| 623 |    559.613627 |    145.317396 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                        |
| 624 |     16.738455 |    361.875604 | Collin Gross                                                                                                                                                          |
| 625 |    913.425499 |    381.164570 | Margot Michaud                                                                                                                                                        |
| 626 |    192.497454 |    792.227464 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 627 |     39.060259 |    178.691158 | David Orr                                                                                                                                                             |
| 628 |    343.544787 |     92.281551 | Andy Wilson                                                                                                                                                           |
| 629 |    122.550341 |    707.377175 | L. Shyamal                                                                                                                                                            |
| 630 |    470.074552 |    599.275957 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 631 |    994.054498 |    110.750035 | Henry Lydecker                                                                                                                                                        |
| 632 |    312.142108 |    762.076872 | Crystal Maier                                                                                                                                                         |
| 633 |    554.828491 |    371.307896 | Tracy A. Heath                                                                                                                                                        |
| 634 |     50.478966 |     93.429263 | Matt Crook                                                                                                                                                            |
| 635 |     74.575770 |    463.191311 | Michelle Site                                                                                                                                                         |
| 636 |    528.242775 |    361.123564 | Andy Wilson                                                                                                                                                           |
| 637 |    639.798935 |    227.305194 | Collin Gross                                                                                                                                                          |
| 638 |     13.972404 |    774.494102 | Erika Schumacher                                                                                                                                                      |
| 639 |    502.829792 |     41.461369 | Steven Traver                                                                                                                                                         |
| 640 |      6.267936 |    527.668683 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 641 |    927.139306 |    305.098008 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 642 |    121.881546 |    389.958992 | Felix Vaux                                                                                                                                                            |
| 643 |    285.057433 |    742.682220 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 644 |    714.169586 |    765.846812 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 645 |    661.438923 |    348.729394 | Margot Michaud                                                                                                                                                        |
| 646 |    406.292221 |    430.973253 | Steven Traver                                                                                                                                                         |
| 647 |    973.927692 |    470.124081 | NA                                                                                                                                                                    |
| 648 |    525.829456 |    557.116144 | Gareth Monger                                                                                                                                                         |
| 649 |    163.923823 |    176.155963 | Michelle Site                                                                                                                                                         |
| 650 |   1003.863674 |    358.684504 | Scott Hartman                                                                                                                                                         |
| 651 |    958.519129 |    652.656561 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 652 |    452.568809 |    783.960892 | Ferran Sayol                                                                                                                                                          |
| 653 |    695.253299 |    151.365255 | Chloé Schmidt                                                                                                                                                         |
| 654 |    148.179435 |    212.535471 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 655 |    354.456697 |    607.034699 | Markus A. Grohme                                                                                                                                                      |
| 656 |    955.310592 |    638.314113 | NA                                                                                                                                                                    |
| 657 |    381.151536 |    566.009808 | Matt Crook                                                                                                                                                            |
| 658 |   1005.720151 |    587.321685 | Margot Michaud                                                                                                                                                        |
| 659 |    612.209721 |    443.281670 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 660 |    793.431633 |    390.396605 | Margot Michaud                                                                                                                                                        |
| 661 |    151.141348 |    727.540211 | Maija Karala                                                                                                                                                          |
| 662 |    773.712955 |     99.887189 | Markus A. Grohme                                                                                                                                                      |
| 663 |     17.410090 |    675.292678 | Markus A. Grohme                                                                                                                                                      |
| 664 |    996.913558 |    307.506871 | Matt Crook                                                                                                                                                            |
| 665 |    769.392634 |    656.604772 | T. Michael Keesey                                                                                                                                                     |
| 666 |    836.918492 |    782.495336 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 667 |    395.065877 |    476.504949 | Chris huh                                                                                                                                                             |
| 668 |    799.412140 |    195.049823 | Jagged Fang Designs                                                                                                                                                   |
| 669 |    395.389888 |    319.772640 | Gareth Monger                                                                                                                                                         |
| 670 |    912.044861 |    783.090156 | Tasman Dixon                                                                                                                                                          |
| 671 |    408.915853 |    296.101950 | NA                                                                                                                                                                    |
| 672 |    269.784568 |    492.257811 | Gareth Monger                                                                                                                                                         |
| 673 |    647.535693 |     28.941135 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 674 |    348.290524 |    586.279081 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 675 |    245.041819 |    474.739473 | Birgit Lang                                                                                                                                                           |
| 676 |     17.384509 |    244.000793 | Chris huh                                                                                                                                                             |
| 677 |    622.290614 |    695.013011 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                        |
| 678 |    735.619205 |    399.742076 | Michelle Site                                                                                                                                                         |
| 679 |    767.227426 |    247.207135 | Julio Garza                                                                                                                                                           |
| 680 |    732.928146 |    534.643756 | Sarah Werning                                                                                                                                                         |
| 681 |    502.170803 |    781.517689 | Matt Crook                                                                                                                                                            |
| 682 |    847.928310 |    347.596575 | Gareth Monger                                                                                                                                                         |
| 683 |    780.261552 |    536.659174 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 684 |    839.407627 |    611.715447 | Andy Wilson                                                                                                                                                           |
| 685 |    618.502375 |     78.799978 | Matt Crook                                                                                                                                                            |
| 686 |    832.457937 |    635.193675 | Beth Reinke                                                                                                                                                           |
| 687 |    249.475579 |    422.483105 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 688 |     65.789439 |    786.734102 | Andrew A. Farke                                                                                                                                                       |
| 689 |    943.876307 |    212.480771 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 690 |     74.697781 |    773.245840 | Matt Crook                                                                                                                                                            |
| 691 |    480.625462 |    554.766716 | Zimices                                                                                                                                                               |
| 692 |    803.455625 |    155.787247 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 693 |    878.983755 |    492.760087 | Steven Traver                                                                                                                                                         |
| 694 |    110.574863 |    158.085003 | Jagged Fang Designs                                                                                                                                                   |
| 695 |    402.235161 |     22.978041 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 696 |    654.909761 |    614.554647 | Rebecca Groom                                                                                                                                                         |
| 697 |    346.354030 |    391.424409 | Harold N Eyster                                                                                                                                                       |
| 698 |     64.610882 |     90.029801 | Margot Michaud                                                                                                                                                        |
| 699 |    166.867891 |     36.292184 | Steven Traver                                                                                                                                                         |
| 700 |    927.700317 |    660.080049 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                     |
| 701 |   1005.662518 |     21.256008 | Zimices / Julián Bayona                                                                                                                                               |
| 702 |    820.764486 |    254.606840 | T. Michael Keesey                                                                                                                                                     |
| 703 |    486.170528 |    683.648903 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 704 |     19.594074 |    178.556951 | B. Duygu Özpolat                                                                                                                                                      |
| 705 |     32.265633 |    755.863371 | Margot Michaud                                                                                                                                                        |
| 706 |   1013.957714 |    712.750254 | Yan Wong                                                                                                                                                              |
| 707 |    554.969604 |    556.195304 | Margot Michaud                                                                                                                                                        |
| 708 |    827.563755 |    527.131381 | Matt Crook                                                                                                                                                            |
| 709 |    921.159867 |     56.273702 | Steven Traver                                                                                                                                                         |
| 710 |    338.386036 |    253.121700 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 711 |    938.464179 |      9.297517 | T. Michael Keesey                                                                                                                                                     |
| 712 |   1014.039683 |    519.177468 | Melissa Broussard                                                                                                                                                     |
| 713 |   1013.376378 |    422.530754 | Armin Reindl                                                                                                                                                          |
| 714 |    972.252084 |    678.250826 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 715 |    999.436101 |    731.133235 | Margot Michaud                                                                                                                                                        |
| 716 |    999.343615 |    477.536334 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 717 |    888.488960 |    519.952106 | Birgit Lang                                                                                                                                                           |
| 718 |    355.286459 |    362.628511 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 719 |    824.291105 |    368.414075 | M Kolmann                                                                                                                                                             |
| 720 |    942.803539 |    630.590517 | Zimices                                                                                                                                                               |
| 721 |    296.215009 |      4.613930 | Alex Slavenko                                                                                                                                                         |
| 722 |    666.535784 |    704.869062 | Matt Crook                                                                                                                                                            |
| 723 |    229.783107 |     29.306099 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 724 |    804.315650 |    743.109045 | Harold N Eyster                                                                                                                                                       |
| 725 |    819.293215 |    351.475337 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 726 |    451.659924 |      7.491566 | Margot Michaud                                                                                                                                                        |
| 727 |    998.553712 |    265.778947 | Tracy A. Heath                                                                                                                                                        |
| 728 |    573.790333 |    146.369859 | Gareth Monger                                                                                                                                                         |
| 729 |    931.026660 |    373.356494 | Kanako Bessho-Uehara                                                                                                                                                  |
| 730 |    524.590880 |    119.392127 | Zimices                                                                                                                                                               |
| 731 |    602.599000 |     62.077669 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 732 |     84.801230 |    755.162640 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 733 |    629.461811 |    742.440912 | Ferran Sayol                                                                                                                                                          |
| 734 |    564.240628 |    375.896995 | Ferran Sayol                                                                                                                                                          |
| 735 |    762.310093 |    505.984045 | Gareth Monger                                                                                                                                                         |
| 736 |     60.846506 |    695.448120 | Matthew E. Clapham                                                                                                                                                    |
| 737 |   1007.830252 |    563.921014 | Collin Gross                                                                                                                                                          |
| 738 |    887.711508 |    229.949995 | Oscar Sanisidro                                                                                                                                                       |
| 739 |    198.405775 |    537.439771 | Anna Willoughby                                                                                                                                                       |
| 740 |    799.598477 |    201.445164 | Birgit Lang                                                                                                                                                           |
| 741 |    196.734498 |    316.271384 | Steven Traver                                                                                                                                                         |
| 742 |    197.802081 |    411.702342 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 743 |    267.374419 |    533.037496 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 744 |    322.093165 |    247.803690 | Andrew A. Farke                                                                                                                                                       |
| 745 |    260.227615 |    748.563811 | Andy Wilson                                                                                                                                                           |
| 746 |    581.695416 |     66.259822 | Scott Hartman                                                                                                                                                         |
| 747 |    378.113636 |    587.773923 | Matt Crook                                                                                                                                                            |
| 748 |    100.099841 |     93.311816 | Zimices                                                                                                                                                               |
| 749 |     27.859788 |    580.419173 | Steven Coombs                                                                                                                                                         |
| 750 |    219.148763 |     41.683111 | Margot Michaud                                                                                                                                                        |
| 751 |    864.044272 |    416.092543 | Michelle Site                                                                                                                                                         |
| 752 |    114.647234 |    786.063198 | Jack Mayer Wood                                                                                                                                                       |
| 753 |     21.402975 |    602.174814 | Scott Hartman                                                                                                                                                         |
| 754 |    971.298676 |    606.673318 | Sean McCann                                                                                                                                                           |
| 755 |    702.199491 |    785.501698 | Cesar Julian                                                                                                                                                          |
| 756 |    619.234556 |    773.213986 | Kamil S. Jaron                                                                                                                                                        |
| 757 |    113.095773 |    667.968221 | NA                                                                                                                                                                    |
| 758 |    982.715582 |    736.392822 | Chris huh                                                                                                                                                             |
| 759 |    585.887547 |    380.116433 | Matt Crook                                                                                                                                                            |
| 760 |    262.356207 |    234.974669 | Zimices                                                                                                                                                               |
| 761 |    329.609570 |    509.406541 | Margot Michaud                                                                                                                                                        |
| 762 |    490.350631 |    365.430735 | Matt Crook                                                                                                                                                            |
| 763 |    220.750802 |    447.541628 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 764 |    704.826226 |    656.901578 | M Kolmann                                                                                                                                                             |
| 765 |    542.177908 |    219.297526 | Pete Buchholz                                                                                                                                                         |
| 766 |    114.279002 |    490.665440 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 767 |   1013.996446 |    665.198846 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 768 |    826.532778 |    341.511370 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 769 |    700.205062 |    331.952471 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 770 |     33.063553 |    501.908561 | Margot Michaud                                                                                                                                                        |
| 771 |    143.805320 |    620.780592 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 772 |    298.912336 |    543.178905 | NA                                                                                                                                                                    |
| 773 |    851.576523 |    784.267476 | Matus Valach                                                                                                                                                          |
| 774 |    897.452133 |    382.960408 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 775 |    870.115238 |    796.412070 | CNZdenek                                                                                                                                                              |
| 776 |    412.968483 |    215.665142 | Rainer Schoch                                                                                                                                                         |
| 777 |    804.697753 |    710.010330 | Matt Crook                                                                                                                                                            |
| 778 |    764.757081 |    168.680492 | Gopal Murali                                                                                                                                                          |
| 779 |   1014.419960 |    254.679458 | Scott Hartman                                                                                                                                                         |
| 780 |   1011.153426 |    379.294524 | Gareth Monger                                                                                                                                                         |
| 781 |     38.041986 |    450.191147 | Margot Michaud                                                                                                                                                        |
| 782 |    553.311997 |    119.059821 | NA                                                                                                                                                                    |
| 783 |    538.001428 |    792.228825 | Kent Elson Sorgon                                                                                                                                                     |
| 784 |    162.824589 |    495.606730 | Jaime Headden                                                                                                                                                         |
| 785 |    558.105052 |    239.300574 | Zimices                                                                                                                                                               |
| 786 |    300.596252 |    764.485679 | Caleb M. Brown                                                                                                                                                        |
| 787 |    252.618872 |    638.118772 | Margot Michaud                                                                                                                                                        |
| 788 |    695.697540 |    216.604792 | Jaime Headden                                                                                                                                                         |
| 789 |    162.383733 |     82.717647 | Gareth Monger                                                                                                                                                         |
| 790 |    621.716795 |    724.088041 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 791 |    695.132001 |    405.487264 | Ferran Sayol                                                                                                                                                          |
| 792 |    975.264250 |    481.947685 | B. Duygu Özpolat                                                                                                                                                      |
| 793 |    791.878767 |    264.917575 | T. Michael Keesey                                                                                                                                                     |
| 794 |    805.012257 |    256.613267 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 795 |    814.466050 |    134.172263 | Myriam\_Ramirez                                                                                                                                                       |
| 796 |    843.461629 |      6.939286 | Zimices                                                                                                                                                               |
| 797 |    758.461488 |    698.904007 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 798 |    419.319839 |    705.681154 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 799 |    923.182926 |    352.826854 | Gareth Monger                                                                                                                                                         |
| 800 |    419.968666 |     98.189919 | nicubunu                                                                                                                                                              |
| 801 |    447.850170 |    301.718447 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 802 |    696.536148 |     13.358207 | Steven Traver                                                                                                                                                         |
| 803 |    898.899908 |    796.522901 | CNZdenek                                                                                                                                                              |
| 804 |    692.123259 |    424.635136 | Zimices                                                                                                                                                               |
| 805 |    228.582685 |    755.006366 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 806 |    153.159792 |    247.641776 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 807 |    935.966811 |     93.011324 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 808 |    637.114632 |    200.594975 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 809 |    523.816288 |    328.807578 | Zimices                                                                                                                                                               |
| 810 |    417.465437 |    109.693419 | Alex Slavenko                                                                                                                                                         |
| 811 |    411.300701 |    359.025346 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 812 |    173.175321 |    752.745498 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 813 |    687.147409 |    110.560130 | Jagged Fang Designs                                                                                                                                                   |
| 814 |    468.637299 |     45.753145 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 815 |    853.221665 |    754.442147 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 816 |    458.253621 |     14.187816 | Joanna Wolfe                                                                                                                                                          |
| 817 |     22.652901 |    286.016098 | Kamil S. Jaron                                                                                                                                                        |
| 818 |     71.873526 |    105.521150 | Tony Ayling                                                                                                                                                           |
| 819 |    818.679235 |    515.562566 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 820 |     40.669066 |    521.808651 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 821 |     14.747601 |    787.487205 | Margot Michaud                                                                                                                                                        |
| 822 |    750.184749 |    707.051371 | Erika Schumacher                                                                                                                                                      |
| 823 |    454.161488 |    559.403141 | Margot Michaud                                                                                                                                                        |
| 824 |    416.891338 |    397.334143 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 825 |   1012.019999 |    496.269679 | Iain Reid                                                                                                                                                             |
| 826 |    551.440568 |    303.791494 | Michelle Site                                                                                                                                                         |
| 827 |    243.054280 |      9.927386 | Karla Martinez                                                                                                                                                        |
| 828 |    672.506574 |     90.474958 | Steven Traver                                                                                                                                                         |
| 829 |    210.083658 |    407.829116 | George Edward Lodge                                                                                                                                                   |
| 830 |    945.198815 |    408.155710 | Felix Vaux                                                                                                                                                            |
| 831 |    238.805308 |    384.660735 | Gareth Monger                                                                                                                                                         |
| 832 |    324.947998 |    750.746955 | Chris huh                                                                                                                                                             |
| 833 |    324.376756 |    237.800840 | Sarah Werning                                                                                                                                                         |
| 834 |    133.247009 |    250.802144 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 835 |    587.271294 |    790.487271 | Chris huh                                                                                                                                                             |
| 836 |    310.927909 |    470.797034 | Tasman Dixon                                                                                                                                                          |
| 837 |    670.737865 |     19.320564 | Birgit Lang                                                                                                                                                           |
| 838 |     24.670596 |    794.774653 | NA                                                                                                                                                                    |
| 839 |    435.893312 |    785.433513 | Matt Crook                                                                                                                                                            |
| 840 |    979.202278 |    159.472801 | Ferran Sayol                                                                                                                                                          |
| 841 |    572.843370 |    240.051519 | Carlos Cano-Barbacil                                                                                                                                                  |
| 842 |    960.744101 |    343.079023 | Milton Tan                                                                                                                                                            |
| 843 |    211.394987 |    622.339952 | T. Michael Keesey                                                                                                                                                     |
| 844 |    155.801054 |    411.582540 | Trond R. Oskars                                                                                                                                                       |
| 845 |    166.658181 |    633.618524 | Alex Slavenko                                                                                                                                                         |
| 846 |    454.293806 |    795.395062 | Dean Schnabel                                                                                                                                                         |
| 847 |     32.874774 |    148.628744 | Emily Willoughby                                                                                                                                                      |
| 848 |    272.063510 |     87.372164 | Andy Wilson                                                                                                                                                           |
| 849 |    213.656777 |    287.679578 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 850 |    969.338958 |    210.813284 | Matt Crook                                                                                                                                                            |
| 851 |    760.691131 |    535.384509 | Gareth Monger                                                                                                                                                         |
| 852 |    846.789833 |    555.894173 | Michelle Site                                                                                                                                                         |
| 853 |     27.674185 |    255.604833 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 854 |    770.579254 |    321.175727 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 855 |    367.779801 |    359.990390 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 856 |    265.349527 |      5.243927 | Zimices                                                                                                                                                               |
| 857 |    918.346365 |    404.588909 | Erika Schumacher                                                                                                                                                      |
| 858 |    604.110380 |     32.908378 | Jaime Headden                                                                                                                                                         |
| 859 |    969.813626 |    722.324250 | Matt Martyniuk                                                                                                                                                        |
| 860 |    475.222508 |    346.570387 | Dmitry Bogdanov                                                                                                                                                       |
| 861 |    565.765655 |    176.291781 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 862 |    850.044505 |    231.570515 | Felix Vaux                                                                                                                                                            |
| 863 |    828.380330 |     86.410023 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                  |
| 864 |     28.874542 |    434.930690 | Jack Mayer Wood                                                                                                                                                       |
| 865 |    781.568651 |    722.100553 | Gareth Monger                                                                                                                                                         |
| 866 |    951.118548 |    757.142958 | Gareth Monger                                                                                                                                                         |
| 867 |    279.989311 |    680.528359 | Collin Gross                                                                                                                                                          |
| 868 |    251.064538 |    583.990291 | Matt Crook                                                                                                                                                            |
| 869 |    968.471788 |    358.837410 | Gareth Monger                                                                                                                                                         |
| 870 |    486.091141 |    266.283043 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
| 871 |    738.468387 |    789.274885 | Margot Michaud                                                                                                                                                        |
| 872 |    235.167391 |    554.624404 | Andrew A. Farke                                                                                                                                                       |
| 873 |     67.854567 |    468.061520 | T. Michael Keesey                                                                                                                                                     |
| 874 |    682.779364 |    378.882130 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 875 |    192.804874 |    628.012676 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 876 |    737.567498 |    614.866317 | Rebecca Groom                                                                                                                                                         |
| 877 |   1012.059442 |    404.034148 | Ferran Sayol                                                                                                                                                          |
| 878 |    584.312782 |     11.401836 | Qiang Ou                                                                                                                                                              |
| 879 |    272.008173 |    227.721143 | Felix Vaux                                                                                                                                                            |
| 880 |    635.794382 |    785.512451 | Matt Martyniuk                                                                                                                                                        |
| 881 |     11.695007 |    369.674574 | Margot Michaud                                                                                                                                                        |
| 882 |     40.844096 |     11.908234 | Joanna Wolfe                                                                                                                                                          |
| 883 |    352.094947 |    764.096796 | Dinah Challen                                                                                                                                                         |
| 884 |    146.834785 |     19.317712 | Yan Wong from illustration by Charles Orbigny                                                                                                                         |
| 885 |    732.391799 |    652.425251 | Christoph Schomburg                                                                                                                                                   |
| 886 |    683.467837 |    228.859940 | Mike Hanson                                                                                                                                                           |
| 887 |    463.080575 |    635.442952 | Margot Michaud                                                                                                                                                        |
| 888 |    203.743747 |    267.382530 | Chris huh                                                                                                                                                             |
| 889 |   1012.439324 |     61.613085 | NA                                                                                                                                                                    |
| 890 |    151.454815 |    454.342382 | Oscar Sanisidro                                                                                                                                                       |
| 891 |    370.905275 |     52.567345 | Margot Michaud                                                                                                                                                        |
| 892 |    934.576339 |    585.059840 | Margot Michaud                                                                                                                                                        |
| 893 |    392.227502 |     35.105245 | Tracy A. Heath                                                                                                                                                        |
| 894 |    181.957132 |    643.576117 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
| 895 |    394.504221 |    519.598717 | Zimices                                                                                                                                                               |
| 896 |    478.561426 |    608.167207 | Jimmy Bernot                                                                                                                                                          |
| 897 |    229.409018 |    529.038572 | NA                                                                                                                                                                    |
| 898 |    829.604724 |    578.504339 | Tyler McCraney                                                                                                                                                        |
| 899 |     20.985315 |    446.649341 | Verdilak                                                                                                                                                              |
| 900 |    889.358512 |     17.976510 | Jon Hill                                                                                                                                                              |
| 901 |    281.188142 |    296.710406 | NA                                                                                                                                                                    |
| 902 |    376.017670 |    458.933993 | Collin Gross                                                                                                                                                          |
| 903 |    132.955871 |    631.691282 | Chris huh                                                                                                                                                             |
| 904 |    813.247404 |     77.853924 | Dmitry Bogdanov                                                                                                                                                       |
| 905 |    500.201659 |    287.821078 | Ferran Sayol                                                                                                                                                          |
| 906 |    997.185668 |    551.798978 | Ferran Sayol                                                                                                                                                          |
| 907 |    990.039297 |    347.177684 | T. Michael Keesey                                                                                                                                                     |
| 908 |    256.510826 |    262.421572 | Christoph Schomburg                                                                                                                                                   |
| 909 |    396.690759 |    199.320264 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 910 |     44.928778 |    563.318132 | Hugo Gruson                                                                                                                                                           |
| 911 |    138.103114 |    705.193538 | Felix Vaux                                                                                                                                                            |
| 912 |    995.392891 |    578.456952 | L. Shyamal                                                                                                                                                            |
| 913 |    810.288267 |    530.983105 | Armelle Ansart (photograph), Maxime Dahirel (digitisation)                                                                                                            |
| 914 |    411.538624 |    317.678751 | Ferran Sayol                                                                                                                                                          |
| 915 |    769.020391 |    112.093468 | Melissa Broussard                                                                                                                                                     |
| 916 |    771.279850 |    211.852625 | Hans Hillewaert                                                                                                                                                       |
| 917 |    228.807548 |    575.872824 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 918 |    600.558824 |    261.204426 | Michele M Tobias                                                                                                                                                      |
| 919 |   1007.337921 |    278.648477 | Zimices                                                                                                                                                               |
| 920 |    711.305603 |    596.825021 | Kamil S. Jaron                                                                                                                                                        |
| 921 |    584.452614 |    546.283547 | Christine Axon                                                                                                                                                        |
| 922 |    940.986615 |    772.980282 | Matt Crook                                                                                                                                                            |
| 923 |    408.536654 |     70.886264 | Matt Crook                                                                                                                                                            |
| 924 |      2.027537 |    276.211412 | T. Michael Keesey                                                                                                                                                     |
| 925 |   1008.693957 |      8.230792 | Sarah Werning                                                                                                                                                         |
| 926 |     22.172365 |    459.361807 | Markus A. Grohme                                                                                                                                                      |
| 927 |     71.114054 |    579.282710 | Gareth Monger                                                                                                                                                         |
| 928 |    300.461531 |    393.110836 | M Kolmann                                                                                                                                                             |
| 929 |    451.756212 |    344.942409 | Margot Michaud                                                                                                                                                        |
| 930 |     69.633668 |    733.231831 | Chloé Schmidt                                                                                                                                                         |

    #> Your tweet has been posted!
