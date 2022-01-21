
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

Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T.
Michael Keesey), Siobhon Egan, Ignacio Contreras, Mali’o Kodis,
photograph by G. Giribet, Chris huh, Julia B McHugh, Enoch Joseph Wetsy
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Zimices, FunkMonk, Sean McCann, Steven Traver, Henry Lydecker,
Margot Michaud, Ingo Braasch, Michelle Site, Tasman Dixon, Gabriela
Palomo-Munoz, Matt Crook, Gareth Monger, Lukasiniho, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Theodore W. Pietsch (photography) and
T. Michael Keesey (vectorization), Martin R. Smith, after Skovsted et al
2015, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf
Jondelius (vectorized by T. Michael Keesey), Eric Moody, Stanton F. Fink
(vectorized by T. Michael Keesey), T. Michael Keesey, Dexter R. Mardis,
Joe Schneid (vectorized by T. Michael Keesey), Matthias Buschmann
(vectorized by T. Michael Keesey), Rebecca Groom, B. Duygu Özpolat,
Markus A. Grohme, Benjamint444, Felix Vaux, Martin R. Smith, Danny
Cicchetti (vectorized by T. Michael Keesey), Scott Reid, Christoph
Schomburg, Milton Tan, Neil Kelley, Ghedoghedo (vectorized by T. Michael
Keesey), Nobu Tamura (vectorized by T. Michael Keesey), Caleb M. Brown,
Agnello Picorelli, Robbie N. Cada (vectorized by T. Michael Keesey),
Noah Schlottman, photo by Casey Dunn, Ian Burt (original) and T. Michael
Keesey (vectorization), Jagged Fang Designs, Dean Schnabel, Lankester
Edwin Ray (vectorized by T. Michael Keesey), Maxwell Lefroy (vectorized
by T. Michael Keesey), Ferran Sayol, Scott Hartman, Brad McFeeters
(vectorized by T. Michael Keesey), Pete Buchholz, Martien Brand
(original photo), Renato Santos (vector silhouette), Francisco Gascó
(modified by Michael P. Taylor), Smokeybjb (modified by T. Michael
Keesey), Collin Gross, Luis Cunha, Shyamal, Tracy A. Heath, Kenneth
Lacovara (vectorized by T. Michael Keesey), C. Camilo Julián-Caballero,
Smokeybjb, vectorized by Zimices, Jaime Headden, Katie S. Collins, Kent
Sorgon, Didier Descouens (vectorized by T. Michael Keesey), Robert Gay,
Tyler Greenfield, Alan Manson (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Emily Willoughby, Mali’o Kodis, image
from Brockhaus and Efron Encyclopedic Dictionary, Caleb M. Gordon,
JCGiron, Andreas Trepte (vectorized by T. Michael Keesey), Chris
Jennings (Risiatto), Jennifer Trimble, Mike Keesey (vectorization) and
Vaibhavcho (photography), Michael P. Taylor, Eduard Solà Vázquez,
vectorised by Yan Wong, T. Michael Keesey (vectorization) and
HuttyMcphoo (photography), Renato de Carvalho Ferreira, Samanta
Orellana, Arthur S. Brum, Matus Valach, Birgit Lang, Iain Reid, Michael
Scroggie, Kamil S. Jaron, Nobu Tamura, vectorized by Zimices, Mali’o
Kodis, photograph from Jersabek et al, 2003, Roberto Díaz Sibaja, Trond
R. Oskars, Tony Ayling (vectorized by Milton Tan), Jack Mayer Wood, Noah
Schlottman, photo by Hans De Blauwe, Robert Gay, modifed from Olegivvit,
Chris Jennings (vectorized by A. Verrière), Steven Coombs, Bill Bouton
(source photo) & T. Michael Keesey (vectorization), Becky Barnes,
S.Martini, Lafage, Juan Carlos Jerí, Frank Förster, Jaime Headden,
modified by T. Michael Keesey, Steven Haddock • Jellywatch.org, M
Kolmann, Jessica Anne Miller, Kailah Thorn & Mark Hutchinson, Sarah
Werning, Qiang Ou, Alexander Schmidt-Lebuhn, Beth Reinke, Matt Hayes,
Andrew A. Farke, Cesar Julian, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), L. Shyamal,
Noah Schlottman, photo by Martin V. Sørensen, Mathieu Basille, Abraão
Leite, Patrick Fisher (vectorized by T. Michael Keesey), Bryan Carstens,
Sergio A. Muñoz-Gómez, Matt Wilkins, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Aline M.
Ghilardi, Mathew Callaghan, Rachel Shoop, Original drawing by Dmitry
Bogdanov, vectorized by Roberto Díaz Sibaja, Adam Stuart Smith
(vectorized by T. Michael Keesey), Melissa Broussard, Harold N Eyster,
Smokeybjb, Noah Schlottman, photo from Moorea Biocode, Maky
(vectorization), Gabriella Skollar (photography), Rebecca Lewis
(editing), Yan Wong from drawing by Joseph Smit, Steve Hillebrand/U. S.
Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Mattia Menchetti, Filip em, Scott D. Sampson, Mark A.
Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua
A. Smith, Alan L. Titus, Jimmy Bernot, Michael Scroggie, from original
photograph by John Bettaso, USFWS (original photograph in public
domain)., Jiekun He, Noah Schlottman, H. F. O. March (vectorized by T.
Michael Keesey), Ville Koistinen (vectorized by T. Michael Keesey),
Donovan Reginald Rosevear (vectorized by T. Michael Keesey), Owen Jones
(derived from a CC-BY 2.0 photograph by Paulo B. Chaves), Lauren
Anderson, Stacy Spensley (Modified), Crystal Maier, Anthony Caravaggi,
Matt Martyniuk (vectorized by T. Michael Keesey), Stuart Humphries,
Zsoldos Márton (vectorized by T. Michael Keesey), Chase Brownstein,
Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime
Dahirel), Todd Marshall, vectorized by Zimices, Mali’o Kodis, photograph
by P. Funch and R.M. Kristensen, Joanna Wolfe, I. Geoffroy Saint-Hilaire
(vectorized by T. Michael Keesey), Rebecca Groom (Based on Photo by
Andreas Trepte), Blanco et al., 2014, vectorized by Zimices, Pearson
Scott Foresman (vectorized by T. Michael Keesey), Rafael Maia, Félix
Landry Yuan, Richard Parker (vectorized by T. Michael Keesey),
Terpsichores, Joedison Rocha, Lukas Panzarin, Jose Carlos Arenas-Monroy,
Kanako Bessho-Uehara, Tess Linden, Dmitry Bogdanov (modified by T.
Michael Keesey), Mathew Wedel, Hans Hillewaert, Mary Harrsch (modified
by T. Michael Keesey), Mateus Zica (modified by T. Michael Keesey),
Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Mason
McNair, Jonathan Wells, Roderic Page and Lois Page, Javiera Constanzo,
Maija Karala, Armin Reindl, Nicolas Mongiardino Koch, Robbie N. Cada
(modified by T. Michael Keesey), Matt Martyniuk, AnAgnosticGod
(vectorized by T. Michael Keesey), T. Michael Keesey (after Heinrich
Harder), James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong),
Mali’o Kodis, photograph by Bruno Vellutini, Luc Viatour (source
photo) and Andreas Plank, NASA, Raven Amos, Emma Kissling, Ray Simpson
(vectorized by T. Michael Keesey), T. Michael Keesey (after Colin M. L.
Burnett), Henry Fairfield Osborn, vectorized by Zimices, Esme
Ashe-Jepson, George Edward Lodge, SauropodomorphMonarch, George Edward
Lodge (vectorized by T. Michael Keesey), Cristopher Silva, Jerry
Oldenettel (vectorized by T. Michael Keesey), Ricardo Araújo,
Taenadoman, Meliponicultor Itaymbere, Michele M Tobias, Dmitry Bogdanov,
vectorized by Zimices, Chloé Schmidt, Matt Celeskey, Lisa Byrne, Saguaro
Pictures (source photo) and T. Michael Keesey, Cagri Cevrim,
annaleeblysse, Matt Wilkins (photo by Patrick Kavanagh), Noah
Schlottman, photo from Casey Dunn, Hans Hillewaert (vectorized by T.
Michael Keesey), xgirouxb, Kai R. Caspar, Christine Axon, Jakovche,
Wayne Decatur, DW Bapst (Modified from photograph taken by Charles
Mitchell), Sam Fraser-Smith (vectorized by T. Michael Keesey), Gabriel
Lio, vectorized by Zimices, Matthew E. Clapham, Lauren Sumner-Rooney,
Ludwik Gasiorowski, Renata F. Martins, Tomas Willems (vectorized by T.
Michael Keesey), Yan Wong from photo by Denes Emoke, Mo Hassan, Oliver
Voigt, Renato Santos, Berivan Temiz, David Orr, Heinrich Harder
(vectorized by T. Michael Keesey), Maxime Dahirel, Xavier
Giroux-Bougard, Conty (vectorized by T. Michael Keesey), Mario Quevedo,
SecretJellyMan - from Mason McNair, Lily Hughes, Tauana J. Cunha,
Dr. Thomas G. Barnes, USFWS, Chuanixn Yu, Lindberg (vectorized by T.
Michael Keesey), Rainer Schoch, Martin Kevil, Johan Lindgren, Michael W.
Caldwell, Takuya Konishi, Luis M. Chiappe, DW Bapst (modified from Bates
et al., 2005), V. Deepak, Mathilde Cordellier, Ryan Cupo, Matthew Hooge
(vectorized by T. Michael Keesey), SecretJellyMan, Karkemish (vectorized
by T. Michael Keesey), NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette),
Christopher Watson (photo) and T. Michael Keesey (vectorization), Ernst
Haeckel (vectorized by T. Michael Keesey), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
CNZdenek, New York Zoological Society, Tony Ayling (vectorized by T.
Michael Keesey), Daniel Stadtmauer, James Neenan

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    474.413001 |    387.400080 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
|   2 |    170.372074 |    694.864332 | Siobhon Egan                                                                                                                                                          |
|   3 |    584.147661 |    143.194229 | Ignacio Contreras                                                                                                                                                     |
|   4 |    781.670900 |    687.818303 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
|   5 |    380.969350 |    683.650635 | Chris huh                                                                                                                                                             |
|   6 |    114.247802 |    431.324550 | Julia B McHugh                                                                                                                                                        |
|   7 |    528.555639 |    295.079954 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
|   8 |    316.976577 |    615.421363 | Zimices                                                                                                                                                               |
|   9 |    684.689341 |    421.920980 | FunkMonk                                                                                                                                                              |
|  10 |    276.146569 |    509.402661 | Sean McCann                                                                                                                                                           |
|  11 |    332.747098 |    218.235731 | Ignacio Contreras                                                                                                                                                     |
|  12 |    156.306234 |    284.058407 | Steven Traver                                                                                                                                                         |
|  13 |    938.614361 |    512.291566 | Henry Lydecker                                                                                                                                                        |
|  14 |    740.826289 |    528.648573 | Margot Michaud                                                                                                                                                        |
|  15 |    919.368082 |    612.620094 | Ingo Braasch                                                                                                                                                          |
|  16 |    604.252954 |    563.227609 | Michelle Site                                                                                                                                                         |
|  17 |    556.154431 |    683.255921 | Tasman Dixon                                                                                                                                                          |
|  18 |    678.742510 |     68.902679 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  19 |    874.015393 |    109.234311 | Matt Crook                                                                                                                                                            |
|  20 |    478.788968 |     63.914061 | Gareth Monger                                                                                                                                                         |
|  21 |    124.822173 |    173.618842 | Lukasiniho                                                                                                                                                            |
|  22 |    571.315750 |    320.473723 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  23 |    181.526339 |     77.923126 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
|  24 |    452.758105 |    572.004698 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
|  25 |    740.808661 |    315.297347 | Margot Michaud                                                                                                                                                        |
|  26 |    203.605678 |    663.505748 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
|  27 |    843.414201 |    419.199142 | NA                                                                                                                                                                    |
|  28 |    251.795630 |    340.423382 | Eric Moody                                                                                                                                                            |
|  29 |     76.347812 |    564.446697 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
|  30 |    900.576541 |    224.556951 | Ignacio Contreras                                                                                                                                                     |
|  31 |    806.066724 |    605.271353 | T. Michael Keesey                                                                                                                                                     |
|  32 |    741.945269 |    218.949517 | Zimices                                                                                                                                                               |
|  33 |    436.139332 |    145.295426 | NA                                                                                                                                                                    |
|  34 |    103.740506 |    512.494684 | Zimices                                                                                                                                                               |
|  35 |    223.880974 |    135.449228 | Dexter R. Mardis                                                                                                                                                      |
|  36 |    898.153091 |    371.059740 | Steven Traver                                                                                                                                                         |
|  37 |    930.581223 |    722.581201 | FunkMonk                                                                                                                                                              |
|  38 |     80.248890 |    615.874655 | Steven Traver                                                                                                                                                         |
|  39 |     47.548449 |    715.250421 | Steven Traver                                                                                                                                                         |
|  40 |    263.009062 |    166.374244 | Zimices                                                                                                                                                               |
|  41 |    302.878788 |     68.624636 | Gareth Monger                                                                                                                                                         |
|  42 |     63.810501 |    291.947511 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
|  43 |    579.675106 |    220.081091 | Steven Traver                                                                                                                                                         |
|  44 |    546.277209 |    779.313583 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  45 |    546.485972 |    442.219507 | Chris huh                                                                                                                                                             |
|  46 |    206.419470 |    472.154975 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                                  |
|  47 |     80.077756 |    403.609930 | Matt Crook                                                                                                                                                            |
|  48 |    651.858337 |    734.185352 | Rebecca Groom                                                                                                                                                         |
|  49 |    891.751079 |    273.728508 | B. Duygu Özpolat                                                                                                                                                      |
|  50 |    327.717104 |    752.546767 | Tasman Dixon                                                                                                                                                          |
|  51 |    566.161000 |    492.858269 | Markus A. Grohme                                                                                                                                                      |
|  52 |    503.885777 |    715.609892 | NA                                                                                                                                                                    |
|  53 |    402.144156 |    473.754042 | Benjamint444                                                                                                                                                          |
|  54 |    284.118073 |    698.394851 | Felix Vaux                                                                                                                                                            |
|  55 |    712.565899 |    154.452431 | Martin R. Smith                                                                                                                                                       |
|  56 |    351.323602 |    282.824457 | Markus A. Grohme                                                                                                                                                      |
|  57 |    682.272126 |    666.484607 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
|  58 |    919.796308 |    546.601281 | Gareth Monger                                                                                                                                                         |
|  59 |    426.780705 |    213.268733 | Scott Reid                                                                                                                                                            |
|  60 |     31.052843 |     89.214728 | Christoph Schomburg                                                                                                                                                   |
|  61 |    786.012316 |    484.528509 | Milton Tan                                                                                                                                                            |
|  62 |    170.875523 |    768.547075 | Gareth Monger                                                                                                                                                         |
|  63 |    203.862212 |    258.486643 | Neil Kelley                                                                                                                                                           |
|  64 |    967.545356 |    325.959354 | Gareth Monger                                                                                                                                                         |
|  65 |    659.530763 |    235.813639 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  66 |    678.639947 |    375.848776 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  67 |    655.834667 |    511.788019 | NA                                                                                                                                                                    |
|  68 |    535.439326 |    602.932074 | Caleb M. Brown                                                                                                                                                        |
|  69 |    813.670060 |    711.113512 | Zimices                                                                                                                                                               |
|  70 |   1004.650739 |    102.962568 | Agnello Picorelli                                                                                                                                                     |
|  71 |    291.770517 |    403.724137 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
|  72 |    516.673533 |    465.247682 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  73 |    182.782317 |    584.317529 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  74 |    777.850131 |     24.049498 | NA                                                                                                                                                                    |
|  75 |    147.795190 |     26.722978 | Tasman Dixon                                                                                                                                                          |
|  76 |    949.354142 |    465.878482 | NA                                                                                                                                                                    |
|  77 |    371.960247 |    357.008992 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
|  78 |    132.234124 |    725.397148 | T. Michael Keesey                                                                                                                                                     |
|  79 |    587.049984 |    625.488050 | Ignacio Contreras                                                                                                                                                     |
|  80 |    508.988193 |    253.692494 | Christoph Schomburg                                                                                                                                                   |
|  81 |    947.005390 |    196.997608 | Matt Crook                                                                                                                                                            |
|  82 |    114.670231 |    219.029263 | Jagged Fang Designs                                                                                                                                                   |
|  83 |    846.009776 |    645.511362 | Dean Schnabel                                                                                                                                                         |
|  84 |    463.199365 |    123.649748 | Lukasiniho                                                                                                                                                            |
|  85 |    836.372141 |    265.711346 | Milton Tan                                                                                                                                                            |
|  86 |    189.939021 |    609.053536 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
|  87 |   1007.746837 |    687.670486 | Zimices                                                                                                                                                               |
|  88 |     65.112119 |    468.929978 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
|  89 |    156.333421 |    624.680110 | Ferran Sayol                                                                                                                                                          |
|  90 |    675.407999 |    783.180244 | Scott Hartman                                                                                                                                                         |
|  91 |     70.290003 |     31.900052 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
|  92 |    868.327709 |    256.771462 | Jagged Fang Designs                                                                                                                                                   |
|  93 |    234.663074 |    733.887230 | Zimices                                                                                                                                                               |
|  94 |    812.267231 |    673.167738 | Pete Buchholz                                                                                                                                                         |
|  95 |    760.480489 |    400.384503 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  96 |    593.211887 |     81.233132 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
|  97 |    549.386617 |    285.267584 | Margot Michaud                                                                                                                                                        |
|  98 |    906.128272 |    306.853882 | Matt Crook                                                                                                                                                            |
|  99 |    243.228810 |    195.015976 | Zimices                                                                                                                                                               |
| 100 |    960.973974 |    638.749792 | Scott Hartman                                                                                                                                                         |
| 101 |    870.665369 |    783.122901 | T. Michael Keesey                                                                                                                                                     |
| 102 |    601.088700 |    463.508748 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 103 |    444.860972 |    785.290156 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 104 |     94.221993 |     69.465342 | Steven Traver                                                                                                                                                         |
| 105 |    289.021096 |    266.908931 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 106 |    168.966426 |    117.527180 | Collin Gross                                                                                                                                                          |
| 107 |    590.085736 |    107.380501 | Margot Michaud                                                                                                                                                        |
| 108 |    218.353379 |    228.570109 | Gareth Monger                                                                                                                                                         |
| 109 |     11.131828 |    284.440534 | T. Michael Keesey                                                                                                                                                     |
| 110 |    446.427535 |    758.281991 | Luis Cunha                                                                                                                                                            |
| 111 |    502.323507 |    347.198732 | Scott Hartman                                                                                                                                                         |
| 112 |     49.915139 |    485.725711 | Margot Michaud                                                                                                                                                        |
| 113 |    703.332260 |    269.165466 | Ignacio Contreras                                                                                                                                                     |
| 114 |     84.352396 |    101.404261 | Shyamal                                                                                                                                                               |
| 115 |    863.626089 |    757.689672 | Tracy A. Heath                                                                                                                                                        |
| 116 |    563.821900 |    391.953420 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 117 |    741.639978 |    352.524551 | Steven Traver                                                                                                                                                         |
| 118 |    993.915361 |    624.119276 | T. Michael Keesey                                                                                                                                                     |
| 119 |    848.020573 |    455.368663 | Tasman Dixon                                                                                                                                                          |
| 120 |    828.027635 |    521.425399 | Ferran Sayol                                                                                                                                                          |
| 121 |    613.426988 |    284.053666 | C. Camilo Julián-Caballero                                                                                                                                            |
| 122 |     37.514832 |    307.777707 | Chris huh                                                                                                                                                             |
| 123 |    372.868938 |    257.307855 | C. Camilo Julián-Caballero                                                                                                                                            |
| 124 |    259.919128 |    509.498305 | Felix Vaux                                                                                                                                                            |
| 125 |      7.756759 |    555.215208 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 126 |    881.012045 |    490.862268 | Gareth Monger                                                                                                                                                         |
| 127 |    436.339900 |    720.676035 | Gareth Monger                                                                                                                                                         |
| 128 |    795.210320 |    326.809618 | Jaime Headden                                                                                                                                                         |
| 129 |    360.775753 |    123.104249 | Zimices                                                                                                                                                               |
| 130 |   1009.334814 |    638.554360 | NA                                                                                                                                                                    |
| 131 |    101.864255 |    342.294051 | C. Camilo Julián-Caballero                                                                                                                                            |
| 132 |    268.630288 |    442.719168 | Katie S. Collins                                                                                                                                                      |
| 133 |    342.538775 |    574.517918 | Kent Sorgon                                                                                                                                                           |
| 134 |    996.143672 |    721.662185 | NA                                                                                                                                                                    |
| 135 |    318.512470 |    656.026699 | Matt Crook                                                                                                                                                            |
| 136 |    121.358470 |    105.455275 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 137 |    245.769219 |    109.075053 | Margot Michaud                                                                                                                                                        |
| 138 |    816.928000 |    371.177608 | Zimices                                                                                                                                                               |
| 139 |    160.000115 |    492.630049 | Robert Gay                                                                                                                                                            |
| 140 |    251.042239 |    642.464213 | Collin Gross                                                                                                                                                          |
| 141 |    636.749084 |    450.132488 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 142 |    571.772014 |    108.427271 | Tyler Greenfield                                                                                                                                                      |
| 143 |      9.768954 |    124.743134 | Gareth Monger                                                                                                                                                         |
| 144 |    777.572839 |    269.013566 | Zimices                                                                                                                                                               |
| 145 |    971.045611 |     22.657168 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 146 |    769.017458 |    361.259181 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 147 |    421.803656 |    551.028702 | Matt Crook                                                                                                                                                            |
| 148 |    318.347917 |    711.587924 | Emily Willoughby                                                                                                                                                      |
| 149 |    391.596532 |    793.887599 | Chris huh                                                                                                                                                             |
| 150 |    606.829301 |    366.223221 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 151 |    107.440140 |    452.885160 | NA                                                                                                                                                                    |
| 152 |    195.336364 |    624.374842 | Jagged Fang Designs                                                                                                                                                   |
| 153 |    820.915253 |    307.521714 | Zimices                                                                                                                                                               |
| 154 |    585.272658 |    767.620032 | Caleb M. Gordon                                                                                                                                                       |
| 155 |    955.438905 |    584.931392 | JCGiron                                                                                                                                                               |
| 156 |     15.272080 |    342.606816 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 157 |    317.267860 |    465.622677 | Chris Jennings (Risiatto)                                                                                                                                             |
| 158 |    407.866864 |    545.821850 | Tasman Dixon                                                                                                                                                          |
| 159 |    227.099962 |    151.275647 | Rebecca Groom                                                                                                                                                         |
| 160 |    995.952297 |     91.903298 | Jennifer Trimble                                                                                                                                                      |
| 161 |    225.961684 |    403.977355 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 162 |    987.293545 |     67.251073 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 163 |     55.379405 |    363.795264 | Michael P. Taylor                                                                                                                                                     |
| 164 |    808.024074 |    250.241272 | Gareth Monger                                                                                                                                                         |
| 165 |    242.491591 |    152.153213 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                           |
| 166 |    202.847042 |    794.496146 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 167 |    544.869733 |     30.137712 | Renato de Carvalho Ferreira                                                                                                                                           |
| 168 |    652.678151 |    577.319882 | Zimices                                                                                                                                                               |
| 169 |    523.237292 |    650.107003 | Zimices                                                                                                                                                               |
| 170 |    233.919507 |    688.011358 | Margot Michaud                                                                                                                                                        |
| 171 |    721.521869 |    360.451650 | Tyler Greenfield                                                                                                                                                      |
| 172 |    285.205641 |    152.589177 | Ferran Sayol                                                                                                                                                          |
| 173 |    679.959497 |    652.053385 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 174 |    877.256209 |    670.099677 | Steven Traver                                                                                                                                                         |
| 175 |     29.864120 |    191.146130 | Steven Traver                                                                                                                                                         |
| 176 |    198.825356 |    710.819902 | Samanta Orellana                                                                                                                                                      |
| 177 |    774.452021 |     36.386957 | T. Michael Keesey                                                                                                                                                     |
| 178 |    236.396886 |    581.821670 | Arthur S. Brum                                                                                                                                                        |
| 179 |    724.932858 |    258.821868 | Matt Crook                                                                                                                                                            |
| 180 |    191.735405 |     96.494789 | Matus Valach                                                                                                                                                          |
| 181 |    313.912293 |     21.772382 | Steven Traver                                                                                                                                                         |
| 182 |    622.042840 |    494.531990 | Matt Crook                                                                                                                                                            |
| 183 |    604.340796 |    649.520381 | Scott Hartman                                                                                                                                                         |
| 184 |    973.199144 |    115.348776 | Birgit Lang                                                                                                                                                           |
| 185 |    130.865300 |    644.884524 | Ferran Sayol                                                                                                                                                          |
| 186 |    721.766374 |    622.083868 | Gareth Monger                                                                                                                                                         |
| 187 |    720.866422 |    176.556783 | NA                                                                                                                                                                    |
| 188 |    835.218484 |    351.783636 | NA                                                                                                                                                                    |
| 189 |    250.855533 |    183.194794 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 190 |   1006.837965 |    490.722023 | NA                                                                                                                                                                    |
| 191 |    276.044665 |    195.307542 | Iain Reid                                                                                                                                                             |
| 192 |    783.457167 |    605.851186 | NA                                                                                                                                                                    |
| 193 |    580.057970 |    267.052025 | Michael Scroggie                                                                                                                                                      |
| 194 |    553.417390 |    365.904104 | Kamil S. Jaron                                                                                                                                                        |
| 195 |    226.233573 |    121.923616 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 196 |    146.515586 |    396.085997 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 197 |    255.558586 |    589.111968 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 198 |    557.392898 |     26.233728 | Margot Michaud                                                                                                                                                        |
| 199 |    939.939404 |    160.850021 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
| 200 |    637.989826 |    164.572529 | Jagged Fang Designs                                                                                                                                                   |
| 201 |    305.386418 |    547.319284 | Roberto Díaz Sibaja                                                                                                                                                   |
| 202 |   1014.711176 |    699.077019 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 203 |    793.868049 |    457.338712 | Zimices                                                                                                                                                               |
| 204 |    347.332742 |    457.416867 | NA                                                                                                                                                                    |
| 205 |    559.408330 |     10.309317 | Matt Crook                                                                                                                                                            |
| 206 |    642.686195 |    329.824915 | Trond R. Oskars                                                                                                                                                       |
| 207 |    736.662950 |    331.898033 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 208 |    720.522786 |    650.282830 | Matt Crook                                                                                                                                                            |
| 209 |    406.904326 |    645.894273 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 210 |    379.245003 |    182.999572 | Zimices                                                                                                                                                               |
| 211 |    688.391032 |    195.892197 | Tasman Dixon                                                                                                                                                          |
| 212 |    327.925544 |    671.014081 | Caleb M. Brown                                                                                                                                                        |
| 213 |   1013.612130 |    742.315018 | Zimices                                                                                                                                                               |
| 214 |     85.153613 |    479.278654 | Jack Mayer Wood                                                                                                                                                       |
| 215 |    419.539441 |    728.111136 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                              |
| 216 |    749.120963 |    372.415142 | Gareth Monger                                                                                                                                                         |
| 217 |    585.332545 |    708.510815 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 218 |    314.435283 |    446.810989 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 219 |    132.433405 |    675.148488 | Iain Reid                                                                                                                                                             |
| 220 |    653.453057 |    753.694059 | Zimices                                                                                                                                                               |
| 221 |     60.370826 |    204.457488 | Ferran Sayol                                                                                                                                                          |
| 222 |     15.479795 |    412.188288 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
| 223 |    974.142151 |    746.328226 | Zimices                                                                                                                                                               |
| 224 |    987.162789 |      7.908176 | Tracy A. Heath                                                                                                                                                        |
| 225 |    269.209813 |    546.347165 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 226 |    812.763062 |    737.845683 | Scott Hartman                                                                                                                                                         |
| 227 |    829.446931 |    238.501997 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 228 |    327.162325 |    131.810553 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 229 |    336.529924 |    429.388778 | Steven Coombs                                                                                                                                                         |
| 230 |    809.106370 |    549.765362 | Zimices                                                                                                                                                               |
| 231 |    309.397777 |    568.937296 | Gareth Monger                                                                                                                                                         |
| 232 |    750.298887 |    438.485130 | Gareth Monger                                                                                                                                                         |
| 233 |    584.100908 |    248.507264 | Ignacio Contreras                                                                                                                                                     |
| 234 |    606.499590 |    190.588513 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 235 |    537.454075 |    528.080707 | Jack Mayer Wood                                                                                                                                                       |
| 236 |    398.695627 |    461.544779 | NA                                                                                                                                                                    |
| 237 |    345.644248 |    494.772772 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 238 |    703.461999 |    189.730569 | Gareth Monger                                                                                                                                                         |
| 239 |    852.066867 |    534.394032 | Gareth Monger                                                                                                                                                         |
| 240 |    421.998743 |    280.974116 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 241 |    219.254003 |    392.300823 | Scott Hartman                                                                                                                                                         |
| 242 |    306.377129 |    740.901114 | Becky Barnes                                                                                                                                                          |
| 243 |     75.870586 |    328.054502 | S.Martini                                                                                                                                                             |
| 244 |    708.484954 |    589.968514 | Scott Hartman                                                                                                                                                         |
| 245 |    323.773759 |    558.785832 | NA                                                                                                                                                                    |
| 246 |    854.800449 |    691.298506 | Lafage                                                                                                                                                                |
| 247 |    585.742905 |     19.425081 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 248 |    196.393204 |    226.118226 | Juan Carlos Jerí                                                                                                                                                      |
| 249 |    145.661108 |    542.888457 | Frank Förster                                                                                                                                                         |
| 250 |    824.768299 |    254.560988 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 251 |    173.664310 |    403.633091 | Matt Crook                                                                                                                                                            |
| 252 |     99.271610 |    684.522714 | Margot Michaud                                                                                                                                                        |
| 253 |    808.456847 |    201.919919 | Tasman Dixon                                                                                                                                                          |
| 254 |     65.393283 |    756.897903 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 255 |    383.826886 |    749.414648 | Matt Crook                                                                                                                                                            |
| 256 |     34.169866 |     11.126705 | Zimices                                                                                                                                                               |
| 257 |     33.844312 |    497.482262 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 258 |    335.127728 |    713.940042 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 259 |    389.130688 |    411.734971 | C. Camilo Julián-Caballero                                                                                                                                            |
| 260 |    358.892359 |    540.636287 | M Kolmann                                                                                                                                                             |
| 261 |    778.922217 |    427.184130 | Jessica Anne Miller                                                                                                                                                   |
| 262 |    686.457122 |    769.384355 | Birgit Lang                                                                                                                                                           |
| 263 |    726.700137 |    394.059020 | Zimices                                                                                                                                                               |
| 264 |    480.141696 |    323.590727 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 265 |    938.476739 |    529.173897 | T. Michael Keesey                                                                                                                                                     |
| 266 |    496.856309 |    334.898521 | Sarah Werning                                                                                                                                                         |
| 267 |    823.976445 |    284.084054 | Collin Gross                                                                                                                                                          |
| 268 |    946.284869 |    508.825645 | Qiang Ou                                                                                                                                                              |
| 269 |    156.952781 |    713.397164 | Steven Traver                                                                                                                                                         |
| 270 |    646.887887 |    680.986596 | Steven Traver                                                                                                                                                         |
| 271 |    600.917942 |    504.556364 | NA                                                                                                                                                                    |
| 272 |     85.025847 |    298.480330 | Zimices                                                                                                                                                               |
| 273 |     31.023558 |    528.950181 | Scott Hartman                                                                                                                                                         |
| 274 |     78.409894 |    116.389415 | Margot Michaud                                                                                                                                                        |
| 275 |     23.433277 |    656.182455 | Gareth Monger                                                                                                                                                         |
| 276 |    411.044371 |    323.793144 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 277 |    988.742490 |    533.927940 | Caleb M. Brown                                                                                                                                                        |
| 278 |    615.524315 |    639.841113 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 279 |    938.171149 |    644.221575 | Emily Willoughby                                                                                                                                                      |
| 280 |    479.550587 |    672.294431 | Beth Reinke                                                                                                                                                           |
| 281 |    138.698603 |    336.884881 | Matt Crook                                                                                                                                                            |
| 282 |    788.377277 |    646.835953 | Steven Traver                                                                                                                                                         |
| 283 |    623.063424 |    452.968763 | T. Michael Keesey                                                                                                                                                     |
| 284 |    678.024428 |    602.334028 | Gareth Monger                                                                                                                                                         |
| 285 |    962.971075 |    702.585125 | Jagged Fang Designs                                                                                                                                                   |
| 286 |    394.851396 |     77.545148 | Ferran Sayol                                                                                                                                                          |
| 287 |    100.432121 |     37.146976 | Matt Hayes                                                                                                                                                            |
| 288 |    686.977950 |    791.609735 | Andrew A. Farke                                                                                                                                                       |
| 289 |    360.444884 |    718.132773 | Margot Michaud                                                                                                                                                        |
| 290 |    734.597221 |    468.419120 | Zimices                                                                                                                                                               |
| 291 |    137.807785 |    110.628071 | Matt Crook                                                                                                                                                            |
| 292 |    166.225174 |    369.540534 | Cesar Julian                                                                                                                                                          |
| 293 |    682.201661 |    349.711735 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 294 |    165.495553 |    535.272049 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 295 |    363.080247 |    583.743008 | NA                                                                                                                                                                    |
| 296 |    688.668757 |    459.677584 | Christoph Schomburg                                                                                                                                                   |
| 297 |     18.346074 |    541.150687 | Markus A. Grohme                                                                                                                                                      |
| 298 |    345.752646 |    715.313817 | Margot Michaud                                                                                                                                                        |
| 299 |    929.084089 |    178.329515 | L. Shyamal                                                                                                                                                            |
| 300 |    991.935864 |     31.351044 | Margot Michaud                                                                                                                                                        |
| 301 |    845.573796 |     16.591503 | Michelle Site                                                                                                                                                         |
| 302 |     81.636352 |    346.992895 | Ferran Sayol                                                                                                                                                          |
| 303 |    450.910082 |    445.866096 | FunkMonk                                                                                                                                                              |
| 304 |    282.935057 |     21.483637 | Scott Hartman                                                                                                                                                         |
| 305 |    539.869481 |    727.411586 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 306 |    483.073986 |    551.913704 | Mathieu Basille                                                                                                                                                       |
| 307 |    695.332641 |    389.761441 | Margot Michaud                                                                                                                                                        |
| 308 |    674.951206 |    626.633981 | Markus A. Grohme                                                                                                                                                      |
| 309 |   1001.612774 |    711.438935 | Tasman Dixon                                                                                                                                                          |
| 310 |    561.060173 |    727.602464 | Zimices                                                                                                                                                               |
| 311 |    190.715139 |    103.766619 | Abraão Leite                                                                                                                                                          |
| 312 |    760.981818 |    391.822259 | Steven Coombs                                                                                                                                                         |
| 313 |    995.958912 |    672.000108 | Chris huh                                                                                                                                                             |
| 314 |    351.575098 |    778.347367 | Andrew A. Farke                                                                                                                                                       |
| 315 |    985.348880 |    503.824091 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 316 |      9.888526 |    202.003316 | Bryan Carstens                                                                                                                                                        |
| 317 |    350.814946 |     17.890909 | NA                                                                                                                                                                    |
| 318 |    401.830461 |    216.099678 | Jaime Headden                                                                                                                                                         |
| 319 |     79.319362 |    669.534804 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 320 |    875.185920 |    637.120208 | NA                                                                                                                                                                    |
| 321 |    274.446302 |    457.491071 | Matt Wilkins                                                                                                                                                          |
| 322 |    799.565805 |    372.256568 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 323 |    275.486978 |    102.209922 | NA                                                                                                                                                                    |
| 324 |    368.143290 |    161.751994 | Ferran Sayol                                                                                                                                                          |
| 325 |    851.234793 |    592.083999 | Aline M. Ghilardi                                                                                                                                                     |
| 326 |    485.166863 |    243.451469 | Zimices                                                                                                                                                               |
| 327 |    615.363553 |    777.141353 | Ferran Sayol                                                                                                                                                          |
| 328 |    733.046127 |    452.424638 | Michael Scroggie                                                                                                                                                      |
| 329 |    682.863351 |    573.127956 | Steven Traver                                                                                                                                                         |
| 330 |    636.272744 |    467.035493 | NA                                                                                                                                                                    |
| 331 |    750.719943 |    181.483735 | Juan Carlos Jerí                                                                                                                                                      |
| 332 |    790.107602 |    334.318731 | Jagged Fang Designs                                                                                                                                                   |
| 333 |    220.111249 |    204.341122 | Mathew Callaghan                                                                                                                                                      |
| 334 |    395.356875 |    291.766466 | Ferran Sayol                                                                                                                                                          |
| 335 |    194.514579 |    403.899210 | Rachel Shoop                                                                                                                                                          |
| 336 |     77.537027 |     17.702116 | Gareth Monger                                                                                                                                                         |
| 337 |    629.964402 |    289.777021 | L. Shyamal                                                                                                                                                            |
| 338 |     59.739013 |     15.900921 | Matt Crook                                                                                                                                                            |
| 339 |    791.536453 |      5.727145 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 340 |    362.466646 |    238.563906 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
| 341 |     49.069713 |     98.962288 | Emily Willoughby                                                                                                                                                      |
| 342 |    784.980125 |    794.732003 | Melissa Broussard                                                                                                                                                     |
| 343 |    795.706151 |    750.189344 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 344 |    388.615268 |    432.477708 | Harold N Eyster                                                                                                                                                       |
| 345 |    156.282179 |    319.400398 | Gareth Monger                                                                                                                                                         |
| 346 |    490.504738 |    530.195455 | Kamil S. Jaron                                                                                                                                                        |
| 347 |    888.405694 |    570.382932 | Smokeybjb                                                                                                                                                             |
| 348 |    648.573656 |    311.734797 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 349 |    492.543323 |    505.519564 | Zimices                                                                                                                                                               |
| 350 |    256.145282 |    498.549954 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
| 351 |    602.501705 |    175.735555 | NA                                                                                                                                                                    |
| 352 |    364.012974 |    651.240709 | Roberto Díaz Sibaja                                                                                                                                                   |
| 353 |     54.672032 |    172.349076 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                        |
| 354 |    359.913934 |    576.076194 | Gareth Monger                                                                                                                                                         |
| 355 |    692.874937 |    564.184784 | Steven Traver                                                                                                                                                         |
| 356 |    790.765244 |     64.550280 | Zimices                                                                                                                                                               |
| 357 |    597.505478 |    294.882554 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 358 |    644.580247 |     17.128963 | Zimices                                                                                                                                                               |
| 359 |     87.005171 |    703.022026 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 360 |    620.374526 |    187.920097 | Ferran Sayol                                                                                                                                                          |
| 361 |    358.056786 |    507.583617 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 362 |    216.749640 |    582.276043 | Jaime Headden                                                                                                                                                         |
| 363 |     14.573612 |    455.140070 | Birgit Lang                                                                                                                                                           |
| 364 |    209.897583 |     87.330210 | Tasman Dixon                                                                                                                                                          |
| 365 |     68.577908 |    108.306626 | Shyamal                                                                                                                                                               |
| 366 |    572.181319 |    225.417434 | Gareth Monger                                                                                                                                                         |
| 367 |    254.424041 |    563.433972 | Mattia Menchetti                                                                                                                                                      |
| 368 |    194.274620 |    191.371934 | Dean Schnabel                                                                                                                                                         |
| 369 |    965.985572 |    594.843479 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 370 |    270.556779 |    250.678930 | T. Michael Keesey                                                                                                                                                     |
| 371 |    732.943723 |    106.339675 | Beth Reinke                                                                                                                                                           |
| 372 |    374.560587 |     13.844473 | Filip em                                                                                                                                                              |
| 373 |    919.776750 |    646.849196 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 374 |    771.769207 |    722.362952 | Sarah Werning                                                                                                                                                         |
| 375 |    806.363215 |    680.143490 | Tracy A. Heath                                                                                                                                                        |
| 376 |    506.075063 |    171.669898 | Jimmy Bernot                                                                                                                                                          |
| 377 |    697.237913 |    174.206152 | Margot Michaud                                                                                                                                                        |
| 378 |    389.866027 |    773.372933 | Kamil S. Jaron                                                                                                                                                        |
| 379 |    419.268354 |    620.199977 | Gareth Monger                                                                                                                                                         |
| 380 |   1014.132401 |    777.623944 | Gareth Monger                                                                                                                                                         |
| 381 |    990.114285 |    404.494270 | Matt Crook                                                                                                                                                            |
| 382 |    151.543994 |    561.385705 | Steven Traver                                                                                                                                                         |
| 383 |    383.917057 |    573.302048 | Ferran Sayol                                                                                                                                                          |
| 384 |    553.112852 |     76.489548 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 385 |    989.109846 |    104.813306 | Lukasiniho                                                                                                                                                            |
| 386 |    989.694734 |    786.713589 | Steven Traver                                                                                                                                                         |
| 387 |    986.865096 |    433.073370 | Jiekun He                                                                                                                                                             |
| 388 |    780.819348 |    615.532057 | Scott Hartman                                                                                                                                                         |
| 389 |    959.913119 |    201.442184 | Rebecca Groom                                                                                                                                                         |
| 390 |    998.057419 |    572.857042 | Katie S. Collins                                                                                                                                                      |
| 391 |    966.617333 |    654.423802 | Noah Schlottman                                                                                                                                                       |
| 392 |    703.849239 |    133.771767 | Zimices                                                                                                                                                               |
| 393 |    593.951435 |    160.605732 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 394 |    165.651369 |    464.471060 | Felix Vaux                                                                                                                                                            |
| 395 |    451.312048 |    233.558351 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 396 |    326.453560 |    153.837218 | Jaime Headden                                                                                                                                                         |
| 397 |    807.300173 |    276.142096 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                     |
| 398 |    715.668981 |    790.702527 | Zimices                                                                                                                                                               |
| 399 |    432.305722 |    790.823604 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                           |
| 400 |    370.048820 |     53.724710 | Ingo Braasch                                                                                                                                                          |
| 401 |    233.858320 |    431.962410 | Matt Crook                                                                                                                                                            |
| 402 |    346.396262 |    662.015298 | Margot Michaud                                                                                                                                                        |
| 403 |    896.155323 |    292.460075 | Shyamal                                                                                                                                                               |
| 404 |    707.265011 |    689.060389 | Matt Crook                                                                                                                                                            |
| 405 |   1003.511663 |    447.016720 | Felix Vaux                                                                                                                                                            |
| 406 |    492.198564 |    317.436775 | Jagged Fang Designs                                                                                                                                                   |
| 407 |    816.318102 |    354.509257 | NA                                                                                                                                                                    |
| 408 |    289.910845 |    436.287126 | Arthur S. Brum                                                                                                                                                        |
| 409 |    227.704647 |     96.873521 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 410 |    392.760536 |     48.603125 | Lauren Anderson                                                                                                                                                       |
| 411 |    879.973991 |    459.669426 | T. Michael Keesey                                                                                                                                                     |
| 412 |    972.298147 |    125.993002 | NA                                                                                                                                                                    |
| 413 |    287.573177 |    244.641858 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 414 |    550.611960 |    457.205269 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 415 |    366.514297 |    520.556944 | Ferran Sayol                                                                                                                                                          |
| 416 |    546.310139 |     53.408499 | Steven Traver                                                                                                                                                         |
| 417 |    511.948580 |    456.711656 | Stacy Spensley (Modified)                                                                                                                                             |
| 418 |    699.731654 |    577.119107 | Felix Vaux                                                                                                                                                            |
| 419 |    979.740888 |    571.418923 | Matt Crook                                                                                                                                                            |
| 420 |    859.017928 |    634.560461 | NA                                                                                                                                                                    |
| 421 |     14.026403 |    517.799756 | Ferran Sayol                                                                                                                                                          |
| 422 |    728.836184 |    591.807161 | Crystal Maier                                                                                                                                                         |
| 423 |    236.878940 |    706.186818 | Anthony Caravaggi                                                                                                                                                     |
| 424 |     22.608208 |    166.041513 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 425 |     99.619716 |    477.176489 | Trond R. Oskars                                                                                                                                                       |
| 426 |     33.049154 |    223.068985 | Shyamal                                                                                                                                                               |
| 427 |    693.364614 |    610.198677 | Matt Crook                                                                                                                                                            |
| 428 |    120.763962 |    662.415714 | Stuart Humphries                                                                                                                                                      |
| 429 |    115.821352 |     46.629580 | Ferran Sayol                                                                                                                                                          |
| 430 |    384.249417 |    647.195333 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 431 |    709.804923 |    766.342412 | Margot Michaud                                                                                                                                                        |
| 432 |    778.201375 |     50.873998 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 433 |    466.503255 |    679.112446 | Zimices                                                                                                                                                               |
| 434 |    871.153506 |    575.866240 | Ferran Sayol                                                                                                                                                          |
| 435 |     16.611677 |    644.942406 | Chase Brownstein                                                                                                                                                      |
| 436 |     29.966397 |    350.539251 | Gareth Monger                                                                                                                                                         |
| 437 |    458.690352 |    758.809506 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 438 |    529.767611 |    564.598202 | Gareth Monger                                                                                                                                                         |
| 439 |    988.114245 |    602.249919 | Scott Reid                                                                                                                                                            |
| 440 |    712.016268 |    391.322399 | Gareth Monger                                                                                                                                                         |
| 441 |    182.996360 |    626.827921 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 442 |    107.613526 |    325.796497 | Christoph Schomburg                                                                                                                                                   |
| 443 |    558.681696 |     63.681224 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 444 |   1003.849922 |    500.383002 | Beth Reinke                                                                                                                                                           |
| 445 |    367.889599 |     82.710120 | Ferran Sayol                                                                                                                                                          |
| 446 |    912.004242 |    285.843873 | Andrew A. Farke                                                                                                                                                       |
| 447 |    952.477724 |    166.197144 | Michelle Site                                                                                                                                                         |
| 448 |    235.846212 |     31.626184 | Scott Hartman                                                                                                                                                         |
| 449 |    506.132877 |    520.227372 | Margot Michaud                                                                                                                                                        |
| 450 |    341.837810 |    539.237089 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 451 |     68.761817 |    376.879435 | Joanna Wolfe                                                                                                                                                          |
| 452 |    793.338119 |    275.556212 | T. Michael Keesey                                                                                                                                                     |
| 453 |    567.919355 |    177.915763 | NA                                                                                                                                                                    |
| 454 |    501.601593 |    233.270202 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 455 |    242.627829 |    631.610694 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 456 |    634.577024 |    666.499778 | Cesar Julian                                                                                                                                                          |
| 457 |    172.407309 |    561.010975 | Zimices                                                                                                                                                               |
| 458 |    628.833848 |    427.380262 | Margot Michaud                                                                                                                                                        |
| 459 |     86.391889 |    753.873783 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 460 |    891.714422 |    479.105200 | NA                                                                                                                                                                    |
| 461 |    541.102696 |    547.377285 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 462 |    486.274195 |    495.445583 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 463 |    320.315156 |    254.010853 | Matt Crook                                                                                                                                                            |
| 464 |    749.919417 |    717.406089 | Rafael Maia                                                                                                                                                           |
| 465 |    985.763775 |    549.987010 | Félix Landry Yuan                                                                                                                                                     |
| 466 |    272.139749 |    235.615150 | Smokeybjb                                                                                                                                                             |
| 467 |    791.347484 |    228.696583 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 468 |    331.454842 |      9.608142 | Melissa Broussard                                                                                                                                                     |
| 469 |    912.465718 |    573.954342 | NA                                                                                                                                                                    |
| 470 |    154.066969 |    452.403457 | Gareth Monger                                                                                                                                                         |
| 471 |    777.296039 |    663.008171 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                      |
| 472 |    854.802859 |    783.029657 | Birgit Lang                                                                                                                                                           |
| 473 |    385.607571 |    549.010401 | Terpsichores                                                                                                                                                          |
| 474 |     27.992707 |    265.661864 | Cesar Julian                                                                                                                                                          |
| 475 |    686.938479 |    636.957616 | Joedison Rocha                                                                                                                                                        |
| 476 |    412.454931 |    440.127359 | Lukas Panzarin                                                                                                                                                        |
| 477 |    101.422556 |    576.655650 | Scott Hartman                                                                                                                                                         |
| 478 |    870.003287 |    706.560885 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 479 |     34.024395 |    320.379323 | Kanako Bessho-Uehara                                                                                                                                                  |
| 480 |    381.584130 |    720.965231 | Tess Linden                                                                                                                                                           |
| 481 |    100.984927 |    567.789198 | Steven Traver                                                                                                                                                         |
| 482 |    353.951956 |    136.002139 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 483 |    690.558768 |    721.196554 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 484 |    475.122297 |    174.004282 | Gareth Monger                                                                                                                                                         |
| 485 |    792.386738 |    381.842340 | T. Michael Keesey                                                                                                                                                     |
| 486 |    460.496444 |    737.882752 | Ignacio Contreras                                                                                                                                                     |
| 487 |     95.704456 |    331.795902 | Mathew Wedel                                                                                                                                                          |
| 488 |    339.853676 |    459.314521 | Dean Schnabel                                                                                                                                                         |
| 489 |    420.508637 |    210.195081 | Matt Crook                                                                                                                                                            |
| 490 |    660.898762 |    767.994279 | Mathieu Basille                                                                                                                                                       |
| 491 |    185.078548 |    291.442131 | Ferran Sayol                                                                                                                                                          |
| 492 |    391.963989 |    715.042147 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 493 |    305.274350 |     17.978123 | Jagged Fang Designs                                                                                                                                                   |
| 494 |    992.003869 |    545.886155 | Collin Gross                                                                                                                                                          |
| 495 |    714.517378 |    451.100660 | Robert Gay                                                                                                                                                            |
| 496 |     61.937840 |    780.225074 | Hans Hillewaert                                                                                                                                                       |
| 497 |    618.539308 |    669.331591 | Aline M. Ghilardi                                                                                                                                                     |
| 498 |    648.488401 |    123.685811 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 499 |    302.171721 |    312.034433 | Gareth Monger                                                                                                                                                         |
| 500 |     77.625159 |    454.734780 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 501 |    464.656451 |    783.930087 | Zimices                                                                                                                                                               |
| 502 |    610.122226 |    344.732982 | Zimices                                                                                                                                                               |
| 503 |    976.950587 |    666.043331 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                            |
| 504 |    593.311379 |    607.779682 | Mason McNair                                                                                                                                                          |
| 505 |    757.685996 |    565.574985 | Margot Michaud                                                                                                                                                        |
| 506 |    616.035451 |    310.069386 | Steven Traver                                                                                                                                                         |
| 507 |    731.071122 |    767.238821 | Jonathan Wells                                                                                                                                                        |
| 508 |     47.847203 |    446.884104 | Anthony Caravaggi                                                                                                                                                     |
| 509 |    129.709409 |    452.238126 | Ferran Sayol                                                                                                                                                          |
| 510 |    341.258415 |    523.757434 | Gareth Monger                                                                                                                                                         |
| 511 |     16.392928 |    240.933742 | Scott Reid                                                                                                                                                            |
| 512 |    830.519764 |      5.690970 | Roderic Page and Lois Page                                                                                                                                            |
| 513 |    724.376059 |    778.669505 | Michelle Site                                                                                                                                                         |
| 514 |    395.502871 |    239.975790 | Javiera Constanzo                                                                                                                                                     |
| 515 |    654.116023 |    357.313414 | NA                                                                                                                                                                    |
| 516 |    769.247668 |     71.762515 | Matt Crook                                                                                                                                                            |
| 517 |     37.997678 |    783.336822 | Scott Hartman                                                                                                                                                         |
| 518 |    884.835275 |    296.786002 | Maija Karala                                                                                                                                                          |
| 519 |     72.473586 |    356.891030 | Armin Reindl                                                                                                                                                          |
| 520 |    753.419531 |    409.135790 | Margot Michaud                                                                                                                                                        |
| 521 |    122.350222 |    573.898635 | NA                                                                                                                                                                    |
| 522 |    595.862477 |    387.689780 | Margot Michaud                                                                                                                                                        |
| 523 |   1011.130519 |    732.868429 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 524 |    508.414412 |    568.179733 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 525 |    608.192741 |    412.889922 | Nicolas Mongiardino Koch                                                                                                                                              |
| 526 |    715.302508 |    472.111514 | Margot Michaud                                                                                                                                                        |
| 527 |    609.278931 |    611.661681 | NA                                                                                                                                                                    |
| 528 |   1010.019727 |    753.676098 | Christoph Schomburg                                                                                                                                                   |
| 529 |    671.576178 |    591.812025 | Matt Hayes                                                                                                                                                            |
| 530 |    842.913155 |    793.972185 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 531 |    619.995877 |    252.304781 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 532 |    579.363991 |    174.821095 | Gareth Monger                                                                                                                                                         |
| 533 |    570.912622 |    749.800346 | Matt Crook                                                                                                                                                            |
| 534 |    683.392375 |    284.398946 | Tracy A. Heath                                                                                                                                                        |
| 535 |    604.113052 |    517.480079 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 536 |    652.860834 |    790.426589 | Cesar Julian                                                                                                                                                          |
| 537 |    643.461207 |    282.233915 | Jimmy Bernot                                                                                                                                                          |
| 538 |     18.397000 |    547.524059 | Anthony Caravaggi                                                                                                                                                     |
| 539 |    959.294310 |    790.873580 | Jagged Fang Designs                                                                                                                                                   |
| 540 |    118.908499 |    477.358280 | Matt Martyniuk                                                                                                                                                        |
| 541 |    228.433128 |    530.429087 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 542 |    370.836636 |     91.287008 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 543 |    144.306674 |    384.651089 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 544 |    861.289254 |    657.159369 | Jagged Fang Designs                                                                                                                                                   |
| 545 |    503.372394 |    663.276735 | T. Michael Keesey                                                                                                                                                     |
| 546 |    380.547168 |    531.572738 | Zimices                                                                                                                                                               |
| 547 |    675.898400 |    767.771960 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 548 |    199.645396 |    436.528584 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 549 |   1011.711933 |    589.890679 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 550 |     59.841201 |    449.872480 | Tasman Dixon                                                                                                                                                          |
| 551 |    911.335941 |    435.304912 | C. Camilo Julián-Caballero                                                                                                                                            |
| 552 |    394.478216 |    665.046230 | Sarah Werning                                                                                                                                                         |
| 553 |    757.073375 |    260.433122 | Gareth Monger                                                                                                                                                         |
| 554 |    671.952380 |    679.568483 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 555 |    677.601924 |    264.820933 | Margot Michaud                                                                                                                                                        |
| 556 |    631.935935 |    497.432154 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 557 |      8.111927 |    503.513430 | Kanako Bessho-Uehara                                                                                                                                                  |
| 558 |    344.884458 |    308.584564 | Milton Tan                                                                                                                                                            |
| 559 |    282.791501 |    258.616788 | Iain Reid                                                                                                                                                             |
| 560 |    501.016859 |    213.454297 | Gareth Monger                                                                                                                                                         |
| 561 |    589.456270 |    792.931223 | Margot Michaud                                                                                                                                                        |
| 562 |    631.795757 |    203.296801 | NASA                                                                                                                                                                  |
| 563 |    918.837525 |    214.282212 | NA                                                                                                                                                                    |
| 564 |    628.735345 |    527.629578 | Tasman Dixon                                                                                                                                                          |
| 565 |    462.525064 |    345.677558 | Margot Michaud                                                                                                                                                        |
| 566 |    804.481161 |    342.320911 | Markus A. Grohme                                                                                                                                                      |
| 567 |   1012.497717 |    168.572473 | Raven Amos                                                                                                                                                            |
| 568 |    620.136260 |    469.487079 | Emma Kissling                                                                                                                                                         |
| 569 |    495.978786 |    299.719872 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 570 |    810.699794 |    755.493070 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                         |
| 571 |    290.725198 |    428.388095 | Steven Traver                                                                                                                                                         |
| 572 |     62.214979 |    101.706277 | Sarah Werning                                                                                                                                                         |
| 573 |    274.879397 |    114.292102 | Steven Traver                                                                                                                                                         |
| 574 |    667.316571 |    610.199298 | Chris huh                                                                                                                                                             |
| 575 |    131.552257 |      8.310877 | Scott Hartman                                                                                                                                                         |
| 576 |    796.426231 |    215.349354 | FunkMonk                                                                                                                                                              |
| 577 |    341.796473 |    111.856233 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 578 |    657.310974 |    297.074403 | Jagged Fang Designs                                                                                                                                                   |
| 579 |    141.667883 |    206.383165 | Armin Reindl                                                                                                                                                          |
| 580 |    406.110391 |    561.699888 | Esme Ashe-Jepson                                                                                                                                                      |
| 581 |    453.170263 |    111.788437 | T. Michael Keesey                                                                                                                                                     |
| 582 |      9.634530 |    634.343783 | T. Michael Keesey                                                                                                                                                     |
| 583 |    888.897089 |    637.675323 | Jagged Fang Designs                                                                                                                                                   |
| 584 |    668.359038 |    307.057712 | Sarah Werning                                                                                                                                                         |
| 585 |    523.033528 |    185.906490 | Tasman Dixon                                                                                                                                                          |
| 586 |    199.936863 |    169.014232 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 587 |    681.478217 |    491.034962 | George Edward Lodge                                                                                                                                                   |
| 588 |    936.301968 |    575.121027 | Gareth Monger                                                                                                                                                         |
| 589 |    925.590759 |    318.323547 | Melissa Broussard                                                                                                                                                     |
| 590 |    372.219798 |     36.690143 | NA                                                                                                                                                                    |
| 591 |    251.076716 |     28.022474 | Steven Traver                                                                                                                                                         |
| 592 |    752.434375 |    283.702184 | Zimices                                                                                                                                                               |
| 593 |    575.684773 |    292.834995 | Jagged Fang Designs                                                                                                                                                   |
| 594 |    667.954036 |    311.111457 | SauropodomorphMonarch                                                                                                                                                 |
| 595 |    935.392205 |    787.783667 | Zimices                                                                                                                                                               |
| 596 |    519.966404 |    625.713115 | Jagged Fang Designs                                                                                                                                                   |
| 597 |    405.041494 |    773.256764 | FunkMonk                                                                                                                                                              |
| 598 |    671.715857 |    642.516370 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
| 599 |     85.065762 |    318.722881 | T. Michael Keesey                                                                                                                                                     |
| 600 |    853.601345 |    565.494583 | Pete Buchholz                                                                                                                                                         |
| 601 |    688.804517 |    696.299940 | Scott Hartman                                                                                                                                                         |
| 602 |     94.178814 |     92.436148 | Chris huh                                                                                                                                                             |
| 603 |     84.036443 |     48.104254 | T. Michael Keesey                                                                                                                                                     |
| 604 |    419.861835 |    190.983001 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 605 |    740.993694 |    390.995355 | Cristopher Silva                                                                                                                                                      |
| 606 |    677.640833 |    397.371578 | Tasman Dixon                                                                                                                                                          |
| 607 |    898.987202 |    771.624939 | Markus A. Grohme                                                                                                                                                      |
| 608 |    683.733895 |      5.113506 | NA                                                                                                                                                                    |
| 609 |    555.549741 |    748.553602 | Zimices                                                                                                                                                               |
| 610 |    278.623682 |    503.313022 | NA                                                                                                                                                                    |
| 611 |    874.934748 |    509.918548 | Zimices                                                                                                                                                               |
| 612 |    667.456511 |    333.115793 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 613 |    197.979365 |    113.534591 | Maija Karala                                                                                                                                                          |
| 614 |    336.855501 |    265.434509 | Zimices                                                                                                                                                               |
| 615 |    519.864379 |    638.637529 | Birgit Lang                                                                                                                                                           |
| 616 |   1014.529486 |    785.717620 | Ricardo Araújo                                                                                                                                                        |
| 617 |    370.987662 |     68.354605 | Collin Gross                                                                                                                                                          |
| 618 |    259.851132 |      8.740292 | Margot Michaud                                                                                                                                                        |
| 619 |    822.313624 |    327.325323 | Matt Crook                                                                                                                                                            |
| 620 |    631.158025 |    300.648182 | Melissa Broussard                                                                                                                                                     |
| 621 |   1013.133846 |     21.757986 | Scott Hartman                                                                                                                                                         |
| 622 |    715.569024 |    749.290812 | Steven Traver                                                                                                                                                         |
| 623 |    162.734336 |    525.014476 | Jagged Fang Designs                                                                                                                                                   |
| 624 |    294.555650 |    575.182906 | Scott Reid                                                                                                                                                            |
| 625 |    703.668787 |    398.004321 | Anthony Caravaggi                                                                                                                                                     |
| 626 |    984.247714 |     81.170691 | Steven Traver                                                                                                                                                         |
| 627 |      6.508483 |    768.946289 | Michelle Site                                                                                                                                                         |
| 628 |    420.570087 |    770.722877 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 629 |    569.776838 |    268.502104 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 630 |    867.824870 |    597.206075 | Taenadoman                                                                                                                                                            |
| 631 |    510.815580 |    534.580727 | Melissa Broussard                                                                                                                                                     |
| 632 |    488.281379 |    644.085794 | Meliponicultor Itaymbere                                                                                                                                              |
| 633 |    408.649226 |    392.068154 | Rebecca Groom                                                                                                                                                         |
| 634 |     41.470518 |    330.745282 | Maija Karala                                                                                                                                                          |
| 635 |    159.844272 |    229.168801 | Benjamint444                                                                                                                                                          |
| 636 |    737.224529 |    270.270321 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 637 |    436.738677 |    466.892297 | Michele M Tobias                                                                                                                                                      |
| 638 |    990.167215 |    142.091229 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 639 |    779.752519 |    458.794049 | Collin Gross                                                                                                                                                          |
| 640 |   1007.786759 |    656.644401 | Terpsichores                                                                                                                                                          |
| 641 |    850.893721 |    212.566838 | Chloé Schmidt                                                                                                                                                         |
| 642 |    989.025406 |    171.399792 | Meliponicultor Itaymbere                                                                                                                                              |
| 643 |    665.570628 |    713.682814 | Matt Crook                                                                                                                                                            |
| 644 |    322.291700 |    636.214215 | Chris huh                                                                                                                                                             |
| 645 |    782.178535 |    569.813865 | Matt Crook                                                                                                                                                            |
| 646 |    419.098230 |    248.866613 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 647 |    250.041135 |    547.953906 | Matt Crook                                                                                                                                                            |
| 648 |    900.054029 |    657.989433 | Matt Celeskey                                                                                                                                                         |
| 649 |    753.923113 |    270.367426 | Scott Hartman                                                                                                                                                         |
| 650 |    940.254210 |      8.020565 | Lisa Byrne                                                                                                                                                            |
| 651 |    114.963072 |    653.713231 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 652 |    617.666191 |    176.699610 | Zimices                                                                                                                                                               |
| 653 |    848.886759 |    610.506184 | Michael Scroggie                                                                                                                                                      |
| 654 |    866.887715 |    501.392271 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 655 |    733.422721 |      8.210810 | Gareth Monger                                                                                                                                                         |
| 656 |    870.618946 |    454.386613 | Luis Cunha                                                                                                                                                            |
| 657 |    788.572523 |    677.865999 | Felix Vaux                                                                                                                                                            |
| 658 |    501.965046 |    646.330374 | T. Michael Keesey                                                                                                                                                     |
| 659 |    489.270257 |    231.751123 | Cagri Cevrim                                                                                                                                                          |
| 660 |    453.724372 |    418.906070 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 661 |    207.829159 |    604.146293 | Scott Hartman                                                                                                                                                         |
| 662 |    293.538597 |    119.966812 | Gareth Monger                                                                                                                                                         |
| 663 |    375.879626 |    102.491577 | T. Michael Keesey                                                                                                                                                     |
| 664 |    143.492705 |    473.734825 | Matt Crook                                                                                                                                                            |
| 665 |    857.775306 |    466.231695 | annaleeblysse                                                                                                                                                         |
| 666 |    969.137237 |    137.763505 | Gareth Monger                                                                                                                                                         |
| 667 |    829.938895 |    632.340981 | Collin Gross                                                                                                                                                          |
| 668 |    440.012942 |      6.885314 | Andrew A. Farke                                                                                                                                                       |
| 669 |    871.428909 |    650.523522 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 670 |    403.781046 |    541.159945 | Iain Reid                                                                                                                                                             |
| 671 |    691.205860 |    148.033267 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 672 |    547.895105 |    570.575331 | Anthony Caravaggi                                                                                                                                                     |
| 673 |    822.797156 |     32.716326 | Sarah Werning                                                                                                                                                         |
| 674 |    728.028929 |    242.812492 | Steven Traver                                                                                                                                                         |
| 675 |    547.653839 |    188.503077 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 676 |    852.232872 |    577.867045 | Emily Willoughby                                                                                                                                                      |
| 677 |    623.626094 |    127.913453 | xgirouxb                                                                                                                                                              |
| 678 |    355.225861 |    193.097016 | Siobhon Egan                                                                                                                                                          |
| 679 |    575.833536 |     89.927447 | T. Michael Keesey                                                                                                                                                     |
| 680 |    414.498437 |     89.734244 | Mattia Menchetti                                                                                                                                                      |
| 681 |    103.014444 |    284.109127 | Jaime Headden                                                                                                                                                         |
| 682 |    409.999342 |    289.416991 | Roberto Díaz Sibaja                                                                                                                                                   |
| 683 |    468.645882 |    157.020657 | Scott Hartman                                                                                                                                                         |
| 684 |     88.079801 |    118.589754 | Steven Traver                                                                                                                                                         |
| 685 |     18.142523 |     19.191721 | Jonathan Wells                                                                                                                                                        |
| 686 |    845.132708 |    393.582925 | Kai R. Caspar                                                                                                                                                         |
| 687 |    688.603999 |    447.794826 | Maija Karala                                                                                                                                                          |
| 688 |    565.709992 |    723.846528 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 689 |    574.825249 |    355.694728 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 690 |    809.389426 |    558.731859 | Steven Traver                                                                                                                                                         |
| 691 |    602.895878 |    759.135922 | Steven Traver                                                                                                                                                         |
| 692 |    610.549392 |    789.763613 | Gareth Monger                                                                                                                                                         |
| 693 |    800.973544 |    637.479335 | Scott Hartman                                                                                                                                                         |
| 694 |    195.233794 |    121.204621 | Christine Axon                                                                                                                                                        |
| 695 |    320.984679 |    179.486770 | Chris huh                                                                                                                                                             |
| 696 |    363.771954 |      5.210908 | NA                                                                                                                                                                    |
| 697 |    824.585374 |    381.691527 | Maija Karala                                                                                                                                                          |
| 698 |    882.511131 |    483.211323 | Steven Traver                                                                                                                                                         |
| 699 |    497.260245 |    786.045396 | Jagged Fang Designs                                                                                                                                                   |
| 700 |    949.625396 |    407.810220 | Margot Michaud                                                                                                                                                        |
| 701 |    558.473669 |     41.569245 | Ferran Sayol                                                                                                                                                          |
| 702 |    730.404856 |    234.933863 | Jakovche                                                                                                                                                              |
| 703 |    648.113229 |    640.489679 | Scott Hartman                                                                                                                                                         |
| 704 |    937.286177 |    657.841627 | Wayne Decatur                                                                                                                                                         |
| 705 |    318.616909 |    268.155596 | Mathew Wedel                                                                                                                                                          |
| 706 |   1021.432089 |    536.208662 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 707 |    414.974010 |    653.535006 | Scott Hartman                                                                                                                                                         |
| 708 |     21.276614 |    372.087461 | Collin Gross                                                                                                                                                          |
| 709 |    520.468911 |    245.872165 | Jagged Fang Designs                                                                                                                                                   |
| 710 |    254.986232 |    625.891325 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 711 |     93.778758 |    309.494828 | Ferran Sayol                                                                                                                                                          |
| 712 |    551.424705 |     35.290242 | Scott Hartman                                                                                                                                                         |
| 713 |    965.715518 |    561.300231 | Scott Hartman                                                                                                                                                         |
| 714 |    491.374825 |    621.587327 | Matt Crook                                                                                                                                                            |
| 715 |    772.661798 |    591.668449 | T. Michael Keesey                                                                                                                                                     |
| 716 |    475.672309 |    449.283275 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 717 |    418.364594 |    705.008511 | Tyler Greenfield                                                                                                                                                      |
| 718 |    249.651443 |    271.390963 | Matt Crook                                                                                                                                                            |
| 719 |    196.744095 |     36.876858 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 720 |     22.387759 |    506.609466 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 721 |    140.959942 |    229.941556 | Tasman Dixon                                                                                                                                                          |
| 722 |    903.346308 |      6.883039 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 723 |    736.765838 |    404.323718 | Zimices                                                                                                                                                               |
| 724 |    987.987903 |    659.629810 | Steven Traver                                                                                                                                                         |
| 725 |    264.766406 |    718.367906 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 726 |    695.150014 |    653.290457 | Matthew E. Clapham                                                                                                                                                    |
| 727 |    475.320313 |    231.515100 | Tracy A. Heath                                                                                                                                                        |
| 728 |    314.393375 |    779.859663 | C. Camilo Julián-Caballero                                                                                                                                            |
| 729 |    478.613333 |    653.589103 | Lauren Sumner-Rooney                                                                                                                                                  |
| 730 |    397.606169 |    305.918922 | Ludwik Gasiorowski                                                                                                                                                    |
| 731 |    478.760940 |    792.636931 | Steven Traver                                                                                                                                                         |
| 732 |    451.440746 |    690.457527 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 733 |    462.858180 |     31.204564 | Renata F. Martins                                                                                                                                                     |
| 734 |    250.538498 |     17.848626 | FunkMonk                                                                                                                                                              |
| 735 |    729.832453 |    186.174762 | Jonathan Wells                                                                                                                                                        |
| 736 |    981.995636 |    460.032529 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 737 |    982.527164 |    644.271039 | Jagged Fang Designs                                                                                                                                                   |
| 738 |    642.544351 |    696.148187 | Steven Traver                                                                                                                                                         |
| 739 |    164.142903 |    611.348567 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 740 |     94.205217 |    375.508571 | Margot Michaud                                                                                                                                                        |
| 741 |    422.985024 |    749.842228 | Mo Hassan                                                                                                                                                             |
| 742 |    862.316148 |    554.394674 | T. Michael Keesey                                                                                                                                                     |
| 743 |    699.368722 |    556.074488 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 744 |    645.266043 |     92.917350 | Zimices                                                                                                                                                               |
| 745 |    448.391637 |    408.749810 | Margot Michaud                                                                                                                                                        |
| 746 |    267.505144 |    282.500464 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 747 |    980.410404 |    211.567833 | Oliver Voigt                                                                                                                                                          |
| 748 |     43.813593 |    469.992103 | Steven Traver                                                                                                                                                         |
| 749 |    606.315791 |    428.238379 | Lukasiniho                                                                                                                                                            |
| 750 |     20.648476 |    150.943539 | Matt Crook                                                                                                                                                            |
| 751 |    384.243900 |    450.040521 | Scott Hartman                                                                                                                                                         |
| 752 |    436.953893 |    739.051169 | Juan Carlos Jerí                                                                                                                                                      |
| 753 |   1015.446175 |    451.579488 | Jaime Headden                                                                                                                                                         |
| 754 |    249.742958 |     95.774541 | Renato Santos                                                                                                                                                         |
| 755 |    683.412157 |     97.903032 | Matt Crook                                                                                                                                                            |
| 756 |    796.301332 |    223.002751 | Chris huh                                                                                                                                                             |
| 757 |    164.325854 |    273.046971 | Berivan Temiz                                                                                                                                                         |
| 758 |    662.410664 |     23.827670 | NA                                                                                                                                                                    |
| 759 |    865.040472 |    243.649570 | Margot Michaud                                                                                                                                                        |
| 760 |    559.129584 |     95.858001 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 761 |    875.367002 |    526.272079 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 762 |    903.621011 |    244.322891 | Gareth Monger                                                                                                                                                         |
| 763 |    941.587238 |    248.347260 | NA                                                                                                                                                                    |
| 764 |    574.814174 |    615.613357 | C. Camilo Julián-Caballero                                                                                                                                            |
| 765 |    885.901040 |    202.577906 | Michelle Site                                                                                                                                                         |
| 766 |    452.129624 |    725.822422 | Lafage                                                                                                                                                                |
| 767 |    988.020228 |    414.970535 | Gareth Monger                                                                                                                                                         |
| 768 |    831.870178 |    597.958624 | David Orr                                                                                                                                                             |
| 769 |    510.877859 |    184.387159 | Birgit Lang                                                                                                                                                           |
| 770 |    834.106084 |    782.693664 | Scott Reid                                                                                                                                                            |
| 771 |    588.587595 |    471.482434 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 772 |   1003.226381 |    524.761939 | Mattia Menchetti                                                                                                                                                      |
| 773 |    117.607578 |    463.799863 | Matt Crook                                                                                                                                                            |
| 774 |    202.884990 |    452.005403 | Maxime Dahirel                                                                                                                                                        |
| 775 |    985.744986 |    730.256501 | T. Michael Keesey                                                                                                                                                     |
| 776 |    678.901719 |    539.375055 | T. Michael Keesey                                                                                                                                                     |
| 777 |    264.343801 |    555.212343 | Scott Hartman                                                                                                                                                         |
| 778 |    157.710100 |    311.661004 | Xavier Giroux-Bougard                                                                                                                                                 |
| 779 |    198.705491 |    724.284751 | NA                                                                                                                                                                    |
| 780 |    304.141927 |    323.107483 | Tracy A. Heath                                                                                                                                                        |
| 781 |    271.818195 |    242.506225 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 782 |    986.462641 |    219.569271 | Dean Schnabel                                                                                                                                                         |
| 783 |    106.923620 |    635.121818 | Mario Quevedo                                                                                                                                                         |
| 784 |    474.383327 |    765.210986 | Gareth Monger                                                                                                                                                         |
| 785 |    261.004304 |    657.423175 | NA                                                                                                                                                                    |
| 786 |    773.044102 |    385.317104 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 787 |    421.158625 |     18.314588 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 788 |    520.154749 |    758.814449 | Lily Hughes                                                                                                                                                           |
| 789 |    443.089369 |    105.005404 | Kamil S. Jaron                                                                                                                                                        |
| 790 |    427.605274 |    100.737773 | Ferran Sayol                                                                                                                                                          |
| 791 |     72.420552 |    286.549894 | Tauana J. Cunha                                                                                                                                                       |
| 792 |    332.510819 |    165.303402 | NA                                                                                                                                                                    |
| 793 |    247.676479 |    230.615540 | Margot Michaud                                                                                                                                                        |
| 794 |    918.817690 |    792.888648 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 795 |    474.044719 |    336.560457 | Maija Karala                                                                                                                                                          |
| 796 |    579.535706 |    411.499002 | Gareth Monger                                                                                                                                                         |
| 797 |   1015.126725 |    519.118940 | Scott Hartman                                                                                                                                                         |
| 798 |    637.204400 |    566.867170 | T. Michael Keesey                                                                                                                                                     |
| 799 |   1002.456734 |    764.394649 | Chuanixn Yu                                                                                                                                                           |
| 800 |    454.924897 |    245.856538 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 801 |    424.264207 |    329.285684 | Ferran Sayol                                                                                                                                                          |
| 802 |    304.618466 |    646.618838 | Jagged Fang Designs                                                                                                                                                   |
| 803 |    696.097835 |    250.103506 | C. Camilo Julián-Caballero                                                                                                                                            |
| 804 |     39.022577 |    296.108984 | Ignacio Contreras                                                                                                                                                     |
| 805 |    968.579757 |    510.523039 | Rainer Schoch                                                                                                                                                         |
| 806 |    262.229575 |    225.150046 | Steven Traver                                                                                                                                                         |
| 807 |    735.562878 |    785.698034 | Martin Kevil                                                                                                                                                          |
| 808 |     60.073410 |    516.548874 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 809 |    381.388032 |    158.367521 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
| 810 |    140.646621 |    443.897313 | V. Deepak                                                                                                                                                             |
| 811 |    653.171521 |    349.051593 | Steven Traver                                                                                                                                                         |
| 812 |    242.135332 |    216.803921 | Mathilde Cordellier                                                                                                                                                   |
| 813 |    548.519087 |    659.947485 | Anthony Caravaggi                                                                                                                                                     |
| 814 |    102.028405 |     16.130797 | Zimices                                                                                                                                                               |
| 815 |    617.328819 |     80.764714 | Margot Michaud                                                                                                                                                        |
| 816 |    202.258713 |    207.597563 | Roberto Díaz Sibaja                                                                                                                                                   |
| 817 |    746.904310 |    381.239087 | Tasman Dixon                                                                                                                                                          |
| 818 |    388.731605 |    784.198127 | Markus A. Grohme                                                                                                                                                      |
| 819 |    721.034439 |    136.057028 | Birgit Lang                                                                                                                                                           |
| 820 |     80.295828 |    656.268783 | Chris huh                                                                                                                                                             |
| 821 |    681.108515 |    110.496927 | Iain Reid                                                                                                                                                             |
| 822 |    145.303409 |    375.616415 | Zimices                                                                                                                                                               |
| 823 |    221.315557 |     38.755051 | Ferran Sayol                                                                                                                                                          |
| 824 |    598.067741 |    745.376046 | L. Shyamal                                                                                                                                                            |
| 825 |     50.421918 |    118.835283 | Ryan Cupo                                                                                                                                                             |
| 826 |    650.457478 |      4.734871 | Margot Michaud                                                                                                                                                        |
| 827 |    984.144090 |    765.290837 | Markus A. Grohme                                                                                                                                                      |
| 828 |    280.474700 |    498.264546 | Chris huh                                                                                                                                                             |
| 829 |    383.309798 |    197.627209 | Martin R. Smith                                                                                                                                                       |
| 830 |     83.792785 |    231.744607 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 831 |    835.057353 |    741.167687 | Gareth Monger                                                                                                                                                         |
| 832 |    829.795881 |    278.221092 | Chris huh                                                                                                                                                             |
| 833 |    358.155867 |     32.592358 | V. Deepak                                                                                                                                                             |
| 834 |    652.649388 |    448.030748 | Tasman Dixon                                                                                                                                                          |
| 835 |    680.637658 |    469.994263 | Matt Crook                                                                                                                                                            |
| 836 |    881.354289 |    583.517447 | Gareth Monger                                                                                                                                                         |
| 837 |     18.338262 |    671.542318 | Ferran Sayol                                                                                                                                                          |
| 838 |    425.146977 |    573.418150 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 839 |    346.296755 |    185.038108 | Katie S. Collins                                                                                                                                                      |
| 840 |    311.333332 |    127.291156 | M Kolmann                                                                                                                                                             |
| 841 |    420.806611 |    717.358376 | Shyamal                                                                                                                                                               |
| 842 |    878.664373 |    725.756389 | Zimices                                                                                                                                                               |
| 843 |     10.713092 |    618.398245 | Zimices                                                                                                                                                               |
| 844 |    808.033962 |    294.723829 | Zimices                                                                                                                                                               |
| 845 |    208.395027 |    106.244777 | Zimices                                                                                                                                                               |
| 846 |    606.138374 |     90.756198 | Melissa Broussard                                                                                                                                                     |
| 847 |    526.798735 |    346.181473 | SecretJellyMan                                                                                                                                                        |
| 848 |    287.298500 |    792.423900 | Zimices                                                                                                                                                               |
| 849 |    842.389287 |    319.658785 | Ferran Sayol                                                                                                                                                          |
| 850 |     93.683693 |    457.546460 | Steven Traver                                                                                                                                                         |
| 851 |    157.761452 |    556.364058 | Tasman Dixon                                                                                                                                                          |
| 852 |    317.576860 |    119.467232 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                             |
| 853 |    804.977030 |    517.197370 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 854 |    343.891662 |     89.630298 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 855 |     65.958473 |     88.609046 | Matt Crook                                                                                                                                                            |
| 856 |     98.483888 |    700.668862 | Becky Barnes                                                                                                                                                          |
| 857 |    351.401610 |    792.113305 | C. Camilo Julián-Caballero                                                                                                                                            |
| 858 |    499.640108 |    485.192455 | Matt Crook                                                                                                                                                            |
| 859 |    233.548403 |    592.471241 | Zimices                                                                                                                                                               |
| 860 |      8.809655 |    465.631583 | Scott Hartman                                                                                                                                                         |
| 861 |    376.473939 |    790.148721 | Margot Michaud                                                                                                                                                        |
| 862 |     41.234544 |    281.262211 | Ferran Sayol                                                                                                                                                          |
| 863 |    566.020841 |    574.513661 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 864 |    729.051994 |    126.211293 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 865 |    210.706122 |    629.953723 | Margot Michaud                                                                                                                                                        |
| 866 |    326.166127 |    687.949672 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 867 |      3.884275 |    648.908986 | T. Michael Keesey                                                                                                                                                     |
| 868 |    220.570026 |    179.100883 | Steven Traver                                                                                                                                                         |
| 869 |     37.885660 |    205.970785 | Mathilde Cordellier                                                                                                                                                   |
| 870 |    417.302327 |     45.641341 | NA                                                                                                                                                                    |
| 871 |     59.385607 |    544.712524 | Margot Michaud                                                                                                                                                        |
| 872 |    121.746747 |    737.791322 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 873 |   1012.760302 |    509.041565 | Scott Hartman                                                                                                                                                         |
| 874 |    755.454933 |    584.612076 | Steven Traver                                                                                                                                                         |
| 875 |    308.825905 |    537.128652 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 876 |    433.181181 |    451.405142 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 877 |    270.190636 |    535.045256 | Gareth Monger                                                                                                                                                         |
| 878 |    975.899203 |    162.942820 | Gareth Monger                                                                                                                                                         |
| 879 |    176.396179 |    601.170059 | NA                                                                                                                                                                    |
| 880 |    681.034276 |    223.080241 | Gareth Monger                                                                                                                                                         |
| 881 |      8.216329 |     14.231306 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 882 |    905.137351 |    451.835707 | Scott Hartman                                                                                                                                                         |
| 883 |    235.019580 |     17.543776 | NA                                                                                                                                                                    |
| 884 |    759.912150 |    782.858327 | Chase Brownstein                                                                                                                                                      |
| 885 |    947.327430 |    398.591623 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 886 |    602.305844 |    725.195531 | Ferran Sayol                                                                                                                                                          |
| 887 |     98.698476 |    659.200312 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 888 |    620.644735 |    788.272110 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 889 |    903.863952 |    527.169891 | Michael Scroggie                                                                                                                                                      |
| 890 |   1001.169615 |    179.056361 | Jagged Fang Designs                                                                                                                                                   |
| 891 |    653.442183 |    706.875320 | Zimices                                                                                                                                                               |
| 892 |    502.598717 |    429.331973 | Shyamal                                                                                                                                                               |
| 893 |    573.854078 |    718.906542 | CNZdenek                                                                                                                                                              |
| 894 |    147.776339 |    530.896845 | Ingo Braasch                                                                                                                                                          |
| 895 |    252.826428 |    514.428296 | Tyler Greenfield                                                                                                                                                      |
| 896 |    568.804150 |     27.671696 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 897 |    799.373574 |    257.786438 | Margot Michaud                                                                                                                                                        |
| 898 |    801.659701 |    438.298265 | New York Zoological Society                                                                                                                                           |
| 899 |    240.835542 |    554.586078 | Matt Martyniuk                                                                                                                                                        |
| 900 |      8.532563 |    364.115253 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 901 |    341.275794 |    565.259693 | Daniel Stadtmauer                                                                                                                                                     |
| 902 |     89.233324 |    360.706109 | James Neenan                                                                                                                                                          |
| 903 |    408.051164 |    578.370622 | Steven Traver                                                                                                                                                         |
| 904 |     19.296836 |    481.644501 | Cagri Cevrim                                                                                                                                                          |
| 905 |    407.548026 |     11.389774 | Jagged Fang Designs                                                                                                                                                   |
| 906 |    703.773976 |    540.729946 | Mo Hassan                                                                                                                                                             |

    #> Your tweet has been posted!
