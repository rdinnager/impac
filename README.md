
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

Zimices, Chris huh, Jagged Fang Designs, Josefine Bohr Brask, Matt
Crook, Steven Traver, Smokeybjb, vectorized by Zimices, Margot Michaud,
Nobu Tamura (vectorized by T. Michael Keesey), Richard Parker
(vectorized by T. Michael Keesey), Jose Carlos Arenas-Monroy, RS,
Gabriela Palomo-Munoz, T. Michael Keesey, Lafage, Collin Gross, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Chris A. Hamilton, Armin
Reindl, Juan Carlos Jerí, Manabu Sakamoto, Ville-Veikko Sinkkonen,
Mathilde Cordellier, Jonathan Wells, Benjamin Monod-Broca, Kai R.
Caspar, T. Michael Keesey (after A. Y. Ivantsov), AnAgnosticGod
(vectorized by T. Michael Keesey), Andrew A. Farke, Michael Day, Neil
Kelley, Joanna Wolfe, Verdilak, Chris Jennings (vectorized by A.
Verrière), Stemonitis (photography) and T. Michael Keesey
(vectorization), FunkMonk, John Conway, Scott Hartman, Birgit Lang, B
Kimmel, Steven Blackwood, Gareth Monger, Steven Coombs, Ellen Edmonson
and Hugh Chrisp (vectorized by T. Michael Keesey), Scarlet23 (vectorized
by T. Michael Keesey), Michelle Site, xgirouxb, Ghedoghedo, Matt
Dempsey, Roberto Díaz Sibaja, Young and Zhao (1972:figure 4), modified
by Michael P. Taylor, Iain Reid, Berivan Temiz, Sarah Werning, Ferran
Sayol, Renata F. Martins, Christoph Schomburg, Dean Schnabel, Yan Wong
from drawing in The Century Dictionary (1911), T. Michael Keesey (after
MPF), Markus A. Grohme, Tyler Greenfield, Tasman Dixon, Melissa
Broussard, Ignacio Contreras, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Shyamal, CNZdenek,
Matus Valach, Harold N Eyster, FJDegrange, Michele M Tobias from an
image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Jaime
Headden, Kanchi Nanjo, FunkMonk (Michael B. H.), Mali’o Kodis,
photograph by P. Funch and R.M. Kristensen, Patrick Strutzenberger,
Óscar San-Isidro (vectorized by T. Michael Keesey), White Wolf, Zachary
Quigley, Meliponicultor Itaymbere, Smokeybjb (vectorized by T. Michael
Keesey), Sergio A. Muñoz-Gómez, Yan Wong, Didier Descouens (vectorized
by T. Michael Keesey), Ingo Braasch, Pete Buchholz, Fcb981 (vectorized
by T. Michael Keesey), DW Bapst (Modified from Bulman, 1964), Gopal
Murali, Sean McCann, Kailah Thorn & Mark Hutchinson, Milton Tan, Ieuan
Jones, C. Camilo Julián-Caballero, Sam Droege (photography) and T.
Michael Keesey (vectorization), Julio Garza, S.Martini, Emily
Willoughby, Julien Louys, Mathieu Basille, Caleb Brown, M. Antonio
Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized
by T. Michael Keesey), Robert Gay, modified from FunkMonk (Michael B.H.)
and T. Michael Keesey., Chase Brownstein, Yusan Yang, Lily Hughes,
Richard J. Harris, Mareike C. Janiak, Andrew A. Farke, shell lines added
by Yan Wong, Smokeybjb, Chuanixn Yu, Andreas Preuss / marauder, E. D.
Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J.
Wedel), Brad McFeeters (vectorized by T. Michael Keesey), Campbell
Fleming, Matt Celeskey, Ernst Haeckel (vectorized by T. Michael Keesey),
Aviceda (vectorized by T. Michael Keesey), Caleb M. Brown, Felix Vaux,
Benjamint444, Manabu Bessho-Uehara, Natalie Claunch, Pranav Iyer (grey
ideas), Dmitry Bogdanov, Oscar Sanisidro, Matt Wilkins, Rebecca Groom,
Kamil S. Jaron, Jon Hill, Mathew Wedel, NOAA Great Lakes Environmental
Research Laboratory (illustration) and Timothy J. Bartley (silhouette),
Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T.
Michael Keesey (vectorization), Christine Axon, Diana Pomeroy, Lankester
Edwin Ray (vectorized by T. Michael Keesey), Stuart Humphries, David
Tana, Terpsichores, Jan A. Venter, Herbert H. T. Prins, David A. Balfour
& Rob Slotow (vectorized by T. Michael Keesey), Thea Boodhoo
(photograph) and T. Michael Keesey (vectorization), Maxwell Lefroy
(vectorized by T. Michael Keesey), Tracy A. Heath, Michael Scroggie,
Stacy Spensley (Modified), Rebecca Groom (Based on Photo by Andreas
Trepte), Mali’o Kodis, photograph from Jersabek et al, 2003, Andrew R.
Gehrke, Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, T. Michael Keesey (photo by Darren Swim), Katie S.
Collins, Alexandre Vong, Conty (vectorized by T. Michael Keesey), Mali’o
Kodis, image from the Smithsonian Institution, Francesco Veronesi
(vectorized by T. Michael Keesey), Becky Barnes, Andrés Sánchez,
Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja,
Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong), Andrew A.
Farke, modified from original by Robert Bruce Horsfall, from Scott 1912,
Matt Martyniuk, Chris Jennings (Risiatto), Noah Schlottman, photo by
Casey Dunn, Maija Karala, Noah Schlottman, photo from Casey Dunn, Todd
Marshall, vectorized by Zimices, T. Michael Keesey (vectorization) and
HuttyMcphoo (photography), Unknown (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Cristian Osorio & Paula Carrera,
Proyecto Carnivoros Australes (www.carnivorosaustrales.org), Jake
Warner, Christopher Chávez, Nobu Tamura, Ville Koistinen and T. Michael
Keesey, Tony Ayling, Mathieu Pélissié, Qiang Ou, Auckland Museum and T.
Michael Keesey, L. Shyamal, Alex Slavenko, T. Tischler, Nobu Tamura,
vectorized by Zimices, T. Michael Keesey and Tanetahi, Cesar Julian,
\[unknown\], Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on
iNaturalist, Jebulon (vectorized by T. Michael Keesey), T. Michael
Keesey (photo by Bc999 \[Black crow\]), Mali’o Kodis, photograph by
“Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>), T.
Michael Keesey (after Colin M. L. Burnett), Hugo Gruson, Alexander
Schmidt-Lebuhn, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), T. Michael Keesey (vectorization) and Nadiatalent
(photography), Maha Ghazal, Mario Quevedo, Anna Willoughby, Skye
McDavid, James R. Spotila and Ray Chatterji, Charles Doolittle Walcott
(vectorized by T. Michael Keesey), Leon P. A. M. Claessens, Patrick M.
O’Connor, David M. Unwin, Dr. Thomas G. Barnes, USFWS, Mihai Dragos
(vectorized by T. Michael Keesey), Joris van der Ham (vectorized by T.
Michael Keesey), Griensteidl and T. Michael Keesey, Courtney Rockenbach,
Siobhon Egan, Beth Reinke, Pearson Scott Foresman (vectorized by T.
Michael Keesey), H. F. O. March (vectorized by T. Michael Keesey), T.
Michael Keesey (after James & al.), Yan Wong from drawing by Joseph
Smit, Tony Ayling (vectorized by Milton Tan), Maxime Dahirel, B. Duygu
Özpolat, Sharon Wegner-Larsen, Dexter R. Mardis, SauropodomorphMonarch,
Martin Kevil, Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis
M. Chiappe, Davidson Sodré, Mo Hassan, John Curtis (vectorized by T.
Michael Keesey), Ghedoghedo (vectorized by T. Michael Keesey), Scott
Reid, Noah Schlottman, photo by Martin V. Sørensen, Vijay Cavale
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, . Original drawing by M. Antón, published in Montoya and Morales
1984. Vectorized by O. Sanisidro, Xavier Giroux-Bougard, Scott Hartman
(modified by T. Michael Keesey), Noah Schlottman, M Kolmann, Mykle
Hoban, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Matthew Hooge (vectorized by T.
Michael Keesey), Joseph Smit (modified by T. Michael Keesey), Oren Peles
/ vectorized by Yan Wong, Hans Hillewaert (vectorized by T. Michael
Keesey), Emily Jane McTavish, Michael P. Taylor, Ron Holmes/U. S. Fish
and Wildlife Service (source photo), T. Michael Keesey (vectorization),
Christina N. Hodson, Felix Vaux and Steven A. Trewick, Carlos
Cano-Barbacil, Metalhead64 (vectorized by T. Michael Keesey), Elizabeth
Parker, terngirl, David Orr, Haplochromis (vectorized by T. Michael
Keesey), Tomas Willems (vectorized by T. Michael Keesey), Birgit Lang;
original image by virmisco.org, (after Spotila 2004), Remes K, Ortega F,
Fierro I, Joger U, Kosma R, et al., T. Michael Keesey (photo by Sean
Mack), Noah Schlottman, photo by Museum of Geology, University of Tartu,
Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Original drawing by Dmitry Bogdanov, vectorized by
Roberto Díaz Sibaja, Michele M Tobias, Kimberly Haddrell, Peter Coxhead,
DW Bapst (Modified from photograph taken by Charles Mitchell), nicubunu,
Martien Brand (original photo), Renato Santos (vector silhouette),
Kenneth Lacovara (vectorized by T. Michael Keesey), Jay Matternes,
vectorized by Zimices, Tony Ayling (vectorized by T. Michael Keesey),
Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, ArtFavor & annaleeblysse, Jessica Anne Miller, Chloé
Schmidt, George Edward Lodge (vectorized by T. Michael Keesey), Inessa
Voet, E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by
T. Michael Keesey), Jack Mayer Wood, Emma Hughes, Mali’o Kodis, image by
Rebecca Ritger, Konsta Happonen, Obsidian Soul (vectorized by T. Michael
Keesey), Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Mary Harrsch (modified by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    552.358255 |    700.895888 | Zimices                                                                                                                                                               |
|   2 |    203.268562 |     26.844640 | Chris huh                                                                                                                                                             |
|   3 |    162.878668 |    429.043347 | Jagged Fang Designs                                                                                                                                                   |
|   4 |    947.679627 |    244.188252 | Josefine Bohr Brask                                                                                                                                                   |
|   5 |    197.189000 |    103.362125 | Matt Crook                                                                                                                                                            |
|   6 |    728.007176 |    580.941527 | Steven Traver                                                                                                                                                         |
|   7 |    413.806439 |    584.075934 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
|   8 |    350.945232 |    287.167392 | Margot Michaud                                                                                                                                                        |
|   9 |    929.255655 |    402.089626 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  10 |    112.973210 |    192.269621 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                      |
|  11 |    300.724562 |    147.717343 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  12 |    275.961598 |    635.050220 | RS                                                                                                                                                                    |
|  13 |    366.339087 |    429.186089 | NA                                                                                                                                                                    |
|  14 |    757.328309 |    179.805660 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  15 |    209.378879 |    727.721667 | T. Michael Keesey                                                                                                                                                     |
|  16 |    382.110307 |    716.669073 | Steven Traver                                                                                                                                                         |
|  17 |    731.912253 |    428.649167 | Lafage                                                                                                                                                                |
|  18 |    764.293507 |    710.205130 | Collin Gross                                                                                                                                                          |
|  19 |    456.017335 |     52.822578 | Zimices                                                                                                                                                               |
|  20 |    799.785123 |     62.946685 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  21 |    704.874502 |    298.780717 | Chris A. Hamilton                                                                                                                                                     |
|  22 |    840.600643 |    527.559087 | Steven Traver                                                                                                                                                         |
|  23 |    577.700069 |    352.060599 | Margot Michaud                                                                                                                                                        |
|  24 |    271.693419 |    585.369419 | Armin Reindl                                                                                                                                                          |
|  25 |    215.147385 |    318.367928 | Juan Carlos Jerí                                                                                                                                                      |
|  26 |    456.920367 |    652.679325 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  27 |    520.863989 |    235.220088 | Manabu Sakamoto                                                                                                                                                       |
|  28 |    572.716095 |    550.178877 | Ville-Veikko Sinkkonen                                                                                                                                                |
|  29 |     48.841394 |     64.302568 | Mathilde Cordellier                                                                                                                                                   |
|  30 |    172.694994 |    523.311289 | Jonathan Wells                                                                                                                                                        |
|  31 |    456.714802 |    383.773832 | Benjamin Monod-Broca                                                                                                                                                  |
|  32 |    957.950976 |    104.691234 | Kai R. Caspar                                                                                                                                                         |
|  33 |    608.631508 |    105.355732 | Matt Crook                                                                                                                                                            |
|  34 |    857.623297 |    273.325004 | T. Michael Keesey                                                                                                                                                     |
|  35 |    817.291269 |    101.727889 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
|  36 |    918.664608 |    681.826421 | Chris huh                                                                                                                                                             |
|  37 |    114.476922 |    647.138380 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
|  38 |    425.369207 |    269.346637 | Andrew A. Farke                                                                                                                                                       |
|  39 |    485.750075 |    492.604618 | Michael Day                                                                                                                                                           |
|  40 |    853.037830 |    422.009872 | Neil Kelley                                                                                                                                                           |
|  41 |    963.518958 |    599.390789 | Joanna Wolfe                                                                                                                                                          |
|  42 |    294.988683 |    439.068281 | NA                                                                                                                                                                    |
|  43 |    930.930647 |    730.431854 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  44 |     39.534411 |    362.531040 | T. Michael Keesey                                                                                                                                                     |
|  45 |     54.264311 |    527.005179 | Verdilak                                                                                                                                                              |
|  46 |    642.800460 |    166.408648 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
|  47 |    390.977672 |    529.510731 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
|  48 |    442.872214 |    133.586380 | Matt Crook                                                                                                                                                            |
|  49 |     91.594847 |    276.130227 | FunkMonk                                                                                                                                                              |
|  50 |    951.189102 |    184.204870 | John Conway                                                                                                                                                           |
|  51 |     98.262718 |    731.941345 | Scott Hartman                                                                                                                                                         |
|  52 |    947.280208 |    341.235620 | Birgit Lang                                                                                                                                                           |
|  53 |    687.803656 |    497.711190 | B Kimmel                                                                                                                                                              |
|  54 |    299.179562 |    236.466663 | Steven Blackwood                                                                                                                                                      |
|  55 |   1008.516309 |    102.373371 | Gareth Monger                                                                                                                                                         |
|  56 |    666.046039 |    228.928251 | Steven Coombs                                                                                                                                                         |
|  57 |    821.559519 |    343.643789 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
|  58 |    117.286188 |     87.202028 | Gareth Monger                                                                                                                                                         |
|  59 |    903.356412 |    766.498840 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
|  60 |    471.825220 |    171.810968 | Michelle Site                                                                                                                                                         |
|  61 |    962.182192 |     26.027887 | xgirouxb                                                                                                                                                              |
|  62 |    576.956867 |    771.261064 | Ghedoghedo                                                                                                                                                            |
|  63 |    740.150712 |    369.537718 | Scott Hartman                                                                                                                                                         |
|  64 |    300.299655 |    535.297708 | Matt Dempsey                                                                                                                                                          |
|  65 |    159.923077 |    348.230955 | Roberto Díaz Sibaja                                                                                                                                                   |
|  66 |    550.226004 |    420.159111 | Birgit Lang                                                                                                                                                           |
|  67 |    198.693812 |    214.118461 | Zimices                                                                                                                                                               |
|  68 |    633.900032 |    787.929710 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
|  69 |    603.633875 |     39.345719 | Iain Reid                                                                                                                                                             |
|  70 |    408.872564 |    357.739961 | Jagged Fang Designs                                                                                                                                                   |
|  71 |    690.168627 |     25.435009 | Jagged Fang Designs                                                                                                                                                   |
|  72 |    854.285251 |    633.107955 | Berivan Temiz                                                                                                                                                         |
|  73 |    452.592996 |    534.141525 | Sarah Werning                                                                                                                                                         |
|  74 |   1005.338901 |    303.326706 | Ferran Sayol                                                                                                                                                          |
|  75 |    430.728576 |    446.665787 | Renata F. Martins                                                                                                                                                     |
|  76 |    143.326274 |    775.243998 | Collin Gross                                                                                                                                                          |
|  77 |     71.469885 |    582.555882 | Zimices                                                                                                                                                               |
|  78 |   1004.403513 |    513.959273 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  79 |    401.114528 |    111.310749 | Christoph Schomburg                                                                                                                                                   |
|  80 |    391.935625 |    665.113294 | Dean Schnabel                                                                                                                                                         |
|  81 |    208.865837 |    399.118688 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
|  82 |    664.734541 |    584.456482 | NA                                                                                                                                                                    |
|  83 |    514.621430 |    129.871215 | Zimices                                                                                                                                                               |
|  84 |    866.882489 |     63.192441 | T. Michael Keesey (after MPF)                                                                                                                                         |
|  85 |    556.354902 |    203.589502 | Markus A. Grohme                                                                                                                                                      |
|  86 |    682.612327 |    257.133557 | Tyler Greenfield                                                                                                                                                      |
|  87 |    677.803657 |    113.419258 | Tasman Dixon                                                                                                                                                          |
|  88 |    749.326613 |     34.928849 | Steven Blackwood                                                                                                                                                      |
|  89 |    123.343638 |    582.690252 | Matt Crook                                                                                                                                                            |
|  90 |    641.357675 |    285.140035 | Chris huh                                                                                                                                                             |
|  91 |    437.188437 |    400.788410 | Melissa Broussard                                                                                                                                                     |
|  92 |     86.156209 |    379.652436 | Ferran Sayol                                                                                                                                                          |
|  93 |    969.229180 |    449.960621 | Ignacio Contreras                                                                                                                                                     |
|  94 |    232.001222 |    469.497036 | Gareth Monger                                                                                                                                                         |
|  95 |     50.576522 |    784.336075 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
|  96 |    298.452422 |     14.845169 | Shyamal                                                                                                                                                               |
|  97 |    635.585097 |     56.800485 | Margot Michaud                                                                                                                                                        |
|  98 |   1007.106600 |    741.153978 | CNZdenek                                                                                                                                                              |
|  99 |    895.496999 |     38.775086 | Tyler Greenfield                                                                                                                                                      |
| 100 |    279.291359 |    753.995092 | Jagged Fang Designs                                                                                                                                                   |
| 101 |    953.894552 |    480.508292 | Matus Valach                                                                                                                                                          |
| 102 |    801.675000 |    606.344955 | Harold N Eyster                                                                                                                                                       |
| 103 |    990.495421 |     62.490847 | NA                                                                                                                                                                    |
| 104 |    545.292710 |    168.083345 | FJDegrange                                                                                                                                                            |
| 105 |    999.612074 |    177.514995 | Margot Michaud                                                                                                                                                        |
| 106 |    332.721310 |    776.910476 | Jagged Fang Designs                                                                                                                                                   |
| 107 |    372.984906 |    135.732881 | Zimices                                                                                                                                                               |
| 108 |    861.231859 |    601.587070 | Matt Crook                                                                                                                                                            |
| 109 |     88.945426 |    599.387427 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 110 |    823.078163 |     17.326123 | Jaime Headden                                                                                                                                                         |
| 111 |    781.883622 |    455.514694 | Kanchi Nanjo                                                                                                                                                          |
| 112 |   1004.834692 |    207.354601 | Armin Reindl                                                                                                                                                          |
| 113 |    837.491268 |     34.484067 | FunkMonk (Michael B. H.)                                                                                                                                              |
| 114 |    473.014468 |    694.323881 | Collin Gross                                                                                                                                                          |
| 115 |    450.107206 |    771.788719 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 116 |     23.319197 |    433.576047 | Patrick Strutzenberger                                                                                                                                                |
| 117 |    788.809522 |    310.246207 | Zimices                                                                                                                                                               |
| 118 |    501.125289 |    769.401273 | Margot Michaud                                                                                                                                                        |
| 119 |    491.379757 |    562.068647 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 120 |     46.338057 |    665.513063 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 121 |    966.598898 |    401.978548 | Jagged Fang Designs                                                                                                                                                   |
| 122 |    468.806112 |    428.767696 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 123 |    994.388911 |    485.418342 | White Wolf                                                                                                                                                            |
| 124 |    301.852668 |    679.956312 | Tasman Dixon                                                                                                                                                          |
| 125 |    707.656018 |    261.475467 | Kanchi Nanjo                                                                                                                                                          |
| 126 |    278.723113 |    272.071564 | NA                                                                                                                                                                    |
| 127 |    391.192972 |    787.798136 | Zachary Quigley                                                                                                                                                       |
| 128 |    811.084136 |    640.190979 | Meliponicultor Itaymbere                                                                                                                                              |
| 129 |    633.419622 |    429.228926 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 130 |    668.772883 |    556.382434 | Scott Hartman                                                                                                                                                         |
| 131 |     50.550802 |    247.275555 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 132 |    923.086882 |    542.325754 | Yan Wong                                                                                                                                                              |
| 133 |    744.571672 |    116.450951 | Zimices                                                                                                                                                               |
| 134 |     28.296184 |    455.000875 | Zimices                                                                                                                                                               |
| 135 |    144.137217 |     61.488346 | T. Michael Keesey                                                                                                                                                     |
| 136 |    553.933557 |    219.531176 | Ferran Sayol                                                                                                                                                          |
| 137 |    835.637662 |    423.066819 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 138 |    298.016058 |    564.265602 | Zimices                                                                                                                                                               |
| 139 |    155.196352 |    302.583584 | T. Michael Keesey                                                                                                                                                     |
| 140 |    729.548886 |     62.499391 | Jaime Headden                                                                                                                                                         |
| 141 |    963.459007 |    769.710357 | Birgit Lang                                                                                                                                                           |
| 142 |    625.259653 |    265.097830 | Markus A. Grohme                                                                                                                                                      |
| 143 |    273.352935 |    497.259130 | Ingo Braasch                                                                                                                                                          |
| 144 |    122.614792 |    400.254514 | Pete Buchholz                                                                                                                                                         |
| 145 |     65.624674 |    239.580313 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 146 |    616.814483 |     69.230019 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 147 |    580.121242 |    445.430620 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 148 |    513.710234 |    628.649676 | Steven Traver                                                                                                                                                         |
| 149 |    994.479085 |    283.403466 | Gopal Murali                                                                                                                                                          |
| 150 |    192.284451 |    794.377847 | Sean McCann                                                                                                                                                           |
| 151 |    295.583373 |    775.117683 | Jaime Headden                                                                                                                                                         |
| 152 |    660.207450 |    374.311391 | NA                                                                                                                                                                    |
| 153 |    339.278804 |    731.793668 | Dean Schnabel                                                                                                                                                         |
| 154 |    910.656364 |    130.077938 | Sarah Werning                                                                                                                                                         |
| 155 |    947.324472 |    214.127048 | NA                                                                                                                                                                    |
| 156 |    292.409394 |     21.763559 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 157 |    979.735794 |    753.276041 | Jagged Fang Designs                                                                                                                                                   |
| 158 |    328.473929 |    640.895889 | Steven Traver                                                                                                                                                         |
| 159 |    320.718834 |    369.872520 | Milton Tan                                                                                                                                                            |
| 160 |    395.835651 |     91.027152 | Chris huh                                                                                                                                                             |
| 161 |    566.578342 |     41.868615 | NA                                                                                                                                                                    |
| 162 |    681.070754 |    762.895429 | Ferran Sayol                                                                                                                                                          |
| 163 |      9.202954 |    546.230112 | Ieuan Jones                                                                                                                                                           |
| 164 |    685.100315 |    377.657864 | Zimices                                                                                                                                                               |
| 165 |    446.478270 |    310.160676 | Dean Schnabel                                                                                                                                                         |
| 166 |     58.298395 |    172.954846 | Margot Michaud                                                                                                                                                        |
| 167 |    423.722122 |    499.820167 | C. Camilo Julián-Caballero                                                                                                                                            |
| 168 |    665.843483 |    646.711544 | Gareth Monger                                                                                                                                                         |
| 169 |    630.384657 |    585.922189 | Matt Crook                                                                                                                                                            |
| 170 |    670.527657 |    664.570671 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 171 |    110.236014 |    383.505707 | Julio Garza                                                                                                                                                           |
| 172 |    186.328778 |    620.177621 | S.Martini                                                                                                                                                             |
| 173 |   1008.138605 |    230.130315 | Gareth Monger                                                                                                                                                         |
| 174 |    274.737883 |    327.680282 | Markus A. Grohme                                                                                                                                                      |
| 175 |     16.305585 |    628.983554 | Gareth Monger                                                                                                                                                         |
| 176 |    452.559751 |    642.817328 | Emily Willoughby                                                                                                                                                      |
| 177 |    503.315047 |    602.209007 | Gareth Monger                                                                                                                                                         |
| 178 |    466.050375 |    335.640215 | Matt Crook                                                                                                                                                            |
| 179 |    987.619422 |    749.821167 | Julien Louys                                                                                                                                                          |
| 180 |    874.892174 |    788.519407 | Zimices                                                                                                                                                               |
| 181 |    350.607580 |    668.432761 | Matt Crook                                                                                                                                                            |
| 182 |    677.595181 |    130.298340 | Mathieu Basille                                                                                                                                                       |
| 183 |    525.240214 |    758.895559 | Caleb Brown                                                                                                                                                           |
| 184 |    461.864959 |    601.352882 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 185 |    192.358885 |    672.084732 | Chris huh                                                                                                                                                             |
| 186 |    359.682586 |     94.581987 | Andrew A. Farke                                                                                                                                                       |
| 187 |    368.708806 |    504.878014 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 188 |   1008.054023 |    538.341462 | Sarah Werning                                                                                                                                                         |
| 189 |    646.882103 |    443.111877 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 190 |    132.398822 |    748.306863 | Chase Brownstein                                                                                                                                                      |
| 191 |    297.930785 |    791.591971 | Jagged Fang Designs                                                                                                                                                   |
| 192 |    859.212621 |    216.740804 | Yusan Yang                                                                                                                                                            |
| 193 |    885.703515 |     90.315482 | NA                                                                                                                                                                    |
| 194 |    390.154469 |    427.574952 | Lily Hughes                                                                                                                                                           |
| 195 |    329.963657 |    456.949352 | Christoph Schomburg                                                                                                                                                   |
| 196 |    264.082260 |    197.641218 | NA                                                                                                                                                                    |
| 197 |    832.498579 |     79.480919 | Gareth Monger                                                                                                                                                         |
| 198 |    487.294579 |    403.653800 | Jagged Fang Designs                                                                                                                                                   |
| 199 |    731.251212 |    186.412042 | S.Martini                                                                                                                                                             |
| 200 |    494.382700 |    340.390177 | Richard J. Harris                                                                                                                                                     |
| 201 |    913.021928 |    546.739607 | Scott Hartman                                                                                                                                                         |
| 202 |     67.851281 |    452.639260 | Mareike C. Janiak                                                                                                                                                     |
| 203 |    924.898313 |    792.585809 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 204 |    611.374712 |    630.444311 | Tasman Dixon                                                                                                                                                          |
| 205 |    518.711829 |    368.967990 | T. Michael Keesey                                                                                                                                                     |
| 206 |    577.896680 |    235.590056 | Tasman Dixon                                                                                                                                                          |
| 207 |     98.883938 |    774.190987 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 208 |    667.943819 |    766.434097 | Jaime Headden                                                                                                                                                         |
| 209 |     84.003659 |    438.367126 | Jagged Fang Designs                                                                                                                                                   |
| 210 |    968.605114 |    196.262769 | Margot Michaud                                                                                                                                                        |
| 211 |    275.724024 |    107.805536 | Smokeybjb                                                                                                                                                             |
| 212 |    852.967121 |    794.060382 | Chuanixn Yu                                                                                                                                                           |
| 213 |    108.752598 |      9.428935 | Ferran Sayol                                                                                                                                                          |
| 214 |     24.762818 |    767.370829 | NA                                                                                                                                                                    |
| 215 |    625.843961 |    627.269848 | Andreas Preuss / marauder                                                                                                                                             |
| 216 |    931.705529 |    361.306435 | Chris huh                                                                                                                                                             |
| 217 |    812.811870 |    445.975747 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 218 |     26.510678 |    216.759394 | Gareth Monger                                                                                                                                                         |
| 219 |    962.043252 |    522.473689 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 220 |    721.391376 |    622.963285 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 221 |    629.474433 |    650.715702 | Margot Michaud                                                                                                                                                        |
| 222 |    893.180202 |    602.746984 | Smokeybjb                                                                                                                                                             |
| 223 |    236.197377 |    499.231590 | Campbell Fleming                                                                                                                                                      |
| 224 |    472.526485 |    642.268371 | Steven Coombs                                                                                                                                                         |
| 225 |    533.866827 |    304.738804 | Ferran Sayol                                                                                                                                                          |
| 226 |    882.316896 |    182.448104 | Zimices                                                                                                                                                               |
| 227 |    255.588299 |    423.093946 | Matt Celeskey                                                                                                                                                         |
| 228 |     98.890391 |     65.204460 | Chuanixn Yu                                                                                                                                                           |
| 229 |    261.474398 |    289.812129 | Sarah Werning                                                                                                                                                         |
| 230 |    544.810708 |    480.159736 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 231 |    630.418224 |    394.373229 | Margot Michaud                                                                                                                                                        |
| 232 |    302.535799 |    514.502107 | Pete Buchholz                                                                                                                                                         |
| 233 |    302.091383 |     46.025690 | T. Michael Keesey                                                                                                                                                     |
| 234 |     55.507638 |    705.252616 | Gareth Monger                                                                                                                                                         |
| 235 |    721.709068 |    101.650293 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 236 |    114.783791 |     28.833079 | Caleb M. Brown                                                                                                                                                        |
| 237 |    724.876690 |    332.717475 | Chase Brownstein                                                                                                                                                      |
| 238 |    524.239878 |    523.043501 | Felix Vaux                                                                                                                                                            |
| 239 |    249.297199 |    353.258134 | Benjamint444                                                                                                                                                          |
| 240 |    451.194725 |    628.405608 | Jagged Fang Designs                                                                                                                                                   |
| 241 |    623.724371 |    596.682852 | Scott Hartman                                                                                                                                                         |
| 242 |    172.485091 |    277.724586 | Sarah Werning                                                                                                                                                         |
| 243 |    657.656172 |    330.688022 | Felix Vaux                                                                                                                                                            |
| 244 |    156.720945 |    761.703315 | Manabu Bessho-Uehara                                                                                                                                                  |
| 245 |    341.945831 |    620.511757 | T. Michael Keesey                                                                                                                                                     |
| 246 |    339.047438 |     30.116398 | Natalie Claunch                                                                                                                                                       |
| 247 |    727.055174 |     50.543208 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 248 |    297.227347 |    704.679550 | Roberto Díaz Sibaja                                                                                                                                                   |
| 249 |     10.632291 |     39.519432 | Matt Crook                                                                                                                                                            |
| 250 |    984.764366 |    439.262107 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 251 |    760.562748 |    530.261539 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 252 |    992.479918 |    320.400448 | NA                                                                                                                                                                    |
| 253 |    347.123828 |      9.205200 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 254 |    617.586479 |    741.935836 | Joanna Wolfe                                                                                                                                                          |
| 255 |    513.691670 |    533.652259 | Steven Traver                                                                                                                                                         |
| 256 |    650.932628 |    718.444814 | NA                                                                                                                                                                    |
| 257 |     17.935835 |    274.176087 | Juan Carlos Jerí                                                                                                                                                      |
| 258 |     13.814727 |    335.963249 | Felix Vaux                                                                                                                                                            |
| 259 |    762.988838 |    476.491952 | Dmitry Bogdanov                                                                                                                                                       |
| 260 |     49.461673 |    123.743060 | Oscar Sanisidro                                                                                                                                                       |
| 261 |    825.166827 |    616.029485 | Matt Crook                                                                                                                                                            |
| 262 |    155.460344 |     11.845858 | Matt Crook                                                                                                                                                            |
| 263 |    490.387248 |    432.107255 | Matt Wilkins                                                                                                                                                          |
| 264 |    999.027422 |    675.157422 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 265 |    507.258489 |    154.258924 | Rebecca Groom                                                                                                                                                         |
| 266 |    643.301946 |    554.883886 | Dean Schnabel                                                                                                                                                         |
| 267 |    600.849718 |    264.077875 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 268 |    446.959462 |    681.100617 | NA                                                                                                                                                                    |
| 269 |    561.966624 |    167.928794 | Scott Hartman                                                                                                                                                         |
| 270 |     84.784728 |    449.431150 | Kamil S. Jaron                                                                                                                                                        |
| 271 |   1004.320451 |    774.695363 | Jon Hill                                                                                                                                                              |
| 272 |    260.164636 |    558.688025 | Mathew Wedel                                                                                                                                                          |
| 273 |    219.712475 |    148.644486 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 274 |    391.674326 |    212.215556 | Zimices                                                                                                                                                               |
| 275 |     66.106961 |    374.139466 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 276 |    898.623485 |    150.841401 | Steven Traver                                                                                                                                                         |
| 277 |    279.390361 |    291.531929 | Margot Michaud                                                                                                                                                        |
| 278 |    426.602856 |    615.590028 | Caleb M. Brown                                                                                                                                                        |
| 279 |     43.631999 |    749.206129 | Kai R. Caspar                                                                                                                                                         |
| 280 |    913.459624 |     46.146599 | Gareth Monger                                                                                                                                                         |
| 281 |    713.120799 |    633.436041 | Margot Michaud                                                                                                                                                        |
| 282 |     43.629259 |    288.648671 | Christine Axon                                                                                                                                                        |
| 283 |    600.934720 |    793.749904 | Diana Pomeroy                                                                                                                                                         |
| 284 |    581.599424 |     17.847228 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 285 |    199.379308 |    780.760636 | Stuart Humphries                                                                                                                                                      |
| 286 |    172.702440 |    196.027635 | Mathew Wedel                                                                                                                                                          |
| 287 |    631.984268 |    111.899131 | David Tana                                                                                                                                                            |
| 288 |    485.685467 |    754.977128 | Matt Crook                                                                                                                                                            |
| 289 |    856.849921 |    318.598181 | Terpsichores                                                                                                                                                          |
| 290 |    817.967154 |    429.039960 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 291 |    149.966127 |    401.786979 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 292 |    958.189493 |    539.697606 | Sarah Werning                                                                                                                                                         |
| 293 |    998.258529 |    493.266513 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 294 |    650.249876 |    474.815558 | Tracy A. Heath                                                                                                                                                        |
| 295 |    405.533224 |    473.034381 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 296 |    647.957332 |    257.044759 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 297 |    864.373935 |    191.753272 | Tracy A. Heath                                                                                                                                                        |
| 298 |    242.847468 |    786.246607 | Iain Reid                                                                                                                                                             |
| 299 |    921.194806 |    522.925665 | Melissa Broussard                                                                                                                                                     |
| 300 |    866.723219 |    584.103483 | Michael Scroggie                                                                                                                                                      |
| 301 |    650.378703 |    498.409378 | Michael Scroggie                                                                                                                                                      |
| 302 |    286.730023 |     58.456972 | Gareth Monger                                                                                                                                                         |
| 303 |    734.540921 |     77.727007 | Scott Hartman                                                                                                                                                         |
| 304 |    284.102020 |    766.700079 | Stacy Spensley (Modified)                                                                                                                                             |
| 305 |    734.118540 |    342.006564 | Christoph Schomburg                                                                                                                                                   |
| 306 |    893.474041 |    747.194847 | Steven Traver                                                                                                                                                         |
| 307 |    450.115789 |    732.414913 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 308 |    244.334004 |    562.478451 | Zimices                                                                                                                                                               |
| 309 |    521.989944 |    479.154136 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
| 310 |    697.531163 |     74.374955 | NA                                                                                                                                                                    |
| 311 |    691.083899 |    636.085070 | Zimices                                                                                                                                                               |
| 312 |    435.570881 |    124.876607 | Scott Hartman                                                                                                                                                         |
| 313 |    990.432604 |    295.786250 | Armin Reindl                                                                                                                                                          |
| 314 |    763.958461 |    214.039380 | Andrew R. Gehrke                                                                                                                                                      |
| 315 |    263.704095 |    343.900475 | Matt Crook                                                                                                                                                            |
| 316 |    300.373500 |     63.014474 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 317 |    376.737465 |    218.165929 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 318 |    160.883303 |    451.809863 | Katie S. Collins                                                                                                                                                      |
| 319 |    467.906379 |    416.590088 | Sarah Werning                                                                                                                                                         |
| 320 |    254.860925 |    660.324649 | Jaime Headden                                                                                                                                                         |
| 321 |     16.451477 |    180.442235 | Alexandre Vong                                                                                                                                                        |
| 322 |    506.973449 |    315.261671 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 323 |    704.577545 |    207.483100 | T. Michael Keesey                                                                                                                                                     |
| 324 |     78.827056 |    309.211414 | Melissa Broussard                                                                                                                                                     |
| 325 |    842.009561 |    201.760268 | Kamil S. Jaron                                                                                                                                                        |
| 326 |    224.198730 |    253.197407 | Chris huh                                                                                                                                                             |
| 327 |    884.309920 |    794.903406 | Chris huh                                                                                                                                                             |
| 328 |    103.463619 |    793.592171 | NA                                                                                                                                                                    |
| 329 |    268.254087 |    713.471295 | Margot Michaud                                                                                                                                                        |
| 330 |    202.391419 |    666.701247 | Gareth Monger                                                                                                                                                         |
| 331 |    642.028272 |    204.871725 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 332 |    999.881725 |    470.027789 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 333 |    888.796316 |    342.770592 | Jonathan Wells                                                                                                                                                        |
| 334 |    351.532764 |     25.494109 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 335 |    878.331692 |    449.755085 | Gareth Monger                                                                                                                                                         |
| 336 |    515.961252 |    307.449414 | Shyamal                                                                                                                                                               |
| 337 |    588.531601 |    190.688290 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 338 |    618.925133 |     21.114378 | Zimices                                                                                                                                                               |
| 339 |    595.082465 |    724.357457 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 340 |    532.956296 |    644.695491 | Matt Crook                                                                                                                                                            |
| 341 |    820.604532 |    148.524117 | Michelle Site                                                                                                                                                         |
| 342 |    904.734578 |    707.261389 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 343 |    757.680906 |    485.299482 | Zimices                                                                                                                                                               |
| 344 |    336.378655 |    743.906317 | Matt Crook                                                                                                                                                            |
| 345 |      5.643931 |    235.566533 | Melissa Broussard                                                                                                                                                     |
| 346 |    487.637024 |    738.556838 | Roberto Díaz Sibaja                                                                                                                                                   |
| 347 |    912.992728 |    480.585700 | Gareth Monger                                                                                                                                                         |
| 348 |    673.571173 |    453.006871 | Steven Traver                                                                                                                                                         |
| 349 |     79.576861 |     10.819016 | Steven Traver                                                                                                                                                         |
| 350 |    534.788111 |    652.772532 | Markus A. Grohme                                                                                                                                                      |
| 351 |    341.567999 |    654.233058 | Becky Barnes                                                                                                                                                          |
| 352 |    457.701839 |    706.594421 | Andrés Sánchez                                                                                                                                                        |
| 353 |    639.204715 |    346.048118 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 354 |     11.781891 |    687.126019 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 355 |     11.838827 |    361.849727 | NA                                                                                                                                                                    |
| 356 |    493.475169 |    788.072506 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 357 |    338.465863 |    240.794248 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 358 |    416.474826 |    227.293876 | T. Michael Keesey                                                                                                                                                     |
| 359 |    649.814803 |    271.147308 | Iain Reid                                                                                                                                                             |
| 360 |    189.624086 |    163.899643 | Zimices                                                                                                                                                               |
| 361 |    282.675208 |    310.547496 | Matt Martyniuk                                                                                                                                                        |
| 362 |    380.529185 |     17.568300 | Margot Michaud                                                                                                                                                        |
| 363 |    317.199573 |    197.375707 | Julio Garza                                                                                                                                                           |
| 364 |    259.937840 |    392.352702 | NA                                                                                                                                                                    |
| 365 |    765.550886 |    598.395526 | Chris Jennings (Risiatto)                                                                                                                                             |
| 366 |    905.321658 |    362.443002 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 367 |    525.770154 |    400.467075 | Steven Traver                                                                                                                                                         |
| 368 |    402.793942 |    192.568101 | Maija Karala                                                                                                                                                          |
| 369 |    147.831417 |     88.208346 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 370 |    873.765327 |    680.514090 | Matt Dempsey                                                                                                                                                          |
| 371 |    615.909808 |    310.749842 | Chuanixn Yu                                                                                                                                                           |
| 372 |    164.375589 |    669.626638 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 373 |    265.740341 |    508.067989 | Christoph Schomburg                                                                                                                                                   |
| 374 |    116.807414 |    371.674925 | Markus A. Grohme                                                                                                                                                      |
| 375 |    778.097632 |    279.973532 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 376 |    856.240206 |    184.317303 | Steven Coombs                                                                                                                                                         |
| 377 |    545.525253 |    438.261182 | Zimices                                                                                                                                                               |
| 378 |    815.226737 |    205.180380 | Kamil S. Jaron                                                                                                                                                        |
| 379 |    633.774413 |    247.365268 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 380 |    958.543317 |    386.574130 | Ferran Sayol                                                                                                                                                          |
| 381 |    855.821319 |    683.361478 | Birgit Lang                                                                                                                                                           |
| 382 |    706.495178 |    777.093191 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 383 |    382.328397 |    599.413353 | Gareth Monger                                                                                                                                                         |
| 384 |    758.755881 |    722.480430 | T. Michael Keesey                                                                                                                                                     |
| 385 |    740.127722 |    388.236646 | Michael Scroggie                                                                                                                                                      |
| 386 |    915.530984 |     93.072021 | Dmitry Bogdanov                                                                                                                                                       |
| 387 |    761.408056 |    389.289200 | Chris huh                                                                                                                                                             |
| 388 |    208.243261 |    235.763107 | T. Michael Keesey                                                                                                                                                     |
| 389 |    490.793954 |    616.859803 | S.Martini                                                                                                                                                             |
| 390 |    699.067798 |    112.266532 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 391 |    245.192234 |    180.111094 | Zimices                                                                                                                                                               |
| 392 |    647.057874 |    613.629371 | S.Martini                                                                                                                                                             |
| 393 |    967.921844 |    308.919526 | Matt Crook                                                                                                                                                            |
| 394 |    451.831369 |    248.416003 | Felix Vaux                                                                                                                                                            |
| 395 |    298.865894 |     82.384853 | Sarah Werning                                                                                                                                                         |
| 396 |    345.316150 |    632.086670 | Jake Warner                                                                                                                                                           |
| 397 |    343.829552 |    329.212760 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 398 |    755.011714 |    339.487535 | Christopher Chávez                                                                                                                                                    |
| 399 |    658.076874 |    668.579097 | Steven Traver                                                                                                                                                         |
| 400 |    708.040360 |    216.841345 | Nobu Tamura                                                                                                                                                           |
| 401 |    601.790128 |    404.274336 | Zimices                                                                                                                                                               |
| 402 |    569.355378 |    642.537932 | Chris huh                                                                                                                                                             |
| 403 |    897.173183 |    611.830124 | Margot Michaud                                                                                                                                                        |
| 404 |     30.126489 |    615.947796 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 405 |     19.836629 |    567.825618 | Melissa Broussard                                                                                                                                                     |
| 406 |     61.067712 |    595.779294 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 407 |     78.758728 |    749.356393 | NA                                                                                                                                                                    |
| 408 |    395.804356 |    763.874198 | Tony Ayling                                                                                                                                                           |
| 409 |    496.322356 |    364.630349 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 410 |    343.799853 |    380.475112 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 411 |    709.409416 |    160.876547 | Roberto Díaz Sibaja                                                                                                                                                   |
| 412 |    749.629141 |    788.129584 | Margot Michaud                                                                                                                                                        |
| 413 |    616.933641 |      6.560042 | Mathieu Pélissié                                                                                                                                                      |
| 414 |    818.648171 |    374.372562 | Sarah Werning                                                                                                                                                         |
| 415 |    374.595967 |    166.504776 | Sarah Werning                                                                                                                                                         |
| 416 |     35.604902 |    173.573715 | Andrew A. Farke                                                                                                                                                       |
| 417 |    619.624297 |    241.300721 | Michelle Site                                                                                                                                                         |
| 418 |    281.182282 |    567.553703 | Jagged Fang Designs                                                                                                                                                   |
| 419 |     64.127039 |    388.541430 | Margot Michaud                                                                                                                                                        |
| 420 |    523.375896 |    180.036693 | Matt Crook                                                                                                                                                            |
| 421 |    878.321666 |     26.431058 | Qiang Ou                                                                                                                                                              |
| 422 |    672.722970 |    494.504490 | Ferran Sayol                                                                                                                                                          |
| 423 |    658.688767 |    414.070203 | Matt Crook                                                                                                                                                            |
| 424 |    920.461435 |    444.217431 | Gareth Monger                                                                                                                                                         |
| 425 |    368.869563 |    242.565013 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
| 426 |     47.365878 |    721.880248 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 427 |    101.802807 |    561.236730 | L. Shyamal                                                                                                                                                            |
| 428 |    667.744355 |    310.620531 | Chris huh                                                                                                                                                             |
| 429 |    762.510782 |    458.495515 | Matt Crook                                                                                                                                                            |
| 430 |    201.968279 |    449.763247 | Ferran Sayol                                                                                                                                                          |
| 431 |    531.900491 |     24.784379 | Markus A. Grohme                                                                                                                                                      |
| 432 |    422.980954 |    529.389818 | Steven Traver                                                                                                                                                         |
| 433 |     80.052208 |    345.331875 | Matt Crook                                                                                                                                                            |
| 434 |    403.059183 |    425.092194 | Dean Schnabel                                                                                                                                                         |
| 435 |    368.080536 |    329.414202 | Alex Slavenko                                                                                                                                                         |
| 436 |    270.748622 |    558.755717 | Joanna Wolfe                                                                                                                                                          |
| 437 |    458.456155 |    228.647662 | T. Michael Keesey                                                                                                                                                     |
| 438 |    899.903205 |    105.538842 | Kai R. Caspar                                                                                                                                                         |
| 439 |    319.678359 |    678.937000 | T. Tischler                                                                                                                                                           |
| 440 |    673.998196 |    392.672820 | Margot Michaud                                                                                                                                                        |
| 441 |    790.869333 |    455.668810 | Gareth Monger                                                                                                                                                         |
| 442 |    655.582057 |    401.160848 | Ferran Sayol                                                                                                                                                          |
| 443 |    399.957434 |    637.001052 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 444 |    802.812565 |    787.422557 | FunkMonk                                                                                                                                                              |
| 445 |    321.204736 |    535.012661 | Gareth Monger                                                                                                                                                         |
| 446 |     77.374527 |    764.914245 | T. Michael Keesey and Tanetahi                                                                                                                                        |
| 447 |    677.590107 |    626.033411 | Cesar Julian                                                                                                                                                          |
| 448 |    730.883558 |    105.845951 | Gareth Monger                                                                                                                                                         |
| 449 |    978.748708 |    228.579281 | \[unknown\]                                                                                                                                                           |
| 450 |    815.283746 |    312.098681 | Ferran Sayol                                                                                                                                                          |
| 451 |    310.351541 |    717.226247 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 452 |    658.054596 |     92.797742 | L. Shyamal                                                                                                                                                            |
| 453 |    158.168174 |    783.179795 | Jagged Fang Designs                                                                                                                                                   |
| 454 |    160.099812 |    238.645263 | Matt Crook                                                                                                                                                            |
| 455 |    543.805580 |    107.004924 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 456 |     22.687116 |    728.851637 | Gareth Monger                                                                                                                                                         |
| 457 |    317.718829 |    671.362680 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
| 458 |     15.467668 |    131.333316 | Ferran Sayol                                                                                                                                                          |
| 459 |    144.132685 |    115.094723 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 460 |    324.685134 |    556.285897 | Rebecca Groom                                                                                                                                                         |
| 461 |    332.717171 |    391.668572 | Steven Traver                                                                                                                                                         |
| 462 |    674.209190 |    358.402321 | Margot Michaud                                                                                                                                                        |
| 463 |     62.464505 |    224.567527 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 464 |    541.051818 |    759.686855 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                           |
| 465 |    824.776182 |    413.212860 | Jagged Fang Designs                                                                                                                                                   |
| 466 |    128.822679 |    595.771923 | Ignacio Contreras                                                                                                                                                     |
| 467 |    453.681800 |    696.172248 | Tasman Dixon                                                                                                                                                          |
| 468 |    571.848735 |    287.615873 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                         |
| 469 |    634.695816 |    125.669291 | Iain Reid                                                                                                                                                             |
| 470 |    592.587597 |    645.593793 | NA                                                                                                                                                                    |
| 471 |    321.377867 |    337.333625 | L. Shyamal                                                                                                                                                            |
| 472 |    696.439912 |     41.208310 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 473 |     15.867321 |     76.417585 | Matt Crook                                                                                                                                                            |
| 474 |    837.774223 |    789.054911 | Zimices                                                                                                                                                               |
| 475 |    740.787820 |     88.898644 | Steven Traver                                                                                                                                                         |
| 476 |    335.369872 |    366.762422 | Oscar Sanisidro                                                                                                                                                       |
| 477 |    185.818789 |    395.829887 | Armin Reindl                                                                                                                                                          |
| 478 |    132.874116 |    382.275748 | Steven Traver                                                                                                                                                         |
| 479 |     32.415361 |    255.856045 | T. Michael Keesey                                                                                                                                                     |
| 480 |    568.739993 |    306.615270 | Ignacio Contreras                                                                                                                                                     |
| 481 |    552.986987 |    286.688420 | Dean Schnabel                                                                                                                                                         |
| 482 |    987.384035 |    430.563192 | Andrew A. Farke                                                                                                                                                       |
| 483 |     40.121291 |    116.215476 | NA                                                                                                                                                                    |
| 484 |    400.391995 |    494.522684 | Hugo Gruson                                                                                                                                                           |
| 485 |     93.553872 |    448.325003 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 486 |    793.448355 |    392.971857 | Gareth Monger                                                                                                                                                         |
| 487 |    158.783153 |     67.894389 | Roberto Díaz Sibaja                                                                                                                                                   |
| 488 |   1006.023080 |    404.640633 | Zimices                                                                                                                                                               |
| 489 |    335.697668 |    225.407848 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 490 |    774.795052 |    298.817813 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 491 |     28.657119 |    735.004670 | Collin Gross                                                                                                                                                          |
| 492 |    447.587157 |    611.530268 | Maha Ghazal                                                                                                                                                           |
| 493 |    213.366889 |     44.513131 | Jagged Fang Designs                                                                                                                                                   |
| 494 |    209.574743 |    372.996782 | Mario Quevedo                                                                                                                                                         |
| 495 |    982.660793 |    272.707879 | Becky Barnes                                                                                                                                                          |
| 496 |    351.346017 |    202.176254 | Anna Willoughby                                                                                                                                                       |
| 497 |    768.487653 |    318.918895 | T. Michael Keesey                                                                                                                                                     |
| 498 |    394.282848 |    383.542748 | Andrew A. Farke                                                                                                                                                       |
| 499 |    101.306978 |    127.655251 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 500 |     15.973473 |    776.785014 | xgirouxb                                                                                                                                                              |
| 501 |    300.763536 |    694.522999 | Steven Traver                                                                                                                                                         |
| 502 |    444.590436 |    338.590429 | Skye McDavid                                                                                                                                                          |
| 503 |    100.315372 |    339.551424 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 504 |    124.492042 |     20.665900 | Gareth Monger                                                                                                                                                         |
| 505 |    566.569133 |    627.662241 | Dean Schnabel                                                                                                                                                         |
| 506 |    311.020530 |    740.074019 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 507 |    256.202862 |     93.000698 | Scott Hartman                                                                                                                                                         |
| 508 |    972.625732 |    181.442420 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                          |
| 509 |    480.248907 |    280.031186 | NA                                                                                                                                                                    |
| 510 |    172.460905 |     59.022357 | Ferran Sayol                                                                                                                                                          |
| 511 |    351.540662 |    179.913822 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 512 |     21.523668 |    751.588881 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                        |
| 513 |    817.905111 |    453.716552 | Emily Willoughby                                                                                                                                                      |
| 514 |    770.824846 |    741.235486 | Matus Valach                                                                                                                                                          |
| 515 |     94.814228 |    700.475643 | Matt Crook                                                                                                                                                            |
| 516 |    594.736556 |    136.686790 | Sarah Werning                                                                                                                                                         |
| 517 |    438.024121 |    114.740168 | Matt Crook                                                                                                                                                            |
| 518 |    254.749667 |    241.589921 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 519 |     24.305441 |    599.907251 | Matt Crook                                                                                                                                                            |
| 520 |    237.037228 |    630.516818 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 521 |    855.063325 |    474.820201 | Shyamal                                                                                                                                                               |
| 522 |    754.231285 |    728.105794 | Margot Michaud                                                                                                                                                        |
| 523 |    670.365584 |    420.315145 | Chris huh                                                                                                                                                             |
| 524 |    624.976443 |    537.395098 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 525 |    929.344973 |    498.864124 | Julio Garza                                                                                                                                                           |
| 526 |    408.499973 |    512.870279 | Courtney Rockenbach                                                                                                                                                   |
| 527 |    859.850277 |      3.302852 | Scott Hartman                                                                                                                                                         |
| 528 |    328.056589 |     93.929419 | Ferran Sayol                                                                                                                                                          |
| 529 |    348.312497 |    447.586400 | Margot Michaud                                                                                                                                                        |
| 530 |    244.926142 |    402.577860 | NA                                                                                                                                                                    |
| 531 |     41.104884 |    191.614305 | Matt Crook                                                                                                                                                            |
| 532 |     33.783175 |    152.808495 | Siobhon Egan                                                                                                                                                          |
| 533 |    159.286856 |    256.054275 | Gareth Monger                                                                                                                                                         |
| 534 |    584.735267 |    220.216405 | Gareth Monger                                                                                                                                                         |
| 535 |    654.524790 |    754.641110 | Margot Michaud                                                                                                                                                        |
| 536 |    309.042771 |    354.612422 | Gareth Monger                                                                                                                                                         |
| 537 |    466.178483 |    407.083922 | Steven Traver                                                                                                                                                         |
| 538 |    550.717725 |    301.622145 | Jagged Fang Designs                                                                                                                                                   |
| 539 |    259.508672 |    757.431838 | Jaime Headden                                                                                                                                                         |
| 540 |    527.370973 |    432.721199 | Matt Crook                                                                                                                                                            |
| 541 |    178.405140 |    226.796648 | Kai R. Caspar                                                                                                                                                         |
| 542 |     75.012123 |     95.103463 | Beth Reinke                                                                                                                                                           |
| 543 |    160.417758 |    748.949315 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 544 |    711.682023 |    343.436689 | Neil Kelley                                                                                                                                                           |
| 545 |    643.094078 |    503.662415 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 546 |    403.164781 |    750.897835 | Collin Gross                                                                                                                                                          |
| 547 |     34.126677 |    676.527528 | Scott Hartman                                                                                                                                                         |
| 548 |    434.485003 |    329.397545 | Scott Hartman                                                                                                                                                         |
| 549 |    227.298653 |    269.956035 | NA                                                                                                                                                                    |
| 550 |    656.006115 |    429.168176 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 551 |     97.579252 |    314.262698 | Chris huh                                                                                                                                                             |
| 552 |      7.855655 |    101.103071 | Matt Crook                                                                                                                                                            |
| 553 |     29.794519 |    656.200447 | Ferran Sayol                                                                                                                                                          |
| 554 |    171.694324 |     74.492252 | Margot Michaud                                                                                                                                                        |
| 555 |    293.585456 |    344.750488 | Matt Crook                                                                                                                                                            |
| 556 |    413.680807 |    779.509684 | Roberto Díaz Sibaja                                                                                                                                                   |
| 557 |    315.727866 |    579.826069 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 558 |    942.573883 |    514.432163 | Alex Slavenko                                                                                                                                                         |
| 559 |    321.115401 |    744.807060 | Matt Crook                                                                                                                                                            |
| 560 |    325.316836 |    214.262414 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 561 |    861.753172 |    692.661502 | Matt Crook                                                                                                                                                            |
| 562 |     27.195731 |    293.809213 | Emily Willoughby                                                                                                                                                      |
| 563 |    768.083233 |    504.080886 | Chris huh                                                                                                                                                             |
| 564 |    734.414649 |    623.036740 | L. Shyamal                                                                                                                                                            |
| 565 |    681.884391 |    197.332481 | Kai R. Caspar                                                                                                                                                         |
| 566 |    579.747557 |     80.225054 | Scott Hartman                                                                                                                                                         |
| 567 |    833.440377 |    596.160246 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 568 |    631.359758 |    318.777083 | Matt Crook                                                                                                                                                            |
| 569 |    264.645825 |    693.402046 | NA                                                                                                                                                                    |
| 570 |    289.788123 |    112.386631 | Michelle Site                                                                                                                                                         |
| 571 |    665.808649 |    348.978149 | Matt Crook                                                                                                                                                            |
| 572 |    579.803570 |    457.300787 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 573 |    507.705735 |    619.293503 | Jaime Headden                                                                                                                                                         |
| 574 |    478.970680 |     84.611600 | L. Shyamal                                                                                                                                                            |
| 575 |    981.884670 |      9.184390 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 576 |    385.634890 |    617.663092 | Zimices                                                                                                                                                               |
| 577 |    662.130071 |    502.984264 | Neil Kelley                                                                                                                                                           |
| 578 |    809.880488 |    436.970821 | Jagged Fang Designs                                                                                                                                                   |
| 579 |    835.954134 |    760.136960 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                         |
| 580 |    563.520179 |    248.405017 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 581 |    421.735385 |    482.660729 | Mathilde Cordellier                                                                                                                                                   |
| 582 |    145.203175 |     83.176058 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 583 |     31.700594 |    639.122541 | Maxime Dahirel                                                                                                                                                        |
| 584 |    646.281440 |    363.012513 | B. Duygu Özpolat                                                                                                                                                      |
| 585 |    393.293786 |    254.744145 | Steven Traver                                                                                                                                                         |
| 586 |   1014.793635 |    784.960787 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 587 |    398.714342 |    317.774693 | Melissa Broussard                                                                                                                                                     |
| 588 |    448.434546 |    222.522199 | Sharon Wegner-Larsen                                                                                                                                                  |
| 589 |    911.580689 |    503.184333 | Matt Crook                                                                                                                                                            |
| 590 |    161.760961 |    792.042242 | Margot Michaud                                                                                                                                                        |
| 591 |    544.904436 |    446.353981 | Margot Michaud                                                                                                                                                        |
| 592 |    116.822602 |    468.667272 | Chris huh                                                                                                                                                             |
| 593 |     98.731724 |     84.938920 | Matt Crook                                                                                                                                                            |
| 594 |    576.354027 |     97.725227 | Dexter R. Mardis                                                                                                                                                      |
| 595 |    980.585504 |    733.508895 | Birgit Lang                                                                                                                                                           |
| 596 |    790.836950 |    758.357954 | Dean Schnabel                                                                                                                                                         |
| 597 |    480.520391 |    319.787707 | Roberto Díaz Sibaja                                                                                                                                                   |
| 598 |    243.592609 |     11.497828 | Shyamal                                                                                                                                                               |
| 599 |   1002.091801 |    449.664291 | Dean Schnabel                                                                                                                                                         |
| 600 |    672.898380 |    319.852663 | Michael Scroggie                                                                                                                                                      |
| 601 |    894.474168 |    456.518933 | Ignacio Contreras                                                                                                                                                     |
| 602 |    320.692300 |    699.309561 | Emily Willoughby                                                                                                                                                      |
| 603 |    931.870827 |    215.886888 | Felix Vaux                                                                                                                                                            |
| 604 |    612.979186 |    459.756349 | Steven Traver                                                                                                                                                         |
| 605 |   1002.415728 |    699.419269 | Dmitry Bogdanov                                                                                                                                                       |
| 606 |    657.252528 |    206.258114 | NA                                                                                                                                                                    |
| 607 |     10.118105 |    286.177871 | Tasman Dixon                                                                                                                                                          |
| 608 |    356.871371 |     38.386300 | SauropodomorphMonarch                                                                                                                                                 |
| 609 |     44.579516 |    436.308660 | Martin Kevil                                                                                                                                                          |
| 610 |    803.470594 |    242.514647 | Chris huh                                                                                                                                                             |
| 611 |    727.634391 |    205.851245 | Margot Michaud                                                                                                                                                        |
| 612 |    580.977216 |    795.348606 | Collin Gross                                                                                                                                                          |
| 613 |    162.823190 |    166.406623 | Jagged Fang Designs                                                                                                                                                   |
| 614 |    542.124610 |    461.609677 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 615 |    903.632776 |    397.522848 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 616 |    260.446975 |    128.656540 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 617 |    931.143996 |    375.186418 | Davidson Sodré                                                                                                                                                        |
| 618 |    857.475856 |    147.765639 | Zimices                                                                                                                                                               |
| 619 |    744.116076 |    243.987580 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 620 |    872.107411 |     92.442088 | Chris huh                                                                                                                                                             |
| 621 |    444.554502 |    420.903185 | Mo Hassan                                                                                                                                                             |
| 622 |    350.116363 |    749.283784 | Roberto Díaz Sibaja                                                                                                                                                   |
| 623 |    646.492078 |    419.153907 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 624 |    216.177312 |    362.804602 | Scott Hartman                                                                                                                                                         |
| 625 |      8.728713 |    144.742395 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 626 |     12.968679 |    407.566331 | Scott Reid                                                                                                                                                            |
| 627 |    892.942793 |    632.397923 | NA                                                                                                                                                                    |
| 628 |    770.598159 |    224.803023 | Zimices                                                                                                                                                               |
| 629 |    266.438335 |    350.678828 | Matt Crook                                                                                                                                                            |
| 630 |    546.937038 |     17.210231 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 631 |    605.861163 |     57.840739 | NA                                                                                                                                                                    |
| 632 |    213.112177 |    468.136827 | Richard J. Harris                                                                                                                                                     |
| 633 |    394.484148 |      8.544502 | Markus A. Grohme                                                                                                                                                      |
| 634 |    342.124896 |    425.276107 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 635 |     82.601052 |    780.820606 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 636 |    760.856073 |    117.515091 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 637 |    408.086578 |    405.470661 | Gareth Monger                                                                                                                                                         |
| 638 |    263.919014 |     13.450791 | FunkMonk                                                                                                                                                              |
| 639 |    408.755920 |    677.090637 | NA                                                                                                                                                                    |
| 640 |    274.836558 |    680.594030 | Margot Michaud                                                                                                                                                        |
| 641 |    403.271821 |    463.996141 | Markus A. Grohme                                                                                                                                                      |
| 642 |    326.245240 |    510.928380 | Maha Ghazal                                                                                                                                                           |
| 643 |    585.278152 |     72.664961 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 644 |    567.601909 |    401.331005 | Gareth Monger                                                                                                                                                         |
| 645 |    626.384363 |    579.085254 | Michelle Site                                                                                                                                                         |
| 646 |     60.025334 |    256.323912 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 647 |    990.389658 |    765.556988 | Xavier Giroux-Bougard                                                                                                                                                 |
| 648 |    220.846587 |    177.102744 | Margot Michaud                                                                                                                                                        |
| 649 |    313.476937 |    795.440666 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 650 |    527.993869 |    338.134118 | Gareth Monger                                                                                                                                                         |
| 651 |    585.087357 |    287.527634 | Steven Traver                                                                                                                                                         |
| 652 |    643.718590 |    576.072041 | Matt Crook                                                                                                                                                            |
| 653 |    222.055993 |    130.731815 | Noah Schlottman                                                                                                                                                       |
| 654 |    138.674539 |    692.166476 | NA                                                                                                                                                                    |
| 655 |     36.112300 |    775.927176 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 656 |    308.199030 |     27.586979 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 657 |    827.772778 |    655.642511 | M Kolmann                                                                                                                                                             |
| 658 |    857.142585 |    460.070842 | Gareth Monger                                                                                                                                                         |
| 659 |    501.532979 |    291.964805 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 660 |    973.775631 |    464.352566 | Mykle Hoban                                                                                                                                                           |
| 661 |    816.256885 |    179.950019 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 662 |    137.729656 |     46.228829 | Mo Hassan                                                                                                                                                             |
| 663 |     83.471199 |    362.227641 | Margot Michaud                                                                                                                                                        |
| 664 |    999.285003 |    335.241222 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 665 |    348.069532 |    501.491638 | Gareth Monger                                                                                                                                                         |
| 666 |   1010.429365 |    267.750738 | NA                                                                                                                                                                    |
| 667 |    489.729783 |    539.284951 | Ignacio Contreras                                                                                                                                                     |
| 668 |    443.262595 |    516.933783 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 669 |    172.524283 |     90.541754 | T. Michael Keesey                                                                                                                                                     |
| 670 |    814.123368 |     42.239784 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 671 |    845.908648 |     49.028251 | Gareth Monger                                                                                                                                                         |
| 672 |    851.267876 |    368.949743 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 673 |    193.101291 |    451.858502 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 674 |    230.700589 |    788.959414 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 675 |    860.386971 |    446.933800 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                           |
| 676 |    866.812719 |     20.462719 | T. Tischler                                                                                                                                                           |
| 677 |    679.381251 |    739.564176 | Oren Peles / vectorized by Yan Wong                                                                                                                                   |
| 678 |    719.159465 |    778.319764 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 679 |    680.548956 |    101.474548 | Matt Crook                                                                                                                                                            |
| 680 |    598.497377 |    176.673738 | Birgit Lang                                                                                                                                                           |
| 681 |     43.485847 |    611.553837 | Emily Jane McTavish                                                                                                                                                   |
| 682 |    955.292978 |    745.608507 | Andrew A. Farke                                                                                                                                                       |
| 683 |    944.842972 |    202.909081 | Jagged Fang Designs                                                                                                                                                   |
| 684 |    419.262583 |    364.693979 | Steven Traver                                                                                                                                                         |
| 685 |    131.033598 |    706.042545 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 686 |    689.536897 |    776.581005 | Matt Crook                                                                                                                                                            |
| 687 |    745.169574 |    354.499812 | Becky Barnes                                                                                                                                                          |
| 688 |    711.928587 |    524.432629 | Matt Crook                                                                                                                                                            |
| 689 |    240.562209 |    535.070577 | Ignacio Contreras                                                                                                                                                     |
| 690 |    283.128554 |    504.924153 | Dean Schnabel                                                                                                                                                         |
| 691 |    597.407093 |    621.835704 | Ferran Sayol                                                                                                                                                          |
| 692 |     40.230319 |    137.507042 | T. Michael Keesey                                                                                                                                                     |
| 693 |    190.257700 |    785.806740 | Jagged Fang Designs                                                                                                                                                   |
| 694 |    848.340967 |     70.972228 | Mathew Wedel                                                                                                                                                          |
| 695 |    778.371484 |    433.435466 | Zimices                                                                                                                                                               |
| 696 |    483.263855 |    595.281268 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 697 |    848.857455 |    129.537507 | Scott Hartman                                                                                                                                                         |
| 698 |    760.196367 |    793.984418 | Margot Michaud                                                                                                                                                        |
| 699 |   1016.164509 |    320.680258 | Michael Scroggie                                                                                                                                                      |
| 700 |     15.779430 |      3.361703 | Jagged Fang Designs                                                                                                                                                   |
| 701 |    974.631706 |    475.685925 | NA                                                                                                                                                                    |
| 702 |    762.232456 |    403.513266 | Ferran Sayol                                                                                                                                                          |
| 703 |    838.466164 |    314.666450 | NA                                                                                                                                                                    |
| 704 |     40.978970 |    649.976990 | C. Camilo Julián-Caballero                                                                                                                                            |
| 705 |    429.986957 |    780.557415 | Margot Michaud                                                                                                                                                        |
| 706 |    846.306884 |     19.442694 | Ferran Sayol                                                                                                                                                          |
| 707 |    553.130824 |     86.879116 | Michael P. Taylor                                                                                                                                                     |
| 708 |    932.643189 |    394.171580 | NA                                                                                                                                                                    |
| 709 |    404.837211 |    692.317428 | Margot Michaud                                                                                                                                                        |
| 710 |     90.274734 |    432.247086 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 711 |    329.110200 |    720.103602 | Michelle Site                                                                                                                                                         |
| 712 |     82.757969 |    326.443961 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 713 |   1003.912770 |    165.927769 | Tasman Dixon                                                                                                                                                          |
| 714 |    552.493356 |    473.108754 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 715 |    323.246942 |     78.990950 | Christina N. Hodson                                                                                                                                                   |
| 716 |    271.312654 |    306.486335 | T. Michael Keesey                                                                                                                                                     |
| 717 |     94.870501 |    689.811943 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
| 718 |    433.387374 |    230.214096 | Zimices                                                                                                                                                               |
| 719 |     10.110952 |    640.533032 | Ferran Sayol                                                                                                                                                          |
| 720 |    864.307992 |    656.091490 | Carlos Cano-Barbacil                                                                                                                                                  |
| 721 |    281.490507 |    740.254099 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 722 |    255.912724 |    279.942391 | Iain Reid                                                                                                                                                             |
| 723 |    896.047039 |     11.457418 | Ingo Braasch                                                                                                                                                          |
| 724 |    482.160388 |    351.523718 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 725 |    347.279093 |    560.360991 | Andrés Sánchez                                                                                                                                                        |
| 726 |    802.667879 |     94.100576 | Kamil S. Jaron                                                                                                                                                        |
| 727 |    339.419584 |    576.754271 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 728 |    657.986135 |    132.940848 | Elizabeth Parker                                                                                                                                                      |
| 729 |    847.360624 |    156.737006 | terngirl                                                                                                                                                              |
| 730 |    279.182031 |    374.083961 | Jagged Fang Designs                                                                                                                                                   |
| 731 |    604.074319 |     89.560790 | Scott Hartman                                                                                                                                                         |
| 732 |     25.604900 |     88.060306 | Margot Michaud                                                                                                                                                        |
| 733 |    724.501762 |    526.649682 | Gareth Monger                                                                                                                                                         |
| 734 |    167.000995 |    380.973749 | Steven Traver                                                                                                                                                         |
| 735 |    993.127206 |    666.158247 | Christoph Schomburg                                                                                                                                                   |
| 736 |    897.233640 |     54.338211 | NA                                                                                                                                                                    |
| 737 |     18.738012 |    319.529844 | Kamil S. Jaron                                                                                                                                                        |
| 738 |    305.778416 |    109.671545 | Matt Crook                                                                                                                                                            |
| 739 |    388.639106 |    440.293628 | Margot Michaud                                                                                                                                                        |
| 740 |    730.888166 |    463.826806 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 741 |     68.993532 |    357.220560 | Dean Schnabel                                                                                                                                                         |
| 742 |    471.964013 |    235.691761 | David Orr                                                                                                                                                             |
| 743 |    346.615918 |    584.349328 | Iain Reid                                                                                                                                                             |
| 744 |    807.587678 |    770.201604 | NA                                                                                                                                                                    |
| 745 |    756.820656 |    135.017801 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 746 |    724.310172 |    173.439036 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 747 |    139.969757 |    269.678163 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 748 |    649.984729 |    636.522437 | Birgit Lang                                                                                                                                                           |
| 749 |     19.356492 |    398.759238 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 750 |    128.159544 |    611.079871 | Steven Traver                                                                                                                                                         |
| 751 |    773.386220 |    623.338353 | Chris huh                                                                                                                                                             |
| 752 |    377.049896 |     28.669463 | Margot Michaud                                                                                                                                                        |
| 753 |    125.466510 |    390.555711 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 754 |     24.677612 |    107.182569 | Jagged Fang Designs                                                                                                                                                   |
| 755 |    267.655840 |    483.515930 | Tasman Dixon                                                                                                                                                          |
| 756 |    253.850514 |    365.707282 | Margot Michaud                                                                                                                                                        |
| 757 |    193.335070 |    292.694713 | Steven Traver                                                                                                                                                         |
| 758 |    224.254882 |    568.245937 | T. Michael Keesey                                                                                                                                                     |
| 759 |    331.931021 |    610.618836 | Matt Crook                                                                                                                                                            |
| 760 |    280.730006 |     31.313482 | NA                                                                                                                                                                    |
| 761 |    871.005822 |    323.107509 | Jagged Fang Designs                                                                                                                                                   |
| 762 |    375.133073 |    678.863214 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 763 |    447.658913 |    702.934029 | Scott Hartman                                                                                                                                                         |
| 764 |    190.285442 |    649.735800 | Matt Crook                                                                                                                                                            |
| 765 |   1015.639318 |    482.456646 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 766 |    906.228133 |    213.339120 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 767 |     31.170642 |    238.067548 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                           |
| 768 |    385.781804 |    271.318972 | Zimices                                                                                                                                                               |
| 769 |    788.882541 |    365.319820 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 770 |    555.041174 |     49.479752 | Gareth Monger                                                                                                                                                         |
| 771 |    264.567876 |    382.359379 | T. Michael Keesey                                                                                                                                                     |
| 772 |    696.978512 |    385.000667 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 773 |    619.864322 |    334.171518 | Gareth Monger                                                                                                                                                         |
| 774 |    923.151699 |     54.490770 | NA                                                                                                                                                                    |
| 775 |    238.597273 |    160.227501 | (after Spotila 2004)                                                                                                                                                  |
| 776 |    960.429278 |    298.236044 | NA                                                                                                                                                                    |
| 777 |    863.143520 |    782.424363 | Jaime Headden                                                                                                                                                         |
| 778 |    117.156693 |    318.763329 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 779 |    865.252977 |    165.993192 | T. Michael Keesey                                                                                                                                                     |
| 780 |    477.180062 |    788.812987 | Carlos Cano-Barbacil                                                                                                                                                  |
| 781 |    475.593025 |    775.265454 | Zimices                                                                                                                                                               |
| 782 |    185.513483 |    182.173553 | Scott Hartman                                                                                                                                                         |
| 783 |    388.799645 |    176.100149 | Beth Reinke                                                                                                                                                           |
| 784 |    790.374376 |    294.016396 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 785 |    414.422902 |    394.196612 | Kai R. Caspar                                                                                                                                                         |
| 786 |    312.364436 |    606.610252 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 787 |    914.880966 |    554.203758 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 788 |    254.501536 |    108.643349 | Markus A. Grohme                                                                                                                                                      |
| 789 |    890.817077 |    158.674390 | Iain Reid                                                                                                                                                             |
| 790 |    108.607111 |    546.300945 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 791 |    988.429270 |    213.289640 | Jagged Fang Designs                                                                                                                                                   |
| 792 |    450.483662 |    751.801121 | Jagged Fang Designs                                                                                                                                                   |
| 793 |    197.628598 |    430.991671 | Steven Coombs                                                                                                                                                         |
| 794 |    499.446033 |    665.291759 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 795 |    729.804077 |    756.174376 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 796 |     11.714373 |    463.171671 | Ferran Sayol                                                                                                                                                          |
| 797 |    397.408574 |    417.019474 | Ferran Sayol                                                                                                                                                          |
| 798 |    901.699049 |    789.600297 | Chase Brownstein                                                                                                                                                      |
| 799 |    993.388207 |    795.130997 | Emily Willoughby                                                                                                                                                      |
| 800 |    745.342572 |    738.358355 | Dmitry Bogdanov                                                                                                                                                       |
| 801 |    474.431530 |    449.333055 | Michele M Tobias                                                                                                                                                      |
| 802 |    683.957911 |    156.911127 | NA                                                                                                                                                                    |
| 803 |     90.029023 |    681.861896 | Zimices                                                                                                                                                               |
| 804 |    274.642023 |     74.927593 | Ferran Sayol                                                                                                                                                          |
| 805 |    647.437534 |    622.554728 | Kimberly Haddrell                                                                                                                                                     |
| 806 |    685.711048 |    621.416145 | Shyamal                                                                                                                                                               |
| 807 |    583.026125 |    174.435780 | Zimices                                                                                                                                                               |
| 808 |    574.488635 |      9.929076 | Jagged Fang Designs                                                                                                                                                   |
| 809 |    658.986809 |    686.196986 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 810 |    102.397996 |    461.687693 | Matt Crook                                                                                                                                                            |
| 811 |    489.874480 |    303.997121 | NA                                                                                                                                                                    |
| 812 |    864.852176 |     39.057571 | Alex Slavenko                                                                                                                                                         |
| 813 |    605.895644 |    473.676471 | Terpsichores                                                                                                                                                          |
| 814 |    112.268722 |    713.743717 | Zimices                                                                                                                                                               |
| 815 |    973.915036 |    378.613412 | Melissa Broussard                                                                                                                                                     |
| 816 |    736.032504 |    254.817017 | Peter Coxhead                                                                                                                                                         |
| 817 |    464.859937 |    188.275167 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 818 |     35.873508 |    756.822695 | NA                                                                                                                                                                    |
| 819 |    666.583494 |    736.257117 | Margot Michaud                                                                                                                                                        |
| 820 |    890.790254 |    624.789741 | Margot Michaud                                                                                                                                                        |
| 821 |    294.772747 |    723.830164 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 822 |    284.671123 |     23.682744 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 823 |    269.025238 |    665.391516 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 824 |    440.151236 |    689.537198 | Margot Michaud                                                                                                                                                        |
| 825 |    544.099211 |    733.788830 | T. Michael Keesey                                                                                                                                                     |
| 826 |    694.566018 |    408.163438 | Margot Michaud                                                                                                                                                        |
| 827 |    931.206769 |    784.144697 | nicubunu                                                                                                                                                              |
| 828 |    693.557726 |    606.785478 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 829 |    771.222738 |    120.711526 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 830 |    765.561948 |    615.380757 | Margot Michaud                                                                                                                                                        |
| 831 |    301.166948 |    186.184902 | Steven Traver                                                                                                                                                         |
| 832 |    594.045256 |    252.658516 | Tasman Dixon                                                                                                                                                          |
| 833 |    894.502381 |    476.732694 | Cesar Julian                                                                                                                                                          |
| 834 |    570.218307 |    468.813159 | Zimices                                                                                                                                                               |
| 835 |    526.600456 |    287.199944 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 836 |    692.425672 |    126.038282 | Matt Crook                                                                                                                                                            |
| 837 |    276.513731 |      6.005301 | Scott Hartman                                                                                                                                                         |
| 838 |    760.285959 |    765.969361 | FunkMonk                                                                                                                                                              |
| 839 |     53.481342 |    286.190730 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 840 |    271.569410 |     91.684238 | xgirouxb                                                                                                                                                              |
| 841 |    747.041322 |    749.076911 | Scott Hartman                                                                                                                                                         |
| 842 |    670.999490 |    138.602786 | Zimices                                                                                                                                                               |
| 843 |    490.511468 |    548.207177 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 844 |    864.069676 |    674.944606 | Melissa Broussard                                                                                                                                                     |
| 845 |     52.864160 |    654.154563 | Chris huh                                                                                                                                                             |
| 846 |    330.068668 |     61.645078 | Gareth Monger                                                                                                                                                         |
| 847 |    137.041962 |    230.549450 | Margot Michaud                                                                                                                                                        |
| 848 |    480.316516 |    676.462864 | Kai R. Caspar                                                                                                                                                         |
| 849 |     43.429139 |    236.625713 | Christina N. Hodson                                                                                                                                                   |
| 850 |   1017.207065 |    658.955698 | Stuart Humphries                                                                                                                                                      |
| 851 |     20.722330 |    117.572077 | Matt Crook                                                                                                                                                            |
| 852 |    891.074811 |    649.603326 | Steven Traver                                                                                                                                                         |
| 853 |    297.568271 |    260.590526 | T. Michael Keesey                                                                                                                                                     |
| 854 |    966.797023 |    547.161969 | Alex Slavenko                                                                                                                                                         |
| 855 |    598.460826 |     64.963414 | Chris huh                                                                                                                                                             |
| 856 |    230.695658 |    124.724734 | Steven Traver                                                                                                                                                         |
| 857 |    934.322116 |    203.749695 | Beth Reinke                                                                                                                                                           |
| 858 |    823.336200 |    163.233171 | Margot Michaud                                                                                                                                                        |
| 859 |    756.812195 |      7.741524 | Zimices                                                                                                                                                               |
| 860 |     32.424669 |    792.340361 | Jay Matternes, vectorized by Zimices                                                                                                                                  |
| 861 |    213.099432 |    457.538049 | Zimices                                                                                                                                                               |
| 862 |    238.270848 |    115.236905 | Steven Traver                                                                                                                                                         |
| 863 |    964.999532 |    282.863254 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 864 |    650.269590 |    334.253570 | Tasman Dixon                                                                                                                                                          |
| 865 |    901.130695 |    663.246967 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 866 |    828.269881 |    129.934137 | Scott Hartman                                                                                                                                                         |
| 867 |    670.938053 |    382.320529 | Kai R. Caspar                                                                                                                                                         |
| 868 |    553.235382 |    795.690108 | Zimices                                                                                                                                                               |
| 869 |    641.228416 |     36.094130 | Margot Michaud                                                                                                                                                        |
| 870 |    454.738187 |    559.128885 | Sarah Werning                                                                                                                                                         |
| 871 |    356.328746 |    610.710276 | Gareth Monger                                                                                                                                                         |
| 872 |    293.182279 |    369.938955 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 873 |     21.971923 |    589.022805 | C. Camilo Julián-Caballero                                                                                                                                            |
| 874 |    655.923439 |    563.683432 | Zimices                                                                                                                                                               |
| 875 |    222.687183 |    409.342680 | Kamil S. Jaron                                                                                                                                                        |
| 876 |    541.088314 |    144.590840 | Matt Crook                                                                                                                                                            |
| 877 |    170.737208 |    395.710397 | Chris huh                                                                                                                                                             |
| 878 |    696.917592 |    590.195364 | Margot Michaud                                                                                                                                                        |
| 879 |    967.742893 |    646.472114 | Zimices                                                                                                                                                               |
| 880 |    927.356315 |     68.542312 | ArtFavor & annaleeblysse                                                                                                                                              |
| 881 |    874.333711 |    155.419973 | Jessica Anne Miller                                                                                                                                                   |
| 882 |    385.678970 |    106.116659 | Chris huh                                                                                                                                                             |
| 883 |     88.620637 |    353.898359 | Zimices                                                                                                                                                               |
| 884 |    889.459961 |    286.552012 | Maxime Dahirel                                                                                                                                                        |
| 885 |    157.678004 |    604.742702 | Chloé Schmidt                                                                                                                                                         |
| 886 |     44.596121 |    594.168200 | Ferran Sayol                                                                                                                                                          |
| 887 |    825.246651 |    214.371830 | Scott Hartman                                                                                                                                                         |
| 888 |    103.562948 |    454.227945 | Tasman Dixon                                                                                                                                                          |
| 889 |    629.734671 |    490.050755 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 890 |    903.327392 |    287.028604 | Matt Crook                                                                                                                                                            |
| 891 |    617.045850 |    282.873050 | Inessa Voet                                                                                                                                                           |
| 892 |     33.748015 |    696.573849 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
| 893 |    241.658274 |    322.267539 | Dean Schnabel                                                                                                                                                         |
| 894 |    426.860193 |    242.853773 | Jack Mayer Wood                                                                                                                                                       |
| 895 |    813.082044 |     81.568594 | Emma Hughes                                                                                                                                                           |
| 896 |    736.728522 |    786.073263 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 897 |    291.484873 |     98.872489 | Konsta Happonen                                                                                                                                                       |
| 898 |    310.108809 |    508.447636 | Jaime Headden                                                                                                                                                         |
| 899 |    530.064548 |    451.649897 | Matt Crook                                                                                                                                                            |
| 900 |     98.872854 |    143.323222 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 901 |    226.497933 |    238.918526 | Kamil S. Jaron                                                                                                                                                        |
| 902 |    620.548327 |    260.391294 | Chris huh                                                                                                                                                             |
| 903 |    408.856238 |    332.475857 | NA                                                                                                                                                                    |
| 904 |    158.255426 |     52.291848 | Matt Crook                                                                                                                                                            |
| 905 |    899.738681 |     78.942284 | Margot Michaud                                                                                                                                                        |
| 906 |    881.709496 |    233.271576 | Markus A. Grohme                                                                                                                                                      |
| 907 |    938.988849 |    447.392187 | Zimices                                                                                                                                                               |
| 908 |    719.409736 |    245.453059 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 909 |    238.372780 |    654.571382 | Scott Hartman                                                                                                                                                         |
| 910 |    133.980620 |    714.609836 | Zimices                                                                                                                                                               |
| 911 |    693.234950 |    789.403542 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 912 |    776.684131 |    757.441344 | Matt Dempsey                                                                                                                                                          |
| 913 |     19.114769 |    255.949740 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 914 |    631.893243 |    472.103400 | Margot Michaud                                                                                                                                                        |
| 915 |    820.742666 |    755.680943 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 916 |    640.704035 |    409.135237 | Tracy A. Heath                                                                                                                                                        |
| 917 |    229.885175 |    427.529073 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 918 |     55.532919 |    428.452265 | Zimices                                                                                                                                                               |
| 919 |    635.317295 |    456.321122 | Zimices                                                                                                                                                               |
| 920 |    714.116829 |     23.366514 | Manabu Bessho-Uehara                                                                                                                                                  |
| 921 |    668.615896 |    434.599323 | Maxime Dahirel                                                                                                                                                        |
| 922 |    396.870542 |     14.087605 | Skye McDavid                                                                                                                                                          |
| 923 |    361.928715 |      6.411873 | T. Michael Keesey                                                                                                                                                     |

    #> Your tweet has been posted!
