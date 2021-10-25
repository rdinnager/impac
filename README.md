
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
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
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Zimices, Ferran Sayol, Birgit Lang, T. Michael Keesey, Sharon
Wegner-Larsen, Jagged Fang Designs, Martien Brand (original photo),
Renato Santos (vector silhouette), Caroline Harding, MAF (vectorized by
T. Michael Keesey), Gareth Monger, Matt Celeskey, Gabriela Palomo-Munoz,
Ernst Haeckel (vectorized by T. Michael Keesey), Matt Crook, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Chase Brownstein, Emily Willoughby, Scott
Hartman, Chris huh, Mali’o Kodis, photograph by John Slapcinsky, Steven
Traver, Mr E? (vectorized by T. Michael Keesey), Roberto Díaz Sibaja,
Christoph Schomburg, Milton Tan, Mathilde Cordellier, Tasman Dixon,
Mathew Wedel, Michael Scroggie, Nina Skinner, Anthony Caravaggi, Margot
Michaud, Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), SecretJellyMan,
Shyamal, Kai R. Caspar, David Orr, Nobu Tamura, vectorized by Zimices,
Alex Slavenko, Dmitry Bogdanov (vectorized by T. Michael Keesey), Becky
Barnes, LeonardoG (photography) and T. Michael Keesey (vectorization),
Ingo Braasch, Martin R. Smith, after Skovsted et al 2015, Collin Gross,
Craig Dylke, Andreas Trepte (vectorized by T. Michael Keesey), Nicholas
J. Czaplewski, vectorized by Zimices, Yan Wong from wikipedia drawing
(PD: Pearson Scott Foresman), Katie S. Collins, Harold N Eyster, Jan
Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Conty (vectorized by T. Michael Keesey), Carlos
Cano-Barbacil, , Dean Schnabel, Lisa Byrne, Steven Coombs, Campbell
Fleming, Antonov (vectorized by T. Michael Keesey), Marcos Pérez-Losada,
Jens T. Høeg & Keith A. Crandall, Chris A. Hamilton, FJDegrange, Joris
van der Ham (vectorized by T. Michael Keesey), Michelle Site, Scott
Reid, Nobu Tamura (vectorized by T. Michael Keesey), C. Camilo
Julián-Caballero, Alexander Schmidt-Lebuhn, Inessa Voet, Mathieu
Basille, L. Shyamal, terngirl, Ghedoghedo (vectorized by T. Michael
Keesey), Felix Vaux, Obsidian Soul (vectorized by T. Michael Keesey),
Julie Blommaert based on photo by Sofdrakou, Oscar Sanisidro, Maija
Karala, Manabu Sakamoto, Robert Bruce Horsfall, from W.B. Scott’s 1912
“A History of Land Mammals in the Western Hemisphere”, JCGiron,
Francisco Gascó (modified by Michael P. Taylor), Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Brockhaus and Efron,
Tommaso Cancellario, Rebecca Groom, Smokeybjb, Griensteidl and T.
Michael Keesey, Natasha Vitek, DW Bapst (modified from Bulman, 1970),
Matt Martyniuk, Melissa Broussard, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Rene Martin,
Arthur Weasley (vectorized by T. Michael Keesey), Abraão B. Leite, Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, E. R. Waite & H. M. Hale
(vectorized by T. Michael Keesey), Caleb M. Brown, Tony Ayling
(vectorized by Milton Tan), Maxime Dahirel, Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Espen Horn (model; vectorized by T.
Michael Keesey from a photo by H. Zell), TaraTaylorDesign, Nobu Tamura,
Iain Reid, Moussa Direct Ltd. (photography) and T. Michael Keesey
(vectorization), annaleeblysse, Tauana J. Cunha, Noah Schlottman, photo
from Casey Dunn, Mali’o Kodis, traced image from the National Science
Foundation’s Turbellarian Taxonomic Database, Mali’o Kodis, image from
the Biodiversity Heritage Library, Catherine Yasuda, Christopher Watson
(photo) and T. Michael Keesey (vectorization), Lukasiniho, Falconaumanni
and T. Michael Keesey, Yan Wong from drawing by T. F. Zimmermann, Noah
Schlottman, photo by Museum of Geology, University of Tartu, S.Martini,
Jake Warner, Taro Maeda, Philip Chalmers (vectorized by T. Michael
Keesey), Tracy A. Heath, Elizabeth Parker, Michael Wolf (photo), Hans
Hillewaert (editing), T. Michael Keesey (vectorization), Matt Martyniuk
(vectorized by T. Michael Keesey), DW Bapst (modified from Bates et al.,
2005), CNZdenek, Jack Mayer Wood, T. Michael Keesey (after Tillyard),
Roberto Diaz Sibaja, based on Domser, T. Tischler, Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Mali’o Kodis, image from the Smithsonian Institution, Mike
Hanson, Nobu Tamura (modified by T. Michael Keesey), Smokeybjb (modified
by Mike Keesey), Sarah Werning, Elisabeth Östman, Matus Valach, Mariana
Ruiz Villarreal, Henry Lydecker, T. Michael Keesey (after Masteraah),
Dmitry Bogdanov, Baheerathan Murugavel, James I. Kirkland, Luis Alcalá,
Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Yan Wong, Beth Reinke, Kamil S.
Jaron, Tambja (vectorized by T. Michael Keesey), Didier Descouens
(vectorized by T. Michael Keesey), Timothy Knepp (vectorized by T.
Michael Keesey), Haplochromis (vectorized by T. Michael Keesey),
wsnaccad, Pete Buchholz, Bryan Carstens, Noah Schlottman, Darren Naish
(vectorized by T. Michael Keesey), Mason McNair, Sean McCann, Joanna
Wolfe, Peter Coxhead, Fir0002/Flagstaffotos (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Jay Matternes (vectorized
by T. Michael Keesey), T. Michael Keesey (vectorization); Thorsten
Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal
Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography),
Darren Naish (vectorize by T. Michael Keesey), Luc Viatour (source
photo) and Andreas Plank, M. A. Broussard, Renata F. Martins, Tarique
Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Pranav Iyer (grey ideas), Renato Santos, Cesar Julian, (after
Spotila 2004), V. Deepak, Matt Martyniuk (modified by Serenchia), Raven
Amos, Noah Schlottman, photo from National Science Foundation -
Turbellarian Taxonomic Database, James R. Spotila and Ray Chatterji,
Ekaterina Kopeykina (vectorized by T. Michael Keesey), Zimices, based in
Mauricio Antón skeletal, Sergio A. Muñoz-Gómez, Chris Jennings
(Risiatto), Evan Swigart (photography) and T. Michael Keesey
(vectorization), Noah Schlottman, photo by Martin V. Sørensen, Robbie N.
Cada (modified by T. Michael Keesey), Qiang Ou, Jon Hill, Trond R.
Oskars, Adrian Reich, NASA, Notafly (vectorized by T. Michael Keesey),
Roule Jammes (vectorized by T. Michael Keesey), Fernando Carezzano,
Davidson Sodré, Burton Robert, USFWS, Jose Carlos Arenas-Monroy,
Lindberg (vectorized by T. Michael Keesey), Audrey Ely, Andrew A. Farke,
Chloé Schmidt, Hans Hillewaert (vectorized by T. Michael Keesey), Don
Armstrong, Yan Wong from drawing by Joseph Smit, Theodore W. Pietsch
(photography) and T. Michael Keesey (vectorization), Jimmy Bernot,
Richard J. Harris, Jaime Headden, Dave Souza (vectorized by T. Michael
Keesey), Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Scarlet23 (vectorized by T. Michael Keesey),
Terpsichores, Smith609 and T. Michael Keesey, Ville-Veikko Sinkkonen,
FunkMonk, Richard Lampitt, Jeremy Young / NHM (vectorization by Yan
Wong), Josep Marti Solans, Liftarn, Martin Kevil, T. Michael Keesey
(vectorization) and Tony Hisgett (photography), Julio Garza, Robbie N.
Cada (vectorized by T. Michael Keesey), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey), Yan
Wong from illustration by Jules Richard (1907), Nobu Tamura, modified by
Andrew A. Farke, Cristina Guijarro, Mattia Menchetti, Walter Vladimir,
Nicolas Mongiardino Koch, Matt Hayes, Julien Louys, Tyler Greenfield,
Aviceda (vectorized by T. Michael Keesey), Armin Reindl, Eyal Bartov,
Douglas Brown (modified by T. Michael Keesey), Yan Wong from SEM by
Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo), Oren Peles /
vectorized by Yan Wong, Tony Ayling (vectorized by T. Michael Keesey),
Noah Schlottman, photo by Gustav Paulay for Moorea Biocode, Cristopher
Silva, Martin R. Smith, Noah Schlottman, photo by Casey Dunn, Mali’o
Kodis, photograph by Jim Vargo, Abraão Leite, Matt Wilkins, NOAA Great
Lakes Environmental Research Laboratory (illustration) and Timothy J.
Bartley (silhouette), Paul Baker (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, B. Duygu Özpolat, Dantheman9758
(vectorized by T. Michael Keesey), Doug Backlund (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Andrew A. Farke,
modified from original by Robert Bruce Horsfall, from Scott 1912,
Dr. Thomas G. Barnes, USFWS, Lee Harding (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, T. Michael Keesey (after
MPF), Kent Sorgon, Ben Moon, Heinrich Harder (vectorized by T. Michael
Keesey), E. Lear, 1819 (vectorization by Yan Wong), Florian Pfaff,
Gustav Mützel, Prin Pattawaro (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Karina Garcia, Michele M Tobias, Marie
Russell, Kimberly Haddrell, nicubunu

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    104.022294 |    676.767319 | Zimices                                                                                                                                                                              |
|   2 |    697.090472 |    158.507719 | Ferran Sayol                                                                                                                                                                         |
|   3 |    189.444412 |    469.805136 | Birgit Lang                                                                                                                                                                          |
|   4 |    325.509335 |    682.149900 | T. Michael Keesey                                                                                                                                                                    |
|   5 |    877.472405 |    567.945023 | Sharon Wegner-Larsen                                                                                                                                                                 |
|   6 |    354.103237 |     49.692305 | Jagged Fang Designs                                                                                                                                                                  |
|   7 |    406.785711 |    365.650915 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
|   8 |    676.662464 |    508.530819 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
|   9 |    962.211706 |    290.893471 | Gareth Monger                                                                                                                                                                        |
|  10 |    742.761421 |    333.431917 | Zimices                                                                                                                                                                              |
|  11 |    574.333314 |     93.752172 | Matt Celeskey                                                                                                                                                                        |
|  12 |    567.303369 |    546.023313 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  13 |    971.413539 |    399.768749 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
|  14 |    248.037469 |    171.420973 | Matt Crook                                                                                                                                                                           |
|  15 |    323.305411 |    241.727306 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|  16 |    347.009888 |    566.390745 | Chase Brownstein                                                                                                                                                                     |
|  17 |    130.616802 |    221.630084 | NA                                                                                                                                                                                   |
|  18 |    548.863906 |    257.293653 | Emily Willoughby                                                                                                                                                                     |
|  19 |    485.227746 |    195.959872 | Scott Hartman                                                                                                                                                                        |
|  20 |    332.202168 |    764.643760 | Chris huh                                                                                                                                                                            |
|  21 |    594.058647 |    222.857814 | Gareth Monger                                                                                                                                                                        |
|  22 |    646.259596 |    735.173005 | NA                                                                                                                                                                                   |
|  23 |    857.638535 |    733.816853 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                                          |
|  24 |    574.315077 |    369.187995 | Steven Traver                                                                                                                                                                        |
|  25 |    786.683608 |     95.428880 | Jagged Fang Designs                                                                                                                                                                  |
|  26 |    291.465660 |    508.018814 | Chris huh                                                                                                                                                                            |
|  27 |    336.515003 |    350.822003 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                              |
|  28 |    752.134901 |    629.634274 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  29 |     60.805560 |    323.607226 | Christoph Schomburg                                                                                                                                                                  |
|  30 |    662.050803 |    278.384295 | Milton Tan                                                                                                                                                                           |
|  31 |    883.336039 |    330.161201 | Mathilde Cordellier                                                                                                                                                                  |
|  32 |    862.133981 |    245.607337 | Tasman Dixon                                                                                                                                                                         |
|  33 |    886.428264 |    647.869344 | Mathew Wedel                                                                                                                                                                         |
|  34 |    101.693683 |    107.842913 | Michael Scroggie                                                                                                                                                                     |
|  35 |    929.354120 |    102.121685 | Zimices                                                                                                                                                                              |
|  36 |    443.290697 |    720.423910 | Matt Crook                                                                                                                                                                           |
|  37 |    416.334495 |    659.673903 | Nina Skinner                                                                                                                                                                         |
|  38 |    177.181023 |    277.574071 | Anthony Caravaggi                                                                                                                                                                    |
|  39 |    255.954356 |    681.411647 | Margot Michaud                                                                                                                                                                       |
|  40 |    592.486041 |    649.189437 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                               |
|  41 |    191.849455 |    714.814825 | SecretJellyMan                                                                                                                                                                       |
|  42 |    230.165451 |     77.172588 | Shyamal                                                                                                                                                                              |
|  43 |    867.140454 |    167.176341 | Kai R. Caspar                                                                                                                                                                        |
|  44 |    730.554233 |    238.703927 | David Orr                                                                                                                                                                            |
|  45 |    414.781272 |    477.494432 | Scott Hartman                                                                                                                                                                        |
|  46 |    716.974656 |     48.089862 | Anthony Caravaggi                                                                                                                                                                    |
|  47 |    160.579672 |     23.663507 | Birgit Lang                                                                                                                                                                          |
|  48 |    898.224268 |     32.859067 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  49 |    840.137713 |    470.442857 | Zimices                                                                                                                                                                              |
|  50 |    399.976593 |    245.069350 | Margot Michaud                                                                                                                                                                       |
|  51 |    209.273940 |    358.060465 | Alex Slavenko                                                                                                                                                                        |
|  52 |    939.506827 |    743.240297 | David Orr                                                                                                                                                                            |
|  53 |    114.881297 |    523.245685 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  54 |     62.135900 |    438.176757 | Becky Barnes                                                                                                                                                                         |
|  55 |    365.951230 |    148.160550 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                        |
|  56 |    706.491390 |    428.570830 | Jagged Fang Designs                                                                                                                                                                  |
|  57 |    295.584791 |    446.343454 | Gareth Monger                                                                                                                                                                        |
|  58 |    529.115712 |    768.708121 | Ingo Braasch                                                                                                                                                                         |
|  59 |    207.803110 |    605.191876 | Chris huh                                                                                                                                                                            |
|  60 |    962.071585 |    531.734113 | Chris huh                                                                                                                                                                            |
|  61 |    781.501065 |    409.372463 | Jagged Fang Designs                                                                                                                                                                  |
|  62 |    477.517638 |    405.132825 | Martin R. Smith, after Skovsted et al 2015                                                                                                                                           |
|  63 |    247.314654 |    756.208611 | Tasman Dixon                                                                                                                                                                         |
|  64 |    366.255116 |    529.243137 | Collin Gross                                                                                                                                                                         |
|  65 |    460.037966 |    162.069413 | Craig Dylke                                                                                                                                                                          |
|  66 |    956.681261 |    493.345997 | T. Michael Keesey                                                                                                                                                                    |
|  67 |     28.181327 |    121.626981 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                     |
|  68 |    412.750546 |     31.023184 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                        |
|  69 |    489.997375 |    290.753860 | Zimices                                                                                                                                                                              |
|  70 |    102.362555 |    183.895561 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                                         |
|  71 |    761.227868 |    550.357857 | Katie S. Collins                                                                                                                                                                     |
|  72 |    983.114297 |    641.419238 | NA                                                                                                                                                                                   |
|  73 |    669.069750 |    767.859265 | Gareth Monger                                                                                                                                                                        |
|  74 |    671.439769 |    635.309012 | Harold N Eyster                                                                                                                                                                      |
|  75 |    418.086577 |     79.297405 | T. Michael Keesey                                                                                                                                                                    |
|  76 |    821.796055 |    714.237821 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
|  77 |    750.861018 |     17.872360 | Ingo Braasch                                                                                                                                                                         |
|  78 |    293.304458 |    190.160452 | Zimices                                                                                                                                                                              |
|  79 |    385.838959 |    286.212736 | Conty (vectorized by T. Michael Keesey)                                                                                                                                              |
|  80 |    997.204072 |    225.814300 | Carlos Cano-Barbacil                                                                                                                                                                 |
|  81 |    449.996737 |    763.225039 | T. Michael Keesey                                                                                                                                                                    |
|  82 |    125.800957 |    777.295468 | Jagged Fang Designs                                                                                                                                                                  |
|  83 |    748.775677 |    782.873496 | T. Michael Keesey                                                                                                                                                                    |
|  84 |    687.750190 |     15.329892 | Jagged Fang Designs                                                                                                                                                                  |
|  85 |    246.974227 |     19.864333 | Zimices                                                                                                                                                                              |
|  86 |    393.691152 |    618.497738 | Steven Traver                                                                                                                                                                        |
|  87 |    761.574112 |    761.307347 |                                                                                                                                                                                      |
|  88 |    899.905208 |    683.330704 | Dean Schnabel                                                                                                                                                                        |
|  89 |    943.438934 |    700.756256 | Christoph Schomburg                                                                                                                                                                  |
|  90 |    892.384908 |     59.751467 | Lisa Byrne                                                                                                                                                                           |
|  91 |    579.959825 |    287.734759 | Steven Coombs                                                                                                                                                                        |
|  92 |    622.556066 |    613.895286 | Campbell Fleming                                                                                                                                                                     |
|  93 |    161.858139 |    557.268076 | Matt Crook                                                                                                                                                                           |
|  94 |    477.272858 |    580.761796 | Steven Traver                                                                                                                                                                        |
|  95 |    432.023513 |     55.597186 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
|  96 |    933.810284 |    260.271748 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                                                |
|  97 |     30.145850 |    394.314072 | Chris A. Hamilton                                                                                                                                                                    |
|  98 |    975.639679 |      7.857518 | Margot Michaud                                                                                                                                                                       |
|  99 |    609.876537 |    173.776424 | FJDegrange                                                                                                                                                                           |
| 100 |    332.364261 |    289.052212 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                                  |
| 101 |    391.149720 |    727.563751 | Michelle Site                                                                                                                                                                        |
| 102 |   1005.786921 |    388.437032 | Scott Hartman                                                                                                                                                                        |
| 103 |    338.660477 |    475.634897 | Scott Reid                                                                                                                                                                           |
| 104 |    557.748501 |     26.073030 | Chris huh                                                                                                                                                                            |
| 105 |     26.849077 |     47.021772 | Scott Hartman                                                                                                                                                                        |
| 106 |     59.595331 |    403.616350 | Matt Crook                                                                                                                                                                           |
| 107 |    136.844816 |    324.287193 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 108 |    187.523427 |    120.191481 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 109 |    442.104505 |    115.540611 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 110 |    997.345691 |     42.456023 | T. Michael Keesey                                                                                                                                                                    |
| 111 |    851.049806 |    789.986135 | Inessa Voet                                                                                                                                                                          |
| 112 |    358.205142 |    410.736444 | Matt Crook                                                                                                                                                                           |
| 113 |    566.406560 |    679.897165 | Mathieu Basille                                                                                                                                                                      |
| 114 |     76.215292 |    468.559854 | Matt Crook                                                                                                                                                                           |
| 115 |     13.677634 |    248.783409 | T. Michael Keesey                                                                                                                                                                    |
| 116 |    976.065585 |    618.624123 | Collin Gross                                                                                                                                                                         |
| 117 |    258.124615 |    417.246059 | Zimices                                                                                                                                                                              |
| 118 |    977.130766 |    254.660615 | Collin Gross                                                                                                                                                                         |
| 119 |    281.372755 |    299.375291 | Zimices                                                                                                                                                                              |
| 120 |    781.271186 |     23.706982 | Chris huh                                                                                                                                                                            |
| 121 |    664.778366 |    149.302821 | Margot Michaud                                                                                                                                                                       |
| 122 |    649.669307 |    326.280440 | L. Shyamal                                                                                                                                                                           |
| 123 |    538.936187 |    155.491265 | Steven Traver                                                                                                                                                                        |
| 124 |    587.723868 |    626.204990 | terngirl                                                                                                                                                                             |
| 125 |    870.071675 |    615.264020 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 126 |    943.765221 |    319.784625 | Felix Vaux                                                                                                                                                                           |
| 127 |    819.189623 |    182.690105 | Zimices                                                                                                                                                                              |
| 128 |    473.378870 |    129.405563 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 129 |    369.809493 |    700.875022 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 130 |    934.062696 |    155.422150 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 131 |    652.234590 |    681.621017 | Gareth Monger                                                                                                                                                                        |
| 132 |    717.973568 |    753.831526 | Margot Michaud                                                                                                                                                                       |
| 133 |    790.358122 |    169.033200 | Julie Blommaert based on photo by Sofdrakou                                                                                                                                          |
| 134 |    430.948975 |    602.348799 | Oscar Sanisidro                                                                                                                                                                      |
| 135 |    591.842726 |    459.037444 | Maija Karala                                                                                                                                                                         |
| 136 |    911.736122 |    751.923592 | Matt Crook                                                                                                                                                                           |
| 137 |    201.164074 |    432.755148 | Margot Michaud                                                                                                                                                                       |
| 138 |    946.433336 |    181.385913 | Manabu Sakamoto                                                                                                                                                                      |
| 139 |    833.469840 |    541.922014 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                                  |
| 140 |    882.876733 |    600.193717 | Zimices                                                                                                                                                                              |
| 141 |    337.371638 |    459.735096 | JCGiron                                                                                                                                                                              |
| 142 |    884.417280 |    289.338416 | Maija Karala                                                                                                                                                                         |
| 143 |    260.257652 |    750.484459 | L. Shyamal                                                                                                                                                                           |
| 144 |    412.695272 |    704.280703 | Katie S. Collins                                                                                                                                                                     |
| 145 |    101.619407 |    501.826090 | Margot Michaud                                                                                                                                                                       |
| 146 |    547.134947 |    295.796885 | NA                                                                                                                                                                                   |
| 147 |    635.804205 |    445.310292 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                                      |
| 148 |     69.385360 |     40.052034 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                                           |
| 149 |    938.911244 |    134.328641 | Brockhaus and Efron                                                                                                                                                                  |
| 150 |    357.775188 |    784.723165 | Shyamal                                                                                                                                                                              |
| 151 |   1001.985400 |    471.706534 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 152 |    789.074953 |    449.759951 | Margot Michaud                                                                                                                                                                       |
| 153 |    508.390292 |    378.605475 | Tommaso Cancellario                                                                                                                                                                  |
| 154 |    951.851840 |    208.867177 | Rebecca Groom                                                                                                                                                                        |
| 155 |    153.877455 |    120.622807 | Zimices                                                                                                                                                                              |
| 156 |    509.166613 |    229.595338 | Smokeybjb                                                                                                                                                                            |
| 157 |   1014.690203 |    737.860013 | T. Michael Keesey                                                                                                                                                                    |
| 158 |     19.062513 |    267.060042 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 159 |    186.551651 |    631.855512 | Griensteidl and T. Michael Keesey                                                                                                                                                    |
| 160 |    491.073266 |     20.376641 | Natasha Vitek                                                                                                                                                                        |
| 161 |    682.237398 |    299.729192 | DW Bapst (modified from Bulman, 1970)                                                                                                                                                |
| 162 |    968.684279 |    229.724424 | Matt Martyniuk                                                                                                                                                                       |
| 163 |    836.674489 |    560.932418 | Melissa Broussard                                                                                                                                                                    |
| 164 |    564.744113 |    477.872690 | Matt Crook                                                                                                                                                                           |
| 165 |    101.331846 |    380.903025 | Jagged Fang Designs                                                                                                                                                                  |
| 166 |      6.934835 |    722.963750 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                                          |
| 167 |    213.498333 |    490.279006 | Rene Martin                                                                                                                                                                          |
| 168 |    121.597521 |    345.646665 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 169 |    816.087158 |    277.179361 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                     |
| 170 |    674.875508 |    250.165749 | David Orr                                                                                                                                                                            |
| 171 |    108.132859 |    398.679790 | Abraão B. Leite                                                                                                                                                                      |
| 172 |    812.978348 |    793.430440 | Zimices                                                                                                                                                                              |
| 173 |     28.871675 |    535.576802 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 174 |    685.348366 |    366.135038 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                   |
| 175 |    487.268375 |    104.229071 | Katie S. Collins                                                                                                                                                                     |
| 176 |     87.071819 |    615.494080 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                                             |
| 177 |   1012.546044 |     85.190944 | Scott Hartman                                                                                                                                                                        |
| 178 |    388.605983 |    215.527841 | NA                                                                                                                                                                                   |
| 179 |    132.013026 |     13.059732 | Smokeybjb                                                                                                                                                                            |
| 180 |    893.040899 |    222.586741 | Mathieu Basille                                                                                                                                                                      |
| 181 |    661.295983 |    317.351551 | NA                                                                                                                                                                                   |
| 182 |    242.208179 |    124.189533 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 183 |    997.782752 |    436.052476 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                                           |
| 184 |    940.524767 |    461.530541 | Matt Crook                                                                                                                                                                           |
| 185 |    790.468234 |    116.783085 | Chris huh                                                                                                                                                                            |
| 186 |    241.965003 |    540.748655 | Jagged Fang Designs                                                                                                                                                                  |
| 187 |     83.576333 |    713.930746 | Chris huh                                                                                                                                                                            |
| 188 |    814.851231 |     29.829436 | Zimices                                                                                                                                                                              |
| 189 |    360.468375 |    477.479102 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 190 |    227.929211 |    421.459182 | Matt Crook                                                                                                                                                                           |
| 191 |    250.980092 |    532.748524 | NA                                                                                                                                                                                   |
| 192 |    835.792628 |     70.431049 | Caleb M. Brown                                                                                                                                                                       |
| 193 |    399.455513 |     37.215172 | T. Michael Keesey                                                                                                                                                                    |
| 194 |    901.214822 |    653.518352 | Scott Hartman                                                                                                                                                                        |
| 195 |    126.251213 |    383.958788 | Scott Hartman                                                                                                                                                                        |
| 196 |    933.319421 |    175.176043 | Ferran Sayol                                                                                                                                                                         |
| 197 |    893.975170 |     71.352480 | Margot Michaud                                                                                                                                                                       |
| 198 |    127.075351 |    797.454286 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                               |
| 199 |    786.078719 |     39.752901 | Gareth Monger                                                                                                                                                                        |
| 200 |    205.849744 |    419.465940 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 201 |    114.500189 |    251.709101 | Matt Crook                                                                                                                                                                           |
| 202 |    979.794620 |    185.074884 | NA                                                                                                                                                                                   |
| 203 |    216.159088 |    563.346429 | Maxime Dahirel                                                                                                                                                                       |
| 204 |    753.660942 |    748.988316 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                                 |
| 205 |    636.068559 |    539.853673 | Margot Michaud                                                                                                                                                                       |
| 206 |    966.035765 |    657.774779 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                   |
| 207 |    960.371349 |    508.940070 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                          |
| 208 |    220.026261 |    322.275831 | Zimices                                                                                                                                                                              |
| 209 |    233.523048 |    647.198185 | TaraTaylorDesign                                                                                                                                                                     |
| 210 |    707.188808 |    389.333676 | Margot Michaud                                                                                                                                                                       |
| 211 |    787.857108 |    190.109159 | Ferran Sayol                                                                                                                                                                         |
| 212 |    860.782240 |    112.555334 | Oscar Sanisidro                                                                                                                                                                      |
| 213 |    783.368178 |    783.663615 | Chris huh                                                                                                                                                                            |
| 214 |    924.677408 |    419.757161 | Nobu Tamura                                                                                                                                                                          |
| 215 |    715.808558 |    412.421295 | Iain Reid                                                                                                                                                                            |
| 216 |    680.145285 |    674.296166 | Collin Gross                                                                                                                                                                         |
| 217 |     32.638148 |    648.382580 | Matt Crook                                                                                                                                                                           |
| 218 |    310.765261 |    422.896269 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                               |
| 219 |    811.036397 |    129.297697 | Jagged Fang Designs                                                                                                                                                                  |
| 220 |    194.822518 |     10.723935 | annaleeblysse                                                                                                                                                                        |
| 221 |    926.138721 |    205.598584 | Zimices                                                                                                                                                                              |
| 222 |    772.718628 |    142.331885 | Matt Crook                                                                                                                                                                           |
| 223 |    741.590765 |    182.984360 | Natasha Vitek                                                                                                                                                                        |
| 224 |    650.141047 |    370.086744 | T. Michael Keesey                                                                                                                                                                    |
| 225 |   1009.644467 |    202.723681 | T. Michael Keesey                                                                                                                                                                    |
| 226 |    912.145256 |    436.906322 | Tauana J. Cunha                                                                                                                                                                      |
| 227 |    641.440229 |    151.816886 | Zimices                                                                                                                                                                              |
| 228 |    279.170025 |    220.665602 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 229 |    157.212357 |    453.959602 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 230 |    171.846651 |    189.184847 | Mali’o Kodis, traced image from the National Science Foundation’s Turbellarian Taxonomic Database                                                                                    |
| 231 |    763.455417 |    702.525666 | Milton Tan                                                                                                                                                                           |
| 232 |    327.592213 |    405.741311 | Christoph Schomburg                                                                                                                                                                  |
| 233 |    295.943100 |     88.552772 | Matt Crook                                                                                                                                                                           |
| 234 |    494.583680 |    592.667125 | Zimices                                                                                                                                                                              |
| 235 |    817.628347 |    777.056609 | Tasman Dixon                                                                                                                                                                         |
| 236 |    401.136329 |    782.951451 | Matt Crook                                                                                                                                                                           |
| 237 |    144.068006 |    423.853464 | Zimices                                                                                                                                                                              |
| 238 |    224.059783 |    720.722312 | Gareth Monger                                                                                                                                                                        |
| 239 |    773.120782 |    729.904103 | Gareth Monger                                                                                                                                                                        |
| 240 |    313.165750 |    786.826552 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 241 |    270.981266 |    577.400207 | Zimices                                                                                                                                                                              |
| 242 |    713.583679 |    688.184452 | Margot Michaud                                                                                                                                                                       |
| 243 |     34.252698 |    275.955675 | Dean Schnabel                                                                                                                                                                        |
| 244 |    438.477764 |    554.237714 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                           |
| 245 |    855.378804 |    624.539900 | Jagged Fang Designs                                                                                                                                                                  |
| 246 |    256.954739 |    283.484985 | Catherine Yasuda                                                                                                                                                                     |
| 247 |     26.314813 |    486.502332 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                     |
| 248 |   1015.554637 |    336.440864 | Chris huh                                                                                                                                                                            |
| 249 |    693.478043 |    306.688909 | Matt Martyniuk                                                                                                                                                                       |
| 250 |    689.108529 |    200.940243 | NA                                                                                                                                                                                   |
| 251 |    850.413000 |    426.276846 | Scott Hartman                                                                                                                                                                        |
| 252 |    264.913618 |    434.332431 | Collin Gross                                                                                                                                                                         |
| 253 |    464.574179 |    232.943701 | Lukasiniho                                                                                                                                                                           |
| 254 |    853.248599 |    392.818607 | Zimices                                                                                                                                                                              |
| 255 |     31.188442 |    700.721892 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 256 |   1017.278201 |    569.267924 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                                            |
| 257 |    831.161669 |    262.704949 | Christoph Schomburg                                                                                                                                                                  |
| 258 |    158.145195 |    258.102244 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                                     |
| 259 |    583.186804 |    697.174576 | NA                                                                                                                                                                                   |
| 260 |    924.694893 |    337.551373 | Zimices                                                                                                                                                                              |
| 261 |    655.788210 |    428.110360 | Steven Traver                                                                                                                                                                        |
| 262 |    299.425722 |    396.299527 | S.Martini                                                                                                                                                                            |
| 263 |    342.664523 |    634.185573 | David Orr                                                                                                                                                                            |
| 264 |     32.097157 |    476.990430 | Jake Warner                                                                                                                                                                          |
| 265 |    858.065414 |    273.229753 | L. Shyamal                                                                                                                                                                           |
| 266 |    792.957977 |     65.365522 | Dean Schnabel                                                                                                                                                                        |
| 267 |    855.872969 |     88.101982 | Taro Maeda                                                                                                                                                                           |
| 268 |     12.909403 |    550.442806 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
| 269 |    101.301183 |    275.247278 | Tracy A. Heath                                                                                                                                                                       |
| 270 |    251.419389 |    148.390977 | Matt Crook                                                                                                                                                                           |
| 271 |    832.346481 |    230.017436 | Michelle Site                                                                                                                                                                        |
| 272 |     96.945408 |    323.577732 | Elizabeth Parker                                                                                                                                                                     |
| 273 |    412.916849 |    573.492537 | Tasman Dixon                                                                                                                                                                         |
| 274 |     66.572730 |    497.550868 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 275 |    266.087044 |    362.027509 | Tasman Dixon                                                                                                                                                                         |
| 276 |    115.137591 |    625.192922 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 277 |    387.927062 |    325.393175 | T. Michael Keesey                                                                                                                                                                    |
| 278 |    495.457556 |    167.932575 | Scott Hartman                                                                                                                                                                        |
| 279 |    896.327645 |    282.486571 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 280 |    801.723187 |    274.158211 | Matt Crook                                                                                                                                                                           |
| 281 |    573.664514 |    176.854482 | Kai R. Caspar                                                                                                                                                                        |
| 282 |    441.915105 |    639.998471 | Tasman Dixon                                                                                                                                                                         |
| 283 |     94.977163 |    558.835434 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
| 284 |     55.319909 |     21.304147 | DW Bapst (modified from Bates et al., 2005)                                                                                                                                          |
| 285 |    289.854678 |    634.089149 | SecretJellyMan                                                                                                                                                                       |
| 286 |    689.706919 |    651.266207 | Collin Gross                                                                                                                                                                         |
| 287 |    762.358509 |    736.635624 | Ferran Sayol                                                                                                                                                                         |
| 288 |    994.094012 |    194.358772 | NA                                                                                                                                                                                   |
| 289 |    214.911829 |    443.960473 | Zimices                                                                                                                                                                              |
| 290 |    764.870359 |    694.659814 | Gareth Monger                                                                                                                                                                        |
| 291 |    765.540150 |    450.386342 | Matt Crook                                                                                                                                                                           |
| 292 |    225.025717 |    410.103806 | CNZdenek                                                                                                                                                                             |
| 293 |    924.628108 |      6.586275 | Gareth Monger                                                                                                                                                                        |
| 294 |    450.568450 |     76.951887 | Matt Crook                                                                                                                                                                           |
| 295 |    178.820969 |    175.747602 | Margot Michaud                                                                                                                                                                       |
| 296 |    987.515271 |    668.544734 | Steven Traver                                                                                                                                                                        |
| 297 |     37.460170 |    678.511611 | Scott Hartman                                                                                                                                                                        |
| 298 |    422.115229 |    199.975812 | Gareth Monger                                                                                                                                                                        |
| 299 |    616.394771 |    144.680495 | Chris huh                                                                                                                                                                            |
| 300 |    528.359415 |    698.053055 | NA                                                                                                                                                                                   |
| 301 |    803.914331 |      9.513452 | Matt Crook                                                                                                                                                                           |
| 302 |    805.696643 |    353.594076 | Matt Crook                                                                                                                                                                           |
| 303 |    282.484497 |    318.493048 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 304 |    793.706048 |    261.867026 | Jack Mayer Wood                                                                                                                                                                      |
| 305 |     32.744723 |     16.009757 | Chris huh                                                                                                                                                                            |
| 306 |    207.765474 |    521.787552 | Katie S. Collins                                                                                                                                                                     |
| 307 |    919.436202 |    162.097685 | T. Michael Keesey (after Tillyard)                                                                                                                                                   |
| 308 |    570.130983 |     17.760990 | Ferran Sayol                                                                                                                                                                         |
| 309 |     62.696683 |    548.879605 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 310 |    440.191976 |    448.559566 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
| 311 |    672.977718 |    342.422094 | T. Tischler                                                                                                                                                                          |
| 312 |    948.819198 |    665.466473 | Chris huh                                                                                                                                                                            |
| 313 |    710.879383 |    630.638481 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                               |
| 314 |     19.098014 |    319.482263 | Steven Traver                                                                                                                                                                        |
| 315 |    565.810222 |    442.412795 | Tasman Dixon                                                                                                                                                                         |
| 316 |    499.067997 |    192.701637 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 317 |    733.136533 |    658.396427 | Chris huh                                                                                                                                                                            |
| 318 |    273.223048 |    608.551883 | Gareth Monger                                                                                                                                                                        |
| 319 |    858.839610 |     60.622459 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 320 |    605.840924 |    301.547741 | Scott Hartman                                                                                                                                                                        |
| 321 |    985.503739 |    592.344331 | Ferran Sayol                                                                                                                                                                         |
| 322 |    792.714938 |     49.999704 | Margot Michaud                                                                                                                                                                       |
| 323 |    635.323722 |    524.311514 | Iain Reid                                                                                                                                                                            |
| 324 |   1009.518246 |    167.648166 | Ferran Sayol                                                                                                                                                                         |
| 325 |    272.113662 |    398.769803 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                                 |
| 326 |    793.685229 |    790.896958 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 327 |    603.531719 |    260.099031 | Scott Hartman                                                                                                                                                                        |
| 328 |    279.741408 |    117.091426 | Gareth Monger                                                                                                                                                                        |
| 329 |    984.593523 |     20.308804 | Mike Hanson                                                                                                                                                                          |
| 330 |     49.799673 |     86.988169 | Ingo Braasch                                                                                                                                                                         |
| 331 |    980.836195 |    193.486554 | Zimices                                                                                                                                                                              |
| 332 |     32.651717 |    257.907624 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 333 |     74.648309 |    543.275248 | Gareth Monger                                                                                                                                                                        |
| 334 |     58.408178 |    105.186532 | Matt Crook                                                                                                                                                                           |
| 335 |    427.095233 |    102.018705 | Margot Michaud                                                                                                                                                                       |
| 336 |    537.218947 |    434.640249 | Smokeybjb (modified by Mike Keesey)                                                                                                                                                  |
| 337 |    882.705288 |    391.793731 | Sarah Werning                                                                                                                                                                        |
| 338 |    646.615294 |    197.541253 | Elisabeth Östman                                                                                                                                                                     |
| 339 |    441.483709 |    434.336185 | Zimices                                                                                                                                                                              |
| 340 |    818.509044 |    611.855543 | Matus Valach                                                                                                                                                                         |
| 341 |    223.805516 |    228.523052 | L. Shyamal                                                                                                                                                                           |
| 342 |    990.663255 |    141.007762 | T. Michael Keesey                                                                                                                                                                    |
| 343 |    198.662484 |    112.228185 | Mariana Ruiz Villarreal                                                                                                                                                              |
| 344 |    131.788196 |    544.496761 | T. Michael Keesey                                                                                                                                                                    |
| 345 |    681.272579 |    390.725229 | Henry Lydecker                                                                                                                                                                       |
| 346 |    798.605976 |    231.354886 | T. Michael Keesey (after Masteraah)                                                                                                                                                  |
| 347 |    317.208666 |    465.476520 | Gareth Monger                                                                                                                                                                        |
| 348 |    570.752150 |    618.374859 | Zimices                                                                                                                                                                              |
| 349 |    403.159532 |    584.078364 | Dmitry Bogdanov                                                                                                                                                                      |
| 350 |    450.730362 |    702.301738 | Baheerathan Murugavel                                                                                                                                                                |
| 351 |    468.406673 |    782.826558 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
| 352 |    888.881177 |      9.405759 | Yan Wong                                                                                                                                                                             |
| 353 |   1013.776669 |    680.344350 | Ferran Sayol                                                                                                                                                                         |
| 354 |    573.711987 |    202.480455 | Lukasiniho                                                                                                                                                                           |
| 355 |    678.748686 |    601.634490 | Chase Brownstein                                                                                                                                                                     |
| 356 |    695.063411 |    377.448202 | Beth Reinke                                                                                                                                                                          |
| 357 |    377.490126 |    208.713439 | Kamil S. Jaron                                                                                                                                                                       |
| 358 |    746.460063 |    593.184302 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 359 |    999.988732 |    348.327840 | Margot Michaud                                                                                                                                                                       |
| 360 |     75.307763 |      9.870308 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                             |
| 361 |    110.970831 |    408.398630 | Ingo Braasch                                                                                                                                                                         |
| 362 |    554.871136 |    186.678365 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 363 |     21.266016 |    216.870010 | Margot Michaud                                                                                                                                                                       |
| 364 |    701.851976 |    703.869305 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                                      |
| 365 |    685.905738 |    782.110491 | Zimices                                                                                                                                                                              |
| 366 |    438.279454 |    172.185224 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 367 |    377.311569 |    372.007508 | Steven Traver                                                                                                                                                                        |
| 368 |    458.130938 |    366.594733 | wsnaccad                                                                                                                                                                             |
| 369 |    123.531156 |    397.738672 | Matt Crook                                                                                                                                                                           |
| 370 |     96.614927 |     43.868207 | Pete Buchholz                                                                                                                                                                        |
| 371 |    292.532064 |    673.411826 | Bryan Carstens                                                                                                                                                                       |
| 372 |    364.528065 |    733.035494 | Margot Michaud                                                                                                                                                                       |
| 373 |    827.504833 |     37.676960 | Jagged Fang Designs                                                                                                                                                                  |
| 374 |    998.038158 |     97.548415 | Noah Schlottman                                                                                                                                                                      |
| 375 |    825.118167 |    203.176205 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                       |
| 376 |     92.032811 |    751.366212 | Christoph Schomburg                                                                                                                                                                  |
| 377 |    485.815849 |    255.168391 | DW Bapst (modified from Bulman, 1970)                                                                                                                                                |
| 378 |    419.004497 |    592.533040 | Scott Reid                                                                                                                                                                           |
| 379 |    252.446163 |    551.929691 | Kamil S. Jaron                                                                                                                                                                       |
| 380 |    487.053503 |    482.166842 | NA                                                                                                                                                                                   |
| 381 |    532.625683 |    127.196433 | Shyamal                                                                                                                                                                              |
| 382 |    510.288454 |    711.247084 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 383 |     24.638558 |    787.255436 | Melissa Broussard                                                                                                                                                                    |
| 384 |    956.710081 |     42.119036 | Mason McNair                                                                                                                                                                         |
| 385 |     40.641339 |    206.169064 | Jagged Fang Designs                                                                                                                                                                  |
| 386 |    610.497289 |    445.466605 | Sean McCann                                                                                                                                                                          |
| 387 |    937.081540 |    552.005798 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 388 |    979.540102 |     59.045336 | Joanna Wolfe                                                                                                                                                                         |
| 389 |    601.877830 |    187.816938 | Peter Coxhead                                                                                                                                                                        |
| 390 |    152.655546 |    107.011434 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                |
| 391 |     58.339588 |    479.576478 | Matt Crook                                                                                                                                                                           |
| 392 |    461.039564 |    257.580177 | Zimices                                                                                                                                                                              |
| 393 |    251.275389 |    268.161333 | Felix Vaux                                                                                                                                                                           |
| 394 |   1014.807280 |    776.320131 | Zimices                                                                                                                                                                              |
| 395 |    932.920895 |    380.217359 | T. Michael Keesey                                                                                                                                                                    |
| 396 |    463.820298 |     81.402481 | Dean Schnabel                                                                                                                                                                        |
| 397 |    197.784242 |    501.095512 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 398 |    334.177300 |    210.661784 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 399 |     32.309267 |    341.508674 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 400 |    104.726650 |     30.841321 | Ferran Sayol                                                                                                                                                                         |
| 401 |    298.225725 |     65.133217 | Scott Hartman                                                                                                                                                                        |
| 402 |    256.628568 |    240.500645 | Zimices                                                                                                                                                                              |
| 403 |    625.257009 |    160.753208 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                      |
| 404 |     22.647265 |    520.957611 | Chris huh                                                                                                                                                                            |
| 405 |     10.158306 |    589.064616 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 406 |     22.543784 |    773.076177 | Matt Crook                                                                                                                                                                           |
| 407 |    432.957343 |    198.129832 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 408 |    148.247814 |    462.940521 | Margot Michaud                                                                                                                                                                       |
| 409 |    658.789875 |    234.513281 | Margot Michaud                                                                                                                                                                       |
| 410 |    690.999369 |    258.539378 | Gareth Monger                                                                                                                                                                        |
| 411 |    303.416717 |     73.057829 | NA                                                                                                                                                                                   |
| 412 |    428.470248 |    768.884293 | Luc Viatour (source photo) and Andreas Plank                                                                                                                                         |
| 413 |    946.538434 |    347.133038 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 414 |    340.111080 |    552.710358 | Matt Crook                                                                                                                                                                           |
| 415 |    114.861910 |    286.781182 | T. Michael Keesey                                                                                                                                                                    |
| 416 |    550.271883 |    170.140798 | M. A. Broussard                                                                                                                                                                      |
| 417 |    391.074617 |     73.251434 | Michael Scroggie                                                                                                                                                                     |
| 418 |    765.974197 |    160.546053 | Renata F. Martins                                                                                                                                                                    |
| 419 |    130.194094 |    502.489917 | Zimices                                                                                                                                                                              |
| 420 |    689.311644 |    115.121766 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 421 |     50.142962 |    790.981806 | NA                                                                                                                                                                                   |
| 422 |    398.900428 |      5.265638 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 423 |    591.372061 |    682.520322 | David Orr                                                                                                                                                                            |
| 424 |     11.194958 |    344.122259 | Ferran Sayol                                                                                                                                                                         |
| 425 |    904.756228 |    449.498477 | Matt Martyniuk                                                                                                                                                                       |
| 426 |    328.540032 |    426.002759 | Michael Scroggie                                                                                                                                                                     |
| 427 |    322.293552 |    169.098608 | Felix Vaux                                                                                                                                                                           |
| 428 |    940.129637 |    230.751246 | Sarah Werning                                                                                                                                                                        |
| 429 |    601.949498 |     15.662189 | Matt Crook                                                                                                                                                                           |
| 430 |    418.892059 |    439.832657 | Kai R. Caspar                                                                                                                                                                        |
| 431 |    928.391281 |    192.140602 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 432 |    997.729105 |    129.766466 | Matt Crook                                                                                                                                                                           |
| 433 |    824.900195 |    252.400925 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 434 |     68.053832 |    554.501567 | Zimices                                                                                                                                                                              |
| 435 |    713.068318 |    672.695790 | Alex Slavenko                                                                                                                                                                        |
| 436 |    531.956747 |    662.142452 | Matt Crook                                                                                                                                                                           |
| 437 |    945.455207 |    625.413059 | Renato Santos                                                                                                                                                                        |
| 438 |    708.979681 |    781.644848 | Cesar Julian                                                                                                                                                                         |
| 439 |    236.098417 |    313.964752 | Ferran Sayol                                                                                                                                                                         |
| 440 |   1003.877146 |    552.628409 | Felix Vaux                                                                                                                                                                           |
| 441 |     25.187228 |    751.229571 | Gareth Monger                                                                                                                                                                        |
| 442 |    705.382447 |    655.977573 | Chris huh                                                                                                                                                                            |
| 443 |    733.829610 |     98.971749 | NA                                                                                                                                                                                   |
| 444 |    786.344554 |    729.219505 | (after Spotila 2004)                                                                                                                                                                 |
| 445 |    437.183327 |    687.884604 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 446 |    150.700451 |    439.756069 | V. Deepak                                                                                                                                                                            |
| 447 |    449.733476 |     95.033115 | Steven Traver                                                                                                                                                                        |
| 448 |     28.227155 |    682.756835 | T. Michael Keesey                                                                                                                                                                    |
| 449 |    466.754424 |    598.836848 | Tracy A. Heath                                                                                                                                                                       |
| 450 |    247.104075 |    468.922669 | Matt Martyniuk (modified by Serenchia)                                                                                                                                               |
| 451 |    115.958227 |    558.315565 | Ferran Sayol                                                                                                                                                                         |
| 452 |    371.462697 |    688.789548 | Matt Crook                                                                                                                                                                           |
| 453 |    851.727734 |    107.466224 | Scott Hartman                                                                                                                                                                        |
| 454 |    627.982479 |    550.301934 | Scott Hartman                                                                                                                                                                        |
| 455 |    670.234356 |    190.004109 | Zimices                                                                                                                                                                              |
| 456 |    654.202284 |    613.334695 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 457 |    447.853105 |    313.532912 | Scott Hartman                                                                                                                                                                        |
| 458 |    918.716061 |    367.024500 | Scott Hartman                                                                                                                                                                        |
| 459 |    649.198643 |    237.960533 | Raven Amos                                                                                                                                                                           |
| 460 |    624.613986 |    774.092014 | NA                                                                                                                                                                                   |
| 461 |    428.143971 |    751.928681 | V. Deepak                                                                                                                                                                            |
| 462 |    532.315924 |     19.919659 | NA                                                                                                                                                                                   |
| 463 |    449.635153 |    619.295389 | Collin Gross                                                                                                                                                                         |
| 464 |    708.149745 |    405.592295 | Steven Traver                                                                                                                                                                        |
| 465 |    954.271413 |    455.115197 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                                            |
| 466 |    462.121394 |    688.374099 | Ferran Sayol                                                                                                                                                                         |
| 467 |    617.133308 |    681.344524 | Zimices                                                                                                                                                                              |
| 468 |    437.671723 |    530.359083 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 469 |    297.567202 |    418.994584 | Gareth Monger                                                                                                                                                                        |
| 470 |    635.072722 |     18.550952 | T. Michael Keesey                                                                                                                                                                    |
| 471 |    180.407052 |    189.165345 | Gareth Monger                                                                                                                                                                        |
| 472 |     12.066986 |    401.146293 | Zimices                                                                                                                                                                              |
| 473 |    489.408683 |    642.640984 | Birgit Lang                                                                                                                                                                          |
| 474 |    670.605217 |    324.241541 | Steven Traver                                                                                                                                                                        |
| 475 |    385.207200 |    197.593593 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 476 |    930.440936 |    619.857325 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 477 |   1007.598881 |    696.830525 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                                |
| 478 |    583.566828 |    494.755349 | TaraTaylorDesign                                                                                                                                                                     |
| 479 |    608.659988 |    524.280151 | Harold N Eyster                                                                                                                                                                      |
| 480 |    836.676485 |    674.640266 | Dean Schnabel                                                                                                                                                                        |
| 481 |   1008.018228 |    254.793554 | NA                                                                                                                                                                                   |
| 482 |    637.037499 |    782.145544 | Zimices, based in Mauricio Antón skeletal                                                                                                                                            |
| 483 |     60.310384 |    219.662614 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 484 |     80.920522 |    738.656000 | Birgit Lang                                                                                                                                                                          |
| 485 |    746.033086 |    428.661519 | TaraTaylorDesign                                                                                                                                                                     |
| 486 |    366.083605 |    714.502484 | T. Michael Keesey                                                                                                                                                                    |
| 487 |    268.204313 |    104.361093 | Matt Crook                                                                                                                                                                           |
| 488 |    630.653360 |    794.761514 | Margot Michaud                                                                                                                                                                       |
| 489 |    547.818474 |    705.465461 | David Orr                                                                                                                                                                            |
| 490 |   1015.194547 |    767.690330 | Jagged Fang Designs                                                                                                                                                                  |
| 491 |   1012.756760 |    292.468742 | Margot Michaud                                                                                                                                                                       |
| 492 |      9.590305 |     82.452360 | Steven Traver                                                                                                                                                                        |
| 493 |    265.212639 |    257.512377 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 494 |    447.266875 |    748.460776 | Ferran Sayol                                                                                                                                                                         |
| 495 |    987.915881 |     72.807174 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 496 |    624.723007 |    256.309861 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 497 |    811.471127 |    521.999375 | Matt Crook                                                                                                                                                                           |
| 498 |    450.916417 |    592.625732 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 499 |    316.334483 |    779.924621 | Oscar Sanisidro                                                                                                                                                                      |
| 500 |    215.383647 |    657.787598 | NA                                                                                                                                                                                   |
| 501 |    124.245634 |    362.143357 | Chris Jennings (Risiatto)                                                                                                                                                            |
| 502 |    478.348392 |    285.390722 | Scott Hartman                                                                                                                                                                        |
| 503 |    348.769144 |    171.058982 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 504 |    290.904873 |    481.108617 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                                     |
| 505 |     10.483824 |    774.144571 | T. Michael Keesey                                                                                                                                                                    |
| 506 |    923.900762 |    654.759273 | Anthony Caravaggi                                                                                                                                                                    |
| 507 |   1011.987996 |    644.823585 | Anthony Caravaggi                                                                                                                                                                    |
| 508 |     38.357127 |    564.086129 | Tracy A. Heath                                                                                                                                                                       |
| 509 |    162.503923 |    713.151547 | Gareth Monger                                                                                                                                                                        |
| 510 |    707.840201 |    104.010273 | Tasman Dixon                                                                                                                                                                         |
| 511 |    679.971734 |     93.187581 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                                           |
| 512 |    701.711937 |    517.388451 | Tauana J. Cunha                                                                                                                                                                      |
| 513 |    690.983968 |    580.090551 | Margot Michaud                                                                                                                                                                       |
| 514 |     32.566178 |    312.743815 | NA                                                                                                                                                                                   |
| 515 |     57.606722 |    249.298224 | Joanna Wolfe                                                                                                                                                                         |
| 516 |    370.891032 |    634.543877 | NA                                                                                                                                                                                   |
| 517 |    799.938941 |    385.638673 | Gareth Monger                                                                                                                                                                        |
| 518 |    638.059643 |    412.871455 | Margot Michaud                                                                                                                                                                       |
| 519 |    412.724557 |    552.146984 | Zimices                                                                                                                                                                              |
| 520 |    807.445049 |    726.485096 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 521 |    959.552404 |    574.192265 | Raven Amos                                                                                                                                                                           |
| 522 |    685.878357 |    126.464020 | Zimices                                                                                                                                                                              |
| 523 |    346.056638 |    195.052578 | S.Martini                                                                                                                                                                            |
| 524 |    433.256092 |     15.897537 | Zimices                                                                                                                                                                              |
| 525 |    917.091039 |    415.877057 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                       |
| 526 |     45.195038 |     15.998973 | Melissa Broussard                                                                                                                                                                    |
| 527 |    614.761211 |     24.324401 | Qiang Ou                                                                                                                                                                             |
| 528 |    937.952386 |     66.643002 | Sarah Werning                                                                                                                                                                        |
| 529 |    356.959307 |    794.095456 | Zimices                                                                                                                                                                              |
| 530 |     95.851468 |    301.719934 | Jon Hill                                                                                                                                                                             |
| 531 |    400.950265 |     86.625998 | Trond R. Oskars                                                                                                                                                                      |
| 532 |    926.908332 |    765.044790 | Chase Brownstein                                                                                                                                                                     |
| 533 |     43.660708 |    705.426555 | Birgit Lang                                                                                                                                                                          |
| 534 |    953.257750 |    581.755935 | Becky Barnes                                                                                                                                                                         |
| 535 |    100.474541 |    481.646492 | Adrian Reich                                                                                                                                                                         |
| 536 |    415.766505 |    189.419924 | NA                                                                                                                                                                                   |
| 537 |    551.525083 |    199.983791 | NASA                                                                                                                                                                                 |
| 538 |    758.027930 |    790.433753 | NA                                                                                                                                                                                   |
| 539 |    694.189947 |    138.477811 | Notafly (vectorized by T. Michael Keesey)                                                                                                                                            |
| 540 |    238.336609 |    439.971682 | Matt Crook                                                                                                                                                                           |
| 541 |    404.003881 |     53.219070 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                                       |
| 542 |    863.950346 |    412.937427 | Ingo Braasch                                                                                                                                                                         |
| 543 |    469.170905 |     25.045828 | NA                                                                                                                                                                                   |
| 544 |    418.417455 |    732.360920 | David Orr                                                                                                                                                                            |
| 545 |    151.961691 |    163.695653 | Margot Michaud                                                                                                                                                                       |
| 546 |    172.340800 |    213.460716 | Zimices                                                                                                                                                                              |
| 547 |    532.811989 |    143.327299 | Rebecca Groom                                                                                                                                                                        |
| 548 |    862.177774 |    698.290036 | Jon Hill                                                                                                                                                                             |
| 549 |    438.043257 |    146.336780 | Margot Michaud                                                                                                                                                                       |
| 550 |    742.182125 |    415.508981 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 551 |    648.505447 |    403.427566 | NA                                                                                                                                                                                   |
| 552 |    232.067558 |    430.338132 | Fernando Carezzano                                                                                                                                                                   |
| 553 |     84.872436 |    781.139136 | Davidson Sodré                                                                                                                                                                       |
| 554 |    517.072010 |    730.463235 | Steven Traver                                                                                                                                                                        |
| 555 |    402.711326 |    591.023094 | NA                                                                                                                                                                                   |
| 556 |    503.405017 |    446.663258 | T. Michael Keesey (after Tillyard)                                                                                                                                                   |
| 557 |    117.256833 |    483.028505 | Zimices                                                                                                                                                                              |
| 558 |    503.996648 |    408.386784 | Matt Crook                                                                                                                                                                           |
| 559 |    769.322372 |    130.822569 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 560 |    662.679861 |    172.105116 | Burton Robert, USFWS                                                                                                                                                                 |
| 561 |    760.939309 |    276.478549 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 562 |    807.189730 |     59.486300 | Chris huh                                                                                                                                                                            |
| 563 |    975.621294 |    562.685290 | Dean Schnabel                                                                                                                                                                        |
| 564 |    318.763257 |    522.355394 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 565 |    423.148125 |    400.712007 | Kai R. Caspar                                                                                                                                                                        |
| 566 |    819.122633 |    698.923935 | NA                                                                                                                                                                                   |
| 567 |   1016.282966 |    546.322576 | Christoph Schomburg                                                                                                                                                                  |
| 568 |    362.881977 |    721.644570 | T. Michael Keesey                                                                                                                                                                    |
| 569 |   1012.798352 |    709.923366 | CNZdenek                                                                                                                                                                             |
| 570 |     28.051420 |    720.343602 | Margot Michaud                                                                                                                                                                       |
| 571 |     45.488476 |    216.703104 | T. Michael Keesey                                                                                                                                                                    |
| 572 |    668.265904 |    575.296189 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                           |
| 573 |    525.121675 |    175.813943 | T. Michael Keesey                                                                                                                                                                    |
| 574 |    797.709970 |    140.583933 | NA                                                                                                                                                                                   |
| 575 |    292.353171 |    390.795580 | Audrey Ely                                                                                                                                                                           |
| 576 |    241.862256 |    303.482891 | Steven Traver                                                                                                                                                                        |
| 577 |    671.227927 |      5.514236 | Zimices                                                                                                                                                                              |
| 578 |    139.427693 |    263.042877 | Steven Traver                                                                                                                                                                        |
| 579 |    150.276324 |    497.493883 | Andrew A. Farke                                                                                                                                                                      |
| 580 |    646.805837 |    555.736718 | Katie S. Collins                                                                                                                                                                     |
| 581 |    902.016722 |    468.829399 | Gareth Monger                                                                                                                                                                        |
| 582 |    420.084778 |    428.847375 | Jagged Fang Designs                                                                                                                                                                  |
| 583 |     20.526805 |    661.537312 | Zimices                                                                                                                                                                              |
| 584 |    311.185972 |     19.980625 | Margot Michaud                                                                                                                                                                       |
| 585 |    365.456874 |    677.700684 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 586 |     22.016432 |    549.456854 | Zimices                                                                                                                                                                              |
| 587 |    617.513632 |    612.817646 | Gareth Monger                                                                                                                                                                        |
| 588 |    669.439252 |    586.901488 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 589 |    808.598110 |     68.493872 | Christoph Schomburg                                                                                                                                                                  |
| 590 |    488.429626 |    272.259648 | Chloé Schmidt                                                                                                                                                                        |
| 591 |    878.646223 |    118.848933 | Steven Traver                                                                                                                                                                        |
| 592 |     53.729170 |    743.731436 | Tracy A. Heath                                                                                                                                                                       |
| 593 |    348.780013 |    332.440061 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 594 |    274.471151 |    554.805392 | S.Martini                                                                                                                                                                            |
| 595 |    732.542894 |    444.617340 | Matt Crook                                                                                                                                                                           |
| 596 |    452.833131 |    339.509103 | Matt Crook                                                                                                                                                                           |
| 597 |    438.001179 |    627.312930 | Lukasiniho                                                                                                                                                                           |
| 598 |    761.050319 |    512.501734 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                                    |
| 599 |    406.148970 |    691.783114 | Ferran Sayol                                                                                                                                                                         |
| 600 |    169.954601 |    786.075066 | Don Armstrong                                                                                                                                                                        |
| 601 |    840.612693 |     55.306142 | Beth Reinke                                                                                                                                                                          |
| 602 |    402.535219 |    675.522095 | Collin Gross                                                                                                                                                                         |
| 603 |    710.039097 |    793.935587 | Tasman Dixon                                                                                                                                                                         |
| 604 |    792.293493 |    374.865847 | Andrew A. Farke                                                                                                                                                                      |
| 605 |    965.595581 |    171.449444 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 606 |     46.692736 |    477.071817 | Fernando Carezzano                                                                                                                                                                   |
| 607 |     14.592063 |    538.448649 | Yan Wong from drawing by Joseph Smit                                                                                                                                                 |
| 608 |    586.547620 |    165.866099 | NA                                                                                                                                                                                   |
| 609 |    248.403582 |    564.932629 | Tracy A. Heath                                                                                                                                                                       |
| 610 |    466.956935 |    732.037572 | Jagged Fang Designs                                                                                                                                                                  |
| 611 |     60.284751 |    236.623160 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                                              |
| 612 |    624.821353 |    585.729300 | Noah Schlottman, photo from Casey Dunn                                                                                                                                               |
| 613 |     38.286245 |    780.073770 | Kamil S. Jaron                                                                                                                                                                       |
| 614 |    651.805496 |    586.912337 | Jimmy Bernot                                                                                                                                                                         |
| 615 |    276.709957 |    380.047345 | Richard J. Harris                                                                                                                                                                    |
| 616 |     46.105971 |     45.238584 | Gareth Monger                                                                                                                                                                        |
| 617 |     10.500169 |    375.303736 | Matt Crook                                                                                                                                                                           |
| 618 |    600.304173 |    493.496320 | Jaime Headden                                                                                                                                                                        |
| 619 |    647.497720 |    341.841394 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 620 |    501.535932 |    223.569678 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 621 |    236.379165 |    164.573837 | Tasman Dixon                                                                                                                                                                         |
| 622 |    136.106455 |    565.613226 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                                         |
| 623 |     22.956592 |    296.244955 | Birgit Lang                                                                                                                                                                          |
| 624 |    490.016100 |    742.853955 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                             |
| 625 |    702.181803 |     87.155795 | Michelle Site                                                                                                                                                                        |
| 626 |    415.387489 |    775.915617 | Ferran Sayol                                                                                                                                                                         |
| 627 |    382.750894 |    174.515277 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 628 |    890.370022 |    703.089525 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                          |
| 629 |    904.435662 |    524.752673 | T. Tischler                                                                                                                                                                          |
| 630 |    421.620195 |    297.039986 | Steven Traver                                                                                                                                                                        |
| 631 |    433.832860 |    511.249579 | Alex Slavenko                                                                                                                                                                        |
| 632 |    584.765256 |    191.231529 | Ferran Sayol                                                                                                                                                                         |
| 633 |    149.323851 |    794.824357 | Dean Schnabel                                                                                                                                                                        |
| 634 |    359.047785 |    549.348148 | Margot Michaud                                                                                                                                                                       |
| 635 |    200.664501 |    399.937253 | Iain Reid                                                                                                                                                                            |
| 636 |    843.858281 |    332.003879 | Matt Crook                                                                                                                                                                           |
| 637 |    898.364921 |    714.249185 | Chris huh                                                                                                                                                                            |
| 638 |    645.636086 |     24.147619 | Chris huh                                                                                                                                                                            |
| 639 |    243.790922 |    573.527371 | Tracy A. Heath                                                                                                                                                                       |
| 640 |    523.866148 |    203.324452 | Christoph Schomburg                                                                                                                                                                  |
| 641 |    274.265418 |    537.243851 | Terpsichores                                                                                                                                                                         |
| 642 |    981.734291 |    317.530199 | Gareth Monger                                                                                                                                                                        |
| 643 |    800.445027 |    209.068245 | Margot Michaud                                                                                                                                                                       |
| 644 |    528.926570 |    794.864834 | Steven Traver                                                                                                                                                                        |
| 645 |    632.839263 |    240.068832 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 646 |    194.339643 |    410.214493 | NA                                                                                                                                                                                   |
| 647 |     93.393424 |    793.889596 | Mathilde Cordellier                                                                                                                                                                  |
| 648 |    459.016081 |    571.647794 | Smith609 and T. Michael Keesey                                                                                                                                                       |
| 649 |    399.510421 |    305.029127 | Yan Wong                                                                                                                                                                             |
| 650 |   1013.910194 |    193.507781 | Zimices                                                                                                                                                                              |
| 651 |    939.836322 |    589.242697 | Steven Traver                                                                                                                                                                        |
| 652 |    778.846121 |    486.179506 | Margot Michaud                                                                                                                                                                       |
| 653 |    360.740451 |    296.192612 | Mason McNair                                                                                                                                                                         |
| 654 |     48.006226 |    726.872270 | Matt Crook                                                                                                                                                                           |
| 655 |    497.547301 |    356.719258 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 656 |    150.837450 |    528.762524 | Matt Crook                                                                                                                                                                           |
| 657 |    444.675502 |     23.489664 | Ville-Veikko Sinkkonen                                                                                                                                                               |
| 658 |    325.186422 |    621.052097 | Becky Barnes                                                                                                                                                                         |
| 659 |    159.282767 |    696.536135 | Pete Buchholz                                                                                                                                                                        |
| 660 |    629.018997 |    122.737057 | Gareth Monger                                                                                                                                                                        |
| 661 |    179.807647 |    248.459181 | NA                                                                                                                                                                                   |
| 662 |    780.020270 |    277.453568 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
| 663 |    139.287125 |    389.774518 | Zimices                                                                                                                                                                              |
| 664 |    793.112596 |    684.217752 | Chris huh                                                                                                                                                                            |
| 665 |    746.115727 |    698.770049 | L. Shyamal                                                                                                                                                                           |
| 666 |    102.056080 |    313.206840 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 667 |     66.191957 |    571.963468 | FunkMonk                                                                                                                                                                             |
| 668 |    776.381873 |    436.018512 | Mathilde Cordellier                                                                                                                                                                  |
| 669 |    324.068757 |    542.649607 | Gareth Monger                                                                                                                                                                        |
| 670 |    257.618736 |    135.760048 | Milton Tan                                                                                                                                                                           |
| 671 |    816.796120 |    537.807230 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 672 |    780.024571 |    595.250644 | Steven Traver                                                                                                                                                                        |
| 673 |     11.173917 |     26.971562 | Sarah Werning                                                                                                                                                                        |
| 674 |    108.130119 |    437.596691 | NA                                                                                                                                                                                   |
| 675 |    743.708330 |      5.361558 | Andrew A. Farke                                                                                                                                                                      |
| 676 |    968.106565 |    554.498255 | Zimices                                                                                                                                                                              |
| 677 |    822.259955 |    646.790352 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 678 |   1007.913967 |    109.738318 | Matt Crook                                                                                                                                                                           |
| 679 |    308.845450 |    109.157864 | Tasman Dixon                                                                                                                                                                         |
| 680 |    784.395649 |    756.973529 | Josep Marti Solans                                                                                                                                                                   |
| 681 |    144.779128 |    613.272746 | Zimices                                                                                                                                                                              |
| 682 |    828.055505 |    236.949647 | NA                                                                                                                                                                                   |
| 683 |    103.809677 |    612.827153 | Zimices                                                                                                                                                                              |
| 684 |    652.530570 |    529.407429 | Margot Michaud                                                                                                                                                                       |
| 685 |    317.668534 |    186.791067 | L. Shyamal                                                                                                                                                                           |
| 686 |    231.797508 |    512.213947 | NA                                                                                                                                                                                   |
| 687 |    703.798140 |     96.502726 | NA                                                                                                                                                                                   |
| 688 |    493.827882 |    660.894116 | Kai R. Caspar                                                                                                                                                                        |
| 689 |    207.971209 |    645.206993 | Liftarn                                                                                                                                                                              |
| 690 |    186.239622 |     46.979025 | Gareth Monger                                                                                                                                                                        |
| 691 |   1019.602157 |    449.310023 | Gareth Monger                                                                                                                                                                        |
| 692 |    661.059922 |    208.102982 | Kamil S. Jaron                                                                                                                                                                       |
| 693 |    439.400329 |    414.989355 | Michelle Site                                                                                                                                                                        |
| 694 |    717.839214 |    112.801239 | Margot Michaud                                                                                                                                                                       |
| 695 |    464.426250 |    620.330811 | Michael Scroggie                                                                                                                                                                     |
| 696 |    259.306248 |    485.486661 | Sarah Werning                                                                                                                                                                        |
| 697 |    627.364727 |     36.446255 | Martin Kevil                                                                                                                                                                         |
| 698 |    488.322987 |    726.234754 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                                                     |
| 699 |    281.930311 |    661.579565 | Steven Traver                                                                                                                                                                        |
| 700 |     46.099652 |    524.952748 | Julio Garza                                                                                                                                                                          |
| 701 |    117.448372 |    434.854910 | Ferran Sayol                                                                                                                                                                         |
| 702 |    364.649882 |    315.172791 | Alex Slavenko                                                                                                                                                                        |
| 703 |    695.013323 |    619.406565 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                             |
| 704 |    188.382415 |    108.950845 | Scott Hartman                                                                                                                                                                        |
| 705 |    587.072721 |    304.665916 | Zimices                                                                                                                                                                              |
| 706 |    242.839868 |    587.817494 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                     |
| 707 |    999.569546 |    327.561080 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 708 |    276.774697 |    594.336862 | Tracy A. Heath                                                                                                                                                                       |
| 709 |    705.135056 |    523.881863 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                                   |
| 710 |    966.668562 |     50.299662 | Margot Michaud                                                                                                                                                                       |
| 711 |    485.998169 |    708.378163 | Beth Reinke                                                                                                                                                                          |
| 712 |     10.508676 |    522.521475 | Felix Vaux                                                                                                                                                                           |
| 713 |    452.953892 |    536.014127 | Harold N Eyster                                                                                                                                                                      |
| 714 |    864.331013 |     13.529498 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
| 715 |    774.385269 |    666.216392 | Matt Crook                                                                                                                                                                           |
| 716 |    710.126414 |    122.570231 | Cristina Guijarro                                                                                                                                                                    |
| 717 |     39.229819 |     64.981402 | Noah Schlottman                                                                                                                                                                      |
| 718 |    881.744941 |    135.435014 | Margot Michaud                                                                                                                                                                       |
| 719 |    618.502229 |    779.957016 | Mattia Menchetti                                                                                                                                                                     |
| 720 |    308.557003 |    606.942854 | Walter Vladimir                                                                                                                                                                      |
| 721 |    718.869537 |    424.012356 | Matt Crook                                                                                                                                                                           |
| 722 |    937.564479 |    115.279750 | Nicolas Mongiardino Koch                                                                                                                                                             |
| 723 |    936.438812 |     45.757433 | Jagged Fang Designs                                                                                                                                                                  |
| 724 |    974.588890 |    203.437095 | Tracy A. Heath                                                                                                                                                                       |
| 725 |    903.958531 |    392.977516 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 726 |    820.985287 |    168.385135 | Matt Hayes                                                                                                                                                                           |
| 727 |     48.288183 |    505.186749 | Scott Hartman                                                                                                                                                                        |
| 728 |    736.303099 |    688.373623 | NA                                                                                                                                                                                   |
| 729 |    328.092879 |    312.048297 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 730 |    228.354318 |    527.829902 | Margot Michaud                                                                                                                                                                       |
| 731 |    927.357638 |    459.340590 | Anthony Caravaggi                                                                                                                                                                    |
| 732 |   1003.452644 |      6.231587 | Steven Coombs                                                                                                                                                                        |
| 733 |     11.007030 |    742.701657 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 734 |    173.542027 |    154.352317 | Julien Louys                                                                                                                                                                         |
| 735 |    944.478836 |    237.270167 | Chris huh                                                                                                                                                                            |
| 736 |    301.985397 |    128.281625 | Steven Traver                                                                                                                                                                        |
| 737 |    474.040139 |    223.358553 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                     |
| 738 |    644.753836 |    598.610922 | NA                                                                                                                                                                                   |
| 739 |    530.520492 |    174.016016 | Kamil S. Jaron                                                                                                                                                                       |
| 740 |      8.364457 |    499.694777 | Margot Michaud                                                                                                                                                                       |
| 741 |    852.306798 |     80.360693 | NA                                                                                                                                                                                   |
| 742 |    301.686313 |    311.485224 | Matt Martyniuk                                                                                                                                                                       |
| 743 |    217.723429 |    439.852416 | Tasman Dixon                                                                                                                                                                         |
| 744 |     30.557553 |     36.442914 | Tyler Greenfield                                                                                                                                                                     |
| 745 |    268.633188 |    472.324104 | Zimices                                                                                                                                                                              |
| 746 |      9.119134 |    289.873347 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                                            |
| 747 |    971.615783 |    456.300999 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 748 |    962.344568 |    156.714080 | Dmitry Bogdanov                                                                                                                                                                      |
| 749 |    300.968817 |    274.968965 | Zimices                                                                                                                                                                              |
| 750 |    602.913078 |    241.477974 | Scott Hartman                                                                                                                                                                        |
| 751 |    922.474981 |    303.634716 | Armin Reindl                                                                                                                                                                         |
| 752 |    818.275917 |    393.683962 | Eyal Bartov                                                                                                                                                                          |
| 753 |    448.895183 |    393.810333 | Margot Michaud                                                                                                                                                                       |
| 754 |    310.078733 |    352.554829 | Collin Gross                                                                                                                                                                         |
| 755 |   1006.280924 |    758.139337 | NA                                                                                                                                                                                   |
| 756 |    936.062156 |    607.634242 | Matt Crook                                                                                                                                                                           |
| 757 |    965.167016 |    679.761428 | Gareth Monger                                                                                                                                                                        |
| 758 |    754.333555 |    186.958130 | Steven Traver                                                                                                                                                                        |
| 759 |    842.012122 |    511.270419 | Sean McCann                                                                                                                                                                          |
| 760 |     11.143019 |    652.452645 | Margot Michaud                                                                                                                                                                       |
| 761 |    514.881391 |    363.995943 | T. Michael Keesey                                                                                                                                                                    |
| 762 |    462.213329 |    516.555257 | Ferran Sayol                                                                                                                                                                         |
| 763 |    153.070596 |     74.544545 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                                        |
| 764 |     64.096539 |     64.676151 | Gareth Monger                                                                                                                                                                        |
| 765 |   1007.311155 |    406.202589 | Ferran Sayol                                                                                                                                                                         |
| 766 |    574.002657 |    501.397699 | Scott Hartman                                                                                                                                                                        |
| 767 |    839.970183 |    299.353941 | Gareth Monger                                                                                                                                                                        |
| 768 |    205.235647 |    229.181680 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                                              |
| 769 |    807.090914 |    264.114357 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 770 |    123.454977 |    569.551536 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 771 |      8.058094 |    613.132584 | Gareth Monger                                                                                                                                                                        |
| 772 |    128.406387 |    273.763985 | Oren Peles / vectorized by Yan Wong                                                                                                                                                  |
| 773 |    717.313254 |    709.785124 | Margot Michaud                                                                                                                                                                       |
| 774 |    807.634334 |    702.143514 | NA                                                                                                                                                                                   |
| 775 |    991.372653 |    680.049782 | Ferran Sayol                                                                                                                                                                         |
| 776 |    664.060265 |    309.042931 | Oscar Sanisidro                                                                                                                                                                      |
| 777 |     17.716716 |    581.009066 | Matt Martyniuk                                                                                                                                                                       |
| 778 |    900.292736 |    148.937798 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                                          |
| 779 |    955.595599 |    138.289934 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 780 |    134.047046 |    764.668382 | Scott Hartman                                                                                                                                                                        |
| 781 |    986.746412 |    213.174100 | Taro Maeda                                                                                                                                                                           |
| 782 |    663.187770 |    785.859943 | NA                                                                                                                                                                                   |
| 783 |    809.901465 |    511.438513 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                                    |
| 784 |    152.090276 |    177.113609 | Shyamal                                                                                                                                                                              |
| 785 |    996.728661 |     27.577348 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                                           |
| 786 |    863.312489 |    661.337987 | Margot Michaud                                                                                                                                                                       |
| 787 |    939.008356 |    162.567101 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 788 |     79.358911 |     17.314899 | Henry Lydecker                                                                                                                                                                       |
| 789 |   1013.763453 |    580.684915 | Chris huh                                                                                                                                                                            |
| 790 |    266.671985 |    219.094833 | Margot Michaud                                                                                                                                                                       |
| 791 |    771.251430 |    204.230560 | Cristopher Silva                                                                                                                                                                     |
| 792 |    206.877580 |    407.695861 | Raven Amos                                                                                                                                                                           |
| 793 |    172.018301 |    316.020576 | Noah Schlottman                                                                                                                                                                      |
| 794 |    816.138207 |     87.766063 | Matt Crook                                                                                                                                                                           |
| 795 |    769.230226 |    248.608177 | Matt Martyniuk                                                                                                                                                                       |
| 796 |    341.770245 |    516.875500 | Rebecca Groom                                                                                                                                                                        |
| 797 |    208.801146 |     86.380086 | Martin R. Smith                                                                                                                                                                      |
| 798 |    779.932611 |    462.971338 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 799 |    362.554783 |    354.858959 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 800 |    179.089148 |    646.797945 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 801 |     57.780700 |    781.853121 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                                |
| 802 |    432.919683 |    725.242920 | Matt Crook                                                                                                                                                                           |
| 803 |    691.706600 |    402.939152 | Yan Wong                                                                                                                                                                             |
| 804 |    741.290676 |    112.915335 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 805 |    333.655526 |    177.108113 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 806 |      9.492767 |    148.335203 | Matt Crook                                                                                                                                                                           |
| 807 |    377.190616 |    187.498985 | Abraão Leite                                                                                                                                                                         |
| 808 |    236.085830 |    499.023889 | Michelle Site                                                                                                                                                                        |
| 809 |    303.558411 |    339.593737 | Ferran Sayol                                                                                                                                                                         |
| 810 |    718.573721 |      7.787805 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                        |
| 811 |    358.020803 |    432.909268 | Matt Wilkins                                                                                                                                                                         |
| 812 |    255.422714 |    429.998417 | Gareth Monger                                                                                                                                                                        |
| 813 |     46.657418 |    120.011811 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                                |
| 814 |    646.299644 |     33.629846 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
| 815 |    935.855289 |    358.412041 | Ferran Sayol                                                                                                                                                                         |
| 816 |    839.688593 |    609.135360 | Rebecca Groom                                                                                                                                                                        |
| 817 |    356.876280 |    384.323802 | Bryan Carstens                                                                                                                                                                       |
| 818 |    227.399014 |    750.529757 | Ferran Sayol                                                                                                                                                                         |
| 819 |    229.305741 |    238.319785 | Zimices                                                                                                                                                                              |
| 820 |    735.228759 |    456.347368 | Andrew A. Farke                                                                                                                                                                      |
| 821 |    188.600713 |    788.622058 | Beth Reinke                                                                                                                                                                          |
| 822 |    513.027197 |    662.268212 | T. Michael Keesey                                                                                                                                                                    |
| 823 |    931.988601 |    717.454990 | Zimices                                                                                                                                                                              |
| 824 |     15.676735 |    564.371827 | Steven Traver                                                                                                                                                                        |
| 825 |    820.789730 |    115.584567 | Jagged Fang Designs                                                                                                                                                                  |
| 826 |     20.392948 |    668.678168 | Tasman Dixon                                                                                                                                                                         |
| 827 |    250.162933 |    299.177332 | Mason McNair                                                                                                                                                                         |
| 828 |    656.280590 |    390.448034 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                                      |
| 829 |    699.178614 |    759.659476 | Gareth Monger                                                                                                                                                                        |
| 830 |    459.878314 |    202.355882 | Gareth Monger                                                                                                                                                                        |
| 831 |    897.837101 |    417.512023 | Jagged Fang Designs                                                                                                                                                                  |
| 832 |    814.453625 |    436.588570 | Margot Michaud                                                                                                                                                                       |
| 833 |    436.426621 |     86.486871 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 834 |    417.763039 |    508.014069 | Matt Crook                                                                                                                                                                           |
| 835 |    706.074231 |    774.396767 | Ferran Sayol                                                                                                                                                                         |
| 836 |    175.946923 |    772.194821 | Zimices                                                                                                                                                                              |
| 837 |    763.820988 |    255.268700 | Steven Traver                                                                                                                                                                        |
| 838 |      9.852540 |      9.422836 | Joanna Wolfe                                                                                                                                                                         |
| 839 |    657.185909 |    546.777522 | Matt Crook                                                                                                                                                                           |
| 840 |    768.871439 |    177.399027 | B. Duygu Özpolat                                                                                                                                                                     |
| 841 |    390.461636 |    184.429316 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                                      |
| 842 |    266.574494 |    563.118865 | T. Michael Keesey                                                                                                                                                                    |
| 843 |    666.670189 |    221.891508 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 844 |   1007.695540 |     15.420946 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 845 |    960.308121 |    325.596716 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                        |
| 846 |    899.762317 |    697.565565 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                                    |
| 847 |    472.300195 |      9.905481 | Dr. Thomas G. Barnes, USFWS                                                                                                                                                          |
| 848 |    150.099293 |     38.228427 | Tracy A. Heath                                                                                                                                                                       |
| 849 |    952.512983 |    565.849877 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
| 850 |    374.905341 |    438.441929 | T. Michael Keesey (after MPF)                                                                                                                                                        |
| 851 |    256.155955 |     32.486438 | Beth Reinke                                                                                                                                                                          |
| 852 |    462.688674 |    118.596097 | T. Michael Keesey                                                                                                                                                                    |
| 853 |     95.239304 |    459.506395 | Beth Reinke                                                                                                                                                                          |
| 854 |    712.110295 |    746.071740 | Kent Sorgon                                                                                                                                                                          |
| 855 |    748.550575 |    386.883474 | Scott Hartman                                                                                                                                                                        |
| 856 |    790.930428 |    438.112856 | Ben Moon                                                                                                                                                                             |
| 857 |    813.657924 |     21.317632 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                                    |
| 858 |    974.122068 |    144.841310 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                                            |
| 859 |    273.800053 |    618.897765 | Scott Hartman                                                                                                                                                                        |
| 860 |    761.306793 |    268.540517 | Gareth Monger                                                                                                                                                                        |
| 861 |     85.207819 |    387.907934 | Matt Crook                                                                                                                                                                           |
| 862 |    700.999571 |    788.064370 | Scott Hartman                                                                                                                                                                        |
| 863 |    930.789598 |    424.901184 | T. Michael Keesey                                                                                                                                                                    |
| 864 |    143.598685 |     94.568886 | Matt Crook                                                                                                                                                                           |
| 865 |    353.852375 |    613.503636 | Scott Hartman                                                                                                                                                                        |
| 866 |    360.114021 |    220.720766 | Steven Traver                                                                                                                                                                        |
| 867 |    257.151824 |    312.000320 | Gareth Monger                                                                                                                                                                        |
| 868 |    425.321945 |    716.625788 | Florian Pfaff                                                                                                                                                                        |
| 869 |    823.862803 |     11.899129 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 870 |    780.257973 |    743.062198 | NA                                                                                                                                                                                   |
| 871 |    239.735245 |    293.029422 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 872 |    477.439864 |    750.370956 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                                      |
| 873 |     37.166508 |    233.937654 | Margot Michaud                                                                                                                                                                       |
| 874 |    456.645580 |    449.347859 | Chloé Schmidt                                                                                                                                                                        |
| 875 |    310.171186 |    373.965034 | Ferran Sayol                                                                                                                                                                         |
| 876 |    617.498195 |    204.015168 | NA                                                                                                                                                                                   |
| 877 |    791.131712 |    517.591969 | Ferran Sayol                                                                                                                                                                         |
| 878 |    862.810448 |    690.942084 | Gustav Mützel                                                                                                                                                                        |
| 879 |    446.660522 |    381.097979 | Jagged Fang Designs                                                                                                                                                                  |
| 880 |     14.587827 |    704.088493 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 881 |    957.177966 |    145.490017 | Christoph Schomburg                                                                                                                                                                  |
| 882 |    509.388574 |    335.314178 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 883 |    166.888790 |    577.827302 | Maija Karala                                                                                                                                                                         |
| 884 |    601.040223 |    790.415617 | Matt Crook                                                                                                                                                                           |
| 885 |    733.115009 |    651.321458 | Chris huh                                                                                                                                                                            |
| 886 |    987.580684 |    342.946622 | NA                                                                                                                                                                                   |
| 887 |    292.808670 |    598.649216 | Chris huh                                                                                                                                                                            |
| 888 |    648.188773 |    167.342410 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                       |
| 889 |   1008.581633 |     70.867271 | Zimices                                                                                                                                                                              |
| 890 |     58.616017 |    202.311253 | T. Michael Keesey                                                                                                                                                                    |
| 891 |    393.826540 |    535.740473 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 892 |    849.498145 |    234.277622 | Jagged Fang Designs                                                                                                                                                                  |
| 893 |    780.080709 |    711.065421 | Matt Crook                                                                                                                                                                           |
| 894 |    779.337545 |    258.349829 | Karina Garcia                                                                                                                                                                        |
| 895 |     33.656548 |    509.596680 | Baheerathan Murugavel                                                                                                                                                                |
| 896 |    175.109142 |     11.648828 | Zimices                                                                                                                                                                              |
| 897 |    555.309513 |    639.780807 | Scott Hartman                                                                                                                                                                        |
| 898 |    497.285264 |    423.612127 | Felix Vaux                                                                                                                                                                           |
| 899 |    477.763843 |    117.220513 | Margot Michaud                                                                                                                                                                       |
| 900 |    468.100363 |    676.738369 | Armin Reindl                                                                                                                                                                         |
| 901 |    266.458685 |     20.337848 | Michele M Tobias                                                                                                                                                                     |
| 902 |    280.576923 |    525.031989 | Marie Russell                                                                                                                                                                        |
| 903 |    483.621106 |    325.879035 | Matt Crook                                                                                                                                                                           |
| 904 |    843.290830 |    555.381205 | Armin Reindl                                                                                                                                                                         |
| 905 |    388.133323 |    707.787637 | Matt Crook                                                                                                                                                                           |
| 906 |     87.758654 |    276.424042 | Steven Traver                                                                                                                                                                        |
| 907 |    514.428019 |    432.575234 | Kimberly Haddrell                                                                                                                                                                    |
| 908 |    561.001563 |    464.939694 | Yan Wong                                                                                                                                                                             |
| 909 |    454.219318 |    506.994412 | nicubunu                                                                                                                                                                             |
| 910 |    163.175500 |    491.662958 | Jagged Fang Designs                                                                                                                                                                  |
| 911 |    481.014620 |    620.386733 | Maija Karala                                                                                                                                                                         |
| 912 |    159.835079 |    142.395707 | Ferran Sayol                                                                                                                                                                         |
| 913 |    166.722246 |     99.952129 | Gareth Monger                                                                                                                                                                        |
| 914 |    577.954087 |    273.993885 | Steven Traver                                                                                                                                                                        |
| 915 |    274.611554 |    342.749425 | Maija Karala                                                                                                                                                                         |
| 916 |    584.216856 |    250.955566 | Matt Crook                                                                                                                                                                           |
| 917 |    367.353182 |    620.129424 | Emily Willoughby                                                                                                                                                                     |
| 918 |    452.775657 |      6.329436 | Emily Willoughby                                                                                                                                                                     |
| 919 |    953.730557 |     14.007972 | Mathew Wedel                                                                                                                                                                         |
| 920 |    935.738528 |    675.186152 | Zimices                                                                                                                                                                              |
| 921 |    977.938125 |    306.614384 | Zimices                                                                                                                                                                              |
| 922 |     89.242536 |    625.714217 | Matt Crook                                                                                                                                                                           |
| 923 |    166.265691 |    464.207525 | Jagged Fang Designs                                                                                                                                                                  |

    #> Your tweet has been posted!
