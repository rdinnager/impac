
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

Maija Karala, Matt Crook, Margot Michaud, Ignacio Contreras, Tauana J.
Cunha, Armin Reindl, Iain Reid, Markus A. Grohme, Zimices, Chris huh,
Alexander Schmidt-Lebuhn, Steven Coombs, Matt Martyniuk, Ferran Sayol,
Gabriela Palomo-Munoz, Tyler Greenfield, Emily Willoughby, Tasman Dixon,
Joanna Wolfe, T. Michael Keesey, Mattia Menchetti, Todd Marshall,
vectorized by Zimices, Arthur S. Brum, Noah Schlottman, photo by Martin
V. Sørensen, Mr E? (vectorized by T. Michael Keesey), Mali’o Kodis,
photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>), Nobu
Tamura (vectorized by T. Michael Keesey), Gareth Monger, Blair Perry,
Dmitry Bogdanov (vectorized by T. Michael Keesey), FunkMonk, Dean
Schnabel, Espen Horn (model; vectorized by T. Michael Keesey from a
photo by H. Zell), Scott Hartman, Pete Buchholz, Roberto Díaz Sibaja,
Smokeybjb, Birgit Lang, Noah Schlottman, photo by Casey Dunn, Jagged
Fang Designs, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and
Ulf Jondelius (vectorized by T. Michael Keesey), Sarah Werning, Carlos
Cano-Barbacil, Renato de Carvalho Ferreira, Tracy A. Heath, Jessica Anne
Miller, Michael Scroggie, B. Duygu Özpolat, Robert Bruce Horsfall,
vectorized by Zimices, Isaure Scavezzoni, Óscar San−Isidro (vectorized
by T. Michael Keesey), Steven Traver, Aviceda (photo) & T. Michael
Keesey, Amanda Katzer, Andy Wilson, A. H. Baldwin (vectorized by T.
Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Brad McFeeters (vectorized by T. Michael Keesey), Darren Naish
(vectorized by T. Michael Keesey), Sam Droege (photo) and T. Michael
Keesey (vectorization), Scott Hartman (modified by T. Michael Keesey),
Katie S. Collins, DW Bapst (modified from Mitchell 1990), Leon P. A. M.
Claessens, Patrick M. O’Connor, David M. Unwin, Sibi (vectorized by T.
Michael Keesey), Michelle Site, James R. Spotila and Ray Chatterji,
Kamil S. Jaron, Matthew E. Clapham, Mali’o Kodis, image from the
Biodiversity Heritage Library, Yan Wong, Mateus Zica (modified by T.
Michael Keesey), Martien Brand (original photo), Renato Santos (vector
silhouette), Rebecca Groom, T. Michael Keesey (photo by Darren Swim),
Cesar Julian, Alex Slavenko, Lindberg (vectorized by T. Michael Keesey),
Allison Pease, Mette Aumala, Kevin Sánchez, Mali’o Kodis, photograph by
Melissa Frey, Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall,
Mali’o Kodis, photograph by Hans Hillewaert, xgirouxb, T. Michael Keesey
(after MPF), Ernst Haeckel (vectorized by T. Michael Keesey), CNZdenek,
V. Deepak, John Conway, Doug Backlund (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Kanchi Nanjo, Original
drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Josefine
Bohr Brask, Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., David Orr, Aline M. Ghilardi, Anthony Caravaggi, Jose
Carlos Arenas-Monroy, Mathilde Cordellier, Taenadoman, Jimmy Bernot,
Darren Naish (vectorize by T. Michael Keesey), Sharon Wegner-Larsen,
Mykle Hoban, Charles Doolittle Walcott (vectorized by T. Michael
Keesey), Geoff Shaw, Nobu Tamura, Inessa Voet, Bennet McComish, photo by
Avenue, Liftarn, Florian Pfaff, S.Martini, Nobu Tamura, vectorized by
Zimices, Martin R. Smith, from photo by Jürgen Schoner, Tony Ayling
(vectorized by T. Michael Keesey), Erika Schumacher, Chris Jennings
(vectorized by A. Verrière), Sean McCann, Cristian Osorio & Paula
Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org),
Becky Barnes, Martin R. Smith, after Skovsted et al 2015, Christopher
Watson (photo) and T. Michael Keesey (vectorization), Christine Axon,
Melissa Broussard, FJDegrange, Harold N Eyster, Ingo Braasch, Felix
Vaux, Apokryltaros (vectorized by T. Michael Keesey), C. Camilo
Julián-Caballero, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Caleb M. Brown,
Michael P. Taylor, Jack Mayer Wood, Jonathan Wells, ArtFavor &
annaleeblysse, Michele Tobias, Renata F. Martins, John Gould (vectorized
by T. Michael Keesey), Scott Reid, Danny Cicchetti (vectorized by T.
Michael Keesey), Scott Hartman (vectorized by T. Michael Keesey), Rachel
Shoop, Mason McNair, Gopal Murali, Vanessa Guerra, Michael B. H.
(vectorized by T. Michael Keesey), Mariana Ruiz Villarreal, David Sim
(photograph) and T. Michael Keesey (vectorization), L. Shyamal, Walter
Vladimir, Farelli (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Milton Tan, Conty, Ghedo and T. Michael Keesey, Beth
Reinke, Frank Förster (based on a picture by Hans Hillewaert), Mali’o
Kodis, photograph by “Wildcat Dunny”
(<http://www.flickr.com/people/wildcat_dunny/>), Cagri Cevrim, Philip
Chalmers (vectorized by T. Michael Keesey), Griensteidl and T. Michael
Keesey, Nobu Tamura (vectorized by A. Verrière), C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), Steven Haddock
• Jellywatch.org, Collin Gross, Stuart Humphries, Mihai Dragos
(vectorized by T. Michael Keesey), Chase Brownstein, U.S. National Park
Service (vectorized by William Gearty), Noah Schlottman, Berivan Temiz,
Andrew R. Gehrke, Tom Tarrant (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Manabu Bessho-Uehara, Trond R. Oskars,
Ghedoghedo (vectorized by T. Michael Keesey), Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Matus Valach,
Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Yan Wong from illustration by Charles Orbigny, U.S. Fish
and Wildlife Service (illustration) and Timothy J. Bartley (silhouette),
Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Neil Kelley, Jake Warner, Mathew Wedel, Julien Louys,
Caleb Brown, Pearson Scott Foresman (vectorized by T. Michael Keesey),
Oliver Griffith, Lukasiniho, Saguaro Pictures (source photo) and T.
Michael Keesey, Maxwell Lefroy (vectorized by T. Michael Keesey),
Andreas Hejnol, Yan Wong from illustration by Jules Richard (1907), Skye
McDavid, Shyamal, Robert Gay, Scarlet23 (vectorized by T. Michael
Keesey), NASA, Ludwik Gąsiorowski, Renato Santos, Mercedes Yrayzoz
(vectorized by T. Michael Keesey), Didier Descouens (vectorized by T.
Michael Keesey), Keith Murdock (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Lafage, Crystal Maier, (after Spotila
2004), Mali’o Kodis, image from the Smithsonian Institution, Marie
Russell, Audrey Ely, J. J. Harrison (photo) & T. Michael Keesey, Chloé
Schmidt, Mo Hassan, T. Michael Keesey (after Ponomarenko), Hanyong Pu,
Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming
Zhang, Songhai Jia & T. Michael Keesey, Aadx, H. F. O. March (modified
by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Noah
Schlottman, photo by Gustav Paulay for Moorea Biocode, Michael Day,
Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey
(vectorization), Catherine Yasuda, Juan Carlos Jerí, New York Zoological
Society, DW Bapst (modified from Bulman, 1970), Jonathan Lawley, Louis
Ranjard, Noah Schlottman, photo by David J Patterson, Pedro de Siracusa,
Chris Jennings (Risiatto), Lukas Panzarin (vectorized by T. Michael
Keesey), Terpsichores, Manabu Sakamoto, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Martin Kevil,
Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Christoph
Schomburg, Conty (vectorized by T. Michael Keesey), Martin R. Smith,
Duane Raver/USFWS, Qiang Ou, Verdilak, Jiekun He, Leann Biancani, photo
by Kenneth Clifton, Konsta Happonen, from a CC-BY-NC image by pelhonen
on iNaturalist, Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Zsoldos Márton (vectorized by
T. Michael Keesey), David Tana, Sergio A. Muñoz-Gómez, Kai R. Caspar,
Henry Fairfield Osborn, vectorized by Zimices, Tess Linden, Eduard Solà
(vectorized by T. Michael Keesey), NOAA Great Lakes Environmental
Research Laboratory (illustration) and Timothy J. Bartley (silhouette),
Smokeybjb, vectorized by Zimices, Hugo Gruson, Mathieu Pélissié,
Smokeybjb (vectorized by T. Michael Keesey), Mario Quevedo, H. Filhol
(vectorized by T. Michael Keesey), Falconaumanni and T. Michael Keesey,
Chuanixn Yu, E. Lear, 1819 (vectorization by Yan Wong), Matt Martyniuk
(vectorized by T. Michael Keesey), James I. Kirkland, Luis Alcalá, Mark
A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Pranav Iyer (grey ideas), Christopher
Chávez, Henry Lydecker, Myriam\_Ramirez, Derek Bakken (photograph) and
T. Michael Keesey (vectorization), Riccardo Percudani, M Hutchinson,
Birgit Szabo, Matt Hayes

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    555.690950 |     86.039575 | Maija Karala                                                                                                                                                                    |
|   2 |    591.974191 |    251.836350 | Matt Crook                                                                                                                                                                      |
|   3 |    588.249070 |    695.044173 | Margot Michaud                                                                                                                                                                  |
|   4 |    503.071165 |    746.040093 | Ignacio Contreras                                                                                                                                                               |
|   5 |     73.864416 |    642.728122 | Tauana J. Cunha                                                                                                                                                                 |
|   6 |    842.873572 |    370.062616 | Ignacio Contreras                                                                                                                                                               |
|   7 |    856.632030 |    701.204792 | Armin Reindl                                                                                                                                                                    |
|   8 |    576.446990 |    524.773164 | Margot Michaud                                                                                                                                                                  |
|   9 |    236.589990 |    142.613462 | Iain Reid                                                                                                                                                                       |
|  10 |    872.739596 |    605.455750 | Markus A. Grohme                                                                                                                                                                |
|  11 |     57.362014 |    524.232287 | Zimices                                                                                                                                                                         |
|  12 |    137.254734 |    287.977854 | Chris huh                                                                                                                                                                       |
|  13 |    340.300357 |    218.675289 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
|  14 |    756.212142 |    465.057773 | Steven Coombs                                                                                                                                                                   |
|  15 |    143.200504 |    208.526578 | Matt Crook                                                                                                                                                                      |
|  16 |    315.070327 |    654.093756 | Zimices                                                                                                                                                                         |
|  17 |    166.281725 |    488.613346 | Zimices                                                                                                                                                                         |
|  18 |    765.487082 |    583.679198 | Margot Michaud                                                                                                                                                                  |
|  19 |     82.310576 |    123.355345 | Matt Martyniuk                                                                                                                                                                  |
|  20 |    513.866165 |    637.549079 | NA                                                                                                                                                                              |
|  21 |    313.900626 |    480.631330 | Ferran Sayol                                                                                                                                                                    |
|  22 |    195.362600 |    724.561842 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  23 |    241.753391 |    454.821640 | Markus A. Grohme                                                                                                                                                                |
|  24 |     31.830881 |    211.172210 | Tyler Greenfield                                                                                                                                                                |
|  25 |    722.083434 |    336.183160 | Emily Willoughby                                                                                                                                                                |
|  26 |    859.623383 |    250.016527 | Margot Michaud                                                                                                                                                                  |
|  27 |    891.403644 |    328.409775 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  28 |    926.504599 |     24.738038 | Tasman Dixon                                                                                                                                                                    |
|  29 |    904.535078 |    142.323357 | Joanna Wolfe                                                                                                                                                                    |
|  30 |    413.336559 |    528.564193 | Matt Crook                                                                                                                                                                      |
|  31 |    706.678961 |    720.110823 | Chris huh                                                                                                                                                                       |
|  32 |    298.796736 |    319.430072 | T. Michael Keesey                                                                                                                                                               |
|  33 |    882.226811 |    522.958687 | Mattia Menchetti                                                                                                                                                                |
|  34 |    940.617347 |    676.592861 | Todd Marshall, vectorized by Zimices                                                                                                                                            |
|  35 |    945.480852 |    426.775031 | Zimices                                                                                                                                                                         |
|  36 |    369.479023 |     54.078113 | Arthur S. Brum                                                                                                                                                                  |
|  37 |    815.949113 |    768.151715 | Chris huh                                                                                                                                                                       |
|  38 |    467.787894 |    396.581946 | Tauana J. Cunha                                                                                                                                                                 |
|  39 |    318.386063 |    411.843762 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                    |
|  40 |    711.649555 |     33.303291 | T. Michael Keesey                                                                                                                                                               |
|  41 |    159.319478 |    363.512726 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                         |
|  42 |    191.433275 |    594.470145 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                                |
|  43 |    251.020798 |     54.004771 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  44 |    962.283330 |    249.941215 | Gareth Monger                                                                                                                                                                   |
|  45 |    441.880216 |    211.406747 | Blair Perry                                                                                                                                                                     |
|  46 |    657.694421 |    408.080955 | Matt Crook                                                                                                                                                                      |
|  47 |    828.255309 |     69.206494 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  48 |    923.802653 |    773.765359 | FunkMonk                                                                                                                                                                        |
|  49 |    323.188255 |    350.088353 | NA                                                                                                                                                                              |
|  50 |    397.452192 |    625.119955 | Dean Schnabel                                                                                                                                                                   |
|  51 |    729.777760 |    670.038016 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                     |
|  52 |    317.088589 |    570.052074 | Scott Hartman                                                                                                                                                                   |
|  53 |    415.948024 |    728.695123 | Matt Crook                                                                                                                                                                      |
|  54 |     73.904438 |    376.931046 | Margot Michaud                                                                                                                                                                  |
|  55 |     94.346214 |     69.458884 | Pete Buchholz                                                                                                                                                                   |
|  56 |    788.091123 |    425.017548 | Roberto Díaz Sibaja                                                                                                                                                             |
|  57 |    811.722924 |    483.296203 | Smokeybjb                                                                                                                                                                       |
|  58 |    702.170050 |    181.297260 | Birgit Lang                                                                                                                                                                     |
|  59 |     76.011722 |    717.570419 | Noah Schlottman, photo by Casey Dunn                                                                                                                                            |
|  60 |     87.650161 |    767.354807 | NA                                                                                                                                                                              |
|  61 |    597.779045 |    629.151472 | Jagged Fang Designs                                                                                                                                                             |
|  62 |    260.726832 |    216.667713 | Scott Hartman                                                                                                                                                                   |
|  63 |    307.130110 |    734.218453 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                        |
|  64 |    641.583544 |    255.125927 | Sarah Werning                                                                                                                                                                   |
|  65 |    616.884072 |    762.906762 | Carlos Cano-Barbacil                                                                                                                                                            |
|  66 |    249.569754 |     20.907794 | Markus A. Grohme                                                                                                                                                                |
|  67 |    983.865362 |    515.076501 | T. Michael Keesey                                                                                                                                                               |
|  68 |    684.506965 |    538.283257 | Renato de Carvalho Ferreira                                                                                                                                                     |
|  69 |    396.059182 |    104.215393 | Maija Karala                                                                                                                                                                    |
|  70 |    951.058602 |     69.311050 | Tasman Dixon                                                                                                                                                                    |
|  71 |    436.707482 |    463.818200 | Jagged Fang Designs                                                                                                                                                             |
|  72 |    215.439394 |     90.182856 | Zimices                                                                                                                                                                         |
|  73 |    341.915909 |    390.228407 | Zimices                                                                                                                                                                         |
|  74 |    564.788028 |    468.306285 | Tracy A. Heath                                                                                                                                                                  |
|  75 |    231.252393 |    683.184722 | Iain Reid                                                                                                                                                                       |
|  76 |     66.103511 |    241.849242 | Jessica Anne Miller                                                                                                                                                             |
|  77 |    773.548307 |    512.791482 | Pete Buchholz                                                                                                                                                                   |
|  78 |    821.445002 |    124.397494 | Joanna Wolfe                                                                                                                                                                    |
|  79 |    858.443265 |    395.119177 | Pete Buchholz                                                                                                                                                                   |
|  80 |    400.081965 |    672.334210 | Michael Scroggie                                                                                                                                                                |
|  81 |    290.956627 |    778.159692 | B. Duygu Özpolat                                                                                                                                                                |
|  82 |    525.248524 |    424.713053 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
|  83 |     55.340626 |     38.961784 | Isaure Scavezzoni                                                                                                                                                               |
|  84 |    966.944106 |    617.378126 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  85 |    837.678672 |     33.576182 | Smokeybjb                                                                                                                                                                       |
|  86 |    921.809746 |    275.748063 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                                              |
|  87 |    301.923265 |    229.039829 | Steven Traver                                                                                                                                                                   |
|  88 |    166.188447 |     22.395605 | T. Michael Keesey                                                                                                                                                               |
|  89 |    988.751735 |    362.837910 | NA                                                                                                                                                                              |
|  90 |    260.628640 |    599.896126 | Steven Traver                                                                                                                                                                   |
|  91 |    685.069155 |     93.762124 | Sarah Werning                                                                                                                                                                   |
|  92 |    535.371888 |    673.582529 | Jessica Anne Miller                                                                                                                                                             |
|  93 |    657.849142 |    597.115789 | Aviceda (photo) & T. Michael Keesey                                                                                                                                             |
|  94 |    983.231679 |    172.373291 | Amanda Katzer                                                                                                                                                                   |
|  95 |    268.077255 |    787.620075 | Andy Wilson                                                                                                                                                                     |
|  96 |    302.865957 |    551.946515 | Gareth Monger                                                                                                                                                                   |
|  97 |    588.340258 |    136.108887 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                 |
|  98 |    332.948469 |    761.523269 | Ferran Sayol                                                                                                                                                                    |
|  99 |     16.395470 |     72.746671 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 100 |    911.317638 |    473.276569 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 101 |    818.283655 |    649.785998 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 102 |    372.910969 |    270.042990 | Dean Schnabel                                                                                                                                                                   |
| 103 |    920.638021 |    643.417448 | Zimices                                                                                                                                                                         |
| 104 |     96.121156 |    225.369468 | NA                                                                                                                                                                              |
| 105 |    485.725949 |    576.735603 | Michael Scroggie                                                                                                                                                                |
| 106 |    273.790727 |    134.700353 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 107 |    835.103340 |    186.665084 | Scott Hartman                                                                                                                                                                   |
| 108 |    351.183607 |    789.970856 | Jagged Fang Designs                                                                                                                                                             |
| 109 |    920.658097 |    492.048803 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
| 110 |    175.472641 |    230.306881 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 111 |    566.464229 |    675.623367 | Chris huh                                                                                                                                                                       |
| 112 |    555.356394 |    579.628330 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
| 113 |    203.414507 |    383.228082 | Steven Traver                                                                                                                                                                   |
| 114 |     99.250135 |    597.567901 | Zimices                                                                                                                                                                         |
| 115 |    314.474364 |      5.131657 | Scott Hartman                                                                                                                                                                   |
| 116 |    437.144319 |    771.733703 | Katie S. Collins                                                                                                                                                                |
| 117 |    367.134675 |    317.535707 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 118 |    344.733629 |    311.411071 | Matt Crook                                                                                                                                                                      |
| 119 |     92.112948 |    317.970343 | Zimices                                                                                                                                                                         |
| 120 |     24.026277 |     27.333342 | Tasman Dixon                                                                                                                                                                    |
| 121 |    798.941398 |     28.448343 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 122 |     75.098319 |    448.175171 | DW Bapst (modified from Mitchell 1990)                                                                                                                                          |
| 123 |    510.560535 |    691.194642 | Mattia Menchetti                                                                                                                                                                |
| 124 |    759.506470 |    387.148464 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                    |
| 125 |    366.273525 |    143.844163 | Tasman Dixon                                                                                                                                                                    |
| 126 |    518.709223 |    156.823075 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                          |
| 127 |    989.503442 |    742.816435 | Michelle Site                                                                                                                                                                   |
| 128 |    169.320341 |    440.288665 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 129 |    218.946248 |    435.304691 | Scott Hartman                                                                                                                                                                   |
| 130 |    408.528881 |    600.005970 | Matt Crook                                                                                                                                                                      |
| 131 |    726.669449 |    788.660552 | Maija Karala                                                                                                                                                                    |
| 132 |    308.611306 |    518.725323 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 133 |   1013.341645 |    712.951064 | Kamil S. Jaron                                                                                                                                                                  |
| 134 |     39.136763 |    284.194554 | Matthew E. Clapham                                                                                                                                                              |
| 135 |    399.051330 |    135.748504 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                      |
| 136 |    992.501113 |    227.125091 | Yan Wong                                                                                                                                                                        |
| 137 |    323.930701 |     11.201491 | Steven Traver                                                                                                                                                                   |
| 138 |    499.105262 |    491.930708 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                                     |
| 139 |    651.457014 |    112.658504 | Margot Michaud                                                                                                                                                                  |
| 140 |    222.816346 |    217.808770 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 141 |    298.936521 |    164.191052 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                               |
| 142 |    520.774329 |    382.026221 | NA                                                                                                                                                                              |
| 143 |    591.930639 |    591.021227 | Zimices                                                                                                                                                                         |
| 144 |    879.903851 |    586.473275 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 145 |    995.633230 |    430.064861 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 146 |    181.417714 |     66.237902 | Jagged Fang Designs                                                                                                                                                             |
| 147 |    346.779590 |    141.717836 | NA                                                                                                                                                                              |
| 148 |    836.279434 |    739.406578 | Rebecca Groom                                                                                                                                                                   |
| 149 |    236.847673 |    775.623019 | Zimices                                                                                                                                                                         |
| 150 |    882.743010 |    637.178331 | Margot Michaud                                                                                                                                                                  |
| 151 |      7.913114 |    444.304360 | T. Michael Keesey (photo by Darren Swim)                                                                                                                                        |
| 152 |    959.693889 |    553.342012 | Cesar Julian                                                                                                                                                                    |
| 153 |    340.618506 |    539.627022 | Matt Martyniuk                                                                                                                                                                  |
| 154 |    300.725620 |    750.033618 | Chris huh                                                                                                                                                                       |
| 155 |     22.185911 |    546.293054 | Alex Slavenko                                                                                                                                                                   |
| 156 |    914.718150 |    378.168528 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                      |
| 157 |    905.936393 |    293.016285 | Margot Michaud                                                                                                                                                                  |
| 158 |    961.251402 |    709.671007 | Zimices                                                                                                                                                                         |
| 159 |     88.844699 |    154.375542 | Allison Pease                                                                                                                                                                   |
| 160 |    356.552759 |    604.193163 | Yan Wong                                                                                                                                                                        |
| 161 |    998.244040 |    143.769303 | Matthew E. Clapham                                                                                                                                                              |
| 162 |    836.430691 |    405.961334 | Yan Wong                                                                                                                                                                        |
| 163 |    346.569770 |    693.915198 | Markus A. Grohme                                                                                                                                                                |
| 164 |    923.120232 |    451.007402 | Mette Aumala                                                                                                                                                                    |
| 165 |    233.978401 |    635.628536 | Gareth Monger                                                                                                                                                                   |
| 166 |    114.265972 |    335.971274 | Kevin Sánchez                                                                                                                                                                   |
| 167 |    345.184570 |    289.184724 | Gareth Monger                                                                                                                                                                   |
| 168 |    944.153920 |    181.750021 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                                        |
| 169 |    992.375170 |    321.127658 | Zimices                                                                                                                                                                         |
| 170 |    896.872229 |    188.090005 | Scott Hartman                                                                                                                                                                   |
| 171 |    214.335430 |    317.965091 | NA                                                                                                                                                                              |
| 172 |    399.011903 |     11.349457 | T. Michael Keesey                                                                                                                                                               |
| 173 |     45.402970 |    338.740837 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                           |
| 174 |    141.175312 |    555.989921 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                                     |
| 175 |    371.808737 |    171.590598 | NA                                                                                                                                                                              |
| 176 |     74.640173 |    150.162327 | Ferran Sayol                                                                                                                                                                    |
| 177 |    816.137588 |    440.331495 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                                 |
| 178 |    134.865060 |    615.994229 | Jagged Fang Designs                                                                                                                                                             |
| 179 |    557.436077 |    443.624280 | Rebecca Groom                                                                                                                                                                   |
| 180 |    969.305678 |    428.601382 | xgirouxb                                                                                                                                                                        |
| 181 |    512.606047 |     17.223651 | Ferran Sayol                                                                                                                                                                    |
| 182 |    122.881327 |    163.712296 | Matt Crook                                                                                                                                                                      |
| 183 |    297.065061 |    282.415412 | Sarah Werning                                                                                                                                                                   |
| 184 |    812.361506 |    784.807542 | Steven Traver                                                                                                                                                                   |
| 185 |    282.138978 |    436.516297 | Markus A. Grohme                                                                                                                                                                |
| 186 |    938.289972 |    582.626064 | Zimices                                                                                                                                                                         |
| 187 |    370.331052 |    236.007917 | Alex Slavenko                                                                                                                                                                   |
| 188 |    173.598988 |     56.950376 | Joanna Wolfe                                                                                                                                                                    |
| 189 |    877.213972 |     96.912954 | Matt Crook                                                                                                                                                                      |
| 190 |    241.783358 |    289.273445 | T. Michael Keesey (after MPF)                                                                                                                                                   |
| 191 |    997.233651 |    597.691109 | Andy Wilson                                                                                                                                                                     |
| 192 |    356.410871 |    148.983417 | Ferran Sayol                                                                                                                                                                    |
| 193 |    431.914339 |     44.789716 | Matt Crook                                                                                                                                                                      |
| 194 |    699.248686 |    632.124135 | Jagged Fang Designs                                                                                                                                                             |
| 195 |     20.982614 |    398.059501 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                 |
| 196 |    462.829699 |    659.867288 | CNZdenek                                                                                                                                                                        |
| 197 |    557.380565 |    788.783574 | Matt Crook                                                                                                                                                                      |
| 198 |     15.917094 |    618.871522 | Gareth Monger                                                                                                                                                                   |
| 199 |    874.549543 |    576.149894 | V. Deepak                                                                                                                                                                       |
| 200 |    855.570223 |    171.732079 | Roberto Díaz Sibaja                                                                                                                                                             |
| 201 |    939.635496 |    597.389316 | NA                                                                                                                                                                              |
| 202 |     73.484936 |    790.977946 | John Conway                                                                                                                                                                     |
| 203 |    468.784928 |    631.169819 | Zimices                                                                                                                                                                         |
| 204 |    682.972700 |    692.608006 | CNZdenek                                                                                                                                                                        |
| 205 |    309.397213 |    131.211662 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 206 |    844.397709 |    647.632612 | Kanchi Nanjo                                                                                                                                                                    |
| 207 |     19.732531 |    744.538532 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 208 |    793.647499 |    181.166938 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                          |
| 209 |    425.594897 |    440.133325 | Josefine Bohr Brask                                                                                                                                                             |
| 210 |    999.592167 |    715.286601 | Birgit Lang                                                                                                                                                                     |
| 211 |    165.534462 |    247.470325 | Tasman Dixon                                                                                                                                                                    |
| 212 |    320.841778 |    144.177832 | Chris huh                                                                                                                                                                       |
| 213 |    395.530981 |    281.092684 | Tyler Greenfield                                                                                                                                                                |
| 214 |    938.594548 |    606.176751 | Ferran Sayol                                                                                                                                                                    |
| 215 |    518.897382 |    706.928930 | NA                                                                                                                                                                              |
| 216 |    257.155200 |    106.114947 | T. Michael Keesey                                                                                                                                                               |
| 217 |    547.096986 |    759.659407 | Joanna Wolfe                                                                                                                                                                    |
| 218 |    990.012095 |    754.861392 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                        |
| 219 |    391.438955 |    509.423746 | Matt Crook                                                                                                                                                                      |
| 220 |    801.734740 |    311.937429 | Matt Crook                                                                                                                                                                      |
| 221 |    464.313108 |    526.470239 | David Orr                                                                                                                                                                       |
| 222 |    413.430371 |    387.496506 | Aline M. Ghilardi                                                                                                                                                               |
| 223 |    454.047297 |    793.855229 | Scott Hartman                                                                                                                                                                   |
| 224 |    286.070676 |     93.701618 | Anthony Caravaggi                                                                                                                                                               |
| 225 |    131.831098 |    259.283331 | Michelle Site                                                                                                                                                                   |
| 226 |    962.819398 |    475.273180 | Matt Crook                                                                                                                                                                      |
| 227 |    806.377754 |    157.061264 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 228 |    459.128499 |    784.419612 | Scott Hartman                                                                                                                                                                   |
| 229 |    276.618410 |    658.710132 | Matt Crook                                                                                                                                                                      |
| 230 |    949.978030 |    319.121969 | Mathilde Cordellier                                                                                                                                                             |
| 231 |    119.482822 |    212.540531 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 232 |     96.293031 |     46.939329 | Margot Michaud                                                                                                                                                                  |
| 233 |    610.299595 |    111.688109 | Taenadoman                                                                                                                                                                      |
| 234 |    145.258133 |    435.443122 | Jimmy Bernot                                                                                                                                                                    |
| 235 |    384.528415 |    437.550374 | Matthew E. Clapham                                                                                                                                                              |
| 236 |    830.814319 |    527.491798 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
| 237 |    365.649743 |    508.163019 | Margot Michaud                                                                                                                                                                  |
| 238 |    420.450858 |    671.226347 | Sharon Wegner-Larsen                                                                                                                                                            |
| 239 |    710.038251 |    649.060943 | NA                                                                                                                                                                              |
| 240 |    977.128923 |    788.369148 | NA                                                                                                                                                                              |
| 241 |    333.714618 |    282.704023 | Mykle Hoban                                                                                                                                                                     |
| 242 |    358.790077 |    219.903572 | NA                                                                                                                                                                              |
| 243 |      6.066634 |    271.851132 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                                     |
| 244 |    708.936243 |    747.681587 | Geoff Shaw                                                                                                                                                                      |
| 245 |    680.321788 |    252.267929 | T. Michael Keesey                                                                                                                                                               |
| 246 |    851.796255 |    538.195361 | Nobu Tamura                                                                                                                                                                     |
| 247 |    801.045327 |    674.588542 | Birgit Lang                                                                                                                                                                     |
| 248 |    444.940574 |    248.234352 | Tasman Dixon                                                                                                                                                                    |
| 249 |    571.974320 |    227.070334 | Inessa Voet                                                                                                                                                                     |
| 250 |    153.680335 |    457.876397 | Bennet McComish, photo by Avenue                                                                                                                                                |
| 251 |    523.553263 |    778.971733 | NA                                                                                                                                                                              |
| 252 |    171.896516 |    423.031199 | Mathilde Cordellier                                                                                                                                                             |
| 253 |    784.505209 |    749.143718 | Liftarn                                                                                                                                                                         |
| 254 |    334.152440 |    794.549132 | Ferran Sayol                                                                                                                                                                    |
| 255 |    265.692162 |    654.535787 | Florian Pfaff                                                                                                                                                                   |
| 256 |     15.482341 |    355.634453 | Gareth Monger                                                                                                                                                                   |
| 257 |    778.219543 |    728.827959 | Steven Traver                                                                                                                                                                   |
| 258 |    790.655381 |    349.403637 | Scott Hartman                                                                                                                                                                   |
| 259 |    734.033832 |    483.704956 | Jagged Fang Designs                                                                                                                                                             |
| 260 |    127.956943 |     83.783473 | Margot Michaud                                                                                                                                                                  |
| 261 |    849.992978 |     38.708468 | S.Martini                                                                                                                                                                       |
| 262 |    689.361549 |    266.827777 | Margot Michaud                                                                                                                                                                  |
| 263 |    875.993952 |    750.804871 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 264 |    778.101205 |    638.660867 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 265 |    158.659734 |    527.180796 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                                   |
| 266 |    509.130035 |    401.092110 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 267 |      9.166267 |    530.231495 | Nobu Tamura                                                                                                                                                                     |
| 268 |    262.317233 |    766.241048 | NA                                                                                                                                                                              |
| 269 |    508.963530 |    514.751055 | Gareth Monger                                                                                                                                                                   |
| 270 |    778.853899 |    394.036242 | T. Michael Keesey                                                                                                                                                               |
| 271 |    116.790414 |     25.595205 | Erika Schumacher                                                                                                                                                                |
| 272 |    317.156034 |    102.959479 | Chris Jennings (vectorized by A. Verrière)                                                                                                                                      |
| 273 |    978.561588 |    446.011321 | Jagged Fang Designs                                                                                                                                                             |
| 274 |    508.471098 |    502.542454 | T. Michael Keesey                                                                                                                                                               |
| 275 |     61.186873 |    462.129412 | Gareth Monger                                                                                                                                                                   |
| 276 |    694.449558 |    133.475543 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 277 |    260.719013 |     76.894172 | Sean McCann                                                                                                                                                                     |
| 278 |    980.691118 |    131.728351 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 279 |    807.671320 |    732.141927 | Becky Barnes                                                                                                                                                                    |
| 280 |    320.795125 |    609.324625 | Matt Crook                                                                                                                                                                      |
| 281 |    907.109466 |     89.422652 | Matt Martyniuk                                                                                                                                                                  |
| 282 |      7.881580 |    388.933813 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                      |
| 283 |    680.057441 |    297.573630 | Steven Traver                                                                                                                                                                   |
| 284 |    702.539478 |    697.081909 | Gareth Monger                                                                                                                                                                   |
| 285 |   1015.080620 |    158.133622 | Matt Martyniuk                                                                                                                                                                  |
| 286 |     52.503214 |    698.117273 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                |
| 287 |    217.684460 |    349.490093 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 288 |    946.026498 |    590.806422 | Christine Axon                                                                                                                                                                  |
| 289 |    246.738801 |    134.805154 | T. Michael Keesey                                                                                                                                                               |
| 290 |     45.655551 |    511.400536 | Zimices                                                                                                                                                                         |
| 291 |    660.504002 |    454.146484 | Jagged Fang Designs                                                                                                                                                             |
| 292 |    248.426216 |    430.911082 | Joanna Wolfe                                                                                                                                                                    |
| 293 |    226.229586 |    416.867740 | Ferran Sayol                                                                                                                                                                    |
| 294 |    853.712798 |    418.620516 | Melissa Broussard                                                                                                                                                               |
| 295 |    858.085906 |    440.035102 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 296 |    239.048464 |    195.187159 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 297 |     11.554964 |    668.723084 | Markus A. Grohme                                                                                                                                                                |
| 298 |    393.925918 |    349.567759 | Tasman Dixon                                                                                                                                                                    |
| 299 |    835.213965 |    152.294429 | FJDegrange                                                                                                                                                                      |
| 300 |    324.939477 |    247.100402 | Harold N Eyster                                                                                                                                                                 |
| 301 |    857.272507 |      5.310601 | Rebecca Groom                                                                                                                                                                   |
| 302 |    207.330085 |    421.433459 | Ingo Braasch                                                                                                                                                                    |
| 303 |    115.397274 |    629.226188 | Felix Vaux                                                                                                                                                                      |
| 304 |     33.936672 |     47.484030 | Margot Michaud                                                                                                                                                                  |
| 305 |    775.173922 |    371.666813 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 306 |    939.423271 |    482.331990 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 307 |    710.950782 |    299.734123 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 308 |    859.171973 |    356.370255 | Margot Michaud                                                                                                                                                                  |
| 309 |    999.023840 |    102.141360 | Margot Michaud                                                                                                                                                                  |
| 310 |    445.199565 |    450.271980 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 311 |    957.165801 |    632.551967 | Ignacio Contreras                                                                                                                                                               |
| 312 |    534.463378 |     17.048910 | Ingo Braasch                                                                                                                                                                    |
| 313 |    720.302683 |    244.125254 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)           |
| 314 |    805.187693 |    218.978961 | Caleb M. Brown                                                                                                                                                                  |
| 315 |    917.309794 |    266.221523 | Tracy A. Heath                                                                                                                                                                  |
| 316 |    238.902792 |    373.091056 | Steven Traver                                                                                                                                                                   |
| 317 |    743.381966 |     62.074247 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 318 |    937.186180 |    378.761975 | Scott Hartman                                                                                                                                                                   |
| 319 |    244.332267 |    388.868738 | Iain Reid                                                                                                                                                                       |
| 320 |    412.524813 |    357.461167 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 321 |   1015.287339 |    206.168453 | Michael P. Taylor                                                                                                                                                               |
| 322 |    938.890256 |    361.707545 | Jack Mayer Wood                                                                                                                                                                 |
| 323 |    699.445769 |    250.864517 | B. Duygu Özpolat                                                                                                                                                                |
| 324 |    111.369354 |    143.698478 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 325 |    603.304897 |    567.201226 | Jonathan Wells                                                                                                                                                                  |
| 326 |     12.503563 |    561.371739 | Michelle Site                                                                                                                                                                   |
| 327 |    327.966668 |    197.748736 | Sarah Werning                                                                                                                                                                   |
| 328 |     57.401804 |     78.858109 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 329 |    413.913766 |    348.127932 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                          |
| 330 |    850.255395 |     51.072549 | ArtFavor & annaleeblysse                                                                                                                                                        |
| 331 |    777.327514 |    364.419975 | Jagged Fang Designs                                                                                                                                                             |
| 332 |     90.754100 |    474.592660 | Steven Traver                                                                                                                                                                   |
| 333 |    160.956392 |    519.020961 | Michele Tobias                                                                                                                                                                  |
| 334 |    477.358164 |    267.411540 | Yan Wong                                                                                                                                                                        |
| 335 |    634.881149 |    596.310078 | Scott Hartman                                                                                                                                                                   |
| 336 |    798.478705 |    256.104062 | Renata F. Martins                                                                                                                                                               |
| 337 |    667.889234 |     84.068988 | T. Michael Keesey                                                                                                                                                               |
| 338 |    374.129889 |    130.494705 | Margot Michaud                                                                                                                                                                  |
| 339 |    939.329863 |    297.991048 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                    |
| 340 |    898.128098 |    500.399906 | Jagged Fang Designs                                                                                                                                                             |
| 341 |     11.979949 |    780.835560 | T. Michael Keesey                                                                                                                                                               |
| 342 |    529.320617 |    392.433032 | Birgit Lang                                                                                                                                                                     |
| 343 |    612.000865 |    642.372753 | Scott Hartman                                                                                                                                                                   |
| 344 |    890.203658 |     61.030204 | Sharon Wegner-Larsen                                                                                                                                                            |
| 345 |    102.074084 |    201.661517 | Scott Reid                                                                                                                                                                      |
| 346 |    493.969048 |    247.499678 | Scott Hartman                                                                                                                                                                   |
| 347 |    274.908953 |    700.499505 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                               |
| 348 |    219.608556 |    267.437032 | Maija Karala                                                                                                                                                                    |
| 349 |    449.080990 |    558.716304 | Scott Hartman                                                                                                                                                                   |
| 350 |    127.909805 |    188.069877 | Tracy A. Heath                                                                                                                                                                  |
| 351 |     40.753827 |    330.615879 | Markus A. Grohme                                                                                                                                                                |
| 352 |     48.660032 |    140.295170 | Matt Crook                                                                                                                                                                      |
| 353 |    929.878189 |    107.379830 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 354 |    134.761348 |    373.604919 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                                 |
| 355 |     58.343129 |    265.206807 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
| 356 |    957.019225 |    781.839466 | Caleb M. Brown                                                                                                                                                                  |
| 357 |     54.276372 |     90.161467 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 358 |      8.605789 |    690.985000 | NA                                                                                                                                                                              |
| 359 |    941.516539 |     14.427921 | Tauana J. Cunha                                                                                                                                                                 |
| 360 |    743.745227 |    436.364227 | Ferran Sayol                                                                                                                                                                    |
| 361 |    314.336847 |    187.980412 | FunkMonk                                                                                                                                                                        |
| 362 |    169.380937 |    644.661509 | Zimices                                                                                                                                                                         |
| 363 |    381.299056 |    485.152046 | Rachel Shoop                                                                                                                                                                    |
| 364 |     41.161912 |     92.621932 | Mason McNair                                                                                                                                                                    |
| 365 |    856.220428 |    620.507146 | Tracy A. Heath                                                                                                                                                                  |
| 366 |    543.279511 |    225.047168 | Pete Buchholz                                                                                                                                                                   |
| 367 |    889.774187 |    361.351137 | Jagged Fang Designs                                                                                                                                                             |
| 368 |    612.424255 |    361.868574 | Jagged Fang Designs                                                                                                                                                             |
| 369 |    788.839943 |    262.121056 | NA                                                                                                                                                                              |
| 370 |    112.117208 |    356.384052 | NA                                                                                                                                                                              |
| 371 |    103.776849 |    186.533578 | Sarah Werning                                                                                                                                                                   |
| 372 |    716.611522 |    264.002522 | Jagged Fang Designs                                                                                                                                                             |
| 373 |    873.501181 |    545.490948 | Michael P. Taylor                                                                                                                                                               |
| 374 |    299.177484 |     12.048405 | Gopal Murali                                                                                                                                                                    |
| 375 |    601.930807 |     27.884954 | Scott Hartman                                                                                                                                                                   |
| 376 |    409.539872 |     55.467588 | Vanessa Guerra                                                                                                                                                                  |
| 377 |    370.610972 |    637.726000 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                 |
| 378 |    426.094375 |      8.393726 | Mariana Ruiz Villarreal                                                                                                                                                         |
| 379 |    402.466811 |    691.293878 | Chris huh                                                                                                                                                                       |
| 380 |    836.864481 |    106.572859 | Pete Buchholz                                                                                                                                                                   |
| 381 |    974.707350 |    319.461840 | Birgit Lang                                                                                                                                                                     |
| 382 |    662.041593 |    122.374350 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 383 |    676.195033 |    784.099216 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                    |
| 384 |    918.562584 |    249.076255 | Sharon Wegner-Larsen                                                                                                                                                            |
| 385 |    236.122188 |    522.755755 | NA                                                                                                                                                                              |
| 386 |     42.914635 |    254.762191 | Markus A. Grohme                                                                                                                                                                |
| 387 |    699.960585 |    237.220786 | Markus A. Grohme                                                                                                                                                                |
| 388 |    257.315875 |    362.109672 | L. Shyamal                                                                                                                                                                      |
| 389 |    429.388997 |    139.803464 | Walter Vladimir                                                                                                                                                                 |
| 390 |    981.672908 |    433.273812 | Scott Hartman                                                                                                                                                                   |
| 391 |    502.071093 |    531.274055 | Kanchi Nanjo                                                                                                                                                                    |
| 392 |    246.027895 |    270.421910 | Felix Vaux                                                                                                                                                                      |
| 393 |    375.344068 |    596.573544 | Markus A. Grohme                                                                                                                                                                |
| 394 |    651.592308 |     98.263499 | Smokeybjb                                                                                                                                                                       |
| 395 |     93.770437 |    436.613069 | James R. Spotila and Ray Chatterji                                                                                                                                              |
| 396 |    669.709198 |     60.647078 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 397 |    749.836978 |    639.426456 | Melissa Broussard                                                                                                                                                               |
| 398 |    869.835139 |    167.713270 | Milton Tan                                                                                                                                                                      |
| 399 |    238.909612 |    206.534202 | Matt Crook                                                                                                                                                                      |
| 400 |      8.937175 |    792.207645 | Conty                                                                                                                                                                           |
| 401 |    946.140705 |    575.103953 | Melissa Broussard                                                                                                                                                               |
| 402 |    996.163379 |    162.312129 | Yan Wong                                                                                                                                                                        |
| 403 |    478.266144 |    506.973253 | Matt Crook                                                                                                                                                                      |
| 404 |     75.425169 |    486.664538 | Ghedo and T. Michael Keesey                                                                                                                                                     |
| 405 |    655.600467 |     45.812740 | Erika Schumacher                                                                                                                                                                |
| 406 |    962.366889 |    316.074500 | Chris huh                                                                                                                                                                       |
| 407 |    475.067996 |    226.217478 | Beth Reinke                                                                                                                                                                     |
| 408 |    385.865471 |    144.256063 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                           |
| 409 |     79.227818 |    209.667795 | Mali’o Kodis, photograph by “Wildcat Dunny” (<http://www.flickr.com/people/wildcat_dunny/>)                                                                                     |
| 410 |    538.641157 |    572.162704 | Zimices                                                                                                                                                                         |
| 411 |    272.845124 |    616.598544 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 412 |    446.703507 |    574.818375 | Steven Traver                                                                                                                                                                   |
| 413 |     88.906282 |    675.444565 | Geoff Shaw                                                                                                                                                                      |
| 414 |    140.930562 |     25.151844 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 415 |    184.398707 |    313.798785 | Matt Crook                                                                                                                                                                      |
| 416 |    337.878241 |    190.409985 | NA                                                                                                                                                                              |
| 417 |    961.988802 |    351.999322 | Tasman Dixon                                                                                                                                                                    |
| 418 |    780.821600 |    442.676548 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 419 |    984.113237 |    612.685388 | Chris huh                                                                                                                                                                       |
| 420 |    635.906939 |    325.226560 | V. Deepak                                                                                                                                                                       |
| 421 |    445.791330 |      5.763077 | Pete Buchholz                                                                                                                                                                   |
| 422 |    635.888724 |     12.298285 | Zimices                                                                                                                                                                         |
| 423 |    984.053943 |    692.902563 | Zimices                                                                                                                                                                         |
| 424 |    948.853653 |    231.772051 | Scott Reid                                                                                                                                                                      |
| 425 |    568.200770 |    551.180925 | Cagri Cevrim                                                                                                                                                                    |
| 426 |   1001.382151 |    650.038707 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                               |
| 427 |    808.106804 |    104.965869 | Griensteidl and T. Michael Keesey                                                                                                                                               |
| 428 |    803.473768 |    402.514576 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                         |
| 429 |    346.074932 |    769.138802 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                   |
| 430 |    998.336522 |    114.137009 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 431 |    301.390369 |    509.934610 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                               |
| 432 |    582.861020 |    232.502125 | Tracy A. Heath                                                                                                                                                                  |
| 433 |     11.791278 |    467.700502 | Collin Gross                                                                                                                                                                    |
| 434 |    818.605759 |    323.410245 | NA                                                                                                                                                                              |
| 435 |    837.874473 |    669.439800 | Tracy A. Heath                                                                                                                                                                  |
| 436 |    138.014283 |    110.378443 | NA                                                                                                                                                                              |
| 437 |    772.659615 |     12.190997 | Stuart Humphries                                                                                                                                                                |
| 438 |    456.032216 |    118.557340 | Ferran Sayol                                                                                                                                                                    |
| 439 |    732.808456 |    411.909301 | Zimices                                                                                                                                                                         |
| 440 |    145.197513 |    751.439035 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                  |
| 441 |    683.244132 |    316.617300 | Scott Hartman                                                                                                                                                                   |
| 442 |    421.365137 |    159.348069 | Margot Michaud                                                                                                                                                                  |
| 443 |   1002.285066 |    124.777473 | Scott Hartman                                                                                                                                                                   |
| 444 |    420.241143 |    587.426489 | Tracy A. Heath                                                                                                                                                                  |
| 445 |     43.729030 |    409.402377 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 446 |    830.512859 |    443.265753 | NA                                                                                                                                                                              |
| 447 |    250.818160 |    664.165738 | Chase Brownstein                                                                                                                                                                |
| 448 |    235.606642 |    392.185148 | Steven Coombs                                                                                                                                                                   |
| 449 |     61.681717 |    323.104760 | Andy Wilson                                                                                                                                                                     |
| 450 |    349.984710 |     20.600300 | Kamil S. Jaron                                                                                                                                                                  |
| 451 |    817.374344 |    344.627675 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                    |
| 452 |    854.699454 |    458.169366 | Margot Michaud                                                                                                                                                                  |
| 453 |    461.184101 |    610.327394 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                                   |
| 454 |     14.715321 |    313.832505 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 455 |    172.060834 |     43.741178 | S.Martini                                                                                                                                                                       |
| 456 |    441.610159 |    635.653194 | Jagged Fang Designs                                                                                                                                                             |
| 457 |    307.994486 |    111.463941 | U.S. National Park Service (vectorized by William Gearty)                                                                                                                       |
| 458 |    599.219540 |      7.311057 | Steven Traver                                                                                                                                                                   |
| 459 |    938.120741 |    239.975849 | Noah Schlottman                                                                                                                                                                 |
| 460 |     30.180527 |     16.664403 | Matt Crook                                                                                                                                                                      |
| 461 |    128.066624 |    355.077364 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 462 |    461.048698 |    644.905066 | Matt Crook                                                                                                                                                                      |
| 463 |     64.572140 |    180.352712 | Scott Hartman                                                                                                                                                                   |
| 464 |    238.500465 |    188.448880 | Berivan Temiz                                                                                                                                                                   |
| 465 |     71.857895 |    403.608653 | Nobu Tamura                                                                                                                                                                     |
| 466 |    623.037249 |     33.699130 | Tasman Dixon                                                                                                                                                                    |
| 467 |    364.108417 |    610.986848 | Andrew R. Gehrke                                                                                                                                                                |
| 468 |    925.437769 |    781.222493 | T. Michael Keesey                                                                                                                                                               |
| 469 |   1007.431897 |    273.377335 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 470 |     79.548188 |     98.404350 | Scott Hartman                                                                                                                                                                   |
| 471 |     11.628171 |    657.213808 | Steven Traver                                                                                                                                                                   |
| 472 |    887.320083 |    653.769441 | Manabu Bessho-Uehara                                                                                                                                                            |
| 473 |    509.749470 |    559.372942 | Trond R. Oskars                                                                                                                                                                 |
| 474 |    915.423245 |    184.971663 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 475 |    563.113427 |    650.689038 | Joanna Wolfe                                                                                                                                                                    |
| 476 |    424.300264 |    558.689954 | Becky Barnes                                                                                                                                                                    |
| 477 |    966.095118 |    502.313537 | Andy Wilson                                                                                                                                                                     |
| 478 |    673.030070 |    494.976430 | Ferran Sayol                                                                                                                                                                    |
| 479 |    381.800390 |    240.166283 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 480 |     94.776453 |    741.755855 | Markus A. Grohme                                                                                                                                                                |
| 481 |    715.523923 |    110.171164 | Matus Valach                                                                                                                                                                    |
| 482 |    737.280965 |    742.614021 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 483 |    157.869371 |    317.459689 | T. Michael Keesey                                                                                                                                                               |
| 484 |    474.989114 |    656.139640 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                 |
| 485 |    144.423625 |    726.173428 | Margot Michaud                                                                                                                                                                  |
| 486 |    804.827124 |    446.136120 | Tyler Greenfield                                                                                                                                                                |
| 487 |    330.399591 |    527.890706 | Steven Coombs                                                                                                                                                                   |
| 488 |    721.358680 |    612.999988 | Scott Hartman                                                                                                                                                                   |
| 489 |    511.540741 |    487.670642 | Chase Brownstein                                                                                                                                                                |
| 490 |    641.105930 |    581.936654 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 491 |    888.716640 |    743.279813 | NA                                                                                                                                                                              |
| 492 |     26.355478 |    147.247872 | Yan Wong from illustration by Charles Orbigny                                                                                                                                   |
| 493 |    103.773720 |    385.783296 | Andy Wilson                                                                                                                                                                     |
| 494 |    975.964143 |    731.573388 | Steven Traver                                                                                                                                                                   |
| 495 |    395.850255 |    420.943974 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 496 |    532.302486 |    738.638927 | Taenadoman                                                                                                                                                                      |
| 497 |    443.387618 |    664.507810 | NA                                                                                                                                                                              |
| 498 |    143.118787 |    176.661670 | Jagged Fang Designs                                                                                                                                                             |
| 499 |   1002.131145 |    442.425999 | Chris huh                                                                                                                                                                       |
| 500 |    868.573740 |    151.149964 | Zimices                                                                                                                                                                         |
| 501 |    549.427054 |    587.006239 | Maija Karala                                                                                                                                                                    |
| 502 |    371.984308 |    788.847298 | Ferran Sayol                                                                                                                                                                    |
| 503 |    420.981521 |    278.482096 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 504 |    597.802618 |     50.477803 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                    |
| 505 |    988.081997 |    700.704270 | John Conway                                                                                                                                                                     |
| 506 |    706.246730 |    761.689307 | Margot Michaud                                                                                                                                                                  |
| 507 |    375.356522 |     76.738308 | Steven Traver                                                                                                                                                                   |
| 508 |   1012.588594 |    460.438700 | Neil Kelley                                                                                                                                                                     |
| 509 |    117.050023 |     21.613986 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 510 |    785.062859 |    792.651342 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                                 |
| 511 |    419.333011 |    420.490475 | Jake Warner                                                                                                                                                                     |
| 512 |     20.906778 |    425.985261 | Mathew Wedel                                                                                                                                                                    |
| 513 |    796.099117 |    788.792343 | Emily Willoughby                                                                                                                                                                |
| 514 |    681.355042 |      8.412862 | Armin Reindl                                                                                                                                                                    |
| 515 |    250.392343 |    489.382638 | Julien Louys                                                                                                                                                                    |
| 516 |    489.856795 |    433.237677 | Zimices                                                                                                                                                                         |
| 517 |    965.904784 |    124.607246 | T. Michael Keesey                                                                                                                                                               |
| 518 |    670.059798 |    706.669276 | Erika Schumacher                                                                                                                                                                |
| 519 |    691.331897 |    281.870263 | Michelle Site                                                                                                                                                                   |
| 520 |    744.981879 |    775.430023 | Becky Barnes                                                                                                                                                                    |
| 521 |    169.399341 |    638.332425 | Caleb Brown                                                                                                                                                                     |
| 522 |    728.860960 |    288.498897 | Jagged Fang Designs                                                                                                                                                             |
| 523 |    407.767318 |    445.057646 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                        |
| 524 |    876.915817 |     49.566919 | Zimices                                                                                                                                                                         |
| 525 |    986.884777 |    241.078070 | Rebecca Groom                                                                                                                                                                   |
| 526 |      8.193347 |    325.004150 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 527 |    297.504917 |    610.260618 | Zimices                                                                                                                                                                         |
| 528 |    668.166948 |    208.306192 | Margot Michaud                                                                                                                                                                  |
| 529 |    333.361854 |    670.297392 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 530 |    413.692368 |    431.003832 | Oliver Griffith                                                                                                                                                                 |
| 531 |    870.414115 |    782.729402 | Chris huh                                                                                                                                                                       |
| 532 |     39.514992 |    454.966149 | Lukasiniho                                                                                                                                                                      |
| 533 |    330.644745 |     69.203247 | Matt Crook                                                                                                                                                                      |
| 534 |    707.717546 |    118.120888 | NA                                                                                                                                                                              |
| 535 |    814.456572 |    209.242708 | Matt Crook                                                                                                                                                                      |
| 536 |    262.598216 |    158.963209 | Matt Crook                                                                                                                                                                      |
| 537 |    820.010862 |    106.495397 | FJDegrange                                                                                                                                                                      |
| 538 |    825.676601 |    491.610418 | T. Michael Keesey                                                                                                                                                               |
| 539 |    340.899539 |    566.610880 | Gareth Monger                                                                                                                                                                   |
| 540 |    213.614623 |    232.278934 | Harold N Eyster                                                                                                                                                                 |
| 541 |     46.498133 |    225.113386 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                           |
| 542 |     11.286386 |    539.592474 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 543 |    207.236555 |    767.860215 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 544 |    228.759585 |    649.139822 | Ferran Sayol                                                                                                                                                                    |
| 545 |    629.388203 |    653.016306 | Collin Gross                                                                                                                                                                    |
| 546 |     98.350393 |    684.482417 | Andreas Hejnol                                                                                                                                                                  |
| 547 |    650.119375 |    490.241471 | Tauana J. Cunha                                                                                                                                                                 |
| 548 |    656.382928 |    717.576597 | NA                                                                                                                                                                              |
| 549 |    855.287642 |    682.197576 | Geoff Shaw                                                                                                                                                                      |
| 550 |    733.419469 |    404.875375 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                              |
| 551 |     19.095894 |    101.145828 | Skye McDavid                                                                                                                                                                    |
| 552 |    580.326482 |    603.135249 | Shyamal                                                                                                                                                                         |
| 553 |    387.274694 |    172.500707 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 554 |     24.594873 |    640.534876 | Chris huh                                                                                                                                                                       |
| 555 |    817.692944 |     11.500888 | Margot Michaud                                                                                                                                                                  |
| 556 |    714.113290 |     90.612355 | NA                                                                                                                                                                              |
| 557 |    131.712644 |      9.168882 | Gareth Monger                                                                                                                                                                   |
| 558 |     60.474243 |    491.536025 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 559 |      8.081448 |    403.628429 | Zimices                                                                                                                                                                         |
| 560 |    997.658204 |    294.898742 | Margot Michaud                                                                                                                                                                  |
| 561 |    148.221587 |    794.790466 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 562 |    385.607542 |    609.116534 | NA                                                                                                                                                                              |
| 563 |     61.233735 |    199.984679 | T. Michael Keesey                                                                                                                                                               |
| 564 |    253.233466 |    371.754721 | T. Michael Keesey                                                                                                                                                               |
| 565 |    945.075744 |    733.431173 | Robert Gay                                                                                                                                                                      |
| 566 |    873.771867 |    410.953472 | NA                                                                                                                                                                              |
| 567 |    126.933151 |     34.421467 | NA                                                                                                                                                                              |
| 568 |    356.833148 |    536.217105 | Emily Willoughby                                                                                                                                                                |
| 569 |    712.041484 |    496.697924 | Zimices                                                                                                                                                                         |
| 570 |    648.586950 |    343.081085 | Chris huh                                                                                                                                                                       |
| 571 |    490.301192 |    552.224156 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                     |
| 572 |    945.560560 |    527.104961 | NASA                                                                                                                                                                            |
| 573 |    535.483968 |    594.298533 | Ludwik Gąsiorowski                                                                                                                                                              |
| 574 |    980.346905 |     17.068891 | Smokeybjb                                                                                                                                                                       |
| 575 |    941.334234 |    506.561758 | Matt Crook                                                                                                                                                                      |
| 576 |    647.961447 |    647.333786 | Matt Crook                                                                                                                                                                      |
| 577 |     22.321781 |    627.418174 | Smokeybjb                                                                                                                                                                       |
| 578 |    695.441356 |     64.736570 | Chris huh                                                                                                                                                                       |
| 579 |    599.553098 |    606.350096 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                        |
| 580 |    168.675075 |    334.453861 | Jagged Fang Designs                                                                                                                                                             |
| 581 |    303.802380 |    202.596460 | Renato Santos                                                                                                                                                                   |
| 582 |     22.974579 |    586.657501 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                              |
| 583 |     48.733576 |    398.975730 | Joanna Wolfe                                                                                                                                                                    |
| 584 |    157.361983 |    259.002799 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 585 |    948.074683 |     42.152196 | Smokeybjb                                                                                                                                                                       |
| 586 |    862.454743 |    180.659043 | U.S. National Park Service (vectorized by William Gearty)                                                                                                                       |
| 587 |    312.656962 |    219.035233 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
| 588 |    438.061814 |    282.288751 | Steven Traver                                                                                                                                                                   |
| 589 |   1016.286877 |    475.604318 | Andy Wilson                                                                                                                                                                     |
| 590 |    939.503837 |    264.221317 | T. Michael Keesey                                                                                                                                                               |
| 591 |    871.241955 |    680.478105 | Steven Traver                                                                                                                                                                   |
| 592 |    112.672726 |    579.437257 | Tasman Dixon                                                                                                                                                                    |
| 593 |    786.110845 |    676.673905 | Scott Hartman                                                                                                                                                                   |
| 594 |    801.050549 |    324.783137 | Ignacio Contreras                                                                                                                                                               |
| 595 |    739.362631 |    767.932036 | Jagged Fang Designs                                                                                                                                                             |
| 596 |    491.301800 |     36.826824 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 597 |    108.821804 |    484.680547 | Maija Karala                                                                                                                                                                    |
| 598 |     55.711961 |    787.349109 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 599 |      9.891175 |    228.615585 | Armin Reindl                                                                                                                                                                    |
| 600 |    572.772510 |    746.624800 | Lafage                                                                                                                                                                          |
| 601 |    993.284536 |    623.753075 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 602 |     90.381011 |    515.597413 | T. Michael Keesey                                                                                                                                                               |
| 603 |    622.009385 |    586.895169 | T. Michael Keesey                                                                                                                                                               |
| 604 |    345.061512 |    513.911565 | Crystal Maier                                                                                                                                                                   |
| 605 |    468.791933 |    618.268036 | (after Spotila 2004)                                                                                                                                                            |
| 606 |    905.889521 |    584.948051 | Scott Hartman                                                                                                                                                                   |
| 607 |    668.770743 |    177.033397 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                            |
| 608 |    470.407429 |    599.474262 | NA                                                                                                                                                                              |
| 609 |    857.676793 |    427.568196 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 610 |    982.497385 |    413.922617 | Robert Gay                                                                                                                                                                      |
| 611 |    246.598190 |    516.658104 | Marie Russell                                                                                                                                                                   |
| 612 |    996.951533 |    452.047840 | NA                                                                                                                                                                              |
| 613 |     10.188281 |    193.115479 | Ferran Sayol                                                                                                                                                                    |
| 614 |    776.423652 |     21.478046 | Zimices                                                                                                                                                                         |
| 615 |    821.425304 |    224.598317 | Audrey Ely                                                                                                                                                                      |
| 616 |    954.364296 |    270.770372 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                                      |
| 617 |    116.826639 |    502.183800 | Sarah Werning                                                                                                                                                                   |
| 618 |    278.053174 |    755.586363 | Chloé Schmidt                                                                                                                                                                   |
| 619 |    199.329606 |    209.301308 | Matt Crook                                                                                                                                                                      |
| 620 |      8.613319 |    712.170174 | Tasman Dixon                                                                                                                                                                    |
| 621 |    596.016737 |    231.763897 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 622 |    300.902132 |    144.028771 | Margot Michaud                                                                                                                                                                  |
| 623 |    286.557813 |    669.974555 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 624 |    499.432067 |    236.852313 | Mo Hassan                                                                                                                                                                       |
| 625 |    295.310383 |    135.684702 | Matt Crook                                                                                                                                                                      |
| 626 |    569.121589 |    144.658411 | Scott Hartman                                                                                                                                                                   |
| 627 |     81.606610 |    412.622282 | Harold N Eyster                                                                                                                                                                 |
| 628 |     97.841111 |    729.733192 | Steven Traver                                                                                                                                                                   |
| 629 |    127.244765 |    599.370777 | Anthony Caravaggi                                                                                                                                                               |
| 630 |    944.567978 |    155.696279 | T. Michael Keesey                                                                                                                                                               |
| 631 |     16.184756 |     36.028729 | Jagged Fang Designs                                                                                                                                                             |
| 632 |    620.006400 |    137.923187 | V. Deepak                                                                                                                                                                       |
| 633 |    961.739807 |    756.231333 | Trond R. Oskars                                                                                                                                                                 |
| 634 |    488.472777 |    607.003322 | T. Michael Keesey                                                                                                                                                               |
| 635 |    448.246593 |     68.606118 | Andy Wilson                                                                                                                                                                     |
| 636 |    995.337086 |    377.865488 | Joanna Wolfe                                                                                                                                                                    |
| 637 |    181.828080 |    535.539071 | Ferran Sayol                                                                                                                                                                    |
| 638 |    162.521276 |    353.806431 | Tasman Dixon                                                                                                                                                                    |
| 639 |    940.688373 |    384.283947 | Tasman Dixon                                                                                                                                                                    |
| 640 |    342.026077 |    118.103653 | Matt Crook                                                                                                                                                                      |
| 641 |     45.341921 |    359.175853 | Scott Hartman                                                                                                                                                                   |
| 642 |    102.911969 |    161.958491 | Ignacio Contreras                                                                                                                                                               |
| 643 |    504.093854 |    164.678410 | T. Michael Keesey (after Ponomarenko)                                                                                                                                           |
| 644 |    279.477628 |    747.613052 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                                     |
| 645 |     75.877323 |    562.503051 | Zimices                                                                                                                                                                         |
| 646 |    108.324045 |    522.773471 | Jagged Fang Designs                                                                                                                                                             |
| 647 |    702.259657 |    291.807417 | Audrey Ely                                                                                                                                                                      |
| 648 |    692.935020 |    492.079971 | Gareth Monger                                                                                                                                                                   |
| 649 |    673.919381 |    647.946479 | Matt Crook                                                                                                                                                                      |
| 650 |    857.685578 |    386.690378 | Birgit Lang                                                                                                                                                                     |
| 651 |    555.799130 |    225.353963 | Aadx                                                                                                                                                                            |
| 652 |    795.774850 |    361.900549 | T. Michael Keesey                                                                                                                                                               |
| 653 |    818.650349 |    302.001928 | H. F. O. March (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                            |
| 654 |    340.137973 |    177.027284 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                                      |
| 655 |    320.080360 |    700.485230 | Jagged Fang Designs                                                                                                                                                             |
| 656 |    368.694175 |    705.659122 | Scott Hartman                                                                                                                                                                   |
| 657 |    149.235236 |    106.855687 | Tasman Dixon                                                                                                                                                                    |
| 658 |    999.701882 |    215.559005 | Maija Karala                                                                                                                                                                    |
| 659 |     48.222013 |    499.849045 | Gareth Monger                                                                                                                                                                   |
| 660 |    380.605978 |    679.456528 | Michael Day                                                                                                                                                                     |
| 661 |    263.913912 |     64.098025 | Tasman Dixon                                                                                                                                                                    |
| 662 |    264.574633 |    357.906553 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 663 |     74.217213 |    726.765454 | NA                                                                                                                                                                              |
| 664 |    615.901117 |    350.815437 | Jagged Fang Designs                                                                                                                                                             |
| 665 |   1011.141086 |    570.086535 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                              |
| 666 |    403.939570 |    165.598143 | Steven Traver                                                                                                                                                                   |
| 667 |    229.278110 |    338.539116 | Carlos Cano-Barbacil                                                                                                                                                            |
| 668 |    246.935461 |    301.764207 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 669 |     69.767719 |     17.191461 | Catherine Yasuda                                                                                                                                                                |
| 670 |    848.931040 |     15.330331 | Tauana J. Cunha                                                                                                                                                                 |
| 671 |    615.984650 |    108.433373 | Carlos Cano-Barbacil                                                                                                                                                            |
| 672 |    115.499696 |    408.929670 | Juan Carlos Jerí                                                                                                                                                                |
| 673 |    727.520874 |    451.079854 | Mykle Hoban                                                                                                                                                                     |
| 674 |    645.764768 |    128.949642 | T. Michael Keesey                                                                                                                                                               |
| 675 |    465.960428 |     20.277920 | Erika Schumacher                                                                                                                                                                |
| 676 |    144.571613 |    536.440164 | T. Michael Keesey                                                                                                                                                               |
| 677 |    992.772096 |    311.585355 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 678 |    607.283796 |    210.453296 | Zimices                                                                                                                                                                         |
| 679 |    209.615709 |    360.376168 | New York Zoological Society                                                                                                                                                     |
| 680 |    958.572491 |    432.485147 | DW Bapst (modified from Bulman, 1970)                                                                                                                                           |
| 681 |    112.637241 |    711.170095 | Scott Hartman                                                                                                                                                                   |
| 682 |    123.584901 |    431.251214 | Jonathan Lawley                                                                                                                                                                 |
| 683 |    837.492400 |    302.307685 | Joanna Wolfe                                                                                                                                                                    |
| 684 |    590.009207 |    568.865854 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 685 |    797.644145 |    138.694725 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
| 686 |    881.158436 |     31.982333 | T. Michael Keesey                                                                                                                                                               |
| 687 |    592.740295 |    652.017310 | Margot Michaud                                                                                                                                                                  |
| 688 |    895.351683 |    724.468110 | Steven Traver                                                                                                                                                                   |
| 689 |    217.819202 |    473.603805 | Louis Ranjard                                                                                                                                                                   |
| 690 |    422.718574 |    167.653162 | Noah Schlottman, photo by David J Patterson                                                                                                                                     |
| 691 |     17.130343 |    300.495982 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                      |
| 692 |    431.187671 |    376.031637 | Matt Crook                                                                                                                                                                      |
| 693 |     26.468389 |    561.375752 | T. Michael Keesey                                                                                                                                                               |
| 694 |    383.394633 |    665.947619 | Carlos Cano-Barbacil                                                                                                                                                            |
| 695 |    104.625090 |    426.528681 | Pedro de Siracusa                                                                                                                                                               |
| 696 |    408.000264 |    567.269030 | Chris Jennings (Risiatto)                                                                                                                                                       |
| 697 |    437.237585 |     75.543795 | NA                                                                                                                                                                              |
| 698 |     36.274232 |    131.695393 | Gareth Monger                                                                                                                                                                   |
| 699 |    884.264169 |    286.786735 | Carlos Cano-Barbacil                                                                                                                                                            |
| 700 |    244.513424 |    594.477855 | Crystal Maier                                                                                                                                                                   |
| 701 |    967.492535 |    195.195017 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                                |
| 702 |    297.739241 |    214.953491 | Steven Traver                                                                                                                                                                   |
| 703 |    375.870795 |    196.770205 | Zimices                                                                                                                                                                         |
| 704 |    104.701662 |     97.317233 | Mattia Menchetti                                                                                                                                                                |
| 705 |    680.610470 |    119.880165 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 706 |    569.750184 |    663.759841 | Terpsichores                                                                                                                                                                    |
| 707 |    971.750624 |    596.882821 | NA                                                                                                                                                                              |
| 708 |    127.525656 |    633.863386 | Tauana J. Cunha                                                                                                                                                                 |
| 709 |    978.473177 |    744.442966 | Manabu Sakamoto                                                                                                                                                                 |
| 710 |    883.247386 |    496.020796 | Chris Jennings (Risiatto)                                                                                                                                                       |
| 711 |    102.481124 |    173.695539 | Iain Reid                                                                                                                                                                       |
| 712 |    894.922235 |    732.572121 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 713 |    169.605426 |    111.878121 | Zimices                                                                                                                                                                         |
| 714 |    785.301303 |    277.715829 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 715 |    521.702717 |    437.416977 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 716 |   1009.352782 |    172.368114 | Steven Traver                                                                                                                                                                   |
| 717 |    626.425813 |    440.777200 | Andy Wilson                                                                                                                                                                     |
| 718 |    903.593611 |    552.659377 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 719 |    936.168673 |    787.567834 | Martin Kevil                                                                                                                                                                    |
| 720 |    158.130331 |     46.885398 | T. Michael Keesey                                                                                                                                                               |
| 721 |     43.074724 |    183.902826 | Kamil S. Jaron                                                                                                                                                                  |
| 722 |     15.793674 |    595.036065 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                                      |
| 723 |    550.770928 |    153.792128 | Zimices                                                                                                                                                                         |
| 724 |    545.607099 |    430.228084 | T. Michael Keesey                                                                                                                                                               |
| 725 |    213.129731 |    183.696661 | Steven Traver                                                                                                                                                                   |
| 726 |    831.483404 |    469.409862 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 727 |    551.272924 |      7.777461 | Sarah Werning                                                                                                                                                                   |
| 728 |    152.925898 |    630.062793 | Michelle Site                                                                                                                                                                   |
| 729 |    121.405235 |    552.434002 | Shyamal                                                                                                                                                                         |
| 730 |     69.370264 |    422.935622 | Gareth Monger                                                                                                                                                                   |
| 731 |   1009.347841 |    684.678673 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 732 |    115.309469 |    198.891377 | Christoph Schomburg                                                                                                                                                             |
| 733 |    710.196438 |    277.866718 | Markus A. Grohme                                                                                                                                                                |
| 734 |    940.295243 |    551.268129 | Chris Jennings (Risiatto)                                                                                                                                                       |
| 735 |    607.756600 |    456.326427 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 736 |   1013.227430 |    392.054177 | Margot Michaud                                                                                                                                                                  |
| 737 |   1008.327951 |    184.605108 | Yan Wong                                                                                                                                                                        |
| 738 |    549.326124 |    137.984198 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 739 |      6.802589 |    418.465333 | NA                                                                                                                                                                              |
| 740 |     48.583472 |    434.397919 | Gareth Monger                                                                                                                                                                   |
| 741 |    810.537195 |    519.791188 | Martin R. Smith                                                                                                                                                                 |
| 742 |    161.390107 |    539.584242 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 743 |    799.399259 |    285.897577 | Lukasiniho                                                                                                                                                                      |
| 744 |    327.100806 |    540.755158 | Andreas Hejnol                                                                                                                                                                  |
| 745 |    910.001158 |    754.490121 | Duane Raver/USFWS                                                                                                                                                               |
| 746 |    589.804477 |    247.309088 | Qiang Ou                                                                                                                                                                        |
| 747 |    751.098297 |    756.215314 | NA                                                                                                                                                                              |
| 748 |    199.212556 |    687.372135 | NA                                                                                                                                                                              |
| 749 |    244.544928 |    780.469414 | David Orr                                                                                                                                                                       |
| 750 |    609.806894 |    415.486318 | Verdilak                                                                                                                                                                        |
| 751 |    956.649155 |    566.181882 | Jiekun He                                                                                                                                                                       |
| 752 |     34.548085 |    732.053774 | T. Michael Keesey                                                                                                                                                               |
| 753 |     47.591353 |     24.832538 | Leann Biancani, photo by Kenneth Clifton                                                                                                                                        |
| 754 |    323.703145 |     87.120418 | NA                                                                                                                                                                              |
| 755 |     19.296715 |    734.584562 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 756 |    370.244593 |    220.639043 | Marie Russell                                                                                                                                                                   |
| 757 |    614.735442 |    248.594228 | Gareth Monger                                                                                                                                                                   |
| 758 |    109.080107 |    797.648466 | Markus A. Grohme                                                                                                                                                                |
| 759 |     92.038316 |     25.970117 | Taenadoman                                                                                                                                                                      |
| 760 |    112.112368 |    111.841737 | Ferran Sayol                                                                                                                                                                    |
| 761 |    614.903774 |    570.814685 | Sibi (vectorized by T. Michael Keesey)                                                                                                                                          |
| 762 |    654.563766 |    189.117147 | Pete Buchholz                                                                                                                                                                   |
| 763 |    313.321730 |    776.142043 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                               |
| 764 |    312.047037 |    293.748612 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                              |
| 765 |     12.365063 |    256.273646 | Rebecca Groom                                                                                                                                                                   |
| 766 |    542.053010 |    450.773228 | Ingo Braasch                                                                                                                                                                    |
| 767 |    881.690851 |    432.039145 | Margot Michaud                                                                                                                                                                  |
| 768 |     42.419302 |    584.314644 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                                |
| 769 |    912.773785 |    627.917630 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 770 |    256.989771 |    339.919909 | Renata F. Martins                                                                                                                                                               |
| 771 |    214.071500 |    169.241144 | NA                                                                                                                                                                              |
| 772 |    976.994309 |    641.896327 | David Tana                                                                                                                                                                      |
| 773 |    283.681785 |    527.764303 | Steven Traver                                                                                                                                                                   |
| 774 |    660.774879 |    748.872128 | Chris huh                                                                                                                                                                       |
| 775 |    654.258109 |    690.717772 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 776 |    323.935581 |    785.536741 | Matt Crook                                                                                                                                                                      |
| 777 |    915.604331 |    205.519035 | Michael Scroggie                                                                                                                                                                |
| 778 |    285.491377 |    473.373104 | Kai R. Caspar                                                                                                                                                                   |
| 779 |    100.375818 |    781.908712 | Arthur S. Brum                                                                                                                                                                  |
| 780 |    964.821265 |    156.859447 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                   |
| 781 |    386.111855 |    180.387248 | Ferran Sayol                                                                                                                                                                    |
| 782 |    805.731155 |    665.317690 | Tess Linden                                                                                                                                                                     |
| 783 |    103.302747 |     16.366162 | Jagged Fang Designs                                                                                                                                                             |
| 784 |    620.685574 |    634.675911 | Andy Wilson                                                                                                                                                                     |
| 785 |    263.023508 |    284.623816 | Andy Wilson                                                                                                                                                                     |
| 786 |    361.763094 |    342.824636 | Kamil S. Jaron                                                                                                                                                                  |
| 787 |    383.600158 |    160.025896 | Steven Traver                                                                                                                                                                   |
| 788 |    905.393883 |    300.518977 | NA                                                                                                                                                                              |
| 789 |     20.296566 |    699.811665 | NA                                                                                                                                                                              |
| 790 |    726.456843 |    652.837329 | Anthony Caravaggi                                                                                                                                                               |
| 791 |    885.028750 |    627.428861 | Ferran Sayol                                                                                                                                                                    |
| 792 |    611.494559 |    218.701668 | xgirouxb                                                                                                                                                                        |
| 793 |    495.689335 |    350.236971 | Zimices                                                                                                                                                                         |
| 794 |    912.153669 |    573.791821 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                   |
| 795 |    905.675765 |    738.841413 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 796 |     58.555178 |    500.705431 | Sean McCann                                                                                                                                                                     |
| 797 |     25.809658 |    365.077997 | Harold N Eyster                                                                                                                                                                 |
| 798 |    528.413245 |    761.709882 | Steven Traver                                                                                                                                                                   |
| 799 |    590.963456 |    674.550979 | Yan Wong                                                                                                                                                                        |
| 800 |    874.117539 |     89.439717 | Jagged Fang Designs                                                                                                                                                             |
| 801 |    120.901412 |    317.190772 | Verdilak                                                                                                                                                                        |
| 802 |    507.109511 |    266.274517 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 803 |    769.392131 |    359.943581 | NA                                                                                                                                                                              |
| 804 |     63.218188 |    476.893995 | NA                                                                                                                                                                              |
| 805 |    725.342587 |    392.398514 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 806 |    984.163033 |    657.261444 | Zimices                                                                                                                                                                         |
| 807 |     21.215842 |    161.349083 | Smokeybjb, vectorized by Zimices                                                                                                                                                |
| 808 |    795.126623 |    722.302567 | Hugo Gruson                                                                                                                                                                     |
| 809 |   1005.345895 |     13.495847 | Tauana J. Cunha                                                                                                                                                                 |
| 810 |    599.839253 |    248.406011 | Mathieu Pélissié                                                                                                                                                                |
| 811 |    668.398847 |    168.627169 | Scott Hartman                                                                                                                                                                   |
| 812 |    452.371722 |    141.164884 | Joanna Wolfe                                                                                                                                                                    |
| 813 |    811.099546 |    465.336698 | Birgit Lang                                                                                                                                                                     |
| 814 |    694.799733 |     74.983773 | Mason McNair                                                                                                                                                                    |
| 815 |    787.935605 |    230.121882 | Tauana J. Cunha                                                                                                                                                                 |
| 816 |    457.620711 |    533.698580 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 817 |    342.722430 |    555.147685 | NA                                                                                                                                                                              |
| 818 |    731.623369 |    111.429699 | Robert Gay                                                                                                                                                                      |
| 819 |    793.139351 |    189.797724 | Jagged Fang Designs                                                                                                                                                             |
| 820 |     47.907957 |      5.463135 | Zimices                                                                                                                                                                         |
| 821 |    150.222504 |    643.921995 | Michael Scroggie                                                                                                                                                                |
| 822 |   1013.095687 |    406.923111 | Zimices                                                                                                                                                                         |
| 823 |    135.469944 |    440.525327 | Kamil S. Jaron                                                                                                                                                                  |
| 824 |    169.514370 |    199.541200 | Mario Quevedo                                                                                                                                                                   |
| 825 |    301.857554 |    105.196688 | Noah Schlottman                                                                                                                                                                 |
| 826 |    633.238541 |    726.698083 | Margot Michaud                                                                                                                                                                  |
| 827 |     12.717380 |    770.320495 | Margot Michaud                                                                                                                                                                  |
| 828 |    822.970151 |     46.267723 | NA                                                                                                                                                                              |
| 829 |    995.543542 |    196.063587 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                                     |
| 830 |    875.395954 |    194.546725 | NA                                                                                                                                                                              |
| 831 |    330.473579 |     31.237153 | Margot Michaud                                                                                                                                                                  |
| 832 |    412.020252 |    408.975492 | Falconaumanni and T. Michael Keesey                                                                                                                                             |
| 833 |    303.153424 |    240.558543 | Chuanixn Yu                                                                                                                                                                     |
| 834 |    654.749823 |    333.588540 | Dean Schnabel                                                                                                                                                                   |
| 835 |    373.566745 |    517.629950 | Tasman Dixon                                                                                                                                                                    |
| 836 |    952.569096 |    703.702553 | Margot Michaud                                                                                                                                                                  |
| 837 |    484.931225 |      4.440178 | FunkMonk                                                                                                                                                                        |
| 838 |    357.924527 |    489.554575 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 839 |     20.199158 |    683.845805 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                                       |
| 840 |    768.636575 |    397.764459 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 841 |    924.807350 |    296.676371 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                |
| 842 |    677.273587 |    270.449972 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 843 |    894.525775 |    489.493527 | NA                                                                                                                                                                              |
| 844 |    323.770214 |    109.515377 | NA                                                                                                                                                                              |
| 845 |    127.397457 |    138.163312 | Margot Michaud                                                                                                                                                                  |
| 846 |    619.465266 |    126.020093 | Gareth Monger                                                                                                                                                                   |
| 847 |    156.363210 |    764.955324 | Zimices                                                                                                                                                                         |
| 848 |    839.960376 |    473.856745 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 849 |     21.270782 |    270.385449 | Matt Crook                                                                                                                                                                      |
| 850 |    616.844002 |    492.491400 | Alex Slavenko                                                                                                                                                                   |
| 851 |    768.001880 |    633.361317 | Sharon Wegner-Larsen                                                                                                                                                            |
| 852 |    394.827080 |    295.902947 | Maija Karala                                                                                                                                                                    |
| 853 |    976.252939 |    762.286770 | Yan Wong                                                                                                                                                                        |
| 854 |    268.269865 |    473.922478 | Andy Wilson                                                                                                                                                                     |
| 855 |    179.267608 |    329.336224 | Kamil S. Jaron                                                                                                                                                                  |
| 856 |    916.587352 |    357.522023 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 857 |    440.648305 |    124.852911 | Jagged Fang Designs                                                                                                                                                             |
| 858 |     94.908619 |    792.991608 | Christopher Chávez                                                                                                                                                              |
| 859 |    585.353810 |    444.956310 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 860 |    963.272778 |    320.699374 | Jagged Fang Designs                                                                                                                                                             |
| 861 |    626.208780 |    624.541066 | Chris huh                                                                                                                                                                       |
| 862 |    236.456438 |    540.217226 | Zimices                                                                                                                                                                         |
| 863 |    401.068782 |    246.084096 | Jagged Fang Designs                                                                                                                                                             |
| 864 |    469.331318 |    177.564680 | Zimices                                                                                                                                                                         |
| 865 |    254.701655 |    644.035120 | Margot Michaud                                                                                                                                                                  |
| 866 |    354.734572 |    413.039278 | Matt Crook                                                                                                                                                                      |
| 867 |    953.497921 |    295.251483 | Margot Michaud                                                                                                                                                                  |
| 868 |    138.501538 |    702.935261 | Henry Lydecker                                                                                                                                                                  |
| 869 |    310.278925 |    619.684516 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 870 |    158.682396 |    225.062237 | Scott Hartman                                                                                                                                                                   |
| 871 |    301.126100 |    359.426734 | CNZdenek                                                                                                                                                                        |
| 872 |    559.760797 |    597.165284 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 873 |     11.554015 |    379.242218 | Gareth Monger                                                                                                                                                                   |
| 874 |    857.351500 |    655.658336 | NA                                                                                                                                                                              |
| 875 |     30.607377 |    758.352409 | Ferran Sayol                                                                                                                                                                    |
| 876 |     86.828208 |    485.077824 | Myriam\_Ramirez                                                                                                                                                                 |
| 877 |    805.988667 |    177.406076 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                                 |
| 878 |    867.020563 |    734.244161 | Zimices                                                                                                                                                                         |
| 879 |     76.179834 |    342.125031 | Matt Crook                                                                                                                                                                      |
| 880 |     89.870542 |    464.689001 | Felix Vaux                                                                                                                                                                      |
| 881 |    662.975250 |    135.270676 | Michelle Site                                                                                                                                                                   |
| 882 |    315.892372 |    535.585630 | Riccardo Percudani                                                                                                                                                              |
| 883 |    768.042407 |    410.215874 | Shyamal                                                                                                                                                                         |
| 884 |    710.992940 |     77.725244 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                   |
| 885 |    588.796774 |    210.259155 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 886 |   1010.558155 |    481.677901 | Zimices                                                                                                                                                                         |
| 887 |    950.911013 |    646.172533 | Nobu Tamura                                                                                                                                                                     |
| 888 |    916.468988 |    442.988941 | Andy Wilson                                                                                                                                                                     |
| 889 |     50.806134 |    153.497151 | Steven Traver                                                                                                                                                                   |
| 890 |    413.810776 |    617.095458 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                        |
| 891 |    122.044231 |    789.328408 | Birgit Lang                                                                                                                                                                     |
| 892 |     75.180453 |     32.360821 | Shyamal                                                                                                                                                                         |
| 893 |    203.110957 |    172.462159 | NA                                                                                                                                                                              |
| 894 |    676.235290 |    479.502287 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 895 |    845.924260 |    404.491781 | Anthony Caravaggi                                                                                                                                                               |
| 896 |    961.184551 |      6.796384 | Gareth Monger                                                                                                                                                                   |
| 897 |    958.521466 |    533.003477 | Matt Crook                                                                                                                                                                      |
| 898 |     39.896090 |    688.549357 | Mathew Wedel                                                                                                                                                                    |
| 899 |    527.604707 |    628.172203 | M Hutchinson                                                                                                                                                                    |
| 900 |    374.972021 |    714.126299 | Erika Schumacher                                                                                                                                                                |
| 901 |    686.290937 |    755.910846 | Michael Scroggie                                                                                                                                                                |
| 902 |    280.726728 |    368.269092 | Gareth Monger                                                                                                                                                                   |
| 903 |    834.579368 |     92.281842 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
| 904 |     98.511748 |    735.639932 | Jack Mayer Wood                                                                                                                                                                 |
| 905 |    818.642146 |    336.883435 | Steven Traver                                                                                                                                                                   |
| 906 |    824.506251 |    402.913640 | Matt Crook                                                                                                                                                                      |
| 907 |    608.101918 |    119.819460 | Matt Crook                                                                                                                                                                      |
| 908 |    931.365046 |    227.898574 | Birgit Szabo                                                                                                                                                                    |
| 909 |    500.511029 |    469.300265 | Milton Tan                                                                                                                                                                      |
| 910 |    758.875755 |    737.530863 | Zimices                                                                                                                                                                         |
| 911 |   1009.310489 |    347.816182 | Joanna Wolfe                                                                                                                                                                    |
| 912 |    468.607723 |    542.046082 | Jose Carlos Arenas-Monroy                                                                                                                                                       |
| 913 |    656.237247 |    659.759432 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 914 |    320.777224 |    181.055820 | Chris huh                                                                                                                                                                       |
| 915 |    823.894455 |    141.559190 | Steven Traver                                                                                                                                                                   |
| 916 |    351.573914 |    324.354369 | Matt Hayes                                                                                                                                                                      |
| 917 |    115.339038 |    158.881336 | Margot Michaud                                                                                                                                                                  |

    #> Your tweet has been posted!
