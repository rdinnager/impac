
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

Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves),
Dmitry Bogdanov, vectorized by Zimices, Margot Michaud, Plukenet,
Michael Scroggie, Arthur S. Brum, Jessica Anne Miller, Markus A. Grohme,
Beth Reinke, Scott Hartman, Josefine Bohr Brask, Birgit Lang, Renato de
Carvalho Ferreira, Fritz Geller-Grimm (vectorized by T. Michael Keesey),
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Dori <dori@merr.info> (source photo)
and Nevit Dilmen, Emma Kissling, Jagged Fang Designs, Ignacio Contreras,
Christian A. Masnaghetti, Jose Carlos Arenas-Monroy, Andreas Preuss /
marauder, Martin Kevil, Kamil S. Jaron, Harold N Eyster, Zimices, Steven
Traver, Ferran Sayol, Zsoldos Márton (vectorized by T. Michael Keesey),
Ghedoghedo, Tauana J. Cunha, Matt Crook, Andy Wilson, Roberto Díaz
Sibaja, Inessa Voet, Tasman Dixon, Frederick William Frohawk (vectorized
by T. Michael Keesey), Nobu Tamura (vectorized by T. Michael Keesey),
Tracy A. Heath, Caio Bernardes, vectorized by Zimices, Emily Jane
McTavish, T. Michael Keesey, C. Camilo Julián-Caballero, Carlos
Cano-Barbacil, Mette Aumala, SauropodomorphMonarch, Jaime Headden,
modified by T. Michael Keesey, Andrew A. Farke, Manabu Bessho-Uehara,
Armin Reindl, Caleb M. Brown, Gareth Monger, Brad McFeeters (vectorized
by T. Michael Keesey), Scott Hartman (modified by T. Michael Keesey),
Andreas Hejnol, Gabriela Palomo-Munoz, Dinah Challen, Melissa Broussard,
Hans Hillewaert (vectorized by T. Michael Keesey), Kanchi Nanjo, Xavier
Giroux-Bougard, Jaime A. Headden (vectorized by T. Michael Keesey),
Mathilde Cordellier, Nobu Tamura, vectorized by Zimices, Mykle Hoban, T.
Michael Keesey (from a mount by Allis Markham), Zachary Quigley, James
I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel,
and Jelle P. Wiersma (vectorized by T. Michael Keesey), T. Michael
Keesey (after MPF), Shyamal, Benjamint444, Skye McDavid, Ville Koistinen
(vectorized by T. Michael Keesey), Dean Schnabel, Matt Martyniuk, Curtis
Clark and T. Michael Keesey, Jimmy Bernot, Filip em, Hugo Gruson,
Terpsichores, T. Tischler, Javier Luque, Taro Maeda, Collin Gross, U.S.
Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Dantheman9758 (vectorized by T. Michael Keesey), Chris
Jennings (vectorized by A. Verrière), Charles R. Knight, vectorized by
Zimices, Jaime Headden, L. Shyamal, T. Michael Keesey (from a photograph
by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Cesar
Julian, Sean McCann, Michelle Site, Sharon Wegner-Larsen, Yan Wong,
Chris huh, Steven Coombs, Aviceda (vectorized by T. Michael Keesey), Ben
Liebeskind, Chase Brownstein, Iain Reid, Oscar Sanisidro, Keith Murdock
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Emily Willoughby, Dmitry Bogdanov, Rebecca Groom, Ieuan Jones,
Tony Ayling (vectorized by T. Michael Keesey), Ellen Edmonson and Hugh
Chrisp (vectorized by T. Michael Keesey), Sarefo (vectorized by T.
Michael Keesey), Milton Tan, Joanna Wolfe, Dmitry Bogdanov (vectorized
by T. Michael Keesey), Ray Simpson (vectorized by T. Michael Keesey),
Matthew E. Clapham, Lafage, Tyler Greenfield, Alex Slavenko, Nina
Skinner, Chloé Schmidt, Pete Buchholz, Maija Karala, Crystal Maier,
(after McCulloch 1908), T. Michael Keesey (vectorization); Yves Bousquet
(photography), Lisa Byrne, Fernando Carezzano, Christine Axon, George
Edward Lodge (modified by T. Michael Keesey), Obsidian Soul (vectorized
by T. Michael Keesey), Matt Dempsey, Brian Gratwicke (photo) and T.
Michael Keesey (vectorization), Robbie N. Cada (vectorized by T. Michael
Keesey), Dave Angelini, Gregor Bucher, Max Farnworth, Juan Carlos Jerí,
Margret Flinsch, vectorized by Zimices, Ghedoghedo (vectorized by T.
Michael Keesey), Yan Wong from illustration by Jules Richard (1907),
Griensteidl and T. Michael Keesey, kreidefossilien.de, M Kolmann,
Danielle Alba, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Noah Schlottman, photo by Adam G. Clause, Smokeybjb
(modified by Mike Keesey), Kent Elson Sorgon, Smokeybjb (modified by T.
Michael Keesey), Kai R. Caspar, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), David
Liao, Timothy Knepp of the U.S. Fish and Wildlife Service (illustration)
and Timothy J. Bartley (silhouette), Robert Gay, Gopal Murali, Christoph
Schomburg, Campbell Fleming, Maxime Dahirel, Ingo Braasch, Neil Kelley,
Tim Bertelink (modified by T. Michael Keesey), Remes K, Ortega F, Fierro
I, Joger U, Kosma R, et al., Prin Pattawaro (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Renata F. Martins, Noah
Schlottman, T. Michael Keesey (vector) and Stuart Halliday (photograph),
FunkMonk, Matus Valach, (after Spotila 2004), Mali’o Kodis, photograph
property of National Museums of Northern Ireland, Mathew Wedel, Ron
Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Noah Schlottman, photo from Casey Dunn, Theodore W.
Pietsch (photography) and T. Michael Keesey (vectorization), Scott
Hartman (vectorized by T. Michael Keesey), nicubunu, Natalie Claunch,
Sergio A. Muñoz-Gómez, DFoidl (vectorized by T. Michael Keesey), Kailah
Thorn & Mark Hutchinson, Alexander Schmidt-Lebuhn, DW Bapst (modified
from Bates et al., 2005), Sam Fraser-Smith (vectorized by T. Michael
Keesey), Cristopher Silva, Aleksey Nagovitsyn (vectorized by T. Michael
Keesey), Chuanixn Yu, Natasha Vitek, Matt Wilkins,
www.studiospectre.com, Derek Bakken (photograph) and T. Michael Keesey
(vectorization), Joseph Smit (modified by T. Michael Keesey), Ewald
Rübsamen, Scott Reid, DW Bapst (modified from Bulman, 1970), Sarah
Werning, Becky Barnes, Jordan Mallon (vectorized by T. Michael Keesey),
Notafly (vectorized by T. Michael Keesey), Mali’o Kodis, image from
Brockhaus and Efron Encyclopedic Dictionary, Mali’o Kodis, image from
the Biodiversity Heritage Library, Julio Garza, terngirl, Felix Vaux,
Apokryltaros (vectorized by T. Michael Keesey), Christina N. Hodson,
Francesco “Architetto” Rollandin, C. W. Nash (illustration) and Timothy
J. Bartley (silhouette), Mario Quevedo, Conty (vectorized by T. Michael
Keesey), Stanton F. Fink, vectorized by Zimices, Andrew A. Farke, shell
lines added by Yan Wong, Benchill, Darren Naish, Nemo, and T. Michael
Keesey, Mason McNair, T. Michael Keesey (after C. De Muizon), John
Conway, Espen Horn (model; vectorized by T. Michael Keesey from a photo
by H. Zell), Maha Ghazal, Arthur Grosset (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Mike Keesey
(vectorization) and Vaibhavcho (photography), Stephen O’Connor
(vectorized by T. Michael Keesey), Ville Koistinen and T. Michael
Keesey, Smokeybjb, Michael Day, Henry Fairfield Osborn, vectorized by
Zimices, Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Robert Bruce Horsfall, from
W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”,
Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>),
CNZdenek, Agnello Picorelli, Nobu Tamura, Ramona J Heim, Alexandre Vong,
Elizabeth Parker, Manabu Sakamoto, Darren Naish (vectorize by T. Michael
Keesey), Davidson Sodré, Martin R. Smith, Tony Ayling (vectorized by
Milton Tan), E. D. Cope (modified by T. Michael Keesey, Michael P.
Taylor & Matthew J. Wedel), Yusan Yang, Raven Amos, Noah Schlottman,
photo by Martin V. Sørensen, Chris Hay, Jiekun He, Hans Hillewaert,
Catherine Yasuda, Robbie Cada (vectorized by T. Michael Keesey), Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Kanako Bessho-Uehara, DW Bapst, modified from Figure 1
of Belanger (2011, PALAIOS)., Myriam\_Ramirez, Lukasiniho, Joseph Wolf,
1863 (vectorization by Dinah Challen), Robert Bruce Horsfall, vectorized
by Zimices, Ludwik Gąsiorowski, Joe Schneid (vectorized by T. Michael
Keesey), Nobu Tamura and T. Michael Keesey, John Gould (vectorized by T.
Michael Keesey), White Wolf, Mo Hassan, , Tony Ayling, Jay Matternes
(vectorized by T. Michael Keesey), Jack Mayer Wood, Adrian Reich, Jon
Hill, Noah Schlottman, photo from National Science Foundation -
Turbellarian Taxonomic Database, Lauren Anderson, M. Antonio Todaro,
Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T.
Michael Keesey), Joschua Knüppe, Evan-Amos (vectorized by T. Michael
Keesey), Original drawing by Nobu Tamura, vectorized by Roberto Díaz
Sibaja, Dmitry Bogdanov (modified by T. Michael Keesey), SecretJellyMan,
Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja,
Abraão B. Leite, Diana Pomeroy, Julien Louys, Noah Schlottman, photo by
Carol Cummings, FJDegrange

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    316.360290 |    390.125348 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                            |
|   2 |    667.998366 |    414.355534 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                         |
|   3 |    184.553237 |    424.935757 | Margot Michaud                                                                                                                                                 |
|   4 |    861.910127 |    422.922805 | Plukenet                                                                                                                                                       |
|   5 |    201.920767 |    301.764532 | Michael Scroggie                                                                                                                                               |
|   6 |    401.573133 |    725.941684 | Arthur S. Brum                                                                                                                                                 |
|   7 |     91.005853 |    102.142061 | Jessica Anne Miller                                                                                                                                            |
|   8 |    234.783659 |    497.894358 | Markus A. Grohme                                                                                                                                               |
|   9 |    844.382266 |    187.227628 | Beth Reinke                                                                                                                                                    |
|  10 |    738.363590 |    706.945665 | Scott Hartman                                                                                                                                                  |
|  11 |    670.627378 |    201.220704 | Josefine Bohr Brask                                                                                                                                            |
|  12 |    717.960605 |    246.350288 | Birgit Lang                                                                                                                                                    |
|  13 |    183.496090 |    192.207388 | Renato de Carvalho Ferreira                                                                                                                                    |
|  14 |    428.560319 |    558.516036 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                           |
|  15 |    472.771919 |    239.161108 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
|  16 |    299.208083 |    107.227979 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                          |
|  17 |    718.738338 |    632.812331 | Emma Kissling                                                                                                                                                  |
|  18 |    158.296178 |    726.585853 | NA                                                                                                                                                             |
|  19 |    891.137217 |    575.015007 | Jagged Fang Designs                                                                                                                                            |
|  20 |    262.567988 |    652.877075 | Margot Michaud                                                                                                                                                 |
|  21 |    525.640180 |    620.005610 | Ignacio Contreras                                                                                                                                              |
|  22 |    417.857907 |    398.128937 | Birgit Lang                                                                                                                                                    |
|  23 |     43.295342 |    651.838165 | NA                                                                                                                                                             |
|  24 |    412.839046 |    313.739862 | Christian A. Masnaghetti                                                                                                                                       |
|  25 |    770.675936 |    572.608157 | Jose Carlos Arenas-Monroy                                                                                                                                      |
|  26 |    954.838400 |    657.261829 | Andreas Preuss / marauder                                                                                                                                      |
|  27 |     61.724610 |    495.712816 | Martin Kevil                                                                                                                                                   |
|  28 |    602.740958 |    150.431730 | Kamil S. Jaron                                                                                                                                                 |
|  29 |    733.298054 |    369.393252 | NA                                                                                                                                                             |
|  30 |    715.694006 |    122.915819 | Harold N Eyster                                                                                                                                                |
|  31 |     79.172791 |    246.945369 | Zimices                                                                                                                                                        |
|  32 |    950.642511 |    164.428587 | Steven Traver                                                                                                                                                  |
|  33 |    847.278827 |     44.160198 | Ferran Sayol                                                                                                                                                   |
|  34 |    296.284955 |    244.131299 | NA                                                                                                                                                             |
|  35 |    657.969897 |     37.895994 | NA                                                                                                                                                             |
|  36 |    409.780190 |    479.398539 | Margot Michaud                                                                                                                                                 |
|  37 |    593.159854 |    484.926085 | Zimices                                                                                                                                                        |
|  38 |    243.060547 |    556.080049 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                               |
|  39 |    512.841543 |     74.773325 | Ghedoghedo                                                                                                                                                     |
|  40 |    548.079598 |    337.991050 | Tauana J. Cunha                                                                                                                                                |
|  41 |    388.723266 |    174.407660 | Matt Crook                                                                                                                                                     |
|  42 |    231.458580 |    768.394102 | NA                                                                                                                                                             |
|  43 |    587.893710 |    250.639546 | Andy Wilson                                                                                                                                                    |
|  44 |    836.085515 |    295.912625 | Roberto Díaz Sibaja                                                                                                                                            |
|  45 |    132.760474 |    594.532758 | Inessa Voet                                                                                                                                                    |
|  46 |    355.383097 |    620.655048 | Tasman Dixon                                                                                                                                                   |
|  47 |    347.446851 |     43.025327 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                    |
|  48 |    946.006567 |    295.195659 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  49 |     77.635138 |    286.047871 | Tracy A. Heath                                                                                                                                                 |
|  50 |    866.123309 |    767.345422 | Caio Bernardes, vectorized by Zimices                                                                                                                          |
|  51 |     81.593124 |    363.424119 | Ferran Sayol                                                                                                                                                   |
|  52 |    917.670771 |     82.942610 | Markus A. Grohme                                                                                                                                               |
|  53 |    983.057718 |    347.429387 | Andy Wilson                                                                                                                                                    |
|  54 |    191.678113 |     64.906378 | Emily Jane McTavish                                                                                                                                            |
|  55 |    451.487775 |    662.822973 | Jagged Fang Designs                                                                                                                                            |
|  56 |    515.535211 |    763.310789 | Steven Traver                                                                                                                                                  |
|  57 |    698.988584 |    761.011539 | T. Michael Keesey                                                                                                                                              |
|  58 |    540.998344 |    568.671475 | C. Camilo Julián-Caballero                                                                                                                                     |
|  59 |    702.891778 |    309.917657 | Jagged Fang Designs                                                                                                                                            |
|  60 |    428.310946 |     65.354343 | Kamil S. Jaron                                                                                                                                                 |
|  61 |    245.656620 |    708.243256 | Carlos Cano-Barbacil                                                                                                                                           |
|  62 |    489.455644 |    175.640228 | Mette Aumala                                                                                                                                                   |
|  63 |    798.086556 |    508.966455 | Steven Traver                                                                                                                                                  |
|  64 |    391.050212 |    265.619066 | SauropodomorphMonarch                                                                                                                                          |
|  65 |    835.681474 |    636.622088 | Jaime Headden, modified by T. Michael Keesey                                                                                                                   |
|  66 |     70.055290 |    177.754345 | Scott Hartman                                                                                                                                                  |
|  67 |    702.788273 |    658.430407 | NA                                                                                                                                                             |
|  68 |    653.943388 |    597.386909 | Andrew A. Farke                                                                                                                                                |
|  69 |     70.403962 |    738.369973 | Manabu Bessho-Uehara                                                                                                                                           |
|  70 |    966.784738 |    507.641303 | Armin Reindl                                                                                                                                                   |
|  71 |     97.967455 |     18.692166 | Jagged Fang Designs                                                                                                                                            |
|  72 |    439.194073 |    358.252515 | Caleb M. Brown                                                                                                                                                 |
|  73 |    283.670456 |    480.893148 | T. Michael Keesey                                                                                                                                              |
|  74 |    571.859339 |    654.556261 | Gareth Monger                                                                                                                                                  |
|  75 |    595.252765 |    391.139348 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
|  76 |    291.924883 |    363.825101 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                  |
|  77 |    116.930396 |    679.515873 | Zimices                                                                                                                                                        |
|  78 |    104.166839 |    767.258565 | Ignacio Contreras                                                                                                                                              |
|  79 |    203.021181 |    139.530844 | Matt Crook                                                                                                                                                     |
|  80 |    777.655693 |     39.730116 | Andy Wilson                                                                                                                                                    |
|  81 |    756.453961 |    406.107069 | Gareth Monger                                                                                                                                                  |
|  82 |    515.596012 |    137.414901 | Andreas Hejnol                                                                                                                                                 |
|  83 |    928.742397 |    766.565626 | Matt Crook                                                                                                                                                     |
|  84 |    124.931989 |    331.131811 | Gabriela Palomo-Munoz                                                                                                                                          |
|  85 |    310.212241 |    564.423931 | Dinah Challen                                                                                                                                                  |
|  86 |    783.030430 |    207.525211 | Andy Wilson                                                                                                                                                    |
|  87 |    323.470900 |    141.736842 | Melissa Broussard                                                                                                                                              |
|  88 |    951.369008 |     22.769437 | Kamil S. Jaron                                                                                                                                                 |
|  89 |    314.774962 |    370.456513 | Margot Michaud                                                                                                                                                 |
|  90 |    243.770185 |    314.554776 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
|  91 |    266.829605 |    441.288817 | Ferran Sayol                                                                                                                                                   |
|  92 |     25.556052 |    381.170146 | Kamil S. Jaron                                                                                                                                                 |
|  93 |     23.356299 |    238.264276 | Matt Crook                                                                                                                                                     |
|  94 |    289.937292 |    449.240059 | Kanchi Nanjo                                                                                                                                                   |
|  95 |     68.267402 |    790.936775 | Xavier Giroux-Bougard                                                                                                                                          |
|  96 |    983.347687 |    433.916902 | NA                                                                                                                                                             |
|  97 |    502.877228 |     55.739679 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                             |
|  98 |   1004.370518 |    427.882497 | Mathilde Cordellier                                                                                                                                            |
|  99 |    422.117401 |    641.083173 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 100 |    521.403838 |    399.942219 | Mykle Hoban                                                                                                                                                    |
| 101 |    126.111647 |    369.490041 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                              |
| 102 |    623.243082 |    338.944595 | Scott Hartman                                                                                                                                                  |
| 103 |    517.929549 |     15.556279 | Margot Michaud                                                                                                                                                 |
| 104 |    630.964867 |    633.864388 | Zachary Quigley                                                                                                                                                |
| 105 |    289.517834 |    593.817781 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                           |
| 106 |    994.404788 |    749.366386 | T. Michael Keesey (after MPF)                                                                                                                                  |
| 107 |    757.495736 |    783.753756 | Zimices                                                                                                                                                        |
| 108 |    675.006354 |    465.556587 | NA                                                                                                                                                             |
| 109 |    643.878313 |    456.181146 | Jagged Fang Designs                                                                                                                                            |
| 110 |    600.102232 |     61.376838 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 111 |    366.173248 |    589.516769 | Shyamal                                                                                                                                                        |
| 112 |    398.083637 |    225.166566 | Carlos Cano-Barbacil                                                                                                                                           |
| 113 |     23.507536 |    699.516775 | Benjamint444                                                                                                                                                   |
| 114 |    177.949204 |     22.838637 | Skye McDavid                                                                                                                                                   |
| 115 |     24.385538 |    659.843124 | T. Michael Keesey                                                                                                                                              |
| 116 |    746.216012 |    444.221326 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                              |
| 117 |    561.858465 |    187.457820 | Dean Schnabel                                                                                                                                                  |
| 118 |    617.529592 |    677.110484 | Matt Martyniuk                                                                                                                                                 |
| 119 |    969.539714 |    705.758170 | Scott Hartman                                                                                                                                                  |
| 120 |    442.799754 |    323.118302 | Markus A. Grohme                                                                                                                                               |
| 121 |     17.203669 |    342.795190 | Andrew A. Farke                                                                                                                                                |
| 122 |    215.469899 |    518.514535 | Skye McDavid                                                                                                                                                   |
| 123 |    323.703282 |    243.532053 | Curtis Clark and T. Michael Keesey                                                                                                                             |
| 124 |    431.786972 |    760.655686 | Jimmy Bernot                                                                                                                                                   |
| 125 |    349.657645 |    758.677195 | Filip em                                                                                                                                                       |
| 126 |    301.014068 |    792.442645 | Hugo Gruson                                                                                                                                                    |
| 127 |    362.409100 |     99.531527 | Terpsichores                                                                                                                                                   |
| 128 |    373.320090 |    237.089116 | T. Tischler                                                                                                                                                    |
| 129 |    986.942601 |     44.829044 | Javier Luque                                                                                                                                                   |
| 130 |    397.755244 |     92.692941 | Caleb M. Brown                                                                                                                                                 |
| 131 |    627.566819 |    763.637148 | Martin Kevil                                                                                                                                                   |
| 132 |    320.972084 |    532.621598 | Taro Maeda                                                                                                                                                     |
| 133 |    614.342479 |    450.215744 | Gareth Monger                                                                                                                                                  |
| 134 |    694.141415 |    617.646802 | Kanchi Nanjo                                                                                                                                                   |
| 135 |    443.142152 |    173.620493 | Collin Gross                                                                                                                                                   |
| 136 |    346.739309 |    564.092642 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 137 |    409.947740 |    376.847214 | Gareth Monger                                                                                                                                                  |
| 138 |    389.003248 |    203.845988 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                |
| 139 |    279.885141 |    681.094184 | Chris Jennings (vectorized by A. Verrière)                                                                                                                     |
| 140 |    966.258491 |    751.545664 | Gareth Monger                                                                                                                                                  |
| 141 |     38.203356 |    427.686073 | Margot Michaud                                                                                                                                                 |
| 142 |    482.601213 |    491.203726 | Charles R. Knight, vectorized by Zimices                                                                                                                       |
| 143 |     52.401704 |    219.118205 | Beth Reinke                                                                                                                                                    |
| 144 |     24.263770 |    785.917062 | Zimices                                                                                                                                                        |
| 145 |    252.198956 |    232.650649 | Kamil S. Jaron                                                                                                                                                 |
| 146 |    287.949315 |    693.718851 | Jaime Headden                                                                                                                                                  |
| 147 |    750.357821 |    417.020125 | L. Shyamal                                                                                                                                                     |
| 148 |    403.294501 |    780.054329 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                              |
| 149 |    498.952434 |    728.953126 | T. Michael Keesey                                                                                                                                              |
| 150 |    576.022022 |     30.559364 | Cesar Julian                                                                                                                                                   |
| 151 |    886.547694 |    637.602422 | Matt Crook                                                                                                                                                     |
| 152 |    495.091182 |     12.530570 | Ferran Sayol                                                                                                                                                   |
| 153 |    114.589624 |    157.961344 | Margot Michaud                                                                                                                                                 |
| 154 |    770.224160 |    674.061982 | Steven Traver                                                                                                                                                  |
| 155 |    226.581300 |     91.727377 | Jagged Fang Designs                                                                                                                                            |
| 156 |    208.290929 |    106.869162 | Melissa Broussard                                                                                                                                              |
| 157 |    531.422103 |    708.162373 | Markus A. Grohme                                                                                                                                               |
| 158 |    469.825872 |    128.770063 | Sean McCann                                                                                                                                                    |
| 159 |    867.165802 |    310.932950 | Michelle Site                                                                                                                                                  |
| 160 |    941.605803 |    424.577170 | Dean Schnabel                                                                                                                                                  |
| 161 |    164.720278 |    230.271040 | Sharon Wegner-Larsen                                                                                                                                           |
| 162 |    771.939086 |    233.548086 | NA                                                                                                                                                             |
| 163 |    524.141996 |    680.154840 | T. Michael Keesey                                                                                                                                              |
| 164 |     14.701388 |    567.046035 | Yan Wong                                                                                                                                                       |
| 165 |     26.536744 |    158.928657 | Scott Hartman                                                                                                                                                  |
| 166 |    956.680558 |    788.361172 | Zimices                                                                                                                                                        |
| 167 |    387.761940 |    135.386608 | Michelle Site                                                                                                                                                  |
| 168 |    817.656678 |    665.436180 | Sean McCann                                                                                                                                                    |
| 169 |    590.927946 |    444.491195 | Gareth Monger                                                                                                                                                  |
| 170 |    811.708497 |    183.843131 | Gareth Monger                                                                                                                                                  |
| 171 |    966.549679 |    728.218943 | Matt Crook                                                                                                                                                     |
| 172 |    154.716398 |    660.777029 | Chris huh                                                                                                                                                      |
| 173 |    356.636105 |    398.859451 | Gareth Monger                                                                                                                                                  |
| 174 |    390.105556 |    294.513323 | Gabriela Palomo-Munoz                                                                                                                                          |
| 175 |     24.731841 |    547.086970 | Ignacio Contreras                                                                                                                                              |
| 176 |    543.071874 |    694.809474 | Margot Michaud                                                                                                                                                 |
| 177 |     59.399813 |    768.059107 | Steven Coombs                                                                                                                                                  |
| 178 |    706.644224 |    669.042672 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                      |
| 179 |    343.841421 |    537.213753 | Birgit Lang                                                                                                                                                    |
| 180 |    504.613829 |    603.433397 | Tasman Dixon                                                                                                                                                   |
| 181 |    981.053556 |    293.372310 | Tracy A. Heath                                                                                                                                                 |
| 182 |    208.607272 |    341.753176 | Gabriela Palomo-Munoz                                                                                                                                          |
| 183 |    461.893289 |    522.575030 | Ben Liebeskind                                                                                                                                                 |
| 184 |     15.255493 |    333.183209 | Zimices                                                                                                                                                        |
| 185 |    944.147192 |    675.172930 | Andy Wilson                                                                                                                                                    |
| 186 |    786.383622 |    116.977223 | Chase Brownstein                                                                                                                                               |
| 187 |    969.769490 |     99.933268 | Iain Reid                                                                                                                                                      |
| 188 |    476.287353 |    636.227087 | Chase Brownstein                                                                                                                                               |
| 189 |    842.179380 |    486.245724 | Margot Michaud                                                                                                                                                 |
| 190 |    887.402031 |    156.215149 | Jagged Fang Designs                                                                                                                                            |
| 191 |    610.906070 |    688.684756 | C. Camilo Julián-Caballero                                                                                                                                     |
| 192 |    914.312675 |     30.795533 | T. Michael Keesey                                                                                                                                              |
| 193 |    151.425325 |      9.969694 | Oscar Sanisidro                                                                                                                                                |
| 194 |     14.546919 |    364.301446 | Gareth Monger                                                                                                                                                  |
| 195 |    349.241818 |    154.282727 | Margot Michaud                                                                                                                                                 |
| 196 |    879.060379 |     11.143834 | Gareth Monger                                                                                                                                                  |
| 197 |    835.170870 |    538.230512 | Zimices                                                                                                                                                        |
| 198 |    476.727174 |    321.550334 | Harold N Eyster                                                                                                                                                |
| 199 |    771.917388 |    457.411455 | Roberto Díaz Sibaja                                                                                                                                            |
| 200 |    147.388226 |     91.048848 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 201 |    510.498735 |    710.735821 | Emily Willoughby                                                                                                                                               |
| 202 |    615.647352 |    621.193299 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 203 |    532.926862 |    503.348169 | Scott Hartman                                                                                                                                                  |
| 204 |    138.961140 |    652.111270 | Dmitry Bogdanov                                                                                                                                                |
| 205 |    709.395975 |    475.914433 | Chris huh                                                                                                                                                      |
| 206 |    942.389092 |    264.254808 | Zimices                                                                                                                                                        |
| 207 |   1004.086120 |    215.828989 | Scott Hartman                                                                                                                                                  |
| 208 |    902.185942 |    495.554172 | Rebecca Groom                                                                                                                                                  |
| 209 |    981.058408 |    110.691555 | NA                                                                                                                                                             |
| 210 |    921.320295 |    344.532706 | Zimices                                                                                                                                                        |
| 211 |    224.895379 |    233.357567 | Ieuan Jones                                                                                                                                                    |
| 212 |    201.431490 |    736.922965 | Jagged Fang Designs                                                                                                                                            |
| 213 |    855.246542 |      8.009539 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 214 |    622.075291 |    322.539607 | Andy Wilson                                                                                                                                                    |
| 215 |   1001.011849 |     49.586967 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                               |
| 216 |    240.204383 |    117.884712 | Gareth Monger                                                                                                                                                  |
| 217 |    575.480583 |    429.327308 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                       |
| 218 |    889.530813 |    211.013307 | Markus A. Grohme                                                                                                                                               |
| 219 |    697.857185 |    184.282016 | Zimices                                                                                                                                                        |
| 220 |    119.196123 |    115.768019 | Matt Crook                                                                                                                                                     |
| 221 |    715.983630 |    786.980047 | NA                                                                                                                                                             |
| 222 |    976.335264 |    402.055027 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 223 |   1003.602063 |    139.121210 | Yan Wong                                                                                                                                                       |
| 224 |     95.737243 |    646.974095 | Milton Tan                                                                                                                                                     |
| 225 |    358.360722 |    578.923688 | Matt Crook                                                                                                                                                     |
| 226 |    374.137390 |    315.314679 | NA                                                                                                                                                             |
| 227 |    283.946421 |    187.145341 | Beth Reinke                                                                                                                                                    |
| 228 |     53.046168 |    579.202467 | Joanna Wolfe                                                                                                                                                   |
| 229 |    737.438011 |    517.652796 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 230 |    657.719112 |     92.218178 | NA                                                                                                                                                             |
| 231 |    482.300118 |    257.624763 | Matt Crook                                                                                                                                                     |
| 232 |     20.416384 |    771.181925 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                  |
| 233 |    468.504280 |    734.424697 | Matthew E. Clapham                                                                                                                                             |
| 234 |     32.247372 |    318.546776 | Gareth Monger                                                                                                                                                  |
| 235 |    946.636195 |    207.228240 | Lafage                                                                                                                                                         |
| 236 |    235.923393 |    143.253892 | Matt Crook                                                                                                                                                     |
| 237 |    728.089536 |    330.270923 | Andy Wilson                                                                                                                                                    |
| 238 |    311.829356 |    319.033360 | Tyler Greenfield                                                                                                                                               |
| 239 |    330.057238 |    686.798332 | Alex Slavenko                                                                                                                                                  |
| 240 |    664.456197 |     82.744145 | Nina Skinner                                                                                                                                                   |
| 241 |    807.400770 |    242.578595 | Kamil S. Jaron                                                                                                                                                 |
| 242 |    503.658689 |    369.259471 | Chloé Schmidt                                                                                                                                                  |
| 243 |    711.931131 |    449.817675 | Chris huh                                                                                                                                                      |
| 244 |    389.550880 |    712.746888 | Pete Buchholz                                                                                                                                                  |
| 245 |    809.461544 |    656.673464 | Carlos Cano-Barbacil                                                                                                                                           |
| 246 |    992.092133 |    621.155627 | Maija Karala                                                                                                                                                   |
| 247 |    269.629563 |    161.680455 | Crystal Maier                                                                                                                                                  |
| 248 |     19.626143 |    355.620736 | Gareth Monger                                                                                                                                                  |
| 249 |    353.449226 |    778.585977 | NA                                                                                                                                                             |
| 250 |    331.311117 |    433.067896 | Matt Crook                                                                                                                                                     |
| 251 |    106.330821 |    131.778090 | Steven Traver                                                                                                                                                  |
| 252 |    793.988245 |    235.603552 | Matt Crook                                                                                                                                                     |
| 253 |    152.066085 |     41.194618 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 254 |    758.838053 |    336.122146 | Kamil S. Jaron                                                                                                                                                 |
| 255 |    109.045069 |    400.158666 | Lafage                                                                                                                                                         |
| 256 |     98.602656 |     45.403647 | Ferran Sayol                                                                                                                                                   |
| 257 |    441.779043 |    598.314875 | Zimices                                                                                                                                                        |
| 258 |    994.330283 |    155.280641 | Matt Crook                                                                                                                                                     |
| 259 |    336.018901 |    189.971628 | NA                                                                                                                                                             |
| 260 |    305.408868 |    628.756379 | (after McCulloch 1908)                                                                                                                                         |
| 261 |    822.217074 |    594.582533 | Margot Michaud                                                                                                                                                 |
| 262 |    982.766946 |      9.749212 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                 |
| 263 |    452.898513 |    516.135416 | Lisa Byrne                                                                                                                                                     |
| 264 |    524.463300 |    485.084920 | Scott Hartman                                                                                                                                                  |
| 265 |    171.040432 |     60.463223 | Scott Hartman                                                                                                                                                  |
| 266 |    459.244081 |    714.621349 | Birgit Lang                                                                                                                                                    |
| 267 |    278.316729 |     14.819505 | Jagged Fang Designs                                                                                                                                            |
| 268 |    543.135405 |    604.351139 | Matt Crook                                                                                                                                                     |
| 269 |    388.402882 |    363.908312 | Gabriela Palomo-Munoz                                                                                                                                          |
| 270 |    914.672058 |    246.416009 | Fernando Carezzano                                                                                                                                             |
| 271 |     47.938110 |      7.682714 | Michael Scroggie                                                                                                                                               |
| 272 |    631.895015 |    561.639483 | Gabriela Palomo-Munoz                                                                                                                                          |
| 273 |    711.697672 |    538.423368 | Margot Michaud                                                                                                                                                 |
| 274 |    966.527521 |    613.479333 | Zimices                                                                                                                                                        |
| 275 |    212.951203 |    669.482676 | Dean Schnabel                                                                                                                                                  |
| 276 |    843.678916 |    130.237133 | Zimices                                                                                                                                                        |
| 277 |    594.348418 |     73.920856 | Christine Axon                                                                                                                                                 |
| 278 |    381.251612 |    603.762063 | Gareth Monger                                                                                                                                                  |
| 279 |    343.208577 |    280.733704 | L. Shyamal                                                                                                                                                     |
| 280 |    712.516675 |    170.467792 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                            |
| 281 |    170.674085 |    285.447863 | Markus A. Grohme                                                                                                                                               |
| 282 |    757.156521 |    478.759857 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 283 |      6.850411 |    193.688766 | Gareth Monger                                                                                                                                                  |
| 284 |    438.604305 |    528.831118 | Matt Dempsey                                                                                                                                                   |
| 285 |    986.014153 |    244.418407 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                  |
| 286 |    593.611519 |    622.027718 | Lisa Byrne                                                                                                                                                     |
| 287 |    632.408102 |    278.428919 | T. Michael Keesey                                                                                                                                              |
| 288 |    670.931331 |    487.647431 | Matt Crook                                                                                                                                                     |
| 289 |    814.563985 |    162.456530 | Scott Hartman                                                                                                                                                  |
| 290 |    695.736523 |     48.628263 | Matt Crook                                                                                                                                                     |
| 291 |    135.232345 |    149.371852 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 292 |   1016.054147 |    689.597740 | Steven Traver                                                                                                                                                  |
| 293 |    757.131260 |     18.581005 | Birgit Lang                                                                                                                                                    |
| 294 |    997.703320 |    451.922273 | Dave Angelini                                                                                                                                                  |
| 295 |    287.189219 |    610.940031 | Matt Crook                                                                                                                                                     |
| 296 |    199.898690 |    538.618463 | Tasman Dixon                                                                                                                                                   |
| 297 |    338.011695 |    721.552746 | Gregor Bucher, Max Farnworth                                                                                                                                   |
| 298 |    626.111936 |    541.348354 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 299 |    757.160701 |    277.310127 | Carlos Cano-Barbacil                                                                                                                                           |
| 300 |    589.442486 |    450.780552 | Juan Carlos Jerí                                                                                                                                               |
| 301 |    503.496858 |    390.128373 | Ferran Sayol                                                                                                                                                   |
| 302 |    364.267608 |    563.444986 | Dean Schnabel                                                                                                                                                  |
| 303 |    226.604586 |    358.306968 | Gabriela Palomo-Munoz                                                                                                                                          |
| 304 |    254.654483 |    342.953864 | Margret Flinsch, vectorized by Zimices                                                                                                                         |
| 305 |    661.997552 |    285.510833 | Birgit Lang                                                                                                                                                    |
| 306 |    180.533680 |     38.643114 | Ferran Sayol                                                                                                                                                   |
| 307 |    729.681225 |    394.638677 | Gabriela Palomo-Munoz                                                                                                                                          |
| 308 |    607.050073 |    753.809306 | Markus A. Grohme                                                                                                                                               |
| 309 |    974.490581 |    603.006537 | Tasman Dixon                                                                                                                                                   |
| 310 |    557.129855 |     36.122751 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 311 |    791.738568 |    766.417063 | Matt Crook                                                                                                                                                     |
| 312 |    729.088978 |    668.388099 | Yan Wong from illustration by Jules Richard (1907)                                                                                                             |
| 313 |    679.176365 |    340.420290 | NA                                                                                                                                                             |
| 314 |    639.389792 |    649.647013 | Griensteidl and T. Michael Keesey                                                                                                                              |
| 315 |    612.049671 |    738.607782 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 316 |    726.679207 |    273.905904 | Ferran Sayol                                                                                                                                                   |
| 317 |    493.785388 |    298.473521 | Matt Crook                                                                                                                                                     |
| 318 |    538.367439 |    728.624891 | Matt Crook                                                                                                                                                     |
| 319 |    133.527187 |    283.793155 | Tasman Dixon                                                                                                                                                   |
| 320 |    813.073427 |    745.442110 | kreidefossilien.de                                                                                                                                             |
| 321 |    366.019207 |    427.700484 | M Kolmann                                                                                                                                                      |
| 322 |    184.968779 |     78.999905 | T. Michael Keesey                                                                                                                                              |
| 323 |    782.994522 |    218.158505 | Gareth Monger                                                                                                                                                  |
| 324 |    823.077601 |    118.306890 | T. Michael Keesey                                                                                                                                              |
| 325 |    779.964180 |    533.145617 | Roberto Díaz Sibaja                                                                                                                                            |
| 326 |    568.172755 |    593.823612 | Danielle Alba                                                                                                                                                  |
| 327 |    223.404937 |    153.620260 | Tracy A. Heath                                                                                                                                                 |
| 328 |    673.829983 |    543.561930 | Gareth Monger                                                                                                                                                  |
| 329 |   1004.537055 |    104.369244 | Gabriela Palomo-Munoz                                                                                                                                          |
| 330 |    585.486066 |    774.042114 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                |
| 331 |    287.078096 |    739.819426 | Steven Traver                                                                                                                                                  |
| 332 |    568.085740 |     96.414823 | Gabriela Palomo-Munoz                                                                                                                                          |
| 333 |    382.570292 |    644.184473 | Andrew A. Farke                                                                                                                                                |
| 334 |     12.075956 |    657.733833 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                |
| 335 |    981.473585 |    671.500418 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 336 |    642.689143 |    302.528945 | Gabriela Palomo-Munoz                                                                                                                                          |
| 337 |     62.132943 |    201.290843 | Noah Schlottman, photo by Adam G. Clause                                                                                                                       |
| 338 |    890.840801 |    129.107596 | Smokeybjb (modified by Mike Keesey)                                                                                                                            |
| 339 |    379.482815 |    444.000837 | Kent Elson Sorgon                                                                                                                                              |
| 340 |    913.631033 |    793.732690 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                      |
| 341 |    411.875815 |    436.023499 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 342 |    983.118813 |    132.713125 | Gareth Monger                                                                                                                                                  |
| 343 |    135.254214 |    534.680437 | Margot Michaud                                                                                                                                                 |
| 344 |    443.721616 |    765.990550 | Zachary Quigley                                                                                                                                                |
| 345 |    503.874733 |     65.756403 | Kai R. Caspar                                                                                                                                                  |
| 346 |    996.722553 |    669.929751 | Matt Crook                                                                                                                                                     |
| 347 |    524.159208 |    738.147812 | Zimices                                                                                                                                                        |
| 348 |    179.999883 |    268.156367 | Steven Traver                                                                                                                                                  |
| 349 |    762.175372 |    441.078494 | Andy Wilson                                                                                                                                                    |
| 350 |    961.451345 |    227.643029 | Matt Crook                                                                                                                                                     |
| 351 |     35.870291 |    139.379881 | Margot Michaud                                                                                                                                                 |
| 352 |   1004.154126 |    279.658955 | Birgit Lang                                                                                                                                                    |
| 353 |    449.304122 |    436.108164 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 354 |    355.417463 |     88.532709 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 355 |    356.377541 |    681.934526 | Margot Michaud                                                                                                                                                 |
| 356 |    612.901611 |    354.194007 | Andy Wilson                                                                                                                                                    |
| 357 |    416.132427 |    284.905313 | Gareth Monger                                                                                                                                                  |
| 358 |    522.598513 |    529.092112 | Matt Crook                                                                                                                                                     |
| 359 |    403.291590 |    691.443762 | David Liao                                                                                                                                                     |
| 360 |    294.618985 |     78.557561 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                         |
| 361 |    573.506837 |    373.500080 | Tasman Dixon                                                                                                                                                   |
| 362 |    129.464929 |    719.495332 | Andy Wilson                                                                                                                                                    |
| 363 |    674.387338 |    782.228865 | Chris huh                                                                                                                                                      |
| 364 |    782.736752 |    259.503842 | Zimices                                                                                                                                                        |
| 365 |     59.938171 |    126.985148 | Gabriela Palomo-Munoz                                                                                                                                          |
| 366 |    955.805354 |    579.897322 | Tasman Dixon                                                                                                                                                   |
| 367 |    924.103035 |     67.488707 | Zimices                                                                                                                                                        |
| 368 |    597.042793 |    204.280581 | Margot Michaud                                                                                                                                                 |
| 369 |    488.897345 |    460.018605 | Robert Gay                                                                                                                                                     |
| 370 |    625.098229 |    309.968710 | Scott Hartman                                                                                                                                                  |
| 371 |    654.055803 |    746.423258 | Lafage                                                                                                                                                         |
| 372 |    824.621327 |    174.711934 | Dinah Challen                                                                                                                                                  |
| 373 |    305.541646 |    516.358752 | NA                                                                                                                                                             |
| 374 |    240.588302 |     16.249693 | Hugo Gruson                                                                                                                                                    |
| 375 |    923.463388 |    259.932758 | Gopal Murali                                                                                                                                                   |
| 376 |    346.531133 |    485.812262 | Matt Crook                                                                                                                                                     |
| 377 |    523.025086 |    109.401178 | Christoph Schomburg                                                                                                                                            |
| 378 |    503.487287 |    378.335043 | Campbell Fleming                                                                                                                                               |
| 379 |    997.154814 |    468.761424 | Emily Willoughby                                                                                                                                               |
| 380 |    830.470011 |    127.328052 | Maxime Dahirel                                                                                                                                                 |
| 381 |    882.106709 |    532.249317 | Gopal Murali                                                                                                                                                   |
| 382 |    931.657697 |    697.330094 | Gareth Monger                                                                                                                                                  |
| 383 |     66.848015 |    268.578293 | Jagged Fang Designs                                                                                                                                            |
| 384 |    857.771470 |    459.133626 | T. Michael Keesey                                                                                                                                              |
| 385 |     15.236477 |    755.455270 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                       |
| 386 |    156.672293 |    545.966388 | Matt Crook                                                                                                                                                     |
| 387 |    957.961030 |    399.457184 | Zimices                                                                                                                                                        |
| 388 |    194.859375 |    118.527085 | Ingo Braasch                                                                                                                                                   |
| 389 |    878.551331 |    118.256062 | Gareth Monger                                                                                                                                                  |
| 390 |    389.229107 |    522.596575 | Christoph Schomburg                                                                                                                                            |
| 391 |    930.265045 |     30.393996 | Neil Kelley                                                                                                                                                    |
| 392 |    892.054028 |    683.221805 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                  |
| 393 |    769.439942 |    765.268546 | Curtis Clark and T. Michael Keesey                                                                                                                             |
| 394 |     89.457477 |      5.115201 | Maija Karala                                                                                                                                                   |
| 395 |     70.736641 |    546.965811 | Andrew A. Farke                                                                                                                                                |
| 396 |    500.975491 |    544.453853 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                          |
| 397 |    987.584300 |    608.700235 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                      |
| 398 |    116.219124 |    266.469328 | Kamil S. Jaron                                                                                                                                                 |
| 399 |    485.311049 |    339.196805 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 400 |    547.439443 |     84.299527 | NA                                                                                                                                                             |
| 401 |    365.052272 |    126.898602 | Gareth Monger                                                                                                                                                  |
| 402 |    789.335598 |    155.998979 | Chris huh                                                                                                                                                      |
| 403 |    856.067949 |    604.263540 | Tasman Dixon                                                                                                                                                   |
| 404 |    435.355844 |    619.512565 | Tracy A. Heath                                                                                                                                                 |
| 405 |    132.121270 |    545.627142 | Steven Traver                                                                                                                                                  |
| 406 |    415.746908 |    392.686067 | Caio Bernardes, vectorized by Zimices                                                                                                                          |
| 407 |     35.131628 |    110.512618 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 408 |    183.301111 |    145.513739 | NA                                                                                                                                                             |
| 409 |    475.411849 |    385.995488 | Renata F. Martins                                                                                                                                              |
| 410 |    604.353340 |    777.879536 | NA                                                                                                                                                             |
| 411 |    316.324859 |    722.185300 | Noah Schlottman                                                                                                                                                |
| 412 |    211.683950 |    219.239945 | T. Michael Keesey                                                                                                                                              |
| 413 |    239.805376 |     53.337009 | Steven Traver                                                                                                                                                  |
| 414 |    792.231169 |    180.197226 | Steven Traver                                                                                                                                                  |
| 415 |    588.523514 |    627.842650 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                    |
| 416 |    255.649546 |     46.228766 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
| 417 |    896.142196 |    511.076137 | Carlos Cano-Barbacil                                                                                                                                           |
| 418 |    919.433372 |    673.850745 | Kanchi Nanjo                                                                                                                                                   |
| 419 |    233.376120 |    462.489744 | Ferran Sayol                                                                                                                                                   |
| 420 |    246.574694 |     63.441250 | Chris huh                                                                                                                                                      |
| 421 |    511.997948 |    686.792118 | FunkMonk                                                                                                                                                       |
| 422 |    581.795395 |    594.554535 | Matus Valach                                                                                                                                                   |
| 423 |    818.686801 |    463.826015 | Maxime Dahirel                                                                                                                                                 |
| 424 |    134.683261 |    162.010987 | Margot Michaud                                                                                                                                                 |
| 425 |    354.714355 |    664.093828 | (after Spotila 2004)                                                                                                                                           |
| 426 |    560.156068 |    601.843948 | Steven Traver                                                                                                                                                  |
| 427 |    826.745496 |    248.579566 | Margot Michaud                                                                                                                                                 |
| 428 |    857.747862 |    736.322442 | Markus A. Grohme                                                                                                                                               |
| 429 |    760.353628 |     50.138651 | Matt Crook                                                                                                                                                     |
| 430 |    942.187621 |    595.174753 | Margot Michaud                                                                                                                                                 |
| 431 |    385.818819 |    430.205248 | Michael Scroggie                                                                                                                                               |
| 432 |    149.416383 |    517.584707 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                      |
| 433 |    128.312704 |     45.483832 | Cesar Julian                                                                                                                                                   |
| 434 |    920.261147 |    708.655494 | Matt Crook                                                                                                                                                     |
| 435 |    125.925037 |    255.823568 | Jagged Fang Designs                                                                                                                                            |
| 436 |    837.846601 |     10.592788 | NA                                                                                                                                                             |
| 437 |    792.291945 |    319.613556 | Gareth Monger                                                                                                                                                  |
| 438 |    319.287344 |    391.029640 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 439 |    547.840544 |    635.864188 | Carlos Cano-Barbacil                                                                                                                                           |
| 440 |    580.298570 |     87.514242 | Mathew Wedel                                                                                                                                                   |
| 441 |    449.697030 |    152.409289 | Zimices                                                                                                                                                        |
| 442 |    708.445952 |     13.643172 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                   |
| 443 |    479.811293 |    698.217333 | Birgit Lang                                                                                                                                                    |
| 444 |    488.876276 |    593.411496 | Steven Traver                                                                                                                                                  |
| 445 |    255.953571 |    145.917505 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 446 |    772.686234 |    392.592712 | Gabriela Palomo-Munoz                                                                                                                                          |
| 447 |    861.171500 |    135.343581 | Ingo Braasch                                                                                                                                                   |
| 448 |    651.068297 |    332.706072 | Emily Willoughby                                                                                                                                               |
| 449 |    602.365451 |    193.499131 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 450 |    571.642249 |     48.653225 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                        |
| 451 |    115.792647 |    146.688128 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                |
| 452 |    394.405163 |    342.251602 | Margot Michaud                                                                                                                                                 |
| 453 |    491.302203 |    479.313193 | Margot Michaud                                                                                                                                                 |
| 454 |    534.829645 |    510.090961 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 455 |    751.102840 |     95.907737 | Margot Michaud                                                                                                                                                 |
| 456 |    899.292016 |    750.973738 | M Kolmann                                                                                                                                                      |
| 457 |    873.776916 |    144.894142 | Ferran Sayol                                                                                                                                                   |
| 458 |    223.928305 |    610.439113 | NA                                                                                                                                                             |
| 459 |    785.938330 |    138.905171 | nicubunu                                                                                                                                                       |
| 460 |    566.827032 |     16.911219 | Andy Wilson                                                                                                                                                    |
| 461 |    265.506017 |    739.586986 | Natalie Claunch                                                                                                                                                |
| 462 |    941.875616 |    326.739802 | Steven Traver                                                                                                                                                  |
| 463 |    469.606758 |    185.256704 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 464 |    361.767496 |    154.609167 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                       |
| 465 |    261.853148 |    419.369336 | Kailah Thorn & Mark Hutchinson                                                                                                                                 |
| 466 |    343.333699 |    268.887195 | Andy Wilson                                                                                                                                                    |
| 467 |    632.413156 |    346.746002 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 468 |    347.516916 |    291.862317 | Maxime Dahirel                                                                                                                                                 |
| 469 |    441.173307 |     25.838824 | Ignacio Contreras                                                                                                                                              |
| 470 |    403.785276 |    603.970539 | Jaime Headden                                                                                                                                                  |
| 471 |    743.284898 |    209.784105 | Margot Michaud                                                                                                                                                 |
| 472 |    427.316645 |    250.333164 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 473 |    876.597799 |    268.193191 | Gareth Monger                                                                                                                                                  |
| 474 |    938.813371 |    787.618634 | Matt Crook                                                                                                                                                     |
| 475 |    742.844823 |    342.285165 | Ferran Sayol                                                                                                                                                   |
| 476 |   1011.387130 |    656.950257 | Steven Traver                                                                                                                                                  |
| 477 |    332.829712 |    343.655226 | Jagged Fang Designs                                                                                                                                            |
| 478 |    230.967155 |     99.015147 | Lafage                                                                                                                                                         |
| 479 |    326.276541 |    221.104935 | DW Bapst (modified from Bates et al., 2005)                                                                                                                    |
| 480 |    199.146238 |    204.689800 | Chris huh                                                                                                                                                      |
| 481 |    202.649039 |    225.963871 | NA                                                                                                                                                             |
| 482 |    317.688566 |    648.501106 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 483 |    290.392876 |    535.467163 | Chris huh                                                                                                                                                      |
| 484 |    187.028404 |    253.110455 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                             |
| 485 |    328.250256 |    783.159060 | Andy Wilson                                                                                                                                                    |
| 486 |    105.242681 |    191.428150 | Gabriela Palomo-Munoz                                                                                                                                          |
| 487 |     79.535708 |    713.956875 | Melissa Broussard                                                                                                                                              |
| 488 |    585.251689 |     97.688813 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
| 489 |    146.684478 |    307.590927 | Christoph Schomburg                                                                                                                                            |
| 490 |    216.971572 |    727.199464 | Markus A. Grohme                                                                                                                                               |
| 491 |    473.433204 |     34.211171 | Jagged Fang Designs                                                                                                                                            |
| 492 |    525.803577 |    147.868135 | Gareth Monger                                                                                                                                                  |
| 493 |     92.768426 |    232.451353 | Jagged Fang Designs                                                                                                                                            |
| 494 |     48.960242 |    780.900569 | Matt Martyniuk                                                                                                                                                 |
| 495 |    328.501801 |     91.602274 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 496 |    373.281668 |    418.002621 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 497 |    914.265729 |    615.441654 | Cristopher Silva                                                                                                                                               |
| 498 |    621.303571 |    174.681238 | Jagged Fang Designs                                                                                                                                            |
| 499 |    990.428273 |    694.240050 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 500 |    830.584542 |    162.886839 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                           |
| 501 |    775.884833 |     18.151187 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                            |
| 502 |     24.995826 |    744.020748 | Margot Michaud                                                                                                                                                 |
| 503 |    538.159939 |     97.949949 | Chris huh                                                                                                                                                      |
| 504 |    120.357677 |    762.394531 | Chris huh                                                                                                                                                      |
| 505 |    238.889522 |    594.659887 | Christian A. Masnaghetti                                                                                                                                       |
| 506 |    789.168013 |    612.635413 | Chuanixn Yu                                                                                                                                                    |
| 507 |    933.814994 |    367.561560 | Cristopher Silva                                                                                                                                               |
| 508 |    198.248765 |    622.720712 | NA                                                                                                                                                             |
| 509 |    191.647153 |    527.353835 | Mette Aumala                                                                                                                                                   |
| 510 |    510.095218 |    102.204602 | Scott Hartman                                                                                                                                                  |
| 511 |    892.596928 |    592.251696 | Natasha Vitek                                                                                                                                                  |
| 512 |    990.563307 |     90.834308 | Andy Wilson                                                                                                                                                    |
| 513 |    874.821718 |    674.692742 | Matt Wilkins                                                                                                                                                   |
| 514 |    625.175603 |    435.911010 | www.studiospectre.com                                                                                                                                          |
| 515 |    542.176371 |    123.755490 | Zimices                                                                                                                                                        |
| 516 |    521.015033 |    270.187741 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                |
| 517 |     65.200202 |    559.893910 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                    |
| 518 |    247.551475 |    727.937643 | Zimices                                                                                                                                                        |
| 519 |    479.034157 |    295.772439 | Ewald Rübsamen                                                                                                                                                 |
| 520 |    203.261916 |     59.778849 | Steven Traver                                                                                                                                                  |
| 521 |    371.468810 |    670.932995 | Margot Michaud                                                                                                                                                 |
| 522 |    782.847273 |    333.569239 | Scott Reid                                                                                                                                                     |
| 523 |    247.695234 |    432.683973 | DW Bapst (modified from Bulman, 1970)                                                                                                                          |
| 524 |    505.411328 |    636.888671 | Armin Reindl                                                                                                                                                   |
| 525 |    928.411488 |     51.286367 | NA                                                                                                                                                             |
| 526 |    320.203813 |    292.743812 | Ferran Sayol                                                                                                                                                   |
| 527 |    457.557840 |    110.358861 | Sarah Werning                                                                                                                                                  |
| 528 |    785.010092 |    306.834868 | Becky Barnes                                                                                                                                                   |
| 529 |    779.152529 |     65.093555 | L. Shyamal                                                                                                                                                     |
| 530 |    336.678292 |    571.989128 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                |
| 531 |    234.312254 |    612.812199 | Margot Michaud                                                                                                                                                 |
| 532 |     18.749975 |     55.313617 | Notafly (vectorized by T. Michael Keesey)                                                                                                                      |
| 533 |    164.536511 |    148.976836 | Tracy A. Heath                                                                                                                                                 |
| 534 |    668.084898 |    565.567310 | Birgit Lang                                                                                                                                                    |
| 535 |    587.243267 |    761.150856 | Tasman Dixon                                                                                                                                                   |
| 536 |    291.822249 |    617.129304 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 537 |    440.033834 |    684.574210 | Joanna Wolfe                                                                                                                                                   |
| 538 |    456.119294 |    797.352604 | Chris huh                                                                                                                                                      |
| 539 |    941.625108 |    774.449062 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                           |
| 540 |    778.409107 |    365.995961 | Jimmy Bernot                                                                                                                                                   |
| 541 |    313.930381 |    768.503456 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                     |
| 542 |    347.317042 |    743.112067 | Julio Garza                                                                                                                                                    |
| 543 |    678.186381 |     61.661235 | terngirl                                                                                                                                                       |
| 544 |    740.804550 |    266.680490 | Felix Vaux                                                                                                                                                     |
| 545 |    791.116402 |      9.624485 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
| 546 |    757.568823 |    462.678388 | Christina N. Hodson                                                                                                                                            |
| 547 |    850.732160 |    671.770083 | FunkMonk                                                                                                                                                       |
| 548 |    221.068534 |    682.999801 | Michelle Site                                                                                                                                                  |
| 549 |    496.405811 |    693.938545 | Francesco “Architetto” Rollandin                                                                                                                               |
| 550 |    633.181631 |    296.213326 | Chris huh                                                                                                                                                      |
| 551 |    645.799140 |    371.130701 | Markus A. Grohme                                                                                                                                               |
| 552 |    437.117053 |    390.521483 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                  |
| 553 |    253.255319 |    253.886475 | Steven Traver                                                                                                                                                  |
| 554 |    142.034508 |    323.848459 | Mario Quevedo                                                                                                                                                  |
| 555 |    395.561770 |    639.086282 | Margot Michaud                                                                                                                                                 |
| 556 |    919.861873 |    768.778467 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 557 |     43.042370 |    568.812689 | Matt Crook                                                                                                                                                     |
| 558 |    138.285826 |    749.383532 | Chris huh                                                                                                                                                      |
| 559 |    620.375399 |     98.717246 | Stanton F. Fink, vectorized by Zimices                                                                                                                         |
| 560 |    687.445981 |     95.561903 | Beth Reinke                                                                                                                                                    |
| 561 |    895.920446 |     78.028705 | Scott Hartman                                                                                                                                                  |
| 562 |    334.992026 |    315.535544 | Margot Michaud                                                                                                                                                 |
| 563 |    936.349798 |    678.964696 | FunkMonk                                                                                                                                                       |
| 564 |    248.300111 |    202.250442 | Matt Crook                                                                                                                                                     |
| 565 |    996.404062 |    581.308186 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                 |
| 566 |   1005.479401 |    251.910054 | Benchill                                                                                                                                                       |
| 567 |    874.316855 |    127.607250 | Margot Michaud                                                                                                                                                 |
| 568 |    955.136585 |    110.983158 | Zimices                                                                                                                                                        |
| 569 |    289.557663 |    384.144930 | Birgit Lang                                                                                                                                                    |
| 570 |    530.625690 |    786.069162 | Sarah Werning                                                                                                                                                  |
| 571 |    498.130668 |    497.132726 | Gabriela Palomo-Munoz                                                                                                                                          |
| 572 |    485.227968 |      5.990350 | Zimices                                                                                                                                                        |
| 573 |    106.163510 |    779.856968 | Gareth Monger                                                                                                                                                  |
| 574 |    170.645347 |    211.997167 | Darren Naish, Nemo, and T. Michael Keesey                                                                                                                      |
| 575 |    319.309522 |    704.977877 | Armin Reindl                                                                                                                                                   |
| 576 |    477.363456 |    270.597779 | Scott Hartman                                                                                                                                                  |
| 577 |    529.898527 |    183.994106 | NA                                                                                                                                                             |
| 578 |    417.683448 |    695.531005 | Ignacio Contreras                                                                                                                                              |
| 579 |    724.604804 |    484.516015 | Steven Traver                                                                                                                                                  |
| 580 |    739.163815 |    529.740770 | Mason McNair                                                                                                                                                   |
| 581 |    619.331500 |    427.359442 | Zimices                                                                                                                                                        |
| 582 |    423.706512 |    118.531977 | T. Michael Keesey (after C. De Muizon)                                                                                                                         |
| 583 |    585.192934 |     58.563440 | John Conway                                                                                                                                                    |
| 584 |    322.250911 |    622.809072 | Jagged Fang Designs                                                                                                                                            |
| 585 |    911.761183 |    269.481867 | Zimices                                                                                                                                                        |
| 586 |     13.780802 |     99.371948 | Chase Brownstein                                                                                                                                               |
| 587 |    817.795182 |     15.460711 | Ewald Rübsamen                                                                                                                                                 |
| 588 |     25.917307 |    199.209001 | Matt Crook                                                                                                                                                     |
| 589 |    335.809135 |    667.384361 | Zimices                                                                                                                                                        |
| 590 |    265.547109 |      9.823847 | Iain Reid                                                                                                                                                      |
| 591 |    104.567034 |    271.961362 | Gabriela Palomo-Munoz                                                                                                                                          |
| 592 |    645.251797 |    630.053052 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 593 |      5.481837 |    632.799509 | Gareth Monger                                                                                                                                                  |
| 594 |    503.899885 |    720.931699 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                    |
| 595 |    542.510774 |     18.036299 | Maha Ghazal                                                                                                                                                    |
| 596 |     61.152673 |     37.072619 | Arthur Grosset (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 597 |     32.103693 |    581.552581 | Markus A. Grohme                                                                                                                                               |
| 598 |    145.635524 |    361.791993 | Maija Karala                                                                                                                                                   |
| 599 |    644.047113 |    322.307187 | Matt Crook                                                                                                                                                     |
| 600 |    336.447947 |    552.644175 | Gabriela Palomo-Munoz                                                                                                                                          |
| 601 |    711.115706 |    341.377115 | Tauana J. Cunha                                                                                                                                                |
| 602 |    263.606725 |    514.831938 | Margot Michaud                                                                                                                                                 |
| 603 |    686.030268 |    227.411305 | Zimices                                                                                                                                                        |
| 604 |    988.854868 |    203.689519 | L. Shyamal                                                                                                                                                     |
| 605 |    639.669381 |    751.724439 | Xavier Giroux-Bougard                                                                                                                                          |
| 606 |     38.948796 |    790.557848 | Steven Traver                                                                                                                                                  |
| 607 |     43.822601 |    350.795752 | nicubunu                                                                                                                                                       |
| 608 |    573.545260 |    689.942704 | Dean Schnabel                                                                                                                                                  |
| 609 |    486.372867 |    417.973079 | T. Michael Keesey                                                                                                                                              |
| 610 |    451.869312 |    614.819577 | Birgit Lang                                                                                                                                                    |
| 611 |    884.538150 |    501.228302 | DW Bapst (modified from Bulman, 1970)                                                                                                                          |
| 612 |    260.716886 |    600.211477 | Tasman Dixon                                                                                                                                                   |
| 613 |    613.059995 |    347.378718 | Tasman Dixon                                                                                                                                                   |
| 614 |     84.110126 |     39.321853 | Matt Crook                                                                                                                                                     |
| 615 |    200.373427 |    791.456442 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                       |
| 616 |    163.635372 |    247.052002 | Steven Traver                                                                                                                                                  |
| 617 |     95.771580 |    141.732421 | Scott Hartman                                                                                                                                                  |
| 618 |    599.058348 |    528.390362 | Beth Reinke                                                                                                                                                    |
| 619 |    495.163265 |    129.490090 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                             |
| 620 |    450.138970 |     15.500493 | Ville Koistinen and T. Michael Keesey                                                                                                                          |
| 621 |    346.596480 |     16.001843 | Smokeybjb                                                                                                                                                      |
| 622 |    361.840509 |    331.405107 | Neil Kelley                                                                                                                                                    |
| 623 |    447.351825 |    774.709467 | Matt Crook                                                                                                                                                     |
| 624 |    251.598454 |    682.102171 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 625 |    628.767701 |    639.341641 | Scott Reid                                                                                                                                                     |
| 626 |      3.698333 |    254.642787 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 627 |    521.811553 |    480.403931 | Jagged Fang Designs                                                                                                                                            |
| 628 |    512.504058 |    354.766154 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 629 |     64.883061 |    113.625341 | Michelle Site                                                                                                                                                  |
| 630 |    141.401983 |    120.774626 | Zimices                                                                                                                                                        |
| 631 |    396.556471 |    238.157854 | Beth Reinke                                                                                                                                                    |
| 632 |    487.194996 |    791.752866 | Alex Slavenko                                                                                                                                                  |
| 633 |    323.667028 |    793.335762 | Chris huh                                                                                                                                                      |
| 634 |    479.356245 |    146.744138 | T. Michael Keesey                                                                                                                                              |
| 635 |    891.582940 |    736.226404 | Rebecca Groom                                                                                                                                                  |
| 636 |   1014.003166 |    211.765466 | Michael Day                                                                                                                                                    |
| 637 |    649.827353 |    447.843089 | Michael Scroggie                                                                                                                                               |
| 638 |    621.818183 |    316.125080 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                  |
| 639 |    164.937696 |    509.016761 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 640 |    375.692056 |    249.304356 | Zimices                                                                                                                                                        |
| 641 |    385.499958 |    682.909216 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                             |
| 642 |    502.743031 |    669.961292 | Steven Traver                                                                                                                                                  |
| 643 |    760.577248 |    600.886234 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 644 |    306.048599 |    439.650742 | Ferran Sayol                                                                                                                                                   |
| 645 |    522.403250 |     53.754874 | Gabriela Palomo-Munoz                                                                                                                                          |
| 646 |    867.979634 |    791.111453 | Margot Michaud                                                                                                                                                 |
| 647 |    970.510968 |    246.504989 | NA                                                                                                                                                             |
| 648 |    901.544368 |      9.873090 | Gabriela Palomo-Munoz                                                                                                                                          |
| 649 |    366.146278 |    509.924773 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                            |
| 650 |    102.644298 |    326.166769 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                 |
| 651 |    618.240988 |    157.293723 | Zimices                                                                                                                                                        |
| 652 |   1011.763746 |    405.691553 | Gareth Monger                                                                                                                                                  |
| 653 |    181.681272 |    131.951821 | Harold N Eyster                                                                                                                                                |
| 654 |    960.505478 |    418.476246 | Roberto Díaz Sibaja                                                                                                                                            |
| 655 |    223.489906 |    196.379482 | CNZdenek                                                                                                                                                       |
| 656 |    975.488911 |     33.927335 | T. Michael Keesey                                                                                                                                              |
| 657 |   1016.233542 |    232.701468 | Agnello Picorelli                                                                                                                                              |
| 658 |    332.800522 |    740.237799 | Melissa Broussard                                                                                                                                              |
| 659 |    282.345119 |    728.486359 | Margot Michaud                                                                                                                                                 |
| 660 |    331.322507 |    157.029504 | Milton Tan                                                                                                                                                     |
| 661 |    246.475959 |    613.550631 | Nina Skinner                                                                                                                                                   |
| 662 |    170.468435 |     73.056659 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
| 663 |    132.483432 |    173.365384 | Gareth Monger                                                                                                                                                  |
| 664 |    813.151123 |    313.681663 | Margot Michaud                                                                                                                                                 |
| 665 |     84.027573 |    208.981204 | Ferran Sayol                                                                                                                                                   |
| 666 |    780.375145 |    742.060900 | Matt Crook                                                                                                                                                     |
| 667 |    656.634586 |    552.545070 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 668 |    490.314250 |    407.806265 | NA                                                                                                                                                             |
| 669 |    712.545211 |    584.989982 | Ferran Sayol                                                                                                                                                   |
| 670 |    153.980376 |    340.211548 | Yan Wong                                                                                                                                                       |
| 671 |    422.782041 |    128.296705 | Matt Crook                                                                                                                                                     |
| 672 |    419.593745 |    711.575721 | Scott Hartman                                                                                                                                                  |
| 673 |    283.131689 |    517.741623 | Gabriela Palomo-Munoz                                                                                                                                          |
| 674 |     44.958456 |     79.097194 | Gareth Monger                                                                                                                                                  |
| 675 |    997.753910 |    793.834282 | Andy Wilson                                                                                                                                                    |
| 676 |     52.829767 |    759.630409 | Nobu Tamura                                                                                                                                                    |
| 677 |    500.047998 |     31.832058 | Andy Wilson                                                                                                                                                    |
| 678 |     40.236385 |     85.915019 | Kai R. Caspar                                                                                                                                                  |
| 679 |   1000.591376 |    128.943211 | Zimices                                                                                                                                                        |
| 680 |    254.713297 |     56.999487 | Ramona J Heim                                                                                                                                                  |
| 681 |    839.347240 |    603.062520 | Ferran Sayol                                                                                                                                                   |
| 682 |    471.950090 |    601.523559 | Joanna Wolfe                                                                                                                                                   |
| 683 |     45.145445 |    700.947254 | Alexandre Vong                                                                                                                                                 |
| 684 |    925.317200 |     38.661265 | Chris huh                                                                                                                                                      |
| 685 |    904.805824 |    360.399187 | NA                                                                                                                                                             |
| 686 |    339.824457 |    527.470963 | Andy Wilson                                                                                                                                                    |
| 687 |    353.874416 |    496.789868 | Ferran Sayol                                                                                                                                                   |
| 688 |    297.581011 |     68.465619 | Gabriela Palomo-Munoz                                                                                                                                          |
| 689 |    721.012651 |    495.234113 | Margot Michaud                                                                                                                                                 |
| 690 |    900.362005 |    600.157938 | Sarah Werning                                                                                                                                                  |
| 691 |    752.412426 |    285.972783 | Elizabeth Parker                                                                                                                                               |
| 692 |    341.528633 |    178.891355 | Steven Traver                                                                                                                                                  |
| 693 |    197.563183 |     11.404456 | Manabu Sakamoto                                                                                                                                                |
| 694 |    234.000306 |    426.320119 | Ignacio Contreras                                                                                                                                              |
| 695 |    561.200023 |    674.125403 | Zimices                                                                                                                                                        |
| 696 |    219.381984 |    338.911971 | Noah Schlottman                                                                                                                                                |
| 697 |    765.206116 |    186.056102 | Chris huh                                                                                                                                                      |
| 698 |    430.555427 |    448.859395 | Ignacio Contreras                                                                                                                                              |
| 699 |    594.789734 |    171.976703 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 700 |   1009.878713 |    270.954080 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 701 |    280.337218 |    620.222245 | Margot Michaud                                                                                                                                                 |
| 702 |    864.289853 |    628.974489 | Birgit Lang                                                                                                                                                    |
| 703 |    496.727314 |    552.444917 | Ignacio Contreras                                                                                                                                              |
| 704 |    743.552329 |     60.736528 | Steven Traver                                                                                                                                                  |
| 705 |    761.933521 |    747.490021 | Davidson Sodré                                                                                                                                                 |
| 706 |    744.986255 |    197.397099 | Scott Hartman                                                                                                                                                  |
| 707 |    989.112578 |    109.580026 | Martin R. Smith                                                                                                                                                |
| 708 |     29.411321 |    557.278936 | Tony Ayling (vectorized by Milton Tan)                                                                                                                         |
| 709 |    437.679893 |    256.909726 | Zimices                                                                                                                                                        |
| 710 |    512.745069 |    288.388117 | Harold N Eyster                                                                                                                                                |
| 711 |    994.063683 |     16.091096 | Zimices                                                                                                                                                        |
| 712 |    698.064458 |      8.109674 | Dave Angelini                                                                                                                                                  |
| 713 |    189.927725 |    744.786236 | Chris huh                                                                                                                                                      |
| 714 |    463.674612 |    458.561133 | Gabriela Palomo-Munoz                                                                                                                                          |
| 715 |    872.851692 |    516.090789 | Ferran Sayol                                                                                                                                                   |
| 716 |    105.237267 |    549.062438 | Mette Aumala                                                                                                                                                   |
| 717 |    480.052031 |    313.025062 | Chris huh                                                                                                                                                      |
| 718 |    939.177430 |    203.571012 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
| 719 |    844.757415 |    651.161264 | Margot Michaud                                                                                                                                                 |
| 720 |    328.178043 |    674.238599 | Markus A. Grohme                                                                                                                                               |
| 721 |     99.663281 |    792.744033 | Tracy A. Heath                                                                                                                                                 |
| 722 |    965.805935 |    570.422029 | Yusan Yang                                                                                                                                                     |
| 723 |    416.343480 |    680.341315 | NA                                                                                                                                                             |
| 724 |    115.370214 |    409.806264 | NA                                                                                                                                                             |
| 725 |    580.119132 |    172.866399 | Raven Amos                                                                                                                                                     |
| 726 |    892.148789 |    462.588518 | Tauana J. Cunha                                                                                                                                                |
| 727 |    443.153384 |    694.793269 | Margot Michaud                                                                                                                                                 |
| 728 |    222.875843 |    789.686364 | Andy Wilson                                                                                                                                                    |
| 729 |    438.527345 |    281.123099 | Gabriela Palomo-Munoz                                                                                                                                          |
| 730 |    652.950292 |      3.228787 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                   |
| 731 |    769.919207 |    146.426320 | Margot Michaud                                                                                                                                                 |
| 732 |      9.005152 |    729.067327 | Chris Hay                                                                                                                                                      |
| 733 |    502.062753 |    699.036173 | Ingo Braasch                                                                                                                                                   |
| 734 |    544.042257 |      4.645381 | Jiekun He                                                                                                                                                      |
| 735 |    203.547519 |     30.266703 | Margot Michaud                                                                                                                                                 |
| 736 |    304.943212 |    691.096914 | Hans Hillewaert                                                                                                                                                |
| 737 |    274.068671 |    598.107849 | Gabriela Palomo-Munoz                                                                                                                                          |
| 738 |     76.009847 |     47.794555 | Ingo Braasch                                                                                                                                                   |
| 739 |    309.605520 |    459.688359 | Collin Gross                                                                                                                                                   |
| 740 |    192.214190 |    349.259763 | Maxime Dahirel                                                                                                                                                 |
| 741 |     82.548638 |    429.235017 | Catherine Yasuda                                                                                                                                               |
| 742 |    781.285622 |     77.622880 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                  |
| 743 |    144.312194 |    642.431046 | Matt Crook                                                                                                                                                     |
| 744 |    712.535138 |    160.511999 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                         |
| 745 |    335.942511 |      7.255407 | Kanako Bessho-Uehara                                                                                                                                           |
| 746 |    370.911427 |    408.666400 | Gareth Monger                                                                                                                                                  |
| 747 |    652.920132 |     10.760896 | Zimices                                                                                                                                                        |
| 748 |    798.913463 |    225.317274 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 749 |    261.985472 |    172.646990 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                  |
| 750 |    730.911464 |    624.125666 | Zimices                                                                                                                                                        |
| 751 |    460.309463 |    694.410733 | Margot Michaud                                                                                                                                                 |
| 752 |    625.959748 |    105.551267 | Margot Michaud                                                                                                                                                 |
| 753 |     80.570515 |    635.842580 | Matt Crook                                                                                                                                                     |
| 754 |    114.409858 |    420.899117 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 755 |    511.336418 |    465.435013 | Matt Crook                                                                                                                                                     |
| 756 |    539.835869 |    108.652312 | Myriam\_Ramirez                                                                                                                                                |
| 757 |    256.517237 |     24.775232 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                       |
| 758 |    154.105942 |     70.479555 | T. Michael Keesey                                                                                                                                              |
| 759 |    911.440048 |    558.769051 | Gareth Monger                                                                                                                                                  |
| 760 |    314.218563 |    243.643098 | Jagged Fang Designs                                                                                                                                            |
| 761 |    323.766583 |    760.256055 | Lukasiniho                                                                                                                                                     |
| 762 |    495.195770 |    521.119659 | Gareth Monger                                                                                                                                                  |
| 763 |    880.088740 |    319.681898 | Zimices                                                                                                                                                        |
| 764 |     43.203477 |    713.976937 | Jagged Fang Designs                                                                                                                                            |
| 765 |   1006.056507 |     85.471726 | Maija Karala                                                                                                                                                   |
| 766 |     14.089536 |    139.691971 | Matt Crook                                                                                                                                                     |
| 767 |    767.196665 |    174.537514 | Maija Karala                                                                                                                                                   |
| 768 |    477.155938 |    515.931306 | Gabriela Palomo-Munoz                                                                                                                                          |
| 769 |    848.061634 |    323.187448 | NA                                                                                                                                                             |
| 770 |    346.293374 |    508.851268 | Zimices                                                                                                                                                        |
| 771 |    352.722525 |    595.673126 | Rebecca Groom                                                                                                                                                  |
| 772 |    976.617129 |    221.007312 | Matt Crook                                                                                                                                                     |
| 773 |     74.714778 |    436.195947 | T. Michael Keesey                                                                                                                                              |
| 774 |    632.561393 |    785.255697 | Sharon Wegner-Larsen                                                                                                                                           |
| 775 |    641.846259 |     89.273864 | Zimices                                                                                                                                                        |
| 776 |    826.712931 |    788.748440 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 777 |     24.225681 |    442.956397 | Zimices                                                                                                                                                        |
| 778 |    327.303274 |    323.192918 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                             |
| 779 |    299.677438 |    774.111845 | Carlos Cano-Barbacil                                                                                                                                           |
| 780 |     11.644119 |    212.669293 | Gareth Monger                                                                                                                                                  |
| 781 |    315.073216 |    467.110064 | Yan Wong                                                                                                                                                       |
| 782 |    443.146374 |    331.488302 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                   |
| 783 |    524.444283 |    601.839277 | Lukasiniho                                                                                                                                                     |
| 784 |    734.407979 |     14.004989 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 785 |    658.339283 |    351.522733 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 786 |     61.850226 |    143.245571 | Ludwik Gąsiorowski                                                                                                                                             |
| 787 |    299.946615 |    528.431797 | Chris huh                                                                                                                                                      |
| 788 |    197.325713 |    689.716327 | Carlos Cano-Barbacil                                                                                                                                           |
| 789 |    572.463072 |    634.029234 | Yan Wong                                                                                                                                                       |
| 790 |    989.135223 |     56.103286 | Tasman Dixon                                                                                                                                                   |
| 791 |    376.975481 |    661.709548 | Ferran Sayol                                                                                                                                                   |
| 792 |    117.391144 |    713.472495 | Kai R. Caspar                                                                                                                                                  |
| 793 |    667.554045 |    133.834383 | Emily Willoughby                                                                                                                                               |
| 794 |    438.432387 |    119.901583 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                  |
| 795 |    361.726988 |    140.925710 | Sharon Wegner-Larsen                                                                                                                                           |
| 796 |    522.196553 |     33.265804 | Andy Wilson                                                                                                                                                    |
| 797 |    255.836132 |    336.007363 | Markus A. Grohme                                                                                                                                               |
| 798 |    422.074087 |    236.718558 | Steven Coombs                                                                                                                                                  |
| 799 |    160.517955 |    128.805090 | Gabriela Palomo-Munoz                                                                                                                                          |
| 800 |    472.963690 |    395.852358 | Nobu Tamura and T. Michael Keesey                                                                                                                              |
| 801 |    390.048691 |    216.426916 | John Gould (vectorized by T. Michael Keesey)                                                                                                                   |
| 802 |    761.958277 |    651.372594 | NA                                                                                                                                                             |
| 803 |    392.142471 |    685.528256 | Melissa Broussard                                                                                                                                              |
| 804 |    617.966830 |    521.955817 | White Wolf                                                                                                                                                     |
| 805 |    548.034368 |    374.394119 | Margot Michaud                                                                                                                                                 |
| 806 |    362.278888 |    734.677619 | Mason McNair                                                                                                                                                   |
| 807 |   1012.047553 |    726.531343 | Tasman Dixon                                                                                                                                                   |
| 808 |    865.078191 |     71.954424 | Markus A. Grohme                                                                                                                                               |
| 809 |    524.646808 |    200.889676 | Gabriela Palomo-Munoz                                                                                                                                          |
| 810 |   1009.107134 |    482.228359 | Matt Crook                                                                                                                                                     |
| 811 |    690.675887 |    342.119403 | NA                                                                                                                                                             |
| 812 |   1001.968177 |    599.127896 | Margot Michaud                                                                                                                                                 |
| 813 |    364.897820 |    284.759104 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 814 |    470.778148 |    496.710814 | Mo Hassan                                                                                                                                                      |
| 815 |    711.770256 |    520.120540 | Matt Crook                                                                                                                                                     |
| 816 |    664.835228 |    667.506183 |                                                                                                                                                                |
| 817 |    177.043405 |    525.981776 | Becky Barnes                                                                                                                                                   |
| 818 |    607.453590 |    564.297558 | Jessica Anne Miller                                                                                                                                            |
| 819 |    596.607740 |    549.218523 | Jiekun He                                                                                                                                                      |
| 820 |    136.277589 |     65.916909 | Steven Traver                                                                                                                                                  |
| 821 |    146.531328 |    528.365593 | Tony Ayling                                                                                                                                                    |
| 822 |    639.456656 |    175.839473 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                |
| 823 |    872.086724 |    744.680454 | NA                                                                                                                                                             |
| 824 |    715.730901 |     50.220458 | Jagged Fang Designs                                                                                                                                            |
| 825 |   1001.457151 |    228.790276 | Jack Mayer Wood                                                                                                                                                |
| 826 |     21.446520 |    225.202591 | Adrian Reich                                                                                                                                                   |
| 827 |    517.995046 |    415.013007 | Matt Crook                                                                                                                                                     |
| 828 |    894.156541 |    447.990383 | Michelle Site                                                                                                                                                  |
| 829 |    174.147633 |    649.791682 | Smokeybjb                                                                                                                                                      |
| 830 |    286.865840 |    166.588005 | Margot Michaud                                                                                                                                                 |
| 831 |    972.097325 |     14.916939 | Margot Michaud                                                                                                                                                 |
| 832 |    866.935438 |    601.093336 | Steven Traver                                                                                                                                                  |
| 833 |    917.721825 |    294.187163 | Ferran Sayol                                                                                                                                                   |
| 834 |    791.244801 |     90.683390 | Matt Crook                                                                                                                                                     |
| 835 |    919.572060 |    588.877583 | Maxime Dahirel                                                                                                                                                 |
| 836 |     98.806316 |    220.177531 | Harold N Eyster                                                                                                                                                |
| 837 |    307.435769 |    708.681462 | Gareth Monger                                                                                                                                                  |
| 838 |    427.988435 |    741.554478 | Tasman Dixon                                                                                                                                                   |
| 839 |    712.446562 |    328.841701 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 840 |    151.584541 |    536.355341 | Jon Hill                                                                                                                                                       |
| 841 |    993.339723 |    788.371033 | Matt Crook                                                                                                                                                     |
| 842 |     92.976421 |    721.454707 | Gareth Monger                                                                                                                                                  |
| 843 |    807.806987 |      8.268948 | Melissa Broussard                                                                                                                                              |
| 844 |   1014.142748 |     35.116775 | FunkMonk                                                                                                                                                       |
| 845 |    302.947149 |    753.488509 | Zimices                                                                                                                                                        |
| 846 |    932.213361 |    270.121688 | Margot Michaud                                                                                                                                                 |
| 847 |    647.989586 |    154.389546 | Steven Traver                                                                                                                                                  |
| 848 |    621.302311 |    292.931796 | Kamil S. Jaron                                                                                                                                                 |
| 849 |    826.488447 |    479.244774 | Birgit Lang                                                                                                                                                    |
| 850 |    892.131394 |    288.343471 | Gareth Monger                                                                                                                                                  |
| 851 |    960.825163 |    594.688121 | Mo Hassan                                                                                                                                                      |
| 852 |    359.842271 |    536.838746 | Steven Traver                                                                                                                                                  |
| 853 |    400.512336 |    247.514567 | Juan Carlos Jerí                                                                                                                                               |
| 854 |    228.979131 |    673.130069 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                      |
| 855 |    326.545763 |    508.338067 | Lauren Anderson                                                                                                                                                |
| 856 |    739.456572 |    675.807994 | Scott Hartman                                                                                                                                                  |
| 857 |    736.170991 |     71.995249 | Matt Crook                                                                                                                                                     |
| 858 |    705.135699 |     72.607219 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                |
| 859 |     46.856102 |     44.742446 | Dean Schnabel                                                                                                                                                  |
| 860 |    657.133327 |    675.278856 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                       |
| 861 |    677.034789 |    165.602146 | Joschua Knüppe                                                                                                                                                 |
| 862 |    523.078688 |    718.546548 | Gabriela Palomo-Munoz                                                                                                                                          |
| 863 |    863.655566 |    549.385150 | Matt Crook                                                                                                                                                     |
| 864 |    824.549239 |    387.557300 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                    |
| 865 |    375.469812 |    230.271835 | Steven Traver                                                                                                                                                  |
| 866 |    917.758981 |    118.671139 | Markus A. Grohme                                                                                                                                               |
| 867 |    716.751263 |     84.908900 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 868 |    658.996805 |    791.520456 | Tasman Dixon                                                                                                                                                   |
| 869 |    854.349742 |    254.422897 | Steven Traver                                                                                                                                                  |
| 870 |    738.330704 |     41.184069 | T. Michael Keesey                                                                                                                                              |
| 871 |    732.106919 |    742.166281 | Ferran Sayol                                                                                                                                                   |
| 872 |     14.356767 |    580.493953 | Chase Brownstein                                                                                                                                               |
| 873 |    257.661734 |    330.628048 | Carlos Cano-Barbacil                                                                                                                                           |
| 874 |    815.272809 |    589.450431 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                             |
| 875 |     12.933609 |    313.135821 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                |
| 876 |    867.519000 |    587.809724 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 877 |    272.101136 |     58.441489 | Gareth Monger                                                                                                                                                  |
| 878 |    467.442215 |    318.095049 | Andy Wilson                                                                                                                                                    |
| 879 |    671.264891 |    507.638893 | Cristopher Silva                                                                                                                                               |
| 880 |    132.836814 |     11.807433 | Margot Michaud                                                                                                                                                 |
| 881 |    242.042194 |    628.868893 | NA                                                                                                                                                             |
| 882 |    703.293935 |    463.866369 | SecretJellyMan                                                                                                                                                 |
| 883 |    491.523155 |    286.885142 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 884 |     94.817746 |    660.714658 | www.studiospectre.com                                                                                                                                          |
| 885 |    518.115962 |    797.349166 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                         |
| 886 |    616.818802 |    764.144012 | T. Michael Keesey                                                                                                                                              |
| 887 |    875.953047 |    630.234132 | Gareth Monger                                                                                                                                                  |
| 888 |    639.419243 |    215.925492 | Steven Traver                                                                                                                                                  |
| 889 |    331.325018 |    698.959322 | NA                                                                                                                                                             |
| 890 |    262.906108 |    312.748040 | NA                                                                                                                                                             |
| 891 |    800.721067 |    529.152293 | Abraão B. Leite                                                                                                                                                |
| 892 |    133.463821 |    756.154940 | Maija Karala                                                                                                                                                   |
| 893 |    766.600430 |    354.903868 | NA                                                                                                                                                             |
| 894 |    241.732483 |    669.350548 | Matt Crook                                                                                                                                                     |
| 895 |    131.130071 |     92.996353 | Andreas Hejnol                                                                                                                                                 |
| 896 |     39.652142 |    376.286574 | Margot Michaud                                                                                                                                                 |
| 897 |    687.359746 |    579.544369 | Gabriela Palomo-Munoz                                                                                                                                          |
| 898 |    544.190303 |     50.496444 | Matt Crook                                                                                                                                                     |
| 899 |    240.722225 |     40.935583 | Gareth Monger                                                                                                                                                  |
| 900 |    141.164317 |    249.480316 | Markus A. Grohme                                                                                                                                               |
| 901 |    229.024425 |    438.818849 | Dinah Challen                                                                                                                                                  |
| 902 |     97.761331 |    180.665712 | Scott Hartman                                                                                                                                                  |
| 903 |     36.512452 |    145.282896 | Diana Pomeroy                                                                                                                                                  |
| 904 |    227.097755 |    187.072477 | Ferran Sayol                                                                                                                                                   |
| 905 |   1020.439328 |    449.980778 | T. Michael Keesey                                                                                                                                              |
| 906 |     80.649507 |    675.579562 | Zimices                                                                                                                                                        |
| 907 |     99.436658 |    202.575668 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 908 |    924.507205 |    353.336950 | Tasman Dixon                                                                                                                                                   |
| 909 |    630.182792 |     71.367869 | Julien Louys                                                                                                                                                   |
| 910 |    904.500376 |    526.201652 | Steven Traver                                                                                                                                                  |
| 911 |    142.361713 |    108.576844 | Ferran Sayol                                                                                                                                                   |
| 912 |    269.197180 |    386.524074 | Gareth Monger                                                                                                                                                  |
| 913 |    946.748635 |    699.267290 | Noah Schlottman, photo by Carol Cummings                                                                                                                       |
| 914 |    480.888764 |    119.522740 | Zimices                                                                                                                                                        |
| 915 |    807.912160 |    730.851947 | Margot Michaud                                                                                                                                                 |
| 916 |    356.038465 |    312.221796 | NA                                                                                                                                                             |
| 917 |    146.692555 |    140.119458 | FJDegrange                                                                                                                                                     |
| 918 |    178.409997 |    550.421452 | Gareth Monger                                                                                                                                                  |

    #> Your tweet has been posted!
