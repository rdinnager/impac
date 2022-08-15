
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

Jagged Fang Designs, Felix Vaux, Steven Traver, Hugo Gruson, Scott
Hartman, Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Zimices, Gabriela Palomo-Munoz, Gareth
Monger, Kai R. Caspar, FunkMonk \[Michael B.H.\] (modified by T. Michael
Keesey), Melissa Broussard, Brian Swartz (vectorized by T. Michael
Keesey), Samanta Orellana, David Orr, Tauana J. Cunha, Sarah Werning,
Harold N Eyster, Michelle Site, Ferran Sayol, Margot Michaud, Moussa
Direct Ltd. (photography) and T. Michael Keesey (vectorization), Joanna
Wolfe, Ignacio Contreras, Jiekun He, Scott Reid, Stanton F. Fink
(vectorized by T. Michael Keesey), Lafage, Sharon Wegner-Larsen, Dean
Schnabel, Beth Reinke, Alexandre Vong, T. Michael Keesey (from a
photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences),
Michael Day, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Collin Gross, Christopher Laumer (vectorized by T.
Michael Keesey), Gopal Murali, Rene Martin, T. Michael Keesey, Tasman
Dixon, Carlos Cano-Barbacil, Birgit Lang, Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Noah Schlottman, photo from Casey Dunn, Dmitry Bogdanov (vectorized by
T. Michael Keesey), Lani Mohan, Ghedoghedo (vectorized by T. Michael
Keesey), Markus A. Grohme, Smokeybjb, S.Martini, Richard J. Harris, T.
Michael Keesey (photo by Bc999 \[Black crow\]), Matt Crook, Jose Carlos
Arenas-Monroy, Burton Robert, USFWS, Matthew E. Clapham, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Chris huh, Ron Holmes/U. S. Fish and Wildlife Service
(source photo), T. Michael Keesey (vectorization), Andy Wilson,
\[unknown\], Rebecca Groom, Erika Schumacher, Mike Keesey
(vectorization) and Vaibhavcho (photography), Martin R. Smith, Armin
Reindl, Iain Reid, Tracy A. Heath, Darius Nau, Nobu Tamura (vectorized
by T. Michael Keesey), Darren Naish (vectorized by T. Michael Keesey),
Chloé Schmidt, Shyamal, Noah Schlottman, photo by Carlos Sánchez-Ortiz,
Anthony Caravaggi, Sean McCann, Sam Fraser-Smith (vectorized by T.
Michael Keesey), Mali’o Kodis, photograph by John Slapcinsky, Duane
Raver/USFWS, Jimmy Bernot, Ralf Janssen, Nikola-Michael Prpic & Wim G.
M. Damen (vectorized by T. Michael Keesey), Sergio A. Muñoz-Gómez, C.
Camilo Julián-Caballero, Evan-Amos (vectorized by T. Michael Keesey),
Maija Karala, Matt Martyniuk, JCGiron, Martin R. Smith, after Skovsted
et al 2015, Berivan Temiz, Robbie N. Cada (vectorized by T. Michael
Keesey), Cesar Julian, Dmitry Bogdanov, E. R. Waite & H. M. Hale
(vectorized by T. Michael Keesey), Tyler Greenfield and Dean Schnabel,
Kanako Bessho-Uehara, Ingo Braasch, FunkMonk, T. Michael Keesey (photo
by J. M. Garg), Juan Carlos Jerí, Timothy Knepp of the U.S. Fish and
Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Ramona J Heim, Agnello Picorelli, Aviceda (photo) & T. Michael Keesey,
Tony Ayling, Jaime Headden, M Hutchinson, Kamil S. Jaron, Geoff Shaw,
Noah Schlottman, photo by Adam G. Clause, Ray Simpson (vectorized by T.
Michael Keesey), Christoph Schomburg, Javier Luque & Sarah Gerken,
Manabu Bessho-Uehara, Obsidian Soul (vectorized by T. Michael Keesey),
T. Michael Keesey (after Walker & al.), Mason McNair, Ben Liebeskind,
Julio Garza, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Mathilde Cordellier,
Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Ghedoghedo, Josep Marti Solans, Fcb981 (vectorized by T.
Michael Keesey), Yan Wong, Aleksey Nagovitsyn (vectorized by T. Michael
Keesey), Steven Coombs, Yusan Yang, Stemonitis (photography) and T.
Michael Keesey (vectorization), Francis de Laporte de Castelnau
(vectorized by T. Michael Keesey), Matt Martyniuk (vectorized by T.
Michael Keesey), Chuanixn Yu, Mattia Menchetti / Yan Wong, Joe Schneid
(vectorized by T. Michael Keesey), Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, L.M. Davalos, Yan Wong from drawing
in The Century Dictionary (1911), Andrew Farke and Joseph Sertich,
Mathieu Basille, Birgit Lang, based on a photo by D. Sikes, Mathew
Wedel, Karla Martinez, Henry Fairfield Osborn, vectorized by Zimices,
Mali’o Kodis, photograph property of National Museums of Northern
Ireland, Frank Förster (based on a picture by Hans Hillewaert), Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Conty (vectorized by T. Michael Keesey),
Roberto Diaz Sibaja, based on Domser, Andrew A. Farke, modified from
original by Robert Bruce Horsfall, from Scott 1912, Cathy, Jonathan
Wells, Luc Viatour (source photo) and Andreas Plank, Raven Amos, Ryan
Cupo, John Curtis (vectorized by T. Michael Keesey), Mette Aumala, David
Tana, David Sim (photograph) and T. Michael Keesey (vectorization),
Aadx, Jordan Mallon (vectorized by T. Michael Keesey), Conty, T. Michael
Keesey (photo by Sean Mack), Michael Scroggie, Emily Willoughby, Martin
Kevil, Mali’o Kodis, photograph by Melissa Frey, Filip em, DW Bapst,
modified from Figure 1 of Belanger (2011, PALAIOS)., Chris Jennings
(vectorized by A. Verrière), Philippe Janvier (vectorized by T. Michael
Keesey), FJDegrange, Eduard Solà (vectorized by T. Michael Keesey),
Marie-Aimée Allard, Noah Schlottman, Darren Naish (vectorize by T.
Michael Keesey), Auckland Museum and T. Michael Keesey, Jessica Anne
Miller, V. Deepak, L. Shyamal, Christine Axon, Jan Sevcik (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Michael P. Taylor, Noah Schlottman, photo by Museum of Geology,
University of Tartu, Remes K, Ortega F, Fierro I, Joger U, Kosma R, et
al., T. K. Robinson, Walter Vladimir, Roberto Díaz Sibaja, T. Michael
Keesey (vectorization) and Larry Loos (photography), Verisimilus, Robert
Hering, Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M.
Chiappe, Ghedoghedo, vectorized by Zimices, Bennet McComish, photo by
Hans Hillewaert, Andrew A. Farke, Xavier Giroux-Bougard, Elizabeth
Parker, Henry Lydecker, Yan Wong from photo by Gyik Toma, (after Spotila
2004), Tony Ayling (vectorized by Milton Tan), Jack Mayer Wood, Renata
F. Martins, Renato Santos, Chris A. Hamilton, Nobu Tamura, vectorized by
Zimices, Jean-Raphaël Guillaumin (photography) and T. Michael Keesey
(vectorization), Jaime Headden, modified by T. Michael Keesey, Abraão B.
Leite, Natalie Claunch, xgirouxb, M Kolmann, Heinrich Harder (vectorized
by T. Michael Keesey), E. J. Van Nieukerken, A. Laštůvka, and Z.
Laštůvka (vectorized by T. Michael Keesey), Didier Descouens
(vectorized by T. Michael Keesey), T. Michael Keesey (vectorization) and
HuttyMcphoo (photography), Steven Haddock • Jellywatch.org, Smokeybjb
(vectorized by T. Michael Keesey), Oscar Sanisidro, Alan Manson (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Smith609 and T. Michael Keesey, Mark Hofstetter (vectorized by T.
Michael Keesey), Original drawing by Antonov, vectorized by Roberto Díaz
Sibaja, Pete Buchholz, DW Bapst (modified from Mitchell 1990), terngirl,
Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja,
Lauren Anderson, Kent Elson Sorgon, T. Michael Keesey (from a mount by
Allis Markham), Becky Barnes, Unknown (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Mattia Menchetti, Nobu
Tamura, Terpsichores, Inessa Voet, Brad McFeeters (vectorized by T.
Michael Keesey), T. Michael Keesey (after MPF), Javiera Constanzo, Tod
Robbins, Karkemish (vectorized by T. Michael Keesey), Lukasiniho, Karina
Garcia, Alex Slavenko, Ludwik Gąsiorowski, Duane Raver (vectorized by T.
Michael Keesey), Ieuan Jones, Alexander Schmidt-Lebuhn, Nobu Tamura
(modified by T. Michael Keesey), Sherman F. Denton via rawpixel.com
(illustration) and Timothy J. Bartley (silhouette), Mark Hannaford
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Fernando Campos De Domenico, New York Zoological Society, Katie
S. Collins, Tyler Greenfield, Mike Hanson, NOAA (vectorized by T.
Michael Keesey), Myriam\_Ramirez, Melissa Ingala, Zachary Quigley, John
Gould (vectorized by T. Michael Keesey), Taenadoman, T. Michael Keesey
(vector) and Stuart Halliday (photograph), Michele M Tobias, Hans
Hillewaert (vectorized by T. Michael Keesey), Maxwell Lefroy (vectorized
by T. Michael Keesey), ArtFavor & annaleeblysse, Adrian Reich, Nina
Skinner, Tony Ayling (vectorized by T. Michael Keesey), Ville Koistinen
and T. Michael Keesey, Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li
Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael
Keesey, Original drawing by Nobu Tamura, vectorized by Roberto Díaz
Sibaja, Diana Pomeroy, Jebulon (vectorized by T. Michael Keesey), T.
Michael Keesey (after C. De Muizon), François Michonneau, Kanchi Nanjo,
Kent Sorgon, Charles R. Knight (vectorized by T. Michael Keesey), Mali’o
Kodis, image from the Biodiversity Heritage Library, Mario Quevedo,
CNZdenek, Madeleine Price Ball, Chris Jennings (Risiatto), Heinrich
Harder (vectorized by William Gearty), Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Joseph J. W. Sertich, Mark A.
Loewen, Pranav Iyer (grey ideas), DW Bapst (Modified from Bulman, 1964),
Benjamint444, Caleb Brown, Pedro de Siracusa

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    511.423071 |    474.079869 | Jagged Fang Designs                                                                                                                                                   |
|   2 |    282.335032 |    624.026098 | Felix Vaux                                                                                                                                                            |
|   3 |    743.658999 |    519.690715 | Steven Traver                                                                                                                                                         |
|   4 |    499.195777 |    246.082802 | Steven Traver                                                                                                                                                         |
|   5 |    735.099674 |    260.545633 | Hugo Gruson                                                                                                                                                           |
|   6 |    902.807966 |    211.587245 | Scott Hartman                                                                                                                                                         |
|   7 |    383.966466 |    110.829597 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
|   8 |    156.781655 |    634.758271 | Zimices                                                                                                                                                               |
|   9 |    920.857605 |    518.244805 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  10 |    296.705366 |    580.456627 | Gareth Monger                                                                                                                                                         |
|  11 |    323.901219 |    241.456483 | Kai R. Caspar                                                                                                                                                         |
|  12 |    962.508904 |     69.666431 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
|  13 |    232.356267 |    443.772752 | Melissa Broussard                                                                                                                                                     |
|  14 |    336.798655 |    657.494527 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
|  15 |     56.186269 |    436.379735 | Samanta Orellana                                                                                                                                                      |
|  16 |    878.989557 |    595.034233 | David Orr                                                                                                                                                             |
|  17 |    130.952727 |     60.727732 | Jagged Fang Designs                                                                                                                                                   |
|  18 |    853.241384 |    108.095448 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  19 |    625.646679 |    118.492293 | Tauana J. Cunha                                                                                                                                                       |
|  20 |    991.500580 |    364.476459 | Sarah Werning                                                                                                                                                         |
|  21 |    222.256952 |    180.452636 | Gareth Monger                                                                                                                                                         |
|  22 |    101.534835 |    191.429308 | Harold N Eyster                                                                                                                                                       |
|  23 |    425.465985 |    348.443392 | Michelle Site                                                                                                                                                         |
|  24 |    932.961282 |    433.809599 | Jagged Fang Designs                                                                                                                                                   |
|  25 |     56.239528 |    737.452625 | Ferran Sayol                                                                                                                                                          |
|  26 |    634.589039 |    628.244072 | Margot Michaud                                                                                                                                                        |
|  27 |    456.710848 |    565.698959 | Scott Hartman                                                                                                                                                         |
|  28 |    739.704198 |    738.040637 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
|  29 |    135.030386 |    313.058543 | Steven Traver                                                                                                                                                         |
|  30 |    248.473810 |    753.524812 | Joanna Wolfe                                                                                                                                                          |
|  31 |    315.812083 |    365.468010 | Joanna Wolfe                                                                                                                                                          |
|  32 |    811.656733 |    390.845055 | Ferran Sayol                                                                                                                                                          |
|  33 |    822.104919 |    556.227713 | NA                                                                                                                                                                    |
|  34 |    954.167776 |    264.065331 | Ignacio Contreras                                                                                                                                                     |
|  35 |    776.765680 |    649.820745 | Jiekun He                                                                                                                                                             |
|  36 |    930.507639 |    715.558813 | Scott Reid                                                                                                                                                            |
|  37 |    485.724659 |    521.675284 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
|  38 |    528.553698 |     46.633917 | Jiekun He                                                                                                                                                             |
|  39 |    916.850668 |    369.259425 | Lafage                                                                                                                                                                |
|  40 |    968.010734 |    190.582795 | Sharon Wegner-Larsen                                                                                                                                                  |
|  41 |    561.101441 |    680.090655 | Steven Traver                                                                                                                                                         |
|  42 |    693.471659 |     77.414164 | Dean Schnabel                                                                                                                                                         |
|  43 |    973.809364 |    615.087253 | Beth Reinke                                                                                                                                                           |
|  44 |    607.387116 |    552.043892 | Zimices                                                                                                                                                               |
|  45 |    595.323680 |    428.760026 | Alexandre Vong                                                                                                                                                        |
|  46 |    900.326146 |     25.489749 | NA                                                                                                                                                                    |
|  47 |    508.879518 |    768.739144 | Scott Reid                                                                                                                                                            |
|  48 |    689.554296 |    398.829709 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
|  49 |    341.332219 |    469.666592 | Michael Day                                                                                                                                                           |
|  50 |    423.532054 |    692.512710 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
|  51 |    619.343111 |    179.531493 | Collin Gross                                                                                                                                                          |
|  52 |    830.834566 |    239.892020 | Scott Hartman                                                                                                                                                         |
|  53 |    832.014097 |    738.207782 | Sharon Wegner-Larsen                                                                                                                                                  |
|  54 |    459.237276 |    200.175492 | Scott Hartman                                                                                                                                                         |
|  55 |    304.813250 |    695.355186 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                  |
|  56 |    594.527188 |    317.947300 | Gopal Murali                                                                                                                                                          |
|  57 |    755.914387 |    448.267054 | Rene Martin                                                                                                                                                           |
|  58 |    183.333562 |    545.557818 | T. Michael Keesey                                                                                                                                                     |
|  59 |    773.433412 |    179.394077 | Jagged Fang Designs                                                                                                                                                   |
|  60 |    645.871157 |    675.832518 | Tasman Dixon                                                                                                                                                          |
|  61 |    519.552934 |    372.708872 | Tasman Dixon                                                                                                                                                          |
|  62 |    162.437341 |     98.544231 | Carlos Cano-Barbacil                                                                                                                                                  |
|  63 |    773.117082 |     40.522402 | Jagged Fang Designs                                                                                                                                                   |
|  64 |    715.476211 |    349.526791 | Margot Michaud                                                                                                                                                        |
|  65 |    275.722603 |    236.715377 | Birgit Lang                                                                                                                                                           |
|  66 |    173.560042 |    714.843508 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  67 |    140.727859 |    492.799432 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  68 |    179.176568 |    779.940291 | T. Michael Keesey                                                                                                                                                     |
|  69 |     42.272635 |    605.181719 | NA                                                                                                                                                                    |
|  70 |    215.339820 |    301.574579 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
|  71 |    622.019861 |    766.858330 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  72 |    593.971884 |     83.321833 | Lani Mohan                                                                                                                                                            |
|  73 |    849.340164 |    463.002748 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  74 |    823.286967 |    308.774256 | Markus A. Grohme                                                                                                                                                      |
|  75 |    318.644817 |    511.878637 | Smokeybjb                                                                                                                                                             |
|  76 |    451.004406 |     60.361955 | Scott Hartman                                                                                                                                                         |
|  77 |    666.137997 |    456.276365 | S.Martini                                                                                                                                                             |
|  78 |    160.844376 |    260.449002 | Markus A. Grohme                                                                                                                                                      |
|  79 |    517.110676 |    613.043666 | Gareth Monger                                                                                                                                                         |
|  80 |    332.434784 |    318.848528 | Jagged Fang Designs                                                                                                                                                   |
|  81 |    987.657161 |    734.227565 | Ferran Sayol                                                                                                                                                          |
|  82 |    509.423914 |    787.451368 | Scott Hartman                                                                                                                                                         |
|  83 |     39.236241 |    122.998256 | Richard J. Harris                                                                                                                                                     |
|  84 |    564.389721 |    777.618887 | Steven Traver                                                                                                                                                         |
|  85 |    211.394303 |    532.593526 | NA                                                                                                                                                                    |
|  86 |    545.748740 |    638.734983 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
|  87 |    114.276677 |    298.948147 | Margot Michaud                                                                                                                                                        |
|  88 |    153.831037 |    788.079719 | Jagged Fang Designs                                                                                                                                                   |
|  89 |    356.278416 |    542.571103 | NA                                                                                                                                                                    |
|  90 |    973.496199 |    290.001231 | Ferran Sayol                                                                                                                                                          |
|  91 |    392.130911 |     14.819762 | Jagged Fang Designs                                                                                                                                                   |
|  92 |    544.608443 |    576.907950 | NA                                                                                                                                                                    |
|  93 |   1005.492971 |    607.886497 | NA                                                                                                                                                                    |
|  94 |    983.723534 |     32.323912 | Michelle Site                                                                                                                                                         |
|  95 |    544.302524 |    529.116755 | Scott Hartman                                                                                                                                                         |
|  96 |    661.288948 |    282.963243 | Ferran Sayol                                                                                                                                                          |
|  97 |    442.746454 |    637.587814 | T. Michael Keesey                                                                                                                                                     |
|  98 |    791.780156 |    689.793856 | Sarah Werning                                                                                                                                                         |
|  99 |    577.983045 |    517.959961 | Margot Michaud                                                                                                                                                        |
| 100 |    723.388885 |    386.796342 | Jagged Fang Designs                                                                                                                                                   |
| 101 |    449.470997 |    734.253881 | David Orr                                                                                                                                                             |
| 102 |    513.319181 |    146.013027 | Matt Crook                                                                                                                                                            |
| 103 |    878.113003 |    569.447721 | Gareth Monger                                                                                                                                                         |
| 104 |    715.826737 |    219.395992 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 105 |    740.567911 |    153.503712 | Scott Hartman                                                                                                                                                         |
| 106 |    951.175250 |    659.866493 | Michelle Site                                                                                                                                                         |
| 107 |    554.362733 |     90.667400 | Matt Crook                                                                                                                                                            |
| 108 |    208.905157 |     20.555291 | Zimices                                                                                                                                                               |
| 109 |    488.967833 |    131.629684 | Burton Robert, USFWS                                                                                                                                                  |
| 110 |    590.806505 |    146.411713 | Jagged Fang Designs                                                                                                                                                   |
| 111 |     31.463945 |    311.637732 | Matt Crook                                                                                                                                                            |
| 112 |    710.009591 |    131.460440 | Gareth Monger                                                                                                                                                         |
| 113 |    440.522998 |    425.987883 | Matthew E. Clapham                                                                                                                                                    |
| 114 |    154.926807 |    229.029904 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 115 |    835.399447 |    604.744572 | Tauana J. Cunha                                                                                                                                                       |
| 116 |    486.795706 |    558.185930 | Zimices                                                                                                                                                               |
| 117 |    950.772805 |    489.586556 | Chris huh                                                                                                                                                             |
| 118 |    824.117031 |    517.799455 | Matt Crook                                                                                                                                                            |
| 119 |    400.531152 |    453.109518 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 120 |    883.483415 |    465.517013 | NA                                                                                                                                                                    |
| 121 |   1005.577947 |    111.064058 | Andy Wilson                                                                                                                                                           |
| 122 |    114.094563 |    252.717061 | Harold N Eyster                                                                                                                                                       |
| 123 |    116.959251 |    236.165949 | \[unknown\]                                                                                                                                                           |
| 124 |    564.001242 |    309.690042 | Rebecca Groom                                                                                                                                                         |
| 125 |    911.917486 |    783.522980 | Zimices                                                                                                                                                               |
| 126 |    894.073550 |    237.055996 | Beth Reinke                                                                                                                                                           |
| 127 |    134.565658 |    404.397852 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 128 |    439.429464 |    158.116615 | Tasman Dixon                                                                                                                                                          |
| 129 |    263.672320 |    150.990097 | Zimices                                                                                                                                                               |
| 130 |    646.469931 |    221.186959 | Gareth Monger                                                                                                                                                         |
| 131 |    912.751313 |    315.228592 | Gareth Monger                                                                                                                                                         |
| 132 |     63.617952 |     18.306775 | Erika Schumacher                                                                                                                                                      |
| 133 |    948.264105 |    614.199893 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 134 |    613.569863 |    241.948095 | T. Michael Keesey                                                                                                                                                     |
| 135 |    247.628984 |    373.888776 | Steven Traver                                                                                                                                                         |
| 136 |    416.871715 |    496.246651 | Martin R. Smith                                                                                                                                                       |
| 137 |    854.595952 |    185.230697 | Armin Reindl                                                                                                                                                          |
| 138 |    148.357595 |      9.440096 | Iain Reid                                                                                                                                                             |
| 139 |    736.876411 |    634.118341 | Tasman Dixon                                                                                                                                                          |
| 140 |    654.317149 |     15.964806 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 141 |    249.455872 |    343.927167 | Matt Crook                                                                                                                                                            |
| 142 |    428.924685 |     11.036145 | Tracy A. Heath                                                                                                                                                        |
| 143 |    200.889443 |    131.198267 | Darius Nau                                                                                                                                                            |
| 144 |    798.503147 |    538.250468 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 145 |    258.784291 |     63.475112 | Matt Crook                                                                                                                                                            |
| 146 |    672.960323 |    573.431624 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 147 |    487.255576 |    421.659851 | NA                                                                                                                                                                    |
| 148 |    397.601808 |    504.064865 | Margot Michaud                                                                                                                                                        |
| 149 |    853.471734 |    139.103604 | Chloé Schmidt                                                                                                                                                         |
| 150 |    733.029702 |    390.408667 | Jagged Fang Designs                                                                                                                                                   |
| 151 |     49.984660 |     87.132878 | Shyamal                                                                                                                                                               |
| 152 |    197.299981 |    689.052969 | Markus A. Grohme                                                                                                                                                      |
| 153 |    393.897190 |    429.019329 | Burton Robert, USFWS                                                                                                                                                  |
| 154 |    865.132186 |    660.553529 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 155 |     96.645105 |    421.109740 | Zimices                                                                                                                                                               |
| 156 |    432.380178 |    215.007126 | Gareth Monger                                                                                                                                                         |
| 157 |    735.889603 |    596.960519 | Ferran Sayol                                                                                                                                                          |
| 158 |   1002.224599 |    438.750648 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 159 |     39.936091 |     72.754055 | Matt Crook                                                                                                                                                            |
| 160 |    853.616607 |    773.976086 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 161 |    367.873590 |    246.231903 | Chris huh                                                                                                                                                             |
| 162 |    309.645310 |    150.352013 | Matt Crook                                                                                                                                                            |
| 163 |    695.883173 |    723.768276 | NA                                                                                                                                                                    |
| 164 |     46.804007 |    248.393637 | Anthony Caravaggi                                                                                                                                                     |
| 165 |    769.591987 |    699.186079 | Chris huh                                                                                                                                                             |
| 166 |    631.955691 |    517.224123 | Matt Crook                                                                                                                                                            |
| 167 |    482.723277 |     97.375856 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 168 |    164.124247 |    192.778970 | Sean McCann                                                                                                                                                           |
| 169 |    450.732961 |    495.347722 | Iain Reid                                                                                                                                                             |
| 170 |    249.125626 |    697.830022 | NA                                                                                                                                                                    |
| 171 |    712.200237 |    690.355802 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 172 |    427.125207 |    606.182949 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 173 |    379.252858 |    794.759749 | Melissa Broussard                                                                                                                                                     |
| 174 |     29.500808 |    205.957727 | Martin R. Smith                                                                                                                                                       |
| 175 |    195.552273 |     21.597427 | Zimices                                                                                                                                                               |
| 176 |    132.581502 |    370.592303 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 177 |    437.087994 |    175.446077 | Erika Schumacher                                                                                                                                                      |
| 178 |     72.405796 |    509.642469 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 179 |    701.502673 |    470.477143 | Duane Raver/USFWS                                                                                                                                                     |
| 180 |    931.414976 |     52.696380 | Chris huh                                                                                                                                                             |
| 181 |    205.953168 |    613.593581 | Jimmy Bernot                                                                                                                                                          |
| 182 |    284.864278 |    304.033445 | T. Michael Keesey                                                                                                                                                     |
| 183 |      8.557762 |    397.290447 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 184 |     16.952625 |    282.985107 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 185 |    998.291959 |    454.051419 | Jagged Fang Designs                                                                                                                                                   |
| 186 |      7.659275 |     17.132853 | Carlos Cano-Barbacil                                                                                                                                                  |
| 187 |    107.326101 |    488.366682 | Matt Crook                                                                                                                                                            |
| 188 |    506.827177 |    308.759748 | C. Camilo Julián-Caballero                                                                                                                                            |
| 189 |    352.458281 |    178.150026 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 190 |    617.328893 |    504.307020 | Zimices                                                                                                                                                               |
| 191 |    858.523471 |    620.155696 | Maija Karala                                                                                                                                                          |
| 192 |    876.439627 |    448.696716 | NA                                                                                                                                                                    |
| 193 |    907.586837 |    744.811505 | Chris huh                                                                                                                                                             |
| 194 |    824.154048 |    792.646929 | Matt Martyniuk                                                                                                                                                        |
| 195 |    460.156388 |    406.562700 | Margot Michaud                                                                                                                                                        |
| 196 |    889.574498 |     53.115430 | JCGiron                                                                                                                                                               |
| 197 |     31.207199 |    331.576050 | Markus A. Grohme                                                                                                                                                      |
| 198 |    892.476742 |     76.396372 | Zimices                                                                                                                                                               |
| 199 |    194.054419 |    157.656047 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 200 |    423.286208 |    725.362050 | NA                                                                                                                                                                    |
| 201 |    965.122384 |    478.630238 | Ferran Sayol                                                                                                                                                          |
| 202 |    889.622187 |    317.204211 | Chris huh                                                                                                                                                             |
| 203 |    446.571743 |    149.193331 | Scott Hartman                                                                                                                                                         |
| 204 |    957.184334 |    783.233555 | Tasman Dixon                                                                                                                                                          |
| 205 |    331.712604 |    561.641890 | Berivan Temiz                                                                                                                                                         |
| 206 |    427.730778 |    296.057989 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 207 |    673.161168 |    644.832249 | Andy Wilson                                                                                                                                                           |
| 208 |    296.773597 |    453.178723 | Cesar Julian                                                                                                                                                          |
| 209 |    361.518630 |     27.317763 | Dmitry Bogdanov                                                                                                                                                       |
| 210 |    844.148137 |     56.303919 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 211 |    768.209056 |    122.258351 | Zimices                                                                                                                                                               |
| 212 |    598.958449 |    389.018653 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 213 |    378.509319 |    355.475609 | Kanako Bessho-Uehara                                                                                                                                                  |
| 214 |    120.642208 |    455.154367 | Ingo Braasch                                                                                                                                                          |
| 215 |    207.323066 |    621.602111 | FunkMonk                                                                                                                                                              |
| 216 |    653.636406 |    467.268821 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 217 |    619.656217 |    147.228975 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 218 |    564.803174 |    624.302123 | Steven Traver                                                                                                                                                         |
| 219 |    112.613551 |    541.604907 | Juan Carlos Jerí                                                                                                                                                      |
| 220 |   1001.671338 |    694.508722 | Steven Traver                                                                                                                                                         |
| 221 |    930.427397 |    111.051171 | Markus A. Grohme                                                                                                                                                      |
| 222 |    181.373446 |    275.983758 | Ferran Sayol                                                                                                                                                          |
| 223 |     20.523329 |    538.348169 | Jagged Fang Designs                                                                                                                                                   |
| 224 |    879.310673 |    141.773003 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 225 |    277.634236 |    114.252180 | Ramona J Heim                                                                                                                                                         |
| 226 |    856.555063 |    357.401597 | Markus A. Grohme                                                                                                                                                      |
| 227 |    175.751879 |     32.126420 | Scott Hartman                                                                                                                                                         |
| 228 |    105.458623 |    584.181885 | Agnello Picorelli                                                                                                                                                     |
| 229 |    671.157320 |    546.755589 | NA                                                                                                                                                                    |
| 230 |    412.487863 |    753.249910 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 231 |    812.983731 |    165.710156 | Tony Ayling                                                                                                                                                           |
| 232 |    327.408028 |    745.405574 | Dean Schnabel                                                                                                                                                         |
| 233 |    226.274149 |     88.779607 | Scott Hartman                                                                                                                                                         |
| 234 |    851.432080 |    687.827441 | Scott Hartman                                                                                                                                                         |
| 235 |    394.743374 |    261.125041 | Jagged Fang Designs                                                                                                                                                   |
| 236 |    159.872392 |    157.203743 | Dean Schnabel                                                                                                                                                         |
| 237 |    778.055773 |    782.090797 | Tasman Dixon                                                                                                                                                          |
| 238 |    995.426256 |    497.378093 | Jaime Headden                                                                                                                                                         |
| 239 |   1008.892370 |    209.564057 | M Hutchinson                                                                                                                                                          |
| 240 |    446.058562 |    674.245321 | Kamil S. Jaron                                                                                                                                                        |
| 241 |    345.325828 |    292.924808 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 242 |    360.581857 |    622.518351 | Jagged Fang Designs                                                                                                                                                   |
| 243 |    171.442348 |    390.637590 | Geoff Shaw                                                                                                                                                            |
| 244 |    382.353035 |    270.074423 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 245 |    812.123272 |    484.203288 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 246 |    264.147838 |     14.488434 | Kamil S. Jaron                                                                                                                                                        |
| 247 |    903.032559 |    735.723682 | Zimices                                                                                                                                                               |
| 248 |    864.940259 |    742.446869 | Markus A. Grohme                                                                                                                                                      |
| 249 |    223.727975 |    662.853019 | Zimices                                                                                                                                                               |
| 250 |    524.808695 |    538.077437 | Margot Michaud                                                                                                                                                        |
| 251 |    224.457157 |    388.619575 | Sharon Wegner-Larsen                                                                                                                                                  |
| 252 |    721.773453 |    417.705916 | Margot Michaud                                                                                                                                                        |
| 253 |    309.867728 |    321.840949 | Christoph Schomburg                                                                                                                                                   |
| 254 |    154.432110 |    415.668688 | C. Camilo Julián-Caballero                                                                                                                                            |
| 255 |    682.741838 |    532.577482 | Kai R. Caspar                                                                                                                                                         |
| 256 |    856.420417 |    378.089871 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 257 |     68.656532 |    282.492413 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 258 |    304.160320 |    236.719178 | Ferran Sayol                                                                                                                                                          |
| 259 |    938.295115 |    783.204669 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 260 |    534.047804 |    173.326748 | Jagged Fang Designs                                                                                                                                                   |
| 261 |     94.571474 |    317.807754 | Smokeybjb                                                                                                                                                             |
| 262 |    737.569570 |    576.833556 | Erika Schumacher                                                                                                                                                      |
| 263 |    456.122894 |    707.604747 | Gareth Monger                                                                                                                                                         |
| 264 |    842.073419 |    780.985398 | Manabu Bessho-Uehara                                                                                                                                                  |
| 265 |    169.526573 |    408.082751 | C. Camilo Julián-Caballero                                                                                                                                            |
| 266 |    624.051185 |    260.785708 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 267 |    365.636316 |    500.733671 | T. Michael Keesey                                                                                                                                                     |
| 268 |    548.780809 |    658.595169 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 269 |    851.881804 |    263.855932 | T. Michael Keesey                                                                                                                                                     |
| 270 |    551.130355 |    337.433056 | Zimices                                                                                                                                                               |
| 271 |    863.414534 |    773.838089 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 272 |    484.107347 |    296.865920 | Andy Wilson                                                                                                                                                           |
| 273 |    589.633346 |    597.261877 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 274 |    383.982076 |    304.169938 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 275 |    573.591914 |    353.004050 | Tony Ayling                                                                                                                                                           |
| 276 |    373.119809 |    557.252343 | Mason McNair                                                                                                                                                          |
| 277 |    974.707005 |    741.058417 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 278 |    284.130486 |    146.197241 | Armin Reindl                                                                                                                                                          |
| 279 |    280.384222 |    421.452138 | Ferran Sayol                                                                                                                                                          |
| 280 |    614.266569 |    586.214251 | Matt Crook                                                                                                                                                            |
| 281 |    495.117624 |    347.383471 | Jagged Fang Designs                                                                                                                                                   |
| 282 |    465.443481 |    563.099587 | Gareth Monger                                                                                                                                                         |
| 283 |    698.671616 |    635.259007 | Ben Liebeskind                                                                                                                                                        |
| 284 |    618.382981 |    419.804000 | Julio Garza                                                                                                                                                           |
| 285 |    547.491065 |    466.914042 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 286 |    697.259539 |    529.358792 | Mathilde Cordellier                                                                                                                                                   |
| 287 |    461.324945 |     84.632640 | Armin Reindl                                                                                                                                                          |
| 288 |    796.212856 |    251.067980 | Andy Wilson                                                                                                                                                           |
| 289 |    639.155553 |     11.156236 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 290 |   1009.889370 |    521.515781 | Sharon Wegner-Larsen                                                                                                                                                  |
| 291 |    859.026490 |    330.595775 | Gareth Monger                                                                                                                                                         |
| 292 |    189.755660 |     29.409315 | Ghedoghedo                                                                                                                                                            |
| 293 |    166.872360 |    666.990339 | Jagged Fang Designs                                                                                                                                                   |
| 294 |     86.671276 |    132.305771 | Josep Marti Solans                                                                                                                                                    |
| 295 |    498.830281 |    188.620247 | Scott Hartman                                                                                                                                                         |
| 296 |    103.106339 |    512.520558 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 297 |    219.735504 |    631.704014 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 298 |    962.424404 |    409.409699 | Matt Crook                                                                                                                                                            |
| 299 |     36.392774 |    166.678709 | Matt Crook                                                                                                                                                            |
| 300 |    544.568241 |    405.354145 | Matt Crook                                                                                                                                                            |
| 301 |    309.331375 |    423.866727 | Collin Gross                                                                                                                                                          |
| 302 |    925.250988 |    651.846130 | Jagged Fang Designs                                                                                                                                                   |
| 303 |    220.466573 |    676.237636 | Yan Wong                                                                                                                                                              |
| 304 |    597.062519 |    249.660452 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 305 |    668.884127 |    751.248229 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 306 |    815.957535 |    776.886391 | NA                                                                                                                                                                    |
| 307 |     67.079312 |    304.759628 | Steven Coombs                                                                                                                                                         |
| 308 |    160.117333 |    508.609597 | Matt Crook                                                                                                                                                            |
| 309 |   1006.483037 |     10.019083 | Yusan Yang                                                                                                                                                            |
| 310 |    867.899121 |    655.047335 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 311 |    351.000330 |    304.178463 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                                     |
| 312 |    298.727777 |    161.482499 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 313 |    333.133081 |    731.892307 | Gareth Monger                                                                                                                                                         |
| 314 |    591.310820 |     97.418136 | Zimices                                                                                                                                                               |
| 315 |    542.017196 |    792.218674 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 316 |    396.988142 |    220.862105 | Chris huh                                                                                                                                                             |
| 317 |    890.718221 |    764.834740 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 318 |    187.663899 |    127.133975 | Chuanixn Yu                                                                                                                                                           |
| 319 |    975.932184 |    244.069603 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 320 |    717.086933 |    673.704579 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 321 |    858.026971 |    544.881097 | Zimices                                                                                                                                                               |
| 322 |    552.552224 |    368.074548 | Tauana J. Cunha                                                                                                                                                       |
| 323 |    463.632516 |    351.274469 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 324 |    462.721602 |    796.365888 | Christoph Schomburg                                                                                                                                                   |
| 325 |   1010.861874 |    275.286461 | Matt Crook                                                                                                                                                            |
| 326 |     10.254646 |     33.038646 | Matt Crook                                                                                                                                                            |
| 327 |    206.594649 |     71.035588 | C. Camilo Julián-Caballero                                                                                                                                            |
| 328 |    508.384470 |    764.577762 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 329 |    120.799917 |    498.736580 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 330 |    702.775844 |    427.988637 | Matt Crook                                                                                                                                                            |
| 331 |    895.561617 |    648.720215 | L.M. Davalos                                                                                                                                                          |
| 332 |     72.732781 |     90.865960 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 333 |    753.204951 |    422.078838 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 334 |    144.959339 |    593.980110 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 335 |    213.257512 |     85.586530 | Margot Michaud                                                                                                                                                        |
| 336 |    963.855372 |    126.847093 | Matt Crook                                                                                                                                                            |
| 337 |    331.932629 |    430.556175 | S.Martini                                                                                                                                                             |
| 338 |    891.521063 |    400.215057 | T. Michael Keesey                                                                                                                                                     |
| 339 |    128.982565 |    768.834939 | Margot Michaud                                                                                                                                                        |
| 340 |    950.415446 |      5.718132 | Mathieu Basille                                                                                                                                                       |
| 341 |    898.956513 |    482.051808 | Sean McCann                                                                                                                                                           |
| 342 |    195.553110 |    181.630026 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 343 |    570.889356 |    609.545094 | Mathew Wedel                                                                                                                                                          |
| 344 |    765.744372 |    234.501312 | Gareth Monger                                                                                                                                                         |
| 345 |    597.302735 |    509.688135 | Karla Martinez                                                                                                                                                        |
| 346 |    741.387644 |    110.475035 | Shyamal                                                                                                                                                               |
| 347 |    525.515957 |      7.362699 | Ignacio Contreras                                                                                                                                                     |
| 348 |    347.743349 |    762.208050 | Kamil S. Jaron                                                                                                                                                        |
| 349 |    566.189981 |    183.599346 | Margot Michaud                                                                                                                                                        |
| 350 |    172.252568 |    445.981632 | Felix Vaux                                                                                                                                                            |
| 351 |    779.878434 |    397.286267 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 352 |     12.723344 |    689.452158 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 353 |    914.088240 |    789.311882 | Michelle Site                                                                                                                                                         |
| 354 |    575.574562 |    361.202209 | Alexandre Vong                                                                                                                                                        |
| 355 |     41.003935 |    682.410312 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
| 356 |    586.820488 |    586.385586 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 357 |     78.575019 |    327.584676 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 358 |    312.710646 |    552.236131 | Joanna Wolfe                                                                                                                                                          |
| 359 |    810.461247 |    627.630761 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 360 |    836.872797 |    755.071457 | Steven Traver                                                                                                                                                         |
| 361 |    246.052605 |    411.997391 | Chris huh                                                                                                                                                             |
| 362 |    667.849133 |    245.901320 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 363 |    129.269357 |    247.237684 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 364 |    889.299652 |    679.579409 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 365 |     12.944148 |    784.993036 | Cathy                                                                                                                                                                 |
| 366 |    254.497485 |    550.907116 | Scott Hartman                                                                                                                                                         |
| 367 |    930.472869 |    329.559037 | Margot Michaud                                                                                                                                                        |
| 368 |    431.558307 |    513.346588 | Jonathan Wells                                                                                                                                                        |
| 369 |    916.040627 |    407.756994 | Zimices                                                                                                                                                               |
| 370 |    294.261259 |    463.235971 | Gareth Monger                                                                                                                                                         |
| 371 |    100.589890 |    695.029908 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 372 |    624.837787 |    596.010895 | Chuanixn Yu                                                                                                                                                           |
| 373 |    689.547671 |    598.159756 | Sarah Werning                                                                                                                                                         |
| 374 |    453.850101 |     15.422823 | NA                                                                                                                                                                    |
| 375 |    835.181338 |    584.251197 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 376 |    228.125850 |    491.697659 | Scott Reid                                                                                                                                                            |
| 377 |    825.435273 |    527.129928 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 378 |    298.051729 |      9.804097 | Raven Amos                                                                                                                                                            |
| 379 |    247.960374 |    716.672571 | Matt Crook                                                                                                                                                            |
| 380 |    547.377093 |    372.081728 | Jaime Headden                                                                                                                                                         |
| 381 |    396.597750 |    625.371745 | Sarah Werning                                                                                                                                                         |
| 382 |     15.872038 |    246.102431 | Matt Crook                                                                                                                                                            |
| 383 |    345.241194 |    426.780625 | Kamil S. Jaron                                                                                                                                                        |
| 384 |    584.887017 |    195.371268 | Ryan Cupo                                                                                                                                                             |
| 385 |    502.256689 |    598.053796 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 386 |    814.668812 |    319.431649 | Rene Martin                                                                                                                                                           |
| 387 |    783.561819 |    586.579763 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 388 |    236.702024 |    660.066065 | Felix Vaux                                                                                                                                                            |
| 389 |    297.269280 |    443.292195 | Mette Aumala                                                                                                                                                          |
| 390 |    795.539014 |    509.540221 | Zimices                                                                                                                                                               |
| 391 |    614.272470 |    784.948367 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 392 |    796.993724 |    338.471566 | Rebecca Groom                                                                                                                                                         |
| 393 |    410.589272 |    622.973450 | Matt Crook                                                                                                                                                            |
| 394 |     51.724876 |    347.305492 | Collin Gross                                                                                                                                                          |
| 395 |    890.993470 |    722.322357 | David Tana                                                                                                                                                            |
| 396 |    352.641673 |    263.082174 | Andy Wilson                                                                                                                                                           |
| 397 |    681.605741 |    297.272365 | Yusan Yang                                                                                                                                                            |
| 398 |    708.209970 |    230.783055 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 399 |   1007.783884 |    563.702586 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 400 |    255.984801 |    431.887212 | Tasman Dixon                                                                                                                                                          |
| 401 |    332.067293 |    779.847874 | Cesar Julian                                                                                                                                                          |
| 402 |    523.038778 |    559.042833 | Zimices                                                                                                                                                               |
| 403 |    118.533331 |    756.174670 | Matt Crook                                                                                                                                                            |
| 404 |    187.392081 |    121.971517 | Jagged Fang Designs                                                                                                                                                   |
| 405 |     93.026629 |    550.952014 | Ferran Sayol                                                                                                                                                          |
| 406 |    797.720055 |    767.403108 | Manabu Bessho-Uehara                                                                                                                                                  |
| 407 |    343.134051 |     17.731823 | Andy Wilson                                                                                                                                                           |
| 408 |    394.827811 |    564.104766 | Aadx                                                                                                                                                                  |
| 409 |    382.459954 |    710.034103 | Sean McCann                                                                                                                                                           |
| 410 |    834.888228 |     32.722376 | Dmitry Bogdanov                                                                                                                                                       |
| 411 |    672.739181 |    494.874396 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 412 |    584.339181 |    178.437087 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 413 |    794.001363 |     10.482866 | Chris huh                                                                                                                                                             |
| 414 |    537.326986 |    385.180025 | Armin Reindl                                                                                                                                                          |
| 415 |    226.865437 |    785.339065 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 416 |    690.275943 |    162.760733 | Scott Hartman                                                                                                                                                         |
| 417 |    260.182434 |    618.680909 | Beth Reinke                                                                                                                                                           |
| 418 |     25.015593 |     22.410024 | Conty                                                                                                                                                                 |
| 419 |    716.994500 |    651.330790 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 420 |    680.444869 |    317.799150 | Michael Scroggie                                                                                                                                                      |
| 421 |    577.415337 |    654.000076 | Matt Crook                                                                                                                                                            |
| 422 |    706.009241 |    461.680943 | Emily Willoughby                                                                                                                                                      |
| 423 |    785.146071 |    124.260466 | Matt Crook                                                                                                                                                            |
| 424 |    709.904792 |    605.651789 | Chris huh                                                                                                                                                             |
| 425 |    523.746861 |    436.461662 | Martin Kevil                                                                                                                                                          |
| 426 |    669.028041 |    524.812554 | Mathew Wedel                                                                                                                                                          |
| 427 |    490.706708 |    543.408708 | Margot Michaud                                                                                                                                                        |
| 428 |    425.286541 |    774.987724 | Ferran Sayol                                                                                                                                                          |
| 429 |     13.048819 |    213.182344 | C. Camilo Julián-Caballero                                                                                                                                            |
| 430 |    687.168390 |    240.162784 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                              |
| 431 |    390.492527 |    211.407445 | Filip em                                                                                                                                                              |
| 432 |    119.203110 |    363.719237 | Jaime Headden                                                                                                                                                         |
| 433 |    305.817062 |    495.708925 | Birgit Lang                                                                                                                                                           |
| 434 |    829.679183 |    202.672508 | Maija Karala                                                                                                                                                          |
| 435 |    640.383066 |    460.062205 | Margot Michaud                                                                                                                                                        |
| 436 |   1011.158799 |    583.182398 | Ferran Sayol                                                                                                                                                          |
| 437 |    164.411778 |    571.755225 | Mathilde Cordellier                                                                                                                                                   |
| 438 |   1006.079324 |    539.600945 | Steven Traver                                                                                                                                                         |
| 439 |    439.702616 |    370.758422 | Matt Crook                                                                                                                                                            |
| 440 |    629.119632 |    284.929346 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 441 |    791.103728 |    498.139264 | Birgit Lang                                                                                                                                                           |
| 442 |    696.547521 |    142.865642 | NA                                                                                                                                                                    |
| 443 |    355.153362 |    369.485289 | Rebecca Groom                                                                                                                                                         |
| 444 |    131.477877 |    349.945570 | Margot Michaud                                                                                                                                                        |
| 445 |      9.219690 |    426.518046 | Joanna Wolfe                                                                                                                                                          |
| 446 |    512.856674 |     87.995639 | Margot Michaud                                                                                                                                                        |
| 447 |    850.160646 |    361.721509 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 448 |    952.377891 |    310.794564 | Jaime Headden                                                                                                                                                         |
| 449 |    706.103269 |    626.736225 | Steven Traver                                                                                                                                                         |
| 450 |    743.141650 |    410.091659 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 451 |    128.988932 |    430.039953 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 452 |    704.303537 |    743.590095 | Hugo Gruson                                                                                                                                                           |
| 453 |    168.427518 |      4.162186 | NA                                                                                                                                                                    |
| 454 |    669.428835 |     90.637486 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 455 |    401.186489 |    777.152543 | Ferran Sayol                                                                                                                                                          |
| 456 |    363.561605 |    324.350632 | Matt Crook                                                                                                                                                            |
| 457 |    656.526499 |    487.093357 | Margot Michaud                                                                                                                                                        |
| 458 |    971.576565 |    365.613144 | FJDegrange                                                                                                                                                            |
| 459 |    629.650011 |    398.903107 | Emily Willoughby                                                                                                                                                      |
| 460 |    108.048655 |    374.034913 | FunkMonk                                                                                                                                                              |
| 461 |    361.185855 |    232.536139 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                         |
| 462 |    529.588880 |    427.053965 | Marie-Aimée Allard                                                                                                                                                    |
| 463 |    302.200402 |    537.157515 | Noah Schlottman                                                                                                                                                       |
| 464 |    409.239215 |     33.256774 | Zimices                                                                                                                                                               |
| 465 |    933.525493 |    611.104759 | Scott Hartman                                                                                                                                                         |
| 466 |     69.308988 |    663.981139 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 467 |    438.462724 |    455.057998 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 468 |    173.784799 |    176.900708 | Ferran Sayol                                                                                                                                                          |
| 469 |    689.861195 |    554.333923 | Sharon Wegner-Larsen                                                                                                                                                  |
| 470 |    730.706351 |     89.939669 | T. Michael Keesey                                                                                                                                                     |
| 471 |    357.115845 |    558.881180 | Matt Crook                                                                                                                                                            |
| 472 |    536.742539 |     14.402122 | Andy Wilson                                                                                                                                                           |
| 473 |    489.353761 |    110.688294 | Matt Crook                                                                                                                                                            |
| 474 |    757.005899 |    114.018985 | Gareth Monger                                                                                                                                                         |
| 475 |    413.978040 |    600.891221 | Scott Hartman                                                                                                                                                         |
| 476 |    273.577396 |    551.520395 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
| 477 |    805.879666 |    603.911534 | Chris huh                                                                                                                                                             |
| 478 |    357.213614 |    270.928855 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 479 |    627.277868 |    494.753796 | Dean Schnabel                                                                                                                                                         |
| 480 |    946.152151 |    411.482835 | Birgit Lang                                                                                                                                                           |
| 481 |    275.149032 |    366.998770 | NA                                                                                                                                                                    |
| 482 |    426.902637 |    658.901556 | Jessica Anne Miller                                                                                                                                                   |
| 483 |     15.810823 |     70.353977 | Scott Hartman                                                                                                                                                         |
| 484 |    204.997014 |     54.535028 | T. Michael Keesey                                                                                                                                                     |
| 485 |    741.617026 |    657.449858 | Steven Traver                                                                                                                                                         |
| 486 |    886.561747 |    670.300874 | Kai R. Caspar                                                                                                                                                         |
| 487 |    529.260478 |    651.056822 | Ferran Sayol                                                                                                                                                          |
| 488 |    147.975116 |    131.893591 | V. Deepak                                                                                                                                                             |
| 489 |    583.897686 |     37.285091 | Kamil S. Jaron                                                                                                                                                        |
| 490 |    278.924185 |    430.879883 | Jagged Fang Designs                                                                                                                                                   |
| 491 |    367.577342 |    687.500045 | Gareth Monger                                                                                                                                                         |
| 492 |    144.234855 |    215.789077 | L. Shyamal                                                                                                                                                            |
| 493 |    267.835450 |    726.573085 | Christine Axon                                                                                                                                                        |
| 494 |    522.214460 |     92.461713 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 495 |    797.585039 |    530.134554 | Jagged Fang Designs                                                                                                                                                   |
| 496 |    241.153794 |    677.021545 | NA                                                                                                                                                                    |
| 497 |    144.035161 |     71.401716 | Matt Crook                                                                                                                                                            |
| 498 |    319.801654 |     13.742092 | Michael P. Taylor                                                                                                                                                     |
| 499 |    639.282718 |    786.284737 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 500 |    245.070269 |     35.390469 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 501 |    430.237944 |    787.975943 | Scott Hartman                                                                                                                                                         |
| 502 |    349.103309 |     10.070904 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 503 |    391.871310 |    678.639780 | Cesar Julian                                                                                                                                                          |
| 504 |    663.168734 |    305.361400 | Cesar Julian                                                                                                                                                          |
| 505 |    465.323672 |    174.245128 | Matt Crook                                                                                                                                                            |
| 506 |    129.503284 |    716.535269 | Felix Vaux                                                                                                                                                            |
| 507 |    391.393741 |     29.625157 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 508 |    248.614955 |    611.400831 | Matt Crook                                                                                                                                                            |
| 509 |    370.416169 |    766.546287 | Mette Aumala                                                                                                                                                          |
| 510 |    546.563642 |    150.914229 | Juan Carlos Jerí                                                                                                                                                      |
| 511 |    283.561850 |    128.151387 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 512 |    378.552175 |     50.765076 | NA                                                                                                                                                                    |
| 513 |    643.434675 |     79.152041 | T. K. Robinson                                                                                                                                                        |
| 514 |    206.153012 |    142.133150 | Andy Wilson                                                                                                                                                           |
| 515 |    598.180579 |    365.238342 | Walter Vladimir                                                                                                                                                       |
| 516 |    332.736978 |    413.712232 | Margot Michaud                                                                                                                                                        |
| 517 |    789.197168 |    326.691567 | Roberto Díaz Sibaja                                                                                                                                                   |
| 518 |     18.071702 |     47.805445 | Jimmy Bernot                                                                                                                                                          |
| 519 |    285.669771 |     91.709025 | Matt Crook                                                                                                                                                            |
| 520 |    293.901461 |    405.017097 | Steven Traver                                                                                                                                                         |
| 521 |    273.777924 |    316.446207 | Ingo Braasch                                                                                                                                                          |
| 522 |    118.843092 |    522.939843 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 523 |    965.824423 |    787.124039 | Tasman Dixon                                                                                                                                                          |
| 524 |     36.146892 |     91.777415 | Andy Wilson                                                                                                                                                           |
| 525 |    993.504334 |     13.006776 | T. Michael Keesey                                                                                                                                                     |
| 526 |    380.308960 |    750.021573 | Verisimilus                                                                                                                                                           |
| 527 |    260.087715 |    315.735554 | Zimices                                                                                                                                                               |
| 528 |    779.152580 |    423.829536 | Noah Schlottman                                                                                                                                                       |
| 529 |    168.563205 |    332.280019 | Michelle Site                                                                                                                                                         |
| 530 |    361.514597 |    791.179441 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 531 |    782.285506 |    219.344004 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                        |
| 532 |    145.179681 |    162.376913 | Robert Hering                                                                                                                                                         |
| 533 |    886.010877 |    162.644170 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 534 |    608.592995 |    223.813294 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 535 |    522.988636 |    294.760676 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 536 |    303.136407 |    416.327617 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 537 |    739.692474 |    663.609040 | Smokeybjb                                                                                                                                                             |
| 538 |    809.222065 |    269.209445 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 539 |    912.027021 |    170.736671 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 540 |    875.018183 |    710.429639 | Zimices                                                                                                                                                               |
| 541 |    132.896458 |    556.073594 | Andrew A. Farke                                                                                                                                                       |
| 542 |    560.600065 |    328.602256 | Andy Wilson                                                                                                                                                           |
| 543 |    339.086982 |    548.487620 | Dean Schnabel                                                                                                                                                         |
| 544 |    474.815614 |    356.886685 | Iain Reid                                                                                                                                                             |
| 545 |     32.295839 |    277.326661 | Xavier Giroux-Bougard                                                                                                                                                 |
| 546 |    126.530455 |    660.351804 | Zimices                                                                                                                                                               |
| 547 |    861.008822 |    166.826713 | Elizabeth Parker                                                                                                                                                      |
| 548 |    376.066996 |    287.418781 | NA                                                                                                                                                                    |
| 549 |    176.702158 |    203.157055 | Margot Michaud                                                                                                                                                        |
| 550 |    697.163969 |    156.002820 | Ferran Sayol                                                                                                                                                          |
| 551 |    491.075914 |    331.282498 | Tracy A. Heath                                                                                                                                                        |
| 552 |    113.460825 |    562.519804 | Henry Lydecker                                                                                                                                                        |
| 553 |    155.611127 |    540.116818 | Jagged Fang Designs                                                                                                                                                   |
| 554 |    523.750699 |    341.373851 | Yan Wong from photo by Gyik Toma                                                                                                                                      |
| 555 |    600.806282 |    286.658899 | Smokeybjb                                                                                                                                                             |
| 556 |    554.456425 |    157.287788 | (after Spotila 2004)                                                                                                                                                  |
| 557 |    687.293844 |    491.066242 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 558 |    992.790642 |    124.008098 | Kanako Bessho-Uehara                                                                                                                                                  |
| 559 |     94.935220 |    596.408321 | Jack Mayer Wood                                                                                                                                                       |
| 560 |    262.421327 |    708.236610 | C. Camilo Julián-Caballero                                                                                                                                            |
| 561 |    489.373806 |     21.857241 | Margot Michaud                                                                                                                                                        |
| 562 |    488.970375 |    367.649341 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 563 |    822.736436 |    615.969783 | Renata F. Martins                                                                                                                                                     |
| 564 |    523.497825 |    273.594875 | Gareth Monger                                                                                                                                                         |
| 565 |    291.213798 |    176.810558 | Melissa Broussard                                                                                                                                                     |
| 566 |    424.154570 |    623.341075 | Renato Santos                                                                                                                                                         |
| 567 |    979.334528 |     98.113272 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 568 |    441.241756 |    767.165986 | Zimices                                                                                                                                                               |
| 569 |     18.953527 |    520.256306 | Margot Michaud                                                                                                                                                        |
| 570 |    384.983911 |    728.836736 | NA                                                                                                                                                                    |
| 571 |    325.601011 |    791.498183 | Smokeybjb                                                                                                                                                             |
| 572 |    320.053730 |    163.667905 | Matt Crook                                                                                                                                                            |
| 573 |     35.960237 |    380.308942 | Chris A. Hamilton                                                                                                                                                     |
| 574 |    616.152951 |    741.491321 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 575 |    428.107358 |    757.998414 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 576 |    834.478236 |    703.938447 | Steven Traver                                                                                                                                                         |
| 577 |    176.720159 |    143.510661 | Christoph Schomburg                                                                                                                                                   |
| 578 |    890.763595 |    544.493657 | Chris huh                                                                                                                                                             |
| 579 |    157.921197 |    213.989932 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 580 |    409.632127 |    636.596120 | Abraão B. Leite                                                                                                                                                       |
| 581 |    240.524904 |    359.294644 | Birgit Lang                                                                                                                                                           |
| 582 |    996.266841 |     66.428717 | Jagged Fang Designs                                                                                                                                                   |
| 583 |    538.648544 |    442.609381 | Natalie Claunch                                                                                                                                                       |
| 584 |    545.581090 |    167.686892 | Andy Wilson                                                                                                                                                           |
| 585 |     56.647504 |    531.228739 | xgirouxb                                                                                                                                                              |
| 586 |    403.281202 |    616.159449 | T. Michael Keesey                                                                                                                                                     |
| 587 |    424.847384 |     30.644844 | Ferran Sayol                                                                                                                                                          |
| 588 |    558.054344 |    449.423358 | Jagged Fang Designs                                                                                                                                                   |
| 589 |    211.030521 |    374.003789 | M Kolmann                                                                                                                                                             |
| 590 |    451.067646 |    788.509388 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 591 |    839.498224 |    282.349757 | Matt Crook                                                                                                                                                            |
| 592 |     25.117512 |    683.060587 | Zimices                                                                                                                                                               |
| 593 |    134.717993 |    794.022129 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                  |
| 594 |    971.013289 |    383.502006 | NA                                                                                                                                                                    |
| 595 |    383.980171 |    340.859645 | Matt Crook                                                                                                                                                            |
| 596 |    115.030177 |    125.772655 | Andy Wilson                                                                                                                                                           |
| 597 |    398.210284 |    756.420818 | C. Camilo Julián-Caballero                                                                                                                                            |
| 598 |    217.033748 |    506.206194 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 599 |    283.015944 |    525.798481 | NA                                                                                                                                                                    |
| 600 |    281.124682 |    671.063165 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 601 |      7.167477 |    648.762503 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 602 |     90.146201 |    681.421235 | Sarah Werning                                                                                                                                                         |
| 603 |    791.818259 |    359.299529 | Birgit Lang                                                                                                                                                           |
| 604 |    916.521916 |    466.109504 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 605 |    417.316472 |    222.569115 | Gopal Murali                                                                                                                                                          |
| 606 |    221.326267 |    551.002992 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 607 |    111.107522 |    342.240439 | Collin Gross                                                                                                                                                          |
| 608 |    771.256462 |    253.147401 | Scott Hartman                                                                                                                                                         |
| 609 |    366.674329 |    219.931727 | Scott Hartman                                                                                                                                                         |
| 610 |    142.587016 |    748.139523 | Zimices                                                                                                                                                               |
| 611 |    465.530939 |    482.660205 | Steven Traver                                                                                                                                                         |
| 612 |    820.381768 |    497.431451 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 613 |    640.840485 |    497.017116 | Tauana J. Cunha                                                                                                                                                       |
| 614 |    179.910826 |    451.949615 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 615 |     93.141939 |    569.935000 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 616 |     63.793964 |    522.465345 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 617 |    801.423311 |    419.888763 | NA                                                                                                                                                                    |
| 618 |    271.506760 |     92.116783 | Matt Crook                                                                                                                                                            |
| 619 |    126.089438 |    327.683302 | Oscar Sanisidro                                                                                                                                                       |
| 620 |    369.908185 |    707.848884 | Zimices                                                                                                                                                               |
| 621 |    705.627647 |    242.595978 | T. Michael Keesey                                                                                                                                                     |
| 622 |    622.835869 |    291.101956 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 623 |   1005.067297 |    701.949446 | Ferran Sayol                                                                                                                                                          |
| 624 |    863.644147 |    390.026685 | Joanna Wolfe                                                                                                                                                          |
| 625 |    208.844746 |     46.585107 | Scott Hartman                                                                                                                                                         |
| 626 |    513.952394 |    435.452190 | Smith609 and T. Michael Keesey                                                                                                                                        |
| 627 |    263.344428 |    332.775090 | T. Michael Keesey                                                                                                                                                     |
| 628 |    467.645511 |     11.913826 | Gareth Monger                                                                                                                                                         |
| 629 |    924.456023 |    142.983146 | Zimices                                                                                                                                                               |
| 630 |    678.188951 |    706.078059 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 631 |    723.095885 |    313.066971 | Matt Crook                                                                                                                                                            |
| 632 |    618.556714 |    660.855884 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 633 |    681.180170 |    632.544761 | Sarah Werning                                                                                                                                                         |
| 634 |    357.536937 |    420.721366 | Pete Buchholz                                                                                                                                                         |
| 635 |     52.908080 |    213.875989 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
| 636 |    630.634541 |    645.799638 | Chloé Schmidt                                                                                                                                                         |
| 637 |    733.887050 |    481.437218 | Tasman Dixon                                                                                                                                                          |
| 638 |    351.428585 |    394.145499 | NA                                                                                                                                                                    |
| 639 |    349.743376 |    699.694821 | Chris huh                                                                                                                                                             |
| 640 |    682.931551 |    118.199135 | Andrew A. Farke                                                                                                                                                       |
| 641 |    348.589085 |    489.947816 | Sharon Wegner-Larsen                                                                                                                                                  |
| 642 |    855.478612 |    751.755710 | Matt Crook                                                                                                                                                            |
| 643 |    809.410447 |    349.123070 | terngirl                                                                                                                                                              |
| 644 |    746.579084 |     88.713334 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 645 |    778.936234 |    712.090745 | Lauren Anderson                                                                                                                                                       |
| 646 |    261.216122 |    417.567128 | Steven Traver                                                                                                                                                         |
| 647 |    114.977425 |     21.441991 | Zimices                                                                                                                                                               |
| 648 |    251.987020 |    792.958839 | Zimices                                                                                                                                                               |
| 649 |    501.492410 |    171.422123 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 650 |    638.819166 |    265.981624 | Andrew A. Farke                                                                                                                                                       |
| 651 |    782.414204 |    265.040379 | Martin R. Smith                                                                                                                                                       |
| 652 |     52.898580 |     96.705759 | Kent Elson Sorgon                                                                                                                                                     |
| 653 |    960.586293 |    692.387461 | NA                                                                                                                                                                    |
| 654 |    276.470114 |    792.235090 | Steven Coombs                                                                                                                                                         |
| 655 |    982.530624 |     60.427151 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 656 |    483.157106 |    308.389630 | Manabu Bessho-Uehara                                                                                                                                                  |
| 657 |   1008.935803 |    685.526972 | Ingo Braasch                                                                                                                                                          |
| 658 |    339.814196 |    151.408585 | Jagged Fang Designs                                                                                                                                                   |
| 659 |    878.575104 |     29.629009 | Becky Barnes                                                                                                                                                          |
| 660 |    512.328660 |     98.761441 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 661 |    286.808371 |    555.285663 | Jagged Fang Designs                                                                                                                                                   |
| 662 |    767.277556 |    426.341292 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 663 |    331.592178 |    538.926478 | Andrew A. Farke                                                                                                                                                       |
| 664 |    572.176032 |    597.763393 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 665 |    945.483418 |    142.113671 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 666 |    953.686149 |    326.798209 | Scott Hartman                                                                                                                                                         |
| 667 |    360.097476 |    285.585478 | Zimices                                                                                                                                                               |
| 668 |     39.580908 |    148.479382 | Mattia Menchetti                                                                                                                                                      |
| 669 |    495.187620 |    449.159916 | Joanna Wolfe                                                                                                                                                          |
| 670 |    966.265001 |    770.961662 | Tracy A. Heath                                                                                                                                                        |
| 671 |    832.703819 |    210.277305 | xgirouxb                                                                                                                                                              |
| 672 |    139.708938 |    654.790611 | FJDegrange                                                                                                                                                            |
| 673 |    531.667550 |    333.801374 | Nobu Tamura                                                                                                                                                           |
| 674 |    214.556128 |     10.497416 | Steven Traver                                                                                                                                                         |
| 675 |     83.982548 |    615.063294 | Terpsichores                                                                                                                                                          |
| 676 |   1012.008245 |    721.793558 | Inessa Voet                                                                                                                                                           |
| 677 |    124.155124 |    509.962365 | Steven Traver                                                                                                                                                         |
| 678 |    739.621148 |    141.169766 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 679 |    992.128913 |    770.355010 | T. Michael Keesey (after MPF)                                                                                                                                         |
| 680 |    541.269238 |    595.094893 | Gareth Monger                                                                                                                                                         |
| 681 |    337.289065 |    179.534259 | Erika Schumacher                                                                                                                                                      |
| 682 |    411.516230 |    794.027529 | Javiera Constanzo                                                                                                                                                     |
| 683 |    449.402766 |    227.535076 | Andy Wilson                                                                                                                                                           |
| 684 |    314.686961 |    525.568200 | Tod Robbins                                                                                                                                                           |
| 685 |    280.176795 |    503.246741 | Jagged Fang Designs                                                                                                                                                   |
| 686 |    809.456329 |    597.387191 | Zimices                                                                                                                                                               |
| 687 |    401.223854 |    596.199397 | L. Shyamal                                                                                                                                                            |
| 688 |    665.903509 |    259.581816 | Scott Hartman                                                                                                                                                         |
| 689 |    480.560590 |    404.611068 | Mattia Menchetti                                                                                                                                                      |
| 690 |    659.501184 |    781.595961 | Markus A. Grohme                                                                                                                                                      |
| 691 |    113.433781 |    712.686169 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 692 |    831.459847 |    152.788533 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 693 |    652.663109 |    557.505283 | Lukasiniho                                                                                                                                                            |
| 694 |    997.286584 |    468.096831 | Gopal Murali                                                                                                                                                          |
| 695 |    784.421992 |    580.348500 | Karina Garcia                                                                                                                                                         |
| 696 |    944.073391 |    127.205030 | Alex Slavenko                                                                                                                                                         |
| 697 |    251.661369 |    319.002957 | Zimices                                                                                                                                                               |
| 698 |    917.579331 |    475.398967 | Christoph Schomburg                                                                                                                                                   |
| 699 |    329.808664 |    485.724632 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                      |
| 700 |    752.734156 |    313.075575 | Ludwik Gąsiorowski                                                                                                                                                    |
| 701 |   1011.828921 |    488.776359 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 702 |    249.967424 |    506.807915 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 703 |    892.139441 |    331.878534 | Matt Crook                                                                                                                                                            |
| 704 |    218.813203 |     45.259592 | Dean Schnabel                                                                                                                                                         |
| 705 |    853.800574 |      7.717945 | Smokeybjb                                                                                                                                                             |
| 706 |    525.611504 |    354.801535 | Inessa Voet                                                                                                                                                           |
| 707 |    664.290671 |    324.115467 | Zimices                                                                                                                                                               |
| 708 |    279.993056 |    492.690758 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 709 |    534.007310 |    284.260574 | Maija Karala                                                                                                                                                          |
| 710 |    979.374843 |    695.252694 | Gareth Monger                                                                                                                                                         |
| 711 |    435.132049 |     16.998603 | Erika Schumacher                                                                                                                                                      |
| 712 |    395.728181 |    698.144640 | Gareth Monger                                                                                                                                                         |
| 713 |    914.900002 |    188.117723 | Andy Wilson                                                                                                                                                           |
| 714 |     29.416729 |     38.436463 | Margot Michaud                                                                                                                                                        |
| 715 |    971.189155 |    224.523642 | Ieuan Jones                                                                                                                                                           |
| 716 |    446.136674 |    724.296703 | T. Michael Keesey                                                                                                                                                     |
| 717 |    862.790463 |    676.569027 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
| 718 |    617.145691 |    405.200577 | Markus A. Grohme                                                                                                                                                      |
| 719 |    658.557150 |    790.552263 | Gareth Monger                                                                                                                                                         |
| 720 |    868.816696 |    341.826911 | Birgit Lang                                                                                                                                                           |
| 721 |     87.377893 |    155.367387 | Ferran Sayol                                                                                                                                                          |
| 722 |    643.214722 |    416.525253 | Zimices                                                                                                                                                               |
| 723 |      7.386574 |    144.458224 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 724 |    883.705633 |    277.186662 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 725 |    339.583901 |    688.092832 | Zimices                                                                                                                                                               |
| 726 |    124.730513 |    735.900108 | Alexandre Vong                                                                                                                                                        |
| 727 |    209.296448 |    659.829154 | Chris huh                                                                                                                                                             |
| 728 |    259.837321 |    537.514155 | xgirouxb                                                                                                                                                              |
| 729 |    955.993228 |    388.007577 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 730 |     95.404765 |    522.996539 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 731 |     97.216580 |    397.280717 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 732 |     56.462042 |      6.913691 | Birgit Lang                                                                                                                                                           |
| 733 |    341.125598 |    242.646492 | Renata F. Martins                                                                                                                                                     |
| 734 |    696.738894 |    515.115577 | Andrew A. Farke                                                                                                                                                       |
| 735 |    212.735864 |    485.668135 | Ludwik Gąsiorowski                                                                                                                                                    |
| 736 |    431.478944 |    458.622454 | Jagged Fang Designs                                                                                                                                                   |
| 737 |    745.282656 |    382.601105 | NA                                                                                                                                                                    |
| 738 |     91.902574 |    242.842124 | Fernando Campos De Domenico                                                                                                                                           |
| 739 |    873.618519 |     66.273446 | New York Zoological Society                                                                                                                                           |
| 740 |    774.194778 |    377.199432 | Katie S. Collins                                                                                                                                                      |
| 741 |    191.661941 |     79.232402 | Mattia Menchetti                                                                                                                                                      |
| 742 |    655.164854 |    431.708505 | Martin R. Smith                                                                                                                                                       |
| 743 |    807.304015 |    582.968281 | Tyler Greenfield                                                                                                                                                      |
| 744 |    837.862108 |     60.024657 | Mike Hanson                                                                                                                                                           |
| 745 |    177.928639 |     50.958781 | T. Michael Keesey                                                                                                                                                     |
| 746 |    115.700741 |    787.625369 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 747 |    190.959104 |    467.130071 | Andrew A. Farke                                                                                                                                                       |
| 748 |    690.206658 |    462.724739 | T. Michael Keesey                                                                                                                                                     |
| 749 |    204.158615 |    671.020312 | Myriam\_Ramirez                                                                                                                                                       |
| 750 |    392.229762 |    527.109855 | Matt Crook                                                                                                                                                            |
| 751 |     24.037766 |     87.189789 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 752 |    617.954453 |    688.856285 | Melissa Ingala                                                                                                                                                        |
| 753 |    854.354076 |     42.203361 | Zimices                                                                                                                                                               |
| 754 |    199.921388 |    374.418986 | NA                                                                                                                                                                    |
| 755 |    603.684482 |    501.012984 | Scott Hartman                                                                                                                                                         |
| 756 |    385.350753 |    784.777702 | Chris huh                                                                                                                                                             |
| 757 |    102.561925 |    287.379507 | Maija Karala                                                                                                                                                          |
| 758 |    543.217143 |    456.100236 | Jagged Fang Designs                                                                                                                                                   |
| 759 |    419.023868 |    167.583192 | Scott Hartman                                                                                                                                                         |
| 760 |    182.714578 |     14.101590 | Matt Crook                                                                                                                                                            |
| 761 |    376.741470 |     25.966873 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 762 |    846.873972 |    290.780475 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 763 |    429.981044 |    383.526192 | Steven Traver                                                                                                                                                         |
| 764 |    910.834069 |    488.335146 | Zachary Quigley                                                                                                                                                       |
| 765 |    397.262255 |    294.955776 | Gareth Monger                                                                                                                                                         |
| 766 |     46.544924 |    261.182983 | Gareth Monger                                                                                                                                                         |
| 767 |    770.791121 |    264.302110 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 768 |     25.819042 |     60.915377 | Tasman Dixon                                                                                                                                                          |
| 769 |   1005.989121 |    779.773463 | Roberto Díaz Sibaja                                                                                                                                                   |
| 770 |    851.911326 |    707.089439 | Ferran Sayol                                                                                                                                                          |
| 771 |    992.765207 |     83.483587 | Taenadoman                                                                                                                                                            |
| 772 |    694.832805 |    692.780638 | Gareth Monger                                                                                                                                                         |
| 773 |    650.304849 |    239.042387 | Gareth Monger                                                                                                                                                         |
| 774 |    896.980609 |    182.069629 | Gareth Monger                                                                                                                                                         |
| 775 |    274.369999 |    294.426937 | T. Michael Keesey                                                                                                                                                     |
| 776 |    413.588992 |     15.706127 | Matt Crook                                                                                                                                                            |
| 777 |    790.203662 |    230.687494 | Gareth Monger                                                                                                                                                         |
| 778 |     85.084832 |    310.876183 | Zimices                                                                                                                                                               |
| 779 |     79.286217 |    257.322861 | NA                                                                                                                                                                    |
| 780 |    769.028209 |    720.768732 | Matt Crook                                                                                                                                                            |
| 781 |    124.591640 |    380.053561 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 782 |    898.041056 |    298.865615 | Zimices                                                                                                                                                               |
| 783 |    347.063038 |    638.699071 | Chris huh                                                                                                                                                             |
| 784 |    310.626212 |    795.953287 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 785 |    595.905616 |    491.260367 | Gareth Monger                                                                                                                                                         |
| 786 |    793.627785 |    130.369689 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 787 |    947.609205 |    135.514837 | Gareth Monger                                                                                                                                                         |
| 788 |    136.488146 |    117.319693 | Matt Crook                                                                                                                                                            |
| 789 |    273.420988 |    375.575295 | Margot Michaud                                                                                                                                                        |
| 790 |    859.004897 |    152.369833 | Lafage                                                                                                                                                                |
| 791 |    757.533043 |    580.703139 | Michael Scroggie                                                                                                                                                      |
| 792 |    975.466158 |    570.137815 | Michele M Tobias                                                                                                                                                      |
| 793 |    380.287793 |    602.966322 | Matt Crook                                                                                                                                                            |
| 794 |    820.916130 |    760.128165 | Andrew A. Farke                                                                                                                                                       |
| 795 |    646.346783 |    432.848981 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 796 |     46.148991 |    280.352409 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 797 |    301.102544 |    717.594020 | Dean Schnabel                                                                                                                                                         |
| 798 |    877.504655 |    173.146616 | Andrew A. Farke                                                                                                                                                       |
| 799 |    456.808169 |    101.767515 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 800 |    541.991113 |    310.329659 | Matt Crook                                                                                                                                                            |
| 801 |    565.799571 |    652.300322 | Chris huh                                                                                                                                                             |
| 802 |    105.453677 |    435.893513 | Zimices                                                                                                                                                               |
| 803 |    561.051006 |    666.773452 | Roberto Díaz Sibaja                                                                                                                                                   |
| 804 |    585.566318 |    166.929015 | Steven Traver                                                                                                                                                         |
| 805 |    789.558735 |     46.567859 | Maija Karala                                                                                                                                                          |
| 806 |    363.800972 |    251.982328 | Maija Karala                                                                                                                                                          |
| 807 |    316.063978 |    303.020442 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 808 |      7.918088 |    195.150389 | Sarah Werning                                                                                                                                                         |
| 809 |    274.808911 |    694.137128 | Steven Traver                                                                                                                                                         |
| 810 |    271.261295 |    175.069510 | Margot Michaud                                                                                                                                                        |
| 811 |    898.351243 |    782.619049 | ArtFavor & annaleeblysse                                                                                                                                              |
| 812 |    145.361624 |     28.843010 | Matt Crook                                                                                                                                                            |
| 813 |    238.994217 |    557.256598 | Chris huh                                                                                                                                                             |
| 814 |    796.626258 |    404.697866 | Adrian Reich                                                                                                                                                          |
| 815 |    241.820868 |    399.145505 | Jack Mayer Wood                                                                                                                                                       |
| 816 |    684.333593 |      7.198704 | Markus A. Grohme                                                                                                                                                      |
| 817 |    849.015678 |    584.272630 | Chris huh                                                                                                                                                             |
| 818 |    283.343239 |     24.084950 | Nina Skinner                                                                                                                                                          |
| 819 |    614.291391 |     91.852847 | Gareth Monger                                                                                                                                                         |
| 820 |    523.533877 |    794.821310 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 821 |    165.573913 |    474.114119 | NA                                                                                                                                                                    |
| 822 |     45.977490 |    528.064407 | Ferran Sayol                                                                                                                                                          |
| 823 |    205.198441 |    362.557507 | Jimmy Bernot                                                                                                                                                          |
| 824 |    652.206629 |     57.591442 | Markus A. Grohme                                                                                                                                                      |
| 825 |    732.217457 |    102.491464 | Xavier Giroux-Bougard                                                                                                                                                 |
| 826 |    416.554432 |    365.864696 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 827 |    238.272518 |    524.552582 | Renato Santos                                                                                                                                                         |
| 828 |    879.878087 |    253.868788 | Scott Hartman                                                                                                                                                         |
| 829 |     76.056738 |    166.983207 | Rebecca Groom                                                                                                                                                         |
| 830 |    682.191751 |     66.002862 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 831 |     16.211092 |    499.799413 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 832 |    267.258828 |    404.448491 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 833 |    993.665468 |    758.443665 | Tauana J. Cunha                                                                                                                                                       |
| 834 |    941.794069 |    205.810840 | Gareth Monger                                                                                                                                                         |
| 835 |    740.333347 |    641.385130 | T. Michael Keesey                                                                                                                                                     |
| 836 |    610.777101 |    263.446117 | Dean Schnabel                                                                                                                                                         |
| 837 |    838.187064 |    667.234204 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 838 |    245.617090 |    283.513393 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 839 |    999.721056 |    446.970279 | Diana Pomeroy                                                                                                                                                         |
| 840 |    880.910001 |    654.866223 | Michael Scroggie                                                                                                                                                      |
| 841 |    861.583372 |    601.491419 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 842 |    497.999942 |    438.499120 | Armin Reindl                                                                                                                                                          |
| 843 |    910.173545 |    127.267220 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
| 844 |    151.616900 |    573.716504 | Chris huh                                                                                                                                                             |
| 845 |    619.510955 |    779.764045 | Steven Traver                                                                                                                                                         |
| 846 |    491.217209 |      5.950365 | Steven Traver                                                                                                                                                         |
| 847 |    721.370483 |    699.205344 | Gareth Monger                                                                                                                                                         |
| 848 |    487.875226 |    794.672690 | Jagged Fang Designs                                                                                                                                                   |
| 849 |     61.177754 |    274.935214 | Zimices                                                                                                                                                               |
| 850 |    451.277402 |    475.932974 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 851 |    452.851117 |    441.318319 | Ferran Sayol                                                                                                                                                          |
| 852 |    170.638758 |    226.234503 | S.Martini                                                                                                                                                             |
| 853 |    261.105670 |    385.859243 | Zimices                                                                                                                                                               |
| 854 |    442.922286 |    482.517316 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 855 |    628.412635 |    234.287135 | François Michonneau                                                                                                                                                   |
| 856 |    800.459281 |    436.658571 | Pete Buchholz                                                                                                                                                         |
| 857 |    885.269882 |    751.538928 | Emily Willoughby                                                                                                                                                      |
| 858 |   1013.948118 |    653.408194 | Kanchi Nanjo                                                                                                                                                          |
| 859 |    246.401287 |    244.981838 | Ferran Sayol                                                                                                                                                          |
| 860 |     14.930418 |    265.604049 | Chris huh                                                                                                                                                             |
| 861 |    644.462736 |    297.838956 | NA                                                                                                                                                                    |
| 862 |    962.580132 |     92.473704 | NA                                                                                                                                                                    |
| 863 |    495.294748 |     47.890323 | Kent Sorgon                                                                                                                                                           |
| 864 |    538.293852 |    554.395608 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 865 |    753.897902 |    669.525643 | Zimices                                                                                                                                                               |
| 866 |    687.269843 |    211.278075 | Oscar Sanisidro                                                                                                                                                       |
| 867 |    851.520532 |    382.475953 | Matt Crook                                                                                                                                                            |
| 868 |    934.633913 |    791.236720 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 869 |    993.254084 |    526.929471 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                            |
| 870 |    701.258265 |    171.488447 | Jaime Headden                                                                                                                                                         |
| 871 |    544.377899 |    137.827980 | Margot Michaud                                                                                                                                                        |
| 872 |    536.916078 |    160.775543 | Mario Quevedo                                                                                                                                                         |
| 873 |    701.531690 |    188.369138 | Sarah Werning                                                                                                                                                         |
| 874 |    931.361594 |    529.620979 | Nobu Tamura                                                                                                                                                           |
| 875 |    522.241459 |    579.565391 | Ferran Sayol                                                                                                                                                          |
| 876 |    697.738895 |    760.329147 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 877 |    353.224438 |    163.640952 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 878 |    945.426003 |    688.742391 | CNZdenek                                                                                                                                                              |
| 879 |    307.076220 |    447.692869 | Kai R. Caspar                                                                                                                                                         |
| 880 |    279.743164 |    396.463138 | Madeleine Price Ball                                                                                                                                                  |
| 881 |   1011.739896 |    188.704167 | Markus A. Grohme                                                                                                                                                      |
| 882 |    959.446913 |    627.968948 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 883 |     85.115876 |    110.850128 | Ferran Sayol                                                                                                                                                          |
| 884 |    519.078586 |    528.694547 | Chris Jennings (Risiatto)                                                                                                                                             |
| 885 |    978.263239 |     10.114500 | Matt Crook                                                                                                                                                            |
| 886 |    912.395478 |      6.039134 | Margot Michaud                                                                                                                                                        |
| 887 |     90.335606 |    628.797692 | Heinrich Harder (vectorized by William Gearty)                                                                                                                        |
| 888 |    951.841212 |    677.079439 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 889 |   1004.888792 |    285.435339 | Erika Schumacher                                                                                                                                                      |
| 890 |    794.840412 |    274.530234 | Renata F. Martins                                                                                                                                                     |
| 891 |    391.569488 |    717.706176 | NA                                                                                                                                                                    |
| 892 |      8.105228 |    549.655757 | NA                                                                                                                                                                    |
| 893 |    472.952403 |    494.348924 | Jagged Fang Designs                                                                                                                                                   |
| 894 |    563.951367 |    145.982138 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 895 |    659.312342 |     36.740705 | Tasman Dixon                                                                                                                                                          |
| 896 |    170.226381 |    397.893850 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 897 |    501.958857 |    423.721485 | François Michonneau                                                                                                                                                   |
| 898 |    902.554447 |    307.495436 | Zimices                                                                                                                                                               |
| 899 |    116.511831 |    576.374381 | Zimices                                                                                                                                                               |
| 900 |    488.469171 |     67.242505 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 901 |    673.689996 |     97.187338 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 902 |    256.066395 |    766.744686 | Sharon Wegner-Larsen                                                                                                                                                  |
| 903 |    488.684547 |    153.137716 | Lukasiniho                                                                                                                                                            |
| 904 |    188.871620 |    145.892499 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 905 |    664.592398 |     68.476004 | Matt Crook                                                                                                                                                            |
| 906 |    356.724304 |     37.303325 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 907 |    151.226511 |    522.761951 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 908 |    455.718242 |    503.442165 | Tasman Dixon                                                                                                                                                          |
| 909 |    821.714853 |    472.601459 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 910 |    132.071172 |    235.888885 | Tasman Dixon                                                                                                                                                          |
| 911 |    635.517610 |     90.656931 | Steven Traver                                                                                                                                                         |
| 912 |    320.233019 |    764.099716 | Melissa Broussard                                                                                                                                                     |
| 913 |    776.581722 |    599.815745 | Margot Michaud                                                                                                                                                        |
| 914 |    524.291324 |    315.461145 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 915 |    602.883344 |     23.561593 | Carlos Cano-Barbacil                                                                                                                                                  |
| 916 |    321.796835 |    427.759411 | Benjamint444                                                                                                                                                          |
| 917 |    253.124412 |     25.797946 | Caleb Brown                                                                                                                                                           |
| 918 |    515.442239 |    489.007769 | Pedro de Siracusa                                                                                                                                                     |

    #> Your tweet has been posted!
