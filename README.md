
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

Ieuan Jones, Steven Traver, L. Shyamal, Joshua Fowler, Gareth Monger,
Ignacio Contreras, Konsta Happonen, from a CC-BY-NC image by pelhonen on
iNaturalist, Mareike C. Janiak, T. Michael Keesey (after Ponomarenko),
Beth Reinke, Kanchi Nanjo, Matt Crook, Matthew E. Clapham, Armin Reindl,
Margot Michaud, Ferran Sayol, Maija Karala, Servien (vectorized by T.
Michael Keesey), Pete Buchholz, Lily Hughes, Joanna Wolfe, Nobu Tamura
(vectorized by T. Michael Keesey), Kai R. Caspar, Zimices, Felix Vaux,
T. Michael Keesey, Andrew A. Farke, Obsidian Soul (vectorized by T.
Michael Keesey), Mathieu Basille, Mali’o Kodis, photograph by P. Funch
and R.M. Kristensen, Charles R. Knight, vectorized by Zimices, Markus A.
Grohme, Lukasiniho, Sarah Werning, Jagged Fang Designs, FunkMonk, Conty
(vectorized by T. Michael Keesey), Richard J. Harris, Hans Hillewaert,
Ville Koistinen and T. Michael Keesey, Caleb M. Brown, Scott Hartman,
Chuanixn Yu, Chris huh, Shyamal, Xavier Giroux-Bougard, Smokeybjb,
vectorized by Zimices, Tasman Dixon, Apokryltaros (vectorized by T.
Michael Keesey), Christoph Schomburg, Mercedes Yrayzoz (vectorized by T.
Michael Keesey), Ghedoghedo (vectorized by T. Michael Keesey), Erika
Schumacher, Becky Barnes, Pranav Iyer (grey ideas), Jaime Headden,
Anthony Caravaggi, Tyler McCraney, Michael Scroggie, Renato de Carvalho
Ferreira, Jose Carlos Arenas-Monroy, Metalhead64 (vectorized by T.
Michael Keesey), Mattia Menchetti / Yan Wong, Alexandre Vong, Matt
Martyniuk (modified by T. Michael Keesey), Martin Kevil, Roderic Page
and Lois Page, Tauana J. Cunha, S.Martini, Birgit Lang, Ingo Braasch,
Rachel Shoop, Dein Freund der Baum (vectorized by T. Michael Keesey), M.
A. Broussard, Zimices, based in Mauricio Antón skeletal, Alexander
Schmidt-Lebuhn, Dmitry Bogdanov, J. J. Harrison (photo) & T. Michael
Keesey, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Doug Backlund
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, T. Michael Keesey (after Colin M. L. Burnett), Mathilde
Cordellier, Liftarn, Gopal Murali, Cesar Julian, John Conway, Rene
Martin, Patrick Strutzenberger, Darius Nau, Dean Schnabel, Milton Tan, M
Kolmann, Iain Reid, Tracy A. Heath, Roberto Díaz Sibaja, Zachary
Quigley, Kamil S. Jaron, Gabriela Palomo-Munoz, Manabu Sakamoto, Sam
Droege (photography) and T. Michael Keesey (vectorization), Melissa
Broussard, Christine Axon, Lukas Panzarin, Conty, Christina N. Hodson,
Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Kent Elson Sorgon, Neil Kelley, Harold
N Eyster, Mark Hannaford (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Collin Gross, Dmitry Bogdanov (vectorized
by T. Michael Keesey), Andrew A. Farke, shell lines added by Yan Wong,
Jesús Gómez, vectorized by Zimices, Oren Peles / vectorized by Yan Wong,
Andy Wilson, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Mo Hassan, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Yan Wong from wikipedia drawing (PD: Pearson Scott
Foresman), T. Michael Keesey (after Marek Velechovský), Tony Ayling,
Campbell Fleming, Sean McCann, Carlos Cano-Barbacil, NOAA (vectorized by
T. Michael Keesey), Scott Reid, Noah Schlottman, T. Michael Keesey and
Tanetahi, Curtis Clark and T. Michael Keesey, Karla Martinez, Dexter R.
Mardis, Matus Valach, Lisa Byrne, Matt Celeskey, George Edward Lodge
(modified by T. Michael Keesey), Charles Doolittle Walcott (vectorized
by T. Michael Keesey), Tony Ayling (vectorized by T. Michael Keesey),
Smokeybjb, Matt Wilkins, T. Tischler, Oliver Voigt, Maxime Dahirel,
Katie S. Collins, Stuart Humphries, Nicolas Huet le Jeune and
Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), Emily Willoughby,
CDC (Alissa Eckert; Dan Higgins), Martin R. Smith, from photo by Jürgen
Schoner, I. Sáček, Sr. (vectorized by T. Michael Keesey), Christian A.
Masnaghetti, Nobu Tamura and T. Michael Keesey, Mihai Dragos (vectorized
by T. Michael Keesey), Jay Matternes, vectorized by Zimices, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), nicubunu, Rebecca Groom, Sarah Alewijnse, Kailah
Thorn & Ben King, Yan Wong, Isaure Scavezzoni, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Noah Schlottman, photo
by Museum of Geology, University of Tartu, Ben Liebeskind, Noah
Schlottman, photo from Casey Dunn, T. Michael Keesey (after Walker &
al.), Francesca Belem Lopes Palmeira, Catherine Yasuda, Bryan Carstens,
Matt Martyniuk, Pollyanna von Knorring and T. Michael Keesey, T. Michael
Keesey (vectorization); Yves Bousquet (photography), Andreas Trepte
(vectorized by T. Michael Keesey), Hans Hillewaert (vectorized by T.
Michael Keesey), Chase Brownstein, Matt Dempsey, Mali’o Kodis, image by
Rebecca Ritger, Sergio A. Muñoz-Gómez, Lankester Edwin Ray (vectorized
by T. Michael Keesey), Raven Amos, Robbie N. Cada (vectorized by T.
Michael Keesey), Birgit Lang; based on a drawing by C.L. Koch, Original
drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja,
www.studiospectre.com, Danielle Alba, DW Bapst (Modified from Bulman,
1964), T. Michael Keesey (photo by Bc999 \[Black crow\]), Philip
Chalmers (vectorized by T. Michael Keesey), Ray Simpson (vectorized by
T. Michael Keesey), (after McCulloch 1908), Terpsichores, CNZdenek,
Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization),
Michelle Site, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), JCGiron, Alex Slavenko, Sharon Wegner-Larsen, Verdilak,
Chloé Schmidt, James R. Spotila and Ray Chatterji, M. Antonio Todaro,
Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T.
Michael Keesey), Allison Pease, Richard Ruggiero, vectorized by Zimices,
Juan Carlos Jerí, Martin R. Smith, Kimberly Haddrell, Fernando
Carezzano, Noah Schlottman, photo by Carlos Sánchez-Ortiz, (after
Spotila 2004), Jimmy Bernot, C. Abraczinskas, DW Bapst, modified from
Ishitani et al. 2016, James I. Kirkland, Luis Alcalá, Mark A. Loewen,
Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T.
Michael Keesey), Alexis Simon, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, E. R. Waite & H. M. Hale (vectorized
by T. Michael Keesey), Skye McDavid, Paul O. Lewis, Florian Pfaff,
Walter Vladimir, Joedison Rocha, Pearson Scott Foresman (vectorized by
T. Michael Keesey), Nobu Tamura, vectorized by Zimices, Arthur S. Brum,
Inessa Voet, T. Michael Keesey (from a mount by Allis Markham),
Elisabeth Östman, David Orr, xgirouxb, Brian Swartz (vectorized by T.
Michael Keesey), Steven Coombs, Marie-Aimée Allard, Trond R. Oskars,
Joschua Knüppe, Smith609 and T. Michael Keesey, Mathew Wedel, zoosnow,
SauropodomorphMonarch, Manabu Bessho-Uehara, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Chris Hay,
Andrew A. Farke, modified from original by Robert Bruce Horsfall, from
Scott 1912, T. Michael Keesey (from a photo by Maximilian Paradiz),
Archaeodontosaurus (vectorized by T. Michael Keesey), Michael Scroggie,
from original photograph by John Bettaso, USFWS (original photograph in
public domain)., Nobu Tamura, Agnello Picorelli, Lafage, Caleb M.
Gordon, U.S. National Park Service (vectorized by William Gearty),
Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey), Oscar
Sanisidro, V. Deepak, Jonathan Wells, Madeleine Price Ball, B. Duygu
Özpolat, Cristopher Silva, Josep Marti Solans, Kristina Gagalova, Matt
Martyniuk (vectorized by T. Michael Keesey), C. Camilo Julián-Caballero,
Didier Descouens (vectorized by T. Michael Keesey), A. R. McCulloch
(vectorized by T. Michael Keesey), Robert Bruce Horsfall, from W.B.
Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”,
Javier Luque, Jake Warner

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    567.359418 |    276.237594 | NA                                                                                                                                                             |
|   2 |    952.682366 |    167.397666 | Ieuan Jones                                                                                                                                                    |
|   3 |    398.133025 |    394.860916 | Steven Traver                                                                                                                                                  |
|   4 |     90.886287 |    423.284088 | L. Shyamal                                                                                                                                                     |
|   5 |    580.997898 |    184.998388 | Steven Traver                                                                                                                                                  |
|   6 |    726.918513 |    332.287802 | Joshua Fowler                                                                                                                                                  |
|   7 |    328.613142 |    134.827642 | Gareth Monger                                                                                                                                                  |
|   8 |    547.979678 |     43.111859 | Ignacio Contreras                                                                                                                                              |
|   9 |    455.188615 |    650.885071 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                              |
|  10 |    353.562675 |    703.084630 | Mareike C. Janiak                                                                                                                                              |
|  11 |    152.328738 |    709.221957 | T. Michael Keesey (after Ponomarenko)                                                                                                                          |
|  12 |    405.720113 |    238.400447 | Beth Reinke                                                                                                                                                    |
|  13 |    826.726522 |    535.171978 | Kanchi Nanjo                                                                                                                                                   |
|  14 |     95.376757 |    636.253533 | Matt Crook                                                                                                                                                     |
|  15 |    711.187465 |    732.697007 | Matthew E. Clapham                                                                                                                                             |
|  16 |    163.031578 |    125.325700 | Armin Reindl                                                                                                                                                   |
|  17 |    872.919414 |    629.811079 | NA                                                                                                                                                             |
|  18 |    569.464845 |    501.499373 | Margot Michaud                                                                                                                                                 |
|  19 |    276.381941 |    620.468745 | Margot Michaud                                                                                                                                                 |
|  20 |    357.678525 |    541.773023 | Ferran Sayol                                                                                                                                                   |
|  21 |    689.247734 |    457.419999 | Maija Karala                                                                                                                                                   |
|  22 |    545.575591 |    631.949875 | Servien (vectorized by T. Michael Keesey)                                                                                                                      |
|  23 |    764.291238 |    200.413826 | Pete Buchholz                                                                                                                                                  |
|  24 |    907.614786 |    350.996738 | NA                                                                                                                                                             |
|  25 |    652.125012 |     61.418521 | NA                                                                                                                                                             |
|  26 |    729.596865 |    635.356661 | Lily Hughes                                                                                                                                                    |
|  27 |    207.461709 |    264.176476 | Joanna Wolfe                                                                                                                                                   |
|  28 |    418.160829 |     56.355907 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  29 |    181.538232 |    405.251036 | Kai R. Caspar                                                                                                                                                  |
|  30 |    918.078717 |    482.025669 | Gareth Monger                                                                                                                                                  |
|  31 |    962.957647 |    241.604659 | Zimices                                                                                                                                                        |
|  32 |     75.181112 |    308.842000 | Felix Vaux                                                                                                                                                     |
|  33 |    502.857955 |    719.560452 | T. Michael Keesey                                                                                                                                              |
|  34 |    821.241786 |    758.222680 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  35 |    820.313729 |    279.476001 | Gareth Monger                                                                                                                                                  |
|  36 |    744.602464 |    505.046927 | Andrew A. Farke                                                                                                                                                |
|  37 |    764.917230 |    129.566291 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
|  38 |    941.184272 |    707.371837 | Margot Michaud                                                                                                                                                 |
|  39 |    894.243944 |     36.320002 | Mathieu Basille                                                                                                                                                |
|  40 |     51.086431 |    139.070313 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                       |
|  41 |    170.051528 |    223.469071 | Charles R. Knight, vectorized by Zimices                                                                                                                       |
|  42 |    217.823558 |    533.782516 | Matt Crook                                                                                                                                                     |
|  43 |    132.172237 |    489.724297 | Steven Traver                                                                                                                                                  |
|  44 |    573.389871 |    371.210472 | Markus A. Grohme                                                                                                                                               |
|  45 |    550.975664 |    406.303936 | Margot Michaud                                                                                                                                                 |
|  46 |    223.848296 |    720.896497 | Matt Crook                                                                                                                                                     |
|  47 |    291.117209 |    304.102983 | Lukasiniho                                                                                                                                                     |
|  48 |    247.400221 |     52.383179 | T. Michael Keesey                                                                                                                                              |
|  49 |    236.833240 |    205.790909 | Sarah Werning                                                                                                                                                  |
|  50 |    611.286303 |    695.547367 | Jagged Fang Designs                                                                                                                                            |
|  51 |    509.220405 |    329.013041 | Sarah Werning                                                                                                                                                  |
|  52 |    274.391966 |    465.254656 | Zimices                                                                                                                                                        |
|  53 |    959.167582 |    581.741444 | FunkMonk                                                                                                                                                       |
|  54 |     67.903736 |    762.108924 | Ignacio Contreras                                                                                                                                              |
|  55 |    899.763538 |    417.296093 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
|  56 |    624.194937 |    607.629090 | Richard J. Harris                                                                                                                                              |
|  57 |    276.752610 |    778.748649 | Steven Traver                                                                                                                                                  |
|  58 |    468.095876 |     88.456150 | Hans Hillewaert                                                                                                                                                |
|  59 |    269.001550 |    401.030791 | Ville Koistinen and T. Michael Keesey                                                                                                                          |
|  60 |    770.397682 |     90.911867 | Caleb M. Brown                                                                                                                                                 |
|  61 |    569.307290 |    576.269747 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  62 |    100.903795 |    548.415775 | Zimices                                                                                                                                                        |
|  63 |    956.502273 |    114.123217 | Scott Hartman                                                                                                                                                  |
|  64 |    620.253480 |    765.314310 | Chuanixn Yu                                                                                                                                                    |
|  65 |    420.614082 |    338.245313 | Markus A. Grohme                                                                                                                                               |
|  66 |    942.978265 |    765.577711 | Chris huh                                                                                                                                                      |
|  67 |    487.852850 |     21.757005 | Chris huh                                                                                                                                                      |
|  68 |     28.658403 |    393.749280 | T. Michael Keesey                                                                                                                                              |
|  69 |    785.225783 |     26.900427 | Shyamal                                                                                                                                                        |
|  70 |     91.456491 |     90.420597 | T. Michael Keesey                                                                                                                                              |
|  71 |    281.145870 |    559.439221 | Xavier Giroux-Bougard                                                                                                                                          |
|  72 |    362.136362 |    770.203873 | Smokeybjb, vectorized by Zimices                                                                                                                               |
|  73 |     83.999846 |     25.507697 | Tasman Dixon                                                                                                                                                   |
|  74 |    436.358985 |    155.034646 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
|  75 |    853.451656 |    156.541023 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  76 |    134.664697 |    167.957278 | Christoph Schomburg                                                                                                                                            |
|  77 |    492.121417 |    509.831494 | Gareth Monger                                                                                                                                                  |
|  78 |    826.708191 |    692.989802 | Markus A. Grohme                                                                                                                                               |
|  79 |    537.456385 |    663.837233 | Jagged Fang Designs                                                                                                                                            |
|  80 |    110.362576 |    269.724083 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                             |
|  81 |    245.197971 |     97.674137 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
|  82 |     28.980718 |    298.458164 | FunkMonk                                                                                                                                                       |
|  83 |    671.555942 |    542.944664 | Erika Schumacher                                                                                                                                               |
|  84 |    845.429586 |    346.460025 | NA                                                                                                                                                             |
|  85 |    578.244640 |    519.401231 | Becky Barnes                                                                                                                                                   |
|  86 |    621.940447 |    227.283441 | Zimices                                                                                                                                                        |
|  87 |    962.774923 |    315.683706 | Pranav Iyer (grey ideas)                                                                                                                                       |
|  88 |    972.985688 |    333.314966 | Zimices                                                                                                                                                        |
|  89 |     18.935057 |    256.987621 | T. Michael Keesey                                                                                                                                              |
|  90 |    180.723283 |    611.996849 | Jaime Headden                                                                                                                                                  |
|  91 |    974.381056 |    496.397513 | Anthony Caravaggi                                                                                                                                              |
|  92 |    626.877093 |    331.210636 | Zimices                                                                                                                                                        |
|  93 |     26.969868 |    592.651117 | Tyler McCraney                                                                                                                                                 |
|  94 |    730.890866 |    411.298790 | Matt Crook                                                                                                                                                     |
|  95 |    215.964366 |    326.447009 | Michael Scroggie                                                                                                                                               |
|  96 |    183.949449 |    467.113804 | Renato de Carvalho Ferreira                                                                                                                                    |
|  97 |    208.159730 |    679.409352 | Ferran Sayol                                                                                                                                                   |
|  98 |    554.055169 |     89.662372 | NA                                                                                                                                                             |
|  99 |    694.604994 |    224.582352 | Zimices                                                                                                                                                        |
| 100 |   1000.407636 |    320.705276 | NA                                                                                                                                                             |
| 101 |    143.438319 |    321.735270 | Matt Crook                                                                                                                                                     |
| 102 |    427.133657 |     10.252015 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 103 |    624.395877 |    413.821456 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                  |
| 104 |    497.422395 |    664.016084 | Gareth Monger                                                                                                                                                  |
| 105 |    206.020970 |    154.830237 | Margot Michaud                                                                                                                                                 |
| 106 |    727.380333 |    602.783309 | NA                                                                                                                                                             |
| 107 |    881.822013 |    131.119613 | Mattia Menchetti / Yan Wong                                                                                                                                    |
| 108 |    918.919893 |    295.202097 | Alexandre Vong                                                                                                                                                 |
| 109 |    987.575583 |    530.398274 | Jaime Headden                                                                                                                                                  |
| 110 |    102.474181 |    249.728090 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                 |
| 111 |    333.897299 |     57.735702 | Martin Kevil                                                                                                                                                   |
| 112 |    921.671342 |    382.293068 | Roderic Page and Lois Page                                                                                                                                     |
| 113 |    221.103625 |    441.526187 | NA                                                                                                                                                             |
| 114 |     59.942579 |    209.905363 | Steven Traver                                                                                                                                                  |
| 115 |    645.691206 |    350.233006 | Tauana J. Cunha                                                                                                                                                |
| 116 |    866.609889 |     48.538877 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 117 |    563.357102 |    108.147898 | Gareth Monger                                                                                                                                                  |
| 118 |    848.847104 |    461.497631 | S.Martini                                                                                                                                                      |
| 119 |    423.730057 |    434.215977 | Margot Michaud                                                                                                                                                 |
| 120 |    721.450679 |    529.418084 | Birgit Lang                                                                                                                                                    |
| 121 |    883.763518 |     86.576944 | Pete Buchholz                                                                                                                                                  |
| 122 |    775.376643 |     72.246473 | Chris huh                                                                                                                                                      |
| 123 |    869.778393 |    318.169942 | Ingo Braasch                                                                                                                                                   |
| 124 |    772.307229 |    607.984158 | Joanna Wolfe                                                                                                                                                   |
| 125 |    319.812713 |    511.856808 | Rachel Shoop                                                                                                                                                   |
| 126 |    346.575161 |    275.113882 | Ingo Braasch                                                                                                                                                   |
| 127 |     21.244939 |    638.035013 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                         |
| 128 |     63.282348 |    375.909537 | Kai R. Caspar                                                                                                                                                  |
| 129 |    294.357280 |    179.382793 | Zimices                                                                                                                                                        |
| 130 |    391.113721 |    614.291303 | M. A. Broussard                                                                                                                                                |
| 131 |     12.842709 |     38.407125 | Margot Michaud                                                                                                                                                 |
| 132 |    524.602328 |    129.775900 | Zimices                                                                                                                                                        |
| 133 |    923.663123 |    263.544544 | Matt Crook                                                                                                                                                     |
| 134 |     58.470730 |    246.958625 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 135 |    653.501927 |    173.691787 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 136 |    358.672771 |     60.067514 | Mathieu Basille                                                                                                                                                |
| 137 |    888.331830 |    293.653665 | Zimices, based in Mauricio Antón skeletal                                                                                                                      |
| 138 |    353.883343 |     41.401006 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 139 |     37.494011 |    720.120166 | Matt Crook                                                                                                                                                     |
| 140 |    730.005822 |    767.207353 | Dmitry Bogdanov                                                                                                                                                |
| 141 |     68.766019 |    493.066396 | Zimices                                                                                                                                                        |
| 142 |    961.112240 |    788.528164 | Armin Reindl                                                                                                                                                   |
| 143 |    580.592704 |    466.348157 | Ignacio Contreras                                                                                                                                              |
| 144 |    267.348846 |    155.903074 | T. Michael Keesey                                                                                                                                              |
| 145 |    688.035042 |    281.777985 | Matt Crook                                                                                                                                                     |
| 146 |    331.190589 |    507.983290 | Joanna Wolfe                                                                                                                                                   |
| 147 |     96.255881 |    221.203511 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                     |
| 148 |    957.249697 |    187.279027 | Margot Michaud                                                                                                                                                 |
| 149 |    956.903757 |     46.536220 | Gareth Monger                                                                                                                                                  |
| 150 |    959.885737 |    556.982203 | Gareth Monger                                                                                                                                                  |
| 151 |    477.880606 |    291.644693 | Lukasiniho                                                                                                                                                     |
| 152 |    882.191195 |    475.708351 | Steven Traver                                                                                                                                                  |
| 153 |    295.553076 |    734.140081 | Ieuan Jones                                                                                                                                                    |
| 154 |    203.811665 |     89.051837 | Chris huh                                                                                                                                                      |
| 155 |    794.602068 |    353.583330 | Zimices                                                                                                                                                        |
| 156 |    703.314964 |    253.955346 | Lukasiniho                                                                                                                                                     |
| 157 |    836.264099 |    439.099756 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                         |
| 158 |     46.476140 |    694.255491 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 159 |    989.896525 |     54.618573 | NA                                                                                                                                                             |
| 160 |    527.276178 |    520.333987 | Richard J. Harris                                                                                                                                              |
| 161 |    131.011972 |     73.148833 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                  |
| 162 |    598.286490 |    122.921559 | NA                                                                                                                                                             |
| 163 |    638.607793 |    447.377732 | Mathilde Cordellier                                                                                                                                            |
| 164 |    782.817521 |    415.514447 | Liftarn                                                                                                                                                        |
| 165 |     24.661552 |    175.796290 | Gopal Murali                                                                                                                                                   |
| 166 |    723.614600 |     30.054726 | Steven Traver                                                                                                                                                  |
| 167 |    380.514963 |     23.809285 | Matt Crook                                                                                                                                                     |
| 168 |    243.746714 |    312.408051 | Matt Crook                                                                                                                                                     |
| 169 |    992.072733 |    546.091634 | Cesar Julian                                                                                                                                                   |
| 170 |    563.977089 |    324.518828 | Michael Scroggie                                                                                                                                               |
| 171 |    621.529969 |    480.205833 | Jagged Fang Designs                                                                                                                                            |
| 172 |     40.597020 |    466.929185 | Matt Crook                                                                                                                                                     |
| 173 |    264.392787 |    170.836275 | Beth Reinke                                                                                                                                                    |
| 174 |    382.269756 |    152.292287 | Matt Crook                                                                                                                                                     |
| 175 |    737.451025 |    616.491717 | Margot Michaud                                                                                                                                                 |
| 176 |    254.083401 |    350.054259 | Chris huh                                                                                                                                                      |
| 177 |    491.221231 |    214.535298 | Kai R. Caspar                                                                                                                                                  |
| 178 |    831.540319 |    217.054455 | John Conway                                                                                                                                                    |
| 179 |    364.077303 |    615.884469 | Michael Scroggie                                                                                                                                               |
| 180 |    696.230638 |    771.350533 | Matt Crook                                                                                                                                                     |
| 181 |    104.297733 |    688.000340 | Zimices                                                                                                                                                        |
| 182 |    815.184851 |    429.420676 | Rene Martin                                                                                                                                                    |
| 183 |    979.912404 |    427.742248 | Patrick Strutzenberger                                                                                                                                         |
| 184 |    643.850584 |    565.712393 | Margot Michaud                                                                                                                                                 |
| 185 |    111.070431 |    781.612134 | Shyamal                                                                                                                                                        |
| 186 |    144.696988 |    427.302830 | Ingo Braasch                                                                                                                                                   |
| 187 |    332.626886 |    478.188303 | Darius Nau                                                                                                                                                     |
| 188 |    466.997143 |    184.877611 | Dean Schnabel                                                                                                                                                  |
| 189 |    115.489366 |      2.427773 | NA                                                                                                                                                             |
| 190 |    544.772304 |    594.959685 | Milton Tan                                                                                                                                                     |
| 191 |    306.886333 |    340.385487 | Chris huh                                                                                                                                                      |
| 192 |    281.315283 |    640.335213 | NA                                                                                                                                                             |
| 193 |    159.387489 |    403.691297 | Sarah Werning                                                                                                                                                  |
| 194 |    640.062859 |    218.596927 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 195 |    743.726133 |    585.633595 | Margot Michaud                                                                                                                                                 |
| 196 |    348.257937 |    400.992796 | Jagged Fang Designs                                                                                                                                            |
| 197 |    115.098589 |    115.593672 | Ferran Sayol                                                                                                                                                   |
| 198 |    140.977994 |    796.074444 | M Kolmann                                                                                                                                                      |
| 199 |    152.049346 |     68.281907 | Margot Michaud                                                                                                                                                 |
| 200 |     74.188699 |    496.685160 | Matt Crook                                                                                                                                                     |
| 201 |    621.152062 |    254.479522 | Iain Reid                                                                                                                                                      |
| 202 |    296.247475 |     65.081773 | Tracy A. Heath                                                                                                                                                 |
| 203 |    388.576364 |     75.504817 | Roberto Díaz Sibaja                                                                                                                                            |
| 204 |    963.322508 |    470.049255 | Zachary Quigley                                                                                                                                                |
| 205 |    695.642316 |    158.949730 | Kamil S. Jaron                                                                                                                                                 |
| 206 |    395.005549 |     97.735428 | L. Shyamal                                                                                                                                                     |
| 207 |    851.681552 |    135.601531 | Scott Hartman                                                                                                                                                  |
| 208 |    971.768710 |    375.325093 | Gabriela Palomo-Munoz                                                                                                                                          |
| 209 |      9.682151 |    149.547161 | Scott Hartman                                                                                                                                                  |
| 210 |    983.196874 |    268.564515 | Chris huh                                                                                                                                                      |
| 211 |    787.493706 |    509.185318 | Manabu Sakamoto                                                                                                                                                |
| 212 |   1003.750881 |    415.043335 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                 |
| 213 |    269.174844 |    727.230152 | Melissa Broussard                                                                                                                                              |
| 214 |    440.462966 |    484.536195 | Kamil S. Jaron                                                                                                                                                 |
| 215 |    265.907224 |    654.480416 | Christoph Schomburg                                                                                                                                            |
| 216 |    683.656806 |    205.497901 | Gareth Monger                                                                                                                                                  |
| 217 |    196.714636 |    649.862217 | Christine Axon                                                                                                                                                 |
| 218 |    457.896030 |     62.820182 | M Kolmann                                                                                                                                                      |
| 219 |    463.216482 |    521.901461 | Steven Traver                                                                                                                                                  |
| 220 |    502.268606 |     85.113312 | Lukas Panzarin                                                                                                                                                 |
| 221 |    864.120076 |    195.549459 | Conty                                                                                                                                                          |
| 222 |    135.411731 |    573.308951 | Christina N. Hodson                                                                                                                                            |
| 223 |    728.268048 |    697.622943 | T. Michael Keesey                                                                                                                                              |
| 224 |     59.471908 |    713.666312 | Gareth Monger                                                                                                                                                  |
| 225 |    849.666700 |    673.578298 | Steven Traver                                                                                                                                                  |
| 226 |    856.694850 |    502.157358 | Cesar Julian                                                                                                                                                   |
| 227 |    105.882905 |     87.257354 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 228 |   1003.869502 |     48.003802 | Sarah Werning                                                                                                                                                  |
| 229 |    889.934636 |     76.413882 | Matt Crook                                                                                                                                                     |
| 230 |    125.283221 |    106.175321 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                          |
| 231 |    325.865202 |     14.205282 | Kent Elson Sorgon                                                                                                                                              |
| 232 |    670.978646 |    205.182746 | Neil Kelley                                                                                                                                                    |
| 233 |    932.202335 |     61.569088 | Maija Karala                                                                                                                                                   |
| 234 |    362.244569 |    480.020086 | Harold N Eyster                                                                                                                                                |
| 235 |    948.236814 |    479.198757 | Jaime Headden                                                                                                                                                  |
| 236 |    183.551784 |    709.595918 | Gareth Monger                                                                                                                                                  |
| 237 |     50.977995 |    511.752368 | T. Michael Keesey                                                                                                                                              |
| 238 |    894.998048 |    325.506421 | Jagged Fang Designs                                                                                                                                            |
| 239 |    226.690271 |    661.353592 | Gareth Monger                                                                                                                                                  |
| 240 |    892.555043 |    243.929126 | T. Michael Keesey                                                                                                                                              |
| 241 |    623.646193 |    729.398939 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 242 |    334.273009 |    232.226773 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 243 |    181.972351 |    723.681881 | Collin Gross                                                                                                                                                   |
| 244 |    589.070634 |    727.046710 | Jagged Fang Designs                                                                                                                                            |
| 245 |    423.946807 |    533.080856 | L. Shyamal                                                                                                                                                     |
| 246 |    629.494027 |    395.595818 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 247 |    528.669750 |    604.280823 | NA                                                                                                                                                             |
| 248 |    929.023025 |    318.156565 | Gareth Monger                                                                                                                                                  |
| 249 |    539.882339 |    765.713759 | Ferran Sayol                                                                                                                                                   |
| 250 |    647.433507 |    302.223470 | Gareth Monger                                                                                                                                                  |
| 251 |    854.478371 |     32.305692 | NA                                                                                                                                                             |
| 252 |    235.594550 |     18.742983 | Jagged Fang Designs                                                                                                                                            |
| 253 |    445.036003 |     39.876205 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                 |
| 254 |    366.100563 |    510.446594 | Jesús Gómez, vectorized by Zimices                                                                                                                             |
| 255 |    724.650594 |    441.998218 | Oren Peles / vectorized by Yan Wong                                                                                                                            |
| 256 |    113.603582 |     41.667212 | Gareth Monger                                                                                                                                                  |
| 257 |    754.354223 |     64.936048 | Matt Crook                                                                                                                                                     |
| 258 |     16.877345 |    677.269246 | Andy Wilson                                                                                                                                                    |
| 259 |     23.193549 |     65.374820 | NA                                                                                                                                                             |
| 260 |     66.333540 |    423.943770 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 261 |    398.705645 |    145.472027 | Gareth Monger                                                                                                                                                  |
| 262 |    643.187377 |    337.289266 | Scott Hartman                                                                                                                                                  |
| 263 |    539.530151 |     13.535624 | Birgit Lang                                                                                                                                                    |
| 264 |    565.559351 |     57.468497 | Maija Karala                                                                                                                                                   |
| 265 |    411.956624 |    563.904657 | Gabriela Palomo-Munoz                                                                                                                                          |
| 266 |    608.956770 |     87.325927 | Erika Schumacher                                                                                                                                               |
| 267 |    391.737565 |      7.816647 | Gabriela Palomo-Munoz                                                                                                                                          |
| 268 |    941.971020 |    190.776593 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 269 |    527.861226 |    423.357049 | Mo Hassan                                                                                                                                                      |
| 270 |    319.927405 |    188.383371 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                         |
| 271 |   1003.251650 |    639.991478 | Andrew A. Farke                                                                                                                                                |
| 272 |     89.233615 |    164.806648 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                   |
| 273 |    866.116599 |    216.422213 | T. Michael Keesey (after Marek Velechovský)                                                                                                                    |
| 274 |    437.356649 |    121.743807 | Maija Karala                                                                                                                                                   |
| 275 |     36.455326 |    658.162654 | Scott Hartman                                                                                                                                                  |
| 276 |    425.599661 |    729.862600 | Kanchi Nanjo                                                                                                                                                   |
| 277 |    970.296088 |    545.856077 | Erika Schumacher                                                                                                                                               |
| 278 |    504.717498 |    685.110720 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 279 |    712.022829 |    569.555559 | Margot Michaud                                                                                                                                                 |
| 280 |    509.256544 |    580.619986 | Gabriela Palomo-Munoz                                                                                                                                          |
| 281 |    236.896897 |    359.819992 | Scott Hartman                                                                                                                                                  |
| 282 |    584.090540 |    455.266713 | Tony Ayling                                                                                                                                                    |
| 283 |   1004.312689 |     10.415756 | Zimices                                                                                                                                                        |
| 284 |    760.313925 |    792.285057 | Ferran Sayol                                                                                                                                                   |
| 285 |    254.347379 |    756.205589 | Michael Scroggie                                                                                                                                               |
| 286 |    743.469210 |    574.228030 | Matt Crook                                                                                                                                                     |
| 287 |    768.092810 |    629.008048 | Caleb M. Brown                                                                                                                                                 |
| 288 |    763.836602 |    150.216096 | Campbell Fleming                                                                                                                                               |
| 289 |    295.749019 |    656.693580 | Gareth Monger                                                                                                                                                  |
| 290 |   1011.118027 |    430.778149 | Sean McCann                                                                                                                                                    |
| 291 |    649.817624 |    204.380868 | Maija Karala                                                                                                                                                   |
| 292 |    401.342672 |    637.419892 | Collin Gross                                                                                                                                                   |
| 293 |     42.483560 |    681.327225 | Carlos Cano-Barbacil                                                                                                                                           |
| 294 |    413.291117 |    626.166588 | NOAA (vectorized by T. Michael Keesey)                                                                                                                         |
| 295 |    459.762993 |    265.931312 | Ignacio Contreras                                                                                                                                              |
| 296 |    584.480191 |    103.798312 | Margot Michaud                                                                                                                                                 |
| 297 |    976.177503 |    304.329133 | NA                                                                                                                                                             |
| 298 |    282.178136 |    698.165024 | Dmitry Bogdanov                                                                                                                                                |
| 299 |    335.293946 |    196.573382 | Gareth Monger                                                                                                                                                  |
| 300 |    683.567372 |    100.411139 | Scott Reid                                                                                                                                                     |
| 301 |    581.383880 |     87.979842 | Noah Schlottman                                                                                                                                                |
| 302 |    597.253802 |    538.282851 | T. Michael Keesey and Tanetahi                                                                                                                                 |
| 303 |    691.287242 |    408.516893 | Dean Schnabel                                                                                                                                                  |
| 304 |   1017.561376 |    499.218046 | Gareth Monger                                                                                                                                                  |
| 305 |    790.445247 |    224.779973 | Matt Crook                                                                                                                                                     |
| 306 |    552.095348 |    699.797883 | Pete Buchholz                                                                                                                                                  |
| 307 |    729.408261 |    582.356078 | Erika Schumacher                                                                                                                                               |
| 308 |    200.326297 |    430.531372 | Curtis Clark and T. Michael Keesey                                                                                                                             |
| 309 |    212.821156 |    394.728584 | NA                                                                                                                                                             |
| 310 |    576.026917 |    216.337225 | Karla Martinez                                                                                                                                                 |
| 311 |    634.436533 |    148.034377 | NA                                                                                                                                                             |
| 312 |    581.824889 |    542.278145 | Dexter R. Mardis                                                                                                                                               |
| 313 |     59.646670 |    576.370880 | Matus Valach                                                                                                                                                   |
| 314 |    915.861615 |    125.646549 | Chris huh                                                                                                                                                      |
| 315 |    202.260677 |    769.661323 | Kamil S. Jaron                                                                                                                                                 |
| 316 |   1008.270339 |     81.091328 | Lisa Byrne                                                                                                                                                     |
| 317 |    269.721648 |    186.640102 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 318 |    507.436176 |    648.597715 | Steven Traver                                                                                                                                                  |
| 319 |   1010.251481 |    402.648631 | Ferran Sayol                                                                                                                                                   |
| 320 |    715.197860 |    690.057720 | Matt Celeskey                                                                                                                                                  |
| 321 |    972.127908 |    190.746769 | Dean Schnabel                                                                                                                                                  |
| 322 |    880.427049 |    168.477113 | Margot Michaud                                                                                                                                                 |
| 323 |    915.890951 |    776.347565 | Steven Traver                                                                                                                                                  |
| 324 |     97.701774 |    739.400560 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                            |
| 325 |    261.588357 |    316.180211 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                    |
| 326 |      8.939763 |    488.684583 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 327 |    606.819263 |    666.494463 | Zimices                                                                                                                                                        |
| 328 |    179.330442 |      4.826119 | Zimices                                                                                                                                                        |
| 329 |    687.216134 |    518.794637 | Scott Hartman                                                                                                                                                  |
| 330 |    811.111555 |    341.828917 | Kamil S. Jaron                                                                                                                                                 |
| 331 |    879.097217 |    201.846990 | Sean McCann                                                                                                                                                    |
| 332 |    380.389680 |    316.659120 | Noah Schlottman                                                                                                                                                |
| 333 |    867.680197 |    570.095205 | Steven Traver                                                                                                                                                  |
| 334 |    475.420159 |    355.609739 | Jagged Fang Designs                                                                                                                                            |
| 335 |     69.076921 |    735.949106 | Tauana J. Cunha                                                                                                                                                |
| 336 |    953.943375 |    529.114738 | Andy Wilson                                                                                                                                                    |
| 337 |    146.951482 |    356.154574 | Shyamal                                                                                                                                                        |
| 338 |    979.833151 |     79.723556 | NA                                                                                                                                                             |
| 339 |    807.235859 |     56.137469 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 340 |    326.238262 |    176.321242 | Lukasiniho                                                                                                                                                     |
| 341 |    967.596015 |    619.875304 | Smokeybjb                                                                                                                                                      |
| 342 |   1006.893129 |     33.383955 | Matt Wilkins                                                                                                                                                   |
| 343 |    558.743843 |     70.997682 | T. Tischler                                                                                                                                                    |
| 344 |    349.122420 |    645.227609 | Oliver Voigt                                                                                                                                                   |
| 345 |    856.493492 |    573.231497 | Maxime Dahirel                                                                                                                                                 |
| 346 |     80.481779 |    241.486864 | NA                                                                                                                                                             |
| 347 |    620.605518 |    623.552087 | Katie S. Collins                                                                                                                                               |
| 348 |    296.420496 |    191.351597 | T. Michael Keesey                                                                                                                                              |
| 349 |    132.412075 |    372.772914 | NA                                                                                                                                                             |
| 350 |    874.199458 |    517.433103 | Joanna Wolfe                                                                                                                                                   |
| 351 |    186.858288 |    599.364863 | NA                                                                                                                                                             |
| 352 |    519.587199 |    653.265917 | Stuart Humphries                                                                                                                                               |
| 353 |    790.784158 |    485.020827 | Scott Hartman                                                                                                                                                  |
| 354 |    484.753702 |     69.926709 | Matt Crook                                                                                                                                                     |
| 355 |    216.884264 |    102.513031 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                |
| 356 |    660.558701 |    613.880568 | Emily Willoughby                                                                                                                                               |
| 357 |     51.245528 |    589.105624 | Zachary Quigley                                                                                                                                                |
| 358 |    621.688182 |    456.229214 | Anthony Caravaggi                                                                                                                                              |
| 359 |    248.869825 |    147.128073 | CDC (Alissa Eckert; Dan Higgins)                                                                                                                               |
| 360 |    726.611640 |     61.461037 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                  |
| 361 |    733.528744 |    104.635513 | Becky Barnes                                                                                                                                                   |
| 362 |    959.611294 |     70.189504 | T. Michael Keesey                                                                                                                                              |
| 363 |    589.804173 |     20.055085 | Tracy A. Heath                                                                                                                                                 |
| 364 |     58.356333 |    359.119900 | T. Michael Keesey                                                                                                                                              |
| 365 |    992.916904 |    448.146895 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                |
| 366 |    170.508460 |    643.806024 | Margot Michaud                                                                                                                                                 |
| 367 |    758.194148 |    445.812576 | Zimices                                                                                                                                                        |
| 368 |    420.084711 |    202.529998 | NA                                                                                                                                                             |
| 369 |    722.369347 |    784.414414 | Christian A. Masnaghetti                                                                                                                                       |
| 370 |    523.691064 |    440.624019 | Steven Traver                                                                                                                                                  |
| 371 |    788.645458 |    564.443565 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 372 |    184.036092 |    790.036647 | Matt Crook                                                                                                                                                     |
| 373 |    105.111508 |    196.773529 | Sean McCann                                                                                                                                                    |
| 374 |    953.312038 |      9.554258 | Gabriela Palomo-Munoz                                                                                                                                          |
| 375 |    510.900054 |     56.674087 | Scott Hartman                                                                                                                                                  |
| 376 |     31.180986 |    557.705757 | Ferran Sayol                                                                                                                                                   |
| 377 |    697.619606 |     95.490365 | Nobu Tamura and T. Michael Keesey                                                                                                                              |
| 378 |    367.796191 |    654.975089 | Markus A. Grohme                                                                                                                                               |
| 379 |    175.003032 |    631.294937 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                 |
| 380 |    752.777748 |    572.825120 | Gareth Monger                                                                                                                                                  |
| 381 |    635.393710 |    791.467062 | Andy Wilson                                                                                                                                                    |
| 382 |    960.598710 |    644.981842 | Zimices                                                                                                                                                        |
| 383 |    406.216040 |    493.123335 | Jay Matternes, vectorized by Zimices                                                                                                                           |
| 384 |    142.808780 |    290.479179 | Kai R. Caspar                                                                                                                                                  |
| 385 |    402.214412 |    710.594368 | Smokeybjb                                                                                                                                                      |
| 386 |    585.144326 |    652.775253 | Markus A. Grohme                                                                                                                                               |
| 387 |    903.580766 |    183.241417 | Jagged Fang Designs                                                                                                                                            |
| 388 |    446.067678 |    775.781342 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 389 |    534.479084 |    360.330684 | Gareth Monger                                                                                                                                                  |
| 390 |    137.285555 |    751.798296 | Sarah Werning                                                                                                                                                  |
| 391 |     51.509290 |    537.218782 | Steven Traver                                                                                                                                                  |
| 392 |    158.348120 |    360.400623 | T. Michael Keesey                                                                                                                                              |
| 393 |    435.340879 |    657.889606 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 394 |    641.367444 |    385.121426 | Jagged Fang Designs                                                                                                                                            |
| 395 |     32.385779 |    480.381251 | nicubunu                                                                                                                                                       |
| 396 |    625.241127 |    142.252741 | Rebecca Groom                                                                                                                                                  |
| 397 |    694.099706 |    561.852359 | Zimices                                                                                                                                                        |
| 398 |    721.757470 |      6.892154 | Anthony Caravaggi                                                                                                                                              |
| 399 |     38.632745 |    663.582810 | Sarah Alewijnse                                                                                                                                                |
| 400 |    422.919960 |    303.762609 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 401 |    769.206618 |    469.439949 | Scott Hartman                                                                                                                                                  |
| 402 |    996.616953 |    503.669155 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 403 |    395.249564 |    465.095868 | Armin Reindl                                                                                                                                                   |
| 404 |    364.240164 |    262.854561 | Kailah Thorn & Ben King                                                                                                                                        |
| 405 |    954.808788 |    514.755873 | Yan Wong                                                                                                                                                       |
| 406 |    169.933961 |    102.298880 | Ingo Braasch                                                                                                                                                   |
| 407 |    652.739718 |    602.977029 | Steven Traver                                                                                                                                                  |
| 408 |     91.162627 |     45.594273 | Isaure Scavezzoni                                                                                                                                              |
| 409 |    449.031842 |    210.277243 | Zimices                                                                                                                                                        |
| 410 |    641.124782 |    744.926258 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 411 |    940.939959 |    450.316976 | T. Michael Keesey                                                                                                                                              |
| 412 |    220.755061 |     13.867079 | NA                                                                                                                                                             |
| 413 |    202.293370 |    605.848514 | Kamil S. Jaron                                                                                                                                                 |
| 414 |    810.407757 |    718.479263 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 415 |    841.385480 |    200.441391 | Markus A. Grohme                                                                                                                                               |
| 416 |    492.069292 |    202.867627 | Tauana J. Cunha                                                                                                                                                |
| 417 |    403.953257 |    792.231854 | Andy Wilson                                                                                                                                                    |
| 418 |    501.660056 |    184.311417 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                               |
| 419 |    997.446322 |    184.735607 | Ben Liebeskind                                                                                                                                                 |
| 420 |    316.361183 |    658.532896 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 421 |    239.227209 |    125.359877 | T. Michael Keesey (after Walker & al.)                                                                                                                         |
| 422 |    103.926142 |    470.430450 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 423 |    920.972459 |    230.506457 | Margot Michaud                                                                                                                                                 |
| 424 |    469.606032 |    783.990020 | NA                                                                                                                                                             |
| 425 |    427.191889 |    642.704527 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 426 |    532.088454 |    682.138431 | Chris huh                                                                                                                                                      |
| 427 |   1016.246001 |    183.533018 | Gabriela Palomo-Munoz                                                                                                                                          |
| 428 |    405.759243 |    609.242878 | Markus A. Grohme                                                                                                                                               |
| 429 |     13.118966 |    140.320698 | T. Michael Keesey                                                                                                                                              |
| 430 |    961.996160 |     33.923865 | Margot Michaud                                                                                                                                                 |
| 431 |    230.326759 |    606.041179 | Chris huh                                                                                                                                                      |
| 432 |    120.431496 |     58.099971 | Francesca Belem Lopes Palmeira                                                                                                                                 |
| 433 |    853.206374 |    112.273335 | Ferran Sayol                                                                                                                                                   |
| 434 |    289.431098 |    207.624494 | NA                                                                                                                                                             |
| 435 |   1002.955969 |    476.092178 | S.Martini                                                                                                                                                      |
| 436 |    998.047301 |    382.676859 | NA                                                                                                                                                             |
| 437 |    201.481644 |    353.463253 | Joanna Wolfe                                                                                                                                                   |
| 438 |    505.515783 |    506.543354 | Zimices                                                                                                                                                        |
| 439 |    575.935049 |    236.351087 | Matt Crook                                                                                                                                                     |
| 440 |    634.337161 |    545.611329 | NA                                                                                                                                                             |
| 441 |   1002.370955 |    664.090453 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 442 |    517.508936 |    609.944816 | T. Michael Keesey                                                                                                                                              |
| 443 |    470.885382 |    514.094614 | Andy Wilson                                                                                                                                                    |
| 444 |    949.883138 |    323.057946 | Scott Hartman                                                                                                                                                  |
| 445 |    988.160547 |    364.151087 | Margot Michaud                                                                                                                                                 |
| 446 |    829.195499 |    346.880747 | Matt Crook                                                                                                                                                     |
| 447 |    559.502569 |    709.566776 | Ferran Sayol                                                                                                                                                   |
| 448 |    158.630676 |    417.893298 | NA                                                                                                                                                             |
| 449 |    999.128718 |    426.323639 | Erika Schumacher                                                                                                                                               |
| 450 |     34.278359 |    512.820272 | Gareth Monger                                                                                                                                                  |
| 451 |    920.807859 |    594.789830 | Gareth Monger                                                                                                                                                  |
| 452 |    965.474619 |    362.149639 | Matt Crook                                                                                                                                                     |
| 453 |    819.555905 |    600.918154 | Margot Michaud                                                                                                                                                 |
| 454 |    912.236717 |    417.242411 | Zimices                                                                                                                                                        |
| 455 |    708.529352 |    787.859688 | Jagged Fang Designs                                                                                                                                            |
| 456 |    682.988357 |    594.183438 | Catherine Yasuda                                                                                                                                               |
| 457 |    161.338119 |    411.061741 | Gabriela Palomo-Munoz                                                                                                                                          |
| 458 |    754.293395 |    161.263222 | Matt Crook                                                                                                                                                     |
| 459 |    570.511973 |     13.011977 | Ignacio Contreras                                                                                                                                              |
| 460 |   1011.285355 |    379.551445 | Ferran Sayol                                                                                                                                                   |
| 461 |    983.856598 |    287.497446 | Bryan Carstens                                                                                                                                                 |
| 462 |     13.100521 |    662.378112 | Matt Martyniuk                                                                                                                                                 |
| 463 |    671.314278 |    693.149564 | Matt Crook                                                                                                                                                     |
| 464 |     25.202568 |     53.561885 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                   |
| 465 |    871.891688 |    178.832301 | Zimices                                                                                                                                                        |
| 466 |    288.298333 |     89.928346 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 467 |    152.648272 |    385.264504 | Iain Reid                                                                                                                                                      |
| 468 |    824.492995 |    791.000725 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                 |
| 469 |    988.425013 |    647.048722 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                               |
| 470 |    768.377509 |    524.963809 | Lukasiniho                                                                                                                                                     |
| 471 |    787.077517 |     65.197262 | Zimices                                                                                                                                                        |
| 472 |    311.706329 |    561.742594 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 473 |    246.589976 |    334.370094 | Zimices                                                                                                                                                        |
| 474 |    431.313705 |    695.237475 | Rebecca Groom                                                                                                                                                  |
| 475 |    389.495818 |    275.003664 | NA                                                                                                                                                             |
| 476 |    475.363360 |    207.064615 | T. Michael Keesey                                                                                                                                              |
| 477 |    524.489773 |    745.615387 | Chase Brownstein                                                                                                                                               |
| 478 |    871.770460 |     98.442156 | Rebecca Groom                                                                                                                                                  |
| 479 |    653.376852 |    520.588531 | Mareike C. Janiak                                                                                                                                              |
| 480 |     16.734121 |    289.518167 | Matt Dempsey                                                                                                                                                   |
| 481 |    784.151258 |    711.434280 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                          |
| 482 |    793.478231 |    334.863525 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 483 |    487.382294 |    616.329006 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                          |
| 484 |    623.461743 |    100.795330 | Jagged Fang Designs                                                                                                                                            |
| 485 |    204.162041 |    290.297095 | Andy Wilson                                                                                                                                                    |
| 486 |    379.990629 |     84.880427 | Cesar Julian                                                                                                                                                   |
| 487 |    700.892742 |     10.501350 | NA                                                                                                                                                             |
| 488 |    791.635081 |    110.766115 | Raven Amos                                                                                                                                                     |
| 489 |     62.016366 |    791.888187 | Margot Michaud                                                                                                                                                 |
| 490 |    662.220757 |    321.680826 | NA                                                                                                                                                             |
| 491 |    800.672759 |    572.532018 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 492 |    256.069615 |    123.062263 | Gabriela Palomo-Munoz                                                                                                                                          |
| 493 |    891.145875 |    230.343274 | Ferran Sayol                                                                                                                                                   |
| 494 |     12.002468 |    723.176290 | Birgit Lang                                                                                                                                                    |
| 495 |     39.359101 |    569.589313 | Zimices                                                                                                                                                        |
| 496 |    862.281119 |    229.516698 | Ferran Sayol                                                                                                                                                   |
| 497 |    136.199506 |    154.286339 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                          |
| 498 |    351.804882 |    622.451946 | Kai R. Caspar                                                                                                                                                  |
| 499 |    653.436502 |    670.365399 | Matt Crook                                                                                                                                                     |
| 500 |    999.621210 |    555.705596 | Birgit Lang                                                                                                                                                    |
| 501 |    553.968402 |    124.714789 | Ferran Sayol                                                                                                                                                   |
| 502 |    764.718450 |    582.468480 | Kai R. Caspar                                                                                                                                                  |
| 503 |    988.473082 |    143.049747 | Ferran Sayol                                                                                                                                                   |
| 504 |    863.643869 |    426.381571 | Erika Schumacher                                                                                                                                               |
| 505 |    230.207903 |     69.002687 | Zimices                                                                                                                                                        |
| 506 |    217.897221 |    784.541603 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                   |
| 507 |     64.165251 |    629.636847 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 508 |     18.367634 |     77.749167 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                             |
| 509 |    652.661580 |    156.287290 | www.studiospectre.com                                                                                                                                          |
| 510 |    455.143063 |    757.665255 | Danielle Alba                                                                                                                                                  |
| 511 |    934.924351 |    643.155377 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 512 |    493.114976 |    437.297002 | M Kolmann                                                                                                                                                      |
| 513 |    637.214391 |    488.510813 | DW Bapst (Modified from Bulman, 1964)                                                                                                                          |
| 514 |    383.247994 |    206.538513 | NA                                                                                                                                                             |
| 515 |     49.352981 |     46.332899 | Dean Schnabel                                                                                                                                                  |
| 516 |   1002.941844 |     66.373632 | Iain Reid                                                                                                                                                      |
| 517 |    672.499472 |    387.754685 | T. Michael Keesey                                                                                                                                              |
| 518 |     64.189012 |    689.036172 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                              |
| 519 |    841.187346 |    180.826111 | Chris huh                                                                                                                                                      |
| 520 |    496.165776 |    344.230470 | Matt Crook                                                                                                                                                     |
| 521 |      9.204364 |    213.846219 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                              |
| 522 |    361.299845 |    718.392219 | Gabriela Palomo-Munoz                                                                                                                                          |
| 523 |    924.754042 |    583.902578 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                  |
| 524 |    163.070658 |    587.703594 | NA                                                                                                                                                             |
| 525 |    400.966768 |    599.293928 | Margot Michaud                                                                                                                                                 |
| 526 |    831.194310 |    468.542871 | Steven Traver                                                                                                                                                  |
| 527 |    825.549062 |    775.081725 | (after McCulloch 1908)                                                                                                                                         |
| 528 |    968.337803 |    285.375533 | Terpsichores                                                                                                                                                   |
| 529 |    668.550379 |    566.803647 | Ferran Sayol                                                                                                                                                   |
| 530 |    205.563417 |    113.755254 | Margot Michaud                                                                                                                                                 |
| 531 |    516.377602 |    108.215015 | Jagged Fang Designs                                                                                                                                            |
| 532 |    561.856893 |    725.533721 | Matt Crook                                                                                                                                                     |
| 533 |     15.422671 |    527.922539 | CNZdenek                                                                                                                                                       |
| 534 |    757.496394 |    606.421672 | Gabriela Palomo-Munoz                                                                                                                                          |
| 535 |    432.665921 |    313.817071 | Dean Schnabel                                                                                                                                                  |
| 536 |    934.949441 |     72.662329 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 537 |    756.626150 |    704.417059 | Gabriela Palomo-Munoz                                                                                                                                          |
| 538 |    346.531041 |    248.181301 | Pete Buchholz                                                                                                                                                  |
| 539 |     28.663973 |    467.122057 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                         |
| 540 |    968.448537 |    601.696728 | T. Michael Keesey                                                                                                                                              |
| 541 |    720.110942 |     50.943412 | T. Michael Keesey                                                                                                                                              |
| 542 |    620.698919 |    791.128357 | Michelle Site                                                                                                                                                  |
| 543 |    947.883669 |    411.291493 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                              |
| 544 |    278.048980 |    156.887550 | Gareth Monger                                                                                                                                                  |
| 545 |     16.077447 |    310.525256 | NA                                                                                                                                                             |
| 546 |    522.635585 |    556.032004 | JCGiron                                                                                                                                                        |
| 547 |     17.573089 |    300.396650 | Alex Slavenko                                                                                                                                                  |
| 548 |    218.760266 |    586.695048 | Sharon Wegner-Larsen                                                                                                                                           |
| 549 |    537.994413 |    704.442608 | Zimices                                                                                                                                                        |
| 550 |    258.651682 |    243.205241 | NA                                                                                                                                                             |
| 551 |    534.745793 |     72.672231 | NA                                                                                                                                                             |
| 552 |    899.218426 |    730.955495 | Verdilak                                                                                                                                                       |
| 553 |    631.239889 |    675.282307 | T. Michael Keesey                                                                                                                                              |
| 554 |    877.662733 |     57.740162 | Chloé Schmidt                                                                                                                                                  |
| 555 |    224.830873 |    303.548091 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 556 |    864.573511 |    794.529523 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 557 |    382.277157 |    134.673942 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                       |
| 558 |    593.212348 |    340.962424 | Allison Pease                                                                                                                                                  |
| 559 |    130.421631 |     44.143791 | T. Michael Keesey                                                                                                                                              |
| 560 |     87.750318 |    789.133396 | Matt Crook                                                                                                                                                     |
| 561 |    115.300403 |    312.689655 | Richard Ruggiero, vectorized by Zimices                                                                                                                        |
| 562 |   1021.009366 |    691.349158 | Gareth Monger                                                                                                                                                  |
| 563 |    738.313161 |    686.698265 | T. Michael Keesey                                                                                                                                              |
| 564 |     35.040636 |    608.707918 | Juan Carlos Jerí                                                                                                                                               |
| 565 |    118.876290 |    629.534180 | NA                                                                                                                                                             |
| 566 |    136.381892 |    253.642275 | Ferran Sayol                                                                                                                                                   |
| 567 |   1003.865385 |    598.162360 | Kamil S. Jaron                                                                                                                                                 |
| 568 |    341.000733 |    576.897734 | Ignacio Contreras                                                                                                                                              |
| 569 |    153.800317 |    420.765092 | Jagged Fang Designs                                                                                                                                            |
| 570 |    323.490549 |    249.042392 | Martin R. Smith                                                                                                                                                |
| 571 |    211.309189 |    364.380911 | Steven Traver                                                                                                                                                  |
| 572 |    706.509003 |    507.232343 | Zimices                                                                                                                                                        |
| 573 |     64.830558 |    591.899134 | Gareth Monger                                                                                                                                                  |
| 574 |    576.077894 |    717.103760 | Steven Traver                                                                                                                                                  |
| 575 |    229.410096 |    379.573090 | Markus A. Grohme                                                                                                                                               |
| 576 |    191.760879 |    664.006780 | Harold N Eyster                                                                                                                                                |
| 577 |    472.986619 |    527.991512 | Matt Crook                                                                                                                                                     |
| 578 |    879.622663 |    490.538372 | Kimberly Haddrell                                                                                                                                              |
| 579 |    441.891427 |    788.812848 | Fernando Carezzano                                                                                                                                             |
| 580 |    308.959427 |    202.538636 | www.studiospectre.com                                                                                                                                          |
| 581 |    646.489724 |    163.530833 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                 |
| 582 |    396.024110 |    352.956085 | Chris huh                                                                                                                                                      |
| 583 |    798.105619 |    616.032310 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 584 |    161.686349 |    326.573634 | Zimices                                                                                                                                                        |
| 585 |    218.174352 |    386.369236 | (after Spotila 2004)                                                                                                                                           |
| 586 |    507.026802 |    195.812677 | Birgit Lang                                                                                                                                                    |
| 587 |    871.236004 |    543.911053 | Zimices                                                                                                                                                        |
| 588 |    902.713648 |    189.819051 | Jimmy Bernot                                                                                                                                                   |
| 589 |    765.737601 |    740.243078 | C. Abraczinskas                                                                                                                                                |
| 590 |    865.001355 |     70.470851 | NA                                                                                                                                                             |
| 591 |    128.587479 |    616.175727 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                   |
| 592 |    527.509652 |    696.230004 | Armin Reindl                                                                                                                                                   |
| 593 |    679.502623 |    400.770721 | Jaime Headden                                                                                                                                                  |
| 594 |     97.215737 |    722.910436 | Steven Traver                                                                                                                                                  |
| 595 |    222.088658 |     86.987809 | NA                                                                                                                                                             |
| 596 |    601.690560 |     13.583961 | Ferran Sayol                                                                                                                                                   |
| 597 |    781.166914 |    390.172580 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 598 |    777.179715 |    437.044615 | Zimices                                                                                                                                                        |
| 599 |    346.572875 |    561.010300 | NA                                                                                                                                                             |
| 600 |    588.210645 |    320.075696 | Margot Michaud                                                                                                                                                 |
| 601 |    448.439312 |    190.896151 | Ferran Sayol                                                                                                                                                   |
| 602 |    307.155548 |    643.212281 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                           |
| 603 |    135.282324 |    783.417100 | Margot Michaud                                                                                                                                                 |
| 604 |    738.686258 |    787.314965 | Christoph Schomburg                                                                                                                                            |
| 605 |    174.091521 |     92.596297 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 606 |    818.128655 |    617.290143 | Gabriela Palomo-Munoz                                                                                                                                          |
| 607 |    423.857484 |    568.967729 | Alexis Simon                                                                                                                                                   |
| 608 |    599.022193 |     44.620488 | NA                                                                                                                                                             |
| 609 |     65.252878 |     43.370578 | Felix Vaux                                                                                                                                                     |
| 610 |    804.369226 |    666.251316 | Gareth Monger                                                                                                                                                  |
| 611 |    183.716536 |    305.000606 | Jaime Headden                                                                                                                                                  |
| 612 |    282.557186 |    335.402654 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                         |
| 613 |    458.512895 |    493.837316 | Kamil S. Jaron                                                                                                                                                 |
| 614 |    229.413790 |    208.522650 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
| 615 |    758.083777 |    425.688677 | Collin Gross                                                                                                                                                   |
| 616 |    514.135352 |     92.816190 | NA                                                                                                                                                             |
| 617 |    822.649900 |    109.602572 | NA                                                                                                                                                             |
| 618 |    662.391957 |    366.579312 | Joanna Wolfe                                                                                                                                                   |
| 619 |    736.140219 |    219.160691 | Skye McDavid                                                                                                                                                   |
| 620 |    774.794544 |    458.955205 | Gareth Monger                                                                                                                                                  |
| 621 |    504.374923 |    122.004484 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 622 |    326.298881 |    161.294764 | Matt Crook                                                                                                                                                     |
| 623 |    970.493818 |     21.796388 | Gareth Monger                                                                                                                                                  |
| 624 |     53.590901 |    429.682285 | Zimices                                                                                                                                                        |
| 625 |    873.372825 |    230.912620 | NA                                                                                                                                                             |
| 626 |    227.752932 |    349.604184 | Matt Crook                                                                                                                                                     |
| 627 |    948.925111 |    336.648176 | Margot Michaud                                                                                                                                                 |
| 628 |    445.207811 |    675.382739 | Margot Michaud                                                                                                                                                 |
| 629 |    998.117427 |    593.999443 | Smokeybjb                                                                                                                                                      |
| 630 |    166.100204 |     56.108622 | Paul O. Lewis                                                                                                                                                  |
| 631 |    661.619791 |    780.834401 | Gareth Monger                                                                                                                                                  |
| 632 |     73.175308 |    138.908901 | Florian Pfaff                                                                                                                                                  |
| 633 |    719.652308 |    479.004306 | Margot Michaud                                                                                                                                                 |
| 634 |    581.245667 |    303.541946 | Birgit Lang                                                                                                                                                    |
| 635 |    110.268595 |     66.273096 | Ferran Sayol                                                                                                                                                   |
| 636 |    638.686267 |    483.794723 | Walter Vladimir                                                                                                                                                |
| 637 |    701.977110 |    517.649119 | Joedison Rocha                                                                                                                                                 |
| 638 |    952.194675 |    664.156105 | Steven Traver                                                                                                                                                  |
| 639 |    104.417317 |    241.129069 | Gareth Monger                                                                                                                                                  |
| 640 |    405.804595 |    742.037267 | Steven Traver                                                                                                                                                  |
| 641 |    136.848823 |    391.435934 | Armin Reindl                                                                                                                                                   |
| 642 |    423.917340 |    786.287649 | Scott Hartman                                                                                                                                                  |
| 643 |    950.941498 |     57.146408 | Tasman Dixon                                                                                                                                                   |
| 644 |    319.192193 |    768.530699 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                       |
| 645 |    297.883050 |     27.044770 | Zimices                                                                                                                                                        |
| 646 |    933.344885 |    294.857563 | Melissa Broussard                                                                                                                                              |
| 647 |    537.819458 |      7.392063 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 648 |    312.525907 |    429.583328 | Christoph Schomburg                                                                                                                                            |
| 649 |    518.865855 |    357.431288 | S.Martini                                                                                                                                                      |
| 650 |    508.441223 |    480.047958 | Birgit Lang                                                                                                                                                    |
| 651 |    670.639865 |    306.922629 | Matt Crook                                                                                                                                                     |
| 652 |    988.410703 |    470.568561 | Dean Schnabel                                                                                                                                                  |
| 653 |     87.295685 |    135.865074 | Arthur S. Brum                                                                                                                                                 |
| 654 |    973.854904 |    207.740949 | Michael Scroggie                                                                                                                                               |
| 655 |    859.923483 |    556.682432 | Ferran Sayol                                                                                                                                                   |
| 656 |    836.461161 |    107.023454 | Inessa Voet                                                                                                                                                    |
| 657 |    384.770818 |    655.134795 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                              |
| 658 |    690.186371 |    197.167464 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                             |
| 659 |    716.948110 |    758.758493 | Neil Kelley                                                                                                                                                    |
| 660 |    459.415800 |    282.946120 | Elisabeth Östman                                                                                                                                               |
| 661 |    260.897083 |     90.720294 | Gareth Monger                                                                                                                                                  |
| 662 |    787.732620 |    768.522388 | T. Michael Keesey                                                                                                                                              |
| 663 |    123.983893 |    461.375957 | David Orr                                                                                                                                                      |
| 664 |    341.153768 |    417.945638 | Matt Crook                                                                                                                                                     |
| 665 |   1013.079452 |     95.232078 | Matt Crook                                                                                                                                                     |
| 666 |    504.686658 |    314.743068 | Tracy A. Heath                                                                                                                                                 |
| 667 |    916.174339 |    577.199449 | Steven Traver                                                                                                                                                  |
| 668 |     91.093774 |    699.342714 | Christoph Schomburg                                                                                                                                            |
| 669 |    383.281205 |    492.016740 | Chris huh                                                                                                                                                      |
| 670 |    718.180560 |    551.218110 | Rebecca Groom                                                                                                                                                  |
| 671 |    460.097678 |    546.721175 | xgirouxb                                                                                                                                                       |
| 672 |    887.028491 |    306.602942 | Andy Wilson                                                                                                                                                    |
| 673 |    149.231101 |    108.901615 | Mathieu Basille                                                                                                                                                |
| 674 |    886.277397 |    578.085929 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                 |
| 675 |    681.715483 |    174.309912 | Markus A. Grohme                                                                                                                                               |
| 676 |    273.942233 |    739.592132 | Matt Crook                                                                                                                                                     |
| 677 |     22.924638 |     42.784220 | Matt Crook                                                                                                                                                     |
| 678 |    482.627188 |    181.685051 | NA                                                                                                                                                             |
| 679 |    887.733674 |     72.903983 | Jagged Fang Designs                                                                                                                                            |
| 680 |    918.612629 |    674.282791 | Matt Crook                                                                                                                                                     |
| 681 |   1009.754311 |    699.541872 | Katie S. Collins                                                                                                                                               |
| 682 |    373.310157 |    741.116134 | NA                                                                                                                                                             |
| 683 |    331.046255 |    657.764879 | Gareth Monger                                                                                                                                                  |
| 684 |    760.246062 |    392.542471 | NA                                                                                                                                                             |
| 685 |   1015.088338 |    581.316555 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 686 |    332.249312 |    625.049915 | Steven Coombs                                                                                                                                                  |
| 687 |    286.990717 |     14.897423 | NA                                                                                                                                                             |
| 688 |    500.908421 |     98.989298 | Marie-Aimée Allard                                                                                                                                             |
| 689 |     61.473297 |    498.545899 | Maxime Dahirel                                                                                                                                                 |
| 690 |    415.504957 |    449.290842 | Birgit Lang                                                                                                                                                    |
| 691 |     12.485082 |    619.068180 | Zimices                                                                                                                                                        |
| 692 |    422.105504 |    194.264725 | Matt Crook                                                                                                                                                     |
| 693 |    822.818906 |     63.957922 | Scott Hartman                                                                                                                                                  |
| 694 |    406.483584 |    113.853869 | Gareth Monger                                                                                                                                                  |
| 695 |    150.432507 |    516.826658 | Maija Karala                                                                                                                                                   |
| 696 |    586.400425 |    736.867762 | Jagged Fang Designs                                                                                                                                            |
| 697 |    805.616145 |    627.044790 | Margot Michaud                                                                                                                                                 |
| 698 |    614.751068 |    356.417276 | Trond R. Oskars                                                                                                                                                |
| 699 |    135.656548 |     88.630202 | Shyamal                                                                                                                                                        |
| 700 |    320.490414 |    210.386148 | Matt Crook                                                                                                                                                     |
| 701 |    481.275876 |    758.917209 | Chase Brownstein                                                                                                                                               |
| 702 |     10.420820 |    111.721672 | Joanna Wolfe                                                                                                                                                   |
| 703 |    223.901715 |    123.498469 | Ferran Sayol                                                                                                                                                   |
| 704 |    891.663563 |    498.191306 | Mathilde Cordellier                                                                                                                                            |
| 705 |    528.320807 |    346.832656 | Tracy A. Heath                                                                                                                                                 |
| 706 |    981.095035 |    669.103076 | Jagged Fang Designs                                                                                                                                            |
| 707 |    144.331151 |     49.714400 | Emily Willoughby                                                                                                                                               |
| 708 |    870.791394 |    716.823022 | Zimices                                                                                                                                                        |
| 709 |    743.764667 |     43.727048 | Martin R. Smith                                                                                                                                                |
| 710 |    963.935247 |    137.439442 | Margot Michaud                                                                                                                                                 |
| 711 |    825.368645 |    712.106496 | Joschua Knüppe                                                                                                                                                 |
| 712 |    177.642067 |    619.719301 | T. Tischler                                                                                                                                                    |
| 713 |   1012.800275 |    784.606263 | Gabriela Palomo-Munoz                                                                                                                                          |
| 714 |    805.303889 |    417.989866 | Ferran Sayol                                                                                                                                                   |
| 715 |    888.153371 |    670.058848 | Steven Traver                                                                                                                                                  |
| 716 |    177.014224 |    332.183045 | Noah Schlottman                                                                                                                                                |
| 717 |    198.005266 |    791.307165 | Katie S. Collins                                                                                                                                               |
| 718 |    503.032565 |    138.281720 | Gabriela Palomo-Munoz                                                                                                                                          |
| 719 |    801.748803 |    676.584617 | Caleb M. Brown                                                                                                                                                 |
| 720 |    852.560727 |     13.395399 | Ferran Sayol                                                                                                                                                   |
| 721 |     79.505260 |    388.845946 | Smith609 and T. Michael Keesey                                                                                                                                 |
| 722 |    425.190964 |    493.917938 | Andrew A. Farke                                                                                                                                                |
| 723 |    628.851492 |    513.030900 | Steven Traver                                                                                                                                                  |
| 724 |    903.723786 |    116.732071 | Margot Michaud                                                                                                                                                 |
| 725 |    413.106782 |    133.615491 | Gareth Monger                                                                                                                                                  |
| 726 |    447.856299 |    501.728800 | Mathew Wedel                                                                                                                                                   |
| 727 |    406.522555 |    701.433425 | Lukas Panzarin                                                                                                                                                 |
| 728 |    349.718912 |    632.594784 | Gabriela Palomo-Munoz                                                                                                                                          |
| 729 |    346.048715 |     73.224669 | T. Michael Keesey                                                                                                                                              |
| 730 |    194.283824 |    703.177288 | T. Michael Keesey                                                                                                                                              |
| 731 |    633.566454 |    552.519625 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 732 |    416.830230 |     29.165223 | Erika Schumacher                                                                                                                                               |
| 733 |    397.496451 |    318.081368 | Manabu Sakamoto                                                                                                                                                |
| 734 |    755.872507 |    775.430039 | Zimices                                                                                                                                                        |
| 735 |    796.628864 |    458.177368 | zoosnow                                                                                                                                                        |
| 736 |    337.586920 |    261.174060 | T. Michael Keesey                                                                                                                                              |
| 737 |    399.099264 |     18.926936 | SauropodomorphMonarch                                                                                                                                          |
| 738 |     77.227805 |    721.927413 | Matt Martyniuk                                                                                                                                                 |
| 739 |    265.208200 |    143.990699 | Gabriela Palomo-Munoz                                                                                                                                          |
| 740 |    413.641493 |    123.257799 | Gabriela Palomo-Munoz                                                                                                                                          |
| 741 |    119.370244 |    177.608373 | Steven Traver                                                                                                                                                  |
| 742 |    109.895789 |    678.921941 | NA                                                                                                                                                             |
| 743 |    825.118147 |     81.466628 | Matt Crook                                                                                                                                                     |
| 744 |    748.056159 |    762.550244 | Jagged Fang Designs                                                                                                                                            |
| 745 |    919.242875 |    246.088280 | T. Michael Keesey                                                                                                                                              |
| 746 |    684.578193 |     86.778809 | Sharon Wegner-Larsen                                                                                                                                           |
| 747 |    974.167437 |    747.023736 | Tauana J. Cunha                                                                                                                                                |
| 748 |    149.482492 |    446.705029 | NA                                                                                                                                                             |
| 749 |    991.133212 |     31.829443 | Xavier Giroux-Bougard                                                                                                                                          |
| 750 |    773.044153 |    710.918792 | Scott Hartman                                                                                                                                                  |
| 751 |    342.185769 |    213.691297 | Steven Traver                                                                                                                                                  |
| 752 |    282.419311 |    490.698727 | Terpsichores                                                                                                                                                   |
| 753 |    203.420914 |    622.304146 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                       |
| 754 |    591.909351 |    793.413194 | Beth Reinke                                                                                                                                                    |
| 755 |    494.666558 |    592.524473 | Manabu Bessho-Uehara                                                                                                                                           |
| 756 |    505.682929 |    565.764386 | Chris huh                                                                                                                                                      |
| 757 |     28.291626 |    710.825009 | Jagged Fang Designs                                                                                                                                            |
| 758 |    481.325304 |    138.358526 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 759 |     29.595606 |    319.421945 | Beth Reinke                                                                                                                                                    |
| 760 |    555.372336 |    689.918200 | Margot Michaud                                                                                                                                                 |
| 761 |    505.106401 |    465.566457 | NA                                                                                                                                                             |
| 762 |    828.911674 |    142.480038 | Emily Willoughby                                                                                                                                               |
| 763 |    592.377008 |    787.529467 | Margot Michaud                                                                                                                                                 |
| 764 |    456.014997 |    155.809756 | Matt Crook                                                                                                                                                     |
| 765 |    241.179627 |    374.928967 | Chris huh                                                                                                                                                      |
| 766 |    906.356560 |    591.705896 | NA                                                                                                                                                             |
| 767 |    805.029707 |    650.265880 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 768 |    462.671655 |    535.591210 | Margot Michaud                                                                                                                                                 |
| 769 |    471.741731 |    160.422429 | Rachel Shoop                                                                                                                                                   |
| 770 |    290.067567 |    356.341429 | T. Michael Keesey                                                                                                                                              |
| 771 |    761.030282 |     46.836501 | Tracy A. Heath                                                                                                                                                 |
| 772 |    511.969206 |    345.399411 | Matt Crook                                                                                                                                                     |
| 773 |    115.446156 |    289.610581 | Chris Hay                                                                                                                                                      |
| 774 |    466.876761 |    541.376183 | Chris huh                                                                                                                                                      |
| 775 |    135.306989 |    401.905663 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                              |
| 776 |    764.321015 |    239.888432 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 777 |    882.031311 |    186.408430 | Jagged Fang Designs                                                                                                                                            |
| 778 |    306.491220 |    790.438428 | Steven Traver                                                                                                                                                  |
| 779 |    184.643224 |    114.306327 | Ferran Sayol                                                                                                                                                   |
| 780 |    490.807763 |    789.277841 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                         |
| 781 |    290.401951 |    580.369656 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                           |
| 782 |    741.791611 |    435.510334 | Arthur S. Brum                                                                                                                                                 |
| 783 |    450.742261 |    458.158138 | Jaime Headden                                                                                                                                                  |
| 784 |    638.219629 |    499.012991 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 785 |    638.617670 |    715.057176 | Xavier Giroux-Bougard                                                                                                                                          |
| 786 |    799.032058 |      3.305487 | Gareth Monger                                                                                                                                                  |
| 787 |    397.174908 |    132.075848 | Matt Crook                                                                                                                                                     |
| 788 |    119.802217 |    329.803463 | Chuanixn Yu                                                                                                                                                    |
| 789 |    632.545551 |    532.587735 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 790 |    830.820858 |      6.315632 | Margot Michaud                                                                                                                                                 |
| 791 |    541.334769 |    671.498312 | T. Michael Keesey                                                                                                                                              |
| 792 |    728.999340 |    199.396359 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                      |
| 793 |    542.700773 |    715.191962 | Gabriela Palomo-Munoz                                                                                                                                          |
| 794 |    279.522002 |    520.406953 | Margot Michaud                                                                                                                                                 |
| 795 |    962.878572 |    415.588495 | Scott Reid                                                                                                                                                     |
| 796 |    411.074949 |    649.672814 | Tasman Dixon                                                                                                                                                   |
| 797 |    957.600472 |    201.922621 | Andy Wilson                                                                                                                                                    |
| 798 |    860.211751 |    342.726543 | Tracy A. Heath                                                                                                                                                 |
| 799 |    248.972863 |      6.443446 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 800 |    704.720461 |    392.659953 | L. Shyamal                                                                                                                                                     |
| 801 |    316.202673 |    240.043424 | Nobu Tamura                                                                                                                                                    |
| 802 |    288.979929 |    214.499516 | Birgit Lang                                                                                                                                                    |
| 803 |    772.016363 |    570.761992 | NA                                                                                                                                                             |
| 804 |    307.970775 |    769.414610 | Agnello Picorelli                                                                                                                                              |
| 805 |    701.841620 |    581.639821 | Maxime Dahirel                                                                                                                                                 |
| 806 |    825.081689 |     49.444015 | xgirouxb                                                                                                                                                       |
| 807 |    879.270243 |    459.938787 | Andy Wilson                                                                                                                                                    |
| 808 |    691.141304 |    553.588328 | Lafage                                                                                                                                                         |
| 809 |     11.427960 |    159.324756 | Matt Crook                                                                                                                                                     |
| 810 |    843.952131 |    713.994883 | Caleb M. Gordon                                                                                                                                                |
| 811 |   1005.607139 |    723.577202 | U.S. National Park Service (vectorized by William Gearty)                                                                                                      |
| 812 |    418.686675 |    612.820522 | Scott Hartman                                                                                                                                                  |
| 813 |    774.421764 |     10.789204 | Zimices                                                                                                                                                        |
| 814 |    491.377444 |    304.698331 | Ferran Sayol                                                                                                                                                   |
| 815 |    894.229574 |    680.442618 | NA                                                                                                                                                             |
| 816 |      7.229402 |    413.859176 | Anthony Caravaggi                                                                                                                                              |
| 817 |    257.785258 |     15.352326 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                     |
| 818 |    717.645355 |    230.763341 | Oscar Sanisidro                                                                                                                                                |
| 819 |    519.991401 |    314.006428 | Zimices                                                                                                                                                        |
| 820 |    983.495549 |    632.474641 | V. Deepak                                                                                                                                                      |
| 821 |    884.226747 |    563.923833 | Margot Michaud                                                                                                                                                 |
| 822 |    279.694054 |    351.709061 | Steven Traver                                                                                                                                                  |
| 823 |    886.337715 |    756.786870 | Felix Vaux                                                                                                                                                     |
| 824 |    571.911016 |    130.749311 | Steven Traver                                                                                                                                                  |
| 825 |    607.589273 |    464.992299 | Jonathan Wells                                                                                                                                                 |
| 826 |    635.753941 |    312.406486 | Erika Schumacher                                                                                                                                               |
| 827 |    689.044205 |    109.841367 | Madeleine Price Ball                                                                                                                                           |
| 828 |    977.076779 |    409.980162 | B. Duygu Özpolat                                                                                                                                               |
| 829 |    888.751932 |    382.060137 | Gabriela Palomo-Munoz                                                                                                                                          |
| 830 |    642.670086 |    463.277062 | Gabriela Palomo-Munoz                                                                                                                                          |
| 831 |    716.694137 |    217.691569 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 832 |    447.669614 |    523.854519 | Steven Traver                                                                                                                                                  |
| 833 |    211.868568 |    758.489203 | NA                                                                                                                                                             |
| 834 |    702.065513 |    555.592082 | Matt Wilkins                                                                                                                                                   |
| 835 |    587.787145 |    207.831279 | Michelle Site                                                                                                                                                  |
| 836 |    931.424347 |    411.556288 | Cristopher Silva                                                                                                                                               |
| 837 |    692.249845 |    392.590087 | Gareth Monger                                                                                                                                                  |
| 838 |    289.339867 |    368.990701 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 839 |    844.986074 |    415.580007 | Gareth Monger                                                                                                                                                  |
| 840 |    951.185238 |    494.085176 | T. Michael Keesey                                                                                                                                              |
| 841 |    121.783140 |     94.627809 | Caleb M. Brown                                                                                                                                                 |
| 842 |    507.802780 |    603.915779 | Matt Crook                                                                                                                                                     |
| 843 |    336.532673 |     96.294334 | Neil Kelley                                                                                                                                                    |
| 844 |    671.783732 |      4.217659 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                         |
| 845 |    270.691759 |    103.796676 | T. Michael Keesey                                                                                                                                              |
| 846 |    972.462441 |    124.699830 | Josep Marti Solans                                                                                                                                             |
| 847 |    866.415533 |    672.482950 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 848 |    957.763329 |    455.112234 | Michelle Site                                                                                                                                                  |
| 849 |    115.224793 |    475.523321 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 850 |    176.961466 |    142.065261 | Matt Crook                                                                                                                                                     |
| 851 |    562.000932 |    786.365419 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                              |
| 852 |    244.894508 |    575.604767 | Margot Michaud                                                                                                                                                 |
| 853 |    799.918060 |    436.512860 | Scott Hartman                                                                                                                                                  |
| 854 |    933.082023 |    431.737091 | Matt Celeskey                                                                                                                                                  |
| 855 |    899.580096 |    308.256416 | Anthony Caravaggi                                                                                                                                              |
| 856 |    522.517955 |    190.055888 | T. Michael Keesey                                                                                                                                              |
| 857 |    654.548343 |    407.142319 | NA                                                                                                                                                             |
| 858 |    979.567498 |     17.291892 | Maija Karala                                                                                                                                                   |
| 859 |     12.402585 |    322.601120 | Matt Crook                                                                                                                                                     |
| 860 |    432.363217 |    670.335122 | Kristina Gagalova                                                                                                                                              |
| 861 |    252.506672 |    164.813938 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                               |
| 862 |    463.537831 |    467.082884 | Zimices                                                                                                                                                        |
| 863 |   1006.680503 |    436.919183 | C. Camilo Julián-Caballero                                                                                                                                     |
| 864 |      9.278496 |    687.507590 | FunkMonk                                                                                                                                                       |
| 865 |    627.941258 |    131.028302 | Sarah Werning                                                                                                                                                  |
| 866 |    277.983800 |    431.452748 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 867 |    473.907340 |    347.533019 | Cesar Julian                                                                                                                                                   |
| 868 |    652.735472 |    240.636458 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                             |
| 869 |    719.052267 |    392.209907 | Ferran Sayol                                                                                                                                                   |
| 870 |     33.629714 |    223.664493 | Gabriela Palomo-Munoz                                                                                                                                          |
| 871 |    747.339862 |    269.114049 | Gabriela Palomo-Munoz                                                                                                                                          |
| 872 |     39.380582 |    491.696587 | Michelle Site                                                                                                                                                  |
| 873 |    541.490749 |    540.048131 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 874 |    620.288659 |    435.487699 | Steven Traver                                                                                                                                                  |
| 875 |    139.627549 |    309.314515 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                              |
| 876 |    769.368569 |    401.226070 | NA                                                                                                                                                             |
| 877 |    462.639812 |     67.494754 | NA                                                                                                                                                             |
| 878 |    282.056990 |    710.781981 | Steven Traver                                                                                                                                                  |
| 879 |    830.119377 |    423.415471 | NA                                                                                                                                                             |
| 880 |    972.659081 |    518.094976 | Jagged Fang Designs                                                                                                                                            |
| 881 |    307.882445 |    493.930185 | Beth Reinke                                                                                                                                                    |
| 882 |    353.060704 |     82.220582 | Matt Crook                                                                                                                                                     |
| 883 |    440.683290 |    510.809559 | NA                                                                                                                                                             |
| 884 |    324.494999 |    589.722698 | Lukas Panzarin                                                                                                                                                 |
| 885 |    889.008933 |    265.105104 | NA                                                                                                                                                             |
| 886 |    182.148195 |    536.626804 | Jagged Fang Designs                                                                                                                                            |
| 887 |    857.165530 |    162.121563 | Collin Gross                                                                                                                                                   |
| 888 |    414.394332 |    668.955901 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                            |
| 889 |    470.598681 |    738.781086 | Margot Michaud                                                                                                                                                 |
| 890 |    166.354348 |    563.988641 | Gareth Monger                                                                                                                                                  |
| 891 |    571.285851 |    118.606185 | Matt Crook                                                                                                                                                     |
| 892 |     45.566972 |    356.124735 | Campbell Fleming                                                                                                                                               |
| 893 |    733.139376 |     45.631798 | Markus A. Grohme                                                                                                                                               |
| 894 |   1015.104413 |    612.267952 | Zimices                                                                                                                                                        |
| 895 |    894.948297 |    748.185819 | Nobu Tamura                                                                                                                                                    |
| 896 |    422.756086 |    749.827549 | Juan Carlos Jerí                                                                                                                                               |
| 897 |    423.999850 |    681.439383 | Steven Traver                                                                                                                                                  |
| 898 |    611.263004 |     60.931954 | Pete Buchholz                                                                                                                                                  |
| 899 |    128.415201 |    143.327712 | Tauana J. Cunha                                                                                                                                                |
| 900 |    403.994993 |    661.461636 | Chris huh                                                                                                                                                      |
| 901 |    817.719747 |    673.417183 | Kamil S. Jaron                                                                                                                                                 |
| 902 |    420.280581 |    103.915161 | Javier Luque                                                                                                                                                   |
| 903 |    905.262233 |     74.981596 | Gareth Monger                                                                                                                                                  |
| 904 |   1002.077118 |    459.287687 | T. Michael Keesey                                                                                                                                              |
| 905 |    602.245438 |     72.516672 | Andy Wilson                                                                                                                                                    |
| 906 |    196.507029 |    669.671846 | Ignacio Contreras                                                                                                                                              |
| 907 |    226.649523 |    394.564140 | NA                                                                                                                                                             |
| 908 |    157.401912 |    624.529987 | Ferran Sayol                                                                                                                                                   |
| 909 |    841.825027 |    370.033983 | NA                                                                                                                                                             |
| 910 |    865.149231 |    789.105691 | Chris huh                                                                                                                                                      |
| 911 |    356.869549 |    313.111626 | Chuanixn Yu                                                                                                                                                    |
| 912 |    986.720267 |    340.824784 | xgirouxb                                                                                                                                                       |
| 913 |    953.931590 |    364.722377 | Jake Warner                                                                                                                                                    |

    #> Your tweet has been posted!
